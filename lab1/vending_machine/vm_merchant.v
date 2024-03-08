`include "vending_machine_def.v"

module vm_merchant(
    i_trigger_return,
    i_input_coin,
    i_select_item,
    item_price,
    coin_value,
    current_total,
    wait_time,
    o_available_item,
    o_output_item,
    current_total_nxt,
    o_return_coin
);
    input i_trigger_return;
    input [`kNumCoins - 1: 0] i_input_coin;
    input [`kNumItems - 1: 0] i_select_item;
    input [31: 0] item_price[`kNumItems - 1: 0];
    input [31: 0] coin_value[`kNumCoins - 1: 0];
    input [`kTotalBits - 1: 0] current_total;
    input [31: 0] wait_time;
    output reg [`kNumItems - 1: 0] o_available_item;
    output reg [`kNumItems - 1: 0] o_output_item;
    output reg [`kTotalBits - 1: 0] current_total_nxt;
    output reg [`kNumCoins - 1: 0] o_return_coin;

    reg [`kTotalBits - 1: 0] input_total;
    reg [`kTotalBits - 1: 0] output_total;
    reg [`kTotalBits - 1: 0] return_total;

    integer i;

    // input_total
    always @(*) begin
        input_total = 0;
        for(i = 0; i < `kNumCoins; i = i + 1) begin
            if(i_input_coin[i])
                input_total = input_total + coin_value[i];
        end
    end

    // o_return_coin, return_total
    always @(*) begin
        o_return_coin = 0;
        return_total = 0;
        if(i_trigger_return || wait_time == 0) begin
            for(i = 0; i < `kNumCoins; i = i + 1) begin
                if(current_total - return_total >= coin_value[i]) begin
                    o_return_coin[i] = 1;
                    return_total = return_total + coin_value[i];
                end
            end
        end
    end

    // o_available_item, o_output_item, output_value
    always @(*) begin
        o_available_item = 0;
        o_output_item = 0;
        output_total = 0;
        for(i = 0; i < `kNumItems; i = i + 1) begin
            if(item_price[i] <= current_total) o_available_item[i] = 1;
            if(i_select_item[i] && o_available_item[i]) begin
                o_output_item[i] = 1;
                output_total = output_total + item_price[i];
            end
        end
    end

    // current_total_nxt
    always @(*) begin
        current_total_nxt = current_total + input_total - output_total - return_total;
    end

endmodule
