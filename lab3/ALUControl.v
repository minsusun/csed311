`include "opcodes.v"

module ALUControl(
    input [1:0] aluOp,
    input [31:0] instruction,
    output reg [3:0] alu_op_o
);

always @(*) begin
    case(aluOp)
        2'b00: alu_op_o = `ALU_ADD;
        2'b01: alu_op_o = `ALU_SUB;
        default: begin
            case(instruction[6:0])
                `ARITHMETIC: begin
                    case(instruction[14:12])
                        `FUNCT3_ADD: alu_op_o = (instruction[30]) ? `ALU_SUB : `ALU_ADD;
                        `FUNCT3_SLL: alu_op_o = `ALU_SLL;
                        `FUNCT3_SRL: alu_op_o = `ALU_SLR;
                        `FUNCT3_AND: alu_op_o = `ALU_AND;
                        `FUNCT3_OR:  alu_op_o = `ALU_OR;
                        `FUNCT3_XOR: alu_op_o = `ALU_XOR;
                        default: alu_op_o = 4'b0;
                    endcase
                end
                `ARITHMETIC_IMM: begin
                    case(instruction[14:12])
                        `FUNCT3_ADD: alu_op_o = `ALU_ADD;
                        `FUNCT3_SLL: alu_op_o = `ALU_SLL;
                        `FUNCT3_SRL: alu_op_o = `ALU_SLR;
                        `FUNCT3_AND: alu_op_o = `ALU_AND;
                        `FUNCT3_OR:  alu_op_o = `ALU_OR;
                        `FUNCT3_XOR: alu_op_o = `ALU_XOR;
                        default: alu_op_o = 4'b0;
                    endcase
                end
                `BRANCH: begin
                    case(instruction[14:12])
                        `FUNCT3_BEQ: alu_op_o = `ALU_BEQ;
                        `FUNCT3_BNE: alu_op_o = `ALU_BNE;
                        `FUNCT3_BLT: alu_op_o = `ALU_BLT;
                        `FUNCT3_BGE: alu_op_o = `ALU_BGE;
                        default: alu_op_o = 4'b0;
                    endcase
                end
                `LOAD: alu_op_o = `ALU_ADD;
                `STORE: alu_op_o = `ALU_ADD;
                `JAL: alu_op_o = `ALU_ADD;
                `ECALL: alu_op_o = `ALU_BEQ;
                default: alu_op_o = 4'b0;
            endcase
        end
    endcase
end

endmodule
