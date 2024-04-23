`include "opcodes.v"

module ALUControl(
    input [31:0] instruction,
    input [1:0] alu_op,
    output reg [3:0] alu_ctrl
);

always @(*) begin
    case(alu_op)
        2'b00: alu_ctrl = `ALU_ADD;
        2'b01: alu_ctrl = `ALU_SUB;
        default: begin
            case(instruction[6:0])
                `ARITHMETIC: begin
                    case(instruction[14:12])
                        `FUNCT3_ADD: alu_ctrl = (instruction[30]) ? `ALU_SUB : `ALU_ADD;
                        `FUNCT3_SLL: alu_ctrl = `ALU_SLL;
                        `FUNCT3_SRL: alu_ctrl = `ALU_SLR;
                        `FUNCT3_AND: alu_ctrl = `ALU_AND;
                        `FUNCT3_OR:  alu_ctrl = `ALU_OR;
                        `FUNCT3_XOR: alu_ctrl = `ALU_XOR;
                        default:     alu_ctrl = 4'b0;
                    endcase
                end
                `ARITHMETIC_IMM: begin
                    case(instruction[14:12])
                        `FUNCT3_ADD: alu_ctrl = `ALU_ADD;
                        `FUNCT3_SLL: alu_ctrl = `ALU_SLL;
                        `FUNCT3_SRL: alu_ctrl = `ALU_SLR;
                        `FUNCT3_AND: alu_ctrl = `ALU_AND;
                        `FUNCT3_OR:  alu_ctrl = `ALU_OR;
                        `FUNCT3_XOR: alu_ctrl = `ALU_XOR;
                        default:     alu_ctrl = 4'b0;
                    endcase
                end
                `BRANCH: begin
                    case(instruction[14:12])
                        `FUNCT3_BEQ: alu_ctrl = `ALU_BEQ;
                        `FUNCT3_BNE: alu_ctrl = `ALU_BNE;
                        `FUNCT3_BLT: alu_ctrl = `ALU_BLT;
                        `FUNCT3_BGE: alu_ctrl = `ALU_BGE;
                        default:     alu_ctrl = 4'b0;
                    endcase
                end
                `LOAD:   alu_ctrl = `ALU_ADD;
                `STORE:  alu_ctrl = `ALU_ADD;
                `JAL:    alu_ctrl = `ALU_ADD;
                `JALR:   alu_ctrl = `ALU_ADD;
                `ECALL:  alu_ctrl = `ALU_BEQ;
                default: alu_ctrl = 4'b0;
            endcase
        end
    endcase
end

endmodule