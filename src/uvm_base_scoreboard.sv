// =============================================================================
// File    : uvm_base/src/uvm_base_scoreboard.sv
// Purpose : 通用比对基类（按配置类型实例化）
//           提供错误/警告计数、统一上报、结果汇总
// =============================================================================
`ifndef UVM_BASE_SCOREBOARD_SV
`define UVM_BASE_SCOREBOARD_SV

class uvm_base_scoreboard #(type CFG = uvm_base_cfg) extends uvm_scoreboard;
  `uvm_component_param_utils(uvm_base_scoreboard #(CFG))

  CFG cfg;

  protected int m_err     = 0;
  protected int m_warn    = 0;
  protected int m_checked = 0;

  function new(string name = "uvm_base_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(CFG)::get(this, "", "cfg", cfg))
      `uvm_fatal("NOCFG", $sformatf("%s : config_db 中未找到 'cfg'", get_full_name()))
  endfunction

  //---------------- 计数与上报 ----------------
  function void incr_err(int n = 1);
    m_err += n;
  endfunction

  function void incr_warn(int n = 1);
    m_warn += n;
  endfunction

  function void incr_checked(int n = 1);
    m_checked += n;
  endfunction

  // 报错：若本用例期望出错则降级为 warning
  function void ub_error(string id, string msg, bit expect_err = 0);
    if (expect_err) begin
      m_warn++;
      `uvm_warning(id, $sformatf("%s (expected error)", msg))
    end else begin
      m_err++;
      `uvm_error(id, msg)
    end
  endfunction

  function void ub_warning(string id, string msg);
    m_warn++;
    `uvm_warning(id, msg)
  endfunction

  virtual function string summary();
    return $sformatf("checked=%0d errors=%0d warnings=%0d", m_checked, m_err, m_warn);
  endfunction

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SUMMARY", $sformatf("%s : %s", get_type_name(), summary()), UVM_NONE)
  endfunction

endclass : uvm_base_scoreboard

`endif // UVM_BASE_SCOREBOARD_SV
