# jellyfin

Jellyfin with the [grpc-ffmpeg](https://github.com/CrystalNET-org/grpc-ffmpeg) client included as `ffmpeg` and `ffprobe`.

## Releases

Image tags are `<Jellyfin version>-<n>`, e.g. `10.11.11-1`; `n` counts the releases of the same Jellyfin version. Pushes to `main` build the `dev` tag.

Updates are released automatically:

1. Renovate opens PRs for new Jellyfin patch releases (one day after release) and new grpc-ffmpeg releases (one hour after release).
2. The PR pipeline test-builds the image for amd64 and arm64, and Renovate merges the PR once it passes. Jellyfin minor and major updates are left for manual review.
3. On `main`, `.woodpecker/auto_release.yaml` pushes the next tag if the Jellyfin or grpc-ffmpeg version differs from the latest release (`scripts/next-release-tag.sh`), and the tag pipeline builds and pushes the image.
