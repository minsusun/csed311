`include "opcodes.v"

module ControlUnit(
    input [6:0] part_of_inst,
    output reg mem_read,
    output reg mem_to_reg,
    output reg mem_write,
    output reg alu_src,
    output reg reg_write,
    output reg [1:0] alu_op,
    output reg is_ecall
);
    wire [6:0] opcode = part_of_inst;
    
    always @(*) begin
        mem_read = (opcode == `LOAD);
        mem_to_reg = (opcode == `LOAD);
        mem_write = (opcode == `STORE);
        alu_src = (opcode != `ARITHMETIC) && (opcode != `BRANCH);
        reg_write = (opcode != `STORE) && (opcode != `BRANCH);
        alu_op = {
            (opcode == `ARITHMETIC) || 
            (opcode == `ARITHMETIC_IMM) || 
            (opcode == `BRANCH),
            0
        }
        is_ecall = (opcode == `ECALL)
    end
endmodule