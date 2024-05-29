`include "CLOG2.v"

`define IDLE       2'b00
`define WRITE_WAIT 2'b01
`define READ_WAIT  2'b10

module Cache #(
  parameter LINE_SIZE = 16,
  parameter NUM_WAYS = 4
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
    output is_output_valid
);
  integer i, j;

  // Parameter definitions
  // Total size of the cache in bytes
  parameter CACHE_SIZE = 256; 

  // The number of entries in a set
  parameter NUM_SETS = (CACHE_SIZE / LINE_SIZE) / NUM_WAYS;

  // Size of the tag and line in bits
  parameter TAG_LEN = 32 - `CLOG2(CACHE_SIZE) + `CLOG2(NUM_WAYS);
  parameter OFFSET_LEN = 2;

  // Length of the index in set
  parameter INDEX_LEN = `CLOG2(NUM_SETS);
  parameter WAY_INDEX_LEN = `CLOG2(NUM_WAYS);

  // Maximum value that an entry of lru bank can have
  parameter [WAY_INDEX_LEN - 1: 0] MAX_LRU = NUM_WAYS[WAY_INDEX_LEN - 1: 0] - 1;

  // Wire declarations
  wire [TAG_LEN - 1: 0] tag;
  wire [INDEX_LEN - 1: 0] index;
  wire [OFFSET_LEN - 1: 0] offset;

  wire is_dmem_ready;
  wire is_dmem_output_valid;
  wire [LINE_SIZE * 8 - 1: 0] dmem_din;
  wire [LINE_SIZE * 8 - 1: 0] dmem_dout;

  // Reg declarations
  // You might need registers to keep the status.
  reg [1:0] state;
  reg [1:0] next_state;

  reg dmem_read;
  reg dmem_write;
  reg [31:0] dmem_addr;
  reg is_dmem_input_valid;

  reg valid[NUM_SETS - 1: 0][NUM_WAYS - 1: 0];
  reg dirty[NUM_SETS - 1: 0][NUM_WAYS - 1: 0];
  reg [TAG_LEN - 1: 0] tag_bank[NUM_SETS - 1: 0][NUM_WAYS - 1: 0];
  reg [LINE_SIZE * 8 - 1: 0] data_bank[NUM_SETS - 1: 0][NUM_WAYS - 1: 0];
  reg [WAY_INDEX_LEN - 1: 0] lru_bank[NUM_SETS - 1: 0][NUM_WAYS - 1: 0];
  reg [WAY_INDEX_LEN - 1: 0] lru;

  reg [WAY_INDEX_LEN - 1: 0] hit_way_index;
  reg [WAY_INDEX_LEN - 1: 0] write_way_index;
  reg hit_way_found;
  reg write_way_found;

  // Combinational logics
  assign tag = addr[31: 31 - (TAG_LEN - 1)];
  assign index = addr[31 - TAG_LEN: 31 - TAG_LEN - (INDEX_LEN - 1)];
  assign offset = addr[OFFSET_LEN + 1: 2];

  assign is_hit = hit_way_found;
  assign is_output_valid = is_hit;
  assign dout = data_bank[index][hit_way_index][32 * offset +: 32];

  assign dmem_din = data_bank[index][write_way_index];

  // Computes data memory address
  always @(*) begin
    if (dmem_write)
      dmem_addr = {tag_bank[index][write_way_index], index, 4'b0};
    else
      dmem_addr = {addr[31:4], 4'b0};
  end

  // Logic that finds the index of the way that hit
  always @(*) begin
    // Notice that hit_way_index may cause unexpected behaviour when used
    // without testing hit_way_found. Usually you may want to examine is_hit,
    // which essencially is just an alias for hit_way_found, before using
    // hit_way_index.
    hit_way_found = 0;
    hit_way_index = 0;

    for (i = 0; i < NUM_WAYS; i = i + 1) begin
      if (tag == tag_bank[index][i] && valid[index][i]) begin
        hit_way_index = i[WAY_INDEX_LEN - 1: 0]; 
        hit_way_found = 1;
      end   
    end
  end

  // Logic that finds the least recently used way in a set 
  always @(*) begin
    lru = 0;
    for (i = 0; i < NUM_WAYS; i = i + 1)
      lru = (lru_bank[index][i] == MAX_LRU) ? i[WAY_INDEX_LEN - 1: 0] : lru;
  end

  // Logic that finds the index of the way to write on
  always @(*) begin
    write_way_found = 0;
    write_way_index = 0;

    for (i = 0; i < NUM_WAYS; i = i + 1) begin
      if (!valid[index][i]) begin
        write_way_index = i[WAY_INDEX_LEN - 1: 0];
        write_way_found = 1;
      end
    end

    if (!write_way_found)
      write_way_index = lru;
  end

  // Compute outputs with respect to the current state
  always @(*) begin
    case(state)
    `IDLE: begin
      is_ready = 1;
      is_dmem_input_valid = 0;
      dmem_read = 0;
      dmem_write = 0;
    end

    `WRITE_WAIT: begin
      is_ready = 0;
      is_dmem_input_valid = is_dmem_ready;
      dmem_write = !is_dmem_output_valid;
      dmem_read = 0;
    end

    `READ_WAIT: begin
      is_ready = 0;
      is_dmem_input_valid = is_dmem_ready;
      dmem_write = 0;
      dmem_read = !is_dmem_output_valid;
    end

    default: begin
      is_ready = 0;
      is_dmem_input_valid = 0;
      dmem_write = 0;
      dmem_read = 0;
    end
    endcase
  end

  // Compute next state
  always @(*) begin
    case(state)
    `IDLE: begin
      if (is_input_valid && !is_hit)
        next_state = dirty[index][write_way_index] ? `WRITE_WAIT : `READ_WAIT;
      else
        next_state = `IDLE;
    end
    `WRITE_WAIT: next_state = is_dmem_ready ? `READ_WAIT : `WRITE_WAIT;
    `READ_WAIT: next_state = is_dmem_output_valid ? `IDLE : `READ_WAIT;
    default: next_state = `IDLE;
    endcase
  end

  // Sequential logics
  always @(posedge clk) begin
    if (reset) begin
      state <= `IDLE;

      for(i = 0; i < NUM_SETS; i = i + 1) begin
        for(j = 0; j < NUM_WAYS; j = j + 1) begin
          valid[i][j] <= 0;
          dirty[i][j] <= 0;
          tag_bank[i][j] <= 0;
          data_bank[i][j] <= 0;
          lru_bank[i][j] <= j[WAY_INDEX_LEN - 1: 0];
        end
      end

    end else begin
      state <= next_state;

      if (state == `IDLE && is_input_valid && is_hit && mem_rw) begin
        data_bank[index][hit_way_index][32 * offset +: 32] <= din;
        dirty[index][hit_way_index] <= 1;
      end 
      
      if (state == `READ_WAIT && is_dmem_output_valid) begin
        valid[index][write_way_index] <= 1;
        dirty[index][write_way_index] <= 0;
        tag_bank[index][write_way_index] <= tag;
        data_bank[index][write_way_index] <= dmem_dout;
      end

      if (state == `IDLE && is_input_valid && is_hit) begin
        for (i = 0; i < NUM_WAYS; i = i + 1) begin
          if (lru_bank[index][i] != MAX_LRU)
            lru_bank[index][i] <= lru_bank[index][i] + 1;
        end
        lru_bank[index][hit_way_index] <= 0;
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
