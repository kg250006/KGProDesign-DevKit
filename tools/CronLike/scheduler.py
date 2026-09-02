"""Fire-time computation, catch-up decisions, and run-state persistence.

Everything here is pure clock arithmetic over the typed job dicts produced by
schedule_config.normalize(). No job is executed from this module.
"""

import json
import os
from datetime import datetime, time, timedelta
from pathlib import Path

# -- Search horizons --------------------------------------------------------

# Eight days back guarantees at least one hit for any weekly pattern, so a job
# that runs only on Mondays still resolves its previous slot on a Sunday.
LOOKBACK_DAYS = 8

# Forward search has to clear a monthly pattern, so it runs well past a year
# rather than stopping at a week.
LOOKAHEAD_DAYS = 400


# -- Job --------------------------------------------------------------------

class Job:
    """One normalized schedule entry.

    Attributes come straight from schedule_config.normalize(); this class adds
    the timing methods and holds no config-parsing logic of its own.
    """

    def __init__(self, spec):
        self.name = spec["name"]
        self.enabled = spec["enabled"]
        self.when = spec["when"]
        self.run = spec["run"]
        self.cwd = spec["cwd"]
        self.catch_up_within = spec["catch_up_within"]
        self.timeout = spec["timeout"]

    def __repr__(self):
        return f"<Job {self.name!r} enabled={self.enabled}>"

    def _at_slots_for(self, day):
        """Return the datetimes this job would fire on the given date."""
        if day.weekday() not in self.when["days"]:
            return []
        return [datetime.combine(day, t) for t in self.when["at"]]

    def _every_slots_for(self, day):
        """Return interval slots for the given date.

        Anchored at the window start and stepped by `every` seconds, not at
        process start time. That anchoring is what keeps a 30-minute job
        landing on :00 and :30 rather than drifting to :07 and :37 after a
        restart.
        """
        if day.weekday() not in self.when["days"]:
            return []
        start, end = self.when.get("between", (time(0, 0), time(23, 59, 59)))
        cursor = datetime.combine(day, start)
        limit = datetime.combine(day, end)
        step = timedelta(seconds=self.when["every"])
        slots = []
        while cursor <= limit:
            slots.append(cursor)
            cursor += step
        return slots

    def _slots_for(self, day):
        """Return every scheduled fire time on the given date, ascending.

        day_of_month intersects with the weekday filter rather than replacing
        it, so "the 1st, but only when it is a weekday" is expressible.
        """
        dom = self.when.get("day_of_month")
        if dom is not None and day.day not in dom:
            return []
        if "at" in self.when:
            return self._at_slots_for(day)
        return self._every_slots_for(day)

    def previous_fire(self, now):
        """Most recent scheduled fire time at or before `now`, or None.

        Walks back day by day so weekday filters and calendar shapes are
        handled by the same code that computes today's slots.
        """
        day = now.date()
        for _ in range(LOOKBACK_DAYS):
            candidates = [s for s in self._slots_for(day) if s <= now]
            if candidates:
                return max(candidates)
            day -= timedelta(days=1)
        return None

    def next_fire(self, now):
        """Earliest scheduled fire time strictly after `now`, or None.

        Used for the tray's "Next:" line and for --check output, never for the
        firing decision itself.
        """
        day = now.date()
        for _ in range(LOOKAHEAD_DAYS):
            candidates = [s for s in self._slots_for(day) if s > now]
            if candidates:
                return min(candidates)
            day += timedelta(days=1)
        return None


# -- Run state --------------------------------------------------------------

class RunState:
    """Last-successful-fire timestamps, keyed by job name.

    Losing run history is an inconvenience; refusing to start because the
    history file is unreadable is an outage. Every read path here degrades to
    empty state rather than raising.
    """

    def __init__(self, path):
        self.path = Path(path)
        self._data = {"last_run": {}}

    def load(self):
        """Read state.json. A missing or corrupt file yields empty state."""
        self._data = {"last_run": {}}
        try:
            raw = json.loads(self.path.read_text(encoding="utf-8"))
        except (OSError, ValueError):
            return self
        last_run = raw.get("last_run") if isinstance(raw, dict) else None
        if isinstance(last_run, dict):
            for name, stamp in last_run.items():
                try:
                    self._data["last_run"][name] = datetime.fromisoformat(stamp)
                except (TypeError, ValueError):
                    continue
        return self

    def save(self):
        """Write state.json atomically: temp file first, then os.replace."""
        payload = {
            "last_run": {
                name: when.isoformat(timespec="seconds")
                for name, when in self._data["last_run"].items()
            }
        }
        tmp = self.path.with_name(self.path.name + ".tmp")
        tmp.write_text(json.dumps(payload, indent=2), encoding="utf-8")
        os.replace(tmp, self.path)

    def get(self, job_name):
        """Return the last recorded fire time for a job, or None."""
        return self._data["last_run"].get(job_name)

    def set(self, job_name, when):
        """Record a job's fire time in memory. Call save() to persist."""
        self._data["last_run"][job_name] = when

    def seed_missing(self, jobs, now):
        """Give every job with no recorded run a last_run of `now`.

        Called once at startup, before the first tick. Without it, a first
        launch treats every past slot inside the catch-up window as
        outstanding and fires the day's backlog at once.
        """
        changed = False
        for job in jobs:
            if self.get(job.name) is None:
                self.set(job.name, now)
                changed = True
        if changed:
            self.save()
        return changed


