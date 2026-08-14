#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Go to metalprobe-image root directory
cd "$SCRIPT_DIR/.."

U_ROOT="${U_ROOT:-u-root}"
KBAKE="${KBAKE:-kbake}"
U_ROOT_PKG="$(go list -m -f "{{ .Dir }}" github.com/u-root/u-root)"

ADDITIONAL_U_ROOT_OPTS=()
KERNEL_TAG=""

while [[ $# -gt 0 ]]; do
  case $1 in
  --kernel-tag|-k)
    KERNEL_TAG="$2"
    shift
    shift
    ;;
  -o)
    ADDITIONAL_U_ROOT_OPTS+=("-o=$2")
    shift
    shift
    ;;
  -*|--*)
    echo "Unknown option $1"
    exit 1
    ;;
  *)
    echo "No positional arguments allowed"
    exit 1
    ;;
  esac
done

if [[ "$KERNEL_TAG" == "" ]]; then
  echo "Must specify --kernel-tag"
  exit 1
fi

mkdir -p ./bin

"$KBAKE" build . --arch amd64 -t "metalprobe-kernel:$KERNEL_TAG"
"$KBAKE" get kernel "metalprobe-kernel:$KERNEL_TAG" -a amd64 -o ./bin/vmlinuz

GOOS=linux CGO_ENABLED=0 "$U_ROOT" \
  -uinitcmd="metalprobe-launcher" \
  -defaultsh="" \
  ${ADDITIONAL_U_ROOT_OPTS[@]+"${ADDITIONAL_U_ROOT_OPTS[@]}"} \
  "$U_ROOT_PKG"/cmds/core/init \
  github.com/ironcore-dev/metal-operator/cmd/metalprobe \
  ./cmd/metalprobe-launcher
