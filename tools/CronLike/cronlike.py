import math
import os
import signal
import subprocess
import sys
import threading
import time

from datetime import datetime

import pystray
from PIL import Image, ImageDraw

import runner
import scheduler
import schedule_config
from schedule_config import logs_dir


# -- Icon color palettes --------------------------------------------------

_PALETTES = {
    'active': {
        'bg': (34, 197, 94),         # Vibrant green
        'border': (22, 163, 74),     # Darker green
        'fg': (255, 255, 255),       # White
        'shadow': (22, 163, 74),     # Green shadow
    },
    'running': {
        'bg': (59, 130, 246),        # Blue
        'border': (37, 99, 235),     # Darker blue
        'fg': (255, 255, 255),       # White
        'shadow': (37, 99, 235),     # Blue shadow
    },
    'paused': {
        'bg': (148, 163, 184),       # Cool slate gray
        'border': (100, 116, 139),   # Darker slate
        'fg': (241, 245, 249),       # Off-white
        'shadow': (100, 116, 139),   # Gray shadow
    },
    'error': {
        'bg': (239, 68, 68),         # Red
        'border': (185, 28, 28),     # Darker red
        'fg': (255, 255, 255),       # White
        'shadow': (185, 28, 28),     # Red shadow
    },
}


def _draw_clock(draw, ox, oy, scale, fill, shadow):
    """Draw a clock face with hands at (ox, oy) with the given scale factor."""
    # Base design is a 34x34 box; the face fills it and the hands run from
    # its centre.
    box = 34
    cx = ox + (box / 2) * scale
    cy = oy + (box / 2) * scale
    radius = (box / 2 - 1) * scale
    width = max(1, round(3 * scale))
    offset = max(1, round(scale))

    draw.ellipse(
        [cx - radius + offset, cy - radius + offset,
         cx + radius + offset, cy + radius + offset],
        outline=shadow,
        width=width,
    )
    draw.ellipse(
        [cx - radius, cy - radius, cx + radius, cy + radius],
        outline=fill,
        width=width,
    )

    # Minute hand straight up, hour hand to 2 o'clock.
    for length, degrees in ((13, 0), (9, 60)):
        angle = math.radians(degrees)
        x = cx + length * scale * math.sin(angle)
        y = cy - length * scale * math.cos(angle)
        draw.line([(cx, cy), (x, y)], fill=fill, width=width)

    dot = max(1, round(2 * scale))
    draw.ellipse([cx - dot, cy - dot, cx + dot, cy + dot], fill=fill)


def _draw_state_badge(draw, ox, oy, scale, state, color):
    """Draw the corner state badge for the given state at (ox, oy)."""
    if state == 'running':
        size = round(9 * scale)
        draw.ellipse([ox, oy, ox + size, oy + size], fill=color)
    elif state == 'paused':
        bar_w = round(4 * scale)
        bar_h = round(13 * scale)
        gap = round(3 * scale)
        draw.rectangle([ox, oy, ox + bar_w, oy + bar_h], fill=color)
        draw.rectangle([ox + bar_w + gap, oy, ox + 2 * bar_w + gap, oy + bar_h],
                       fill=color)
    elif state == 'error':
        bar_w = max(1, round(3 * scale))
        draw.rectangle([ox, oy, ox + bar_w, oy + round(9 * scale)], fill=color)
        draw.rectangle([ox, oy + round(12 * scale),
                        ox + bar_w, oy + round(15 * scale)], fill=color)
    else:
        # 'active': a motion arc, echoing the motion lines in the sibling
        # tray tool at ../MouseJiggler/mouse_jiggler.py.
        span = round(13 * scale)
        draw.arc([ox, oy, ox + span, oy + span], start=200, end=20,
                 fill=color, width=max(1, round(2 * scale)))


def create_icon_image(state='active', size=64):
    """Create a system tray icon showing a clock with a status badge.

    Args:
        state: 'active', 'running', 'paused', or 'error'.
        size:  Icon dimension in pixels (square).

    Returns:
        PIL RGBA Image.
    """
    pal = _PALETTES.get(state, _PALETTES['active'])
    scale = size / 64  # base design is 64x64

    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Rounded-rectangle background
    pad = round(2 * scale)
    radius = round(13 * scale)
    draw.rounded_rectangle(
        [pad, pad, size - pad - 1, size - pad - 1],
        radius=radius,
        fill=pal['bg'],
        outline=pal['border'],
        width=max(1, round(2 * scale)),
    )

    # Clock face
    _draw_clock(draw, round(9 * scale), round(11 * scale), scale,
                fill=pal['fg'], shadow=pal['shadow'])

    # State badge, bottom right
    _draw_state_badge(draw, round(45 * scale), round(45 * scale), scale,
                      state, pal['fg'])

    return img


