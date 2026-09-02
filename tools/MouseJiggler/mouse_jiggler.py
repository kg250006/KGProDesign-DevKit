import sys
import os
import signal
import pystray
from PIL import Image, ImageDraw
import threading
import time

from pathlib import Path

from mouse_input import send_mouse_input


CONFIG_DIR_NAME = '.mousejiggler'
LOCK_FILE = 'mousejiggler.lock'


# -- Icon color palettes --------------------------------------------------

_PALETTES = {
    'active': {
        'bg': (34, 197, 94),         # Vibrant green
        'border': (22, 163, 74),     # Darker green
        'fg': (255, 255, 255),       # White
        'shadow': (22, 163, 74),     # Green shadow
    },
    'paused': {
        'bg': (148, 163, 184),       # Cool slate gray
        'border': (100, 116, 139),   # Darker slate
        'fg': (241, 245, 249),       # Off-white
        'shadow': (100, 116, 139),   # Gray shadow
    },
}


def _draw_cursor(draw, ox, oy, scale, fill, shadow):
    """Draw a mouse cursor arrow at (ox, oy) with the given scale factor."""
    # Classic pointer shape (coordinates at 1x scale, relative to origin)
    pts = [
        (0, 0),       # Tip
        (0, 35),      # Bottom of left edge
        (8, 27),      # Inner notch left
        (16, 39),     # Tail bottom
        (22, 33),     # Tail right
        (12, 21),     # Inner notch right
        (22, 11),     # Right wing
    ]
    scaled = [(ox + x * scale, oy + y * scale) for x, y in pts]
    shadow_pts = [(x + scale, y + scale) for x, y in scaled]
    draw.polygon(shadow_pts, fill=shadow)
    draw.polygon(scaled, fill=fill)


def _draw_motion_lines(draw, ox, oy, scale, color):
    """Draw three diagonal motion lines indicating jiggle activity."""
    lines = [(0, 0, 11, -5), (2, 9, 13, 4), (0, 18, 11, 13)]
    for x1, y1, x2, y2 in lines:
        draw.line(
            [(ox + x1 * scale, oy + y1 * scale),
             (ox + x2 * scale, oy + y2 * scale)],
            fill=color,
            width=max(1, round(2 * scale)),
        )


def _draw_pause_bars(draw, ox, oy, scale, color):
    """Draw two vertical pause bars."""
    bar_w = round(5 * scale)
    bar_h = round(17 * scale)
    gap = round(3 * scale)
    draw.rectangle([ox, oy, ox + bar_w, oy + bar_h], fill=color)
    draw.rectangle([ox + bar_w + gap, oy, ox + 2 * bar_w + gap, oy + bar_h], fill=color)


def create_icon_image(state='active', size=64):
    """Create a system tray icon showing a mouse cursor with status indicators.

    Args:
        state: 'active' (green + motion lines) or 'paused' (gray + pause bars).
        size:  Icon dimension in pixels (square).

    Returns:
        PIL RGBA Image.
    """
    pal = _PALETTES.get(state, _PALETTES['active'])
    scale = size / 64  # base design is 64×64

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

    # Mouse cursor
    _draw_cursor(draw, round(15 * scale), round(10 * scale), scale,
                 fill=pal['fg'], shadow=pal['shadow'])

    # State indicators
    if state == 'active':
        _draw_motion_lines(draw, round(44 * scale), round(12 * scale),
                           scale, pal['fg'])
    else:
        _draw_pause_bars(draw, round(43 * scale), round(36 * scale),
                         scale, pal['fg'])

    return img


def generate_ico(path=None):
    """Generate a Windows .ico file with multiple sizes from the active icon."""
    if path is None:
        path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'icon.ico')
    sizes = [16, 24, 32, 48, 64, 128, 256]
    img = create_icon_image('active', size=max(sizes))
    img.save(path, format='ICO',
             sizes=[(s, s) for s in sizes])


class MouseJiggler:
    def __init__(self, interval=60):
        self.interval = interval
        self.running = False
        self.paused = False
        self._thread = None
        self._lock = threading.Lock()
        self._jiggle_direction = 1  # Alternates between 1 and -1

    def _jiggle(self):
        """Move mouse using SendInput API with 4px delta, alternating direction"""
        if not self.paused:
            delta = 4 * self._jiggle_direction
            send_mouse_input(delta)
            self._jiggle_direction *= -1  # Alternate direction for next jiggle

    def _run_loop(self):
        """Background thread loop"""
        while self.running:
            self._jiggle()
            # Sleep in small increments to allow quick shutdown
            for _ in range(self.interval * 10):
                if not self.running:
                    break
                time.sleep(0.1)

    def start(self):
        """Start the jiggler background thread"""
        with self._lock:
            if self.running:
                return  # Already running
            self.running = True
            self.paused = False
            self._thread = threading.Thread(target=self._run_loop, daemon=True)
            self._thread.start()

    def stop(self):
        """Stop the jiggler and wait for thread to terminate"""
        with self._lock:
            self.running = False
        if self._thread:
            self._thread.join(timeout=2)
            self._thread = None

    def toggle_pause(self):
        """Toggle pause state - when paused, thread stays alive but no mouse movement"""
        with self._lock:
            self.paused = not self.paused
            return self.paused

    def is_running(self):
        """Check if the jiggler is currently running"""
        return self.running

    def is_paused(self):
        """Check if the jiggler is currently paused"""
        return self.paused


