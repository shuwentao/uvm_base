// =============================================================================
// File    : uvm_base/src/uvm_base_sequencer.sv
// Purpose : 通用 sequencer（模板类，按事务类型实例化）
// =============================================================================
`ifndef UVM_BASE_SEQUENCER_SV
`define UVM_BASE_SEQUENCER_SV

class uvm_base_sequencer #(type REQ = uvm_base_item) extends uvm_sequencer #(REQ);
  `uvm_component_param_utils(uvm_base_sequencer #(REQ))

  function new(string name = "uvm_base_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction

endclass : uvm_base_sequencer

`endif // UVM_BASE_SEQUENCER_SV
