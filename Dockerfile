FROM docker.io/library/rust:1.94.1-slim-trixie@sha256:a08d20a404f947ed358dfb63d1ee7e0b88ecad3c45ba9682ccbf2cb09c98acca AS build
SHELL ["/usr/bin/bash", "-u", "-e", "-o", "pipefail", "-c"]
WORKDIR /build

RUN --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
	--mount=type=cache,target=/var/lib/dpkg \
	--mount=type=tmpfs,target=/var/cache \
	--mount=type=tmpfs,target=/var/log \
	apt-get -qq update && \
	apt-get -qq install --yes --no-install-recommends musl-tools=*

ARG TARGETARCH
ARG RUSTUP_DIST_SERVER
ARG RUSTUP_UPDATE_ROOT

RUN [[ $TARGETARCH == amd64 ]] && export ARCH=x86_64; \
	[[ $TARGETARCH == arm64 ]] && export ARCH=aarch64; \
	[[ -z ${ARCH:-} ]] && echo "Unknown arch: $TARGETARCH" && exit 1; \
	rustup target add "$ARCH-unknown-linux-musl" && \
	mkdir .cargo && echo -e "[build]\ntarget = \"$ARCH-unknown-linux-musl\"\n\n[target.$ARCH-unknown-linux-musl]\nlinker = \"$ARCH-linux-gnu-gcc\"" > .cargo/config.toml

COPY Cargo.lock Cargo.toml /build/
RUN --mount=type=cache,target=/build/target,id=$TARGETARCH-target,sharing=locked \
	--mount=type=cache,target=/usr/local/cargo/registry,id=$TARGETARCH-registry \
	mkdir src && touch src/lib.rs && cargo build --locked --release --lib && rm -rf src

COPY src /build/src
RUN --mount=type=cache,target=/build/target,id=$TARGETARCH-target,sharing=locked \
	--mount=type=cache,target=/usr/local/cargo/registry,id=$TARGETARCH-registry \
	cargo install --locked --bin=renovate-approve-bot --path .

FROM scratch
COPY --chmod=555 --from=build /usr/local/cargo/bin/renovate-approve-bot /renovate-approve-bot
ENTRYPOINT ["/renovate-approve-bot"]
USER 65354:65354
