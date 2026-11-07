#!/usr/bin/env python3
"""Print "day" or "night" for the current moment at the given coordinates.

Used by switch-theme.sh when LAT/LON are configured. Uses the NOAA solar
position approximation; no third-party dependencies.
"""
import datetime
import math
import sys


def main():
    if len(sys.argv) != 3:
        print("usage: sun.py LAT LON", file=sys.stderr)
        return 2

    lat = math.radians(float(sys.argv[1]))
    lon = math.radians(float(sys.argv[2]))

    now = datetime.datetime.now(datetime.timezone.utc)
    n = now.timetuple().tm_yday
    gamma = 2 * math.pi / 365 * (n - 1 + (now.hour - 12) / 24)

    eqtime = 229.18 * (
        0.000075
        + 0.001868 * math.cos(gamma)
        - 0.032077 * math.sin(gamma)
        - 0.014615 * math.cos(2 * gamma)
        - 0.040849 * math.sin(2 * gamma)
    )
    decl = (
        0.006918
        - 0.399912 * math.cos(gamma)
        + 0.070257 * math.sin(gamma)
        - 0.006758 * math.cos(2 * gamma)
        + 0.000907 * math.sin(2 * gamma)
        - 0.002697 * math.cos(3 * gamma)
        + 0.00148 * math.sin(3 * gamma)
    )

    minutes = now.hour * 60 + now.minute + now.second / 60
    true_solar_time = (minutes + eqtime + 4 * math.degrees(lon)) % 1440
    hour_angle = math.radians(true_solar_time / 4 - 180)

    cos_zenith = (
        math.sin(lat) * math.sin(decl)
        + math.cos(lat) * math.cos(decl) * math.cos(hour_angle)
    )
    cos_zenith = max(-1.0, min(1.0, cos_zenith))
    zenith = math.degrees(math.acos(cos_zenith))

    print("day" if zenith < 90.833 else "night")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
