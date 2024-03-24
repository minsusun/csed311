`include "opcodes.v"

module immediate_generator(
    input [31:0] inst,
    output reg [31:0] imm_gen_out
);

always @(*) begin
    case(inst[6:0])
        // I-type
        `ARITHMETIC_IMM: begin
            imm_gen_out = {{20{inst[31]}}, inst[31:20]};
        end
        `LOAD: begin
            imm_gen_out = {{20{inst[31]}}, inst[31:20]};
        end
        `JALR: begin
            imm_gen_out = {{20{inst[31]}}, inst[31:20]};
        end

        // SB-type, B-type
        `BRANCH: begin
            imm_gen_out = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
        end

        // S-type
        `STORE: begin
            imm_gen_out = {{20{inst[31]}}, inst[31:25], inst[11:7]};
        end

        // UJ-type, J-type
        `JAL: begin
            imm_gen_out = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
        end

        default: begin
            imm_gen_out = 32'b0;
        end
    endcase
end

endmodule