def generate_ico(path=None):
    """Generate a Windows .ico file with multiple sizes from the active icon."""
    if path is None:
        path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'icon.ico')
    sizes = [16, 24, 32, 48, 64, 128, 256]
    img = create_icon_image('active', size=max(sizes))
    img.save(path, format='ICO', sizes=[(s, s) for s in sizes])
    return path


# -- Scheduler worker -----------------------------------------------------

class CronLike:
    """Scheduler worker. Owns the tick loop and the loaded config."""

    def __init__(self, tick=30):
        self.tick = tick
        self.running = False
        self.paused = False
        self._thread = None
        self._lock = threading.Lock()
        self.jobs = []
        self.state = None
        self.last_error = None
        self._inflight = set()
        self._inflight_lock = threading.Lock()
        self.on_state_change = None     # the tray uses this to recolour the icon
        self.notify_on_failure = True
        self.on_notify = None           # the tray supplies the notifier
        self._config_mtime = None

    def load_config(self):
        """Load, validate, and normalize the schedule. Never raises.

        On failure the previously loaded jobs keep running and the error is
        surfaced instead. A typo in schedule.json must not take the scheduler
        down, which is the exact failure mode that let the previous automation
        die unnoticed for months.

        Returns True when the live config changed, False otherwise.
        """
        try:
            path = schedule_config.schedule_path()
            mtime = path.stat().st_mtime if path.exists() else None
            raw = schedule_config.load_raw()
            cfg = schedule_config.normalize(schedule_config.validate(raw))
        except schedule_config.ConfigError as e:
            self.last_error = f"config: {e}"
            return False
        except OSError as e:
            self.last_error = f"config: {e}"
            return False

        self.jobs = [scheduler.Job(j) for j in cfg["jobs"]]
        self.tick = cfg["settings"]["check_every"]
        self.notify_on_failure = cfg["settings"]["notify_on_failure"]
        self._config_mtime = mtime
        self.last_error = None
        return True

    def prime_state(self):
        """Load run state and seed any job that has never run.

        Seeding is what stops a first launch at 16:00 from firing the whole
        day's backlog at once.
        """
        if self.state is None:
            self.state = scheduler.RunState(schedule_config.state_path())
        self.state.load()
        self.state.seed_missing(self.jobs, datetime.now())

    def _check_config_changed(self):
        """Reload when schedule.json's mtime moves. Never raises."""
        try:
            path = schedule_config.schedule_path()
            mtime = path.stat().st_mtime if path.exists() else None
        except OSError:
            return False
        if mtime == self._config_mtime:
            return False
        self._config_mtime = mtime
        if self.load_config():
            self.prime_state()
            self._notify_state()
            return True
        self._raise_notification("CronLike config error", self.last_error or "")
        self._notify_state()
        return False

    def _tick_once(self):
        """One scheduling pass. Never raises: a failure here must not kill the loop."""
        self._check_config_changed()
        if self.paused or self.state is None:
            return
        now = datetime.now()
        for job, verdict, slot in scheduler.due_jobs(self.jobs, self.state, now):
            self._handle(job, verdict, slot, now)

    def _handle(self, job, verdict, slot, now):
        """Act on one non-idle verdict.

        Run state is advanced before anything is dispatched, for both FIRE and
        MISSED, so a job that takes minutes cannot be re-dispatched for the
        same slot on the next tick.
        """
        self.state.set(job.name, slot)
        self.state.save()

        if verdict == scheduler.MISSED:
            runner.log_summary(logs_dir(), job.name, "MISSED", slot=slot,
                               window=job.catch_up_within)
            return

        lateness = (now - slot).total_seconds()
        self._dispatch(job, slot, is_catch_up=lateness > self.tick)

    def _dispatch(self, job, slot, is_catch_up):
        """Start one job in its own thread. No-op if it is already running."""
        with self._inflight_lock:
            if job.name in self._inflight:
                runner.log_summary(logs_dir(), job.name, "SKIP",
                                   error="previous run still in progress")
                return
            self._inflight.add(job.name)
        self._notify_state()

        def _work():
            try:
                result = runner.execute(job, logs_dir())
                runner.log_summary(
                    logs_dir(), job.name, "OK" if result.ok else "FAIL",
                    result=result, slot=slot if is_catch_up else None,
                )
                if not result.ok:
                    detail = result.error or f"exit {result.exit_code}"
                    self.last_error = f"{job.name}: {detail}"
                    self._on_failure(job, detail)
            except Exception as e:
                self.last_error = f"{job.name}: {e}"
            finally:
                with self._inflight_lock:
                    self._inflight.discard(job.name)
                self._notify_state()

        threading.Thread(target=_work, daemon=True).start()

    def run_now(self, job):
        """Execute a job immediately, outside its schedule."""
        self._dispatch(job, datetime.now(), is_catch_up=False)

    def inflight_count(self):
        """Return how many jobs are executing right now."""
        with self._inflight_lock:
            return len(self._inflight)

    def _notify_state(self):
        """Tell the tray that the icon may need recolouring."""
        callback = self.on_state_change
        if callback is None:
            return
        try:
            callback()
        except Exception:
            pass

    def _on_failure(self, job, detail):
        """Raise a desktop notification for a failed job, when enabled."""
        self._raise_notification(f"{job.name} failed", detail)

    def _raise_notification(self, title, message):
        """Hand a notification to the tray, if one is attached and enabled."""
        if not self.notify_on_failure or self.on_notify is None:
            return
        try:
            self.on_notify(title, message)
        except Exception:
            pass

    def _run_loop(self):
        while self.running:
            try:
                self._tick_once()
            except Exception as e:
                self.last_error = str(e)
            # Chunked sleep, copied from ../MouseJiggler/mouse_jiggler.py:132-139.
            # Sleeping in 0.1s slices keeps Exit responsive instead of stalling
            # for a full tick.
            for _ in range(int(self.tick * 10)):
                if not self.running:
                    break
                time.sleep(0.1)

    def start(self):
        """Start the tick loop. A second call while running is a no-op."""
        with self._lock:
            if self.running:
                return
            self.running = True
        self._thread = threading.Thread(target=self._run_loop, daemon=True)
        self._thread.start()

    def stop(self):
        """Stop the tick loop and wait briefly for the thread to unwind."""
        with self._lock:
            self.running = False
        if self._thread is not None:
            self._thread.join(timeout=2)
            self._thread = None

    def toggle_pause(self):
        """Flip the paused flag. The thread keeps running while paused."""
        with self._lock:
            self.paused = not self.paused
        return self.paused

    def is_paused(self):
        """Return True while scheduling passes are suppressed."""
        return self.paused


