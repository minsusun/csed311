// The input and output ports are modified to get 32-bit value.
// Can this be problematic? Can input next_pc be odd number?
module pc(
    input reset,
    input clk,
    input [31:0] next_pc,
    output reg [31:0] current_pc
);
    always @(posedge clk) begin
        if (reset) begin
            current_pc <= 0;
        end else begin
            current_pc <= next_pc;
        end
    end
endmodule
