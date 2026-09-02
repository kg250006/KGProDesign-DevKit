"""Configuration loading and validation for CronLike.

Owns every path under ~/.cronlike/ and every user-facing config error message.
Nothing else in the tool is allowed to build one of these paths by hand.
"""

import json
from datetime import time
from pathlib import Path

# -- Filesystem layout ------------------------------------------------------

CONFIG_DIR_NAME = ".cronlike"
SCHEDULE_FILE = "schedule.json"
STATE_FILE = "state.json"
LOCK_FILE = "cronlike.lock"
LOGS_DIR = "logs"


# -- Errors -----------------------------------------------------------------

class ConfigError(Exception):
    """Raised when schedule.json is missing, unparseable, or invalid.

    The message is shown verbatim to the user, so it must name the job and the
    field whenever the problem is job-specific.
    """


# -- Paths ------------------------------------------------------------------

def config_dir() -> Path:
    """Return ~/.cronlike/, creating it if absent.

    Returns:
        Path to the configuration directory.
    """
    d = Path.home() / CONFIG_DIR_NAME
    d.mkdir(parents=True, exist_ok=True)
    return d


def schedule_path() -> Path:
    """Return the path to schedule.json.

    Returns:
        Path to the live schedule file, which may not exist yet.
    """
    return config_dir() / SCHEDULE_FILE


def state_path() -> Path:
    """Return the path to state.json.

    Returns:
        Path to the run-state file, which may not exist yet.
    """
    return config_dir() / STATE_FILE


def lock_path() -> Path:
    """Return the path to cronlike.lock.

    Returns:
        Path to the single-instance lockfile, which may not exist yet.
    """
    return config_dir() / LOCK_FILE


def logs_dir() -> Path:
    """Return ~/.cronlike/logs/, creating it if absent.

    Returns:
        Path to the log directory.
    """
    d = config_dir() / LOGS_DIR
    d.mkdir(parents=True, exist_ok=True)
    return d


# -- Loading ----------------------------------------------------------------

def load_raw(path=None) -> dict:
    """Read and JSON-parse schedule.json.

    Args:
        path: optional explicit path. Defaults to schedule_path().

    Returns:
        The parsed JSON document, unvalidated.

    Raises:
        ConfigError: file missing, unreadable, or not valid JSON. A syntax
            error reports the line and column so the typo can be found.
    """
    p = Path(path) if path is not None else schedule_path()
    if not p.exists():
        raise ConfigError(f"No schedule file at {p}. Run: python cronlike.py --init")
    try:
        text = p.read_text(encoding="utf-8")
    except OSError as e:
        raise ConfigError(f"Could not read {p}: {e}")
    try:
        return json.loads(text)
    except json.JSONDecodeError as e:
        raise ConfigError(
            f"{p} is not valid JSON: {e.msg} at line {e.lineno} column {e.colno}"
        )


# -- Validation vocabulary --------------------------------------------------

VALID_DAY_NAMES = {"mon", "tue", "wed", "thu", "fri", "sat", "sun"}
VALID_DAY_GROUPS = {"daily", "weekdays", "weekends"}
TOP_KEYS = {"version", "settings", "jobs"}
SETTINGS_KEYS = {"check_every", "notify_on_failure"}
JOB_KEYS = {"name", "enabled", "when", "run", "cwd", "catch_up_within", "timeout"}
WHEN_KEYS = {"days", "at", "every", "between", "day_of_month"}

_UNITS = {
    "second": 1, "seconds": 1,
    "minute": 60, "minutes": 60,
    "hour": 3600, "hours": 3600,
}


def _as_list(value) -> list:
    """Wrap a scalar in a list; pass a list or tuple through unchanged.

    Args:
        value: a scalar, list, or tuple.

    Returns:
        A list.
    """
    if isinstance(value, (list, tuple)):
        return list(value)
    return [value]


def _where(label, field) -> str:
    """Render the "which field of which job" prefix used in error messages.

    Args:
        label: job name, or None when the value has no owning job.
        field: field name.

    Returns:
        A message prefix ending in the quoted field name.
    """
    return f'job "{label}": "{field}"' if label else f'"{field}"'


def _check_time(label, field: str, value) -> None:
    """Validate one "HH:MM" 24-hour clock string.

    Args:
        label: job name, or None when the value has no owning job.
        field: field name, used in the error message.
        value: the candidate value.

    Raises:
        ConfigError: not a string, not HH:MM, or out of range.
    """
    if not isinstance(value, str):
        raise ConfigError(
            f'{_where(label, field)} must be a "HH:MM" string, '
            f"got {type(value).__name__}"
        )
    parts = value.split(":")
    if len(parts) != 2 or not all(p.isdigit() for p in parts):
        raise ConfigError(
            f'{_where(label, field)} value "{value}" is not a "HH:MM" 24-hour time'
        )
    hour, minute = int(parts[0]), int(parts[1])
    if not 0 <= hour <= 23:
        raise ConfigError(
            f'{_where(label, field)} value "{value}" has hour {hour}; must be 0-23'
        )
    if not 0 <= minute <= 59:
        raise ConfigError(
            f'{_where(label, field)} value "{value}" has minute {minute}; must be 0-59'
        )


