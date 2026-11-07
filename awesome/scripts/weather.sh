#!/usr/bin/env bash
# Meadow weather for the AwesomeWM wibar.
# Prints "<nerd icon> <temp>°C", or "<cloud icon> --" when no API key is set.
set -u

ENV_FILE="${MEADOW_ENV:-$HOME/.config/awesome/meadow_env}"
[ -f "$ENV_FILE" ] || ENV_FILE="$HOME/.config/awesome/sketchybar_env"

# shellcheck disable=SC1090
[ -f "$ENV_FILE" ] && . "$ENV_FILE"

CLOUD=$'\uf0c2'

if [ -z "${API_KEY:-}" ] || [ "$API_KEY" = "your_api_key_here" ] || ! command -v curl >/dev/null || ! command -v jq >/dev/null; then
    printf '%s --' "$CLOUD"
    exit 0
fi

LOCATION=$(curl -sf --max-time 8 "http://ip-api.com/json" || true)
LAT=$(printf '%s' "$LOCATION" | jq -r '.lat // empty' 2>/dev/null)
LON=$(printf '%s' "$LOCATION" | jq -r '.lon // empty' 2>/dev/null)

if [ -z "$LAT" ] || [ -z "$LON" ]; then
    printf '%s --' "$CLOUD"
    exit 0
fi

DATA=$(curl -sf --max-time 8 \
    "https://api.openweathermap.org/data/2.5/weather?lat=${LAT}&lon=${LON}&appid=${API_KEY}&units=metric" || true)

if [ -z "$DATA" ]; then
    printf '%s --' "$CLOUD"
    exit 0
fi

TEMP=$(printf '%s' "$DATA" | jq '.main.temp' | cut -d "." -f 1)
CONDITION=$(printf '%s' "$DATA" | jq -r '.weather[0].main')
DESCRIPTION=$(printf '%s' "$DATA" | jq -r '.weather[0].description')

case "$DESCRIPTION" in
    "few clouds") ICON=$'\uf0c2' ;;
    *)
        case "$CONDITION" in
            Thunderstorm) ICON=$'\uf0e7' ;;
            Drizzle | Rain) ICON=$'\uf043' ;;
            Snow) ICON=$'\uf2dc' ;;
            Clear) ICON=$'\uf185' ;;
            Clouds) ICON=$'\uf0c2' ;;
            Mist | Fog | Haze | Smoke | Dust | Ash | Sand) ICON=$'\uf72e' ;;
            *) ICON=$'\uf0c2' ;;
        esac
        ;;
esac

printf '%s %s°C' "$ICON" "$TEMP"
