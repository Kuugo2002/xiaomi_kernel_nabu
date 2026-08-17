#!/bin/bash

# 颜色定义
yellow='\033[0;33m'
white='\033[0m'
red='\033[0;31m'
green='\033[0;32m'
cyan='\033[0;36m'

# 输出带颜色的消息函数
color_echo() {
    local color=$1
    shift
    echo -e "${color}$*${white}"
}

# 确保脚本在出错时退出
set -e

# 动态定位脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || {
    color_echo "$red" "无法切换到脚本所在目录: $SCRIPT_DIR"
    exit 1
}
color_echo "$green" "工作目录: $SCRIPT_DIR"

# 参数处理
TARGET_DEVICE="nabu"
KERNEL_NAME="Kuugo"
KERNEL_VERSION="v1.0"
NO_CLEAN=false
MAKE_FLAGS=""
NUM_JOBS=$(nproc --all)

# 解析目标设备
if [ $# -lt 1 ] || [[ "$1" == --* ]]; then
    TARGET_DEVICE="nabu"
    color_echo "$yellow" "未指定设备，使用默认设备: $TARGET_DEVICE"
else
    TARGET_DEVICE="$1"
    shift || true
fi

# 处理选项参数
while [ $# -gt 0 ]; do
    case "$1" in
        -j)                 
            if [[ "$2" =~ ^[0-9]+$ ]]; then
                NUM_JOBS="$2"
                shift 2
            else
                color_echo "$red" "错误: -j 参数后面必须跟数字"
                exit 1
            fi
            ;;
        --noclean)
            NO_CLEAN=true
            shift
            ;;
        --)
            shift
            MAKE_FLAGS="$*"
            break
            ;;
        *)
            color_echo "$yellow" "忽略未知选项: $1"
            shift
            ;;
    esac
done

# 唯一构建目录
BUILD_DIR="../Releases_${TARGET_DEVICE}_${KERNEL_NAME}"
color_echo "$green" "使用独立构建目录: $BUILD_DIR"

# 修改产物路径
MAKE_ARGS="O=$BUILD_DIR"

# 编译信息
MAKE_ARGS+=" KBUILD_BUILD_HOST=Kuugo"
MAKE_ARGS+=" KBUILD_BUILD_USER=kuugo"

# 修改编译参数设置
MAKE_ARGS+=" ARCH=arm64"
MAKE_ARGS+=" SUBARCH=arm64"

# LLVM toolchain（系统 clang）
MAKE_ARGS+=" CC=clang"
MAKE_ARGS+=" LD=ld.lld"
MAKE_ARGS+=" NM=llvm-nm"
MAKE_ARGS+=" OBJDUMP=llvm-objdump"
MAKE_ARGS+=" STRIP=llvm-strip"

# 交叉编译工具链（系统 GNU binutils）
MAKE_ARGS+=" CROSS_COMPILE=aarch64-linux-gnu-"

# 检查设备配置是否存在
if [[ ! -f "$SCRIPT_DIR/arch/arm64/configs/${TARGET_DEVICE}_defconfig" ]]; then
    color_echo "$red" "错误: 未找到目标设备 [$TARGET_DEVICE] 的配置"
    color_echo "$yellow" "可用设备配置:"
    ls "$SCRIPT_DIR/arch/arm64/configs/"*_defconfig | sed "s/.*\///; s/_defconfig//" | xargs printf "  %s\n"
    exit 1
fi

# 显示环境信息
color_echo "$cyan" "=============================================="
color_echo "$green" "构建配置信息:"
color_echo "$cyan" "=============================================="
color_echo "$yellow" "目标设备:    $TARGET_DEVICE"
color_echo "$yellow" "内核名称:    $KERNEL_NAME"
color_echo "$yellow" "内核版本:    $KERNEL_VERSION"
color_echo "$yellow" "编译线程数:  $NUM_JOBS"
color_echo "$yellow" "KernelSU:    禁用"
color_echo "$yellow" "清理:        $($NO_CLEAN && echo "跳过" || echo "执行")"
color_echo "$cyan" "=============================================="

color_echo "$green" "[clang 版本信息]:"
clang --version

# 清理工作区
if ! $NO_CLEAN; then
    color_echo "$yellow" "清理工作区..."
    rm -rf "$BUILD_DIR"
else
    color_echo "$yellow" "跳过清理步骤..."
fi

# 添加日期到本地版本
LOCAL_VERSION_DATE="-${KERNEL_NAME}-${KERNEL_VERSION}-$(date +%y%m%d)"
touch .scmversion

# 配置内核
color_echo "$green" "配置 ${TARGET_DEVICE}_defconfig..."
make $MAKE_ARGS "${TARGET_DEVICE}_defconfig"

# 设置本地版本
./scripts/config --file "$BUILD_DIR/.config" --set-str CONFIG_LOCALVERSION "$LOCAL_VERSION_DATE"

# 记录开始时间
START_TIME=$(date +%s)

# 编译内核
color_echo "$green" "开始编译内核 (使用 $NUM_JOBS 个线程)..."
make $MAKE_ARGS -j$NUM_JOBS $MAKE_FLAGS

# 检查编译结果
IMAGE_PATH="$BUILD_DIR/arch/arm64/boot/Image"
if [[ ! -f "$IMAGE_PATH" ]]; then
    color_echo "$red" "错误: 未找到内核镜像 [$IMAGE_PATH]，编译失败"
    exit 1
fi

# 计算编译时间
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

color_echo "$green" "编译成功! 耗时: ${MINUTES}分${SECONDS}秒"

DTB_PATH="$BUILD_DIR/arch/arm64/boot/dtb"

DTBO_PATH="$BUILD_DIR/arch/arm64/boot/dtbo.img"

ANY_KERNEL_DIR="$SCRIPT_DIR/anykernel"

cp "$IMAGE_PATH" "$ANY_KERNEL_DIR"
cp "$DTBO_PATH" "$ANY_KERNEL_DIR"
if [[ -f "$DTB_PATH" ]]; then
    cp "$DTB_PATH" "$ANY_KERNEL_DIR"
else
    color_echo "$yellow" "提示: 未检测到 DTB 文件，跳过复制"
fi

# 创建ZIP文件名
ZIP_NAME="${TARGET_DEVICE}_${KERNEL_NAME}-${KERNEL_VERSION}_NoSU_$(date +%y%m%d)$(date +%H%M).zip"

color_echo "$green" "创建刷机包: $ZIP_NAME"
(cd "$ANY_KERNEL_DIR" && zip -r9 "$ZIP_NAME" ./* -x .git .gitignore out/ ./*.zip)

mv "$ANY_KERNEL_DIR/$ZIP_NAME" "$BUILD_DIR/"

color_echo "$green" "完成! 刷机包已保存到: [$BUILD_DIR/$ZIP_NAME]"

color_echo "$green" "ALL DONE"
