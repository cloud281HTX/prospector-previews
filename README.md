# Prospector — GitHub Pages Preview Hosting

Static preview hosts for the Prospector agent's outreach pipeline, deployed to
GitHub Pages using **OIDC** (short-lived per-run tokens — no long-lived Pages
secret stored anywhere).

## Architecture

```
[prospector / any bot]  --SSH deploy key (write, THIS repo only)-->  push to main
                                                                                |
                                                                                v
                                GitHub Actions (OIDC, ephemeral token) --> Pages deploy
```

- Static files: `public/` (one folder per batch name is fine; no build step)
- Workflow: `.github/workflows/deploy.yml`
- Push credential: SSH **deploy key** (`~/.ssh/sk-prospector-previews`) via the
  `github-prospector-previews` alias — writable to ONLY this one repo.
- Live URL: `https://<your-org-or-user>.github.io/prospector-previews/` (once Pages + repo name are set)

## Security model
- **Deploy:** `id-token: write` → ephemeral OIDC token per run. **No stored Pages credential.**
- **Push:** single-repo SSH deploy key. No web token exists on this machine, and
  the key cannot touch any other repo or org.
- Workflow uses `permissions: contents: read / pages: write / id-token: write`
  (minimal) and interpolates no untrusted event input.

## One-time setup (do this once, in ~3 min)

1. **Create a repo** named exactly `prospector-previews` under your existing
   account (public — required for free public Pages URLs).

2. **Add the deploy key** (write access):
   Repo → **Settings → Deploy keys → Add deploy key**
   - Title: `prospector-previews`
   - Key: paste the contents of `~/.ssh/sk-prospector-previews.pub`
   - **✓ Allow write access**
   This key is scoped to ONLY this repo — it cannot access any other repository
   or your account's orgs.

3. **Set the remote + push this folder** to `main`:
   ```
   cd ~/hermes-builds/prospector-previews
   git remote set-url origin git@github-prospector-previews:<YOUR_USERNAME>/prospector-previews.git
   git push -u origin main
   ```

4. **Enable Pages source = "GitHub Actions":**
   Repo → **Settings → Pages → Source → GitHub Actions** (click Save).
   This is a one-time, human step. Because the Actions `GITHUB_TOKEN` cannot
   *create* a Pages site (`administration:write` is structurally impossible for
   it), the source must be set once manually; every deploy *after* that uses the
   ephemeral OIDC token and needs no credential.

## To deploy a new batch (what the bot does)

```
cd ~/hermes-builds/prospector-previews
./prospector-deploy.sh ~/outreach/<batch>   # stages public/ + pushes via deploy key
```
(or exactly the old steps — `cp` previews into `public/`, then `git push` —
which also triggers the workflow.)

## Rotation
- **Deploy key:** rotate by generating a new `~/.ssh/sk-prospector-previews` and
  replacing the key at Repo → Settings → Deploy keys (remove the old one). Do
  this on any suspicion of compromise.
- **OIDC:** the Pages token self-rotates per run — nothing to rotate there.
