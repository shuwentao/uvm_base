// =============================================================================
// File    : uvm_base/src/uvm_base_agent.sv
// Purpose : 通用 agent 基类（按配置类型实例化）
//           自动完成 config_db 取配置 + 标准 connect 钩子
// =============================================================================
`ifndef UVM_BASE_AGENT_SV
`define UVM_BASE_AGENT_SV

class uvm_base_agent #(type CFG = uvm_base_cfg) extends uvm_agent;
  `uvm_component_param_utils(uvm_base_agent #(CFG))

  CFG cfg;

  function new(string name = "uvm_base_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(CFG)::get(this, "", "cfg", cfg))
      `uvm_fatal("NOCFG", $sformatf("%s : config_db 中未找到 'cfg'", get_full_name()))
    if (cfg != null) cfg.cfg_from_plusargs();
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

endclass : uvm_base_agent

`endif // UVM_BASE_AGENT_SV