class MouseJigglerApp:
    """System tray application wrapper for MouseJiggler"""

    def __init__(self):
        self.jiggler = MouseJiggler()
        self.icon = None

    def _get_menu(self):
        """Build the right-click context menu with checkmark-based Pause toggle"""
        return pystray.Menu(
            pystray.MenuItem(
                "Pause",
                self._on_toggle_pause,
                checked=lambda item: self.jiggler.is_paused(),
            ),
            pystray.MenuItem("Exit", self._on_exit)
        )

    def _on_toggle_pause(self, icon, item):
        """Handle Pause/Resume menu click"""
        paused = self.jiggler.toggle_pause()
        # Update icon color: gray when paused, green when active
        icon.icon = create_icon_image('paused' if paused else 'active')
        # Update tooltip to reflect current state
        icon.title = "Mouse Jiggler (Paused)" if paused else "Mouse Jiggler (Active)"
        # Force menu rebuild to update text
        icon.update_menu()

    def _on_exit(self, icon, item):
        """Handle Exit menu click - clean shutdown"""
        self.jiggler.stop()
        icon.stop()

    def run(self):
        """Start the jiggler and run the system tray icon"""
        self.jiggler.start()
        self.icon = pystray.Icon(
            "Mouse Jiggler",
            create_icon_image('active'),
            "Mouse Jiggler (Active)",
            menu=self._get_menu()
        )
        self.icon.run()


# -- Paths ----------------------------------------------------------------

def config_dir():
    """Return ~/.mousejiggler/, creating it if absent.

    Returns:
        Path to the configuration directory.
    """
    d = Path.home() / CONFIG_DIR_NAME
    d.mkdir(parents=True, exist_ok=True)
    return d


def lock_path():
    """Return the path to mousejiggler.lock.

    Returns:
        Path to the single-instance lockfile, which may not exist yet.
    """
    return config_dir() / LOCK_FILE


# -- Single-instance lock -------------------------------------------------
#
# Ported from the sibling tray tool at ../CronLike/cronlike.py. Before this
# existed, nothing stopped a second jiggler from starting and nothing could
# tell which one was running, so there was no honest way to report status or
# to stop the tool from outside its own tray menu.

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
    path = lock_path()
    try:
        return int(path.read_text(encoding='utf-8').strip())
    except (OSError, ValueError):
        return None


def acquire_lock():
    """Claim ~/.mousejiggler/mousejiggler.lock. Returns True on success.

    A lock naming a dead PID, or holding text that is not a PID at all, is
    stale and gets overwritten, so a crash never requires manual cleanup.
    """
    path = lock_path()
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
    path = lock_path()
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
    path = lock_path()
    if read_lock_pid() != pid:
        return False
    try:
        path.unlink()
    except OSError:
        return False
    return True

# -- Command line ---------------------------------------------------------

def cmd_status():
    """Print the one-line status. Always exits 0.

    The grammar is shared with ../CronLike/cronlike.py and documented in both
    READMEs; scripts/tools/toolctl.sh parses it.
    """
    pid = read_lock_pid()
    if pid and _pid_alive(pid):
        print(f"state=running pid={pid}")
    else:
        print("state=stopped")
    return 0


def cmd_stop():
    """Terminate a running instance. 0 if stopped, 1 if nothing was running."""
    pid = read_lock_pid()
    if not pid or not _pid_alive(pid):
        print("Mouse Jiggler is not running.")
        return 1
    if not _terminate(pid):
        print(f"Could not stop Mouse Jiggler (PID {pid}).", file=sys.stderr)
        return 1
    # The tray's own finally-block releases the lock on a clean exit, but a
    # terminated process never reaches it. Poll rather than assume.
    for _ in range(30):
        if not _pid_alive(pid):
            break
        time.sleep(0.1)
    _clear_lock(pid)
    print(f"Stopped Mouse Jiggler (PID {pid}).")
    return 0


def main():
    """Main entry point with error handling and graceful shutdown"""
    if '--generate-ico' in sys.argv:
        generate_ico()
        print("icon.ico generated.")
        sys.exit(0)
    if '--status' in sys.argv:
        sys.exit(cmd_status())
    if '--stop' in sys.argv:
        sys.exit(cmd_stop())

    if not acquire_lock():
        holder = read_lock_pid()
        print(f"Mouse Jiggler is already running (PID {holder}).", file=sys.stderr)
        sys.exit(1)
    try:
        app = MouseJigglerApp()
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
