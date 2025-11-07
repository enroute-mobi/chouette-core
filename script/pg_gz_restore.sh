#!/bin/bash

set -o pipefail

DATABASE=$1
FILE=$2

gunzip -kf < "$FILE" | psql -d "$DATABASE" --quiet -v ON_ERROR_STOP=1 -1
