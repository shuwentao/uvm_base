// =============================================================================
// File    : uvm_base/example/ex_if.sv
// Purpose : 示例工程接口（输入侧 / 输出侧）
// =============================================================================
`ifndef EX_IF_SV
`define EX_IF_SV

`timescale 1ns/1ps

interface ex_if (input logic clk, input logic rst_n);
  logic       valid;
  logic [7:0] data;

  // 信号必须初始化：否则 X 会沿 DUT 传播，monitor 误判为有效事务
  initial begin
    valid = 1'b0;
    data  = '0;
  end

  clocking drv_cb @(posedge clk);
    default output #0;
    output valid;
    output data;
  endclocking

  clocking mon_cb @(posedge clk);
    default input #1step;
    input valid;
    input data;
  endclocking
endinterface

interface ex_out_if (input logic clk, input logic rst_n);
  // 注意：本接口的信号由 DUT 输出结构化驱动，不能再加 initial 过程赋值
  // （否则报 Error-[ICPSD] Illegal combination of drivers）
  logic       valid;
  logic [7:0] data;

  clocking mon_cb @(posedge clk);
    default input #1step;
    input valid;
    input data;
  endclocking
endinterface

`endif // EX_IF_SV
