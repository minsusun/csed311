`include "opcodes.v"

module ControlUnit(
    input [31:0] inst,
    input bcond,
    output reg_write,
    output alu_src,
    output mem_read,
    output mem_write,
    output mem_to_reg,
    output pc_to_reg,
    output [1:0] pc_src,
    output [1:0] alu_op,
    output is_jalr,
    output is_branch,
    output is_ecall
);
    wire [6:0] opcode = inst[6:0];

    wire is_arith = (opcode == `ARITHMETIC);
    wire is_arith_imm = (opcode == `ARITHMETIC_IMM);
    wire is_load = (opcode == `LOAD);
    assign is_jalr = (opcode == `JALR);
    wire is_store = (opcode == `STORE);
    assign is_branch = (opcode == `BRANCH);
    wire is_jal = (opcode == `JAL);
    assign is_ecall = (opcode == `ECALL);

    assign reg_write = !is_store && !is_branch;
    assign alu_src = !is_arith && !is_branch;
    assign mem_read = is_load;
    assign mem_write = is_store;
    assign mem_to_reg = is_load;
    assign pc_to_reg = is_jal || is_jalr;
    assign pc_src[0] = is_jal || (is_branch && bcond); 
    assign pc_src[1] = is_jalr;
    assign alu_op[0] = 1'b0;
    assign alu_op[1] = !is_load && !is_store && !is_jalr;
endmodule
