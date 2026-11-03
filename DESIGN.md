---
name: Driver Portal
description: A driver's own custody ledger, issued like a weighbridge ticket in the official slate-navy palette.
colors:
  ink-950: "#111522"
  ink-900: "#1E263B"
  ink-800: "#303D59"
  slate-600: "#536684"
  slate-450: "#7687A4"
  slate-350: "#8395B1"
  slate-300: "#98A9C4"
  slate-100: "#DCE3EF"
  mist-50: "#EEF1F7"
  mist-25: "#F6F8FB"
  ticket-white: "#FFFFFF"
  error-light: "#B42318"
  error-surface-light: "#FBEEEC"
  error-dark: "#FDA29B"
  error-surface-dark: "#3D3041"
typography:
  display:
    fontFamily: "system-ui, Roboto, -apple-system, 'SF Pro Text', sans-serif"
    fontSize: "28px"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "normal"
  brand:
    fontFamily: "system-ui, Roboto, -apple-system, 'SF Pro Text', sans-serif"
    fontSize: "16px"
    fontWeight: 700
    lineHeight: 1.25
    letterSpacing: "normal"
  body-large:
    fontFamily: "system-ui, Roboto, -apple-system, 'SF Pro Text', sans-serif"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.45
    letterSpacing: "normal"
  body-medium:
    fontFamily: "system-ui, Roboto, -apple-system, 'SF Pro Text', sans-serif"
    fontSize: "14px"
    fontWeight: 500
    lineHeight: 1.4
    letterSpacing: "normal"
  label:
    fontFamily: "system-ui, Roboto, -apple-system, 'SF Pro Text', sans-serif"
    fontSize: "14px"
    fontWeight: 600
    lineHeight: 1.3
    letterSpacing: "normal"
  input:
    fontFamily: "system-ui, Roboto, -apple-system, 'SF Pro Text', sans-serif"
    fontSize: "16px"
    fontWeight: 500
    lineHeight: 1.3
    letterSpacing: "normal"
  helper:
    fontFamily: "system-ui, Roboto, -apple-system, 'SF Pro Text', sans-serif"
    fontSize: "12px"
    fontWeight: 500
    lineHeight: 1.4
    letterSpacing: "normal"
  data:
    fontFamily: "system-ui, Roboto, -apple-system, 'SF Pro Text', sans-serif"
    fontSize: "12px"
    fontWeight: 600
    lineHeight: 1.4
    letterSpacing: "normal"
    fontFeature: "'tnum' 1"
  button:
    fontFamily: "system-ui, Roboto, -apple-system, 'SF Pro Text', sans-serif"
    fontSize: "16px"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "normal"
rounded:
  notch: "10px"
  control: "12px"
  ticket: "20px"
spacing:
  xs: "8px"
  sm: "12px"
  md: "16px"
  lg: "20px"
  xl: "24px"
components:
  ticket:
    backgroundColor: "{colors.ticket-white}"
    textColor: "{colors.ink-950}"
    rounded: "{rounded.ticket}"
    padding: "24px"
  ticket-dark:
    backgroundColor: "{colors.ink-900}"
    textColor: "{colors.mist-50}"
    rounded: "{rounded.ticket}"
    padding: "24px"
  button-primary:
    backgroundColor: "{colors.ink-900}"
    textColor: "{colors.ticket-white}"
    typography: "{typography.button}"
    rounded: "{rounded.control}"
    height: "56px"
    width: "100%"
  button-primary-loading:
    backgroundColor: "{colors.ink-900}"
    textColor: "{colors.ticket-white}"
    rounded: "{rounded.control}"
    height: "56px"
    width: "100%"
  button-primary-dark:
    backgroundColor: "{colors.slate-100}"
    textColor: "{colors.ink-950}"
    typography: "{typography.button}"
    rounded: "{rounded.control}"
    height: "56px"
    width: "100%"
  input-field:
    backgroundColor: "{colors.mist-25}"
    textColor: "{colors.ink-950}"
    typography: "{typography.input}"
    rounded: "{rounded.control}"
    padding: "16px"
  input-field-dark:
    backgroundColor: "{colors.ink-950}"
    textColor: "{colors.mist-50}"
    typography: "{typography.input}"
    rounded: "{rounded.control}"
    padding: "16px"
  notice-error:
    backgroundColor: "{colors.error-surface-light}"
    textColor: "{colors.error-light}"
    typography: "{typography.body-medium}"
    rounded: "{rounded.control}"
    padding: "12px 16px"
  notice-error-dark:
    backgroundColor: "{colors.error-surface-dark}"
    textColor: "{colors.error-dark}"
    typography: "{typography.body-medium}"
    rounded: "{rounded.control}"
    padding: "12px 16px"
  route-mark:
    backgroundColor: "{colors.ink-900}"
    textColor: "{colors.slate-100}"
    rounded: "{rounded.control}"
    size: "40px"
  route-mark-dark:
    backgroundColor: "{colors.slate-100}"
    textColor: "{colors.ink-900}"
    rounded: "{rounded.control}"
    size: "40px"
