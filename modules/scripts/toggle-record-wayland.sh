#!/usr/bin/env bash

if pgrep wf-recorder; then
    pkill wf-recorder
else
    wf-recorder -g "$(slurp)" -f "@carpeta_grabaciones@/$(date +%s).mp4" &
fi

