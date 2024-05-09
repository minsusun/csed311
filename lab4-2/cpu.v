module cpu(
    input reset,
    input clk,
    output reg is_halted,
    output [31:0] print_reg [0:31]
);
  // Wire naming convention
  // When a wire signal is generated in {STAGE_NAME}, 
  // the name of the wire is {STAGE_NAME}_WIRENAME

  // Pipeline register naming convention
  // For a pipeline register between {STAGE1_NAME} and {STAGE2_name}, 
  // the name of the pipeline register is 
  // {STAGE1_NAME}_{STAGE2_NAME}_REGISTERNAME

  // IF stage wire declarations
  wire [1:0] IF_pc_src;
  wire [31:0] IF_next_pc;
  wire [31:0] IF_next_pc_0;
  wire [31:0] IF_next_pc_1;
  wire [31:0] IF_next_pc_2;
  wire [31:0] IF_current_pc;
  wire [31:0] IF_inst;

  // IF/ID stage pipeline register declarations
  reg [31:0] IF_ID_current_pc;
  reg [31:0] IF_ID_inst;

  // ID stage wire declarations
  wire ID_reg_write;
  wire ID_alu_src;
  wire ID_mem_read;
  wire ID_mem_write;
  wire ID_mem_to_reg;
  wire ID_pc_to_reg;
  wire ID_pc_src;
  wire [1:0] ID_alu_op;
  wire is_jalr;
  wire ID_bcond;
  wire ID_is_hazard;
  wire ID_is_ecall;
  wire ID_is_halted;
  wire [4:0] ID_rs1;
  wire [31:0] ID_rs1_dout;
  wire [31:0] ID_rs2_dout;
  wire [31:0] ID_immediate;

  // ID/EX stage pipeline register declarations
  reg ID_EX_reg_write;
  reg ID_EX_alu_src;
  reg ID_EX_mem_read;
  reg ID_EX_mem_write;
  reg ID_EX_mem_to_reg;
  reg ID_EX_pc_to_reg;
  reg ID_EX_pc_src;
  reg ID_EX_is_jalr;
  reg ID_EX_is_halted;
  reg [1:0] ID_EX_alu_op;
  reg [31:0] ID_EX_current_pc;
  reg [31:0] ID_EX_rs1_dout;
  reg [31:0] ID_EX_rs2_dout;
  reg [31:0] ID_EX_inst;
  reg [31:0] ID_EX_immediate;

  // EX stage wire declarations
  wire [1:0] EX_forward_1;
  wire [1:0] EX_forward_2;
  wire [3:0] EX_alu_ctrl;
  wire [31:0] EX_rs2_dout;
  wire [31:0] EX_alu_in_1;
  wire [31:0] EX_alu_in_2;
  wire [31:0] EX_alu_result;

  // EX/MEM stage pipeline register declarations
  reg EX_MEM_reg_write;
  reg EX_MEM_mem_read;
  reg EX_MEM_mem_write;
  reg EX_MEM_mem_to_reg;
  reg EX_MEM_pc_to_reg;
  reg EX_MEM_is_halted;
  reg [31:0] EX_MEM_current_pc;
  reg [31:0] EX_MEM_alu_result;
  reg [31:0] EX_MEM_rs2_dout;
  reg [31:0] EX_MEM_inst;

  // MEM stage wire declarations
  wire [31:0] MEM_dout;

  // MEM/WB stage pipeline register declarations
  reg MEM_WB_reg_write;
  reg MEM_WB_mem_to_reg;
  reg MEM_WB_pc_to_reg;
  reg MEM_WB_is_halted;
  reg [31:0] MEM_WB_current_pc;
  reg [31:0] MEM_WB_dout;
  reg [31:0] MEM_WB_alu_result;
  reg [31:0] MEM_WB_inst;

  // IF stage module instantiations
  PC pc(
    .reset(reset),
    .clk(clk),
    .pc_write(~is_hazard),
    .next_pc(IF_next_pc),
    .current_pc(IF_current_pc)
  );

  InstMemory instruction_memory(
    .reset(reset),
    .clk(clk),
    .addr(IF_current_pc),
    .dout(IF_inst)
  );

  // IF stage combinational logics
  always @(*) begin
    IF_pc_src = ID_EX_is_jalr ? 2'b01 : ID_pc_src;
    IF_next_pc_0 = IF_current_pc + 4;
    IF_next_pc_1 = IF_ID_current_pc + ID_immediate;
    IF_next_pc_2 = EX_alu_result;

    case(IF_pc_src)
    2'b00: IF_next_pc = IF_next_pc_0;
    2'b01: IF_next_pc = IF_next_pc_1;
    2'b10: IF_next_pc = IF_next_pc_2;
    default: IF_next_pc = 0;
    endcase
  end
  
  // IF/ID stage pipeline registers updates
  always @(posedge clk) begin
    IF_ID_current_pc <= 
      reset ? 0 : (ID_is_hazard ? IF_ID_current_pc : IF_current_pc);
    IF_ID_inst <= 
      reset ? 0 : (ID_is_hazard ? IF_ID_inst : IF_inst);
  end

  // ID stage module instantiations
  HazardDetection hazard_detection(
    .bcond(ID_bcond),
    .opcode(IF_ID_inst[6:0]),
    .is_hazard(ID_is_hazard)
  );

  ControlUnit control_unit(
    .inst(IF_ID_inst),
    .bcond(ID_bcond),
    .reg_write(ID_reg_write),
    .alu_src(ID_alu_src),
    .mem_read(ID_mem_read),
    .mem_write(ID_mem_write),
    .mem_to_reg(ID_mem_to_reg),
    .pc_to_reg(ID_pc_to_reg),
    .pc_src(ID_pc_src),
    .alu_op(ID_alu_op),
    .is_ecall(is_ecall)
  );

  RegisterFile register_file(
    .reset(reset),
    .clk(clk),
    .reg_write(ID_reg_write),
    .rs1(ID_rs1),
    .rs2(IF_ID_inst[24:20]),
    .rd(MEM_WB_inst[11:7]),
    .din(WB_din)
    .rs1_dout(ID_rs1_dout),
    .rs2_dout(ID_rs2_dout),
    .print_reg(print_reg)
  );

  ImmediateGenerator immediate_generator(
    .inst(IF_ID_inst),
    .immediate(ID_immediate)
  );

  BranchComputation branch_computation(
    .alu_op(ID_alu_op),
    .rs1_dout(ID_rs1_dout),
    .rs2_dout(ID_rs2_dout),
    .funct3(IF_ID_inst[14:12]),
    .bcond(ID_bcond)
  );

  // ID stage combinational logics
  always @(*) begin
    ID_rs1 = ID_is_ecall ? 17 : IF_ID_inst[19:15];
    ID_is_halted = ID_is_ecall && (ID_rs1_dout == 10);
  end

  // ID/EX stage pipeline registers updates
  always @(posedge clk) begin
    ID_EX_reg_write <= reset ? 0 : ID_reg_write;
    ID_EX_alu_src <= reset ? 0 : ID_alu_src;
    ID_EX_mem_read <= reset ? 0 : ID_mem_read;
    ID_EX_mem_to_reg <= reset ? 0 : ID_mem_to_reg;
    ID_EX_pc_to_reg <= reset ? 0 : ID_EX_pc_to_reg;
    ID_EX_alu_op <= reset ? 0 : ID_EX_alu_op;
    ID_EX_is_jalr <= reset ? 0 : ID_is_jalr;
    ID_EX_current_pc <= reset ? 0 : IF_ID_current_pc;
    ID_EX_rs1_dout <= reset ? 0 : ID_EX_rs1_dout;
    ID_EX_rs2_dout <= reset ? 0 : ID_EX_rs2_dout;
    ID_EX_inst <= reset ? 0 : IF_ID_inst;
    ID_EX_immediate <= reset ? 0 : ID_immediate;
    ID_EX_is_halted <= reset ? 0 : ID_is_halted;
  end


  // EX stage module instantiations
  ALU alu(
    .alu_ctrl(EX_alu_ctrl),
    .alu_in_1(EX_alu_in_1),
    .alu_in_2(EX_alu_in_2),
    .alu_result(EX_alu_result)
  );

  ALUControlUnit alu_control_unit(
    .alu_op(ID_EX_alu_op),
    .inst(ID_EX_inst),
    .alu_ctrl(EX_alu_ctrl)
  );

  ForwardingUnit forwarding_unit(
    .EX_rs1(ID_EX_inst[19:15]),
    .EX_rs2(ID_EX_inst[24:20]),
    .EX_rd(ID_EX_inst[11:7]),
    .MEM_rd(EX_MEM_inst[11:7]),
    .WB_rd(MEM_WB_inst[11:7]),
    .MEM_reg_write(MEM_reg_write),
    .WB_reg_write(WB_reg_write),
    .forward_1(EX_forward_1),
    .forward_2(EX_forward_2)
  );

  // EX stage combinational logics
  always @(*) begin
    case(EX_forward_1)
    2'b00: EX_alu_in_1 = ID_EX_rs1_dout;
    2'b01: EX_alu_in_1 = WB_din;
    2'b10: EX_alu_in_1 = EX_MEM_alu_result;
    default: EX_alu_in_1 = 0;
    endcase

    case(EX_forward_2)
    2'b00: EX_rs2_dout = ID_EX_rs2_dout;
    2'b01: EX_rs2_dout = WB_din;
    2'b10: EX_rs2_dout = EX_MEM_alu_result;
    default: EX_rs2_dout = 0;
    endcase

    EX_alu_in_2 = ID_EX_alu_src ? ID_EX_immediate : EX_rs2_dout;
  end

  // EX/MEM stage pipeline registers updates
  always @(posedge clk) begin
    EX_MEM_reg_write <= reset ? 0 : ID_EX_reg_write;
    EX_MEM_mem_read <= reset ? 0 : ID_EX_mem_read;
    EX_MEM_mem_write <= reset ? 0 : ID_EX_mem_write;
    EX_MEM_mem_to_reg <= reset ? 0 : ID_EX_mem_to_reg;
    EX_MEM_pc_to_reg <= reset ? 0 : EX_MEM_pc_to_reg;
    EX_MEM_alu_result <= reset ? 0 : EX_alu_result;
    EX_MEM_current_pc <= reset ? 0 : ID_EX_current_pc;
    EX_MEM_rs2_dout <= reset ? 0 : EX_rs2_dout;
    EX_MEM_inst <= reset ? 0 : ID_EX_inst;
    EX_MEM_is_halted <= reset ? 0 : ID_EX_is_halted;
  end

  // MEM stage module instantiations
  DataMemory data_memory(
    .reset(reset),
    .clk(clk),
    .addr(EX_MEM_alu_result),
    .din(EX_MEM_rs2_dout),
    .mem_read(EX_MEM_mem_read),
    .mem_write(EX_MEM_mem_write),
    .dout(MEM_dout)
  );

  // MEM/WB stage pipeline registers updates
  always @(posedge clk) begin
    MEM_WB_reg_write <= reset ? 0 : EX_MEM_reg_write;
    MEM_WB_mem_to_reg <= reset ? 0 : EX_MEM_mem_to_reg;
    MEM_WB_pc_to_reg <= reset ? 0 : EX_MEM_pc_to_reg;
    MEM_WB_dout <= reset ? 0 : MEM_WB_dout;
    MEM_WB_alu_result <= reset ? 0 : EX_MEM_alu_result;
    MEM_WB_current_pc <= reset ? 0 : EX_MEM_current_pc;
    MEM_WB_inst <= reset ? 0 : EX_MEM_inst;
    MEM_WB_is_halted <= reset ? 0 : MEM_WB_is_halted;
  end

  // WB stage combinational logics
  always @(*) begin
    WB_din = 
      MEM_WB_pc_to_reg ? MEM_WB_current_pc : 
        (MEM_WB_mem_to_reg ? MEM_WB_dout : MEM_WB_alu_result);
  end
endmodule