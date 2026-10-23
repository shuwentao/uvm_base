// =============================================================================
// File    : uvm_base/src/uvm_base_defines.svh
// Purpose : 通用宏定义（可被命令行 +define+ 覆盖）
// =============================================================================
`ifndef UVM_BASE_DEFINES_SVH
`define UVM_BASE_DEFINES_SVH

// 默认仿真超时（ns）：可在命令行用 +TMO_NS= 覆盖
`ifndef UVM_BASE_TIMEOUT_NS
`define UVM_BASE_TIMEOUT_NS 50000000
`endif

// 默认收尾等待时间（ns）：可在命令行用 +DRAIN_NS= 覆盖
`ifndef UVM_BASE_DRAIN_NS
`define UVM_BASE_DRAIN_NS 300000
`endif

// =1 时打印 UVM 拓扑（也可用 +PRINT_TOPO=1 打开）
`ifndef UVM_BASE_PRINT_TOPO
`define UVM_BASE_PRINT_TOPO 0
`endif

`endif // UVM_BASE_DEFINES_SVH
