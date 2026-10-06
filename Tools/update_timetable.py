#!/usr/bin/env python3
"""Rebuild Shared/TimetableData.swift from the school's published Prime Timetable.

Run it from the project folder whenever the school republishes:

    python3 Tools/update_timetable.py

It reads the published feed, keeps the lessons of the forms in FORMS, and
writes one row per lesson: subject ~ day ~ start ~ end ~ staff ~ room. To add
a form, add its name to FORMS as the timetable spells it.
"""
import json
import re
import urllib.request
from datetime import date
from pathlib import Path

PUBLICATION = "3d9e5ee3-c15b-41f7-810c-0e16e6cafa92"
FORMS = ["11A", "11B"]
FEED = f"https://primetimetable.com/api/v2/timetables/{PUBLICATION}/"
OUT = Path(__file__).resolve().parent.parent / "Shared" / "TimetableData.swift"


def tidy(text):
    """The feed's names carry stray spaces: 'DP Bio ', 'Nancy  Huang'."""
    return re.sub(r"\s+", " ", text).strip()


def clock(period, edge):
    return f"{period.get(edge + 'Hour', 0):02d}:{period.get(edge + 'Minute', 0):02d}"


def rows(feed, form):
    by_id = lambda key: {item["id"]: item for item in feed[key]}
    subjects, teachers, rooms, days, periods = (by_id(k) for k in ("subjects", "teachers", "rooms", "days", "periods"))
    # The bells everyone shares, in order. A lesson starts on one and runs for `length` of them.
    bells = sorted((p for p in feed["periods"] if "entityId" not in p and "dayId" not in p),
                   key=lambda p: p.get("position", 1))
    bell_index = {p["id"]: i for i, p in enumerate(bells)}

    school_class = next(c for c in feed["classes"] if tidy(c["name"]) == form)
    groups = {g["id"] for group_set in school_class["groupSets"] for g in group_set["groups"]}

    out = set()
    for activity in feed["activities"]:
        if not groups & set(activity.get("groupIds", [])):
            continue
        for card in activity.get("cards", []):
            # A card with no day has been left off the grid: it is not a lesson.
            if "dayId" not in card:
                continue
            if card["periodId"] in bell_index:
                i = bell_index[card["periodId"]]
                first, last = bells[i], bells[min(i + activity.get("length", 1) - 1, len(bells) - 1)]
            else:
                # A period made for one activity (the clubs) carries its own times.
                first = last = periods[card["periodId"]]
            out.add((
                days[card["dayId"]].get("position", 1) - 1,
                clock(first, "start"),
                clock(last, "end"),
                tidy(subjects[activity["subjectId"]]["name"]),
                ";".join(tidy(teachers[t]["name"]) for t in activity.get("teacherIds", [])),
                ";".join(tidy(rooms[r]["name"]) for r in card.get("roomIds", activity.get("roomIds", []))),
            ))
    return ["~".join([subject, str(day), start, end, staff, room]) for day, start, end, subject, staff, room in sorted(out)]


def main():
    with urllib.request.urlopen(FEED, timeout=60) as response:
        feed = json.load(response)
    today = date.today()
    read_on = f"{today.day} {today.strftime('%b %Y')}"
    class_ids = {tidy(c["name"]): c["id"] for c in feed["classes"]}

    lines = [
        "/* The school's two-week timetable for each form, written by",
        "   Tools/update_timetable.py from the published Prime Timetable. Don't edit",
        "   the rows by hand: when the school republishes, run the script again.",
        "",
        "   subject ~ day ~ start ~ end ~ staff ~ room",
        "   Days 0-4 are Week 1 (the columns it numbers 1..5), 5-9 Week 2 (Mon..Fri).",
        "   Cards the school has left off the grid are not lessons and are left out. */",
        "enum TimetableData {",
        "    /// The edition the rows were read from, and the day they were read.",
        f"    static let edition = \"{tidy(feed['name'])}\"",
        f"    static let readOn = \"{read_on}\"",
        "",
        "    /// The published timetable, and each form's own page on it, in the order",
        "    /// setup offers them.",
        f"    static let publication = \"{PUBLICATION}\"",
        "    static let forms: [(name: String, id: String)] = [",
        *[f"        (\"{form}\", \"{class_ids[form]}\")," for form in FORMS],
        "    ]",
        "",
        "    static let rows: [String: String] = [",
    ]
    for form in FORMS:
        form_rows = rows(feed, form)
        lines += [f"        \"{form}\": #\"\"\"", *form_rows, "\"\"\"#,"]
        print(f"{form}: {len(form_rows)} rows")
    lines += ["    ]", "}", ""]
    OUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"wrote {OUT.relative_to(OUT.parent.parent)} from \"{tidy(feed['name'])}\" (feed last changed {feed['updatedAt'][:10]})")


if __name__ == "__main__":
    main()
