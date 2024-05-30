`include "opcodes.v"

module ALU(
    input [3:0] alu_ctrl,
    input [31:0] alu_in_1,
    input [31:0] alu_in_2,
    output reg [31:0] alu_result
);

always @(*) begin
    case(alu_ctrl)
        `ALU_ADD: alu_result = alu_in_1 + alu_in_2;
        `ALU_SUB: alu_result = alu_in_1 - alu_in_2;
        `ALU_AND: alu_result = alu_in_1 & alu_in_2;
        `ALU_OR:  alu_result = alu_in_1 | alu_in_2;
        `ALU_XOR: alu_result = alu_in_1 ^ alu_in_2;
        `ALU_SLL: alu_result = alu_in_1 << alu_in_2;
        `ALU_SLR: alu_result = alu_in_1 >> alu_in_2;
        default:  alu_result = 32'b0;
    endcase
end
endmodule
