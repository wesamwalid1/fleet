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
  title:
    fontFamily: "system-ui, Roboto, -apple-system, 'SF Pro Text', sans-serif"
    fontSize: "22px"
    fontWeight: 700
    lineHeight: 1.25
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
  row-title:
    fontFamily: "system-ui, Roboto, -apple-system, 'SF Pro Text', sans-serif"
    fontSize: "16px"
    fontWeight: 500
    lineHeight: 1.3
    letterSpacing: "normal"
  value:
    fontFamily: "system-ui, Roboto, -apple-system, 'SF Pro Text', sans-serif"
    fontSize: "14px"
    fontWeight: 600
    lineHeight: 1.4
    letterSpacing: "normal"
    fontFeature: "'tnum' 1"
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
  id-badge:
    backgroundColor: "{colors.ticket-white}"
    textColor: "{colors.ink-950}"
    rounded: "{rounded.ticket}"
    padding: "12px 24px 8px"
  id-badge-dark:
    backgroundColor: "{colors.ink-900}"
    textColor: "{colors.mist-50}"
    rounded: "{rounded.ticket}"
    padding: "12px 24px 8px"
  initials-tile:
    backgroundColor: "{colors.ink-900}"
    textColor: "{colors.slate-100}"
    typography: "{typography.title}"
    rounded: "{rounded.control}"
    size: "64px"
  initials-tile-dark:
    backgroundColor: "{colors.slate-100}"
    textColor: "{colors.ink-900}"
    typography: "{typography.title}"
    rounded: "{rounded.control}"
    size: "64px"
  settings-row:
    backgroundColor: "{colors.mist-50}"
    textColor: "{colors.ink-950}"
    typography: "{typography.row-title}"
    height: "56px"
    padding: "12px 20px"
  settings-row-dark:
    backgroundColor: "{colors.ink-950}"
    textColor: "{colors.mist-50}"
    typography: "{typography.row-title}"
    height: "56px"
    padding: "12px 20px"
  settings-row-destructive:
    backgroundColor: "{colors.mist-50}"
    textColor: "{colors.error-light}"
    typography: "{typography.row-title}"
    height: "56px"
    padding: "12px 20px"
  settings-row-destructive-dark:
    backgroundColor: "{colors.ink-950}"
    textColor: "{colors.error-dark}"
    typography: "{typography.row-title}"
    height: "56px"
    padding: "12px 20px"
  pending-count:
    backgroundColor: "{colors.ink-900}"
    textColor: "{colors.ticket-white}"
    typography: "{typography.label}"
    rounded: "{rounded.control}"
    padding: "3px 8px"
  pending-count-dark:
    backgroundColor: "{colors.slate-100}"
    textColor: "{colors.ink-950}"
    typography: "{typography.label}"
    rounded: "{rounded.control}"
    padding: "3px 8px"
  sheet:
    backgroundColor: "{colors.ticket-white}"
    textColor: "{colors.ink-950}"
    rounded: "{rounded.ticket}"
    padding: "24px 20px 16px"
  sheet-dark:
    backgroundColor: "{colors.ink-900}"
    textColor: "{colors.mist-50}"
    rounded: "{rounded.ticket}"
    padding: "24px 20px 16px"
  language-option:
    backgroundColor: "{colors.ticket-white}"
    textColor: "{colors.ink-950}"
    typography: "{typography.row-title}"
    rounded: "{rounded.control}"
    height: "56px"
    padding: "12px 16px"
  language-option-selected:
    backgroundColor: "{colors.mist-25}"
    textColor: "{colors.ink-950}"
    typography: "{typography.row-title}"
    rounded: "{rounded.control}"
    height: "56px"
    padding: "12px 16px"
  language-option-dark:
    backgroundColor: "{colors.ink-900}"
    textColor: "{colors.mist-50}"
    typography: "{typography.row-title}"
    rounded: "{rounded.control}"
    height: "56px"
    padding: "12px 16px"
  language-option-selected-dark:
    backgroundColor: "{colors.ink-950}"
    textColor: "{colors.mist-50}"
    typography: "{typography.row-title}"
    rounded: "{rounded.control}"
    height: "56px"
    padding: "12px 16px"
  button-outline:
    backgroundColor: "{colors.ticket-white}"
    textColor: "{colors.ink-950}"
    typography: "{typography.button}"
    rounded: "{rounded.control}"
    height: "56px"
  button-outline-dark:
    backgroundColor: "{colors.ink-900}"
    textColor: "{colors.mist-50}"
    typography: "{typography.button}"
    rounded: "{rounded.control}"
    height: "56px"
  button-destructive:
    backgroundColor: "{colors.error-light}"
    textColor: "{colors.ticket-white}"
    typography: "{typography.button}"
    rounded: "{rounded.control}"
    height: "56px"
  button-destructive-dark:
    backgroundColor: "{colors.error-dark}"
    textColor: "{colors.ink-950}"
    typography: "{typography.button}"
    rounded: "{rounded.control}"
    height: "56px"
