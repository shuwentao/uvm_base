// =============================================================================
// File    : uvm_base/example/ex_dut.sv
// Purpose : 示例 DUT：2 级流水（valid/data 延迟 2 拍输出）
// =============================================================================
`ifndef EX_DUT_SV
`define EX_DUT_SV

module ex_dut (
  input  logic       clk,
  input  logic       rst_n,
  input  logic       valid,
  input  logic [7:0] data,
  output logic       o_valid,
  output logic [7:0] o_data
);

  logic       v1;
  logic [7:0] d1;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      v1      <= 1'b0;
      d1      <= '0;
      o_valid <= 1'b0;
      o_data  <= '0;
    end else begin
      v1      <= valid;
      d1      <= data;
      o_valid <= v1;
      o_data  <= d1;
    end
  end

endmodule

`endif // EX_DUT_SV
