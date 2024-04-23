`include "opcodes.v"

module ImmediateGenerator(
  input [31:0] instruction,
  output reg [31:0] immediate
);
  wire [6:0] opcode = inst[6:0];

  always @(*) begin
    case(opcode)
    `ARITHMETIC_IMM: immediate = {{20{inst[31]}}, inst[31:20]};
    `LOAD          : immediate = {{20{inst[31]}}, inst[31:20]};

    `STORE: begin
      immediate = {{20{inst[31]}}, inst[31:25], inst[11:7]};
    end

    `BRANCH: begin
      immediate = {
        {19{inst[31]}},
        inst[31],
        inst[7],
        inst[30:25],
        inst[11:8],
        1'b0
      };
    end

    `JAL: begin
      immediate = {
        {11{inst[31]}},
        inst[31],
        inst[19:12],
        inst[20],
        inst[30:21],
        1'b0
      };
    end

    `JALR  : immediate = {{20{inst[31]}}, inst[31:20]};
    `LUI   : immediate = {inst[31:12], 12'b0};
    `AUIPC : immediate = {inst[31:12], 12'b0};
    default: immediate = {32{1'b0}};
    endcase
  end

endmodule
