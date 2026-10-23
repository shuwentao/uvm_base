// =============================================================================
// File    : uvm_base/src/uvm_base_cfg.sv
// Purpose : 通用配置基类
//           项目配置类继承它，即可获得 is_active / 开关 / 数量 / plusarg 等能力
// =============================================================================
`ifndef UVM_BASE_CFG_SV
`define UVM_BASE_CFG_SV

class uvm_base_cfg extends uvm_object;
  `uvm_object_utils(uvm_base_cfg)

  // agent 工作模式
  uvm_active_passive_enum is_active = UVM_ACTIVE;

  // 组件开关
  bit enable_scoreboard = 1;
  bit enable_coverage   = 1;
  bit enable_checker    = 1;

  // 结果判定
  bit expect_err  = 0;   // 1 = 期望出错（负向用例，报错降级为 warning）
  bit require_err = 0;   // 1 = 必须出错（没报错反而要报错）

  // 激励数量与冗余度
  int num_items = 1;
  int verbosity = UVM_MEDIUM;

  // 实例名（便于多实例环境区分）
  string inst_name = "";

  function new(string name = "uvm_base_cfg");
    super.new(name);
  endfunction

  // 通用 plusarg 覆盖
  virtual function void cfg_from_plusargs();
    num_items = ub_get_int("NUM_ITEMS", num_items);
    verbosity = ub_get_int("VERBOSITY", verbosity);
    if (ub_get_int("EXPECT_ERR",  expect_err ? 1 : 0)) expect_err  = 1;
    if (ub_get_int("REQUIRE_ERR", require_err ? 1 : 0)) require_err = 1;
    if (ub_get_int("PASSIVE", 0)) is_active = UVM_PASSIVE;
  endfunction

  virtual function string convert2string();
    return $sformatf("is_active=%s sb=%0b cov=%0b chk=%0b num_items=%0d expect_err=%0b require_err=%0b",
      is_active.name(), enable_scoreboard, enable_coverage, enable_checker,
      num_items, expect_err, require_err);
  endfunction

endclass : uvm_base_cfg

`endif // UVM_BASE_CFG_SV
