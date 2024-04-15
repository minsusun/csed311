module PC(
    input reset,
    input clk,
    input pc_update,
    input [31:0] next_pc,
    output reg [31:0] current_pc
);
    always @(posedge clk) begin
        if(reset) 
            current_pc <= 0;
        else if(pc_update) 
            current_pc <= next_pc;
        else 
            current_pc <= current_pc;
    end
endmodule
