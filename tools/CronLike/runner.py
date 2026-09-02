"""Cross-platform command execution for scheduled jobs.

Command resolution is explicit rather than delegated to a shell. A scheduler
runs unattended strings from a config file, and handing those to a shell turns
every job definition into a quoting question.
"""

import os
import shlex
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path


class ResolveError(Exception):
    """Raised when a job's command cannot be found on PATH."""


def _unquote(token: str) -> str:
    """Strip one matched pair of surrounding quotes from a token.

    Args:
        token: a token produced by a non-posix shlex split.

    Returns:
        The token without its outermost matching quote pair.
    """
    if len(token) >= 2 and token[0] == token[-1] and token[0] in ("'", '"'):
        return token[1:-1]
    return token


def resolve(run) -> list:
    """Turn a job's `run` value into an executable argv list.

    Accepts a string, which is split with shlex, or an explicit argv list,
    which is used verbatim and so bypasses all quoting risk.

    On Windows, `claude` resolves to claude.cmd, an npm shim. CreateProcess
    cannot execute a .cmd directly and fails with "%1 is not a valid Win32
    application", so .cmd and .bat targets are wrapped as
    [COMSPEC, "/c", exe, *args].

    Args:
        run: command string or argv list.

    Returns:
        An argv list ready for subprocess.

    Raises:
        ResolveError: if the command is empty or argv[0] is not on PATH.
    """
    if isinstance(run, (list, tuple)):
        argv = [str(part) for part in run]
    elif os.name == "nt":
        # Non-posix splitting keeps backslashes intact, which Windows paths
        # need, but it also leaves the quote characters attached to each
        # token. Strip a matched surrounding pair back off so
        #   python -c "print(1)"
        # reaches the child as two arguments rather than one quoted blob.
        argv = [_unquote(token) for token in shlex.split(run, posix=False)]
    else:
        argv = shlex.split(run, posix=True)
    if not argv:
        raise ResolveError("empty command")

    exe = shutil.which(argv[0])
    if exe is None:
        raise ResolveError(f'command not found on PATH: "{argv[0]}"')

    if sys.platform == "win32" and exe.lower().endswith((".cmd", ".bat")):
        comspec = os.environ.get("COMSPEC", "cmd.exe")
        return [comspec, "/c", exe] + argv[1:]
    return [exe] + argv[1:]


# -- Execution --------------------------------------------------------------

_SAFE_CHARS = "abcdefghijklmnopqrstuvwxyz0123456789-"


class Result:
    """Outcome of one job execution."""

    def __init__(self, ok: bool, exit_code, duration_s: float, log_path, error=None):
        self.ok = ok
        self.exit_code = exit_code
        self.duration_s = duration_s
        self.log_path = log_path
        self.error = error

    def __repr__(self):
        return (
            f"<Result ok={self.ok} exit_code={self.exit_code} "
            f"duration_s={self.duration_s:.1f} error={self.error!r}>"
        )


def _slugify(name: str) -> str:
    """Reduce a job name to a lowercase filename-safe slug.

    Args:
        name: the job name.

    Returns:
        A slug containing only lowercase letters, digits, and hyphens.
    """
    slug = "".join(c if c in _SAFE_CHARS else "-" for c in name.strip().lower())
    while "--" in slug:
        slug = slug.replace("--", "-")
    return slug.strip("-") or "job"


