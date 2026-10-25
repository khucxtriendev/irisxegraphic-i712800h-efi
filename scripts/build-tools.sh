#!/bin/bash
set -euo pipefail
task_root="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$task_root/bin" "$task_root/build/module-cache"
export CLANG_MODULE_CACHE_PATH="$task_root/build/module-cache"
clang -O2 -Wall -Wextra -Werror "$task_root/src/p1-display.c" -framework CoreGraphics -framework CoreFoundation -o "$task_root/bin/p1-display"
clang -O2 -Wall -Wextra -Werror "$task_root/src/p1-hardware.c" -o "$task_root/bin/p1-hardware"
clang -O2 -Wall -Wextra -Werror -fobjc-arc "$task_root/src/p1-metal.m" -framework Metal -framework Foundation -o "$task_root/bin/p1-metal"
echo "Built p1-display, p1-hardware and p1-metal. No system changes."
