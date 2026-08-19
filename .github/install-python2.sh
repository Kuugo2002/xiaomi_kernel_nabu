#!/usr/bin/env bash
# =============================================================================
# install-python2.sh — 在 Ubuntu 24.04 (noble) 上从源码编译安装 Python 2.7
#
# 背景：Ubuntu 24.04 官方仓库已不再提供 python2 包，因此只能源码编译。
# 兼容性说明（已在 ubuntu:noble 容器中实测验证）：
#   * Python 2.7.18（最后发布版）可在 Ubuntu 24.04 的 GCC 13 下直接编译，
#     无需补丁；
#   * _ssl / _hashlib 模块可用系统 OpenSSL 3.0 编译通过（2.7.18 对
#     OpenSSL 1.1+ API 有条件编译保护，覆盖 3.x），运行时 TLS 1.2+ 正常。
#
# 用法：
#   sudo ./install-python2.sh                 # 默认安装 Python 2.7.18 到 /usr/local
#   PREFIX=/opt/python2 sudo ./install-python2.sh
#   INSTALL_PIP=0 sudo ./install-python2.sh   # 跳过 pip 安装
#
# 环境变量（均可覆盖）：
#   PYTHON_VERSION  要编译的 Python 版本，默认 2.7.18
#   PREFIX          安装前缀，默认 /usr/local
#   BUILD_DIR       下载/编译用的临时目录，默认 /tmp/python2-build
#   INSTALL_PIP     是否安装 pip（1=装，0=不装），默认 1
# =============================================================================
set -euo pipefail

PYTHON_VERSION="${PYTHON_VERSION:-2.7.18}"
PREFIX="${PREFIX:-/usr/local}"
BUILD_DIR="${BUILD_DIR:-/tmp/python2-build}"
INSTALL_PIP="${INSTALL_PIP:-1}"

log()  { echo -e "\033[1;32m[install-python2]\033[0m $*"; }
warn() { echo -e "\033[1;33m[install-python2:警告]\033[0m $*"; }
die()  { echo -e "\033[1;31m[install-python2:错误]\033[0m $*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# 0. 前置检查
# ---------------------------------------------------------------------------
[ "$(id -u)" -eq 0 ] || die "需要 root 权限，请用 sudo 运行"
[ -n "$(command -v apt-get)" ] || die "未找到 apt-get，本脚本仅适用于 Debian/Ubuntu 系统"

PYTHON_URL="https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz"

# ---------------------------------------------------------------------------
# 1. 安装编译依赖
# ---------------------------------------------------------------------------
log "安装编译依赖（build-essential / zlib / bz2 / readline / sqlite3 / libffi / openssl / tk / expat / gdbm ...）"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y \
    build-essential \
    wget \
    ca-certificates \
    pkg-config \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    libffi-dev \
    libssl-dev \
    libncursesw5-dev \
    tk-dev \
    libgdbm-dev \
    libexpat1-dev

# ---------------------------------------------------------------------------
# 2. 下载并编译 Python
# ---------------------------------------------------------------------------
log "下载 Python ${PYTHON_VERSION} 源码"
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"
[ -f "Python-${PYTHON_VERSION}.tgz" ] || wget -q "${PYTHON_URL}"
tar xzf "Python-${PYTHON_VERSION}.tgz"
cd "Python-${PYTHON_VERSION}"

log "configure（--prefix=${PREFIX}）"
./configure \
    --prefix="${PREFIX}" \
    --enable-unicode=ucs4

log "make（$(nproc) 并行）..."
make -j"$(nproc)"

log "make install -> ${PREFIX}"
make install

# 为方便调用，若 ${PREFIX}/bin 下没有 python 链接则补一个
if [ ! -e "${PREFIX}/bin/python" ]; then
    ln -sf "python${PYTHON_VERSION%.*}" "${PREFIX}/bin/python"
fi

# ---------------------------------------------------------------------------
# 3. （可选）安装 pip —— Python 2.7 的最后一个 pip 是 20.3.4
# ---------------------------------------------------------------------------
if [ "${INSTALL_PIP}" = "1" ]; then
    if "${PREFIX}/bin/python" -m pip --version >/dev/null 2>&1; then
        log "pip 已存在，跳过"
    else
        log "安装 pip（bootstrap.pypa.io/pip/2.7 提供 Python 2.7 最后支持的 pip 20.3.4）"
        cd "${BUILD_DIR}"
        wget -q https://bootstrap.pypa.io/pip/2.7/get-pip.py
        "${PREFIX}/bin/python" get-pip.py || warn "pip 安装失败（不影响 Python 本身，可稍后重试）"
    fi
fi

# ---------------------------------------------------------------------------
# 4. 验证
# ---------------------------------------------------------------------------
log "验证安装结果"
PYBIN="${PREFIX}/bin/python"
"${PYBIN}" -c "import sys; print('Python', sys.version.split()[0], '->', sys.executable)"
for m in ssl hashlib sqlite3 ctypes zlib bz2 readline pyexpat gdbm; do
    "${PYBIN}" -c "import $m" >/dev/null 2>&1 \
        && log "  模块 OK: $m" \
        || warn "  模块不可用: $m"
done
[ "${INSTALL_PIP}" = "1" ] && "${PREFIX}/bin/pip" --version 2>/dev/null \
    && log "  pip OK: $("${PREFIX}/bin/pip" --version)"

echo
log "安装完成。"
echo "  Python:  ${PREFIX}/bin/python   (python2.7 位于 ${PREFIX}/bin/python2.7)"
echo "  pip:     ${PREFIX}/bin/pip"
echo "  源码目录: ${BUILD_DIR}/Python-${PYTHON_VERSION}（不需要可删除）"
if [ "${PREFIX}" != "/usr/local" ] && [[ ":${PATH}:" != *":${PREFIX}/bin:"* ]]; then
    echo "  提示: ${PREFIX}/bin 不在 PATH 中，可执行: export PATH=${PREFIX}/bin:\$PATH"
fi
