# renovate: datasource=docker depName=jellyfin/jellyfin versioning=semver
ARG JELLYFIN_VERSION=10.9.11

FROM debian:bookworm-slim AS builder
ARG JELLYFIN_VERSION

# Setzen der Arbeitsverzeichnis im Container
WORKDIR /app

# Installieren von notwendigen Paketen
RUN apt-get update && apt-get install -y \
    git \
    python3 \
    python3-pip \
    protobuf-compiler \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip
RUN pip3 install --break-system-packages --upgrade pip

# Checkout latest master of grpc-ffmpeg
RUN git clone https://github.com/CrystalNET-org/grpc-ffmpeg.git && \
    mv grpc-ffmpeg/proto/ffmpeg.proto .

# Kompilieren der .proto-Datei für Python
RUN python3 -m pip install --break-system-packages grpcio grpcio-tools 
RUN python3 -m grpc_tools.protoc -I. --python_out=. --grpc_python_out=. ffmpeg.proto

FROM docker.io/jellyfin/jellyfin:${JELLYFIN_VERSION}

ARG JELLYFIN_VERSION

ENV FFMPEGOF_PROGRAM_LOG=/config/log \
    FFMPEGOF_DIRECTORIES_OWNER=64710 \
    FFMPEGOF_DIRECTORIES_GROUP=64710 \
    FFMPEGOF_REMOTE_USER=root \
    FFMPEGOF_DATABASE_PATH=/config/ffmpegof/db

RUN sed -i 's/Components: main/Components: main contrib non-free/' /etc/apt/sources.list.d/debian.sources

COPY --from=builder /app/grpc-ffmpeg/client/grpc-ffmpeg.py /usr/local/bin/grpc-ffmpeg.py
COPY --from=builder /app/ffmpeg* /usr/local/bin/

RUN chmod a+x /usr/local/bin/grpc-ffmpeg.py && \
    ln -s /usr/local/bin/grpc-ffmpeg.py /usr/local/bin/ffmpeg && \
    ln -s /usr/local/bin/grpc-ffmpeg.py /usr/local/bin/ffprobe

RUN mkdir -p /run/shm /media

RUN apt-get update && apt-get install -y \
    openssh-client \
    python3-click \
    python3-yaml \
    libssl3 \
    libc-bin \
    ca-certificates \
    wget \
    python3-pip

RUN pip3 install --break-system-packages --upgrade pip
RUN python3 -m pip install --break-system-packages grpcio grpcio-tools aiofiles


RUN groupadd -g 64710 jellyfin && \
    useradd -r -m -p '' -u 64710 -g 64710 -s "" -c 'User' jellyfin

EXPOSE 8096
VOLUME /config

ENTRYPOINT "/jellyfin/jellyfin" \
    "--datadir" "/data" \
    "--configdir" "/config" \
    "--cachedir" "/cache" \
    "--ffmpeg" "/usr/local/bin/ffmpeg"

LABEL org.opencontainers.image.source="https://github.com/CrystalNET-org/jellyfin"
