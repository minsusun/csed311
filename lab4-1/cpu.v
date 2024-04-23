// Submit this file with other files you created.
// Do not touch port declarations of the module 'CPU'.

// Guidelines
// 1. It is highly recommened to `define opcodes and something useful.
// 2. You can modify modules (except InstMemory, DataMemory, and RegisterFile)
// (e.g., port declarations, remove modules, define new modules, ...)
// 3. You might need to describe combinational logics to drive them into the module (e.g., mux, and, or, ...)
// 4. `include files if required

module cpu(input reset,       // positive reset signal
           input clk,         // clock signal
           output is_halted, // Whehther to finish simulation
           output [31:0]print_reg[0:31]); // Whehther to finish simulation
  /* NAME CONVENTION */
  /* (STAGE_NAME)_REGISTERORWIRE_NAME */
  /* (STAGE_1_NAME)_(STAGE_2_NAME)_REGISTERORWIRE_NAME */
  
  /***** Wire declarations *****/
  /***** PC *****/
  wire [31: 0] current_pc;
  wire [31: 0] next_pc;

  /***** IF Stage *****/
  // ID
  wire [31: 0] IF_inst;

  // EX
  wire [31: 0] IF_PC;

  /***** ID Stage *****/
  // EX
  wire [31: 0] ID_PC;
  wire [ 1: 0] ID_alu_op;
  wire ID_alu_src;
  wire [31: 0] ID_rs1_data;
  wire [31: 0] ID_rs2_data;
  wire [31: 0] ID_imm;
  wire [31: 0] ID_ALU_ctrl_unit_input;
  
  // MEM
  wire ID_mem_write;
  wire ID_mem_read;
  
  // WB
  wire ID_mem_to_reg;
  wire ID_reg_write;
  wire [ 4: 0] ID_rd;
  wire ID_is_ecall;
  
  /***** EX Stage *****/
  //EX
  wire [31: 0] EX_ALU_in_2;
  wire [ 4: 0] EX_alu_op;
  wire [31: 0] EX_alu_out;
  wire EX_alu_bcond;

  // MEM
  wire EX_is_branch;
  wire EX_mem_write;
  wire EX_mem_read;
  wire [31: 0] EX_dmem_data;
  
  // WB
  wire EX_mem_to_reg;
  wire EX_reg_write;
  wire [ 4: 0] EX_rd;

  /***** MEM Stage *****/
  // WB
  wire MEM_mem_to_reg;
  wire MEM_reg_write;
  
  /***** WB Stage *****/
  wire [31: 0] WB_rdin_data;

  /***** Register declarations *****/
  // You need to modify the width of registers
  // In addition, 
  // 1. You might need other pipeline registers that are not described below
  // 2. You might not need registers described below
  
  /***** IF/ID pipeline registers *****/
  reg [31: 0] IF_ID_inst;           // will be used in ID stage
  reg [31: 0] IF_ID_PC;             // will be used in EX stage
  
  /***** ID/EX pipeline registers *****/
  // From the control unit
  reg [31: 0] ID_EX_PC;     // will be used in EX stage
  reg [ 1: 0] ID_EX_alu_op;         // will be used in EX stage
  reg ID_EX_alu_src;        // will be used in EX stage
  reg ID_EX_is_branch;      // will be used in MEM stage
  reg ID_EX_mem_write;      // will be used in MEM stage
  reg ID_EX_mem_read;       // will be used in MEM stage
  reg ID_EX_mem_to_reg;     // will be used in WB stage
  reg ID_EX_reg_write;      // will be used in WB stage
  // From others
  reg [31: 0] ID_EX_rs1_data;
  reg [31: 0] ID_EX_rs2_data;
  reg [31: 0] ID_EX_imm;
  reg [31: 0] ID_EX_ALU_ctrl_unit_input;
  reg [ 4: 0] ID_EX_rd;
  reg is_ecall;

  /***** EX/MEM pipeline registers *****/
  // From the control unit
  reg EX_MEM_mem_write;     // will be used in MEM stage
  reg EX_MEM_mem_read;      // will be used in MEM stage
  reg EX_MEM_is_branch;     // will be used in MEM stage
  reg EX_MEM_alu_bcond;     // will be used in MEM stage
  reg EX_MEM_mem_to_reg;    // will be used in WB stage
  reg EX_MEM_reg_write;     // will be used in WB stage
  // From others
  reg [31: 0] EX_MEM_alu_out;
  reg [31: 0] EX_MEM_dmem_data;
  reg [ 4: 0] EX_MEM_rd;

  /***** MEM/WB pipeline registers *****/
  // From the control unit
  reg MEM_WB_mem_to_reg;    // will be used in WB stage
  reg MEM_WB_reg_write;     // will be used in WB stage
  // From others
  reg [31: 0] MEM_WB_mem_to_reg_src_1;
  reg [31: 0] MEM_WB_mem_to_reg_src_2;
  reg MEM_WB_is_halt;

  // ---------- Update program counter ----------
  // PC must be updated on the rising edge (positive edge) of the clock.
  assign next_pc = current_pc + 4;
  PC pc(
    .reset(reset),       // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),         // input
    .next_pc(next_pc),     // input
    .current_pc(current_pc)   // output
  );
  
  // ---------- Instruction Memory ----------
  InstMemory imem(
    .reset(reset),   // input
    .clk(clk),     // input
    .addr(current_pc),    // input
    .dout(IF_inst)     // output
  );

  // Update IF/ID pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
      IF_ID_inst = 32'b0;
    end
    else begin
      IF_ID_inst = IF_inst;
    end
  end

  // ---------- Register File ----------
  RegisterFile reg_file (
    .reset (reset),        // input
    .clk (clk),          // input
    .rs1 (IF_ID_inst[19:15]),          // input
    .rs2 (IF_ID_inst[24: 0]),          // input
    .rd (IF_ID_inst[11: 7]),           // input
    .rd_din (EX_rdin_data),       // input
    .write_enable (MEM_WB_reg_write),    // input
    .rs1_dout (ID_rs1_data),     // output
    .rs2_dout (ID_rs2_data),      // output
    .print_reg(print_reg)
  );


  // ---------- Control Unit ----------
  ControlUnit ctrl_unit (
    .part_of_inst(IF_ID_inst),  // input
    .mem_read(ID_mem_read),      // output
    .mem_to_reg(ID_mem_to_reg),    // output
    .mem_write(ID_mem_write),     // output
    .alu_src(ID_alu_src),       // output
    .write_enable(ID_reg_write),  // output
    .pc_to_reg(ID_mem_to_reg),     // output
    .alu_op(ID_alu_op),        // output
    .is_ecall(ID_is_ecall)       // output (ecall inst)
  );

  // ---------- Immediate Generator ----------
  ImmediateGenerator imm_gen(
    .part_of_inst(IF_ID_inst),  // input
    .imm_gen_out(imm)    // output
  );

  // Update ID/EX pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
      ID_EX_alu_op = 0;
      ID_EX_alu_src = 0;
      ID_EX_mem_write = 0;
      ID_EX_mem_read = 0;
      ID_EX_mem_to_reg = 0;
      ID_EX_reg_write = 0;
      ID_EX_rs1_data = 32'b0;
      ID_EX_rs2_data = 32'b0;
      ID_EX_imm = 32'b0;
      ID_EX_ALU_ctrl_unit_input = 0;
      ID_EX_rd = 5'b0;
    end
    else begin
      ID_EX_alu_op = ID_alu_op;
      ID_EX_alu_src = ID_mem_write;
      ID_EX_mem_write = ID_mem_write;
      ID_EX_mem_read = ID_mem_read;
      ID_EX_mem_to_reg = ID_mem_to_reg;
      ID_EX_reg_write = ID_reg_write;
      ID_EX_rs1_data = ID_rs1_data;
      ID_EX_rs2_data = ID_rs2_data;
      ID_EX_imm = ID_imm;
      ID_EX_ALU_ctrl_unit_input = IF_ID_inst;
      ID_EX_rd = ID_rd;
    end
  end

  // ---------- ALU Control Unit ----------
  ALUControlUnit alu_ctrl_unit (
    .aluOp(ID_EX_ALU_ctrl_unit_input),
    .instruction(ID_EX_alu_op),  // input
    .alu_op(EX_alu_op)         // output
  );

  // ---------- ALU ----------
  ALU alu (
    .alu_op(EX_alu_op),      // input
    .alu_in_1(ID_EX_rs1_data),    // input  
    .alu_in_2(ID_EX_rs2_data),    // input
    .alu_result(EX_alu_out),  // output
    .alu_zero(EX_is_branch)     // output
  );

  // Update EX/MEM pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
      EX_MEM_mem_write = 0;
      EX_MEM_mem_read = 0;
      EX_MEM_is_branch = 0;
      EX_MEM_mem_to_reg = 0;
      EX_MEM_reg_write = 0;
      EX_MEM_alu_out = 32'b0;
      EX_MEM_dmem_data = 32'b0;
      EX_MEM_rd = 5'b0;
    end
    else begin
      EX_MEM_mem_write = EX_mem_write;
      EX_MEM_mem_read = EX_mem_read;
      EX_MEM_is_branch = EX_is_branch;
      EX_MEM_mem_to_reg = ID_EX_mem_to_reg;
      EX_MEM_reg_write = ID_EX_reg_write;
      EX_MEM_alu_out = EX_alu_out;
      EX_MEM_dmem_data = EX_dmem_data;
      EX_MEM_rd = ID_EX_rd;
    end
  end

  // ---------- Data Memory ----------
  DataMemory dmem(
    .reset (reset),      // input
    .clk (clk),        // input
    .addr (),       // input
    .din (),        // input
    .mem_read (),   // input
    .mem_write (),  // input
    .dout ()        // output
  );

  // Update MEM/WB pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
      MEM_WB_mem_to_reg = 0;
      MEM_WB_reg_write = 0;
      MEM_WB_mem_to_reg_src_1 = 32'b0;
      MEM_WB_mem_to_reg_src_2 = 32'b0;
      MEM_WB_is_halt = 0;
    end
    else begin
    end
  end

  assign EX_ALU_in_2 = (ID_EX_alu_src) ? ID_EX_imm : ID_EX_rs2_data;
  assign MEM_PCSrc = EX_MEM_is_branch & EX_MEM_alu_bcond;
  assign WB_rdin_data = (MEM_WB_mem_to_reg) ? MEM_WB_mem_to_reg_src_1 : MEM_WB_mem_to_reg_src_2;
  
endmodule
