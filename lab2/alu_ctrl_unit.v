// Note that alu_op assigns some part of instruction into
// the output, alu_op, no matter what the opcode is.
// That is, the first 10 bits of alu_op can contain trash value when the operation
// does not require funct3 and funct7.
module alu_ctrl_unit(
    input [6:0] funct7,
    input [2:0] funct3,
    input [6:0] opcode,
    output reg [16:0] alu_op
);
    always @(*) begin
        alu_op = {funct7, funct3, opcode};
    end
endmodule
