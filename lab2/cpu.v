// TODO: Implement ECALL
// Refer to the lecture 5 pdf, page 34.
// How about integrating adders and dirty MUX's into pc module?

// Submit this file with other files you created.
// Do not touch port declarations of the module 'cpu'.

// Guidelines
// 1. It is highly recommened to `define opcodes and something useful.
// 2. You can modify the module.
// (e.g., port declarations, remove modules, define new modules, ...)
// 3. You might need to describe combinational logics to drive them into the module (e.g., mux, and, or, ...)
// 4. `include files if required

module cpu(input reset,                     // positive reset signal
           input clk,                       // clock signal
           output reg is_halted,                // Whehther to finish simulation
           output [31:0] print_reg [0:31]); // TO PRINT REGISTER VALUES IN TESTBENCH (YOU SHOULD NOT USE THIS)

  /***** Wire declarations *****/
  wire [31:0] current_pc;
  wire [31:0] next_pc;
  wire [31:0] immediate;
  wire [31:0] alu_result;
  wire [31:0] inst;
  wire [16:0] alu_op;
  wire [4:0] rs2 = inst[24:20];
  wire [4:0] rd = inst[11:7];
  wire [31:0] rs1_dout;
  wire [31:0] rs2_dout;
  wire [6:0] opcode = inst[6:0];
  wire [31:0] data;

  wire is_jal;
  wire is_jalr;
  wire branch;
  wire mem_read;
  wire mem_to_reg;
  wire mem_write;
  wire alu_src;
  wire write_enable;
  wire pc_to_reg;
  wire is_ecall;

  wire alu_bcond;

  /***** Register declarations *****/

  reg [4:0] rs1;
  reg [31:0] rd_din;
  reg [31:0] alu_in_2;

  always @(*) begin
    if(pc_to_reg)
      rd_din = current_pc + 4;
    else begin
      if(mem_to_reg)
        rd_din = data;
      else
        rd_din = alu_result;
    end
  end

  always @(*) begin
    if(alu_src) begin
      alu_in_2 = immediate;
    end else begin
      alu_in_2 = rs2_dout;
    end
  end
  
  always @(*) begin
    if(is_ecall)
      rs1 = 5'b10001;
    else
      rs1 = inst[19:15];
  end

  always @(*) begin
    if(is_ecall && rs1_dout == 10)
      is_halted = 1;
    else
      is_halted = 0;
  end

  // ---------- Update program counter ----------
  // PC must be updated on the rising edge (positive edge) of the clock.
  next_pc_logic next_pc_logic(
    .current_pc(current_pc),
    .immediate(immediate),
    .alu_result(alu_result),
    .is_jal(is_jal),
    .is_jalr(is_jalr),
    .branch(branch),
    .alu_bcond(alu_bcond),
    .next_pc(next_pc)
  );
  
  pc pc(
    .reset(reset),       // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),         // input
    .next_pc(next_pc),     // input
    .current_pc(current_pc)   // output
  );
  
  // ---------- Instruction Memory ----------
  instruction_memory imem(
    .reset(reset),   // input
    .clk(clk),     // input
    .addr(current_pc),    // input
    .dout(inst)     // output
  );

  // ---------- Register File ----------
  register_file reg_file (
    .reset (reset),        // input
    .clk (clk),          // input
    .rs1 (rs1),          // input
    .rs2 (rs2),          // input
    .rd (rd),           // input
    .rd_din (rd_din),       // input
    .write_enable (write_enable), // input
    .rs1_dout (rs1_dout),     // output
    .rs2_dout (rs2_dout),     // output
    .print_reg (print_reg)  //DO NOT TOUCH THIS
  );


  // ---------- Control Unit ----------
  control_unit ctrl_unit (
    // Note that the port name has been changed from 'part_of_inst' to 'opcode'
    .opcode(opcode),  // input
    .is_jal(is_jal),        // output
    .is_jalr(is_jalr),       // output
    .branch(branch),        // output
    .mem_read(mem_read),      // output
    .mem_to_reg(mem_to_reg),    // output
    .mem_write(mem_write),     // output
    .alu_src(alu_src),       // output
    .write_enable(write_enable),  // output
    .pc_to_reg(pc_to_reg),     // output
    .is_ecall(is_ecall)       // output (ecall inst)
  );

  // ---------- Immediate Generator ----------
  immediate_generator imm_gen(
    // Note the port name changed from original skeleton code.
    .inst(inst),  // input
    .imm_gen_out(immediate)    // output
  );

  // ---------- ALU Control Unit ----------
  alu_ctrl_unit alu_ctrl_unit (
    // Note that the port name changed from original skeleton code.
    .funct7(inst[31:25]),
    .funct3(inst[14:12]),
    .opcode(inst[6:0]),
    .alu_op(alu_op)         // output
  );

  // ---------- ALU ----------
  alu alu (
    .alu_op(alu_op),      // input
    .alu_in_1(rs1_dout),    // input  
    .alu_in_2(alu_in_2),    // input
    .alu_result(alu_result),  // output
    .alu_bcond(alu_bcond)    // output
  );

  // ---------- Data Memory ----------
  data_memory dmem(
    .reset (reset),      // input
    .clk (clk),        // input
    .addr (alu_result),       // input
    .din (rs2_dout),        // input
    .mem_read (mem_read),   // input
    .mem_write (mem_write),  // input
    .dout (data)        // output
  );
endmodule
