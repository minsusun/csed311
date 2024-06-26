// Do not submit this file.
module top(
    input reset,
    input clk,
    output is_halted,
    output [31:0] print_reg [0:31]
    // DEBUG
    , output [31:0] print_pc
    , output [31:0] print_mem[0:9]
    // DEBUG
);
    cpu cpu(
        .reset(reset), 
        .clk(clk),
        .is_halted(is_halted),
        .print_reg(print_reg)
        // DEBUG
        , .print_pc(print_pc)
        , .print_mem(print_mem)
        // DEBUG
    );

endmodule
