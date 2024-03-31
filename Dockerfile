# syntax=docker/dockerfile:1

FROM rust:1.76.0-alpine3.19 as builder
ARG TARGETOS
ARG TARGETARCH

WORKDIR /app
RUN apk add --no-cache \
  build-base libressl-dev ca-certificates sccache mold \
  && update-ca-certificates

COPY Cargo.toml Cargo.lock ./
COPY src/ ./src/
RUN  --mount=type=secret,id=SCCACHE_ENDPOINT \
     --mount=type=secret,id=SCCACHE_AWS_ACCESS_KEY_ID \
     --mount=type=secret,id=SCCACHE_AWS_SECRET_ACCESS_KEY \
     <<EOF
set -e
SCCACHE_BUCKET=suterobot \
SCCACHE_REGION=auto \
SCCACHE_S3_KEY_PREFIX=${TARGETOS}_${TARGETARCH} \
SCCACHE_S3_USE_SSL=true \
SCCACHE_IDLE_TIMEOUT=3600 \
SCCACHE_S3_NO_CREDENTIALS=false \
SCCACHE_S3_SERVER_SIDE_ENCRYPTION=false \
SCCACHE_ENDPOINT=$(cat /run/secrets/SCCACHE_ENDPOINT) \
AWS_ACCESS_KEY_ID=$(cat /run/secrets/SCCACHE_AWS_ACCESS_KEY_ID) \
AWS_SECRET_ACCESS_KEY=$(cat /run/secrets/SCCACHE_AWS_SECRET_ACCESS_KEY) \
sccache --start-server
CARGO_INCREMENTAL=0 \
RUSTC_WRAPPER=sccache \
mold -run cargo build --locked --release
cp ./target/release/suterobot /bin/server
sccache --stop-server
EOF

FROM alpine:3.19 as final
COPY --from=builder /bin/server /bin/
CMD ["/bin/server"]
