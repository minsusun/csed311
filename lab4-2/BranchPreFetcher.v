`include "opcodes.v"

module BranchPreFetcher(
    input [31: 0] i_register_a,
    input [31: 0] i_register_b,
    input [ 6: 0] opcode,
    input [ 2: 0] btype,
    output bcond
);

always @(*) begin
    case(opcode)
        `BRANCH: begin
            case(Btype)
                `FUNCT3_BEQ: bcond = i_register_a == i_register_b;
                `FUNCT3_BNE: bcond = i_register_a != i_register_b;
                `FUNCT3_BLT: bcond = i_register_a  < i_register_b;
                `FUNCT3_BGE: bcond = i_register_a >= i_register_b;
                default: bcond = 0;
            endcase
        end
        default: bcond = 0;
    endcase
end


endmodule