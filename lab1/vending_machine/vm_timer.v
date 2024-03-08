`include "vending_machine_def.v"

module vm_timer(
    clk,
    reset_n,
    i_input_coin,
    i_select_item,
    item_price,
    coin_value,
    current_total
);
    input clk;
    input reset_n;
    input [`kNumCoins - 1: 0] i_input_coin;
    input [`kNumItems - 1: 0] i_select_item;
    input [`kNumItems - 1: 0] o_available_item;
    output reg [31: 0] wait_time;

    // initialize values
    initial begin
        wait_time = 0;
    end

    always @(i_input_coin, i_select_item) begin
        if(i_input_coin != 0 || (i_select_item & o_available_item) != 0)
            wait_time = `kWaitTime;
    end

    always @(posedge clk) begin
        if(!reset_n)
            wait_time = 0;
        else if(wait_time)
            wait_time = wait_time - 1;
    end

endmodule