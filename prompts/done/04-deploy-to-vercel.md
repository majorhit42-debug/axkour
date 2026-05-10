# 04 — Deploy to Vercel

> Before starting, read `CLAUDE.md` in the project root.

## Goal

Get axkour live on Vercel as a public URL. One-time setup; future deploys are just `git push` + a re-export.

## Approach

Build the HTML5 export locally → commit `builds/web/` to git → push to GitHub → Vercel serves the static files. **No build step on Vercel** — Godot can't run there, so we ship the build itself.

---

## Steps Todd Does First (Manual)

Do these **before** handing this prompt to Claude Code:

1. **Install Godot's HTML5 export templates** if you haven't already:
   - Godot Editor → top menu → Editor → Manage Export Templates
   - Click "Download and Install" for the version matching your editor
   - Wait for the download to complete

2. **Create a GitHub repository** (if it doesn't exist yet):
   - Go to https://github.com/new
   - Name: `axkour` (or whatever — this becomes part of the Vercel URL)
   - Public or private, your call
   - **Do not** initialize with a README — we already have files
   - Copy the SSH or HTTPS clone URL

3. **Have the GitHub clone URL ready** — paste it to Claude Code when it asks for it (step 7 below).

---

## Steps for Claude Code

### 1. Create `.gitignore`

Create `.gitignore` in the project root:

```
# Godot 4+ editor cache
.godot/

# Build outputs (we DO want builds/web/ committed — that's what Vercel serves)
builds/desktop/
builds/mobile/

# OS files
.DS_Store
Thumbs.db

# Editors
.vscode/
.idea/
```

**Important:** do NOT ignore `export_presets.cfg`. It's needed for reproducible exports.

### 2. Create `vercel.json`

Create `vercel.json` in the project root:

```json
{
  "outputDirectory": "builds/web",
  "headers": [
    {
      "source": "/(.*).wasm",
      "headers": [
        { "key": "Content-Type", "value": "application/wasm" }
      ]
    }
  ]
}
```

This tells Vercel: serve files from `builds/web/`, and make sure `.wasm` files get the correct MIME type for streaming compilation.

### 3. Verify the Web export preset

The "Web" preset was created in prompt 01. Confirm it's still configured:
- Open Project → Export
- Confirm a "Web" preset exists with Export Path `builds/web/index.html`
- Variant is Regular (single-threaded — the default in 4.3+)
- VRAM Texture Compression "For Mobile" is checked

If the preset is missing, recreate it per prompt 01.

### 4. Run the export

From the terminal in the project root:

```bash
mkdir -p builds/web
godot --headless --export-release "Web" builds/web/index.html
```

If `godot` isn't on your PATH, use the full path to the Godot binary, or do the export from the editor: Project → Export → select "Web" → Export Project → save to `builds/web/index.html`.

This produces about 6 files in `builds/web/`, all named `index.*` (`.html`, `.js`, `.wasm`, `.pck`, `.audio.worklet.js`, `.icon.png`). **Do not rename any of them** — Godot's loader expects these exact names.

### 5. Smoke-test locally

```bash
cd builds/web
python3 -m http.server 8000
```

Open http://localhost:8000 in Chrome or Firefox (Safari has known WebGL 2 issues with Godot exports). The game should load and play.

- **If it loads cleanly**: stop the server (Ctrl+C), `cd` back to project root, continue.
- **If it errors**: open the browser console, check the message. Most common: export templates missing (re-run step 1 of Todd's manual steps), or renderer not Compatibility (check Project Settings → Rendering).

### 6. Initial git commit

If git isn't initialized yet:
```bash
git init
git branch -M main
git add .
git commit -m "Bootstrap project: bootstrap, quiz gates, dont-touch-red, web build, Vercel config"
```

If git is already initialized:
```bash
git add .
git commit -m "Add web build and Vercel config"
```

### 7. Connect to GitHub

**Pause here and ask Todd for the GitHub clone URL** if you don't have it. Then:

```bash
git remote add origin <URL>
git push -u origin main
```

(If `origin` already exists, use `git remote set-url origin <URL>` instead of `add`.)

Confirm the push succeeded by checking the GitHub repo page in a browser — `builds/web/index.html` and friends should be visible.

---

## Steps Todd Does (Vercel Setup — One Time Only)

After Claude Code has pushed to GitHub:

1. Go to https://vercel.com/new
2. Find the `axkour` repo in the list, click "Import"
3. On the configure screen:
   - **Framework Preset**: `Other`
   - **Build Command**: leave blank
   - **Output Directory**: leave default (the `vercel.json` overrides it)
   - **Install Command**: leave blank
   - **Root Directory**: leave as `./`
4. Click "Deploy"
5. Wait ~30 seconds. Vercel gives you a URL like `axkour-xxxxx.vercel.app`.

### Verify it works
- Open the Vercel URL on your laptop
- Test: walk, jump, try a quiz gate, try a red tile
- If audio is silent: click anywhere on the game canvas (browser autoplay policy — first user gesture unlocks audio)
- Then open the URL on a phone — confirms it works on devices other than your dev machine

### Tell Claude Code the live URL
Paste the Vercel URL back to Claude Code so it can update CLAUDE.md.

---

## Final Step (Claude Code)

### 8. Update CLAUDE.md

Once Todd provides the URLs:
- Replace `[TODO: deploy to Vercel and add URL]` with the actual Vercel URL
- Replace `[TODO: add GitHub repo URL]` with the GitHub repo URL
- Under **Current Features**, add: "Deployed to Vercel — live at <URL>"

---

## Future Deploys (Reference — Not for This Prompt)

After this initial setup, the loop is:

```bash
# After making changes in Godot
godot --headless --export-release "Web" builds/web/index.html
git add .
git commit -m "Description of changes"
git push
```

Vercel auto-deploys within ~30 seconds of the push. No manual step needed.

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---|---|---|
| `Export templates not found` | Templates not installed | Editor → Manage Export Templates → Download |
| Game loads black/blank in browser | WebGL 2.0 unsupported, or Safari quirks | Try Chrome/Firefox. Verify Project Settings → Rendering → Compatibility renderer. |
| Audio silent | Browser autoplay policy | Click into the game canvas — first gesture unlocks Web Audio |
| Vercel "No output directory found" | Build files not pushed | `git ls-files builds/web/` should list them; if empty, redo step 6 |
| Mouse escapes game on click | Pointer Lock requires user gesture | Normal — click into the game to recapture |
| Game runs locally but blank on Vercel | `.wasm` MIME type wrong | Confirm `vercel.json` has the wasm header block from step 2 |

---

## Do NOT
- Do **not** rename any of the Godot-exported files (`index.html`, `index.js`, etc.) — Godot's loader expects those exact names.
- Do **not** add a `buildCommand` to `vercel.json` — there's no build step, Godot already built it locally.
- Do **not** commit the `.godot/` editor cache folder.
- Do **not** switch the renderer to Forward+ or Mobile to "improve graphics" — web export only supports Compatibility.
- Do **not** enable "Threading" in the Web export variant — needs special server headers we haven't set up.

## When Done
1. Live URL works on phone (not just dev machine)
2. Axel has tested it
3. CLAUDE.md updated with live URL and GitHub repo URL
4. Move this prompt file from `prompts/ready/` to `prompts/done/`
5. Commit the CLAUDE.md update and push (triggers an auto-deploy, harmless — just confirms the loop works)