---

# Design System: Driver Portal

## Overview

**Creative North Star: "The Issued Ticket"**

Every surface in this world reads like a fuel or weighbridge ticket handed to a driver: a stub that says who issued it and when, a perforated tear line, and a working body below. The paper is calm and the ink is official. The palette is the binding slate-navy six, built into two schemes that are designed separately rather than inverted: Light is a mist ground with a white ticket and ink action; Dark is an ink ground with a lifted navy ticket and a mist action. Depth comes from one soft shadow on the one raised surface and from fields that sit tonally below the ticket.

Density is low and deliberate. A surface shows the few things the driver needs, in a single centred column, at a size that survives a cab in daylight, a night shift, a large system font, and Arabic as much as English. Decoration is limited to the ticket's own anatomy: the notches, the perforation, and the route mark. Motion is short, purposeful, and always skipped when the system asks for reduced motion.

Scope: this world is adopted by Login only. Every other screen still renders the previous violet system (the earlier tokens in `AppColors` and the `AppSurfaces` roles) and migrates one screen at a time. This document governs only surfaces built on `AppPalette`.

**Key Characteristics:**
- Official slate-navy only; no saturated hue anywhere except a muted error red.
- Two built schemes with their own roles, read through `AppPalette`.
- One raised surface per screen: the ticket, with one soft shadow.
- Hairline borders; controls share one 12dp corner.
- The perforated tear line with side notches is the signature.
- Platform system fonts, no negative tracking, tabular figures for data.

## Colors

A cool, low-chroma slate-navy ladder from near-black ink to pale mist, with one muted red reserved for errors.

### Primary
- **Issuing Ink** (`ink-900`): the primary action fill in Light (Sign In) and the route-mark tile; also the focus outline, caret, and field labels in Light. In Dark the action role moves to **Pale Slate** (`slate-100`), so the strongest mark on the screen is always the action.

### Neutral
- **Night Ink** (`ink-950`): Dark page ground and Dark field fill; Light title text and Dark action text.
- **Lifted Navy** (`ink-800`): Light body text; Dark hairlines and perforation.
- **Steel Slate** (`slate-600`): Light hints and icons; Dark resting field outline.
- **Field Slate** (`slate-450`): Light resting field outline, chosen to hold 3:1 against the field fill.
- **Night Hint** (`slate-350`): Dark hints and icons (4.5:1 or more on the Dark ground and ticket).
- **Haze Slate** (`slate-300`): Dark body text.
- **Pale Slate** (`slate-100`): Light hairlines and perforation; Dark action, focus, labels, and route-mark tile; Light route-mark drawing.
- **Mist** (`mist-50`): Light page ground; Dark title text.
- **Field Mist** (`mist-25`): Light field fill, inset below the white ticket.
- **Ticket White** (`ticket-white`): the Light ticket surface and Light action text.

### Status
- **Muted Error Red** (`error-light` on `error-surface-light`; `error-dark` on `error-surface-dark`): field error outlines, error helper text, and the sign-in notice. Muted so an error is unmistakable without shouting.

Role map, as built in `AppPalette`:

