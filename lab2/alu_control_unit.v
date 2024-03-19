`include "opcodes.v"
`include "alu_func.v"

module alu_control_unit(
    input [10:0] part_of_inst,
    output [3:0] alu_op,
    output [1:0] btype
);

wire funct7;
wire [2:0]funct3;
wire [6:0]opcode;

assign funct7 = part_of_inst[10];
assign funct3 = part_of_inst[9:7];
assign opcode = part_of_inst[6:0];

always @(*) begin
    case(opcode)
        `ARITHMETIC:
        `ARITHMETIC_IMM: begin
            case(func3)
                `FUNCT3_ADD: begin     // `FUNCT3_ADD == `FUNCT3_SUB == 3'b000
                    if(funct7) alu_op = `FUNC_SUB;
                    else alu_op = `FUNC_ADD;
                end
                `FUNCT3_SLL: begin
                    alu_op = `FUNC_LLS;
                end
                `FUNCT3_XOR: begin
                    alu_op = `FUNC_XOR;
                end
                `FUNCT3_OR: begin
                    alu_op = `FUNC_OR;
                end
                `FUNCT3_AND: begin
                    alu_op = `FUNC_AND;
                end
                `FUNCT3_SRL: begin
                    if(funct7) alu_op = `FUNC_ARS;
                    else alu_op = `FUNC_LRS;
                end
            endcase
        end
        `LOAD:
        `STORE:
        `JALR: begin
            alu_op = `FUNC_ADD;
        end
        `BRANCH: begin
            alu_op = `FUNC_SUB;
            case(funct3)
                `FUNCT3_BEQ: begin
                    btype = `BRANCH_EQ;
                end
                `FUNCT3_BNE begin
                    btype = `BRANCH_NE;
                end
                `FUNCT3_BLT begin
                    btype = `BRANCH_LT;
                end
                `FUNCT3_BGE begin
                    btype = `BRANCH_GE;
                end
            endcase
        end
        // `LUI: begin
        // end
        // `AUIPC: begin
        //     alu_op = `FUNC_ADD;
        // end
        `ECALL: begin
        end

    endcase
end

endmodule
