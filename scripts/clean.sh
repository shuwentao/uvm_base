#!/usr/bin/env bash
# =============================================================================
# File    : uvm_base/scripts/clean.sh
# Purpose : 清理仿真产物（通用）
# =============================================================================
set -euo pipefail
PROJ_DIR="${PROJ_DIR:-$(pwd)}"
cd "${PROJ_DIR}"

rm -rf simv simv.daidir simv_rtl csrc DVEfiles inter.vpd ucli.key vc_hdrs.h .vcs_compat
rm -rf novas* verdiLog urgReport logs waves
rm -f *.log *.fsdb *.vcd *.vpd *.key transcript
rm -rf .__solver_cache__ 64bit

echo "[INFO] 清理完成: ${PROJ_DIR}"
