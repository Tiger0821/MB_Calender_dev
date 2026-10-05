# Timetable (iOS)

The userscript's timetable dock as an iPhone app with widgets, plus today's
date, a clock, a countdown to Taiwan's next national holiday, and the weather
outside as a pixel-art sky behind the page. One build serves the whole year
group: the first time it opens it asks who you are and which classes are
yours, and lays out your own timetable. Built with
the iOS 27 SDK (Xcode 27); runs on iOS 26 and later.

The userscript it comes from:
[ManageBac Reimagined](https://github.com/Tiger0821/ManageBac-Reimagined).

## Setup

The first time the app is opened it asks a few questions, one to a page:

1. **Your name.** It goes under the clock.
2. **Your form** — 11A or 11B. Each has its own timetable.
3. **Your classes.** The form's classes are sorted into sets that are on at
   the same time, so nobody takes two from one set: Maths (MAA HL, MAA SL,
   MAI HL), the two TOK groups, and so on. Each set is one page and one tap.
   Where a set isn't strictly one-or-the-other — in 11A, Eng B-1 and Eng Lit
   can be taken together, but neither with Eng A-2 — the page lets you pick
   more than one, and picking a class drops any that clash with it.
4. **SL revision**, if any of the classes you picked has a revision class.
5. **Your clubs.** The timetable only says "Service Clubs" and "Academic
   Clubs"; put in what yours are called, with a room and a teacher if you
   like, and a different club for Week 2 if yours alternate. Or leave them
   blank.

Guidance, Weekly Alignment and the clubs are on everyone's timetable and are
never asked about. Any period before 16:05 with none of your classes in it is
shown as IB Core.

Tap your name under the clock to go through it again, already filled in, and
change anything. Changing form keeps the choices the two forms share.

None of the sets are written into the app. `Timetable.catalog(for:)` works
them out from the rows: two classes clash when they are on at the same time
on some day, a class that clashes with nothing is everyone's, and the rest
fall into sets of classes linked by clashes. So when the school changes the
options, the questions follow.

## The app

- Your name and form, then today's date and the time to the second.
- The class running now (or the next one), with the minutes left.
- The next national holiday: whole days while it is more than a day away, then
  hours, minutes and seconds. The three after it are listed underneath.
- A picker for any of the ten days in the cycle, and that day's timetable.
- The weather outside, painted behind it all as pixel art — see
  [Weather](#weather).

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
account. Whose timetable to show they read from the profile setup saves, which
the app and the widgets share through an app group; until setup has been done
they say to open the app. Each widget lays out a timeline with an entry at every bell through
the next two school days; the countdowns in between are drawn by the system.

## Run it

Open `ManageBacTimetable.xcodeproj`, pick a simulator, and press Run.

On your own iPhone: Xcode → Settings → Accounts, sign in with your Apple ID,
then select the project → each of the two targets → Signing & Capabilities →
Team. Both targets have the App Groups capability, which Xcode registers for
your team the first time it signs them.

Building it under a different Apple ID — a classmate building their own copy —
means changing the bundle id `com.tigercho.ManageBacTimetable` (and the
widget's `.Widget` id under it) to something of their own, and the app group
with it, in three places: `Profile.group` in `Shared/Profile.swift`, and the
two `.entitlements` files in `App/` and `Widget/`. The group id has to start
with `group.` and be the same in all three, or the widgets won't see the
profile.

## When the school changes the timetable

```bash
python3 Tools/update_timetable.py
```

That reads the school's published Prime Timetable and rewrites
`Shared/TimetableData.swift` with every lesson of each form, one row each:
subject, day, start, end, staff, room. Build again and everyone's timetable,
and the questions setup asks, follow the new rows. To add a form, add its name
to `FORMS` at the top of the script.

Cards the school has left off the grid (they have no day) are not lessons and
are left out.

## Keeping it in step with the userscript

The timetable logic in `Shared/Timetable.swift` is a port of the userscript's
TIMETABLE section, and for the same classes lays out the same ten days. The
differences are deliberate:

- The userscript has one person's classes written into it; here they come
  from the profile, so `TT_MINE` and `TT_CLUBS` have no constants to match.
- The timetable's "G: Agency [EE, CAS, CC]" block is shown as "Guidance" (see
  `Timetable.displayName`).
- The rows are read from the school's feed by the script above. The
  userscript's `TT_RAW` counts cards with no day as Week 1 Monday, which puts
  two lessons on that day that the published timetable doesn't have (a Bus Man
  at 16:15 and a Chinese revision at 15:40); `TT_SKIP` was there to hide one
  of them. Neither is in the rows here, so there is nothing to skip.

| Userscript   | Here                                            |
|--------------|-------------------------------------------------|
| `TT_RAW`     | `Shared/TimetableData.swift`, from the script   |
| `TT_MINE`    | `Profile.subjects`, picked in setup             |
| `TT_SKIP`    | not needed                                      |
| `TT_CLUBS`   | `Profile.clubs`, typed in setup                 |
| `TT_ANCHOR`  | `Timetable.anchor`                              |
| `TT_SOURCE`  | `Timetable.source`                              |

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

## Weather

The page's background is the sky as it is outside, the way the Weather app
does it, drawn as pixel art: a sun with rays or a crescent moon, stars,
clouds drifting with the wind, rain that leans with it, snow, fog, lightning,
and a line of hills along the bottom. Under the date is a strip of open sky
for it to show in, with the temperature, the conditions, the place and the
day's high and low on glass in its corner.

- The weather is from [Open-Meteo](https://open-meteo.com/), which needs no
  key and no account. It is looked up when the app opens and every ten
  minutes while it stays open, and the last reading is kept for three hours so
  the sky is there at once next time.
- It is for where the phone is, so the app asks to use the location while it
  is open. The position is rounded to about a kilometre before it is sent.
  Refuse, or be offline, and there is no weather: the page keeps its plain
  background and nothing else changes.
- Sunrise and sunset come with the weather, so the sky turns from day through
  twilight to night on its own between readings.
- Over a sky the page is always in its dark colours, since every sky is dark
  at the top where the date is.
- With Reduce Motion on, the sky is painted once and left still.
- Nothing is an image file. `PixelSky.swift` paints each frame into a small
  grid of pixels, fifteen times a second, and scales it up unsmoothed.

To see a sky without waiting for the weather, launch with the argument
`-demoWeather` and a sky and a time of day — `-demoWeather thunderstorm-night`,
say. The skies are `clear`, `mostlyClear`, `partlyCloudy`, `overcast`, `fog`,
`drizzle`, `rain`, `heavyRain`, `snow` and `thunderstorm`; the times are `day`,
`twilight` and `night`. In Xcode that is Product → Scheme → Edit Scheme → Run →
Arguments.

The widgets do not show the weather and still use no network.

## Layout

- `Shared/` — the timetable and its styling; compiled into both targets.
  `TimetableData.swift` is the rows for each form, `Profile.swift` is whose
  timetable it is, and `Timetable.swift` lays one person's fortnight out.
- `App/` — the app: date and clock, Now card, holiday card, the ten-day
  picker, the day's timetable. `SetupView.swift` is setup.
  `ReorderableStack.swift` is the hold-and-drag reordering, edge scrolling
  included. `Weather.swift` fetches the weather and `PixelSky.swift` paints
  it.
- `Tools/` — `update_timetable.py`, which rebuilds the rows from the school's
  published timetable.
- `Widget/` — the widget extension.

The folders are synchronised groups, so a file dropped into one in Finder or
Xcode is picked up by that folder's targets without editing the project.

## License

MIT — see [LICENSE](LICENSE).

The timetable logic is a port of the TIMETABLE section of the
[ManageBac Reimagined](https://github.com/Tiger0821/ManageBac-Reimagined)
userscript, written by Arstoien and extended by Tiger0821.
