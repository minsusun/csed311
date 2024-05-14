`define BP_ST 2'b11
`define BP_WT 2'b10
`define BP_WN 2'b01
`define BP_SN 2'b00

module BranchPredict(
  input reset,
  input clk,
  input is_correct,
  input is_control_flow,
  input [31:0] current_pc,
  input [31:0] pc_to_update,
  input [31:0] branch_target,
  output prediction,
  output [31:0] predicted_pc
);
  assign predicted_pc = current_pc + 4;
  assign prediction = 1'b0;

endmodule
