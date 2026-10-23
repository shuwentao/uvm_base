// =============================================================================
// File    : uvm_base/src/uvm_base_pkg.sv
// Purpose : 通用 UVM 母版包（与具体协议无关，可被任意项目复用）
//
//   层次：
//     uvm_base_cfg        配置基类
//     uvm_base_item       事务基类
//     uvm_base_sequencer  通用 sequencer
//     uvm_base_driver     通用 driver 骨架（模板方法）
//     uvm_base_monitor    通用 monitor 骨架（模板方法）
//     uvm_base_agent      通用 agent 基类
//     uvm_base_scoreboard 通用比对基类
//     uvm_base_seq        通用序列骨架（模板方法）
//     uvm_base_env        通用 env 基类
//     uvm_base_test       通用 test 基类
//     ub_*                通用工具函数
// =============================================================================
`ifndef UVM_BASE_PKG_SV
`define UVM_BASE_PKG_SV

package uvm_base_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "uvm_base_defines.svh"
  `include "uvm_base_utils.svh"
  `include "uvm_base_cfg.sv"
  `include "uvm_base_item.sv"
  `include "uvm_base_sequencer.sv"
  `include "uvm_base_driver.sv"
  `include "uvm_base_monitor.sv"
  `include "uvm_base_agent.sv"
  `include "uvm_base_scoreboard.sv"
  `include "uvm_base_seq.sv"
  `include "uvm_base_env.sv"
  `include "uvm_base_test.sv"

endpackage : uvm_base_pkg

`endif // UVM_BASE_PKG_SV
