`include "opcodes.v"

module HazardDetection (
    input EX_mem_read,
    input [31:0] ID_inst,
    input [4:0] EX_rd,
    output is_hazard
);
    wire [6:0] ID_opcode = ID_inst[6:0];
    wire is_ecall = (ID_opcode == `ECALL);
    wire [4:0] ID_rs1 = is_ecall ? 17 : ID_inst[19:15];
    wire [4:0] ID_rs2 = ID_inst[24:20];

    wire use_rs1 = (
        (ID_opcode != `LUI) || (ID_opcode != `AUIPC) || (ID_opcode != `JAL)
    ) && ID_rs1 != 5'b0; 

    wire use_rs2 = (
        (ID_opcode == `ARITHMETIC) || (ID_opcode == `STORE) ||
        (ID_opcode == `BRANCH)
    ) && ID_rs2 != 5'b0;

    assign is_hazard = (
        (ID_rs1 == EX_rd) && use_rs1 || (ID_rs2 == EX_rd) && use_rs2 
    ) && EX_mem_read;
endmodule
