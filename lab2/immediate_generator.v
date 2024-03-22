`include "opcodes.v"

module immediate_generator(
    // Note the port name changed from original skeleton code.
    input [31:0] inst,
    output reg [31:0] imm_gen_out
);
    reg [6:0] opcode = inst[6:0];

    always @(*) begin
        case(opcode)
        `ARITHMETIC_IMM: imm_gen_out = {{20{inst[31]}}, inst[31:20]};
        `LOAD          : imm_gen_out = {{20{inst[31]}}, inst[31:20]};
        `STORE         : imm_gen_out = {{20{inst[31]}}, inst[31:25], inst[11:7]};
        `BRANCH        : imm_gen_out = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
        `JAL           : imm_gen_out = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
        // Is it okay to set default value into 0?
        default        : imm_gen_out = {32{1'b0}};
        endcase
    end
endmodule
