#!/usr/bin/env bash
# =============================================================================
# File    : uvm_base/scripts/env_setup.sh
# Purpose : 环境变量模板 —— 按你的实际安装路径修改后 source
#
#   source uvm_base/scripts/env_setup.sh
#   （建议把下面几行直接写进 ~/.bashrc，或改好路径后在本文件里 source）
# =============================================================================

# ---- EDA 工具安装路径（必改）----
export VCS_HOME="${VCS_HOME:-/mnt/data1/synopsys/vcs-mx/O-2018.09-SP2}"
export VERDI_HOME="${VERDI_HOME:-/mnt/data1/synopsys/verdi/Verdi_O-2018.09-SP2}"

# ---- License（必改：指向 license server 或 Synopsys.dat）----
export LM_LICENSE_FILE="${LM_LICENSE_FILE:-/mnt/data1/synopsys/license/Synopsys.dat}"

# ---- PATH ----
export PATH="${VCS_HOME}/bin:${VERDI_HOME}/bin:${PATH}"

# ---- 本仓库根（供脚本定位 src/）----
export UVM_BASE="${UVM_BASE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

echo "[env] VCS_HOME   = ${VCS_HOME}"
echo "[env] VERDI_HOME = ${VERDI_HOME}"
echo "[env] UVM_BASE   = ${UVM_BASE}"
echo "[env] LM_LICENSE_FILE = ${LM_LICENSE_FILE}"
command -v vcs   >/dev/null && echo "[env] vcs   : $(command -v vcs)"   || echo "[env] vcs   未找到"
command -v verdi >/dev/null && echo "[env] verdi : $(command -v verdi)" || echo "[env] verdi 未找到"
