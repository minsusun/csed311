module PCGenerator(
    input [31: 0] PC,
    input [31: 0] imm,
    output [31: 0] next_pc
);

wire [31: 0] shifted_imm;

assign next_pc = PC + shifted_imm;
assign shifted_imm = imm << 2;

endmodule