# -- Tray application -----------------------------------------------------

def _open_in_os(path):
    """Open a file or folder with the platform's default handler."""
    try:
        if sys.platform == 'win32':
            os.startfile(str(path))
        elif sys.platform == 'darwin':
            subprocess.run(['open', str(path)], check=False)
        else:
            subprocess.run(['xdg-open', str(path)], check=False)
    except Exception:
        pass


class CronLikeApp:
    """System tray application wrapper for CronLike."""

    def __init__(self):
        self.cron = CronLike()
        self.icon = None

    # -- Menu -------------------------------------------------------------

    def _next_line(self, item=None):
        """Return the 'Next: <job> at <time>' header line.

        pystray calls a dynamic text callable with the menu item, so the
        parameter is required even though nothing here uses it.
        """
        upcoming = []
        now = datetime.now()
        for job in self.cron.jobs:
            if not job.enabled:
                continue
            when = job.next_fire(now)
            if when is not None:
                upcoming.append((when, job.name))
        if not upcoming:
            return "No jobs scheduled"
        when, name = min(upcoming)
        if when.date() == now.date():
            return f"Next: {name} at {when:%H:%M}"
        return f"Next: {name} at {when:%a %H:%M}"

    def _status_line(self, item=None):
        """Return the error line, or an empty string when there is none."""
        if self.cron.last_error:
            return f"! {self.cron.last_error}"
        return ""

    def _make_run_now(self, job):
        def _handler(icon, item):
            self.cron.run_now(job)
        return _handler

    def _make_toggle(self, job):
        def _handler(icon, item):
            job.enabled = not job.enabled
            self._refresh_icon()
        return _handler

    def _job_submenu(self, job):
        return pystray.Menu(
            pystray.MenuItem("Run now", self._make_run_now(job)),
            pystray.MenuItem("Disabled", self._make_toggle(job),
                             checked=lambda item, j=job: not j.enabled),
        )

    def _get_menu(self):
        items = [
            pystray.MenuItem(self._next_line, None, enabled=False),
        ]
        if self.cron.last_error:
            items.append(pystray.MenuItem(self._status_line, None, enabled=False))
        items += [
            pystray.Menu.SEPARATOR,
            pystray.MenuItem("Jobs", pystray.Menu(*[
                pystray.MenuItem(f"{j.name} - {scheduler.describe(j)}",
                                 self._job_submenu(j))
                for j in self.cron.jobs
            ] or [pystray.MenuItem("No jobs", None, enabled=False)])),
            pystray.Menu.SEPARATOR,
            pystray.MenuItem("Pause all", self._on_toggle_pause,
                             checked=lambda item: self.cron.is_paused()),
            pystray.MenuItem("Reload config", self._on_reload),
            pystray.MenuItem("Open config file", self._on_open_config),
            pystray.MenuItem("Open log folder", self._on_open_logs),
            pystray.Menu.SEPARATOR,
            pystray.MenuItem("Exit", self._on_exit),
        ]
        return pystray.Menu(*items)

    # -- Icon -------------------------------------------------------------

    def _icon_state(self):
        """Return the icon state by precedence: error, paused, running, active."""
        if self.cron.last_error:
            return 'error'
        if self.cron.is_paused():
            return 'paused'
        if self.cron.inflight_count():
            return 'running'
        return 'active'

    def _refresh_icon(self):
        """Recolour the tray icon and rebuild the menu."""
        if self.icon is None:
            return
        state = self._icon_state()
        self.icon.icon = create_icon_image(state)
        self.icon.title = f"CronLike ({state.capitalize()})"
        self.icon.menu = self._get_menu()
        self.icon.update_menu()

    # -- Menu handlers ----------------------------------------------------

    def _on_toggle_pause(self, icon, item):
        self.cron.toggle_pause()
        self._refresh_icon()

    def _on_reload(self, icon, item):
        self.cron.load_config()
        self._refresh_icon()

    def _on_open_config(self, icon, item):
        _open_in_os(schedule_config.schedule_path())

    def _on_open_logs(self, icon, item):
        _open_in_os(logs_dir())

    def _notify(self, title, message):
        """Best-effort desktop notification.

        Notification support varies by platform and desktop environment, and a
        missing notifier must not take down a scheduled run.
        """
        try:
            if self.icon is not None:
                self.icon.notify(str(message), title)
        except Exception:
            pass

    def _on_exit(self, icon, item):
        self.cron.stop()
        icon.stop()

    # -- Lifecycle --------------------------------------------------------

    def run(self):
        """Start the worker, then block on the tray icon.

        The worker starts first and icon.run() is last, because pystray's
        AppKit backend has to own the main thread on macOS.
        """
        self.cron.load_config()
        self.cron.prime_state()
        self.cron.on_state_change = self._refresh_icon
        self.cron.on_notify = self._notify
        self.cron.start()
        state = self._icon_state()
        self.icon = pystray.Icon("CronLike", create_icon_image(state),
                                 f"CronLike ({state.capitalize()})",
                                 menu=self._get_menu())
        self.icon.run()


