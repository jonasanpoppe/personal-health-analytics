"""
Fetch RHR and HRV data from Garmin Connect API.

Saves daily JSON files to data/garmin_api/ for ingestion by the R targets pipeline.
Credentials are cached in ~/.garminconnect after first login.

Usage:
  python scripts/fetch_garmin_api.py                          # last 30 days
  python scripts/fetch_garmin_api.py --start 2024-07-20       # from date to today
  python scripts/fetch_garmin_api.py --start 2024-07-20 --end 2025-08-21  # specific range
"""

import argparse
import json
import os
from datetime import date, datetime, timedelta
from pathlib import Path
from getpass import getpass

from garminconnect import Garmin

TOKEN_DIR = Path.home() / ".garminconnect"
OUTPUT_DIR = Path(__file__).resolve().parent.parent / "data" / "garmin_api"


def authenticate() -> Garmin:
    """Authenticate with Garmin Connect, reusing saved tokens when possible."""
    garmin = Garmin()
    try:
        garmin.login(TOKEN_DIR)
        print("✓ Authenticated with saved tokens")
    except Exception:
        print("No saved session found — logging in with credentials.")
        email = input("Garmin email: ")
        password = getpass("Garmin password: ")
        garmin = Garmin(email=email, password=password)
        garmin.login()
        garmin.garth.dump(str(TOKEN_DIR))
        print(f"✓ Logged in and tokens saved to {TOKEN_DIR}")
    return garmin


def fetch_day(garmin: Garmin, d: date) -> dict:
    """Fetch RHR and HRV for a single date. Returns a flat dict."""
    cdate = d.isoformat()
    record = {"date": cdate, "rhr": None, "hrv": None}

    # ── RHR ──────────────────────────────────────────────────────────────────
    try:
        rhr_resp = garmin.get_rhr_day(cdate)
        # Response shape varies; dig into allMetrics or direct fields
        if isinstance(rhr_resp, dict):
            metrics = rhr_resp.get("allMetrics", {}).get("metricsMap", {})
            rhr_entry = metrics.get("WELLNESS_RESTING_HEART_RATE", [{}])
            if rhr_entry and isinstance(rhr_entry, list) and len(rhr_entry) > 0:
                record["rhr"] = rhr_entry[0].get("value")
            # Fallback: direct key
            if record["rhr"] is None:
                record["rhr"] = rhr_resp.get("restingHeartRate")
    except Exception as e:
        print(f"  ⚠ RHR {cdate}: {e}")

    # ── HRV ──────────────────────────────────────────────────────────────────
    try:
        hrv_resp = garmin.get_hrv_data(cdate)
        if isinstance(hrv_resp, dict):
            summary = hrv_resp.get("hrvSummary", {})
            if summary:
                record["hrv"] = summary.get("weeklyAvg")
                record["hrv_last_night"] = summary.get("lastNight")
                record["hrv_last_night_avg"] = summary.get("lastNightAvg")
                record["hrv_last_night_5_min_high"] = summary.get("lastNight5MinHigh")
                record["hrv_baseline_low"] = summary.get("baselineLowUpper")
                record["hrv_baseline_high"] = summary.get("baselineBalancedUpper")
                record["hrv_status"] = summary.get("status")
    except Exception as e:
        print(f"  ⚠ HRV {cdate}: {e}")

    return record


def main():
    parser = argparse.ArgumentParser(description="Fetch Garmin RHR & HRV data")
    parser.add_argument("--start", type=str, default=None,
                        help="Start date (YYYY-MM-DD). Default: 30 days ago.")
    parser.add_argument("--end", type=str, default=None,
                        help="End date (YYYY-MM-DD). Default: yesterday.")
    args = parser.parse_args()

    end_date = datetime.strptime(args.end, "%Y-%m-%d").date() if args.end else date.today() - timedelta(days=1)
    start_date = datetime.strptime(args.start, "%Y-%m-%d").date() if args.start else end_date - timedelta(days=29)

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    garmin = authenticate()

    total_days = (end_date - start_date).days + 1
    print(f"Fetching {total_days} days: {start_date} → {end_date}")

    records = []
    for i in range(total_days):
        d = start_date + timedelta(days=i)
        print(f"  [{i+1}/{total_days}] {d}", end=" … ")
        record = fetch_day(garmin, d)
        records.append(record)
        has_data = record["rhr"] is not None or record["hrv"] is not None
        print("✓" if has_data else "—")

    # Write single JSON file with all records
    out_file = OUTPUT_DIR / f"{start_date}_{end_date}_garmin_api.json"
    with open(out_file, "w") as f:
        json.dump(records, f, indent=2)

    filled = sum(1 for r in records if r["rhr"] is not None or r["hrv"] is not None)
    print(f"\n✓ Wrote {len(records)} records ({filled} with data) → {out_file}")


if __name__ == "__main__":
    main()
