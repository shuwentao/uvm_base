// =============================================================================
// File    : uvm_base/src/uvm_base_item.sv
// Purpose : 通用事务基类（所有项目的事务对象都继承它）
// =============================================================================
`ifndef UVM_BASE_ITEM_SV
`define UVM_BASE_ITEM_SV

class uvm_base_item extends uvm_sequence_item;
  `uvm_object_utils(uvm_base_item)

  int    id   = -1;      // 事务序号（建议从 1 开始，与 monitor 编号对齐）
  string tag  = "";      // 事务标签，便于调试
  time   t_start = 0;    // 开始驱动/观测的时间
  time   t_end   = 0;    // 结束时间

  function new(string name = "uvm_base_item");
    super.new(name);
  endfunction

  virtual function void mark_start();
    t_start = $time;
  endfunction

  virtual function void mark_end();
    t_end = $time;
  endfunction

  virtual function int latency_ns();
    if (t_end == 0) return -1;
    return (t_end - t_start) / 1ns;
  endfunction

endclass : uvm_base_item

`endif // UVM_BASE_ITEM_SV
