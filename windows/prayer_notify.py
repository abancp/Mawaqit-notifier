#!/usr/bin/env python3
"""Check today's cached prayer times (Adhan & Iqamah) and fire Windows Toast notifications
with standard system sound. Runs every minute via Windows Task Scheduler."""
import argparse
import json
import os
import subprocess
import sys
from datetime import date, datetime, timedelta
from pathlib import Path

APPDATA = os.environ.get("APPDATA") or str(Path.home() / "AppData" / "Roaming")
LOCALAPPDATA = os.environ.get("LOCALAPPDATA") or str(Path.home() / "AppData" / "Local")

CONFIG_DIR = Path(APPDATA) / "mawaqit-notify"
CONFIG_FILE = CONFIG_DIR / "config.json"
CACHE_DIR = Path(LOCALAPPDATA) / "mawaqit-notify" / "cache"
TODAY_FILE = CACHE_DIR / "today.json"
YESTERDAY_FILE = CACHE_DIR / "yesterday.json"
STATE_FILE = CACHE_DIR / "state.json"
TOAST_SCRIPT = Path(__file__).resolve().parent / "notify_toast.ps1"


def load_json(path: Path, default):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (FileNotFoundError, json.JSONDecodeError):
        return default


def save_json(path: Path, data) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2), encoding="utf-8")


def load_config() -> dict:
    return load_json(CONFIG_FILE, {})


def notify(title: str, message: str, play_sound: bool = True) -> None:
    """Display native Windows Toast notification with standard system notification sound."""
    if TOAST_SCRIPT.exists():
        sound_flag = "$true" if play_sound else "$false"
        subprocess.run(
            ["powershell", "-ExecutionPolicy", "Bypass", "-File", str(TOAST_SCRIPT),
             "-Title", title, "-Message", message, "-PlaySound", sound_flag],
            check=False,
        )
    else:
        print(f"[{title}] {message}")


def ensure_today_cache() -> dict | None:
    """Ensure today's cache is available. If not, trigger fetch script or offline fallback."""
    today = load_json(TODAY_FILE, None)
    today_str = date.today().isoformat()
    if today and today.get("date") == today_str:
        return today

    sibling_fetch = Path(__file__).resolve().parent / "mawaqit_fetch.py"
    if sibling_fetch.exists():
        subprocess.run([sys.executable, str(sibling_fetch)], check=False)

    today = load_json(TODAY_FILE, None)
    if today and today.get("date") == today_str:
        return today

    candidates = [YESTERDAY_FILE, TODAY_FILE]
    for candidate in candidates:
        if candidate.exists():
            try:
                data = json.loads(candidate.read_text(encoding="utf-8"))
                if "adhan" in data and "iqama" in data:
                    data["date"] = today_str
                    data["offline_fallback"] = True
                    data["fallback_source"] = candidate.name
                    data["fetched_at"] = datetime.now().astimezone().isoformat()
                    save_json(TODAY_FILE, data)
                    return data
            except Exception:
                continue

    return None


def run_checks():
    today = ensure_today_cache()
    if not today:
        sys.exit(0)

    config = load_config()
    notify_azan = config.get("notify_azan", True)
    notify_azan_before = int(config.get("notify_azan_before_minutes", 0))

    notify_iqama = config.get("notify_iqama", True)
    legacy_minutes = config.get("notify_before_minutes", 5)
    notify_iqama_before = int(config.get("notify_iqama_before_minutes", legacy_minutes))

    sound_enabled = config.get("sound_enabled", True)
    mosque_name = today.get("mosque", "Mosque")

    state = load_json(STATE_FILE, {"date": None, "notified_azan": [], "notified_iqama": []})
    if state.get("date") != today["date"]:
        state = {"date": today["date"], "notified_azan": [], "notified_iqama": []}

    if "notified_azan" not in state:
        state["notified_azan"] = []
    if "notified_iqama" not in state:
        state["notified_iqama"] = state.get("notified", [])

    now = datetime.now()
    today_date = date.today()

    # 1. Check Adhan times
    if notify_azan and "adhan" in today:
        for prayer, adhan_str in today["adhan"].items():
            if prayer in state["notified_azan"] or not adhan_str:
                continue
            try:
                adhan_time = datetime.strptime(adhan_str, "%H:%M").time()
                target_dt = datetime.combine(today_date, adhan_time)
            except ValueError:
                continue

            remind_dt = target_dt - timedelta(minutes=notify_azan_before)
            if remind_dt <= now <= target_dt + timedelta(minutes=2):
                remaining_min = max(0, int(round((target_dt - now).total_seconds() / 60)))
                if remaining_min > 0:
                    title = f"{prayer} Adhan in {remaining_min} min"
                else:
                    title = f"{prayer} Adhan Time"
                message = f"Adhan at {adhan_str} • {mosque_name}"
                notify(title, message, play_sound=sound_enabled)
                state["notified_azan"].append(prayer)

    # 2. Check Iqamah times
    if notify_iqama and "iqama" in today:
        for prayer, iqama_str in today["iqama"].items():
            if prayer in state["notified_iqama"] or not iqama_str:
                continue
            try:
                iqama_time = datetime.strptime(iqama_str, "%H:%M").time()
                target_dt = datetime.combine(today_date, iqama_time)
            except ValueError:
                continue

            remind_dt = target_dt - timedelta(minutes=notify_iqama_before)
            if remind_dt <= now <= target_dt + timedelta(minutes=2):
                remaining_min = max(0, int(round((target_dt - now).total_seconds() / 60)))
                if remaining_min > 0:
                    title = f"{prayer} Iqamah in {remaining_min} min"
                else:
                    title = f"{prayer} Iqamah Time"
                message = f"Iqamah at {iqama_str} • {mosque_name}"
                notify(title, message, play_sound=sound_enabled)
                state["notified_iqama"].append(prayer)

    save_json(STATE_FILE, state)


def main():
    parser = argparse.ArgumentParser(description="Windows Mawaqit Prayer Notification Daemon")
    parser.add_argument("--test-azan", action="store_true", help="Send a test Adhan notification")
    parser.add_argument("--test-iqama", action="store_true", help="Send a test Iqamah notification")
    parser.add_argument("--status", action="store_true", help="Print today's prayer cache status")
    args = parser.parse_args()

    config = load_config()
    sound_enabled = config.get("sound_enabled", True)

    if args.test_azan:
        notify("Test Adhan Notification", "Fajr Adhan at 05:00 • Standard Sound", play_sound=sound_enabled)
        print("Sent test Adhan notification.")
        return

    if args.test_iqama:
        notify("Test Iqamah Notification", "Fajr Iqamah in 5 min • Standard Sound", play_sound=sound_enabled)
        print("Sent test Iqamah notification.")
        return

    if args.status:
        today = ensure_today_cache()
        if today:
            print(json.dumps(today, indent=2, ensure_ascii=False))
        else:
            print("No cached prayer data available.")
        return

    run_checks()


if __name__ == "__main__":
    main()