# -- Single-instance lock -------------------------------------------------

def _pid_alive(pid):
    """Return True when a process with this PID exists."""
    if pid is None or pid <= 0:
        return False
    if sys.platform == 'win32':
        import ctypes
        PROCESS_QUERY_LIMITED_INFORMATION = 0x1000
        STILL_ACTIVE = 259
        kernel32 = ctypes.windll.kernel32
        handle = kernel32.OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, False, pid)
        if not handle:
            return False
        try:
            # A PID stays openable while any handle to it is still held, so an
            # exited process can answer OpenProcess. The exit code is what
            # actually distinguishes running from finished.
            code = ctypes.c_ulong()
            if not kernel32.GetExitCodeProcess(handle, ctypes.byref(code)):
                return True
            return code.value == STILL_ACTIVE
        finally:
            kernel32.CloseHandle(handle)
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    return True


def read_lock_pid():
    """Return the PID recorded in the lockfile, or None if there is none."""
    path = schedule_config.lock_path()
    try:
        return int(path.read_text(encoding='utf-8').strip())
    except (OSError, ValueError):
        return None


def acquire_lock():
    """Claim ~/.cronlike/cronlike.lock. Returns True on success.

    A lock naming a dead PID, or holding text that is not a PID at all, is
    stale and gets overwritten, so a crash never requires manual cleanup.
    """
    path = schedule_config.lock_path()
    if path.exists():
        existing = read_lock_pid()
        if existing and existing != os.getpid() and _pid_alive(existing):
            return False
    try:
        path.write_text(str(os.getpid()), encoding='utf-8')
    except OSError:
        return False
    return True


