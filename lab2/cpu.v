// Submit this file with other files you created.
// Do not touch port declarations of the module 'cpu'.

// Guidelines
// 1. It is highly recommened to `define opcodes and something useful.
// 2. You can modify the module.
// (e.g., port declarations, remove modules, define new modules, ...)
// 3. You might need to describe combinational logics to drive them into the module (e.g., mux, and, or, ...)
// 4. `include files if required

`include "pc.v"
`include "instruction_memory.v"
`include "register_file.v"
`include "control_unit.v"
`include "immediate_generator.v"
`include "alu_control_unit.v"
`include "alu.v"
`include "data_memory.v"

module cpu(input reset,                     // positive reset signal
           input clk,                       // clock signal
           output is_halted,                // Whehther to finish simulation
           output [31:0] print_reg [0:31]); // TO PRINT REGISTER VALUES IN TESTBENCH (YOU SHOULD NOT USE THIS)
  /***** Wire declarations *****/
  wire [31:0] pc;
  wire [31:0] next_pc;
  wire [31:0] inst;

  // register file
  wire [4:0] rs1;
  wire [4:0] rs2;
  wire [31:0] rs1_dout;
  wire [31:0] rs2_dout;
  wire [4:0] rd;
  wire [31:0] rd_din;

  // imm-gen
  wire [31:0] imm;

  // ALU
  wire [6:0] ALUOp;
  wire [31:0] i_alu_a;
  wire [31:0] i_alu_b;
  wire bcond;
  wire [31:0] ALU_result;

  // Control
  wire JALR;
  wire JAL;
  wire Branch;
  wire MemRead;
  wire MemtoReg;
  wire MemWrite;
  wire [1:0] ALUSrc_1;
  wire ALUSrc_2;
  wire RegWrite;
  wire PCtoReg;
  wire is_ecall;

  // PC-related
  wire PCSrc_1;
  wire PCSrc_2;

  // PC-related data path
  wire [31:0] aux_pc_1;   // PC + 4
  wire [31:0] aux_pc_2;   // PC + imm
  wire [31:0] aux_pc_3;   // PC + 4 OR PC + imm

  // data memory
  wire [31:0] o_memory_dout_aux;
  wire [31:0] o_memory_dout;

  /***** Register declarations *****/

  /***** something... *******/
  assign rs1 = inst[19:15];
  assign rs2 = inst[24:20];
  assign rd = inst[11:7];

  assign PCSrc_1 = (Branch & bcond) | JAL;
  assign PCSrc_2 = JALR;

  assign aux_pc_1 = pc + 4;
  assign aux_pc_2 = pc + imm;
  assign aux_pc_3 = (PCSrc_1 ? aux_pc_2 : aux_pc_1);
  assign next_pc = (PCSrc_2 ? ALU_result : aux_pc_3);

  assign i_alu_a = (ALUSrc_1[1] ? 32'b0 : (ALUSrc_1[0] ?  rs1_dout : pc));
  assign i_alu_b = (ALUSrc_2 ? imm : rs2_dout);

  assign o_memory_dout = (MemtoReg ? o_memory_dout_aux : ALU_result);

  assign rd_din = (PCtoReg ? aux_pc_1 : o_memory_dout);

  assign is_halted = (is_ecall && print_reg[10] == 0);

  // ---------- Update program counter ----------
  // PC must be updated on the rising edge (positive edge) of the clock.
  pc pc_module(
    .reset(reset),       // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),         // input
    .next_pc(next_pc),     // input
    .current_pc(pc)   // output
  );
  
  // ---------- Instruction Memory ----------
  instruction_memory imem(
    .reset(reset),   // input
    .clk(clk),     // input
    .addr(pc),    // input
    .dout(inst)     // output
  );

  // ---------- Register File ----------
  register_file reg_file (
    .reset(reset),        // input
    .clk(clk),          // input
    .rs1(rs1),          // input
    .rs2(rs2),          // input
    .rd(rd),           // input
    .rd_din(rd_din),       // input
    .write_enable(RegWrite), // input
    .rs1_dout(rs1_dout),     // output
    .rs2_dout(rs2_dout),     // output
    .print_reg(print_reg)  //DO NOT TOUCH THIS
  );


  // ---------- Control Unit ----------
  control_unit ctrl_unit (
    .part_of_inst(inst[6:0]),  // input
    .is_jal(JAL),        // output
    .is_jalr(JALR),       // output
    .branch(Branch),        // output
    .mem_read(MemRead),      // output
    .mem_to_reg(MemtoReg),    // output
    .mem_write(MemWrite),     // output
    .alu_src_1(ALUSrc_1),     // output
    .alu_src_2(ALUSrc_2),     // output
    .write_enable(RegWrite),  // output
    .pc_to_reg(PCtoReg),     // output
    .is_ecall(is_ecall)       // output (ecall inst)
  );

  // ---------- Immediate Generator ----------
  immediate_generator imm_gen(
    .inst(inst),  // input
    .imm_gen_out(imm)    // output
  );

  // ---------- ALU Control Unit ----------
  alu_control_unit alu_ctrl_unit (
    .part_of_inst({inst[30], inst[14:12], inst[6:0]}),  // input
    .alu_op(ALUOp)         // output
  );

  // ---------- ALU ----------
  alu alu (
    .alu_op(ALUOp),      // input
    .alu_in_1(i_alu_a),    // input  
    .alu_in_2(i_alu_b),    // input
    .alu_result(ALU_result),  // output
    .alu_bcond(bcond)    // output
  );

  // ---------- Data Memory ----------
  data_memory dmem(
    .reset(reset),      // input
    .clk(clk),        // input
    .addr(ALU_result),       // input
    .din(rs2_dout),        // input
    .mem_read(MemRead),   // input
    .mem_write(MemWrite),  // input
    .dout(o_memory_dout_aux)        // output
  );
endmodule