def _check_duration(label, field: str, value) -> None:
    """Validate one "<amount> <unit>" duration string.

    Args:
        label: job name, "settings", or None when there is no owning job.
        field: field name, used in the error message.
        value: the candidate value.

    Raises:
        ConfigError: not a string, malformed, or an unrecognised unit.
    """
    if not isinstance(value, str):
        raise ConfigError(
            f'{_where(label, field)} must be a duration string like "30 minutes", '
            f"got {type(value).__name__}"
        )
    parts = value.split()
    if len(parts) != 2 or not parts[0].lstrip("-").isdigit():
        raise ConfigError(
            f'{_where(label, field)} value "{value}" is not a duration '
            f'like "30 minutes"'
        )
    if parts[1] not in _UNITS:
        raise ConfigError(
            f'{_where(label, field)} has unrecognised unit "{parts[1]}". '
            f'Valid units: {", ".join(sorted(_UNITS))}'
        )
    if int(parts[0]) < 0:
        raise ConfigError(
            f'{_where(label, field)} value "{value}" must not be negative'
        )


def _validate_settings(settings) -> None:
    """Validate the optional top-level settings object.

    Args:
        settings: the raw settings value.

    Raises:
        ConfigError: wrong type, unknown key, or a bad value.
    """
    if not isinstance(settings, dict):
        raise ConfigError('"settings" must be an object')
    for k in settings:
        if k not in SETTINGS_KEYS:
            raise ConfigError(
                f'settings: unknown field "{k}". '
                f'Valid fields: {", ".join(sorted(SETTINGS_KEYS))}'
            )
    if "check_every" in settings:
        _check_duration("settings", "check_every", settings["check_every"])
    if "notify_on_failure" in settings:
        if not isinstance(settings["notify_on_failure"], bool):
            raise ConfigError('settings: "notify_on_failure" must be true or false')


def _validate_when(label: str, w) -> None:
    """Validate one job's "when" object.

    Args:
        label: job name, used in error messages.
        w: the raw when value.

    Raises:
        ConfigError: on the first problem found.
    """
    if not isinstance(w, dict):
        raise ConfigError(f'job "{label}": "when" must be an object')

    for k in w:
        if k not in WHEN_KEYS:
            raise ConfigError(
                f'job "{label}": unknown "when" field "{k}". '
                f'Valid: {", ".join(sorted(WHEN_KEYS))}'
            )

    # Composition rules.
    if "at" in w and "every" in w:
        raise ConfigError(
            f'job "{label}": "at" and "every" are mutually exclusive. Use one.'
        )
    if "at" not in w and "every" not in w:
        raise ConfigError(f'job "{label}": "when" needs either "at" or "every".')
    if "between" in w and "every" not in w:
        raise ConfigError(f'job "{label}": "between" requires "every".')

    # days
    if "days" in w:
        days = w["days"]
        if isinstance(days, str):
            if days not in VALID_DAY_GROUPS:
                raise ConfigError(
                    f'job "{label}": "days" value "{days}" is not a known group. '
                    f'Valid groups: {", ".join(sorted(VALID_DAY_GROUPS))}, '
                    f'or a list of {", ".join(sorted(VALID_DAY_NAMES))}'
                )
        elif isinstance(days, list):
            if not days:
                raise ConfigError(f'job "{label}": "days" list must not be empty')
            for d in days:
                if not isinstance(d, str) or d not in VALID_DAY_NAMES:
                    raise ConfigError(
                        f'job "{label}": "days" entry "{d}" is not a day name. '
                        f'Valid: {", ".join(sorted(VALID_DAY_NAMES))}'
                    )
        else:
            raise ConfigError(
                f'job "{label}": "days" must be a group name or a list of day names'
            )

    # at
    if "at" in w:
        at_values = _as_list(w["at"])
        if not at_values:
            raise ConfigError(f'job "{label}": "at" must not be empty')
        for t in at_values:
            _check_time(label, "at", t)

    # every
    if "every" in w:
        _check_duration(label, "every", w["every"])
        amount, unit = str(w["every"]).split()
        if int(amount) * _UNITS[unit] <= 0:
            raise ConfigError(f'job "{label}": "every" must be greater than zero')

    # between
    if "between" in w:
        b = w["between"]
        if not isinstance(b, (list, tuple)) or len(b) != 2:
            raise ConfigError(
                f'job "{label}": "between" must be a two-element list, '
                f'for example ["09:00", "17:00"]'
            )
        _check_time(label, "between", b[0])
        _check_time(label, "between", b[1])
        if b[0] >= b[1]:
            raise ConfigError(
                f'job "{label}": "between" start "{b[0]}" must be earlier '
                f'than end "{b[1]}"'
            )

    # day_of_month
    if "day_of_month" in w:
        for d in _as_list(w["day_of_month"]):
            if not isinstance(d, int) or isinstance(d, bool):
                raise ConfigError(
                    f'job "{label}": "day_of_month" entry "{d}" must be a '
                    f"whole number 1-31"
                )
            if not 1 <= d <= 31:
                raise ConfigError(
                    f'job "{label}": "day_of_month" entry {d} is out of range; '
                    f"must be 1-31"
                )


