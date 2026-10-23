// =============================================================================
// File    : uvm_base/example/ex_top.sv
// Purpose : 示例工程顶层
// =============================================================================
`timescale 1ns/1ps

module ex_top;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import uvm_base_pkg::*;
  import ex_pkg::*;

  localparam int CLK_HALF_NS = 5;

  logic clk   = 1'b0;
  logic rst_n = 1'b0;

  ex_if     in_if  (.clk(clk), .rst_n(rst_n));
  ex_out_if out_if (.clk(clk), .rst_n(rst_n));

  ex_dut u_dut (
    .clk     (clk),
    .rst_n   (rst_n),
    .valid   (in_if.valid),
    .data    (in_if.data),
    .o_valid (out_if.valid),
    .o_data  (out_if.data)
  );

  // 时钟
  initial forever #(CLK_HALF_NS) clk = ~clk;

  // 复位
  initial begin
    rst_n = 1'b0;
    #200ns;
    rst_n = 1'b1;
  end

  // 配置下发 + 启动 UVM
  initial begin
    uvm_config_db #(virtual ex_if)::set(null, "*", "vif", in_if);
    uvm_config_db #(virtual ex_out_if)::set(null, "*", "out_vif", out_if);
    run_test("ex_test");
  end

  // 波形
`ifdef UVM_BASE_DUMP_FSDB
  initial begin
    $fsdbDumpfile("waves/ex_top.fsdb");
    $fsdbDumpvars(0, ex_top);
  end
`elsif UVM_BASE_DUMP_VCD
  initial begin
    $dumpfile("waves/ex_top.vcd");
    $dumpvars(0, ex_top);
  end
`endif

endmodule : ex_top
