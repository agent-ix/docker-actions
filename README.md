# 🛠 Docker Actions

> A set of composite GitHub Actions for authenticated Docker image builds, pulls, and registry summary output using metadata from `image.json`.

---

## 📆 Actions

### 🔨 `build`

**Path:** `build/action.yml`

Build and push a Docker image using metadata from an `image.json` artifact.

**Inputs:**

| Name                | Description                                | Required | Default      |
| ------------------- | ------------------------------------------ | -------- | ------------ |
| `registry_user`     | Username for Docker registry auth          | ✅        | —            |
| `registry_password` | Password/token for Docker registry         | ✅        | —            |
| `artifact`          | Name of the image metadata artifact (JSON) | ✅        | `image.json` |
| `GITHUB_TOKEN`      | GitHub token for `ghcr-docker-summary`     | ✅        | —            |
| `extra_build_args`  | Additional Docker build-args (newline-separated `KEY=VALUE` pairs) | ❌ | `""` |

**Behavior:**

- Downloads the `image.json` artifact and parses fields like `image`, `tag`, `url`, and `description`.
- Logs in to the Docker registry using provided credentials.
- Builds and pushes the Docker image using `docker/build-push-action` with:
  - `cache-from` and `cache-to` using `image:buildcache`
  - OCI labels for `version`, `description`, and `source`
- Outputs a summary using `ghcr-docker-summary`.

---

### 📥 `pull`

**Path:** `pull/action.yml`

Authenticate and pull a Docker image described in an `image.json` artifact.

**Inputs:**

| Name                | Description                                | Required | Default      |
| ------------------- | ------------------------------------------ | -------- | ------------ |
| `registry_user`     | Username for Docker registry auth          | ✅        | —            |
| `registry_password` | Password/token for Docker registry         | ✅        | —            |
| `artifact`          | Name of the image metadata artifact (JSON) | ❌        | `image.json` |

**Outputs:**

| Name  | Description                     |
| ----- | ------------------------------- |
| `url` | Fully-qualified image reference |

**Behavior:**

- Downloads the `image.json` artifact
- Extracts the `registry` and `url` fields
- Authenticates with the registry
- Pulls the image using `docker pull`

---

### 📄 `ghcr-docker-summary`

**Path:** `ghcr-docker-summary/action.yml`

Outputs a summary of a GHCR-hosted image and resolves its internal image ID using the GitHub API.

**Inputs:**

| Name           | Description                              | Required |
| -------------- | ---------------------------------------- | -------- |
| `repository`   | Image name in the form `org/image`       | ✅        |
| `tag`          | Tag to match in the registry             | ✅        |
| `GITHUB_TOKEN` | GitHub token for resolving GHCR metadata | ✅        |

**Outputs:**

| Name       | Description            |
| ---------- | ---------------------- |
| `image_id` | Internal GHCR image ID |

**Behavior:**

- Calls GitHub API via `get_image_id.sh` to retrieve the image's internal ID
- Writes a Markdown-formatted summary to `$GITHUB_STEP_SUMMARY`:
  - Image tag with registry link
  - Docker pull command in a code block

---

## 🧠 Caching Strategy

The `build` action enables build caching using:

```
cache-from: type=registry,ref=image:buildcache
cache-to: type=registry,ref=image:buildcache,mode=max
```

This leverages registry-based cache layers to accelerate rebuilds across CI runs.

---

## 🧰 Usage Pattern

These actions assume that your CI pipeline generates an `image.json` artifact before calling them. Example fields in `image.json`:

```json
{
  "registry": "ghcr.io",
  "repository": "agent-ix/my-service",
  "image": "ghcr.io/agent-ix/my-service",
  "tag": "1.2.3",
  "url": "ghcr.io/agent-ix/my-service:1.2.3",
  "description": "My Dockerized service",
  "source": "https://github.com/agent-ix/my-service",
  "version": "1.2.3"
}
```

---

## 🧑‍👷 Example Integration

```yaml
- uses: ./pull
  with:
    registry_user: ${{ secrets.REGISTRY_USER }}
    registry_password: ${{ secrets.REGISTRY_PASSWORD }}

- uses: ./build
  with:
    registry_user: ${{ secrets.REGISTRY_USER }}
    registry_password: ${{ secrets.REGISTRY_PASSWORD }}
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```
