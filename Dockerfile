# renovate: datasource=github-releases depName=jellyfin/jellyfin extractVersion=^v(?<version>.*)$ versioning=loose
ARG JELLYFIN_VERSION=12.1
# renovate: datasource=github-releases depName=CrystalNET-org/grpc-ffmpeg versioning=loose
ARG GRPC_FFMPEG_VERSION=8.1.3-8.1

FROM docker.io/jellyfin/jellyfin:${JELLYFIN_VERSION}

ARG JELLYFIN_VERSION
ARG GRPC_FFMPEG_VERSION
# Set by buildx for each target platform (amd64 or arm64)
ARG TARGETARCH

RUN sed -i 's/Components: main/Components: main contrib non-free/' /etc/apt/sources.list.d/debian.sources

# Static grpc-ffmpeg client; it runs the binary it is invoked as, so it is
# installed as both ffmpeg and ffprobe
ADD --chmod=755 https://github.com/CrystalNET-org/grpc-ffmpeg/releases/download/${GRPC_FFMPEG_VERSION}/grpc-ffmpeg-client-${TARGETARCH} /usr/local/bin/grpc-ffmpeg-client
RUN ln -s grpc-ffmpeg-client /usr/local/bin/ffmpeg && \
    ln -s grpc-ffmpeg-client /usr/local/bin/ffprobe

RUN mkdir -p /run/shm /media

RUN apt-get update && apt-get install -y \
    openssh-client \
    python3-click \
    python3-yaml \
    libssl3t64 \
    libc-bin \
    ca-certificates \
    wget \
    sqlite3 \
    strace


RUN groupadd -g 64710 jellyfin && \
    useradd -r -m -p '' -u 64710 -g 64710 -s "" -c 'User' jellyfin

EXPOSE 8096
VOLUME /config

ENTRYPOINT [ "/jellyfin/jellyfin", "--datadir", "/data", "--configdir", "/config", "--cachedir", "/cache", "--ffmpeg", "/usr/local/bin/ffmpeg" ]

LABEL org.opencontainers.image.source="https://github.com/CrystalNET-org/jellyfin"
