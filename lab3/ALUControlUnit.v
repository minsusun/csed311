`include "ALUControlSignals.v"
`include "opcodes.v"

module ALUControlUnit(
    input [6:0] opcode,
    input [2:0] funct3,
    input [6:0] funct7,
    input [1:0] alu_op,
    output reg [3:0] alu_ctrl
);
    always @(*) begin
        case(alu_op)
        2'b00: alu_ctrl = `ADD;
        2'b01: alu_ctrl = `SUB;

        default: begin
            case(opcode)
            `BRANCH: begin
                case(funct3)
                3'b000:  alu_ctrl = `CEQ;
                3'b001:  alu_ctrl = `CNE;
                3'b100:  alu_ctrl = `CLT;
                3'b101:  alu_ctrl = `CGE;
                default: alu_ctrl = `ADD;
                endcase
            end

            `LOAD:  alu_ctrl = `ADD;
            `STORE: alu_ctrl = `ADD;

            default: begin
                if(opcode == `ARITHMETIC && funct7 == `FUNCT7_SUB)
                    alu_ctrl = `SUB;
                else begin
                    case(funct3)
                    3'b000:  alu_ctrl = `ADD;
                    3'b001:  alu_ctrl = `SLL;
                    3'b100:  alu_ctrl = `XOR;
                    3'b101:  alu_ctrl = `SRL;
                    3'b110:  alu_ctrl = `OR;
                    3'b111:  alu_ctrl = `AND;
                    default: alu_ctrl = `ADD;
                    endcase
                end
            end
            endcase
        end
        endcase
    end
endmodule