def validate(raw) -> dict:
    """Validate the parsed config, raising on the first problem found.

    Every message names the job and the offending field, because the message is
    the whole diagnostic: once the JSON has parsed there is no line number left
    to point at.

    Args:
        raw: the parsed schedule document.

    Returns:
        The same document, unchanged, so calls can be chained.

    Raises:
        ConfigError: on the first problem found.
    """
    if not isinstance(raw, dict):
        raise ConfigError("Top level of schedule.json must be an object")

    for k in raw:
        if k not in TOP_KEYS:
            raise ConfigError(
                f'unknown top-level field "{k}". '
                f'Valid fields: {", ".join(sorted(TOP_KEYS))}'
            )

    if "settings" in raw:
        _validate_settings(raw["settings"])

    if "jobs" not in raw:
        raise ConfigError('schedule.json must contain a "jobs" array')
    if not isinstance(raw["jobs"], list):
        raise ConfigError('"jobs" must be an array')

    seen = set()
    for i, job in enumerate(raw["jobs"]):
        if not isinstance(job, dict):
            raise ConfigError(f"jobs[{i}]: each job must be an object")
        label = job.get("name") or f"jobs[{i}]"

        # Required fields.
        if "name" not in job:
            raise ConfigError(f'jobs[{i}]: missing required field "name"')
        if not isinstance(job["name"], str) or not job["name"].strip():
            raise ConfigError(f'jobs[{i}]: "name" must be a non-empty string')
        if "run" not in job:
            raise ConfigError(f'job "{label}": missing required field "run"')
        if "when" not in job:
            raise ConfigError(f'job "{label}": missing required field "when"')

        # Unique name: it is the identity key for run state.
        if job["name"] in seen:
            raise ConfigError(
                f'duplicate job name "{job["name"]}". Names must be unique; '
                f"they key the run history."
            )
        seen.add(job["name"])

        # Unknown keys are hard errors, never silent no-ops.
        for k in job:
            if k not in JOB_KEYS:
                raise ConfigError(
                    f'job "{label}": unknown field "{k}". '
                    f'Valid fields: {", ".join(sorted(JOB_KEYS))}'
                )

        # Optional field shapes.
        if "enabled" in job and not isinstance(job["enabled"], bool):
            raise ConfigError(f'job "{label}": "enabled" must be true or false')
        if not isinstance(job["run"], (str, list)):
            raise ConfigError(
                f'job "{label}": "run" must be a command string or an argv list'
            )
        if isinstance(job["run"], str) and not job["run"].strip():
            raise ConfigError(f'job "{label}": "run" must not be empty')
        if isinstance(job["run"], list):
            if not job["run"]:
                raise ConfigError(f'job "{label}": "run" argv list must not be empty')
            for part in job["run"]:
                if not isinstance(part, str):
                    raise ConfigError(
                        f'job "{label}": every entry in the "run" argv list '
                        f"must be a string"
                    )
        if "cwd" in job and not isinstance(job["cwd"], str):
            raise ConfigError(f'job "{label}": "cwd" must be a path string')
        if "catch_up_within" in job:
            _check_duration(label, "catch_up_within", job["catch_up_within"])
        if "timeout" in job:
            _check_duration(label, "timeout", job["timeout"])

        _validate_when(label, job["when"])

    return raw


# -- Normalization ----------------------------------------------------------

DEFAULT_CHECK_EVERY = 30            # seconds between scheduling passes
DEFAULT_TIMEOUT = 900               # 15 minutes
DEFAULT_CATCH_UP = 0                # no catch-up unless the job asks for one
DEFAULT_NOTIFY_ON_FAILURE = True

_DAY_INDEX = {"mon": 0, "tue": 1, "wed": 2, "thu": 3, "fri": 4, "sat": 5, "sun": 6}
_DAY_GROUPS = {
    "daily": {0, 1, 2, 3, 4, 5, 6},
    "weekdays": {0, 1, 2, 3, 4},
    "weekends": {5, 6},
}

