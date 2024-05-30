`include "opcodes.v"

module cpu(
    input reset,
    input clk,
    output reg is_halted,
    output [31:0] print_reg [0:31],
    output integer mem_access_count,
    output integer cache_hit_count
);
  // To calculate cache hit ratio
  initial begin
    mem_access_count = 0;
    cache_hit_count = 0;
  end

  event mem_access;
  event hit;

  always @(EX_MEM_current_pc) begin
    if (MEM_is_input_valid)
      -> mem_access;

    if (MEM_is_hit && MEM_is_input_valid)
      -> hit;
  end

  always @(mem_access)
    mem_access_count <= mem_access_count + 1;

  always @(hit)
    cache_hit_count <= cache_hit_count + 1;

  // Wire naming convention
  // When a wire signal is generated in {STAGE_NAME}, 
  // the name of the wire is {STAGE_NAME}_WIRENAME

  // Pipeline register naming convention
  // For a pipeline register between {STAGE1_NAME} and {STAGE2_name}, 
  // the name of the pipeline register is 
  // {STAGE1_NAME}_{STAGE2_NAME}_REGISTERNAME

  // IF stage wire declarations
  wire IF_pc_write;
  wire IF_prediction;
  wire IF_is_stall;
  wire IF_is_flush;
  wire [31:0] IF_next_pc;
  wire [31:0] IF_current_pc;
  wire [31:0] IF_predicted_pc;
  wire [31:0] IF_inst;

  // IF/ID stage pipeline register declarations
  reg IF_ID_prediction;
  reg IF_ID_is_flush;
  reg [31:0] IF_ID_current_pc;
  reg [31:0] IF_ID_predicted_pc;
  reg [31:0] IF_ID_inst;

  // IF stage module instantiations
  PC pc(
    .reset(reset),
    .clk(clk),
    .pc_write(IF_pc_write),
    .next_pc(IF_next_pc),
    .current_pc(IF_current_pc)
  );

  InstMemory instruction_memory(
    .reset(reset),
    .clk(clk),
    .addr(IF_current_pc),
    .dout(IF_inst)
  );

  BranchPredict branch_predict(
    .reset(reset),
    .clk(clk),
    .is_correct(ID_EX_is_correct),
    .is_control_flow(ID_EX_is_jalr || ID_EX_is_jal || ID_EX_is_branch),
    .current_pc(IF_current_pc),
    .pc_to_update(ID_EX_current_pc),
    .branch_target(ID_EX_branch_target),
    .prediction(IF_prediction),
    .predicted_pc(IF_predicted_pc)
  );

  // IF stage combinational logics
  assign IF_next_pc = ID_is_correct ? IF_predicted_pc : ID_next_pc;
  assign IF_pc_write = !IF_is_stall && !MEM_is_stall;
  assign IF_is_stall = ID_is_data_hazard || (ID_is_jalr && !ID_EX_is_jalr);
  assign IF_is_flush = ID_is_control_hazard;

  // IF/ID stage pipeline register updates
  // IF_is_flush must passed until ID stage, and if current instruction in 
  // ID stage's is_flush is asserted, its mem_write and reg_write must be 
  // de-asserted.
  always @(posedge clk) begin
    if (!IF_is_stall && !MEM_is_stall) begin
      IF_ID_is_flush <= reset ? 0 : IF_is_flush;
      IF_ID_prediction <= reset ? 0 : IF_prediction;
      IF_ID_current_pc <= reset ? 0 : IF_current_pc;
      IF_ID_predicted_pc <= reset ? 0 : IF_predicted_pc;
      IF_ID_inst <= reset ? 0 : IF_inst;
    end
  end

  // ID stage wire declarations
  wire ID_bcond;
  wire ID_is_stall;
  wire ID_is_taken;
  wire ID_reg_write;
  wire ID_alu_src;
  wire ID_mem_read;
  wire ID_mem_write;
  wire ID_mem_to_reg;
  wire ID_pc_to_reg;
  wire [1:0] ID_alu_op;
  wire ID_is_jal;
  wire ID_is_jalr;
  wire ID_is_branch;
  wire ID_is_ecall;
  wire ID_is_data_hazard;
  wire ID_is_control_hazard;
  wire ID_is_correct;
  wire [1:0] ID_forward_1;
  wire [1:0] ID_forward_2;
  wire [4:0] ID_rs1;
  wire [31:0] ID_imm;
  wire [31:0] ID_rs1_dout_rf;
  wire [31:0] ID_rs2_dout_rf;
  wire [31:0] ID_branch_target;
  reg [31:0] ID_next_pc;
  reg [31:0] ID_rs1_dout;
  reg [31:0] ID_rs2_dout;

  // ID/EX stage pipeline register declarations
  reg ID_EX_alu_src;
  reg [1:0] ID_EX_alu_op;
  reg ID_EX_mem_read;
  reg ID_EX_mem_write;
  reg ID_EX_is_jalr;
  reg ID_EX_is_jal;
  reg ID_EX_is_branch;
  reg ID_EX_is_correct;
  reg ID_EX_is_halted;
  reg ID_EX_reg_write;
  reg ID_EX_mem_to_reg;
  reg ID_EX_pc_to_reg;
  reg [31:0] ID_EX_inst;
  reg [31:0] ID_EX_current_pc;
  reg [31:0] ID_EX_branch_target;
  reg [31:0] ID_EX_rs1_dout;
  reg [31:0] ID_EX_rs2_dout;
  reg [31:0] ID_EX_imm;

  // ID stage module instantiations
  HazardDetection hazard_detection(
    .bcond(ID_bcond),
    .prediction(IF_ID_prediction),
    .ID_opcode(IF_ID_inst[6:0]),
    .ID_rs1(ID_rs1),
    .ID_rs2(IF_ID_inst[24:20]),
    .EX_rd(ID_EX_inst[11:7]),
    .MEM_rd(EX_MEM_inst[11:7]),
    .MEM_mem_read(EX_MEM_mem_read),
    .EX_mem_read(ID_EX_mem_read),
    .is_data_hazard(ID_is_data_hazard),
    .is_control_hazard(ID_is_control_hazard)
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
    .alu_op(ID_alu_op),
    .is_jalr(ID_is_jalr),
    .is_jal(ID_is_jal),
    .is_branch(ID_is_branch),
    .is_ecall(ID_is_ecall)
  );

  RegisterFile register_file(
    .reset(reset),
    .clk(clk),
    .write_enable(MEM_WB_reg_write),
    .rs1(ID_rs1),
    .rs2(IF_ID_inst[24:20]),
    .rd(MEM_WB_inst[11:7]),
    .rd_din(WB_din),
    .rs1_dout(ID_rs1_dout_rf),
    .rs2_dout(ID_rs2_dout_rf),
    .print_reg(print_reg)
  );

  ImmediateGenerator immediate_generator(
    .inst(IF_ID_inst),
    .immediate(ID_imm)
  );

  ForwardingUnit forwarding_unit(
    .ID_rs1(ID_rs1),
    .ID_rs2(IF_ID_inst[24:20]),
    .EX_rd(ID_EX_inst[11:7]),
    .MEM_rd(EX_MEM_inst[11:7]),
    .WB_rd(MEM_WB_inst[11:7]),
    .EX_reg_write(ID_EX_reg_write),
    .MEM_reg_write(EX_MEM_reg_write),
    .WB_reg_write(MEM_WB_reg_write),
    .forward_1(ID_forward_1),
    .forward_2(ID_forward_2)
  );

  BranchPreFetcher branch_prefetcher(
    .btype(IF_ID_inst[14:12]),
    .rs1_dout(ID_rs1_dout),
    .rs2_dout(ID_rs2_dout),
    .bcond(ID_bcond)
  );

  // ID stage combinational logics
  assign ID_is_stall = ID_is_data_hazard || (ID_is_jalr && !ID_EX_is_jalr);
  assign ID_is_taken = ID_is_jal || ID_is_jalr || ID_is_branch && ID_bcond; 
  assign ID_rs1 = ID_is_ecall ? 17 : IF_ID_inst[19:15];
  assign ID_branch_target = IF_ID_current_pc + ID_imm; 
  assign ID_is_correct = !(IF_ID_prediction ^ ID_is_taken);

  always @(*) begin
    if (ID_EX_is_jalr)
      ID_next_pc = EX_alu_result;
    else if (ID_is_jal || ID_is_branch && ID_bcond)
      ID_next_pc = ID_branch_target;
    else
      ID_next_pc = IF_ID_current_pc + 4;
  end

  always @(*) begin
    case(ID_forward_1)
    2'b00: ID_rs1_dout = ID_rs1_dout_rf;
    2'b01: ID_rs1_dout = WB_din;
    2'b10: ID_rs1_dout =
      EX_MEM_pc_to_reg ? EX_MEM_current_pc + 4 : EX_MEM_alu_result;
    2'b11: ID_rs1_dout = 
      ID_EX_pc_to_reg ? ID_EX_current_pc + 4 : EX_alu_result;
    default: ID_rs1_dout = 0;
    endcase

    case(ID_forward_2)
    2'b00: ID_rs2_dout = ID_rs2_dout_rf;
    2'b01: ID_rs2_dout = WB_din;
    2'b10: ID_rs2_dout = 
      EX_MEM_pc_to_reg ? EX_MEM_current_pc + 4 : EX_MEM_alu_result;
    2'b11: ID_rs2_dout = 
      ID_EX_pc_to_reg ? ID_EX_current_pc + 4 : EX_alu_result;
    default: ID_rs2_dout = 0;
    endcase
  end

  // ID/EX stage pipeline register updates
  always @(posedge clk) begin
    if (!MEM_is_stall || reset) begin
      ID_EX_alu_src <= reset ? 0 : ID_alu_src;
      ID_EX_alu_op <= reset ? 0 : ID_alu_op;
      ID_EX_mem_read <= reset ? 0 : ID_mem_read;
      ID_EX_mem_write <= 
        (reset || IF_ID_is_flush || ID_is_stall) ? 0 : ID_mem_write;
      ID_EX_is_jalr <= reset ? 0 : ID_is_jalr;
      ID_EX_is_jal <= reset ? 0 : ID_is_jal;
      ID_EX_is_branch <= reset ? 0 : ID_is_branch;
      ID_EX_is_correct <= reset ? 0 : ID_is_correct;
      ID_EX_is_halted <= reset ? 0 : ID_is_ecall && (ID_rs1_dout == 10);
      ID_EX_reg_write <= 
        (reset || IF_ID_is_flush || ID_is_stall) ? 0 : ID_reg_write;
      ID_EX_mem_to_reg <= reset ? 0 : ID_mem_to_reg;
      ID_EX_pc_to_reg <= reset ? 0 : ID_pc_to_reg;
      ID_EX_inst <= reset ? 0 : IF_ID_inst;
      ID_EX_current_pc <= reset ? 0 : IF_ID_current_pc;
      ID_EX_branch_target <= reset ? 0 : ID_branch_target;
      ID_EX_rs1_dout <= reset ? 0 : ID_rs1_dout;
      ID_EX_rs2_dout <= reset ? 0 : ID_rs2_dout;
      ID_EX_imm <= reset ? 0 : ID_imm;
    end
  end

  // EX stage wire declarations
  wire [3:0] EX_alu_ctrl;
  wire [31:0] EX_alu_in_2;
  wire [31:0] EX_alu_result;

  // EX/MEM stage pipeline register declarations
  reg EX_MEM_is_jal;
  reg EX_MEM_is_jalr;
  reg EX_MEM_mem_read;
  reg EX_MEM_mem_write;
  reg EX_MEM_reg_write;
  reg EX_MEM_mem_to_reg;
  reg EX_MEM_pc_to_reg;
  reg EX_MEM_is_halted;
  reg [31:0] EX_MEM_inst;
  reg [31:0] EX_MEM_rs2_dout;
  reg [31:0] EX_MEM_current_pc;
  reg [31:0] EX_MEM_alu_result;

  // EX stage module instantiations
  ALU alu(
    .alu_ctrl(EX_alu_ctrl),
    .alu_in_1(ID_EX_rs1_dout),
    .alu_in_2(EX_alu_in_2),
    .alu_result(EX_alu_result)
  );

  ALUControlUnit alu_control_unit(
    .alu_op(ID_EX_alu_op),
    .inst(ID_EX_inst),
    .alu_ctrl(EX_alu_ctrl)
  );

  // EX stage combinational logics
  assign EX_alu_in_2 = ID_EX_alu_src ? ID_EX_imm : ID_EX_rs2_dout; 

  // EX/MEM stage pipeline register updates
  always @(posedge clk) begin
    if (!MEM_is_stall || reset) begin
      EX_MEM_is_jal <= reset ? 0 : ID_EX_is_jal;
      EX_MEM_is_jalr <= reset ? 0 : ID_EX_is_jalr;
      EX_MEM_mem_read <= reset ? 0 : ID_EX_mem_read;
      EX_MEM_mem_write <= reset ? 0 : ID_EX_mem_write;
      EX_MEM_reg_write <= reset ? 0 : ID_EX_reg_write;
      EX_MEM_mem_to_reg <= reset ? 0 : ID_EX_mem_to_reg;
      EX_MEM_pc_to_reg <= reset ? 0 : ID_EX_pc_to_reg;
      EX_MEM_is_halted <= reset ? 0 : ID_EX_is_halted;
      EX_MEM_inst <= reset ? 0 : ID_EX_inst;
      EX_MEM_rs2_dout <= reset ? 0 : ID_EX_rs2_dout;
      EX_MEM_current_pc <= reset ? 0 : ID_EX_current_pc;
      EX_MEM_alu_result <= reset ? 0 : EX_alu_result;
    end
  end

  // MEM stage wire declarations
  wire [31:0] MEM_dout;
  wire MEM_is_cache_ready;
  wire MEM_is_stall;
  wire MEM_is_input_valid;
  wire MEM_is_output_valid;
  wire MEM_is_hit;
  wire MEM_mem_rw;
  wire MEM_in_use;

  // MEM/WB stage pipeline register declarations
  reg MEM_WB_is_jal;
  reg MEM_WB_is_jalr;
  reg MEM_WB_reg_write;
  reg MEM_WB_mem_to_reg;
  reg MEM_WB_pc_to_reg;
  reg MEM_WB_is_halted;
  reg [31:0] MEM_WB_inst;
  reg [31:0] MEM_WB_dout;
  reg [31:0] MEM_WB_alu_result;
  reg [31:0] MEM_WB_current_pc;

  Cache data_cache(
    .reset(reset),
    .clk(clk),
    .mem_rw(MEM_mem_rw),
    .is_input_valid(MEM_is_input_valid),
    .addr(EX_MEM_alu_result),
    .din(EX_MEM_rs2_dout),
    .is_hit(MEM_is_hit),
    .dout(MEM_dout),
    .is_ready(MEM_is_cache_ready),
    .is_output_valid(MEM_is_output_valid)
  );

  assign MEM_is_input_valid = EX_MEM_mem_read || EX_MEM_mem_write;
  assign MEM_mem_rw = EX_MEM_mem_write;
  assign MEM_in_use = MEM_is_input_valid ? !MEM_is_output_valid : 0;
  assign MEM_is_stall = MEM_is_input_valid && !MEM_is_cache_ready || MEM_in_use;

  // MEM/WB stage pipeline register declarations
  always @(posedge clk) begin
    if (!MEM_in_use || reset) begin
      MEM_WB_is_jal <= reset ? 0 : EX_MEM_is_jal;
      MEM_WB_is_jalr <= reset ? 0 : EX_MEM_is_jalr;
      MEM_WB_reg_write <= reset ? 0 : EX_MEM_reg_write;
      MEM_WB_mem_to_reg <= reset ? 0 : EX_MEM_mem_to_reg;
      MEM_WB_pc_to_reg <= reset ? 0 : EX_MEM_pc_to_reg;
      MEM_WB_is_halted <= reset ? 0 : EX_MEM_is_halted;
      MEM_WB_inst <= reset ? 0 : EX_MEM_inst;
      MEM_WB_dout <= reset ? 0 : MEM_dout;
      MEM_WB_alu_result <= reset ? 0 : EX_MEM_alu_result;
      MEM_WB_current_pc <= reset ? 0 : EX_MEM_current_pc;
    end
  end

  // WB stage wire declarations
  reg [31:0] WB_din;

  // WB combinational logics
  always @(*) begin
    if (MEM_WB_pc_to_reg)
      WB_din = MEM_WB_current_pc + 4;
    else if (MEM_WB_mem_to_reg)
      WB_din = MEM_WB_dout;
    else
      WB_din = MEM_WB_alu_result;
  end

  // WB sequential logics
  always @(posedge clk) begin
    is_halted <= reset ? 0 : MEM_WB_is_halted;
  end
endmodule