def release_lock():
    """Remove the lockfile if it still names this process."""
    path = schedule_config.lock_path()
    if read_lock_pid() != os.getpid():
        return False
    try:
        path.unlink()
    except OSError:
        return False
    return True


def _terminate(pid):
    """Ask the process to exit. Returns True when the request was delivered."""
    try:
        if sys.platform == 'win32':
            import ctypes
            PROCESS_TERMINATE = 0x0001
            kernel32 = ctypes.windll.kernel32
            handle = kernel32.OpenProcess(PROCESS_TERMINATE, False, pid)
            if not handle:
                return False
            try:
                return bool(kernel32.TerminateProcess(handle, 0))
            finally:
                kernel32.CloseHandle(handle)
        os.kill(pid, signal.SIGTERM)
        return True
    except OSError:
        return False


def _clear_lock(pid):
    """Remove a lockfile still naming a process we just terminated.

    A terminated process never reaches its own `finally: release_lock()`, so
    the file outlives it. Windows recycles PIDs, and a stale lock naming a
    recycled PID makes --status report a stopped tool as running and makes a
    later start refuse. This is the stop path finishing the cleanup its own
    kill prevented; stale-lock takeover in acquire_lock() is unchanged and
    remains the only staleness *detection* in the tool.
    """
    path = schedule_config.lock_path()
    if read_lock_pid() != pid:
        return False
    try:
        path.unlink()
    except OSError:
        return False
    return True

# -- Command line ---------------------------------------------------------

EXAMPLE_FILE = 'schedule.example.json'


def _load_jobs():
    """Load, validate, and normalize the config into Job objects.

    Raises:
        schedule_config.ConfigError: if the config is missing or invalid.
    """
    cfg = schedule_config.normalize(
        schedule_config.validate(schedule_config.load_raw()))
    return [scheduler.Job(j) for j in cfg['jobs']], cfg['settings']


def cmd_init():
    """Seed ~/.cronlike/schedule.json from the shipped example.

    Never overwrites an existing config.
    """
    target = schedule_config.schedule_path()
    if target.exists():
        print(f"Config already exists, leaving it alone: {target}")
        return 0
    source = os.path.join(os.path.dirname(os.path.abspath(__file__)), EXAMPLE_FILE)
    if not os.path.exists(source):
        print(f"Missing {EXAMPLE_FILE} next to cronlike.py", file=sys.stderr)
        return 1
    with open(source, encoding='utf-8') as fh:
        target.write_text(fh.read(), encoding='utf-8')
    print(f"Created {target}")
    print("Edit it, then run: python cronlike.py --check")
    return 0


def cmd_check():
    """Validate the config and print each job with its next 5 fire times."""
    try:
        jobs, settings = _load_jobs()
    except schedule_config.ConfigError as e:
        print(f"Invalid config: {e}", file=sys.stderr)
        return 1

    print(f"{schedule_config.schedule_path()}")
    print(f"checking every {settings['check_every']}s, "
          f"notify_on_failure={str(settings['notify_on_failure']).lower()}")
    if not jobs:
        print("\nNo jobs defined.")
        return 0

    now = datetime.now()
    for job in jobs:
        suffix = "" if job.enabled else "   (disabled)"
        print(f"\n{job.name}{suffix}")
        print(f"  {scheduler.describe(job)}")
        print(f"  runs: {job.run}")
        upcoming = []
        cursor = now
        for _ in range(5):
            nxt = job.next_fire(cursor)
            if nxt is None:
                break
            upcoming.append(nxt)
            cursor = nxt
        if upcoming:
            print("  next: " + ", ".join(f"{t:%a %Y-%m-%d %H:%M}" for t in upcoming))
        else:
            print("  next: never")
    print(f"\n{len(jobs)} job(s), config is valid.")
    return 0