_WINDOW_START = time(0, 0)
_WINDOW_END = time(23, 59, 59)


def parse_duration(text: str) -> int:
    """Convert "30 minutes" / "2 hours" / "45 seconds" to whole seconds.

    Args:
        text: a duration string of the form "<amount> <unit>".

    Returns:
        The duration in whole seconds.

    Raises:
        ConfigError: on a non-numeric amount or an unrecognised unit.
    """
    _check_duration(None, "duration", text)
    amount, unit = text.split()
    return int(amount) * _UNITS[unit]


def parse_time(text: str) -> time:
    """Convert "07:45" to a datetime.time. 24-hour clock only.

    Args:
        text: a "HH:MM" string.

    Returns:
        The corresponding datetime.time.

    Raises:
        ConfigError: on a malformed or out-of-range time.
    """
    _check_time(None, "time", text)
    hour, minute = text.split(":")
    return time(int(hour), int(minute))


def expand_days(spec) -> set:
    """Return the set of weekday integers a day spec covers, Monday = 0.

    Args:
        spec: a group name ("daily", "weekdays", "weekends") or a list of
            three-letter day names.

    Returns:
        A set of weekday integers.

    Raises:
        ConfigError: on an unknown group name or day name.
    """
    if isinstance(spec, str):
        if spec not in _DAY_GROUPS:
            raise ConfigError(
                f'unknown day group "{spec}". '
                f'Valid groups: {", ".join(sorted(_DAY_GROUPS))}'
            )
        return set(_DAY_GROUPS[spec])

    days = set()
    for name in _as_list(spec):
        if name not in _DAY_INDEX:
            raise ConfigError(
                f'unknown day name "{name}". '
                f'Valid: {", ".join(sorted(_DAY_INDEX))}'
            )
        days.add(_DAY_INDEX[name])
    return days


def _normalize_when(raw_when: dict) -> dict:
    """Convert one validated "when" object into typed values.

    Args:
        raw_when: the validated raw when object.

    Returns:
        A dict with "days" as a set of weekday ints, plus either "at" as a list
        of datetime.time or "every" as seconds with "between" as a
        (start, end) time pair. "day_of_month" is present only when the job
        used it.
    """
    when = {"days": expand_days(raw_when.get("days", "daily"))}

    if "day_of_month" in raw_when:
        when["day_of_month"] = set(_as_list(raw_when["day_of_month"]))

    if "at" in raw_when:
        when["at"] = sorted(parse_time(t) for t in _as_list(raw_when["at"]))
    else:
        when["every"] = parse_duration(raw_when["every"])
        start, end = raw_when.get("between", (None, None))
        when["between"] = (
            parse_time(start) if start is not None else _WINDOW_START,
            parse_time(end) if end is not None else _WINDOW_END,
        )

    return when


def _normalize_job(raw_job: dict) -> dict:
    """Convert one validated job into the typed dict scheduler.Job consumes.

    Args:
        raw_job: the validated raw job object.

    Returns:
        A dict with keys name, enabled, when, run, cwd, catch_up_within and
        timeout. Defaults are applied here so no downstream module needs to
        know them.
    """
    cwd = raw_job.get("cwd")
    return {
        "name": raw_job["name"],
        "enabled": raw_job.get("enabled", True),
        "when": _normalize_when(raw_job["when"]),
        "run": raw_job["run"],
        "cwd": str(Path(cwd).expanduser()) if cwd else None,
        "catch_up_within": (
            parse_duration(raw_job["catch_up_within"])
            if "catch_up_within" in raw_job
            else DEFAULT_CATCH_UP
        ),
        "timeout": (
            parse_duration(raw_job["timeout"])
            if "timeout" in raw_job
            else DEFAULT_TIMEOUT
        ),
    }


def normalize(raw) -> dict:
    """Convert a validated config into typed values.

    Disabled jobs stay in the list with enabled=False so the tray can still
    display them, greyed, rather than pretending they do not exist.

    Args:
        raw: a config that has already passed validate().

    Returns:
        {"settings": {"check_every": int, "notify_on_failure": bool},
         "jobs": [typed job dict, ...]}

    Raises:
        ConfigError: on a value that validate() accepted structurally but that
            cannot be converted, which should not happen in practice.
    """
    raw_settings = raw.get("settings", {})
    settings = {
        "check_every": (
            parse_duration(raw_settings["check_every"])
            if "check_every" in raw_settings
            else DEFAULT_CHECK_EVERY
        ),
        "notify_on_failure": raw_settings.get(
            "notify_on_failure", DEFAULT_NOTIFY_ON_FAILURE
        ),
    }
    return {
        "settings": settings,
        "jobs": [_normalize_job(j) for j in raw["jobs"]],
    }