| Role | Light | Dark |
|---|---|---|
| ground | mist-50 | ink-950 |
| surface | ticket-white | ink-900 |
| hairline | slate-100 | ink-800 |
| field | mist-25 | ink-950 |
| fieldBorder | slate-450 | slate-600 |
| focus | ink-900 | slate-100 |
| title | ink-950 | mist-50 |
| body | ink-800 | slate-300 |
| muted | slate-600 | slate-350 |
| label | ink-900 | slate-100 |
| action / onAction | ink-900 / ticket-white | slate-100 / ink-950 |
| mark / onMark | ink-900 / slate-100 | slate-100 / ink-900 |
| error / errorSurface | error-light / error-surface-light | error-dark / error-surface-dark |

### Named Rules
**The Official Six Rule.** Every neutral is one of the six official values or a stated mix of them (mist is slate-100 toward white; slate-450 and slate-350 sit between slate-600 and slate-300). New colors are derived the same way, never picked freely.

**The Built Twice Rule.** Light and Dark are two designed role sets, not an inversion: the Dark field sinks to the ground color, and the Dark action turns pale. Screens read roles from `AppPalette`, never raw tokens.

## Typography

**Display Font:** Platform system sans (Roboto on Android, SF Pro on iOS, the platform's native Arabic face)
**Body Font:** Same system family
**Label/Mono Font:** Same system family; data uses tabular figures rather than a mono face

**Character:** Plain, native, and legible at arm's length; weight and size carry the hierarchy, never tracking. Fonts are not bundled in this phase.

### Hierarchy
- **Display** (700, 28dp, 1.2): the screen headline, such as the sign-in welcome. Material role headlineMedium.
- **Brand** (700, 16dp, 1.25): the product name in the ticket stub. Material role titleMedium.
- **Body Large** (400, 16dp, 1.45): a headline's supporting line.
- **Body Medium** (500, 14dp, 1.4): notices and help lines; the error notice raises it to 600.
- **Label** (600, 14dp, 1.3): the label above a field.
- **Input** (500, 16dp, 1.3): text typed into a field.
- **Helper** (500, 12dp, 1.4): field error messages.
- **Data** (600, 12dp, 1.4, tabular figures): small data fields such as the stub's issue date.
- **Button** (700, 16dp, 1.2): the primary action label.

### Named Rules
**The Joined Letters Rule.** Letter spacing stays at normal on every role so Arabic letters stay joined. Hierarchy comes from size and weight.

**The Tabular Data Rule.** Dates, amounts, and any figure that may line up with another use tabular figures.

## Layout

A single centred column, at most 440dp wide, vertically centred on the ground and scrollable when the keyboard opens (dragging dismisses it). Page padding is 20dp horizontally and 24dp vertically inside the safe area. The rhythm is 8dp with 4dp half-steps: 8dp between a headline and its supporting line and between a label and its field; 12dp between the route mark and the product name; 16dp between fields and before a notice; 20dp between the ticket and the help line beneath it; 24dp for the ticket's inner padding, after the supporting line, and before the action.

The stub's height is computed from the current text scale so the tear line never cuts text. The stub holds the route mark, the product name, and the issue date at its end; when name and date cannot share one line, the date moves under the name. Everything mirrors for right-to-left, including the action arrow.

## Elevation & Depth

A hybrid of one shadow and tonal layering. The ticket is the only raised surface and carries the single `raisedShadow` role: a soft ambient drop with a faint contact edge in Light, one deeper soft drop in Dark. Inside the ticket, depth runs downward: fields are filled a step below the surface (Field Mist on white, Night Ink on Lifted Navy). Everything else is flat. The hard band under the ticket in the review goldens is a software-renderer artifact; on device the shadow is soft.

### Shadow Vocabulary
- **Raised, Light** (`0 12px 28px` ink-950 at 7%, plus `0 1px 4px` ink-950 at 4%): the ticket in Light.
- **Raised, Dark** (`0 14px 28px` black at 35%): the ticket in Dark.

### Named Rules
**The One Raised Surface Rule.** A screen has one raised surface, and it is the ticket. Fields, notices, and buttons do not cast shadows.

## Shapes

Soft but disciplined corners: the ticket at 20dp, every control inside it (fields, the action, notices, the route-mark tile) at 12dp. Borders are 1dp hairlines; only a focused field thickens its outline to 1.6dp. The ticket's silhouette is cut by two semicircular side notches (10dp radius) at the tear line, and the cut runs through the fill, the shadow, and the hairline alike. Between the notches, inset 8dp from each, runs the perforation: a 1dp dashed line of 6dp dashes and 5dp gaps in the hairline color.

### Named Rules
**The Perforation Rule.** The tear line separates a ticket's identifying stub from its working body. It appears once per ticket and is never used as a generic divider.

## Components

### Buttons
Solid, full-width, and unmistakably the one thing to press.
- **Shape:** gently rounded (12dp), 56dp tall, full width of the ticket body.
- **Primary:** action fill with onAction content (Issuing Ink with white in Light; Pale Slate with Night Ink in Dark). Content is the label followed by a 20dp forward arrow with an 8dp gap; the arrow mirrors in right-to-left.
- **Loading:** the label and arrow swap for a 22dp spinner (2.2dp stroke, onAction color) through a 180ms cross-fade. The button stays in its full action colors while it waits; it does not grey out.
- **Pressed:** Material 3 state layer only.

### Cards / Containers
The ticket is the only container.
- **Corner Style:** 20dp, with 10dp side notches at the tear line.
- **Background:** the surface role (Ticket White / Lifted Navy).
- **Shadow Strategy:** `raisedShadow`; see Elevation & Depth.
- **Border:** 1dp hairline that follows the notches.
- **Internal Padding:** 24dp in the body; the stub uses 24dp horizontally and 16dp vertically.
- **Entrance:** on a cold start the ticket rises 18dp into place over 520ms (ease-out-expo), already visible, with no fade. It does not play when a route transition brings the page in or when the system asks for reduced motion.

### Inputs / Fields
Inset, labelled, and quiet until touched.
- **Style:** field-role fill, 1dp fieldBorder outline, 12dp corners, 16dp padding; a 20dp muted leading icon; the password field adds a 20dp show/hide toggle with a tooltip. The label sits 8dp above in the Label style and is merged into the field's semantics.
- **Focus:** the outline becomes 1.6dp in the focus role; the caret, selection handles, and a 22% selection tint use the same role.
- **Error:** the outline turns to the error role (1.6dp when focused), with the message below in Helper, error color, up to two lines.

### Notices
A tinted error surface (errorSurface) with 12dp corners and 12dp by 16dp padding; a 20dp error or offline icon, 8dp gap, and the message in Body Medium at 600 in the error role. It is a live region, so it is announced when it appears.

### Route Mark
The product's mark: a 40dp tile with 12dp corners in the mark role, with a route drawn in onMark from a filled origin dot, along a rounded bend, to a destination ring. It is custom-painted and hidden from screen readers; the product name next to it carries the meaning.

### Page Transitions
Screens in this world meet through one fade-through: over 320ms in (260ms back), the incoming page's ground covers the old page during the first 35%, then the content fades in while settling from 0.96 to full scale. With system animations off, the page appears at once. Status bar is transparent and the navigation bar takes the ground color, with icon brightness following the scheme.

## Do's and Don'ts

### Do:
- **Do** read colors through `AppPalette` roles so each scheme gets its own built value.
- **Do** keep one raised surface per screen, carrying `raisedShadow`.
- **Do** put every control on the 12dp corner and every border on a 1dp hairline; only focus thickens to 1.6dp.
- **Do** space on the 8dp rhythm (8, 12, 16, 20, 24dp).
- **Do** set figures in tabular numerals.
- **Do** keep touch targets at least 48dp and merge a field's visible label into its semantics.
- **Do** skip every entrance and transition when the system asks for reduced motion.

### Don't:
- **Don't** introduce saturated colors; the error red stays muted and is the only hue outside the slate-navy ladder.
- **Don't** use the previous violet tokens (`AppColors.primary` and its siblings, `AppSurfaces`) on a surface that has moved to this world.
- **Don't** invert Light to make Dark; each scheme has its own role values.
- **Don't** apply negative letter spacing on any role.
- **Don't** add shadows to fields, notices, or buttons, or stack a second raised card on the ticket.
- **Don't** use the perforation as a plain divider in lists or sections.
- **Don't** fade the ticket in on entrance; it rises once, already visible.
