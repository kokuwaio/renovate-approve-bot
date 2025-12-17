# https://just.systems/man/en/

[private]
@default:
    just --list --unsorted

# Run linter.
@lint:
    cargo fmt --all --
    docker run --rm --read-only --volume=$PWD:$PWD:ro --workdir=$PWD kokuwaio/just:1.45.0
    docker run --rm --read-only --volume=$PWD:$PWD:ro --workdir=$PWD kokuwaio/hadolint:v2.14.0
    docker run --rm --read-only --volume=$PWD:$PWD:ro --workdir=$PWD kokuwaio/yamllint:v1.37.1
    docker run --rm --read-only --volume=$PWD:$PWD:rw --workdir=$PWD kokuwaio/markdownlint:0.47.0 --fix
    docker run --rm --read-only --volume=$PWD:$PWD:ro --workdir=$PWD kokuwaio/renovate-config-validator:42
    docker run --rm --read-only --volume=$PWD:$PWD:ro --workdir=$PWD woodpeckerci/woodpecker-cli lint

# Build binary run.
run TOKEN_FILE:
    cargo build
    ./target/debug/renovate-approve-bot --host=https://git.kokuwa.io --token-file {{ TOKEN_FILE }}

# Build image with buildkit.
build:
    docker buildx build . --build-arg=RUSTUP_UPDATE_ROOT --build-arg=RUSTUP_DIST_SERVER --platform=linux/arm64,linux/amd64

# Build image with local docker daemon and run.
docker TOKEN_FILE:
    docker build . --tag=kokuwaio/renovate-approve-bot:dev -build-arg=RUSTUP_UPDATE_ROOT --build-arg=RUSTUP_DIST_SERVER
    docker run --rm -it --read-only --user=1000:1000 --volume={{ TOKEN_FILE }}:/token:ro kokuwaio/renovate-approve-bot:dev --host=https://git.kokuwa.io --token-file=/token

# Print image size.
size:
    #!/usr/bin/env bash
    docker run --quiet --detach --publish=5000:5000 --name=registry registry >/dev/null
    docker build . --build-arg=RUSTUP_UPDATE_ROOT --build-arg=RUSTUP_DIST_SERVER --quiet --tag localhost:5000/i --push >/dev/null
    printf "uncompressed: %'14d bytes (on your disk)\n" "$(docker image inspect localhost:5000/i --format='{{{{.Size}}')"
    printf "compressed:   %'14d bytes (transferred from registry to disk)\n" "$(docker manifest inspect localhost:5000/i --insecure | jq .layers[].size | tr '\n' '+' | cat - <(echo "0") | bc)"
    docker rm registry --force --volumes >/dev/null 2>&1

# Inspect image layers with `dive`.
dive TARGET="":
    dive build . --target={{ TARGET }} --build-arg=RUSTUP_UPDATE_ROOT --build-arg=RUSTUP_DIST_SERVER

# Create sbom from Cargo.lock.
sbom:
    docker run --rm --user=$(id -u):$(id -g) --volume=$PWD:$PWD --workdir=$PWD ghcr.io/cyclonedx/cdxgen-debian-rust:v12.0.0 --fail-on-error --author="$(git config --get user.name) <$(git config --get user.email)>"

# Create sbom from Cargo.lock and push to DependencyTrack.
dtrack DTRACK_API_KEY:
    docker run --rm --user=$(id -u):$(id -g) --volume=$PWD:$PWD --workdir=$PWD ghcr.io/cyclonedx/cdxgen-debian-rust:v12.0.0 --fail-on-error --author="$(git config --get user.name) <$(git config --get user.email)>" --server-url=https://dtrack.kokuwa.io --api-key={{ DTRACK_API_KEY }} --project-id=594d7129-9099-4f53-a284-8eccbbf35d2a
