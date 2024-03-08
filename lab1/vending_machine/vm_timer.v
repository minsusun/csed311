`include "vending_machine_def.v"

module vm_timer(
    clk,
    reset_n,
    i_trigger_return,
    i_input_coin,
    i_select_item,
    o_available_item,
    wait_time
);
    input clk;
    input reset_n;
    input i_trigger_return;
    input [`kNumCoins - 1: 0] i_input_coin;
    input [`kNumItems - 1: 0] i_select_item;
    input [`kNumItems - 1: 0] o_available_item;
    output reg [31: 0] wait_time;

    reg trigger_flag;

    // initialize values
    initial begin
        wait_time = 0;
        trigger_flag = 0;
    end

    always @(posedge clk) begin
        if(!reset_n)
            wait_time <= 0;
        else if(!trigger_flag && i_trigger_return) begin
            trigger_flag <= 1;
            wait_time <= 3;
        end
        else if(i_input_coin != 0 || (i_select_item & o_available_item) != 0)
            wait_time <= `kWaitTime + 1;
        else if(wait_time != 0)
            wait_time <= wait_time - 1;
        else if(trigger_flag && wait_time == 0)
            trigger_flag <= 0;
    end

endmodule
