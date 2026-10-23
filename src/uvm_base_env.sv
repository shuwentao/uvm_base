// =============================================================================
// File    : uvm_base/src/uvm_base_env.sv
// Purpose : 通用 env 基类（按配置类型实例化）
//           自动取配置、可选打印拓扑、统一结果汇总
// =============================================================================
`ifndef UVM_BASE_ENV_SV
`define UVM_BASE_ENV_SV

class uvm_base_env #(type CFG = uvm_base_cfg) extends uvm_env;
  `uvm_component_param_utils(uvm_base_env #(CFG))

  CFG cfg;

  function new(string name = "uvm_base_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(CFG)::get(this, "", "cfg", cfg))
      `uvm_fatal("NOCFG", $sformatf("%s : config_db 中未找到 'cfg'", get_full_name()))
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    if (`UVM_BASE_PRINT_TOPO || ub_get_int("PRINT_TOPO", 0))
      uvm_root::get().print_topology();
  endfunction

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("ENV", $sformatf("%s : cfg = %s", get_type_name(),
      (cfg == null) ? "<null>" : cfg.convert2string()), UVM_NONE)
  endfunction

endclass : uvm_base_env

`endif // UVM_BASE_ENV_SV
