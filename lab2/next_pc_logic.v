module next_pc_logic(
    input [31:0] current_pc,
    input [31:0] immediate,
    input [31:0] alu_result,
    input is_jal,
    input is_jalr,
    input branch,
    input alu_bcond,
    output reg [31:0] next_pc
);
    always @(*) begin
        if(is_jalr) begin
            next_pc = alu_result;
        end else begin
            if(branch && alu_bcond || is_jal)
                next_pc = current_pc + immediate;
            else
                next_pc = current_pc + 4;
        end
    end
endmodule
