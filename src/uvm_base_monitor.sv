// =============================================================================
// File    : uvm_base/src/uvm_base_monitor.sv
// Purpose : 通用 monitor 骨架（模板方法模式）
//
//   项目 monitor 只需：
//     1) extends uvm_base_monitor #(观测事务类型)
//     2) 实现 pre_run()     —— 等待复位等
//     3) 实现 do_monitor()  —— 采集"一个观测单位"并按需 ap.write()
// =============================================================================
`ifndef UVM_BASE_MONITOR_SV
`define UVM_BASE_MONITOR_SV

class uvm_base_monitor #(type TRANS = uvm_base_item) extends uvm_monitor;
  `uvm_component_param_utils(uvm_base_monitor #(TRANS))

  uvm_analysis_port #(TRANS) ap;

  int  mon_cnt = 0;     // do_monitor() 调用次数
  int  obs_cnt = 0;     // 已广播事务数
  bit  enabled = 1;

  function new(string name = "uvm_base_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    pre_run();
    if (!enabled) begin
      `uvm_info("MON", $sformatf("%s : monitor disabled", get_type_name()), UVM_LOW)
      return;
    end
    forever begin
      do_monitor();
      mon_cnt++;
    end
  endtask

  protected function void emit(TRANS t);
    if (t == null) return;
    t.mark_end();
    obs_cnt++;
    ap.write(t);
  endfunction

  //---------------- 以下由子类按需覆盖 ----------------
  virtual task pre_run();
  endtask

  virtual task do_monitor();
    `uvm_fatal("NOTIMPL", $sformatf("%s : do_monitor() 未实现", get_type_name()))
  endtask

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("MON", $sformatf("%s : sampled %0d time(s), emitted %0d item(s)",
      get_type_name(), mon_cnt, obs_cnt), UVM_NONE)
  endfunction

endclass : uvm_base_monitor

`endif // UVM_BASE_MONITOR_SV