---

# Design System: Driver Portal

## Overview

**Creative North Star: "The Issued Ticket"**

Every surface in this world reads like a fuel or weighbridge ticket handed to a driver: a stub that says who issued it and when, a perforated tear line, and a working body below. The paper is calm and the ink is official. The palette is the binding slate-navy six, built into two schemes that are designed separately rather than inverted: Light is a mist ground with a white ticket and ink action; Dark is an ink ground with a lifted navy ticket and a mist action. Depth comes from one soft shadow on the one raised surface and from fields that sit tonally below the ticket.

The same paper and ink also issue the driver's company ID. Profile is one laminated badge, white on mist in Light and lifted navy on ink in Dark, with a punched lanyard slot at its top and a hairline-ruled grid of labels and values. Everything the driver can change sits loose on the ground below it in hairline-divided rows, never boxed in cards.

Density is low and deliberate. A surface shows the few things the driver needs, at a size that survives a cab in daylight, a night shift, a large system font, and Arabic as much as English. Decoration is limited to each issued document's own anatomy: the ticket's notches, perforation, and route mark; the badge's lanyard slot and label-value grid. Motion is short, purposeful, and always skipped when the system asks for reduced motion.

Scope: this world is adopted by Login and Profile, including Profile's language and logout sheets. Every other screen, the floating bottom navigation, `PortalShell`, and its offline banner still render the previous violet system (the earlier tokens in `AppColors` and the `AppSurfaces` roles) and migrate one screen at a time. This document governs only surfaces built on `AppPalette`.

**Key Characteristics:**
- Official slate-navy only; no saturated hue anywhere except a muted error red.
- Two built schemes with their own roles, read through `AppPalette`.
- One raised surface per screen, with one soft shadow: the ticket on Login, the ID badge on Profile.
- Hairline borders; controls share one 12dp corner.
- The perforated tear line with side notches is the ticket's signature; the lanyard slot and label-value grid are the badge's.
- Lists sit on the ground, divided by 1dp hairlines.
- Platform system fonts, no negative tracking, tabular figures for data.

## Colors

A cool, low-chroma slate-navy ladder from near-black ink to pale mist, with one muted red reserved for errors.

### Primary
- **Issuing Ink** (`ink-900`): the primary action fill in Light (Sign In), the route-mark tile, the Profile initials tile, and the pending-count pill; also the focus outline, caret, and field labels in Light; the Dark ticket, badge, and sheet surface. In Dark the action role moves to **Pale Slate** (`slate-100`), so the strongest mark on the screen is always the action.

