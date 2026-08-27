FROM docker.io/library/rust:1.98.0-slim-trixie@sha256:fb4b2f1dc68c06f46618948b09d0ade147e6d2b11a6581e599b0c808d5b8a167 AS build
SHELL ["/usr/bin/bash", "-u", "-e", "-o", "pipefail", "-c"]
WORKDIR /build

ARG TARGETARCH
RUN --mount=type=cache,target=/var/lib/apt/lists,sharing=locked,id=apt-$TARGETARCH  \
	--mount=type=cache,target=/var/lib/dpkg,id=dpkg-$TARGETARCH  \
	--mount=type=tmpfs,target=/var/cache \
	--mount=type=tmpfs,target=/var/log \
	apt-get -qq update && \
	apt-get -qq install --yes --no-install-recommends musl-tools=*

ARG RUSTUP_DIST_SERVER
ARG RUSTUP_UPDATE_ROOT
# hadolint ignore=SC3010,SC3037
RUN [[ $TARGETARCH == amd64 ]] && export ARCH=x86_64; \
	[[ $TARGETARCH == arm64 ]] && export ARCH=aarch64; \
	[[ -z ${ARCH:-} ]] && echo "Unknown arch: $TARGETARCH" && exit 1; \
	rustup target add "$ARCH-unknown-linux-musl" && \
	mkdir .cargo && echo -e "[build]\ntarget = \"$ARCH-unknown-linux-musl\"\n\n[target.$ARCH-unknown-linux-musl]\nlinker = \"$ARCH-linux-gnu-gcc\"" > .cargo/config.toml

COPY Cargo.lock Cargo.toml /build/
RUN --mount=type=cache,target=/build/target,id=cargo-registry-$TARGETARCH,sharing=locked \
	--mount=type=cache,target=/usr/local/cargo/registry,id=cargo-registry-$TARGETARCH \
	mkdir src && touch src/lib.rs && cargo build --locked --release --lib && rm -rf src

COPY src /build/src
RUN --mount=type=cache,target=/build/target,id=cargo-registry-$TARGETARCH,sharing=locked \
	--mount=type=cache,target=/usr/local/cargo/registry,id=cargo-registry-$TARGETARCH \
	cargo install --locked --bin=renovate-approve-bot --path .

FROM scratch
COPY --chmod=555 --from=build /usr/local/cargo/bin/renovate-approve-bot /renovate-approve-bot
ENTRYPOINT ["/renovate-approve-bot"]
USER 65354:65354
