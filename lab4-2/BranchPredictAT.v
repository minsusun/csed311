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
  parameter INDEX_LENGTH = 5;
  parameter ENTRY_NUMBER = 2 ** INDEX_LENGTH;
  parameter TAG_LENGTH = 32 - INDEX_LENGTH - 2;

  reg [31:0] branch_target_buffer[ENTRY_NUMBER - 1: 0];
  reg valid[ENTRY_NUMBER - 1: 0];
  reg [TAG_LENGTH - 1: 0] tag_table[ENTRY_NUMBER - 1: 0]; 

  integer i;
  
  wire [INDEX_LENGTH - 1: 0] idx_to_update = pc_to_update[INDEX_LENGTH + 1: 2];
  wire [TAG_LENGTH - 1: 0] new_tag = pc_to_update[31: 32 - TAG_LENGTH];
  wire is_exist = (tag_table[idx_to_update] == new_tag) && valid[idx_to_update];

  always @(posedge clk) begin
    if(reset) begin
      for(i = 0; i < ENTRY_NUMBER; i = i + 1) begin
        branch_target_buffer[i] <= 0;
        tag_table[i] <= 0;
        valid[i] <= 0;
      end
    end else if(is_control_flow && is_exist) begin
      branch_target_buffer[idx_to_update] <= branch_target;
      valid[idx_to_update] <= is_correct;
    end else if(is_control_flow && !is_exist) begin
      branch_target_buffer[idx_to_update] <= branch_target;
      tag_table[idx_to_update] <= new_tag;
      valid[idx_to_update] <= 1;
    end
  end

  wire [INDEX_LENGTH - 1: 0] index = current_pc[INDEX_LENGTH + 1: 2];
  wire [TAG_LENGTH - 1: 0] tag = current_pc[31: 32 - TAG_LENGTH];
  wire is_match = (tag_table[index] == tag);
  wire is_taken = valid[index];

  assign prediction = is_match && is_taken;
  assign predicted_pc = 
    prediction ? branch_target_buffer[index] : (current_pc + 4);

endmodule
