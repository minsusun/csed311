`define IDLE       2'b00
`define WRITE_WAIT 2'b01
`define READ_WAIT  2'b10

module Cache #(
  parameter LINE_SIZE = 16,
  // ALERT: NUM_SETS AND NUM_WAYS MUST BE CHANGED WHEN IMPLEMENTING SET-ASSOCIATIVE CACHE!
  parameter NUM_SETS = 0,
  parameter NUM_WAYS = 0
) (
    input reset,
    input clk,

    input mem_rw,
    input is_input_valid,
    input [31:0] addr,
    input [31:0] din,

    output is_hit,
    output [31:0] dout,
    output reg is_ready,
    output reg is_output_valid
);
  integer i;

  // Parameter definitions
  parameter INDEX_LENGTH = 4;
  parameter BLOCK_OFFSET_LENGTH = 2;
  parameter GRANULARITY = 2;
  parameter TAG_LENGTH = 32 - INDEX_LENGTH - BLOCK_OFFSET_LENGTH - GRANULARITY;
  parameter ENTRY_NUMBER = 2 ** INDEX_LENGTH;
  parameter WORD_SIZE_IN_BITS = 2 ** GRANULARITY * 8;
  parameter LINE_SIZE_IN_BITS = LINE_SIZE * 8;

  // Wire declarations
  wire is_tag_match;

  wire [TAG_LENGTH - 1: 0] tag;
  wire [INDEX_LENGTH - 1: 0] index;
  wire [BLOCK_OFFSET_LENGTH - 1: 0] block_offset;

  wire is_dmem_ready;
  wire is_dmem_output_valid;
  wire [LINE_SIZE_IN_BITS - 1: 0] dmem_din;
  wire [LINE_SIZE_IN_BITS - 1: 0] dmem_dout;
  wire [31:0] dmem_addr;

  // Reg declarations
  // You might need registers to keep the status.
  reg [1:0] state;
  reg [1:0] next_state;

  reg dmem_read;
  reg dmem_write;
  reg is_dmem_input_valid;

  reg valid[ENTRY_NUMBER - 1: 0];
  reg dirty[ENTRY_NUMBER - 1: 0];
  reg [TAG_LENGTH - 1: 0] tag_bank[ENTRY_NUMBER - 1: 0];
  reg [LINE_SIZE_IN_BITS - 1: 0] data_bank[ENTRY_NUMBER - 1: 0];

  // Combinational logics
  assign tag = addr[31: 31 - (TAG_LENGTH - 1)];
  assign index = addr[32 - TAG_LENGTH: 32 - TAG_LENGTH - (INDEX_LENGTH - 1)];
  assign block_offset = addr[BLOCK_OFFSET_LENGTH + GRANULARITY - 1: GRANULARITY];

  assign is_tag_match = (tag_bank[index] == tag);
  assign is_hit = is_tag_match && valid[index];
  assign dout = 
    data_bank[index][WORD_SIZE_IN_BITS * block_offset +: WORD_SIZE_IN_BITS];

  assign dmem_din = data_bank[index];
  assign dmem_addr = {addr[31:4], 4'b0};

  // Compute outputs with respect to the current state
  always @(*) begin
    case(state)
    `IDLE: begin
      is_ready = 1;
      is_output_valid = 1;
      is_dmem_input_valid = 0;
    end

    `WRITE_WAIT: begin
      is_ready = 0;
      dmem_write = 1;
      is_dmem_input_valid = 1;
    end

    `READ_WAIT: begin
      is_ready = 0;
      dmem_read = 1;
      is_dmem_input_valid = 1;
    end

    default: begin
      is_ready = 1;
      is_output_valid = 1;
      is_dmem_input_valid = 0;
    end
    endcase
  end

  // Compute next state
  always @(*) begin
    case(state)
    `IDLE: begin
      if(is_input_valid && !is_hit && dirty[index])
        next_state = `WRITE_WAIT;
      else if(is_input_valid && !is_hit && !dirty[index])
        next_state = `READ_WAIT;
      else
        next_state = `IDLE;
    end 

    `WRITE_WAIT: begin
      if(is_dmem_ready && !mem_rw)
        next_state = `READ_WAIT;
      else if(is_dmem_ready && mem_rw)
        next_state = `IDLE;
      else
        next_state = `WRITE_WAIT;
    end

    `READ_WAIT: begin
      if(!is_output_valid)
        next_state = `READ_WAIT;
      else
        next_state = `IDLE;
    end

    default: next_state = `IDLE;
    endcase
  end

  // Sequential logics
  always @(posedge clk) begin
    if(reset) begin
      state <= `IDLE;

      for(i = 0; i < ENTRY_NUMBER; i = i + 1) begin
        valid[i] <= 1'b0;
        dirty[i] <= 1'b0;
        tag_bank[i] <= {TAG_LENGTH{1'b0}};
        data_bank[i] <= {LINE_SIZE_IN_BITS{1'b0}};
      end
    end else begin
      state <= next_state;
      if(is_dmem_output_valid && dmem_read) begin
        valid[index] <= 1'b1;
        dirty[index] <= 1'b0;
        tag_bank[index] <= tag;
        data_bank[index] <= dmem_dout;
      end else if(is_input_valid && is_hit && mem_rw) begin
        valid[index] <= 1'b1;
        dirty[index] <= 1'b1;
        data_bank[index][WORD_SIZE_IN_BITS * block_offset +: WORD_SIZE_IN_BITS]
          <= din;
      end
    end
  end

  // Instantiate data memory
  DataMemory #(.BLOCK_SIZE(LINE_SIZE)) data_mem(
    .reset(reset),
    .clk(clk),

    .is_input_valid(is_dmem_input_valid),
    .addr(dmem_addr),  // NOTE: address must be shifted by CLOG2(LINE_SIZE)
    .mem_read(dmem_read),
    .mem_write(dmem_write),
    .din(dmem_din),

    // is output from the data memory valid?
    .is_output_valid(is_dmem_output_valid),
    .dout(dmem_dout),
    // is data memory ready to accept request?
    .mem_ready(is_dmem_ready)
  );
endmodule
