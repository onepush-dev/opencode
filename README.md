# OpenCode — the open-source AI coding agent in your browser, password-protected with a persistent workspace. Deploy on Railway with one click.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/TEMPLATE_CODE)

[OpenCode](https://opencode.ai) is the open-source AI coding agent (214k+ GitHub stars). It reads your code, edits files, runs commands and works with 75+ model providers. This template runs **OpenCode v1.19.3** as `opencode serve`: the API plus the **embedded web UI** on your Railway domain, behind a **generated password**. Your projects, sessions, provider logins and config live on a volume. Nothing needs to be filled in at deploy time, and it works without an API key: OpenCode's free Zen models (for example `big-pickle`) are ready on first boot.

## Why this template
- **Official build, current and pinned:** the image is the upstream `ghcr.io/anomalyco/opencode:1.19.3` (pinned by digest) with a thin layer on top. Nothing uses `latest`, and the auto-updater is off, so a redeploy never changes the version on you.
- **Ready for real coding work:** the upstream image is bare Alpine with only the `opencode` binary and ripgrep. It has no `git`, which OpenCode needs for repos and for its undo/snapshot feature, and no bash. This image adds `git`, `git-lfs`, `bash`, `openssh-client`, `curl`, `jq`, Node.js/npm and Python 3. It's built by GitHub Actions in this repo (`.github/workflows/image.yml`) for amd64 and arm64.
- **Never open to the internet:** `OPENCODE_SERVER_PASSWORD` is generated per deploy (`${{secret(32)}}`), so every page and API call needs HTTP basic auth. The entrypoint **refuses to start** if the password is empty. An agent that can run shell commands should never be public without auth.
- **Everything on one volume:** `/data/home` (config, `auth.json` provider logins, the sessions database, snapshots, git and ssh setup) and `/data/workspace` (your projects). Redeploys keep everything.
- **Binds correctly on Railway:** it listens on `0.0.0.0:$PORT` (4096). It doesn't use upstream's default `127.0.0.1` with a random port.

## Services
| Service | Source | Notes |
|---|---|---|
| opencode | image `ghcr.io/onepush-dev/opencode:1.19.3@sha256:9a248429018cfcec9e51416ae5e85c78c45bb6c4b9e61141d7f18e435bedd6a3` (built from `Dockerfile`, base `ghcr.io/anomalyco/opencode:1.19.3@sha256:6ebc13097f2381301220abe9d1b2a54f50cd1603a910dc1c66e93d8f2c4e8ebb`) | **public**, port `4096`, volume `/data`, healthcheck `/site.webmanifest` (the only unauthenticated path), no start command (the image entrypoint runs `opencode serve --hostname 0.0.0.0 --port $PORT` under `tini -s`) |

## Variables
| Variable | Template value | Notes |
|---|---|---|
| PORT | `4096` | Port for the public domain |
| OPENCODE_HOSTNAME | `0.0.0.0` | Bind address |
| OPENCODE_SERVER_USERNAME | `opencode` | Login username |
| OPENCODE_SERVER_PASSWORD | `${{secret(32, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")}}` | Login password. Copy it from the Variables tab |
| HOME | `/data/home` | Config, logins and sessions on the volume |
| OPENCODE_WORKSPACE | `/data/workspace` | Default project directory |
| OPENCODE_DISABLE_AUTOUPDATE | `true` | Stay on the pinned version |
| RAILWAY_DEPLOYMENT_DRAINING_SECONDS | `30` | Graceful shutdown time |
| ANTHROPIC_API_KEY | empty (optional) | Claude models |
| OPENAI_API_KEY | empty (optional) | GPT models |
| OPENROUTER_API_KEY | empty (optional) | Many models behind one key |
| GEMINI_API_KEY | empty (optional) | Gemini models |

Optional extras you can add later: `GIT_USER_NAME` and `GIT_USER_EMAIL` set the commit identity (applied on first boot only, unless one is already configured). `OPENCODE_ALLOW_NO_PASSWORD=true` lets the server start without a password, but only use that if the service has no public domain.

## First login
1. Open `https://<your-domain>`. The browser asks for a username and password: enter `opencode` and the `OPENCODE_SERVER_PASSWORD` from the service's **Variables** tab.
2. Open the `/data/workspace` project. You can start a session right away with a free OpenCode Zen model, or add a provider: paste a key into the variables above, or connect one from the web UI. Logins made in the UI are saved in `/data/home/.local/share/opencode/auth.json` on the volume.
3. To work on a repo, ask the agent to clone it into `/data/workspace` (`git` and `ssh` are installed). For private GitHub repos, generate a key in the agent's shell (`ssh-keygen -t ed25519`) and add the public key to GitHub. It's stored in `/data/home/.ssh`.

### Use it from your terminal too
The same server works with the OpenCode TUI and SDK:
```bash
opencode attach https://<your-domain> --username opencode --password <OPENCODE_SERVER_PASSWORD>
```
The API is documented at `https://<your-domain>/doc` (OpenAPI, needs auth). Health check (needs auth): `GET /global/health` → `{"healthy":true,"version":"1.19.3"}`.

## Notes
- Run **one replica**. Sessions are stored in a SQLite database on the volume.
- Keep **serverless sleeping off** if you run long agent tasks, because sleeping stops running sessions.
- The agent runs commands as root inside the container. It is isolated to this service and volume, but treat the password like an SSH key.
- **Upgrading:** change the base digest in `Dockerfile` and `OPENCODE_VERSION` in the workflow, push (CI publishes `ghcr.io/onepush-dev/opencode:<version>`), then point the service at the new digest. The volume carries over.
- Upstream: https://github.com/anomalyco/opencode (formerly sst/opencode) · Docs: https://opencode.ai/docs/server/ · Release: https://github.com/anomalyco/opencode/releases/tag/v1.19.3
