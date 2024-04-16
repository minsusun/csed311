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
  /***** Wire declarations *****/
  /***** IF Stage *****/
  wire [31:0] IF_inst;
  /***** ID Stage *****/
  wire ID_alu_op;
  wire ID_alu_src;
  wire ID_mem_write;
  wire ID_mem_read;
  wire ID_mem_to_reg;
  wire ID_reg_write;
  wire [31:0] ID_rs1_data;
  wire [31:0] ID_rs2_data;
  wire [31:0] ID_imm;
  wire ID_ALU_ctrl_unit_input;
  wire [ 5:0] ID_rd;
  /***** EX Stage *****/
  /***** MEM Stage *****/
  /***** WB Stage *****/
  /***** Register declarations *****/
  // You need to modify the width of registers
  // In addition, 
  // 1. You might need other pipeline registers that are not described below
  // 2. You might not need registers described below
  /***** IF/ID pipeline registers *****/
  reg [31:0] IF_ID_inst;           // will be used in ID stage
  /***** ID/EX pipeline registers *****/
  // From the control unit
  reg ID_EX_alu_op;         // will be used in EX stage
  reg ID_EX_alu_src;        // will be used in EX stage
  reg ID_EX_mem_write;      // will be used in MEM stage
  reg ID_EX_mem_read;       // will be used in MEM stage
  reg ID_EX_mem_to_reg;     // will be used in WB stage
  reg ID_EX_reg_write;      // will be used in WB stage
  // From others
  reg ID_EX_rs1_data;
  reg ID_EX_rs2_data;
  reg ID_EX_imm;
  reg ID_EX_ALU_ctrl_unit_input;
  reg ID_EX_rd;

  /***** EX/MEM pipeline registers *****/
  // From the control unit
  reg EX_MEM_mem_write;     // will be used in MEM stage
  reg EX_MEM_mem_read;      // will be used in MEM stage
  reg EX_MEM_is_branch;     // will be used in MEM stage
  reg EX_MEM_mem_to_reg;    // will be used in WB stage
  reg EX_MEM_reg_write;     // will be used in WB stage
  // From others
  reg EX_MEM_alu_out;
  reg EX_MEM_dmem_data;
  reg EX_MEM_rd;

  /***** MEM/WB pipeline registers *****/
  // From the control unit
  reg MEM_WB_mem_to_reg;    // will be used in WB stage
  reg MEM_WB_reg_write;     // will be used in WB stage
  // From others
  reg [4:0] MEM_WB_mem_to_reg_src_1;
  reg [4:0] MEM_WB_mem_to_reg_src_2;
  reg MEM_WB_is_halt;

  // ---------- Update program counter ----------
  // PC must be updated on the rising edge (positive edge) of the clock.
  PC pc(
    .reset(reset),       // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),         // input
    .next_pc(),     // input
    .current_pc()   // output
  );
  
  // ---------- Instruction Memory ----------
  InstMemory imem(
    .reset(reset),   // input
    .clk(clk),     // input
    .addr(),    // input
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
    .rs1 (),          // input
    .rs2 (),          // input
    .rd (),           // input
    .rd_din (),       // input
    .write_enable (MEM_WB_reg_write),    // input
    .rs1_dout (ID_rs1_data),     // output
    .rs2_dout (ID_rs2_data),      // output
    .print_reg(print_reg)
  );


  // ---------- Control Unit ----------
  ControlUnit ctrl_unit (
    .part_of_inst(),  // input
    .mem_read(ID_mem_read),      // output
    .mem_to_reg(ID_mem_to_reg),    // output
    .mem_write(ID_mem_write),     // output
    .alu_src(ID_alu_src),       // output
    .write_enable(ID_reg_write),  // output
    .pc_to_reg(ID_mem_to_reg),     // output
    .alu_op(ID_alu_op),        // output
    .is_ecall()       // output (ecall inst)
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
      ID_EX_alu_op = 0;
      ID_EX_alu_src = ID_mem_write;
      ID_EX_mem_write = ID_mem_write;
      ID_EX_mem_read = ID_mem_read;
      ID_EX_mem_to_reg = ID_mem_to_reg;
      ID_EX_reg_write = ID_reg_write;
      ID_EX_rs1_data = ID_rs1_data;
      ID_EX_rs2_data = ID_rs2_data;
      ID_EX_imm = ID_imm;
      ID_EX_ALU_ctrl_unit_input = 0;
      ID_EX_rd = ID_rd;
    end
  end

  // ---------- ALU Control Unit ----------
  ALUControlUnit alu_ctrl_unit (
    .part_of_inst(),  // input
    .alu_op()         // output
  );

  // ---------- ALU ----------
  ALU alu (
    .alu_op(),      // input
    .alu_in_1(),    // input  
    .alu_in_2(),    // input
    .alu_result(),  // output
    .alu_zero()     // output
  );

  // Update EX/MEM pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
    end
    else begin
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
      MEM_WB_mem_to_reg_src_1 = 5'b0;
      MEM_WB_mem_to_reg_src_2 = 5'b0;
      MEM_WB_is_halt = 0;
    end
    else begin
    end
  end

  
endmodule
