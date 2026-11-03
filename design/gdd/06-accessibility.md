# GDD — Accessibility

*Tidewrack — Fogline Games · source snapshot dated 2026-07-17 · gdd, a11y*

> Corrected repository copy based on the supplied source snapshot. Candidate findings refer to `8c9b1e40`. Later branch changes are identified separately. The distributed Steam build has not been matched to that commit.

## Committed design goals and implementation status

- **Adjustable text speed and an instant-reveal toggle.** The candidate uses a fixed 45 characters per second. Accept while a linear line is typing reveals the rest; another accept advances. Choice buttons unlock after reveal finishes. Settings exposes volume and fullscreen. Adjustable speed and a persistent instant-reveal setting remain design goals.
- **Full keyboard and gamepad navigation, including Settings.** June deferred gamepad support to full release. The later demo milestone included it. In `8c9b1e40`, six explicit joypad-only event lists replaced the default keyboard bindings, despite the configuration comment. Button 0 accepts, button 1 cancels, and stick axes 0/1 move. Back takes initial focus in Settings and the first unlocked dialogue choice takes focus. Enter prompts are hardcoded. Initial focus and action definitions alone do not establish end-to-end navigation or device-specific glyphs.
- **Readable interactions without reliance on colour alone.** Preserve the low-saturation coastal palette and shape-plus-text direction. The ground-floor interactables have visible markers and labels and the HUD shows text. Verify contrast on lit tiles and discoverability on the rendered build.
- **No timed inputs.** Retain the no-fail-state design. The ground-floor choice path waits for a selection after text reveal. Whole-game accessibility has not been tested.

## Later branch correction

`f554a9e6` explicitly binds Enter, keypad Enter and Space to accept, Escape to cancel, and the four arrow keys to movement alongside the existing joypad events. Project configuration and deadzones were checked statically. KB-01 tracks this keyboard regression separately from controller coverage and missing glyphs. In Godot, test each device from title through Settings, choice focus, pause and resume; check prompts and long-line layout at 1080p. The distributed build remains unidentified.

## Backlog

Subtitle background opacity slider; remappable controls. Original tracker reference: `../TODO.md`.
