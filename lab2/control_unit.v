`include "opcodes.v"

module control_unit(
    input [6:0] opcode,
    output reg is_jal,
    output reg is_jalr,
    output reg branch,
    output reg mem_read,
    output reg mem_to_reg,
    output reg mem_write,
    output reg alu_src,
    output reg write_enable,
    output reg pc_to_reg,
    output reg is_ecall
);
    always @(*) begin
        is_jal = (opcode == `JAL);
        is_jalr = (opcode == `JALR);
        branch = (opcode == `BRANCH);
        mem_read = (opcode == `LOAD);
        mem_to_reg = (opcode == `LOAD);
        mem_write = (opcode == `STORE);
        alu_src = ((opcode != `ARITHMETIC) && (opcode != `BRANCH));
        write_enable = ((opcode != `STORE) && (opcode != `BRANCH));
        pc_to_reg = (opcode == `JALR || opcode == `JAL);
        is_ecall = (opcode == `ECALL);
    end
endmodule
