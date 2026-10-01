# jellyfin

Jellyfin with the [grpc-ffmpeg](https://github.com/CrystalNET-org/grpc-ffmpeg) client included as `ffmpeg` and `ffprobe`.

## Releases

Image tags are `<Jellyfin version>-<n>`, e.g. `12.1-1` or `10.11.11-1`; `n` counts the releases of the same Jellyfin version. Pushes to `main` build the `dev` tag.

Run the image with grpc-ffmpeg workers of the same ffmpeg major version as Jellyfin's own ffmpeg. Jellyfin chooses ffmpeg options by the version it detects, and if the workers are unreachable at startup, it detects its local ffmpeg instead:

| Image | Jellyfin's ffmpeg | grpc-ffmpeg worker |
|---|---|---|
| `12.1-1` and later | 8.x | `8.1.3-7.8` and later |
| up to `10.11.11-1` (no longer maintained) | 7.x | up to `7.1.4-7.7` |

Updates are released automatically:

1. Renovate opens PRs for new Jellyfin patch releases (one day after release) and new grpc-ffmpeg releases (one hour after release).
2. The PR pipeline test-builds the image for amd64 and arm64, and Renovate merges the PR once it passes. Jellyfin minor and major updates are left for manual review.
3. On `main`, `.woodpecker/auto_release.yaml` pushes the next tag once the dev build of the commit succeeded, if the Jellyfin or grpc-ffmpeg version differs from the latest release (`scripts/next-release-tag.sh`), and the tag pipeline builds and pushes the image.
