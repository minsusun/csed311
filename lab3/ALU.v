`include "ALUControlSignals.v"

module ALU(
    input [3:0] alu_ctrl,
    input [31:0] alu_in_a,
    input [31:0] alu_in_b,
    output reg [31:0] alu_result,
    output reg alu_bcond
);
    always @(*) begin
        case(alu_ctrl)
        `ADD: begin
            alu_result = alu_in_a + alu_in_b;
            alu_bcond = 1'b0;
        end

        `SUB: begin
            alu_result = alu_in_a - alu_in_b;
            alu_bcond = 1'b0;
        end

        `SLL: begin
            alu_result = alu_in_a << alu_in_b;
            alu_bcond = 1'b0;
        end

        `SRL: begin
            alu_result = alu_in_a >> alu_in_b;
            alu_bcond = 1'b0;
        end

        `AND: begin
            alu_result = alu_in_a & alu_in_b;
            alu_bcond = 1'b0;
        end

        `OR : begin
            alu_result = alu_in_a | alu_in_b;
            alu_bcond = 1'b0;
        end

        `XOR: begin
            alu_result = alu_in_a ^ alu_in_b;
            alu_bcond = 1'b0;
        end

        `CEQ: begin
            alu_result = 0;
            alu_bcond = (alu_in_a == alu_in_b);
        end

        `CNE: begin
            alu_result = 0;
            alu_bcond = (alu_in_a != alu_in_b);
        end

        `CLT: begin
            alu_result = 0;
            alu_bcond = (alu_in_a < alu_in_b);
        end

        `CGE: begin
            alu_result = 0;
            alu_bcond = (alu_in_a >= alu_in_b);
        end

        default: begin
            alu_result = 0;
            alu_bcond = 0;
        end
        endcase
    end
endmodule
