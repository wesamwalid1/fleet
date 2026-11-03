---
version: 1
slug: "s-auth-presentation-pages-login-page-dart-0d4a4145"
primary_target: "lib/features/auth/presentation/pages/login_page.dart"
related_targets: ["lib/features/auth/presentation/widgets/login_form.dart","lib/features/auth/presentation/widgets/login_header.dart"]
---

# Login

Scope: the sign-in screen (Operate mode). Audience: company drivers signing in from the cab in daylight or on night shifts. Task: enter the demo driver email and password and reach Home; see validation, offline, and credential errors plainly. Constraints: existing mock auth, BLoC states, l10n strings, widget keys, theme preference, and launch screen stay unchanged; system fonts; new palette tokens used on Login only.

## Direction contract

THESIS: Signing in is being issued your driver ticket; the screen refuses the category default of a dark marketing band with a floating white card.

OWN-WORLD: Official slate-navy palette in two built schemes: light is mist ground, white ticket, ink action; dark is ink ground, lifted navy ticket, mist action. Hairline borders only, tabular figures, 8dp rhythm, one soft offset shadow.

STORY: The driver recognises Driver Portal, sees exactly two fields and one action, understands any error at once, and is moved to Home without a jolt.

FIRST VIEWPORT: Vertically centred ticket, max 440dp wide: a stub row with the route mark and the product name, a perforated tear line with side notches, then the welcome headline, subtitle, labelled email and password fields, the error banner when present, and a full-width Sign In action at the bottom of the ticket. Help line sits under the ticket.

FORM: Fuel / weighbridge ticket, position 5 of 7; seed:aa4de8db44fd5662. Signature move: the perforated tear line; motion grammar: the ticket rises once into place (no fade), the action swaps label for spinner, and Login and Home meet through one shared fade-through.

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance
