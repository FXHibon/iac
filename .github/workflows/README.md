# Reusable GitHub Actions Workflows

This directory contains reusable workflows for GitHub Actions.

## Reusable GitHub Action (Docker Build & Push)

This repository implements a reusable GitHub Actions workflow to build and push multi-platform (`amd64`/`arm64`) Docker images for your other projects.

### How to Use

Create a workflow file in your other repository (e.g., `.github/workflows/ci.yml`):

```yaml
name: Build and Push Service

on:
  push:
    branches:
      - master
    tags:
      - 'v*' # Trigger on SemVer version tags

jobs:
  docker-build-push:
    uses: fxhibon/iac/.github/workflows/docker-build-push.yml@master
    secrets:
      dockerhub_username: ${{ secrets.DOCKERHUB_USERNAME }}
      dockerhub_token: ${{ secrets.DOCKERHUB_TOKEN }}
```

### Secrets Setup
Make sure you store the following secrets under **Settings** -> **Secrets and variables** -> **Actions** in the calling repository:
- `DOCKERHUB_USERNAME`: Set to `fxhibon`.
- `DOCKERHUB_TOKEN`: Your Docker Hub Personal Access Token.

The workflow automatically names the image based on the caller repository's name and handles SemVer, branch, and commit-level tagging automatically. For detailed configuration, refer to [docker-build-push.yml](docker-build-push.yml).
