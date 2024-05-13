module RegisterFile(
  input	reset,
  input clk,
  input reg_write,
  input [4:0] rs1,
  input [4:0] rs2,
  input [4:0] rd, 
  input [31:0] din,
  output [31:0] rs1_dout,
  output [31:0] rs2_dout,
  output [31:0] print_reg[0:31]
);
  integer i;
  // Register file
  reg [31:0] rf[0:31];
  assign print_reg = rf;
  // Asynchronously read register file
  assign rs1_dout = rf[rs1];
  assign rs2_dout = rf[rs2];

  always @(clk) begin
    if (clk==0) begin // negative edge
      if (reg_write & (rd != 0))
        rf[rd] <= din;
    end
    else begin // positive edge
      if (reset) begin
        rf[0] <= 32'b0;
        rf[1] <= 32'b0;
        rf[2] <= 32'h2ffc; // stack pointer
        for (i = 3; i < 32; i = i + 1)
          rf[i] <= 32'b0;
      end
    end
  end
endmodule
