FROM rust:1.88.0-slim@sha256:4679aa0a88781517cbc33adeea4057d8a740eb4a07c43f3aaa63c26e35e9a65c AS build
SHELL ["/usr/bin/bash", "-u", "-e", "-o", "pipefail", "-c"]
WORKDIR /build

RUN --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
	--mount=type=cache,target=/var/lib/dpkg \
	--mount=type=tmpfs,target=/var/cache \
	--mount=type=tmpfs,target=/var/log \
	apt-get -qq update && \
	apt-get -qq install --yes --no-install-recommends musl-tools=* musl-dev=*

ARG RUSTUP_DIST_SERVER
ARG RUSTUP_UPDATE_ROOT

RUN [[ $(uname -m) == x86_64 ]] && export TARGET=x86_64-unknown-linux-musl; \
	[[ $(uname -m) == aarch64 ]] && export TARGET=aarch64-unknown-linux-musl; \
	[[ -z ${TARGET:-} ]] && echo "Unknown arch: $(uname -m)" && exit 1; \
	rustup target add "$TARGET" && \
	mkdir .cargo && echo -e "[build]\ntarget = \"$TARGET\"\n\n[target.aarch64-unknown-linux-musl]\nlinker = \"aarch64-linux-gnu-gcc\"" > .cargo/config.toml

COPY Cargo.lock Cargo.toml /build/
RUN --mount=type=cache,target=/build/target,sharing=locked \
	--mount=type=cache,target=/usr/local/cargo/registry \
	mkdir src && touch src/lib.rs && cargo build --locked --release --lib && rm -rf src

COPY src /build/src
RUN --mount=type=cache,target=/build/target,sharing=locked \
	--mount=type=cache,target=/usr/local/cargo/registry \
	cargo install --locked --bin=renovate-approve-bot --path .

FROM scratch
COPY --chmod=555 --from=build /usr/local/cargo/bin/renovate-approve-bot /renovate-approve-bot
ENTRYPOINT ["/renovate-approve-bot"]
USER 1000:1000
