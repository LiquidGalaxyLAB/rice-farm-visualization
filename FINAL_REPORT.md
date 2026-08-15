# Rice Farm Agriculture India Visualization — GSoC 2026 Final Report

**Contributor:** Vinayak Dhaka  
**Organization:** Liquid Galaxy Lab  
**Mentors:** Vedant Singh, Dev Gandani  
**Program:** Google Summer of Code 2026  
**Repository:** https://github.com/LiquidGalaxyLAB/rice-farm-visualization  
**Go Store:** https://store.liquidgalaxy.eu/index.html?app=Rice%20Farm%20Agriculture

---

## Project Goals

Build a Flutter controller application for the Liquid Galaxy multi-screen rig that visualizes India's rice agriculture on Google Earth. The app turns rice production statistics, seasonal crop cycles, irrigation and rainfall data, and guided narrated tours into an immersive multi-screen experience, fully controllable from a phone over SSH.

<div align="center">
  <img width="900" src="https://github.com/user-attachments/assets/120d3365-fa41-4a4b-bbc1-952a777b27fd" />
</div>

## What I Did

### 🌾 Colored 3D Production Visualization

Extruded polygon KMLs for all Indian states, color-scaled by rice output, rendered across every screen of the rig.

<div align="center">
  <img width="800" src="https://github.com/user-attachments/assets/341ce21b-598a-471a-b0af-c7ff5dc287e7" />
</div>

### 📍 Major Rice Regions

Fly-to any state with TTS narration, a full 360° orbit camera, and a production-tier color scale (green → blue → orange → red).

<div align="center">
  <img width="800" src="https://github.com/user-attachments/assets/aef93583-c4c1-41de-8a09-6d67bf170729" />
</div>

### 💧 Irrigation & Rainfall

Per-state rainfall polygons, irrigation-source markers, orbit, and per-state water-source dashboards.

<div align="center">
  <img width="800" src="https://github.com/user-attachments/assets/bc58c018-80b3-484e-a57d-2bb528c7f82a" />
</div>

### 🌱 Seasonal Crop Cycle

Kharif/Rabi stage visualization with auto-play narration.

<div align="center">
  <img width="800" src="https://github.com/user-attachments/assets/1e9ebd93-a7f2-42a1-8215-cf8543b44d1b" />
</div>

### 🎬 Three Guided Tours

Automated storytelling with TTS narration and matching data dashboards per step.

<div align="center">
  <img width="800" src="https://github.com/user-attachments/assets/cc7ec591-e6df-4da0-9ab7-f6ff4cfc84da" />
</div>

### 🗺️ Synced Navigation

Real-time Google Maps pan/zoom drives the Liquid Galaxy camera live.

<div align="center">
  <img width="800" src="https://github.com/user-attachments/assets/0562dcbd-6214-4f94-a864-2db0a7dfda4a" />
</div>

### Additional Features

- **Side-screen dashboards** — HTML balloon dashboards with live statistics and narration text, plus a logo/branding overlay on the leftmost screen.
- **KML self-diagnostic** — a built-in on-screen verifier that checks delivery end to end (write → serve → slave-fetch) and reports the exact failure, enabling remote debugging without rig access.
- **User controls** — voice on/off toggle, connect/disconnect handling, instant navigation, and a skippable first-time onboarding tour.
- **LG management** — relaunch, reboot, shutdown, and logo controls.

## Current State

The application is complete and working on the Liquid Galaxy rig. All features — production maps, fly-to, orbit, irrigation, crop cycle, guided tours, side-screen dashboards, branding, and synced navigation — are functional and have been reviewed and approved by mentors.

## What's Left to Do

- Final validation on the Liquid Galaxy HQ rig.

## Merged Work

All work was contributed through 12 pull requests to the official Liquid Galaxy repository, all reviewed and merged:

- [PR #12 — v9: voice toggle, irrigation orbit, dashboard narration, onboarding](https://github.com/LiquidGalaxyLAB/rice-farm-visualization/pull/12)
- [PR #11 — v8: Synced Navigation restored, tour dashboards, 4-tier tour colors](https://github.com/LiquidGalaxyLAB/rice-farm-visualization/pull/11)
- [PR #10 — HTML dashboard balloons, crop stage & irrigation dashboard fixes](https://github.com/LiquidGalaxyLAB/rice-farm-visualization/pull/10)
- [PR #9 — v5: colored KMLs via kml/ + master IP, 360 orbit, self-diagnostic](https://github.com/LiquidGalaxyLAB/rice-farm-visualization/pull/9)
- [PR #8 — colored KML loading fix: lg1, unique filenames, chmod](https://github.com/LiquidGalaxyLAB/rice-farm-visualization/pull/8)
- [PR #7 — light theme UI redesign, splash screen, 13 bug fixes, LG management](https://github.com/LiquidGalaxyLAB/rice-farm-visualization/pull/7)
- [PR #6 — visualization suite: about screen, blue irrigation KMLs, README](https://github.com/LiquidGalaxyLAB/rice-farm-visualization/pull/6)
- [PR #5 — TTS narration, 3 guided tours, visualization suite](https://github.com/LiquidGalaxyLAB/rice-farm-visualization/pull/5)
- [PR #4 — home screen redesign, regions screen](https://github.com/LiquidGalaxyLAB/rice-farm-visualization/pull/4)
- [PR #3 — data layer: production data, boundary coordinates](https://github.com/LiquidGalaxyLAB/rice-farm-visualization/pull/3)
- [PR #2 — CI fixes: import casing, unused imports](https://github.com/LiquidGalaxyLAB/rice-farm-visualization/pull/2)
- [PR #1 — base Flutter LG controller: SSH, SFTP, KML support](https://github.com/LiquidGalaxyLAB/rice-farm-visualization/pull/1)

The final GSoC commit is the last commit merged in PR #12.

## Challenges & Learnings

The most significant challenge was a colored-KML rendering issue: the visualizations worked perfectly on my local 3-screen rig but failed on the physical test rig. Because i couldn't directly access the failing environment, i studied the Liquid Galaxy core source code and several past GSoC projects to understand the rig's KML sync mechanism, then built an on-screen self-diagnostic that verified each stage of delivery and reported the exact failure remotely. This revealed that the KML serving path and hostname resolution behaved differently on the physical rig. Resolving it taught me disciplined debugging of distributed systems i could not directly observe, and the value of building instrumentation instead of guessing , an approach that turned a multi-week blocker into a solved problem.
