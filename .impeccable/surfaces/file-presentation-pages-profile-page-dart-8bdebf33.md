---
version: 1
slug: "file-presentation-pages-profile-page-dart-8bdebf33"
primary_target: "lib/features/profile/presentation/pages/profile_page.dart"
related_targets: ["lib/features/profile/presentation/language_sheet.dart","lib/features/profile/presentation/logout_dialog.dart"]
---

# Profile

Scope: the Profile tab inside PortalShell, plus its language and logout sheets (Operate mode). Audience: company drivers checking who they are signed in as and changing language, theme, or session, often one-handed in a cab, day or night. Task: confirm identity and custody at a glance (balance secondary; Home owns the money), jump to Balance, Approvals, or History, switch language or Dark Mode, log out. Constraints: every widget key, BLoC dependency, navigation target, pending-count behaviour, language and theme persistence, logout flow, and the loading, failure, retry, and offline states stay exactly as they are; system fonts; English and Arabic RTL; Light and Dark; reduced motion respected. Must not read as a generic settings list, heavy or decorative, a copy of the Login ticket, disconnected from Login, or too dense for one-handed use.

Approved decisions: the badge grid gets new short labels (ID, Vault, Balance) in English and Arabic; section labels use sentence case, updating the three test strings that expect uppercase. Still open: the floating nav and shell stay in the previous style until their turn.

## Direction contract

THESIS: Profile is the driver's company ID: one laminated badge states who you are, and everything you can change sits loose below it. It refuses the category default of a dark avatar band over boxed settings cards.

OWN-WORLD: Login's official slate-navy world through AppPalette roles, built twice: Light is mist ground, white badge, ink initials tile; Dark is ink ground, lifted navy badge, pale tile. Login's system type scale, 12dp controls, 1dp hairlines, tabular figures, and one raisedShadow on the badge only. No notches, stub, or perforation; no tinted icon tiles; rows are divided by hairlines on the ground.

STORY: The driver sees their name, ID, vault, and a quiet balance at once, then reaches Quick Access, Settings, and Account with one thumb, and never feels they left Login's world.

FIRST VIEWPORT: Profile in Display at a 20dp inset. Below it, a 20dp-cornered badge with a punched lanyard slot at top centre: a 64dp ink initials tile beside the name, then a hairline-ruled ID / Vault / Balance grid with values end-aligned in tabular figures. Then Quick access, Settings, and Account labels over 56dp hairline rows (20dp icon, title, end-aligned value or count, directional chevron); Dark Mode keeps its switch; Logout uses the error role. The floating nav is unchanged.

FORM: Company ID badge, position 1 of 7 on the ordered list, a dealt structure; seed:9263a51e12dc131d. Signature: the lanyard slot and the label-value grid. Motion grammar: a changed value swaps in place over 180ms without moving its row, and every motion is skipped under reduced motion; no entrance rise, which stays the Login ticket's.

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance
