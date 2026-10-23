// =============================================================================
// File    : uvm_base/example/ex_pkg.sv
// Purpose : 示例工程：演示如何基于 uvm_base 快速搭出一个项目的验证环境
//           项目只需要实现"与协议相关"的部分，通用流程全部由 uvm_base 提供
// =============================================================================
`ifndef EX_PKG_SV
`define EX_PKG_SV

package ex_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import uvm_base_pkg::*;

  //---------------------------------------------------------------- 事务 ----
  class ex_item extends uvm_base_item;
    `uvm_object_utils(ex_item)

    rand bit [7:0] data;
    rand int       gap;      // 驱动后空闲几拍

    constraint c_gap { gap inside {[0 : 3]}; }

    function new(string name = "ex_item");
      super.new(name);
    endfunction

    function string convert2string();
      return $sformatf("id=%0d data=0x%02h gap=%0d", id, data, gap);
    endfunction
  endclass

  //---------------------------------------------------------------- driver --
  class ex_driver extends uvm_base_driver #(ex_item);
    `uvm_component_utils(ex_driver)

    virtual ex_if vif;

    function new(string name = "ex_driver", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db #(virtual ex_if)::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "ex_driver: vif 未设置")
    endfunction

    virtual task pre_run();
      @(posedge vif.rst_n);
      repeat (3) @(vif.drv_cb);
    endtask

    virtual task do_drive_item(ex_item t);
      @(vif.drv_cb);
      vif.drv_cb.valid <= 1'b1;
      vif.drv_cb.data  <= t.data;
      @(vif.drv_cb);
      vif.drv_cb.valid <= 1'b0;
      vif.drv_cb.data  <= '0;
      repeat (t.gap) @(vif.drv_cb);
    endtask
  endclass

  //--------------------------------------------------------------- monitor --
  class ex_monitor extends uvm_base_monitor #(ex_item);
    `uvm_component_utils(ex_monitor)

    virtual ex_out_if vif;

    function new(string name = "ex_monitor", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db #(virtual ex_out_if)::get(this, "", "out_vif", vif))
        `uvm_fatal("NOVIF", "ex_monitor: out_vif 未设置")
    endfunction

    virtual task pre_run();
      @(posedge vif.rst_n);
    endtask

    virtual task do_monitor();
      ex_item t;
      @(vif.mon_cb);
      // 用 !== 1'b1 而不是 !valid：X 态时 !X 仍为 X，if(X) 判为假会误收事务
      if (vif.mon_cb.valid !== 1'b1) return;
      if (!$cast(t, ex_item::type_id::create("obs")))
        `uvm_fatal("CAST", "create ex_item failed")
      t.data = vif.mon_cb.data;
      t.tag  = "obs";
      emit(t);
    endtask
  endclass

  //----------------------------------------------------------------- agent --
  class ex_agent extends uvm_base_agent #(uvm_base_cfg);
    `uvm_component_utils(ex_agent)

    uvm_analysis_port #(ex_item) exp_ap;   // 期望（driver 侧）
    uvm_analysis_port #(ex_item) ap;       // 实测（monitor 侧）

    ex_driver                    drv;
    ex_monitor                   mon;
    uvm_base_sequencer #(ex_item) sqr;

    function new(string name = "ex_agent", uvm_component parent = null);
      super.new(name, parent);
      exp_ap = new("exp_ap", this);
      ap     = new("ap",     this);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      mon = ex_monitor::type_id::create("mon", this);
      if (cfg.is_active == UVM_ACTIVE) begin
        drv = ex_driver::type_id::create("drv", this);
        sqr = uvm_base_sequencer #(ex_item)::type_id::create("sqr", this);
      end
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      mon.ap.connect(ap);
      if (cfg.is_active == UVM_ACTIVE) begin
        drv.seq_item_port.connect(sqr.seq_item_export);
        drv.exp_ap.connect(exp_ap);
      end
    endfunction
  endclass

  //------------------------------------------------------------ scoreboard --
  `uvm_analysis_imp_decl(_exp)
  `uvm_analysis_imp_decl(_obs)

  class ex_sb extends uvm_base_scoreboard #(uvm_base_cfg);
    `uvm_component_utils(ex_sb)

    uvm_analysis_imp_exp #(ex_item, ex_sb) exp_imp;
    uvm_analysis_imp_obs #(ex_item, ex_sb) obs_imp;

    protected ex_item exp_q[$];

    function new(string name = "ex_sb", uvm_component parent = null);
      super.new(name, parent);
      exp_imp = new("exp_imp", this);
      obs_imp = new("obs_imp", this);
    endfunction

    function void write_exp(ex_item t);
      exp_q.push_back(t);
    endfunction

    function void write_obs(ex_item t);
      ex_item e;
      if (exp_q.size() == 0) begin
        ub_error("SB", $sformatf("观测到多余事务: data=0x%02h", t.data), cfg.expect_err);
        return;
      end
      e = exp_q.pop_front();
      if (t.data !== e.data)
        ub_error("SB", $sformatf("数据比对失败: got=0x%02h exp=0x%02h (exp_id=%0d)",
          t.data, e.data, e.id), cfg.expect_err);
      incr_checked();
    endfunction

    virtual function string summary();
      return $sformatf("%s, 未比对期望事务=%0d", super.summary(), exp_q.size());
    endfunction
  endclass

  //------------------------------------------------------------------- env --
  class ex_env extends uvm_base_env #(uvm_base_cfg);
    `uvm_component_utils(ex_env)

    ex_agent agt;
    ex_sb    sb;

    function new(string name = "ex_env", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      uvm_config_db #(uvm_base_cfg)::set(this, "agt", "cfg", cfg);
      uvm_config_db #(uvm_base_cfg)::set(this, "sb",  "cfg", cfg);
      agt = ex_agent::type_id::create("agt", this);
      if (cfg.enable_scoreboard) sb = ex_sb::type_id::create("sb", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      if (cfg.enable_scoreboard) begin
        agt.exp_ap.connect(sb.exp_imp);
        agt.ap.connect(sb.obs_imp);
      end
    endfunction
  endclass

  //------------------------------------------------------------------- seq --
  class ex_seq extends uvm_base_seq #(ex_item);
    `uvm_object_utils(ex_seq)

    int m_id = 1;

    function new(string name = "ex_seq");
      super.new(name);
      num_items = 8;
    endfunction

    virtual function ex_item new_item();
      ex_item it;
      if (!$cast(it, ex_item::type_id::create("it")))
        `uvm_fatal("CAST", "create ex_item failed")
      if (!it.randomize()) `uvm_fatal("RAND", "randomize ex_item failed")
      it.id = m_id++;
      return it;
    endfunction
  endclass

  //------------------------------------------------------------------ test --
  class ex_test extends uvm_base_test;
    `uvm_component_utils(ex_test)

    uvm_base_cfg  cfg;
    ex_env        env;
    int           m_id = 1;

    function new(string name = "ex_test", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      virtual ex_if      v_in;
      virtual ex_out_if  v_out;
      super.build_phase(phase);

      cfg = new("cfg");
      cfg.num_items = ub_get_int("NUM_ITEMS", 8);

      if (!uvm_config_db #(virtual ex_if)::get(this, "", "vif", v_in))
        `uvm_fatal("NOVIF", "vif 未设置")
      if (!uvm_config_db #(virtual ex_out_if)::get(this, "", "out_vif", v_out))
        `uvm_fatal("NOVIF", "out_vif 未设置")

      uvm_config_db #(uvm_base_cfg)::set(this, "env", "cfg", cfg);
      env = ex_env::type_id::create("env", this);
    endfunction

    virtual function uvm_sequence_base create_main_sequence();
      ex_seq s;
      if (!$cast(s, ex_seq::type_id::create("seq")))
        `uvm_fatal("CAST", "create ex_seq failed")
      s.num_items = cfg.num_items;
      return s;
    endfunction

    virtual function uvm_sequencer_base main_sequencer();
      return env.agt.sqr;
    endfunction
  endclass

endpackage : ex_pkg

`endif // EX_PKG_SV
