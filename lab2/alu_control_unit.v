`include "opcodes.v"
`include "alu_func.v"

module alu_control_unit(
    input [10:0] part_of_inst,
    output [6:0] alu_op
);

wire [3:0] atype;
wire [1:0] btype;
wire is_branch;

wire funct7;
wire [2:0]funct3;
wire [6:0]opcode;

assign funct7 = part_of_inst[10];
assign funct3 = part_of_inst[9:7];
assign opcode = part_of_inst[6:0];

assign alu_op = {is_branch, btype, atype};

always @(*) begin
    atype = 0;
    btype = 0;
    is_branch = 0;

    case(opcode)
        `ARITHMETIC:
        `ARITHMETIC_IMM: begin
            case(func3)
                `FUNCT3_ADD: begin     // `FUNCT3_ADD == `FUNCT3_SUB == 3'b000
                    if(funct7) atype = `FUNC_SUB;
                    else atype = `FUNC_ADD;
                end
                `FUNCT3_SLL: begin
                    atype = `FUNC_LLS;
                end
                `FUNCT3_XOR: begin
                    atype = `FUNC_XOR;
                end
                `FUNCT3_OR: begin
                    atype = `FUNC_OR;
                end
                `FUNCT3_AND: begin
                    atype = `FUNC_AND;
                end
                `FUNCT3_SRL: begin
                    if(funct7) atype = `FUNC_ARS;
                    else atype = `FUNC_LRS;
                end
            endcase
        end
        `LOAD:
        `STORE:
        `JALR: begin
            atype = `FUNC_ADD;
        end
        `BRANCH: begin
            atype = `FUNC_SUB;
            is_branch = 1;
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
