# Timetable (iOS)

The userscript's timetable dock as an iPhone app with widgets, plus today's
date, a clock, and a countdown to Taiwan's next national holiday. Built with
the iOS 27 SDK (Xcode 27); runs on iOS 26 and later.

The userscript it comes from:
[ManageBac Reimagined](https://github.com/Tiger0821/ManageBac-Reimagined).

## The app

- Today's date and the time to the second, at the top.
- The class running now (or the next one), with the minutes left.
- The next national holiday: whole days while it is more than a day away, then
  hours, minutes and seconds. The three after it are listed underneath.
- A picker for any of the ten days in the cycle, and that day's timetable.

The four boxes — class, holiday, day picker, timetable — can be put in any
order: touch and hold one until it lifts, drag it, and the others slide out of
its way. Hold it near the top or bottom of the screen and the page scrolls
under it, so a box can travel further than one screen. The order is remembered
(`boxOrder` in the app's defaults). A swipe still scrolls the page and a tap
still picks a day; only a held finger lifts a box.

## Widgets

- **Now & Next** — small, medium, and three Lock Screen sizes (inline,
  circular, rectangular). The class running now with a live countdown and
  progress bar, and what's next. Before school, after it and at weekends it
  shows the first class of the next school day instead.
- **Today** — large. The whole day as the dock lays it out: finished blocks
  greyed back, the current one filled in with its countdown.
- **Holiday Countdown** — small, medium, and the three Lock Screen sizes. Days
  to the next national holiday, switching to a live hours:minutes:seconds
  countdown once it is under a day away. The medium size adds today's date and
  a running clock.

Add them by touching and holding the Home Screen or Lock Screen → Edit →
Add Widget → search "Timetable".

The timetable is built into the app, so the widgets need no network and no
account. Each widget lays out a timeline with an entry at every bell through
the next two school days; the countdowns in between are drawn by the system.

## Run it

Open `ManageBacTimetable.xcodeproj`, pick a simulator, and press Run.

On your own iPhone: Xcode → Settings → Accounts, sign in with your Apple ID,
then select the project → each of the two targets → Signing & Capabilities →
Team. If the bundle id is taken, change `com.tigercho.ManageBacTimetable` (and
the widget's `.Widget` id under it) to something of your own.

## Keeping it in step with the userscript

The timetable logic in `Shared/Timetable.swift` is a port of the userscript's
TIMETABLE section, and produces the same ten days row for row — with one
deliberate difference: the timetable's "G: Agency [EE, CAS, CC]" block is
shown as "Guidance" (see `Timetable.displayName`). When something changes,
change it in both:

| Userscript   | Here                                   |
|--------------|----------------------------------------|
| `TT_RAW`     | `Shared/TimetableData.swift`           |
| `TT_MINE`    | `Timetable.mine`                       |
| `TT_SKIP`    | `Timetable.skip`                       |
| `TT_CLUBS`   | `Timetable.clubs`                      |
| `TT_ANCHOR`  | `Timetable.anchor`                     |
| `TT_SOURCE`  | `Timetable.source`                     |

Subject colours are in `Shared/SubjectStyle.swift`.

## Holidays

`Shared/Holidays.swift` lists Taiwan's national holidays from the government
office calendars for 2026 (民國115年) and 2027 (116年), from National Day 2026
through New Year's Day 2028, with the weekday given off when one lands on a
weekend. The lunar festivals move every year, so add the 2028 dates when that
calendar is published — after the last entry the countdown simply disappears.

The countdown runs to midnight at the start of the holiday itself (not the
substitute day off), in the phone's own time zone. The timetable does not know
about holidays: classes are still shown on a day off.

## Layout

- `Shared/` — the timetable and its styling; compiled into both targets.
- `App/` — the app: date and clock, Now card, holiday card, the ten-day
  picker, the day's timetable. `ReorderableStack.swift` is the hold-and-drag
  reordering, edge scrolling included.
- `Widget/` — the widget extension.

The folders are synchronised groups, so a file dropped into one in Finder or
Xcode is picked up by that folder's targets without editing the project.
