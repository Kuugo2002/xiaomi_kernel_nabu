#!/usr/bin/env bash
set -euo pipefail

PYTHON_VERSION="${PYTHON_VERSION:-2.7.18}"
PREFIX="${PREFIX:-/usr/local}"
BUILD_DIR="${BUILD_DIR:-/tmp/python2-build}"
INSTALL_PIP="${INSTALL_PIP:-1}"
PYTHON_URL="https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz"

[[ "$(id -u)" -eq 0 ]] || { echo "This script must run as root" >&2; exit 1; }
command -v apt-get >/dev/null || { echo "apt-get is required" >&2; exit 1; }

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y \
  build-essential wget ca-certificates pkg-config zlib1g-dev libbz2-dev \
  libreadline-dev libsqlite3-dev libffi-dev libssl-dev libncursesw5-dev \
  tk-dev libgdbm-dev libexpat1-dev

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"
wget -q -O "Python-${PYTHON_VERSION}.tgz" "$PYTHON_URL"
rm -rf "Python-${PYTHON_VERSION}"
tar xzf "Python-${PYTHON_VERSION}.tgz"
cd "Python-${PYTHON_VERSION}"
./configure --prefix="$PREFIX" --enable-unicode=ucs4
make -j"$(nproc)"
make install

if [[ "$INSTALL_PIP" == 1 ]] && ! "$PREFIX/bin/python" -m pip --version >/dev/null 2>&1; then
  cd "$BUILD_DIR"
  wget -q -O get-pip.py https://bootstrap.pypa.io/pip/2.7/get-pip.py
  "$PREFIX/bin/python" get-pip.py || true
fi

"$PREFIX/bin/python" --version
