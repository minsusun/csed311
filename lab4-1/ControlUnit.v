`include "opcodes.v"

module ControlUnit(
    input [31:0] part_of_inst,
    output reg mem_read,
    output reg mem_to_reg,
    output reg mem_write,
    output reg alu_src,
    output reg write_enable,
    output reg pc_to_reg,
    output reg [1:0] alu_op,
    output reg is_ecall
);
    wire [6:0] opcode = part_of_inst[6:0];
    
    always @(*) begin
        mem_read = (opcode == `LOAD);
        mem_to_reg = (opcode == `LOAD);
        mem_write = (opcode == `STORE);
        alu_src = (opcode != `ARITHMETIC) && (opcode != `BRANCH);
        write_enable = (opcode != `STORE) && (opcode != `BRANCH);
        pc_to_reg = (opcode == `JALR || opcode == `JAL);
        alu_op = {
            (opcode == `ARITHMETIC) || 
            (opcode == `ARITHMETIC_IMM) || 
            (opcode == `BRANCH),
            1'b0
        };
        is_ecall = (opcode == `ECALL);
    end
endmodule
