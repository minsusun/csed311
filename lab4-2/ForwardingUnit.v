// TODO: Refactor code.
module ForwardingUnit(
    input [4:0] ID_rs1,
    input [4:0] ID_rs2,
    input [4:0] EX_rs1,
    input [4:0] EX_rs2,
    input [4:0] EX_rd,
    input [4:0] MEM_rd,
    input [4:0] WB_rd,
    input EX_reg_write,
    input MEM_reg_write,
    input WB_reg_write,
    output reg [1:0] ID_forward_1,
    output reg [1:0] ID_forward_2,
    output reg [1:0] EX_forward_1,
    output reg [1:0] EX_forward_2
);
    always @(*) begin
        if((ID_rs1 != 5'b0) && (ID_rs1 == EX_rd) && EX_reg_write)
            ID_forward_1 = 2'b11;
        else if((ID_rs1 != 5'b0) && (ID_rs1 == MEM_rd) && MEM_reg_write)
            ID_forward_1 = 2'b10;
        else if((ID_rs1 != 5'b0) && (ID_rs1 == WB_rd) && WB_reg_write)
            ID_forward_1 = 2'b01;
        else
            ID_forward_1 = 2'b00;

        if((ID_rs2 != 5'b0) && (ID_rs2 == EX_rd) && EX_reg_write)
            ID_forward_2 = 2'b11;
        else if((ID_rs2 != 5'b0) && (ID_rs2 == MEM_rd) && MEM_reg_write)
            ID_forward_2 = 2'b10;
        else if((ID_rs2 != 5'b0) && (ID_rs2 == WB_rd) && WB_reg_write)
            ID_forward_2 = 2'b01;
        else
            ID_forward_2 = 2'b00;

        if((EX_rs1 != 5'b0) && (EX_rs1 == MEM_rd) && MEM_reg_write)
            EX_forward_1 = 2'b10;
        else if((EX_rs1 != 5'b0) && (EX_rs1 == WB_rd) && WB_reg_write)
            EX_forward_1 = 2'b01;
        else
            EX_forward_1 = 2'b00;

        if((EX_rs2 != 5'b0) && (EX_rs2 == MEM_rd) && MEM_reg_write)
            EX_forward_2 = 2'b10;
        else if((EX_rs2 != 5'b0) && (EX_rs2 == WB_rd) && WB_reg_write)
            EX_forward_2 = 2'b01;
        else
            EX_forward_2 = 2'b00;
    end
endmodule