# -- Catch-up decision ------------------------------------------------------

FIRE = "fire"
MISSED = "missed"
IDLE = "idle"


def evaluate(job, state, now):
    """Return (verdict, slot) for one job.

    IDLE   no outstanding slot, or the job is disabled
    FIRE   an outstanding slot inside the catch-up window
    MISSED an outstanding slot older than the window

    A slot is outstanding when the job has no recorded run, or its recorded run
    predates the slot. Because the caller advances state on both FIRE and
    MISSED, the same slot is never considered twice.
    """
    if not job.enabled:
        return IDLE, None
    slot = job.previous_fire(now)
    if slot is None:
        return IDLE, None
    last = state.get(job.name)
    if last is not None and last >= slot:
        return IDLE, None
    lateness = (now - slot).total_seconds()
    if lateness <= job.catch_up_within:
        return FIRE, slot
    return MISSED, slot


def due_jobs(jobs, state, now):
    """Yield (job, verdict, slot) for every job with a non-IDLE verdict."""
    for job in jobs:
        verdict, slot = evaluate(job, state, now)
        if verdict != IDLE:
            yield job, verdict, slot


# -- Human-readable rendering -----------------------------------------------

_DAY_LABELS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
_NAMED_DAY_SETS = {
    frozenset({0, 1, 2, 3, 4, 5, 6}): "every day",
    frozenset({0, 1, 2, 3, 4}): "weekdays",
    frozenset({5, 6}): "weekends",
}


def _join_and(items):
    """Join a list into "a", "a and b", or "a, b and c"."""
    items = list(items)
    if not items:
        return ""
    if len(items) == 1:
        return items[0]
    return ", ".join(items[:-1]) + " and " + items[-1]


def _humanize_days(days):
    """Render a weekday set as a group name or a list of day abbreviations."""
    named = _NAMED_DAY_SETS.get(frozenset(days))
    if named:
        return named
    return _join_and([_DAY_LABELS[d] for d in sorted(days)])


def _humanize_duration(seconds):
    """Render whole seconds as the largest unit that divides evenly."""
    for size, unit in ((3600, "hour"), (60, "minute")):
        if seconds >= size and seconds % size == 0:
            amount = seconds // size
            return unit if amount == 1 else f"{amount} {unit}s"
    return "second" if seconds == 1 else f"{seconds} seconds"


def _ordinal(n):
    """Render an integer as 1st, 2nd, 3rd, 4th, and so on."""
    if 10 <= n % 100 <= 20:
        suffix = "th"
    else:
        suffix = {1: "st", 2: "nd", 3: "rd"}.get(n % 10, "th")
    return f"{n}{suffix}"


def describe(job):
    """Render a job's schedule as an English phrase.

    Examples:
        "weekdays at 07:45"
        "Mon and Fri at 09:00 and 16:30"
        "every 30 minutes on weekdays between 09:00 and 17:00"
        "on the 1st and 15th at 08:00"
    """
    when = job.when
    days = when.get("days", set())
    dom = when.get("day_of_month")

    if dom:
        day_phrase = "on the " + _join_and([_ordinal(d) for d in sorted(dom)])
        if frozenset(days) not in (frozenset({0, 1, 2, 3, 4, 5, 6}), frozenset()):
            day_phrase += f" when it falls on {_humanize_days(days)}"
    else:
        day_phrase = _humanize_days(days)

    if "at" in when:
        times = _join_and([t.strftime("%H:%M") for t in when["at"]])
        return f"{day_phrase} at {times}".strip()

    start, end = when["between"]
    phrase = f"every {_humanize_duration(when['every'])}"
    if day_phrase == "every day":
        day_phrase = ""
    if day_phrase:
        phrase += f" on {day_phrase}" if not day_phrase.startswith("on ") else f" {day_phrase}"
    return f"{phrase} between {start.strftime('%H:%M')} and {end.strftime('%H:%M')}"
