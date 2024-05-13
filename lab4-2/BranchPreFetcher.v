`include "opcodes.v"

module BranchPreFetcher(
    input [2:0] btype,
    input [31:0] rs1_dout,
    input [31:0] rs2_dout,
    output reg bcond
);

always @(*) begin
    case(btype)
        `FUNCT3_BEQ: bcond = (rs1_dout == rs2_dout);
        `FUNCT3_BNE: bcond = (rs1_dout != rs2_dout);
        `FUNCT3_BLT: bcond = (rs1_dout  < rs2_dout);
        `FUNCT3_BGE: bcond = (rs1_dout >= rs2_dout);
        default: bcond = 0;
    endcase
end
endmodule
