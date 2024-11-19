ARG TARGETPLATFORM
ARG BUILDPLATFORM
# renovate: datasource=github-releases depName=jellyfin/jellyfin versioning=loose
ARG JELLYFIN_VERSION=10.10.3
ARG PROTOC_VERSION=28.2

FROM debian:bookworm-slim AS builder
ARG JELLYFIN_VERSION
ARG PROTOC_VERSION

# Setzen der Arbeitsverzeichnis im Container
WORKDIR /app

# Installieren von notwendigen Paketen
RUN apt-get update && apt-get install -y \
    git \
    curl \
    unzip \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN curl -LO https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-x86_64.zip && \
    unzip protoc-${PROTOC_VERSION}-linux-x86_64.zip -d /app/.local

# Upgrade pip
RUN pip3 install --break-system-packages --upgrade pip

# Checkout latest master of grpc-ffmpeg
RUN git clone https://github.com/CrystalNET-org/grpc-ffmpeg.git && \
    mv grpc-ffmpeg/proto/ffmpeg.proto .

# Kompilieren der .proto-Datei für Python
RUN python3 -m pip install --break-system-packages grpcio grpcio-tools 
RUN PATH="$PATH:$HOME/app/.local/bin" python3 -m grpc_tools.protoc -I. --python_out=. --grpc_python_out=. ffmpeg.proto

FROM docker.io/jellyfin/jellyfin:${JELLYFIN_VERSION}

ARG JELLYFIN_VERSION

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
    python3-pip \
    strace

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
