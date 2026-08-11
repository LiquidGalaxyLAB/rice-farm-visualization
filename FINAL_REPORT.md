# Rice Farm Agriculture India Visualization — GSoC 2026 Final Report

**Contributor:** Vinayak Dhaka  
**Organization:** Liquid Galaxy Lab  
**Mentors:** Vedant Singh, Dev Gandani  
**Program:** Google Summer of Code 2026  
**Repository:** https://github.com/LiquidGalaxyLAB/rice-farm-visualization

---

## Project Goals

Build a Flutter controller application for the Liquid Galaxy multi-screen rig that visualizes India's rice agriculture on Google Earth. The app turns rice production statistics, seasonal crop cycles, irrigation and rainfall data, and guided narrated tours into an immersive multi-screen experience, fully controllable from a phone over SSH.
<img width="1917" height="973" alt="image" src="https://github.com/user-attachments/assets/120d3365-fa41-4a4b-bbc1-952a777b27fd" />


## What I Did

- **Colored 3D production visualization** — extruded polygon KMLs for all Indian states, color-scaled by rice output, rendered across every screen of the rig.
- **Major Rice Regions** — fly-to any state with TTS narration, a full 360° orbit camera, and a production-tier color scale (green → blue → orange → red).
- **Irrigation & Rainfall** — per-state rainfall polygons, irrigation-source markers, orbit, and per-state water-source dashboards.
- **Seasonal Crop Cycle** — Kharif/Rabi stage visualization with auto-play narration.
- **Three guided tours** — automated storytelling with TTS narration and matching data dashboards per step.
- **Synced Navigation** — real-time Google Maps pan/zoom drives the Liquid Galaxy camera live.
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

The most significant challenge was a colored-KML rendering issue: the visualizations worked perfectly on my local 3-screen rig but failed on the physical test rig. Because I couldn't directly access the failing environment, I studied the Liquid Galaxy core source code and several past GSoC projects to understand the rig's KML sync mechanism, then built an on-screen self-diagnostic that verified each stage of delivery and reported the exact failure remotely. This revealed that the KML serving path and hostname resolution behaved differently on the physical rig. Resolving it taught me disciplined debugging of distributed systems I could not directly observe, and the value of building instrumentation instead of guessing — an approach that turned a multi-week blocker into a solved problem.

---

*This report is submitted as the Work Product for Google Summer of Code 2026 with Liquid Galaxy Lab.*
