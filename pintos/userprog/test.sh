#!/usr/bin/env bash
set -e

########################################
# 설정
########################################

USERPROG_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="${USERPROG_DIR}/build"
LOG_DIR="${USERPROG_DIR}/logs"

# 필요한 write 관련 테스트들 (필요한 것만 골라 수정)
WRITE_TESTS=(
  write-normal
  write-zero
  write-bad-ptr
  write-boundary
  write-read
  write-file
  write-stdin
  write-stdout
)

DISK_SIZE=2   # MB

########################################
# 로그 폴더 준비
########################################

mkdir -p "${LOG_DIR}"

########################################
# 빌드
########################################

cd "${BUILD_DIR}"
echo "=== 빌드 시작 ==="
make -j

########################################
# 테스트 루프
########################################

for TEST in "${WRITE_TESTS[@]}"; do
  echo ""
  echo "======================================="
  echo "   테스트 실행: ${TEST}"
  echo "======================================="

  DISK_NAME="fs-${TEST}.dsk"
  rm -f "${DISK_NAME}"

  LOG_FILE="${LOG_DIR}/${TEST}.out"

  {
    echo "=== [1] 디스크 생성: ${DISK_NAME} ==="
    pintos-mkdisk "${DISK_NAME}" "${DISK_SIZE}"

    echo "=== [2] 파일 시스템 포맷 ==="
    pintos --fs-disk="${DISK_NAME}" -- -q -f mkfs

    echo "=== [3] 테스트 바이너리 복사 ==="
    pintos --fs-disk="${DISK_NAME}" \
      -p "tests/userprog/${TEST}:${TEST}" \
      -- -q

    # sample.txt 필요한 테스트 처리
    if [[ "${TEST}" == "write-file" || "${TEST}" == "write-read" ]]; then
      echo "=== [3-1] sample.txt 복사 ==="
      pintos --fs-disk="${DISK_NAME}" \
        -p "tests/userprog/sample.txt:sample.txt" \
        -- -q
    fi

    echo "=== [4] 실행: run ${TEST} ==="
    pintos --fs-disk="${DISK_NAME}" \
      -- -q run "${TEST}"

    echo ""
    echo "=== 테스트 ${TEST} 완료 ==="

  } | tee "${LOG_FILE}"    # ← 이 줄이 '터미널 출력 + 로그 파일 저장' 동시에 수행

done

echo ""
echo "======================================="
echo "   모든 write 테스트 완료"
echo "   로그 저장됨: ${LOG_DIR}/"
echo "======================================="