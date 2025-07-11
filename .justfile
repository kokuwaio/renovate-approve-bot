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
run:
	cargo build
	./target/debug/renovate-approve-bot foo bar

# Build image with local docker daemon and run.
docker:
    docker build . --tag=kokuwaio/kokuwaio/renovate-approve-bot:dev
    docker run --rm -it --read-only --user=1000:1000 kokuwaio/kokuwaio/renovate-approve-bot:dev foo bar

# Inspect image layers with `dive`.
dive TARGET="":
	dive build . --target={{TARGET}}
