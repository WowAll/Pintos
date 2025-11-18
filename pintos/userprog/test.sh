#!/usr/bin/env bash
set -e

# 이 스크립트는 pintos/userprog 에서 실행한다고 가정
USERPROG_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="${USERPROG_DIR}/build"

DISK_NAME="filesys.dsk"
DISK_SIZE=2                     # MB
TEST_BIN_SRC="tests/userprog/args-single"
TEST_BIN_DST="args-single"
TEST_ARGS="args-single onearg"

echo ""
echo "=== [1] build 디렉토리 확인 ==="
if [ ! -d "${BUILD_DIR}" ]; then
    echo "build/ 폴더 없음 → 생성"
    mkdir -p "${BUILD_DIR}"
fi

echo ""
echo "=== [2] 커널 빌드 ==="
cd "${BUILD_DIR}"
make -j

echo ""
echo "=== [3] 파일시스템 디스크 생성 ==="
rm -f "${DISK_NAME}"
pintos-mkdisk "${DISK_NAME}" ${DISK_SIZE}

echo ""
echo "=== [4] 파일 시스템 포맷 (mkfs) ==="
pintos --fs-disk="${DISK_NAME}" -- -q -f mkfs

echo ""
echo "=== [5] 테스트 바이너리 복사: ${TEST_BIN_SRC} → ${TEST_BIN_DST} ==="
pintos --fs-disk="${DISK_NAME}" \
  -p "${TEST_BIN_SRC}:${TEST_BIN_DST}" \
  -- -q

echo ""
echo "=== [6] 실행: run '${TEST_ARGS}' ==="
pintos --fs-disk="${DISK_NAME}" \
  -- -q run "${TEST_ARGS}"