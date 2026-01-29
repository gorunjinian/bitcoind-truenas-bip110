# Use the latest available Ubuntu image as build stage
FROM ubuntu:latest AS builder

# Upgrade all packages and install dependencies
RUN apt-get update \
    && apt-get upgrade -y
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        wget \
        gnupg \
    && apt clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Set variables necessary for download and verification of bitcoind
ARG TARGETARCH
ARG ARCH
ARG VERSION=29.2.knots20251110+bip110-v0.1
ARG BITCOIN_CORE_SIGNATURE=1A3E761F19D2CC7785C5502EA291A2C45D0C504A
# Download from GitHub instead of bitcoinknots.org to get BIP110 UASF
ARG RELEASE_URL=https://github.com/dathonohm/bitcoin/releases/download/v29.2.knots20251110%2Bbip110-v0.1

# Don't use base image's bitcoin package for a few reasons:
# 1. Would need to use ppa/latest repo for the latest release.
# 2. Some package generates /etc/bitcoin.conf on install and that's dangerous to bake in with Docker Hub.
# 3. Verifying pkg signature from main website should inspire confidence and reduce chance of surprises.
# Instead fetch, verify, and extract to Docker image
RUN case ${TARGETARCH:-amd64} in \
    "arm64") ARCH="aarch64";; \
    "amd64") ARCH="x86_64";; \
    *) echo "Dockerfile does not support this platform"; exit 1 ;; \
    esac \
    && gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys ${BITCOIN_CORE_SIGNATURE} \
    && wget -q --show-progress --progress=dot:giga \
            ${RELEASE_URL}/SHA256SUMS.asc \
            ${RELEASE_URL}/SHA256SUMS \
            ${RELEASE_URL}/bitcoin-${VERSION}-${ARCH}-linux-gnu.tar.gz \
    && gpg --verify --status-fd 1 --verify SHA256SUMS.asc SHA256SUMS 2>/dev/null | grep "^\[GNUPG:\] VALIDSIG.*${BITCOIN_CORE_SIGNATURE}\$" \
    && sha256sum --ignore-missing --check SHA256SUMS \
    && tar -xzvf bitcoin-${VERSION}-${ARCH}-linux-gnu.tar.gz -C /opt \
    && ln -sv bitcoin-${VERSION} /opt/bitcoin \
    && /opt/bitcoin/bin/test_bitcoin --show_progress \
    && rm -v /opt/bitcoin/bin/test_bitcoin /opt/bitcoin/bin/bitcoin-qt

# Use latest Ubuntu image as base for main image
FROM ubuntu:latest AS final
LABEL author="Kyle Manna <kyle@kylemanna.com>" \
      maintainer="Seth For Privacy <seth@sethforprivacy.com>"

WORKDIR /bitcoin

# Set bitcoin user and group with static IDs
ARG GROUP_ID=1000
ARG USER_ID=1000
RUN userdel ubuntu \
    && groupadd -g ${GROUP_ID} bitcoin \
    && useradd -u ${USER_ID} -g bitcoin -d /bitcoin bitcoin

# Copy over bitcoind binaries
COPY --chown=bitcoin:bitcoin --from=builder /opt/bitcoin/bin/ /usr/local/bin/

# Upgrade all packages and install dependencies
RUN apt-get update \
    && apt-get upgrade -y
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends gosu \
    && apt clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy scripts to Docker image
COPY ./bin ./docker-entrypoint.sh /usr/local/bin/

# Enable entrypoint script
ENTRYPOINT ["docker-entrypoint.sh"]

# Set HOME
ENV HOME=/bitcoin

# Expose default p2p and RPC ports
EXPOSE 8332 8333

# Expose default bitcoind storage location
VOLUME ["/bitcoin/.bitcoin"]

CMD ["btc_oneshot"]
