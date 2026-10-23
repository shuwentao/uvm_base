#!/usr/bin/env bash
# =============================================================================
# File    : uvm_base/scripts/run_vcs.sh
# Purpose : 与项目无关的通用 VCS 编译 + 仿真脚本
#           DVP、SPI、AXI……任何基于 uvm_base 的项目都可复用
#
# 必选：FILELIST  编译文件列表
# 常用：TOP TEST SEED VERB UVM_VER DEFS PLUS DUMP WAVE COV OUT
#       VCS_HOME VERDI_HOME
# 控制：COMP_ONLY=1 / RUN_ONLY=1
#
# 例：
#   FILELIST=./filelist.f TOP=tb_top TEST=dvp_smoke_test \
#   DEFS="+define+DVP_DATA_WIDTH=8" PLUS="+NUM_FRAMES=3" bash run_vcs.sh
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJ_DIR="${PROJ_DIR:-$(pwd)}"
cd "${PROJ_DIR}"

#---------------------------------------------------------------- 工具路径 ----
export VCS_HOME="${VCS_HOME:-/opt/synopsys/vcs/latest}"
export VERDI_HOME="${VERDI_HOME:-/opt/synopsys/verdi/latest}"
export PATH="${VCS_HOME}/bin:${VERDI_HOME}/bin:${PATH}"

if ! command -v vcs >/dev/null 2>&1; then
  echo "[ERROR] 未找到 vcs，请设置 VCS_HOME（当前: ${VCS_HOME}）"
  exit 1
fi

#------------------------------------------------------------- 路径有效性校验 ---
# VERDI_HOME 指向不存在的目录时，VCS 的 -kdb 会报
#   Error-[VERDI_VCS_MM] ... '/pli.a' could not be found
# 因此无效时直接取消该变量，并退回 VCD 波形
if [ ! -d "${VERDI_HOME}" ]; then
  echo "[WARN] VERDI_HOME 无效: ${VERDI_HOME} -> 关闭 FSDB，改用 VCD"
  unset VERDI_HOME
  if [ "${WAVE}" = "fsdb" ]; then
    WAVE=vcd
  fi
fi

#---------------------------------------------------------------- 参数 --------
FILELIST="${FILELIST:?必须指定 FILELIST（编译文件列表）}"
TOP="${TOP:?必须指定 TOP（顶层模块名）}"

TEST="${TEST:-}"
UVM_VER="${UVM_VER:-uvm-1.2}"
SEED="${SEED:-1}"
VERB="${VERB:-UVM_MEDIUM}"
WAVE="${WAVE:-fsdb}"
DUMP="${DUMP:-1}"
COV="${COV:-0}"
DEFS="${DEFS:-}"
PLUS="${PLUS:-}"
OUT="${OUT:-simv}"
EXTRA_COMP="${EXTRA_COMP:-}"
COMP_ONLY="${COMP_ONLY:-0}"
RUN_ONLY="${RUN_ONLY:-0}"

LOG_DIR="${LOG_DIR:-logs}"
WAVE_DIR="${WAVE_DIR:-waves}"
mkdir -p "${LOG_DIR}" "${WAVE_DIR}"

#---------------------------------------------------------------- 波形宏 ------
if [ "${DUMP}" = "1" ]; then
  case "${WAVE}" in
    fsdb) DEFS="${DEFS} +define+UVM_BASE_DUMP_FSDB" ;;
    vcd)  DEFS="${DEFS} +define+UVM_BASE_DUMP_VCD"  ;;
  esac
fi

#---------------------------------------------------------------- Verdi PLI ---
PLI_ARGS=""
if [ "${DUMP}" = "1" ] && [ "${WAVE}" = "fsdb" ] && [ -d "${VERDI_HOME}" ]; then
  for d in LINUX64 LINUX; do
    if [ -f "${VERDI_HOME}/share/PLI/VCS/${d}/novas.tab" ] &&
       [ -f "${VERDI_HOME}/share/PLI/VCS/${d}/pli.a" ]; then
      PLI_ARGS="-P ${VERDI_HOME}/share/PLI/VCS/${d}/novas.tab ${VERDI_HOME}/share/PLI/VCS/${d}/pli.a"
      break
    fi
  done
  if [ -z "${PLI_ARGS}" ]; then
    echo "[WARN] 未找到 Verdi FSDB PLI，改用 VCD 方式 dump"
    DEFS="${DEFS} +define+UVM_BASE_DUMP_VCD"
  fi
fi

#---------------------------------------------------------------- 覆盖率 ------
COV_OPTS=""
if [ "${COV}" = "1" ]; then
  COV_OPTS="-cm line+cond+fsm+tgl+branch -cm_dir ${LOG_DIR}/cov.vdb -cm_name ${TEST:-sim}"
fi

