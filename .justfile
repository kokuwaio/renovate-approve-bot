# https://just.systems/man/en/

[private]
@default:
	just --list --unsorted

# Run linter.
@lint:
	cargo fmt --all --
	docker run --rm --read-only --volume=$(pwd):$(pwd):ro --workdir=$(pwd) kokuwaio/hadolint
	docker run --rm --read-only --volume=$(pwd):$(pwd):ro --workdir=$(pwd) kokuwaio/yamllint
	docker run --rm --read-only --volume=$(pwd):$(pwd):rw --workdir=$(pwd) kokuwaio/markdownlint --fix
	docker run --rm --read-only --volume=$(pwd):$(pwd):ro --workdir=$(pwd) kokuwaio/renovate-config-validator
	docker run --rm --read-only --volume=$(pwd):$(pwd):ro --workdir=$(pwd) woodpeckerci/woodpecker-cli lint

# Build binary run.
run TOKEN_FILE:
	cargo build
	./target/debug/renovate-approve-bot --host=https://git.kokuwa.io --token-file {{TOKEN_FILE}}

# Build image with local docker daemon and run.
docker TOKEN_FILE:
    docker build . --tag=kokuwaio/kokuwaio/renovate-approve-bot:dev --build-arg=RUSTUP_UPDATE_ROOT --build-arg=RUSTUP_DIST_SERVER
    docker run --rm -it --read-only --user=1000:1000 --volume={{TOKEN_FILE}}:/token:ro kokuwaio/kokuwaio/renovate-approve-bot:dev --host=https://git.kokuwa.io --token-file=/token

# Inspect image layers with `dive`.
dive TARGET="":
	dive build . --target={{TARGET}} --build-arg=RUSTUP_UPDATE_ROOT --build-arg=RUSTUP_DIST_SERVER

# Create sbom from Cargo.lock.
sbom:
	docker run --rm --user=$(id -u):$(id -g) --volume=$PWD:$PWD --workdir=$PWD ghcr.io/cyclonedx/cdxgen-debian-rust:v11.4.3 --fail-on-error --author="$(git config --get user.name) <$(git config --get user.email)>" --output sbom.json

# Create sbom from Cargo.lock and push to DependencyTrack.
dtrack DTRACK_API_KEY:
	docker run --rm --user=$(id -u):$(id -g) --volume=$PWD:$PWD --workdir=$PWD ghcr.io/cyclonedx/cdxgen-debian-rust:v11.4.3 --fail-on-error --author="$(git config --get user.name) <$(git config --get user.email)>" --server-url=https://dtrack.kokuwa.io --api-key={{DTRACK_API_KEY}} --project-id=594d7129-9099-4f53-a284-8eccbbf35d2a
	