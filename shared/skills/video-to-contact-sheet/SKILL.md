---
name: video-to-contact-sheet
description: Convert a recording into reviewable evidence such as trimmed clips, contact sheets, and focused crops. Use when the input is a browser demo, gameplay clip, Playwright WebM, screen recording, or local app video that needs frame-sampled review artifacts.
allowed-tools: Bash(ffmpeg:*) Bash(ffprobe:*) Bash(find:*) Bash(mkdir:*) Bash(ls:*) Bash(du:*) Bash(jq:*) Bash(sed:*) Bash(cat:*)
metadata:
  short-description: Turn recordings into contact sheets and review clips
---

# Video To Contact Sheet

Use this skill when a recording needs to become something a human or agent can scan quickly.

## Inputs

- A direct video path such as `demo.webm` or `recording.mov`
- An artifact directory that contains a recording plus optional structured evidence
- A browser-generated recording, including Playwright WebM output

## Workflow

1. Locate the evidence bundle.
   - Prefer the newest artifact directory when a runner produces one.
   - Inspect nearby JSON, NDJSON, or console logs before trimming so you understand the intended moment.
2. Probe the recording.
   - Run `ffprobe -v error -show_entries format=duration,size -show_streams "<video>"`.
   - Call out missing audio explicitly instead of assuming silence is a product bug.
3. Build a high-resolution overview first.
   - Example:

```bash
mkdir -p /tmp/video-review
ffmpeg -y -i "<video>" \
  -vf "fps=1/2,scale=640:-1,tile=3x3" \
  -frames:v 1 /tmp/video-review/contact.png
```

4. Trim dead time when startup frames hide the actual action.
   - Example:

```bash
ffmpeg -y -ss 1.5 -i "<video>" -c copy /tmp/video-review/review.webm
ffmpeg -y -i /tmp/video-review/review.webm \
  -vf "fps=1/2,scale=640:-1,tile=3x3" \
  -frames:v 1 /tmp/video-review/contact-trimmed.png
```

5. Create focused evidence for brief or small actions.
   - Higher-frequency contact sheet:

```bash
ffmpeg -y -ss 2.0 -t 2.0 -i "<video>" \
  -vf "fps=12,scale=480:-1,tile=6x4" \
  -frames:v 1 /tmp/video-review/focused.png
```

   - Cropped contact sheet:

```bash
ffmpeg -y -ss 2.0 -t 2.0 -i "<video>" \
  -vf "crop=420:260:760:320,fps=12,scale=420:-1,tile=6x4" \
  -frames:v 1 /tmp/video-review/crop.png
```

6. Hand the artifacts back to `visual-qa` or the active repo workflow for judgment.

## Review Rules

- Artifact existence is not enough; the contact sheet must show the meaningful behavior.
- If the visual complaint is attachment, occlusion, directional read, or any other fighter-scale issue, do not stop at the overview sheet. Generate a higher-resolution crop focused on the object under discussion.
- If the first sheet is black, blank, or all setup, trim and rebuild instead of arguing from the raw recording.
- Prefer a high-resolution overview for broad state coverage, then increase FPS or crop tighter around the interesting window.
- Keep the raw video as source evidence and point reviewers at the trimmed clip when it is more truthful.
- If logs say "pass" but the sampled frames still look wrong, preserve that mismatch in the report.
