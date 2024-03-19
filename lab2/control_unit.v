`include "opcodes.v"

module control_unit(
    input [6:0] part_of_inst,
    output is_jal,
    output is_jalr,
    output branch,
    output mem_read,
    output mem_to_reg,
    output mem_write,
    output [1:0] alu_src_1,
    output alu_src_2,
    output write_enable,
    output pc_to_reg,
    output is_ecall
);

assign is_jal = (part_of_inst == `JAL);
assign is_jalr = (part_of_inst == `JALR);
assign branch = (part_of_inst == `BRANCH);

assign mem_read = (part_of_inst == `LOAD);
assign mem_to_reg = (part_of_inst == `LOAD);
assign mem_write = (part_of_inst == `STORE);

assign alu_src_1 = 2'b00;
assign alu_src_2 = (part_of_inst != `STORE) && (part_of_inst != BRANCH);

assign write_enable = (part_of_inst != `STORE) && (part_of_inst != `BRANCH)
assign pc_to_reg = (part_of_inst == `JAL) || (part_of_inst == `JALR);

assign is_ecall = (part_of_inst == `ECALL);

endmodule
