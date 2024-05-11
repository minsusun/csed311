`include "opcodes.v"

module HazardDetection (
    input bcond,
    input [6:0] ID_opcode,
    input [4:0] ID_rs1,
    input [4:0] ID_rs2,
    input [6:0] EX_opcode,
    input [4:0] EX_rd,
    input EX_mem_read,
    output is_control_hazard,
    output is_data_hazard
);
    wire is_arith = (ID_opcode == `ARITHMETIC);
    wire is_store = (ID_opcode == `STORE);
    wire is_branch = (ID_opcode == `BRANCH);
    wire is_lui = (ID_opcode == `LUI);
    wire is_auipc = (ID_opcode == `AUIPC);
    wire is_jal = (ID_opcode == `JAL);
    wire is_jalr = (ID_opcode == `JALR);
    wire is_rs1_zero = (ID_rs1 == 5'b0);
    wire is_rs2_zero = (ID_rs2 == 5'b0);

    wire use_rs1 = (!is_lui || !is_auipc || !is_jal) && !is_rs1_zero;
    wire use_rs2 = (is_arith || is_store || is_branch) && !is_rs2_zero;

    assign is_control_hazard = 
        is_jalr || is_jal || (is_branch && bcond);

    assign is_data_hazard = 
        ((ID_rs1 == EX_rd) && use_rs1 || (ID_rs2 == EX_rd) && use_rs2) 
            && EX_mem_read;
endmodule
