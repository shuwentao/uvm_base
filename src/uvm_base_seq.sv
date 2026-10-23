// =============================================================================
// File    : uvm_base/src/uvm_base_seq.sv
// Purpose : 通用序列骨架（模板方法模式）
//           项目序列只需继承并实现 new_item()，基类完成 start/finish_item 循环
// =============================================================================
`ifndef UVM_BASE_SEQ_SV
`define UVM_BASE_SEQ_SV

class uvm_base_seq #(type REQ = uvm_base_item) extends uvm_sequence #(REQ);
  `uvm_object_param_utils(uvm_base_seq #(REQ))

  int num_items = 1;

  function new(string name = "uvm_base_seq");
    super.new(name);
  endfunction

  virtual function REQ new_item();
    `uvm_fatal("NOTIMPL", $sformatf("%s : new_item() 未实现", get_type_name()))
    return null;
  endfunction

  virtual task body();
    if (num_items < 1) num_items = 1;
    for (int i = 0; i < num_items; i++) begin
      REQ it = new_item();
      if (it == null) continue;
      start_item(it);
      finish_item(it);
    end
  endtask

endclass : uvm_base_seq

`endif // UVM_BASE_SEQ_SV
