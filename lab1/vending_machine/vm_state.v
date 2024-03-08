`include "vending_machine_def.v"

module vm_state(
	clk,
	reset_n,
	current_total_nxt,
	current_total
);
	input clk;
	input reset_n;
	input [`kTotalBits - 1: 0] current_total_nxt;
	output reg [`kTotalBits - 1: 0] current_total;
	
	always @(posedge clk) begin
		if (!reset_n)
			current_total <= 0;
		else
			current_total <= current_total_nxt;
	end
endmodule 
