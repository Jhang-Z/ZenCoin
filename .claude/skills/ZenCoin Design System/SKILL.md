---
name: zencoin-design
description: Use this skill to generate well-branded interfaces and assets for ZenCoin — a zen-minimal iOS bookkeeping app — either for production or throwaway prototypes/mocks/etc. Contains essential design guidelines, colors, type, fonts, assets, and UI kit components for prototyping.
user-invocable: true
---

Read the README.md file within this skill, and explore the other available files.

ZenCoin's design language is opinionated and restrictive — that's the point. Before adding anything, ask if it can be left out. One element per screen earns the spotlight. No rainbow gradients, no shadows, no glow, no emoji.

If creating visual artifacts (slides, mocks, throwaway prototypes, etc), copy assets out of `assets/` and create static HTML files for the user to view. Use `colors_and_type.css` as the design-token source of truth — never hardcode colors, type, or spacing. Pick one of the four themes (`claude` / `cursor` / `zapier` / `elevenlabs`) by setting `data-theme` on the root.

If working on production code, copy assets and read the rules here to become an expert in designing with this brand. The original `DESIGN.md` from the ZenCoin repo is the canonical anti-pattern list — surface its rules in code review.

If the user invokes this skill without any other guidance, ask them what they want to build or design (which theme? which screens? icons or full UI?), then act as an expert designer who outputs HTML artifacts _or_ production code, depending on the need.
