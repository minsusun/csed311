// TODO: Forwarding for branch computation in ID stage.
module ForwardingUnit(
    input [4:0] EX_rs1,
    input [4:0] EX_rs2,
    input [4:0] EX_rd,
    input [4:0] MEM_rd,
    input [4:0] WB_rd,
    input MEM_reg_write,
    input WB_reg_write,
    output reg [1:0] forward_1,
    output reg [1:0] forward_2
);
    always @(*) begin
        if((EX_rs1 != 5'b0) && (EX_rs1 == MEM_rd) && MEM_reg_write)
            forward_1 = 2'b10;
        else if((EX_rs1 != 5'b0) && (EX_rs1 == WB_rd) && WB_reg_write)
            forward_1 = 2'b01;
        else
            forward_1 = 2'b00;

        if((EX_rs2 != 5'b0) && (EX_rs2 == MEM_rd) && MEM_reg_write)
            forward_2 = 2'b10;
        else if((EX_rs2 != 5'b0) && (EX_rs2 == WB_rd) && WB_reg_write)
            forward_2 = 2'b01;
        else
            forward_2 = 2'b00;
    end
endmodule
