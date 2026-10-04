#!/bin/sh
set -eu

cd "$(dirname "$0")/.."

exec xcrun swift format lint --strict --recursive \
  ResearchNotebook ResearchNotebookTests ResearchNotebookUITests
