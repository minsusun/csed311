`include "opcodes.v"

module alu(
    input [16:0] alu_op,
    input [31:0] alu_in_1,
    input [31:0] alu_in_2,
    output reg [31:0] alu_result,
    output reg alu_bcond
);
    reg [6:0] opcode = alu_op[6:0];
    reg [2:0] funct3 = alu_op[9:7];
    reg [6:0] funct7 = alu_op[16:10];

    always @(*) begin
        case(opcode)
        `ARITHMETIC: begin
            alu_bcond = 1'b0;
            if(funct7 != `FUNCT7_SUB) begin
                case(funct3)
                `FUNCT3_ADD: alu_result = alu_in_1 + alu_in_2;
                `FUNCT3_SLL: alu_result = alu_in_1 << alu_in_2;
                `FUNCT3_XOR: alu_result = alu_in_1 ^ alu_in_2;
                `FUNCT3_SRL: alu_result = alu_in_1 >> alu_in_2;
                `FUNCT3_OR : alu_result = alu_in_1 | alu_in_2;
                `FUNCT3_AND: alu_result = alu_in_1 & alu_in_2;
                default    : alu_result = 32'b0;
                endcase
            end else begin
                alu_result = alu_in_1 - alu_in_2;
            end
        end

        `ARITHMETIC_IMM: begin
            alu_bcond = 1'b0;
            case(funct3)
            `FUNCT3_ADD: alu_result = alu_in_1 + alu_in_2;
            `FUNCT3_SLL: alu_result = alu_in_1 << alu_in_2;
            `FUNCT3_XOR: alu_result = alu_in_1 ^ alu_in_2;
            `FUNCT3_OR : alu_result = alu_in_1 | alu_in_2;
            `FUNCT3_AND: alu_result = alu_in_1 & alu_in_2;
            `FUNCT3_SRL: alu_result = alu_in_1 >> alu_in_2;
            default    : alu_result = 32'b0;
            endcase
        end

        `LOAD: begin
            alu_bcond = 1'b0;
            alu_result = alu_in_1 + alu_in_2;
        end

        `JALR: begin
            alu_bcond = 1'b0;
            alu_result = alu_in_1 + alu_in_2;
        end

        `STORE: begin
            alu_bcond = 1'b0;
            alu_result = alu_in_1 + alu_in_2;
        end

        `BRANCH: begin
            alu_result = 32'b0;
            case(funct3)
            `FUNCT3_BEQ: alu_bcond = (alu_in_1 == alu_in_2);
            `FUNCT3_BNE: alu_bcond = (alu_in_1 != alu_in_2);
            `FUNCT3_BLT: alu_bcond = (alu_in_1 < alu_in_2);
            `FUNCT3_BGE: alu_bcond = (alu_in_1 >= alu_in_2);
            default    : alu_bcond = 1'b0; 
            endcase
        end

        `JAL: begin
            alu_result = 32'b0;
            alu_bcond = 1'b0;
        end

        default: begin
            alu_result = 32'b0;
            alu_bcond = 1'b0;
        end
        endcase
    end
endmodule