### Neutral
- **Night Ink** (`ink-950`): Dark page ground and Dark field fill; Light title text; Dark action text and Dark content on an error fill.
- **Lifted Navy** (`ink-800`): Light body text; Dark hairlines and perforation.
- **Steel Slate** (`slate-600`): Light hints and icons, including Profile's section labels, row icons, chevrons, and badge labels; Dark resting field outline.
- **Field Slate** (`slate-450`): Light resting field outline, chosen to hold 3:1 against the field fill.
- **Night Hint** (`slate-350`): Dark hints and icons (4.5:1 or more on the Dark ground and ticket).
- **Haze Slate** (`slate-300`): Dark body text.
- **Pale Slate** (`slate-100`): Light hairlines and perforation; Dark action, focus, labels, route-mark tile, and initials tile; Light route-mark drawing and initials.
- **Mist** (`mist-50`): Light page ground, which Profile's rows sit directly on; Dark title text.
- **Field Mist** (`mist-25`): Light field fill, inset below the white ticket; the selected language option.
- **Ticket White** (`ticket-white`): the Light ticket, badge, and sheet surface; Light action text and Light content on an error fill.

### Status
- **Muted Error Red** (`error-light` on `error-surface-light`; `error-dark` on `error-surface-dark`): field error outlines, error helper text, and the sign-in notice; on Profile, the Logout row's icon and title and the fill of the confirm-logout button. Muted so an error is unmistakable without shouting.

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
| onError | ticket-white | ink-950 |
| insetShade | ink-950 at 16% | black at 50% |

`onError` is the content on an error fill, mirroring `onAction`: white on the Light red, Night Ink on the pale Dark red. `insetShade` is the shade along the top inner edge of a shape cut into a surface, such as the badge's lanyard slot; it is laid over the ground color, never used as a fill on its own.

### Named Rules
**The Official Six Rule.** Every neutral is one of the six official values or a stated mix of them (mist is slate-100 toward white; slate-450 and slate-350 sit between slate-600 and slate-300). New colors are derived the same way, never picked freely.

**The Built Twice Rule.** Light and Dark are two designed role sets, not an inversion: the Dark field sinks to the ground color, and the Dark action turns pale. Screens read roles from `AppPalette`, never raw tokens.

## Typography

