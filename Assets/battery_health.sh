#!/usr/bin/env bash

total_full=0
total_design=0

for bat in /sys/class/power_supply/BAT*; do
	if [ -f "$bat/energy_full_design" ]; then
		full=$(cat "$bat/energy_full")
		design=$(cat "$bat/energy_full_design")

		total_full=$((total_full + full))
		total_design=$((total_design + design))
	fi
done

combined=$((total_full * 100 / total_design))
echo "${combined}%"
