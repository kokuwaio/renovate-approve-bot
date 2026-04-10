FROM docker.io/library/rust:1.94.1-slim-trixie@sha256:cf09adf8c3ebaba10779e5c23ff7fe4df4cccdab8a91f199b0c142c53fef3e1a AS build
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
