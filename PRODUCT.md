# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users

Company drivers of heavy transport vehicles (telescope, lowbed, and flatbed trucks) working assigned trips. They hold company custody cash and use the app to see what they hold, record trip expenses, move cash, and answer approvals. They sign in both in daylight in the cab and on night shifts (confirmed), often one-handed and between tasks.

## Product Purpose

Driver Portal gives each driver an accurate, trustworthy view of their custody money and the actions that change it: total, available, and frozen balance; recording expenses against trips; sending cash to other drivers; requesting or returning cash to the vault; and confirming incoming transfers, vault receipts, and road expenses. Success is a driver who always knows what they hold and never doubts a number.

## Positioning

A driver's own custody ledger, not a fleet manager's dashboard: every figure is the driver's, every action is one the driver takes, and pending money is shown as reserved rather than hidden.

## Operating Context

- Egypt; amounts in EGP.
- English and Arabic, with full right-to-left layout.
- Mobile phones, sometimes with weak or no connectivity (online-only actions are blocked offline).
- Light, Dark, and System theme preference chosen by the user.

## Capabilities and Constraints

- Flutter app shipping to Android and iOS with one Material 3 design language; Clean Architecture with BLoC.
- Authentication is mock-only for now (one demo driver account); a persisted mock session reopens Home on cold start. A real API will replace it later.
- The platform's default launch screen stays unchanged; no custom splash screen.
- The UI is being redesigned one screen at a time; screens not yet redesigned keep the previous look until their turn.
- Typography uses platform system fonts in this phase (no bundled font assets).

## Brand Commitments

- Product name: Driver Portal.
- Official palette, binding as the foundation of the visual identity: `#111522`, `#1E263B`, `#303D59`, `#536684`, `#98A9C4`, `#DCE3EF`. Light and Dark Mode each get their own roles built from it; not an inversion.
- Professional, clean, and visually balanced; not decorative. Subtle gradients and shadows only; no saturated colors.

## Evidence on Hand

All data is mock demonstration data (balances, trips, drivers, approvals). There are no real customers, testimonials, metrics, or logos; future work must not invent them.

## Product Principles

1. Money first, never ambiguous: a figure is either confirmed or clearly marked as pending or reserved.
2. Calm under pressure: the driver may be tired, outdoors, or in a hurry; clarity beats ornament.
3. One language in two directions: English and Arabic are equal citizens, LTR and RTL.
4. Honest states: loading, offline, errors, and failures are named plainly with a way forward.
5. Smooth by default: lightweight, purposeful motion that never blocks a task.

## Accessibility & Inclusion

- Text meets WCAG AA contrast in both themes (4.5:1 body, 3:1 large text and UI boundaries).
- Layouts tolerate large system font scales and narrow phones without clipping.
- Touch targets at least 48×48 dp.
