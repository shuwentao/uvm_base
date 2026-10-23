// =============================================================================
// File    : uvm_base/src/uvm_base_driver.sv
// Purpose : 通用 driver 骨架（模板方法模式）
//
//   项目 driver 只需：
//     1) extends uvm_base_driver #(项目事务类型)
//     2) 实现 pre_run()        —— 等待复位、启动时钟等
//     3) 实现 do_drive_item()  —— 真正把事务驱动到接口上
//   基类统一完成：取事务 -> 广播期望 -> 驱动 -> 记账 -> item_done
// =============================================================================
`ifndef UVM_BASE_DRIVER_SV
`define UVM_BASE_DRIVER_SV

class uvm_base_driver #(type REQ = uvm_base_item) extends uvm_driver #(REQ);
  `uvm_component_param_utils(uvm_base_driver #(REQ))

  // 期望事务广播口（供 scoreboard / coverage / checker 使用）
  uvm_analysis_port #(REQ) exp_ap;

  int drv_cnt      = 0;    // 已驱动事务数
  bit broadcast_exp = 1;   // 是否在驱动前广播期望事务

  function new(string name = "uvm_base_driver", uvm_component parent = null);
    super.new(name, parent);
    exp_ap = new("exp_ap", this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    pre_run();
    forever begin
      seq_item_port.get_next_item(req);
      pre_drive_item(req);
      if (broadcast_exp) exp_ap.write(req);
      do_drive_item(req);
      post_drive_item(req);
      drv_cnt++;
      seq_item_port.item_done();
    end
  endtask

  //---------------- 以下由子类按需覆盖 ----------------
  virtual task pre_run();
  endtask

  virtual task pre_drive_item(REQ t);
    if (t != null) t.mark_start();
  endtask

  virtual task do_drive_item(REQ t);
    `uvm_fatal("NOTIMPL", $sformatf("%s : do_drive_item() 未实现", get_type_name()))
  endtask

  virtual task post_drive_item(REQ t);
    if (t != null) t.mark_end();
  endtask

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("DRV", $sformatf("%s : driven %0d item(s)", get_type_name(), drv_cnt), UVM_NONE)
  endfunction

endclass : uvm_base_driver

`endif // UVM_BASE_DRIVER_SV
