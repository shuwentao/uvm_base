# =============================================================================
# uvm_base —— 通用 UVM 母版库 Makefile
#
#   make check     用 example 工程编译 + 仿真，验证 uvm_base 与具体协议无关
#   make comp      仅编译 example
#   make run       仅仿真 example
#   make verdi     打开 Verdi
#   make clean     清理
#
# 本库自身不含 DUT；真实项目（如 ../dvp_uvm）在自己的 Makefile 里
# 通过 FILELIST / TOP / DEFS 调用 scripts/run_vcs.sh 即可。
# =============================================================================

export VCS_HOME   ?= /opt/synopsys/vcs/latest
export VERDI_HOME ?= /opt/synopsys/verdi/latest

UVM_VER ?= uvm-1.2
SEED    ?= 1
VERB    ?= UVM_MEDIUM
WAVE    ?= fsdb
DUMP    ?= 1
COV     ?= 0

FILELIST ?= ./example/ex_filelist.f
TOP      ?= ex_top
TEST     ?= ex_test
OUT      ?= simv
PLUS     ?= +NUM_ITEMS=8

RUN = FILELIST=$(FILELIST) TOP=$(TOP) TEST=$(TEST) UVM_VER=$(UVM_VER) \
      SEED=$(SEED) VERB=$(VERB) WAVE=$(WAVE) DUMP=$(DUMP) COV=$(COV) OUT=$(OUT) \
      VCS_CC="$(VCS_CC)" VCS_CXX="$(VCS_CXX)" \
      PLUS="$(PLUS)" bash ./scripts/run_vcs.sh

.PHONY : all check comp run verdi clean help

all : check

check : comp run

comp :
	@mkdir -p logs waves
	@COMP_ONLY=1 $(RUN)

run :
	@mkdir -p logs waves
	@RUN_ONLY=1 $(RUN)

verdi :
	@FILELIST=$(FILELIST) TOP=$(TOP) WAVE=waves/$(TOP).fsdb bash ./scripts/run_verdi.sh

clean :
	@bash ./scripts/clean.sh

help :
	@echo "make check       编译并运行 example 工程（验证 uvm_base）"
	@echo "make verdi       打开 Verdi"
	@echo "make clean       清理"
	@echo "老版本 VCS + 新 GCC 报 uvm_hdl_vcs.c 弯引号错误时：make check VCS_CXX=g++-4.8"
