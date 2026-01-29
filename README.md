# Bitcoind for Docker (BIP-110 UASF)

[![Build and Push Docker Image](https://github.com/gorunjinian/bitcoind-truenas-bip110/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/gorunjinian/bitcoind-truenas-bip110/actions/workflows/docker-publish.yml)

Docker image running **Bitcoin Knots v29.2.knots20251110+bip110-v0.1** with UASF BIP-110 support.

## What is BIP-110?

BIP-110 is a User Activated Soft Fork (UASF) proposal. This Docker image runs a Bitcoin Knots node that signals support for BIP-110. See the [full BIP-110 proposal](https://github.com/dathonohm/bips/blob/reduced-data/bip-0110.mediawiki) for details.

## Credits

- Original docker-bitcoind by [kylemanna](https://github.com/kylemanna/docker-bitcoind)
- TrueNAS optimizations by [Retropex](https://github.com/Retropex/docker-bitcoind-truenas)
- BIP-110 binaries by [dathonohm](https://github.com/dathonohm/bitcoin/releases)
- GPG signed by Luke Dashjr (same key as official Bitcoin Knots)

## Quick Start

### 1. Create a volume for blockchain data

```bash
docker volume create --name=bitcoind-data
```

### 2. Run the node

```bash
docker run -v bitcoind-data:/bitcoin/.bitcoin --name=bitcoind-node -d \
    -p 8333:8333 \
    -p 127.0.0.1:8332:8332 \
    ghcr.io/gorunjinian/bitcoind-truenas-bip110:latest
```

### 3. Verify the node is running

```bash
docker ps
docker logs -f bitcoind-node
```

### 4. Check version

```bash
docker exec bitcoind-node bitcoind --version
# Output: Bitcoin Knots daemon version v29.2.knots20251110+bip110-v0.1
```

## Docker Image

| Registry | Image |
|----------|-------|
| GitHub Container Registry | `ghcr.io/gorunjinian/bitcoind-truenas-bip110:latest` |

### Available Tags

- `latest` - Latest build from master branch
- `sha-xxxxxxx` - Specific commit builds

## Requirements

- Docker host with at least **500 GB** storage for blockchain
- At least **1 GB RAM** + 2 GB swap
- Supported architectures: `linux/amd64`, `linux/arm64`

## TrueNAS Deployment

Use the **Custom App** feature in TrueNAS SCALE:
1. Image: `ghcr.io/gorunjinian/bitcoind-truenas-bip110:latest`
2. Ports: `8333` (P2P), `8332` (RPC)
3. Volume: Mount persistent storage to `/bitcoin/.bitcoin`

## Documentation

Additional documentation in the [docs folder](docs).

## License

MIT License - see [LICENSE](LICENSE)
