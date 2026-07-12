---
name: Tactile Zen & Cyber Sprint
colors:
  surface: '#f6f9ff'
  surface-dim: '#d5dae1'
  surface-bright: '#f6f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4fb'
  surface-container: '#e9eef5'
  surface-container-high: '#e4e9f0'
  surface-container-highest: '#dee3ea'
  on-surface: '#171c21'
  on-surface-variant: '#5c3f3f'
  inverse-surface: '#2b3136'
  inverse-on-surface: '#ecf1f8'
  outline: '#916f6e'
  outline-variant: '#e6bdbc'
  surface-tint: '#bf0030'
  primary: '#b1002c'
  on-primary: '#ffffff'
  primary-container: '#dc143c'
  on-primary-container: '#fff1f0'
  inverse-primary: '#ffb3b3'
  secondary: '#3b6934'
  on-secondary: '#ffffff'
  secondary-container: '#b9eeab'
  on-secondary-container: '#3f6d38'
  tertiary: '#555663'
  on-tertiary: '#ffffff'
  tertiary-container: '#6e6e7c'
  on-tertiary-container: '#f4f2ff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdad9'
  primary-fixed-dim: '#ffb3b3'
  on-primary-fixed: '#40000a'
  on-primary-fixed-variant: '#920022'
  secondary-fixed: '#bcf0ae'
  secondary-fixed-dim: '#a1d494'
  on-secondary-fixed: '#002201'
  on-secondary-fixed-variant: '#23501e'
  tertiary-fixed: '#e2e1f1'
  tertiary-fixed-dim: '#c6c5d4'
  on-tertiary-fixed: '#1a1b26'
  on-tertiary-fixed-variant: '#454652'
  background: '#f6f9ff'
  on-background: '#171c21'
  surface-variant: '#dee3ea'
typography:
  display-calligraphy:
    fontFamily: Montserrat
    fontSize: 48px
    fontWeight: '900'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Montserrat
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
  headline-lg-mobile:
    fontFamily: Montserrat
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-mono:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 48px
  gutter: 16px
  margin-mobile: 20px
---

## Brand & Style

The design system is built on a dual-personality framework: **Zen Learning** and **Cyber Competition**. 

The **Learning Mode** utilizes **Experimental Skeuomorphism** and **Neumorphism**. It targets students seeking a focused, tactile experience that mimics the physical sensation of high-quality Japanese stationery and mechanical keyboards. The emotional response is one of calm, rhythmic study and tangible progress.

The **Game Mode** pivots to a **Cyberpunk** aesthetic. It shifts the emotional state from calm to high-energy adrenaline. It uses glowing edges, digital interfaces, and high-contrast visuals to simulate a competitive "hacker" or "arcade" environment for team-based challenges.

The transition between these modes is a core differentiator, moving from soft, physical depth to vibrant, light-emitting digital surfaces.

## Colors

This design system uses two distinct palettes based on the active mode:

### Learning Mode (Primary)
- **Base Neutral (#E0E5EC):** A soft, mid-grey used for Neumorphic surfaces. This serves as the "plastic" canvas.
- **Sensei Red (#DC143C):** A vibrant crimson used for primary actions and "Call to Action" buttons.
- **Zen Green (#2D5A27):** A deep, organic green for progress bars, correct answers, and achievement states.
- **Ink Blue (#1A1B26):** A near-black, high-density blue used for primary legibility and calligraphy-style accents.

### Game Mode (Cyberpunk Sub-theme)
- **Midnight Indigo (#0D0E14):** Replaces the neutral base to create a deep, dark-mode environment.
- **Neon Magenta & Electric Cyan:** Used for glowing borders, data visualizations, and competitive ranking elements.

## Typography

The typography strategy balances modern precision with traditional weight.

- **Headlines:** Montserrat provides a geometric, bold structure. In "Display" contexts, use heavy weights (900) to mimic the impactful strokes of Shodo (calligraphy).
- **Body:** Inter is used for all instructional text and Kanji/Kana descriptions to ensure maximum legibility at small sizes.
- **Labels:** JetBrains Mono is introduced specifically for the **Game Mode** and technical metadata to lean into the Cyberpunk/Digital aesthetic.

For Japanese characters, ensure the font-weight matches the surrounding English text to maintain visual balance.

## Layout & Spacing

The design system employs a **fluid grid** optimized for thumb-reachability on mobile devices.

- **Base Unit:** A 4px rhythm dictates all padding and margins.
- **Container Strategy:** Elements are housed in Neumorphic "wells" or "extrusions." Because these elements rely on shadows for definition, spacing between cards must be at least `lg` (24px) to prevent shadow overlap and visual muddying.
- **Safe Areas:** Maintain a 20px margin on all mobile screens. In Game Mode, use tighter margins (16px) to create a sense of information density and digital urgency.

## Elevation & Depth

Depth is the primary communicator of hierarchy in the design system.

### Learning Mode (Neumorphic)
- **Extruded (Buttons/Cards):** Created using two shadows: a light shadow (White, #FFFFFF, -5px -5px, 10px blur) on the top-left and a dark shadow (Ink Blue at 15% opacity, 5px 5px, 10px blur) on the bottom-right.
- **Sunken (Input Fields/Wells):** Created using inner shadows with the same light/dark orientation. This suggests a surface that has been physically pressed in.

### Game Mode (Cyberpunk)
- **Luminescent Depth:** Depth is created through "glow" rather than "shadow." Use `box-shadow` with high-saturation colors (Magenta/Cyan) and 0px spread to create neon-tube effects.
- **Glassmorphism:** Use backdrop-blur (12px) on Indigo surfaces to create the illusion of translucent digital HUDs.

## Shapes

The shape language reflects "Soft Industrial" design.

- **Standard Elements:** Use `rounded-lg` (1rem) for most cards and containers. This provides enough curvature for the Neumorphic shadows to wrap smoothly.
- **Interactive Elements:** Buttons utilize the "Tactile Key" style—slightly more rounded than cards to invite a "press" action.
- **Cyberpunk Elements:** In Game Mode, introduce 45-degree chamfered corners (clipped corners) on headers and buttons to reinforce the futuristic, robotic aesthetic.

## Components

### Buttons
- **Tactile Key:** In Learning Mode, buttons must look like physical plastic. Use a subtle gradient and a 2px "rim" (inner glow) to simulate a beveled edge. When pressed, the button should transition from "Extruded" to "Sunken" elevation.
- **Cyber Button:** In Game Mode, buttons feature a "Neon Stroke" (1.5px border) and a subtle flicker animation on hover.

### Cards
- **Kanji Study Card:** A large, extruded Neumorphic surface. The central Kanji should be rendered in Ink Blue with a slight inner shadow to appear engraved into the surface.

### Progress Bars
- **Zen Progress:** A "Well" (Sunken) container with a Zen Green fill that has a soft inner glow, making it look like a liquid tube filling up.
- **Cyber Sprint Bar:** A flat, segmented bar with each segment glowing in Electric Cyan, blinking as it fills.

### Input Fields
- Always "Sunken" elevation. Use JetBrains Mono for the cursor and text to provide a clear, functional contrast to the soft UI.

### Chips/Tags
- Small, pill-shaped elements. In Learning Mode, they are flat with a 1px Ink Blue outline. In Game Mode, they have a solid Neon Magenta background with black text for high-contrast visibility.