---
name: gameplay-asset-imagegen
description: Generate and integrate game-ready raster assets using imagegen, including sprites, tiles, props, pickups, effects, and decal sheets. Use when a game prototype needs new or replacement bitmap runtime assets, chroma-key sprite extraction, generated source traceability, manifest/test updates, or asset readability checks at gameplay scale.
metadata:
  short-description: Generate game-ready raster assets
allowed-tools: read,write,edit,bash
---

# Gameplay Asset Imagegen

Use this skill when generated images need to become runtime game assets, not just preview art. Route actual generation through the existing `imagegen` skill, then handle the game-specific integration contract.

## Quick Workflow

1. Load the project's asset contract first:
   - asset manifest or loader
   - asset README/docs
   - tests that assert paths, dimensions, alpha, or metadata
   - visual reference image, if one exists
2. Use `imagegen` for new bitmap art. Do not substitute procedural placeholders when the request asks for new art.
3. Save generated source images in a traceable project location, such as `assets/.../generated-sources/`.
4. Create runtime assets separately from sources:
   - crop or slice sheets into named files
   - remove flat chroma-key backgrounds for sprites
   - resize to the dimensions expected by the game
   - preserve transparent padding when placement depends on it
5. Update the manifest, loader, docs, and tests together.
6. Validate the asset in context at gameplay scale.

## Prompting For Runtime Assets

Ask imagegen for orthographic or camera-appropriate framing that matches the game. For transparent sprites, request a flat removable chroma-key background:

```text
Create the requested game asset on a perfectly flat solid #00ff00 chroma-key background for background removal.
The background must be one uniform color with no shadows, gradients, texture, reflections, floor plane, or lighting variation.
Keep the subject fully separated from the background with crisp edges and generous padding.
Do not use #00ff00 anywhere in the subject.
No cast shadow, no contact shadow, no watermark, and no text unless explicitly requested.
```

Use a different key color when the subject needs green. Prefer single assets for precise replacements and sheets only when the project already has a clear slicing plan.

## Integration Checklist

- Preserve the generated source separately from the runtime file.
- Keep runtime filenames stable unless the consuming manifest is updated.
- Validate alpha channels, transparent corners, nonblank subject coverage, and visible key-color fringe.
- Check asset dimensions against collision, placement, UI, or animation contracts.
- Inspect the asset against the real gameplay background; a sprite can pass alpha tests and still show matte spill.
- Size held items, pickups, effects, and decals for gameplay-camera readability, not only for source-image neatness.
- Update tests that guard dimensions, paths, source provenance, and runtime manifest completeness.
- Run the project's visual validation or the `visual-qa` skill after integration when the game has a browser or video review path.

## Common Gotchas

- Generated chroma-key sources can retain darker key-color spill even when bright-fringe thresholds pass.
- Generic background removal can shrink or recenter sprites in ways that break runtime placement.
- Pickup-sized sprites may be too small when reused as held weapons or HUD icons.
- Runtime art should not be loaded from sibling repos, temp folders, or default imagegen output locations.
- The concept/reference image is usually a target, not a sprite sheet. Do not crop runtime assets from it unless the project explicitly allows that.
