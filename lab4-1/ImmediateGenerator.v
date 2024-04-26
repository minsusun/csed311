`include "opcodes.v"

module ImmediateGenerator(
  input [31:0] part_of_inst,
  output reg [31:0] imm_gen_out
);
  wire [6:0] opcode = part_of_inst[6:0];

  always @(*) begin
    case(opcode)
    `ARITHMETIC_IMM: imm_gen_out = {{20{part_of_inst[31]}}, part_of_inst[31:20]};
    `LOAD          : imm_gen_out = {{20{part_of_inst[31]}}, part_of_inst[31:20]};

    `STORE: begin
      imm_gen_out = {{20{part_of_inst[31]}}, part_of_inst[31:25], part_of_inst[11:7]};
    end

    `BRANCH: begin
      imm_gen_out = {
        {19{part_of_inst[31]}},
        part_of_inst[31],
        part_of_inst[7],
        part_of_inst[30:25],
        part_of_inst[11:8],
        1'b0
      };
    end

    `JAL: begin
      imm_gen_out = {
        {11{part_of_inst[31]}},
        part_of_inst[31],
        part_of_inst[19:12],
        part_of_inst[20],
        part_of_inst[30:21],
        1'b0
      };
    end

    `JALR  : imm_gen_out = {{20{part_of_inst[31]}}, part_of_inst[31:20]};
    `LUI   : imm_gen_out = {part_of_inst[31:12], 12'b0};
    `AUIPC : imm_gen_out = {part_of_inst[31:12], 12'b0};
    default: imm_gen_out = {32{1'b0}};
    endcase
  end

endmodule
