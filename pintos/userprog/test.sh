#!/usr/bin/env bash
set -e

# pintos/userprog 내부에서 실행한다고 가정
USERPROG_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="${USERPROG_DIR}/build"

DISK_NAME="filesys.dsk"
DISK_SIZE=10
MEM=20
TIMEOUT=60

# read 테스트 목록
READ_TESTS=(
  read-normal
  read-bad-ptr
  read-boundary
  read-zero
  read-stdout
  read-stdin
)

echo "=== [1] build 디렉토리 체크 및 커널 빌드 ==="
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"
make -j

echo ""
echo "=== [2] 파일시스템 초기화 ==="
rm -f "${DISK_NAME}"
pintos-mkdisk "${DISK_NAME}" "${DISK_SIZE}"
pintos --fs-disk="${DISK_NAME}" -- -q -f mkfs

echo ""
echo "=== [3] sample.txt 복사 ==="
pintos --fs-disk="${DISK_NAME}" \
  -p ../../tests/userprog/sample.txt:sample.txt \
  -- -q

echo ""
echo "=== [4] READ 테스트 실행 & 채점 ==="

SUMMARY_OUTPUT="read_summary.txt"
echo "" > "${SUMMARY_OUTPUT}"

for T in "${READ_TESTS[@]}"; do
  TEST_BIN="tests/userprog/${T}"
  CK_SCRIPT="../../tests/userprog/${T}.ck"

  RESULT_FILE="tests/userprog/${T}.result"
  OUTPUT_FILE="tests/userprog/${T}.output"

  if [ ! -f "${TEST_BIN}" ]; then
    echo "[SKIP] ${T} — 바이너리 없음" | tee -a "${SUMMARY_OUTPUT}"
    continue
  fi
  if [ ! -f "${CK_SCRIPT}" ]; then
    echo "[SKIP] ${T} — 체크 스크립트 없음" | tee -a "${SUMMARY_OUTPUT}"
    continue
  fi

  echo ""
  echo ">>> 실행중: ${T}"

  # fresh disk
  rm -f "${DISK_NAME}"
  pintos-mkdisk "${DISK_NAME}" "${DISK_SIZE}"
  pintos --fs-disk="${DISK_NAME}" -- -q -f mkfs

  # copy test + sample.txt
  pintos --fs-disk="${DISK_NAME}" \
    -p "${TEST_BIN}:${T}" \
    -p ../../tests/userprog/sample.txt:sample.txt \
    -- -q

  # 실행 + result + output 저장
  pintos -v -k -T "${TIMEOUT}" -m "${MEM}" \
    --fs-disk="${DISK_NAME}" \
    -- -q run "${T}" \
    > "${RESULT_FILE}" 2> "${OUTPUT_FILE}"

  # 채점
  if perl -I../.. "${CK_SCRIPT}" "${TEST_BIN}" "${RESULT_FILE}" >/dev/null 2>&1; then
    echo "[PASS] ${T}" | tee -a "${SUMMARY_OUTPUT}"
  else
    echo "[FAIL] ${T}" | tee -a "${SUMMARY_OUTPUT}"
    echo "  - 실행 결과: ${RESULT_FILE}"
    echo "  - 출력 로그: ${OUTPUT_FILE}"
  fi
done

echo ""
echo "=== [5] 테스트 요약 ==="
cat "${SUMMARY_OUTPUT}"
echo ""

echo "=== 모든 read-* 테스트 완료 ==="