**Display Font:** Platform system sans (Roboto on Android, SF Pro on iOS, the platform's native Arabic face)
**Body Font:** Same system family
**Label/Mono Font:** Same system family; data uses tabular figures rather than a mono face

**Character:** Plain, native, and legible at arm's length; weight and size carry the hierarchy, never tracking. Fonts are not bundled in this phase.

### Hierarchy
- **Display** (700, 28dp, 1.2): the screen headline, such as the sign-in welcome and the Profile page title. Material role headlineMedium.
- **Title** (700, 22dp, 1.25): a person's name or a sheet title: the driver's name on the badge, the initials in the badge tile, and the language and logout sheet titles. Material role titleLarge.
- **Brand** (700, 16dp, 1.25): the product name in the ticket stub. Material role titleMedium.
- **Body Large** (400, 16dp, 1.45): a headline's supporting line and a sheet's message.
- **Body Medium** (500, 14dp, 1.4): notices and help lines; the error notice raises it to 600. On the badge it sets the labels (muted) and status values such as an offline balance (muted, 500).
- **Row Title** (500, 16dp, 1.3): Body Large tightened for a settings row or sheet option; a selected language option raises it to 700.
- **Value** (600, 14dp, 1.4, tabular figures): Body Medium raised for data: badge values in the title role, row values (balance, language) in the body role.
- **Label** (600, 14dp, 1.3): the label above a field and the section labels over Profile's row groups (muted, sentence case); the pending count raises it to 700 with tabular figures.
- **Input** (500, 16dp, 1.3): text typed into a field.
- **Helper** (500, 12dp, 1.4): field error messages.
- **Data** (600, 12dp, 1.4, tabular figures): small data fields such as the stub's issue date.
- **Button** (700, 16dp, 1.2): the primary action label.

### Named Rules
**The Joined Letters Rule.** Letter spacing stays at normal on every role so Arabic letters stay joined. Hierarchy comes from size and weight.

**The Tabular Data Rule.** Dates, amounts, and any figure that may line up with another use tabular figures.

## Layout

Login is a single centred column, at most 440dp wide, vertically centred on the ground and scrollable when the keyboard opens (dragging dismisses it). Page padding is 20dp horizontally and 24dp vertically inside the safe area. The rhythm is 8dp with 4dp half-steps: 8dp between a headline and its supporting line and between a label and its field; 12dp between the route mark and the product name; 16dp between fields and before a notice; 20dp between the ticket and the help line beneath it; 24dp for the ticket's inner padding, after the supporting line, and before the action.

The stub's height is computed from the current text scale so the tear line never cuts text. The stub holds the route mark, the product name, and the issue date at its end; when name and date cannot share one line, the date moves under the name. Everything mirrors for right-to-left, including the action arrow.

Profile is a full-width scroll on the ground inside the portal shell. The Display page title and the badge sit at a 20dp horizontal inset, 16dp below the safe area, with 20dp between title and badge. Inside the badge: 12dp to the lanyard slot, 12dp below it, 24dp at the sides, 8dp at the bottom; 16dp between the initials tile and the name; 20dp from the name row to the first rule; each grid line has 12dp vertical padding and 16dp between label and value. Section labels start 24dp above their group at the same 20dp inset, with 4dp below. Rows run edge to edge with a 20dp inner inset; trailing content gets a 12dp gap and at most 140dp of width, and the chevron a 4dp gap. The list ends 32dp plus the floating navigation's height (reported by the shell as bottom padding) so the last row scrolls clear of the bar.

Bottom sheets are at most 640dp wide (the language sheet up to 92% of the screen height), with 24dp top, 20dp side, and 16dp bottom padding above the safe area. The language sheet has 16dp from title to options and 8dp between options; the logout sheet has 8dp from title to message, 24dp to the buttons, and 12dp between the two buttons.

## Elevation & Depth

A hybrid of one shadow and tonal layering. The ticket is the only raised surface on Login and the ID badge is the only one on Profile; each carries the single `raisedShadow` role: a soft ambient drop with a faint contact edge in Light, one deeper soft drop in Dark. Inside the ticket, depth runs downward: fields are filled a step below the surface (Field Mist on white, Night Ink on Lifted Navy). Inside the badge, the lanyard slot reads as punched through to the ground: a vertical fade from `insetShade` over the ground at its top edge to the bare ground at 45% of its height. Everything else is flat: Profile's rows lie on the ground, and the language and logout sheets are modal layers in the surface color, not a second raised surface on the screen. The hard band under the ticket in the review goldens is a software-renderer artifact; on device the shadow is soft.

### Shadow Vocabulary
- **Raised, Light** (`0 12px 28px` ink-950 at 7%, plus `0 1px 4px` ink-950 at 4%): the ticket or badge in Light.
- **Raised, Dark** (`0 14px 28px` black at 35%): the ticket or badge in Dark.

### Named Rules
**The One Raised Surface Rule.** A screen has one raised surface: the ticket on Login, the ID badge on Profile. Fields, notices, buttons, and rows do not cast shadows.

## Shapes

Soft but disciplined corners: the ticket at 20dp, every control inside it (fields, the action, notices, the route-mark tile) at 12dp. Borders are 1dp hairlines; only a focused field thickens its outline to 1.6dp. The ticket's silhouette is cut by two semicircular side notches (10dp radius) at the tear line, and the cut runs through the fill, the shadow, and the hairline alike. Between the notches, inset 8dp from each, runs the perforation: a 1dp dashed line of 6dp dashes and 5dp gaps in the hairline color.

The ID badge shares the ticket's 20dp corner and 1dp hairline border but has no notches, stub, or perforation. Its one cut is the lanyard slot: a fully rounded 40 by 8dp opening (4dp radius) centred 12dp below the top edge. Inside the badge, the initials tile takes the 12dp control corner; the label-value grid is ruled by solid 1dp hairlines. Profile's rows have no shape of their own: they are flat bands on the ground, divided by 1dp hairlines inset 20dp from each side. The pending-count pill, language options, and sheet buttons take the 12dp control corner; bottom sheets round only their top corners, at 20dp.

### Named Rules
**The Perforation Rule.** The tear line separates a ticket's identifying stub from its working body. It appears once per ticket and is never used as a generic divider. It stays the ticket's: the badge's grid and Profile's rows are divided by solid hairlines.

## Components

### Buttons
Solid, full-width, and unmistakably the one thing to press.
- **Shape:** gently rounded (12dp), 56dp tall, full width of the ticket body.
- **Primary:** action fill with onAction content (Issuing Ink with white in Light; Pale Slate with Night Ink in Dark). Content is the label followed by a 20dp forward arrow with an 8dp gap; the arrow mirrors in right-to-left.
- **Loading:** the label and arrow swap for a 22dp spinner (2.2dp stroke, onAction color) through a 180ms cross-fade. The button stays in its full action colors while it waits; it does not grey out.
- **Pressed:** Material 3 state layer only.
- **Paired sheet actions:** two equal-width 56dp buttons with 12dp corners, 12dp apart, in the Button style. The cancel is outlined: surface fill, title-role content, 1dp fieldBorder outline. The destructive confirm is filled in the error role with onError content.
- **Text:** a retry under a failure line uses action-role text in the Button style with a 48dp minimum target.

### Cards / Containers
The ticket (Login) and the ID badge (Profile) are the only containers.
- **Corner Style:** 20dp; the ticket adds 10dp side notches at the tear line.
- **Background:** the surface role (Ticket White / Lifted Navy).
- **Shadow Strategy:** `raisedShadow`; see Elevation & Depth.
- **Border:** 1dp hairline that follows the notches.
- **Internal Padding:** 24dp in the ticket body; the stub uses 24dp horizontally and 16dp vertically. The badge uses 24dp at the sides; see Layout.
- **Entrance:** on a cold start the ticket rises 18dp into place over 520ms (ease-out-expo), already visible, with no fade. It does not play when a route transition brings the page in or when the system asks for reduced motion. The rise stays the ticket's: the badge has no entrance.

### Inputs / Fields
Inset, labelled, and quiet until touched.
- **Style:** field-role fill, 1dp fieldBorder outline, 12dp corners, 16dp padding; a 20dp muted leading icon; the password field adds a 20dp show/hide toggle with a tooltip. The label sits 8dp above in the Label style and is merged into the field's semantics.
- **Focus:** the outline becomes 1.6dp in the focus role; the caret, selection handles, and a 22% selection tint use the same role.
- **Error:** the outline turns to the error role (1.6dp when focused), with the message below in Helper, error color, up to two lines.

### Switch
The Material switch read through palette roles: on, an action-role track and outline with an onAction thumb; off, a field-role track with a fieldBorder outline and thumb. A row that holds a switch (Dark Mode) merges its semantics with the switch and drops the chevron.

### Lists / Settings Rows
Rows lie directly on the ground, grouped and divided by hairlines; no card surrounds them.
- **Row:** at least 56dp tall, 20dp horizontal and 12dp vertical padding. A 20dp muted icon, 16dp gap, the title in Row Title (title role, up to two lines), then an optional end-aligned value or count, then a 22dp muted chevron that mirrors in right-to-left. The Dark Mode and Logout rows have no chevron. Icons sit bare, never on a tinted tile.
- **Value:** end-aligned, in the Value style in the body role, one line with an ellipsis.
- **Dividers:** 1dp hairlines between rows only, inset 20dp from each side.
- **States:** pressed is a title-role overlay at 6% (highlight) and 8% (splash); keyboard focus is a focus-role overlay at 12%.
- **Destructive:** the icon and title take the error role; the row itself stays on the ground.
- **Section labels:** the Label style in the muted role, sentence case (Quick access, Settings, Account), marked as headers for screen readers.

### Pending Count
A small pill at the end of the Pending Approvals row: action-role fill, 12dp corners, at least 28dp wide, 8dp by 3dp padding, the count in Label at 700 with tabular figures in onAction. It is hidden while approvals load, when the count is zero, and offline.

### ID Badge
Profile's signature: the driver's company ID, the screen's one raised surface. A surface-role card with 20dp corners, a 1dp hairline border, and `raisedShadow`. At top centre sits the lanyard slot, hidden from screen readers. Below it, a 64dp initials tile in the mark role (12dp corners, initials in Title in onMark, scaled down to fit inside 8dp padding, hidden from screen readers) sits beside the driver's name in Title, title role, up to two lines. Under a hairline, the label-value grid: ID, Vault, and Balance, each a merged semantic line with the label in Body Medium (muted) at the start and the value end-aligned in the Value style in the title role, up to two lines. A status value (offline or a failed balance) is set in Body Medium in the muted role so it does not read as data; the Balance line is omitted until there is something to show.

### Bottom Sheets
Modal sheets in the surface role with 20dp top corners. The title is in Title, title role, marked as a header.
- **Language:** options are 56dp boxes with 12dp corners and 16dp by 12dp padding, the language name in Row Title. At rest: surface fill, 1dp hairline. Selected: field fill, a 1.6dp focus-role outline, the name at 700, and a 22dp check in the focus role; the option is announced as selected. Press overlays match the rows.
- **Logout:** the title, the message in Body Large (body role), then the paired cancel and destructive confirm buttons.

### Value Swap
When a value changes in place (a badge value, a row value, or the pending count), the new value cross-fades over the old in 180ms (ease-out-cubic), anchored to the end edge, without moving its row. With reduced motion it replaces the old value at once.

### Notices
A tinted error surface (errorSurface) with 12dp corners and 12dp by 16dp padding; a 20dp error or offline icon, 8dp gap, and the message in Body Medium at 600 in the error role. It is a live region, so it is announced when it appears.

### Route Mark
The product's mark: a 40dp tile with 12dp corners in the mark role, with a route drawn in onMark from a filled origin dot, along a rounded bend, to a destination ring. It is custom-painted and hidden from screen readers; the product name next to it carries the meaning.

### Page Transitions
Screens in this world meet through one fade-through: over 320ms in (260ms back), the incoming page's ground covers the old page during the first 35%, then the content fades in while settling from 0.96 to full scale. With system animations off, the page appears at once. Status bar is transparent and the navigation bar takes the ground color, with icon brightness following the scheme. Profile is a tab inside the portal shell, so tab changes belong to the shell; logging out returns to Login through this fade-through. Profile sets the same transparent status bar with scheme-following icons and leaves the navigation bar to the shell.

## Do's and Don'ts

### Do:
- **Do** read colors through `AppPalette` roles so each scheme gets its own built value.
- **Do** keep one raised surface per screen, carrying `raisedShadow`.
- **Do** put every control on the 12dp corner and every border on a 1dp hairline; only focus thickens to 1.6dp.
- **Do** space on the 8dp rhythm (8, 12, 16, 20, 24dp).
- **Do** set figures in tabular numerals.
- **Do** keep touch targets at least 48dp and merge a field's visible label into its semantics.
- **Do** lay list rows on the ground at 56dp or more, divided by 1dp hairlines inset 20dp.
- **Do** end-align values and swap a changed value in place (180ms ease-out-cubic cross-fade) without moving its row.
- **Do** mirror directional icons (arrows, chevrons) in right-to-left.
- **Do** put content on an error fill in `onError`, as content on an action fill uses `onAction`.
- **Do** skip every entrance, transition, and value swap when the system asks for reduced motion.

### Don't:
- **Don't** introduce saturated colors; the error red stays muted and is the only hue outside the slate-navy ladder.
- **Don't** use the previous violet tokens (`AppColors.primary` and its siblings, `AppSurfaces`) on a surface that has moved to this world.
- **Don't** invert Light to make Dark; each scheme has its own role values.
- **Don't** apply negative letter spacing on any role.
- **Don't** add shadows to fields, notices, buttons, or rows, or stack a second raised card on the ticket or badge.
- **Don't** box list rows in cards; they lie on the ground.
- **Don't** use the perforation as a plain divider in lists or sections, or give the badge a stub, notches, or perforation.
- **Don't** fade the ticket in on entrance; it rises once, already visible. The rise stays the ticket's.
