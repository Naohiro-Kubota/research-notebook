#!/bin/sh
set -eu

cd "$(dirname "$0")/.."

exec xcrun swift format format --in-place --recursive \
  ResearchNotebook ResearchNotebookTests ResearchNotebookUITests
