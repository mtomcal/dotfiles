---
name: gameplay-asset-imagegen
description: Generate and integrate game-ready raster assets with available image-generation tools, including sprites, tiles, props, pickups, effects, and decal sheets. Use when a game prototype needs new or replacement bitmap runtime assets, chroma-key extraction, generated-source traceability, synchronized consumers, or readability checks at gameplay scale.
metadata:
  short-description: Generate game-ready raster assets
allowed-tools: read,write,edit,bash
---

# Gameplay Asset Imagegen

## Language Definitions

- **Generated source** — original generated image retained for traceability and transformation, not direct runtime loading.
- **Runtime asset** — processed game-consumed file satisfying manifest, dimensions, alpha, naming, and placement.
- **Chroma-key background** — uniform color excluded from the subject and removed for transparency.
- **Matte spill** — residual background color contaminating subject edges.
- **Gameplay scale** — rendered size and camera or UI context where the player must recognize the asset.

## Workflow

Use this workflow when generated images must become runtime game assets rather than preview art.

### 1. Load the asset contract and route generation

Read the asset manifest or loader, asset README or docs, tests asserting paths/dimensions/alpha/metadata, and any visual reference. Treat concept or reference art as a target, not a sprite sheet: do not crop runtime assets from it unless the project explicitly authorizes that use.

For requested new bitmap art, use a raster image-generation tool or skill available in the active harness, such as `imagegen` or `image_gen` when exposed. If none is available, stop and ask the user to provide generated bitmap source or continue in a capable environment. Do not substitute procedural, vector, HTML/CSS, or other code-native placeholders, and do not claim generation is complete.

Completion criterion: the required asset contract, reference authorization, and executable generation route are known.

### 2. Generate and retain traceable sources

Generate orthographic or camera-appropriate framing that matches the game. Use the chroma-key Activity for sprites requiring transparency. Prefer a single image for a precise replacement; request a sheet only when the project has a clear slicing plan.

Move or copy each selected generated source into a traceable project location, such as `assets/.../generated-sources/`, and record source provenance where the project contract requires it. Keep it separate from every runtime output.

Completion criterion: every selected source exists in a project-local traceable location and no generated source is treated as the runtime asset.

### 3. Produce and check runtime assets

Apply every transformation required by the asset contract:

- Crop or slice sheets into named files according to the approved slicing plan.
- Remove flat chroma-key backgrounds and verify an alpha channel, transparent corners, nonblank subject coverage, and no visible key-color fringe.
- Resize to the expected dimensions and check collision, placement, UI, and animation contracts.
- Preserve transparent padding when placement depends on it.

Inspect transformation output for shrinkage or recentering before accepting placement. Reject or correct any runtime asset that fails its alpha, dimensions, coverage, fringe, padding, naming, or placement contract.

Completion criterion: each runtime asset is separate from its source and passes all applicable transformation checks.

### 4. Synchronize every consumer

Keep runtime filenames stable unless the consuming manifest changes. Store runtime art in the project; never load it from sibling repositories, temporary folders, or a generator's default output location.

Update the manifest, loader, docs, and tests together. Tests must continue to guard applicable dimensions, paths, source provenance, and runtime-manifest completeness.

Completion criterion: the loader resolves every project-local runtime asset and all four consumer surfaces agree.

### 5. Validate in gameplay context

Inspect each asset against the real gameplay background for matte spill, including darker contamination that bright-fringe thresholds can miss. Render it at gameplay scale and verify held items, pickups, effects, decals, and HUD reuse remain recognizable; an asset sized for one use may be too small for another.

Run the project's visual validation after integration. When the game has a browser or video review path and the skill is available, route that evidence through `visual-qa`; return its evidence and limitations to the caller rather than claiming final acceptance.

Completion criterion: machine contracts and real-background gameplay-scale checks pass, and any browser/video evidence path and residual visual risk are reported.

## Activities

### Prompt a chroma-key source

Ask the selected image generator for framing that matches the game and use this prompt for a transparent sprite source:

```text
Create the requested game asset on a perfectly flat solid #00ff00 chroma-key background for background removal.
The background must be one uniform color with no shadows, gradients, texture, reflections, floor plane, or lighting variation.
Keep the subject fully separated from the background with crisp edges and generous padding.
Do not use #00ff00 anywhere in the subject.
No cast shadow, no contact shadow, no watermark, and no text unless explicitly requested.
```

Use a different key color when the subject needs green, and verify that the chosen key color does not occur in the subject. Prefer one asset for precise replacement and a sheet only when an explicit slicing plan exists.

Completion criterion: the generated source has camera-appropriate framing, a uniform non-conflicting key background, a fully separated subject, and enough padding for extraction.
