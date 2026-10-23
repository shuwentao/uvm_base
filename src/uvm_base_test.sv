// =============================================================================
// File    : uvm_base/src/uvm_base_test.sv
// Purpose : 通用 test 基类（与项目无关）
//           统一完成：plusarg 超时/收尾时间、UVM 超时设置、objection + drain、
//                     启动主序列、结果汇总
//
//   项目 test 只需：
//     1) extends uvm_base_test
//     2) build_phase 里建配置、下发 config_db、创建 env
//     3) 实现 create_main_sequence() 返回主序列
//     4) 实现 main_sequencer()     返回主 sequencer
// =============================================================================
`ifndef UVM_BASE_TEST_SV
`define UVM_BASE_TEST_SV

class uvm_base_test extends uvm_test;
  `uvm_component_utils(uvm_base_test)

  int tmo_ns   = `UVM_BASE_TIMEOUT_NS;   // UVM 超时
  int drain_ns = `UVM_BASE_DRAIN_NS;     // 序列结束后的收尾等待

  function new(string name = "uvm_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  //---------------- 子类覆盖 ----------------
  virtual function uvm_sequence_base  create_main_sequence();
    return null;
  endfunction

  virtual function uvm_sequencer_base main_sequencer();
    return null;
  endfunction

  //---------------- 通用流程 ----------------
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tmo_ns   = ub_get_int("TMO_NS",   tmo_ns);
    drain_ns = ub_get_int("DRAIN_NS", drain_ns);
    uvm_root::get().set_timeout(tmo_ns * 1ns);
  endfunction

  virtual task run_phase(uvm_phase phase);
    uvm_sequence_base  seq;
    uvm_sequencer_base sqr;

    phase.raise_objection(this, "uvm_base_test");
    phase.phase_done.set_drain_time(this, drain_ns * 1ns);

    seq = create_main_sequence();
    if (seq != null) begin
      sqr = main_sequencer();
      if (sqr == null)
        `uvm_fatal("NOSQR", "main_sequencer() 返回 null，请检查 test 实现")
      `uvm_info("TEST", $sformatf("start sequence : %s", seq.get_type_name()), UVM_LOW)
      seq.start(sqr);
    end else begin
      `uvm_info("TEST", "no main sequence (create_main_sequence 返回 null)", UVM_LOW)
    end

    #(drain_ns * 1ns);      // 等待 monitor / DUT 收尾
    phase.drop_objection(this, "uvm_base_test done");
  endtask

  virtual function void report_phase(uvm_phase phase);
    uvm_report_server svr;
    int               n_err, n_fatal;
    super.report_phase(phase);
    svr     = uvm_report_server::get_server();
    n_err   = svr.get_severity_count(UVM_ERROR);
    n_fatal = svr.get_severity_count(UVM_FATAL);
    `uvm_info("TEST", $sformatf("=== %s : sim time=%0s, UVM_FATAL=%0d UVM_ERROR=%0d ===",
      get_type_name(), ub_fmt_ns($time), n_fatal, n_err), UVM_NONE)
    if ((n_err == 0) && (n_fatal == 0))
      `uvm_info("TEST", "*** TEST PASSED ***", UVM_NONE)
    else
      `uvm_info("TEST", "*** TEST FAILED ***", UVM_NONE)
  endfunction

endclass : uvm_base_test

`endif // UVM_BASE_TEST_SV
