---
name: video-to-contact-sheet
description: Convert a recording into reviewable evidence such as trimmed clips, contact sheets, and focused crops. Use when the input is a browser demo, gameplay clip, Playwright WebM, screen recording, or local app video that needs frame-sampled review artifacts.
allowed-tools: Bash(ffmpeg:*) Bash(ffprobe:*) Bash(find:*) Bash(mkdir:*) Bash(ls:*) Bash(du:*) Bash(jq:*) Bash(sed:*) Bash(cat:*)
metadata:
  short-description: Turn recordings into contact sheets and review clips
---

# Video To Contact Sheet

## Language Definitions

- **Source evidence** — original recording and structured evidence preserved unchanged.
- **Contact sheet** — chronological sampled-frame grid.
- **Overview contact sheet** — low-frequency full-timeline sampling.
- **Focused evidence** — trimmed, higher-frequency, or cropped artifact isolating hard-to-review behavior.

## Workflow

1. **Route and preserve the input.** Accept a direct video path, an artifact directory containing a recording and optional structured evidence, or a browser-generated recording such as Playwright WebM output. For runner output, prefer the newest artifact directory. Resolve one readable video with `find`/`ls`, record the caller's intended moment and audio expectation, and inspect nearby JSON with `jq` plus NDJSON, console logs, and other text evidence with `sed` or `cat` before transforming anything. Keep all source evidence unchanged and put generated files in a separate output directory. Stop if no unambiguous readable video can be found. This step is complete when the source path, relevant nearby evidence paths, intended moment, and audio expectation are recorded.

2. **Probe before selecting a transformation.** Run:

   ```bash
   ffprobe -v error -show_entries format=duration,size -show_streams "<video>"
   ```

   Record duration, file size, stream inventory, video dimensions and codec, and whether an audio stream exists. Stop if probing fails, duration is not positive, or no usable video stream exists. Disclose missing audio as an artifact limitation; do not call silence a product bug unless independent capture evidence establishes that audio was expected and missing. This step is complete when the transformation parameters can be checked against the probe.

3. **Build an overview first, then select focused evidence from visible frames.** Run the Overview Activity for broad state coverage and inspect the sheet; file existence alone does not prove meaningful behavior. Then branch as needed:
   - If frames are black, blank, setup-only, or startup obscures the action, run the Trim Activity and rebuild the sheet from the trimmed clip.
   - If the behavior is brief or transient, run the High-frequency Activity over the observed window.
   - If the behavior is small, occluded, hard to read, or concerns attachment, directional read, motion, or another fighter-scale issue, run the Crop Activity and increase crop resolution if needed.

   Choose start time, duration, frame rate, and crop bounds from the overview and probe rather than guessing. Combine trim, frequency, and crop escalation when one alone remains misleading. This step is complete only when the selected artifact visibly shows the meaningful behavior at a readable scale; otherwise adjust and rebuild.

4. **Return evidence without claiming acceptance.** Preserve any machine/visual mismatch: when structured evidence says “pass” but sampled frames look wrong, report both without silently favoring either. Return to `visual-qa` or the caller one compact line for every source-evidence and generated-artifact path used: `<path> — <purpose> — <limitations or none observed>`. Include missing audio, sample interval, omitted timeline regions, crop bounds, stream-copy trim imprecision, and machine/visual mismatch when applicable. Identify a trimmed clip as the more truthful review surface when startup makes the raw recording misleading, but always include the raw source path. Completion requires every path, purpose, and limitation needed for downstream judgment; final acceptance remains with the caller or human.

## Activities

### Overview contact sheet

Use this first or whenever a low-frequency full-timeline view is independently useful.

```bash
video="<video>"
output_dir="<output-directory>"
mkdir -p "$output_dir"
duration=$(ffprobe -v error -show_entries format=duration \
  -of default=noprint_wrappers=1:nokey=1 "$video")
ffmpeg -y -i "$video" \
  -vf "fps=9/${duration},scale=640:-1,tile=3x3" \
  -frames:v 1 "$output_dir/contact.png"
ls -lh "$output_dir/contact.png"
du -h "$output_dir/contact.png"
```

Use only the positive numeric duration established by the probe; `9/<duration>` distributes at most nine samples across the timeline instead of silently covering only the beginning of a long source. Keep output separate from the source. Stop on a failed command or missing/empty image. Inspect chronological coverage and meaningful behavior before calling the Activity complete; route blank, setup-only, or unreadable evidence back to Workflow selection.

### Trimmed clip and rebuilt sheet

Use when observed startup or dead time obscures the meaningful action.

```bash
video="<video>"
output_dir="<output-directory>"
start=1.5
mkdir -p "$output_dir"
trimmed="$output_dir/review.${video##*.}"
ffmpeg -y -ss "$start" -i "$video" -c copy "$trimmed"
trim_duration=$(ffprobe -v error -show_entries format=duration \
  -of default=noprint_wrappers=1:nokey=1 "$trimmed")
ffmpeg -y -i "$trimmed" \
  -vf "fps=9/${trim_duration},scale=640:-1,tile=3x3" \
  -frames:v 1 "$output_dir/contact-trimmed.png"
ls -lh "$trimmed" "$output_dir/contact-trimmed.png"
du -h "$trimmed" "$output_dir/contact-trimmed.png"
```

Set `start` from observed frames and use a leading zero for fractional values below one second. Keep a source-compatible filename extension and never overwrite the raw recording. Stream copy may start at an earlier keyframe: inspect the actual first frame and duration, and adjust the seek or choose an explicitly compatible re-encoded output when an exact cut is required. Stop on incompatible streams/containers, failed commands, or missing/empty outputs. Complete only when the rebuilt sheet removes misleading startup and shows the intended action; report keyframe imprecision as a limitation.

### High-frequency contact sheet

Use for a brief or transient action whose window is known from overview evidence.

```bash
video="<video>"
output_dir="<output-directory>"
start=2.0
window=2.0
mkdir -p "$output_dir"
ffmpeg -y -ss "$start" -t "$window" -i "$video" \
  -vf "fps=12,scale=480:-1,tile=6x4" \
  -frames:v 1 "$output_dir/focused.png"
ls -lh "$output_dir/focused.png"
du -h "$output_dir/focused.png"
```

Keep `start` and `window` inside the probed duration. A 6x4 tile holds 24 frames, so keep `fps × window` at or below 24 or deliberately change the grid; the defaults cover two seconds at 12 FPS. Stop on a failed command or missing/empty image. Inspect event order and readability before completion, and report sampling gaps that could hide the behavior.

### Cropped contact sheet

Use when the important action is too small or occluded in the full frame.

```bash
video="<video>"
output_dir="<output-directory>"
start=2.0
window=2.0
crop_width=420
crop_height=260
x=760
y=320
mkdir -p "$output_dir"
ffmpeg -y -ss "$start" -t "$window" -i "$video" \
  -vf "crop=${crop_width}:${crop_height}:${x}:${y},fps=12,scale=420:-1,tile=6x4" \
  -frames:v 1 "$output_dir/crop.png"
ls -lh "$output_dir/crop.png"
du -h "$output_dir/crop.png"
```

Derive the window and `crop=w:h:x:y` from visible evidence and probed dimensions. Before running, require nonnegative coordinates, positive crop size, `x + crop_width <= video width`, `y + crop_height <= video height`, and `fps × window <= 24`. Keep output separate from the source. Stop on a failed command or missing/empty image. Inspect the object, attachment, occlusion, direction, motion, and readability; tighten or increase crop resolution until the focused behavior is meaningful, and report context excluded by the crop.
