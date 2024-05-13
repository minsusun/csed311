`include "opcodes.v"

module HazardDetection (
  input bcond,
  input prediction,
  input [6:0] ID_opcode,
  input [4:0] ID_rs1,
  input [4:0] ID_rs2,
  input [4:0] EX_rd,
  input [4:0] MEM_rd,
  input MEM_mem_read,
  input EX_mem_read,
  output is_data_hazard,
  output is_control_hazard
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

  wire is_data_hazard_from_EX = 
    ((ID_rs1 == EX_rd) && use_rs1 || (ID_rs2 == EX_rd) && use_rs2) 
      && EX_mem_read;

  wire is_data_hazard_from_MEM = 
    ((ID_rs1 == MEM_rd) && use_rs1 || (ID_rs2 == MEM_rd) && use_rs2)
      && MEM_mem_read;

  assign is_data_hazard = is_data_hazard_from_EX || is_data_hazard_from_MEM;
  assign is_control_hazard = 
    (prediction ^ (is_jalr || is_jal || (is_branch && bcond)));
endmodule
