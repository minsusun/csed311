/*** 2-bit Saturated Branch Predictor ***/

`define BP_ST 0     // Branch Prediction Strongly Taken
`define BP_WT 1     // Branch Prediction Weakly Taken
`define BP_WN 2     // Branch Prediction Weakly Not taken
`define BP_SN 3     // Branch Prediction Strongly Not taken

module BranchPredict(
  input reset,
  input clk,
  input ID_is_branch,
  input ID_is_taken,
  input [31:0] IF_current_pc,
  input [31:0] ID_current_pc,
  input [31:0] ID_branch_target,
  output prediction,
  output [31:0] predicted_pc
);
  parameter BTB_INDEX_LENGTH = 2;
  parameter BTB_ENTRY_NUMBER = 2 ** BTB_INDEX_LENGTH;
  parameter TAG_LENGTH = 32 - BTB_INDEX_LENGTH - 2;

  reg [31:0] branch_target_buffer[BTB_ENTRY_NUMBER - 1: 0]; 
  reg [1:0] pattern_history_table[BTB_ENTRY_NUMBER - 1: 0];
  reg [TAG_LENGTH - 1: 0] tag_table[BTB_ENTRY_NUMBER - 1: 0];

  integer i;

  always @(posedge clk) begin
    if(reset) begin
      for(i = 0; i < BTB_ENTRY_NUMBER; i = i + 1) begin
        branch_target_buffer[i] <= 32'b0;
        pattern_history_table[i] <= `BP_WN;
        tag_table[i] <= 28'b0;
      end
    end
  end

  wire [BTB_INDEX_LENGTH - 1: 0] IF_index = 
    IF_current_pc[2 + (BTB_INDEX_LENGTH - 1): 2];
  wire [TAG_LENGTH - 1: 0] IF_tag = 
    IF_current_pc[31: 31 - (TAG_LENGTH - 1)];
  wire IF_is_tag_matched = (tag_table[IF_index] == IF_tag);
  wire IF_pattern_history_outcome = pattern_history_table[IF_index][1];
  wire [31:0] IF_branch_target = branch_target_buffer[IF_index];

  wire [BTB_INDEX_LENGTH - 1: 0] ID_index = 
    ID_current_pc[2 + (BTB_INDEX_LENGTH - 1): 2];
  wire [TAG_LENGTH - 1: 0] ID_tag = 
    ID_current_pc[31: 31 - (TAG_LENGTH - 1)];
  wire [1:0] ID_pattern_history = pattern_history_table[ID_index];
  wire ID_is_tag_matched = (tag_table[ID_index] == ID_tag);

  always @(posedge clk) begin
    if(ID_is_branch) begin
      tag_table[ID_index] <= ID_tag;
      branch_target_buffer[ID_index] <= ID_branch_target;

      if(!ID_is_tag_matched) begin
        pattern_history_table[ID_index] <= ID_is_taken ? `BP_ST : `BP_WN;
      end else begin
        case(ID_pattern_history)
        `BP_ST: pattern_history_table[ID_index] <= ID_is_taken ? `BP_ST : `BP_WT;
        `BP_WT: pattern_history_table[ID_index] <= ID_is_taken ? `BP_ST : `BP_WN;
        `BP_WN: pattern_history_table[ID_index] <= ID_is_taken ? `BP_WT : `BP_SN;
        `BP_SN: pattern_history_table[ID_index] <= ID_is_taken ? `BP_WN : `BP_WT;
        endcase
      end
    end
  end

  assign prediction = IF_is_tag_matched && IF_pattern_history_outcome;
  assign predicted_pc = prediction ? IF_branch_target : (IF_current_pc + 4);

endmodule
