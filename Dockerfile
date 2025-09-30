FROM rust:1.90.0-slim-bookworm@sha256:fabcc911fbe27596d0fd98e578a977636c0da1965e919304f82968ed27f4f02f AS build
SHELL ["/usr/bin/bash", "-u", "-e", "-o", "pipefail", "-c"]
WORKDIR /build

RUN --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
	--mount=type=cache,target=/var/lib/dpkg \
	--mount=type=tmpfs,target=/var/cache \
	--mount=type=tmpfs,target=/var/log \
	apt-get -qq update && \
	apt-get -qq install --yes --no-install-recommends musl-tools=* musl-dev=*

ARG TARGETARCH
ARG RUSTUP_DIST_SERVER
ARG RUSTUP_UPDATE_ROOT

RUN [[ $TARGETARCH == amd64 ]] && export ARCH=x86_64-unknown-linux-musl; \
	[[ $TARGETARCH == arm64 ]] && export ARCH=aarch64-unknown-linux-musl; \
	[[ -z ${ARCH:-} ]] && echo "Unknown arch: $TARGETARCH" && exit 1; \
	rustup target add "$ARCH" && \
	mkdir .cargo && echo -e "[build]\ntarget = \"$ARCH\"\n\n[target.aarch64-unknown-linux-musl]\nlinker = \"aarch64-linux-gnu-gcc\"" > .cargo/config.toml

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
