---
type: master-requirements
name: docker-actions
org: agent-ix
component_type: github-actions
implementation_language: none
depends_on: []
standards_alignment: []
---

# Master Requirements Specification

## Purpose

Docker Actions is a collection of reusable composite GitHub Actions that standardize how the Agent-IX ecosystem builds, pushes, pulls, and publishes container images and Helm charts in CI. Its purpose is to centralize the authentication, metadata handling, caching, and registry-summary logic that would otherwise be duplicated across every repository's workflow. By exchanging a standardized `image.json` metadata artifact between steps, the actions let pipelines describe an image once (registry, repository, tag, URL, description, source, version) and then build, pull, or summarize it consistently. This master requirements specification defines the boundary, behavior, and requirement classes for the action set so that consumer repositories can rely on a stable, well-understood CI building block.

## Scope

### In Scope

- Composite GitHub Actions delivered from this repository, each defined by an `action.yml`:
  - `create-metadata` — generates a standardized `image.json` metadata file and exposes its fields as step outputs.
  - `load-metadata` — downloads an `image.json` artifact and re-exposes its fields as outputs.
  - `build` — authenticates to a Docker registry, builds and pushes an image (with registry-based build caching and OCI labels), and emits a GHCR summary.
  - `pull` — authenticates and pulls an image described by an `image.json` artifact.
  - `ghcr-docker-summary` — resolves a GHCR image's internal ID via the GitHub API and writes a Markdown summary to `$GITHUB_STEP_SUMMARY`.
  - `helm-publish` — packages and pushes a Helm chart to an OCI-compatible registry and records `helm.json` chart metadata.
- The `image.json` / `helm.json` metadata contract exchanged between actions and consumer workflows.
- Registry authentication using caller-supplied credentials and tokens.

### Out of Scope

- The CI workflow definitions of consumer repositories that invoke these actions.
- Provisioning or administration of the container/Helm registries themselves.
- Application source code, Dockerfiles, or Helm charts owned by consumer repositories.
- Secret management; credentials and `GITHUB_TOKEN` are supplied by the calling workflow.

## System Overview

Docker Actions is packaged as a single repository of independent composite actions, each in its own directory with an `action.yml`. Consumer workflows reference them by path (for example `uses: ./build`) and pass registry credentials, a `GITHUB_TOKEN`, and an artifact name as inputs.

The actions are coordinated through a shared metadata artifact:

- `create-metadata` produces an `image.json` describing the target image (registry, repository, image, tag, url, description, source, version).
- `build`, `pull`, and `load-metadata` consume that artifact, so the image is described once and reused across steps.
- `build` logs in to the registry, builds and pushes via `docker/build-push-action` with `cache-from`/`cache-to` registry caching and OCI labels, then calls `ghcr-docker-summary`.
- `ghcr-docker-summary` queries the GitHub API (via `get_image_id.sh`) to resolve the internal GHCR image ID and writes a pull-command summary.
- `helm-publish` reads `Chart.yaml`, logs in with `helm registry login`, packages with `helm package`, pushes with `helm push` to `oci://<registry>/<repository>`, and writes `helm.json`.

There is no runtime service or compiled artifact; the implementation language is shell within composite GitHub Action steps, and behavior is exercised entirely inside GitHub Actions runners.

## Requirements Architecture

Requirements for Docker Actions are organized into the following classes:

### Functional Requirements (FR)

The per-action input/output contracts and behaviors: metadata generation and loading, registry authentication, image build/push with caching, image pull, GHCR summary generation, and Helm chart packaging and publishing.

### Non-Functional Requirements (NFR)

Quality attributes such as build-cache effectiveness (registry-backed `cache-from`/`cache-to`), determinism of the `image.json`/`helm.json` contract, and portability across OCI-compatible registries (defaulting to GHCR).

### Interface Requirements

The metadata artifact schema (`image.json`, `helm.json`) and the GitHub Actions input/output surface of each composite action, which together form the integration contract with consumer workflows.

## References

- `README.md` — authoritative description of each action's inputs, outputs, behavior, caching strategy, and usage patterns.
- `build/action.yml`, `pull/action.yml`, `create-metadata/action.yml`, `load-metadata/action.yml`, `ghcr-docker-summary/action.yml`, `helm-publish/action.yml` — the composite action definitions implementing the requirements above.
- GitHub Actions composite action documentation and `docker/build-push-action` for the underlying build/push and caching primitives.
