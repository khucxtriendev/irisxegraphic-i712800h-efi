#!/bin/bash
# Compiles temporary CPU check executables only; never builds or loads a kext/driver.
set -euo pipefail
task_root="$(cd "$(dirname "$0")/.." && pwd)"
task_temp="$(mktemp -d /private/tmp/p1-source-check.XXXXXX)"
trap 'rm -rf "$task_temp"' EXIT
clang++ -std=c++17 -O1 -g -Wall -Wextra -Werror -fsanitize=address,undefined \
  "$task_root/source-review/scanout-check.cpp" -o "$task_temp/scanout"
"$task_temp/scanout"
clang -O1 -g -fno-objc-arc -fsanitize=address,undefined \
  "$task_root/source-review/nocopy-check.m" -framework Foundation -framework Metal \
  -framework IOSurface -o "$task_temp/nocopy"
ASAN_OPTIONS=detect_leaks=0 "$task_temp/nocopy"
