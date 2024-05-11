`include "opcodes.v"

module BranchPreFetcher(
    input is_branch,
    input [2:0] btype,
    input [31:0] rs1_dout,
    input [31:0] rs2_dout,
    output reg bcond
);

always @(*) begin
    case(btype)
        `FUNCT3_BEQ: bcond = is_branch ? (rs1_dout == rs2_dout) : 0;
        `FUNCT3_BNE: bcond = is_branch ? (rs1_dout != rs2_dout) : 0;
        `FUNCT3_BLT: bcond = is_branch ? (rs1_dout  < rs2_dout) : 0;
        `FUNCT3_BGE: bcond = is_branch ? (rs1_dout >= rs2_dout) : 0;
        default: bcond = 0;
    endcase
end
endmodule
