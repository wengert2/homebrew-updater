#!/bin/sh
set -eu

tests_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

"$tests_dir/installer.sh"
"$tests_dir/script.sh"

printf 'All tests passed.\n'
