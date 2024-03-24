`include "alu_func.v"

module alu(
    input [6:0] alu_op,
    input [31:0] alu_in_1,
    input [31:0] alu_in_2,
    output reg [31:0] alu_result,
    output reg alu_bcond
);

wire is_branch;
wire [3:0] atype;
wire [1:0] btype;

assign is_branch = alu_op[6];
assign atype = alu_op[3:0];
assign btype = alu_op[5:4];

always @(*) begin
    if(is_branch) begin
        case(btype)
            `BRANCH_EQ: begin
                alu_bcond = alu_result == 0;
            end
            `BRANCH_NE: begin
                alu_bcond = alu_result != 0;
            end
            `BRANCH_GE: begin
                alu_bcond = $signed(alu_result) >= 0;
            end
            `BRANCH_LT: begin
                alu_bcond = $signed(alu_result) < 0;
            end
        endcase
    end
    else alu_bcond = 0;
end

always @(*) begin
    case(atype)
        `FUNC_ADD : begin
            alu_result = alu_in_1 + alu_in_2;
        end
        `FUNC_SUB : begin
            alu_result = alu_in_1 - alu_in_2;
        end
        `FUNC_ID : begin
            alu_result = alu_in_1;
        end
        `FUNC_NOT : begin
            alu_result = ~alu_in_1;
        end
        `FUNC_AND : begin
            alu_result = alu_in_1 & alu_in_2;
        end
        `FUNC_OR : begin
            alu_result = alu_in_1 | alu_in_2;
        end
        `FUNC_NAND : begin
            alu_result = ~(alu_in_1 & alu_in_2);
        end
        `FUNC_NOR : begin
            alu_result = ~(alu_in_1 | alu_in_2);
        end
        `FUNC_XOR : begin
            alu_result = alu_in_1 ^ alu_in_2;
        end
        `FUNC_XNOR : begin
            alu_result = ~(alu_in_1 ^ alu_in_2);
        end
        `FUNC_LLS : begin
            alu_result = alu_in_1 << 1;
        end
        `FUNC_LRS : begin
            alu_result = alu_in_1 >> 1;
        end
        `FUNC_ALS : begin
            alu_result = alu_in_1 <<< 1;
        end
        `FUNC_ARS : begin
            alu_result = {alu_in_1[32 - 1], {alu_in_1 >>> 1}[32 - 2: 0]};
        end
        `FUNC_TCP : begin
            alu_result = ~alu_in_1 + 1;
        end
        `FUNC_ZERO : begin
            alu_result = 0;
        end
    endcase
end

endmodule