#------------------------------------------------------- 老 VCS 兼容性补丁 ------
# 1) VCS（O-2018.09 等）与 GCC>=12 不兼容：
#      uvm_hdl_vcs.c: error: extended character “ is not valid in an identifier
#    解决：VCS_CXX=g++-4.8（或 g++-6 / g++-7）
# 2) glibc >= 2.34（Ubuntu 22.04+）删除了 pthread_yield()，链接期报：
#      undefined reference to `pthread_yield'
#    解决：自动生成兼容桩并注入 -LDFLAGS
STUB_OBJ=""
GLIBC_VER="$(getconf GNU_LIBC_VERSION 2>/dev/null | awk '{print $2}')"
if [ -n "${GLIBC_VER}" ]; then
  GLIBC_MAJ="$(echo "${GLIBC_VER}" | cut -d. -f1)"
  GLIBC_MIN="$(echo "${GLIBC_VER}" | cut -d. -f2)"
  if [ "${GLIBC_MAJ}" -gt 2 ] || { [ "${GLIBC_MAJ}" -eq 2 ] && [ "${GLIBC_MIN}" -ge 34 ]; }; then
    STUB_DIR="${PROJ_DIR}/.vcs_compat"
    mkdir -p "${STUB_DIR}"
    cat > "${STUB_DIR}/pthread_yield_stub.c" <<'EOF'
/* glibc >= 2.34 删除了 pthread_yield()，此处为老版本 VCS 提供兼容实现 */
#include <sched.h>
int pthread_yield(void) { return sched_yield(); }
EOF
    gcc -c -fPIC -O2 -o "${STUB_DIR}/pthread_yield_stub.o" "${STUB_DIR}/pthread_yield_stub.c"
    STUB_OBJ="${STUB_DIR}/pthread_yield_stub.o"
    echo "[INFO] glibc ${GLIBC_VER} >= 2.34 -> 生成 pthread_yield 兼容桩: ${STUB_OBJ}"
  fi
fi

LDF_OPTS=""
if [ -n "${VCS_CXX}" ]; then
  LDF_OPTS="-Wl,--no-as-needed"
fi
if [ -n "${STUB_OBJ}" ]; then
  LDF_OPTS="${LDF_OPTS} ${STUB_OBJ}"
fi

if [ -n "${VCS_CXX}" ] || [ -n "${LDF_OPTS}" ]; then
  echo "[INFO] 兼容性选项: cc/cpp=${VCS_CC:-${VCS_CXX:-<default>}}/${VCS_CXX:-<default>} LDFLAGS=${LDF_OPTS}"
fi

#---------------------------------------------------------------- 编译 --------
if [ "${RUN_ONLY}" != "1" ]; then
  echo "==================== VCS COMPILE ===================="
  echo "[INFO] TOP=${TOP} FILELIST=${FILELIST} UVM_VER=${UVM_VER}"
  echo "[INFO] DEFS=${DEFS}"
  # 用数组拼命令行，保证 -LDFLAGS 后的多个参数作为整体传入
  VCS_ARGS=(-full64 -sverilog -ntb_opts "${UVM_VER}"
            -timescale=1ns/1ps
            -debug_access+all -kdb
            -Mupdate +vcs+lic+wait
            "+incdir+${BASE_DIR}/src"
            ${DEFS} ${PLI_ARGS} ${COV_OPTS})
  if [ -n "${VCS_CXX}" ]; then
    VCS_ARGS+=(-cc "${VCS_CC:-${VCS_CXX}}" -cpp "${VCS_CXX}")
  fi
  if [ -n "${LDF_OPTS}" ]; then
    VCS_ARGS+=(-LDFLAGS "${LDF_OPTS}")
  fi
  VCS_ARGS+=(${EXTRA_COMP}
             -f "${FILELIST}" -top "${TOP}" -o "${OUT}" -l "${LOG_DIR}/compile.log")

  vcs "${VCS_ARGS[@]}"
  echo "[INFO] 编译日志: ${LOG_DIR}/compile.log"
fi

#---------------------------------------------------------------- 仿真 --------
if [ "${COMP_ONLY}" != "1" ]; then
  echo "==================== VCS RUN ===================="
  RUN_LOG="${LOG_DIR}/sim_${TEST:-sim}.log"
  PLUS_TEST=""
  [ -n "${TEST}" ] && PLUS_TEST="+UVM_TESTNAME=${TEST}"

  ./"${OUT}" \
      ${PLUS_TEST} \
      +UVM_VERBOSITY="${VERB}" \
      +ntb_random_seed="${SEED}" \
      ${PLUS} \
      ${COV_OPTS} \
      -l "${RUN_LOG}"

  echo "[INFO] 仿真日志: ${RUN_LOG}"
  echo "==================== SUMMARY ===================="
  # 真实报错行形如： UVM_ERROR /path/file.sv(48) @ 225000: ...
  # 报告末尾统计行形如： UVM_ERROR :    0     <- 不能把它当报错
  grep -E "UVM_(ERROR|FATAL|WARNING)[[:space:]]+/|TEST PASSED|TEST FAILED|COVERAGE" \
      "${RUN_LOG}" | tail -30 || true
  echo "-------------------------------- UVM 统计 --------------------------------"
  grep -E "^UVM_(INFO|WARNING|ERROR|FATAL) *: " "${RUN_LOG}" || true

  N_ERR="$(grep -cE '^UVM_ERROR[[:space:]]+/' "${RUN_LOG}" || true)"
  N_FATAL="$(grep -cE '^UVM_FATAL[[:space:]]+/' "${RUN_LOG}" || true)"
  N_ERR="${N_ERR:-0}"
  N_FATAL="${N_FATAL:-0}"

  if [ "${N_ERR}" != "0" ] || [ "${N_FATAL}" != "0" ]; then
    echo "[RESULT] FAIL  (UVM_ERROR=${N_ERR} UVM_FATAL=${N_FATAL})"
    exit 1
  fi
  echo "[RESULT] PASS"
fi
