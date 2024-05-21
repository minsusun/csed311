module ForwardingUnit(
  input [4:0] ID_rs1,
  input [4:0] ID_rs2,
  input [4:0] EX_rd,
  input [4:0] MEM_rd,
  input [4:0] WB_rd,
  input EX_reg_write,
  input MEM_reg_write,
  input WB_reg_write,
  output reg [1:0] forward_1,
  output reg [1:0] forward_2
);
  always @(*) begin
    if((ID_rs1 != 0) && (ID_rs1 == EX_rd) && EX_reg_write)
      forward_1 = 2'b11;
    else if((ID_rs1 != 0) && (ID_rs1 == MEM_rd) && MEM_reg_write)
      forward_1 = 2'b10;
    else if((ID_rs1 != 0) && (ID_rs1 == WB_rd) && WB_reg_write)
      forward_1 = 2'b01;
    else
      forward_1 = 2'b00;

    if((ID_rs2 != 0) && (ID_rs2 == EX_rd) && EX_reg_write)
      forward_2 = 2'b11;
    else if((ID_rs2 != 0) && (ID_rs2 == MEM_rd) && MEM_reg_write)
      forward_2 = 2'b10;
    else if((ID_rs2 != 0) && (ID_rs2 == WB_rd) && WB_reg_write)
      forward_2 = 2'b01;
    else
      forward_2 = 2'b00;
  end
endmodule
