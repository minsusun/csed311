`include "opcodes.v"

module ALU(
    input [3:0] alu_op_i,
    input [31:0] alu_a_i,
    input [31:0] alu_b_i,
    output reg [31:0] alu_p_o,
    output reg bcond
);

always @(*) begin
    case(alu_op_i)
        `ALU_ADD: begin
            alu_p_o = alu_a_i + alu_b_i;
            bcond = 0;
        end
        `ALU_SUB: begin
            alu_p_o = alu_a_i - alu_b_i;
            bcond = 0;
        end
        `ALU_AND: begin
            alu_p_o = alu_a_i & alu_b_i;
            bcond = 0;
        end
        `ALU_OR: begin
            alu_p_o = alu_a_i | alu_b_i;
            bcond = 0;
        end
        `ALU_XOR: begin
            alu_p_o = alu_a_i ^ alu_b_i;
            bcond = 0;
        end
        `ALU_SLL: begin
            alu_p_o = alu_a_i << alu_b_i;
            bcond = 0;
        end
        `ALU_SLR: begin
            alu_p_o = alu_a_i >> alu_b_i;
            bcond = 0;
        end
        `ALU_BEQ: begin
            alu_p_o = 32'b0;
            bcond = alu_a_i == alu_b_i;
        end
        `ALU_BNE: begin
            alu_p_o = 32'b0;
            bcond = alu_a_i != alu_b_i;
        end
        `ALU_BLT: begin
            alu_p_o = 32'b0;
            bcond = alu_a_i < alu_b_i;
        end
        `ALU_BGE: begin
            alu_p_o = 32'b0;
            bcond = alu_a_i >= alu_b_i;
        end
        default: begin
            alu_p_o = 32'b0;
            bcond = 0;
        end
    endcase
end

endmodule