def cmd_run(name):
    """Execute one named job immediately, outside its schedule."""
    try:
        jobs, _ = _load_jobs()
    except schedule_config.ConfigError as e:
        print(f"Invalid config: {e}", file=sys.stderr)
        return 1

    matches = [j for j in jobs if j.name == name]
    if not matches:
        print(f'No job named "{name}". Known jobs: '
              f'{", ".join(j.name for j in jobs) or "none"}', file=sys.stderr)
        return 1

    job = matches[0]
    print(f"Running {job.name}: {job.run}")
    result = runner.execute(job, logs_dir())
    runner.log_summary(logs_dir(), job.name, "OK" if result.ok else "FAIL",
                       result=result)
    if result.ok:
        print(f"OK in {result.duration_s:.1f}s, exit {result.exit_code}")
        print(f"Output: {result.log_path}")
        return 0
    detail = result.error or f"exit {result.exit_code}"
    print(f"FAILED: {detail}", file=sys.stderr)
    print(f"Output: {result.log_path}", file=sys.stderr)
    return 1


def cmd_status():
    """Print the one-line status. Always exits 0.

    The grammar is shared with ../MouseJiggler/mouse_jiggler.py and documented
    in both READMEs; scripts/tools/toolctl.sh parses it.
    """
    pid = read_lock_pid()
    if not (pid and _pid_alive(pid)):
        print("state=stopped")
        return 0

    parts = [f"state=running pid={pid}"]
    # Next-fire is best-effort. A broken config must not turn status into an
    # error, because "the config is broken" is exactly when status gets asked.
    try:
        jobs, _ = _load_jobs()
        now = datetime.now()
        upcoming = []
        for job in jobs:
            if not job.enabled:
                continue
            when = job.next_fire(now)
            if when is not None:
                upcoming.append((when, job.name))
        if upcoming:
            when, name = min(upcoming)
            parts.append(f'next="{name}" at={when:%Y-%m-%dT%H:%M}')
    except schedule_config.ConfigError:
        parts.append("next=unknown")
    print(" ".join(parts))
    return 0


def cmd_stop():
    """Terminate the running scheduler. 0 if stopped, 1 if nothing was running.

    No lockfile cleanup happens here on purpose: acquire_lock() already takes
    over a lock naming a dead PID, and a second cleanup implementation would
    be a second thing that can be wrong.
    """
    pid = read_lock_pid()
    if not pid or not _pid_alive(pid):
        print("CronLike is not running.")
        return 1
    if not _terminate(pid):
        print(f"Could not stop CronLike (PID {pid}).", file=sys.stderr)
        return 1
    for _ in range(30):
        if not _pid_alive(pid):
            break
        time.sleep(0.1)
    _clear_lock(pid)
    print(f"Stopped CronLike (PID {pid}).")
    return 0


def main():
    if '--generate-ico' in sys.argv:
        path = generate_ico()
        print(f"icon.ico generated: {path}")
        sys.exit(0)
    if '--init' in sys.argv:
        sys.exit(cmd_init())
    if '--check' in sys.argv:
        sys.exit(cmd_check())
    if '--status' in sys.argv:
        sys.exit(cmd_status())
    if '--stop' in sys.argv:
        sys.exit(cmd_stop())
    if '--run' in sys.argv:
        i = sys.argv.index('--run')
        if i + 1 >= len(sys.argv):
            print('--run requires a job name', file=sys.stderr)
            sys.exit(1)
        sys.exit(cmd_run(sys.argv[i + 1]))

    if not acquire_lock():
        holder = read_lock_pid()
        print(f"CronLike is already running (PID {holder}).", file=sys.stderr)
        sys.exit(1)
    try:
        app = CronLikeApp()
        app.run()
    except KeyboardInterrupt:
        print("Shutting down...")
        sys.exit(0)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    finally:
        release_lock()


if __name__ == "__main__":
    main()