def execute(job, log_dir) -> Result:
    """Run one job to completion and capture its output.

    stdin is DEVNULL: Claude Code headless print mode has crashed on Windows
    when stdin is unreadable, and a pythonw-launched tray has no console stdin.
    On Windows, CREATE_NO_WINDOW stops a console flashing at fire time.

    Args:
        job: a scheduler.Job.
        log_dir: directory for the per-run output file.

    Returns:
        A Result. A timeout or a resolve failure is a Result with ok=False,
        never a raised exception: one bad job must not stop the scheduler.
    """
    started = datetime.now()
    log_path = Path(log_dir) / f"{_slugify(job.name)}-{started:%Y-%m-%d}.log"

    try:
        argv = resolve(job.run)
    except ResolveError as e:
        _append(log_path, f"\n=== {started:%Y-%m-%d %H:%M:%S} {job.name} ===\n{e}\n")
        return Result(False, None, 0.0, log_path, error=str(e))

    flags = getattr(subprocess, "CREATE_NO_WINDOW", 0) if sys.platform == "win32" else 0
    env = dict(os.environ, CRONLIKE_JOB=job.name)

    try:
        with open(log_path, "a", encoding="utf-8") as fh:
            fh.write(f"\n=== {started:%Y-%m-%d %H:%M:%S} {job.name} ===\n")
            fh.flush()
            try:
                proc = subprocess.run(
                    argv,
                    cwd=job.cwd or None,
                    env=env,
                    stdin=subprocess.DEVNULL,
                    stdout=fh,
                    stderr=subprocess.STDOUT,
                    timeout=job.timeout,
                    creationflags=flags,
                )
            except subprocess.TimeoutExpired:
                elapsed = (datetime.now() - started).total_seconds()
                message = f"timed out after {job.timeout}s"
                fh.write(f"--- {message} ---\n")
                return Result(False, None, elapsed, log_path, error=message)
            except OSError as e:
                elapsed = (datetime.now() - started).total_seconds()
                fh.write(f"--- could not start: {e} ---\n")
                return Result(False, None, elapsed, log_path, error=str(e))
    except OSError as e:
        elapsed = (datetime.now() - started).total_seconds()
        return Result(False, None, elapsed, log_path, error=f"could not write log: {e}")

    elapsed = (datetime.now() - started).total_seconds()
    return Result(proc.returncode == 0, proc.returncode, elapsed, log_path)


def _append(path, text: str) -> None:
    """Append text to a log file, ignoring filesystem failures.

    Args:
        path: the log file path.
        text: the text to append.
    """
    try:
        with open(path, "a", encoding="utf-8") as fh:
            fh.write(text)
    except OSError:
        pass


# -- Rolling summary log ----------------------------------------------------

SUMMARY_LOG = "cronlike.log"


def _compact_duration(seconds) -> str:
    """Render seconds compactly for a log line: 90 -> "1m30s", 3600 -> "1h".

    Args:
        seconds: a whole number of seconds.

    Returns:
        A short human-readable duration.
    """
    seconds = int(seconds)
    if seconds < 60:
        return f"{seconds}s"
    if seconds < 3600:
        minutes, rest = divmod(seconds, 60)
        return f"{minutes}m" if rest == 0 else f"{minutes}m{rest}s"
    hours, rest = divmod(seconds, 3600)
    minutes = rest // 60
    return f"{hours}h" if minutes == 0 else f"{hours}h{minutes}m"


def log_summary(log_dir, job_name, verdict, result=None, slot=None,
                window=None, error=None) -> None:
    """Append one line to cronlike.log.

    One line per run keeps the whole history scannable without opening the
    per-job files.

        [2026-09-02 07:45:03] [OK]     Pull Linear (12.4s, exit 0)
        [2026-09-02 08:31:10] [OK]     Daily briefing (catch-up for 08:00, 94.1s, exit 0)
        [2026-09-02 11:02:00] [FAIL]   WO poll (exit 1) see wo-poll-2026-09-02.log
        [2026-09-02 09:00:00] [MISSED] Daily briefing (slot 08:00 older than 1h window)

    Args:
        log_dir: the ~/.cronlike/logs/ directory.
        job_name: the job's name.
        verdict: OK, FAIL, MISSED, or SKIP.
        result: the Result for OK and FAIL lines.
        slot: the scheduled slot, for catch-up and MISSED lines.
        window: the job's catch-up window in seconds, for MISSED lines.
        error: an explanatory message for SKIP and for failures with no exit
            code.
    """
    stamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    tag = f"[{verdict}]".ljust(8)

    parts = []
    if slot is not None and verdict == "OK":
        parts.append(f"catch-up for {slot:%H:%M}")
    if slot is not None and verdict == "MISSED":
        window_text = _compact_duration(window) if window is not None else "the catch-up"
        parts.append(f"slot {slot:%H:%M} older than {window_text} window")
    if result is not None:
        if result.error:
            parts.append(result.error)
        if result.exit_code is not None:
            if verdict == "OK":
                parts.append(f"{result.duration_s:.1f}s")
            parts.append(f"exit {result.exit_code}")
    if error:
        parts.append(error)

    detail = f" ({', '.join(parts)})" if parts else ""
    trailer = ""
    if verdict == "FAIL" and result is not None and result.log_path is not None:
        trailer = f" see {Path(result.log_path).name}"

    line = f"[{stamp}] {tag} {job_name}{detail}{trailer}\n"
    _append(Path(log_dir) / SUMMARY_LOG, line)
