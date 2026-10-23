#!/usr/bin/env bash
# =============================================================================
# File    : uvm_base/scripts/run_verdi.sh
# Purpose : 与项目无关的通用 Verdi 启动脚本
#
#   FILELIST=./filelist.f TOP=tb_top DEFS="+define+XXX=1" bash run_verdi.sh
#   WAVE=waves/xxx.fsdb   波形文件（默认 waves/<TOP>.fsdb）
#   MODE=auto|nodb        auto: 优先用 <OUT>.daidir（KDB，可看 UVM class 层次）
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJ_DIR="${PROJ_DIR:-$(pwd)}"
cd "${PROJ_DIR}"

export VERDI_HOME="${VERDI_HOME:-/opt/synopsys/verdi/latest}"
export PATH="${VERDI_HOME}/bin:${PATH}"

if ! command -v verdi >/dev/null 2>&1; then
  echo "[ERROR] 未找到 verdi，请设置 VERDI_HOME（当前: ${VERDI_HOME}）"
  exit 1
fi

FILELIST="${FILELIST:-./filelist.f}"
TOP="${TOP:-tb_top}"
DEFS="${DEFS:-}"
WAVE="${WAVE:-waves/${TOP}.fsdb}"
OUT="${OUT:-simv}"
MODE="${MODE:-auto}"

SSF=""
if [ -f "${WAVE}" ]; then
  SSF="-ssf ${WAVE}"
else
  echo "[WARN] 波形文件不存在: ${WAVE} （将只加载设计）"
fi

if [ "${MODE}" = "auto" ] && [ -d "${OUT}.daidir" ]; then
  echo "[INFO] KDB 模式: ${OUT}.daidir"
  verdi -nologo -dbdir "${OUT}.daidir" ${SSF} &
  exit 0
fi

echo "[INFO] filelist 模式: ${FILELIST}"
verdi -nologo -sv \
  -f "${FILELIST}" \
  -top "${TOP}" \
  +incdir+"${BASE_DIR}"/src \
  ${DEFS} \
  ${SSF} &
