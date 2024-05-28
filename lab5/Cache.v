`include "CLOG2.v"

`define IDLE       2'b00
`define DMEM_WRITE 2'b01
`define DMEM_READ  2'b10

module Cache #(
  parameter LINE_SIZE = 16,
  parameter NUM_SETS = 4,
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
    output reg is_output_valid
);
  // for loop temporary variables
  integer i, j, k, l, m, n, o;

  // Parameter definitions
  parameter        NUM_INDEX_BITS = `CLOG2(NUM_SETS);
  parameter          NUM_WAY_BITS = `CLOG2(NUM_WAYS);
  parameter NUM_BLOCK_OFFSET_BITS = `CLOG2(LINE_SIZE);
  parameter          NUM_TAG_BITS = 32 - NUM_INDEX_BITS - NUM_BLOCK_OFFSET_BITS;
  parameter         NUM_WORD_BITS = 2 ** NUM_GRANULARITY_BITS * 8;
  parameter  NUM_GRANULARITY_BITS = 2;

  // Cache FSM Abstraction
  // : State < IDLE -> (DMEM_WRITE) -> DMEM_READ >
  reg [1:0] fsm_state;

  // Cache Internal Data Structure
  // lru_table: Evict Policy
  //            Each entry has number which indicates the time step since last reference
  //            Bigger number is less recently visited than smaller one
  //            Every time evict needed, the slot with biggest number(it should be NUM_WAYS-1) evicted
  //            Every time each set visited, every entry of LRU table increased by 1
  //            Entry for most recently visited one marked as 0, at the same time, all the entries moderated to be in (0, NUM_WAYS-1)
  //            Initial value of each entries in LRU table is NUM_WAY
  //            This is the reason each entires in LRU table is (NUM_WAY_BITS+1) bits total
  reg      [NUM_WAY_BITS: 0] lru_table [NUM_SETS - 1: 0][NUM_WAYS - 1: 0];
  reg  [NUM_TAG_BITS - 1: 0]  tag_bank [NUM_SETS - 1: 0][NUM_WAYS - 1: 0];
  reg                            valid [NUM_SETS - 1: 0][NUM_WAYS - 1: 0];
  reg [LINE_SIZE * 8 - 1: 0] data_bank [NUM_SETS - 1: 0][NUM_WAYS - 1: 0];
  reg                            dirty [NUM_SETS - 1: 0][NUM_WAYS - 1: 0];

  // Memory Address Abstraction
  // 31 ------------------------------------------ 0
  //   tag    |   index   |   offset   |   reserve
  //      (reserve: for word GRANULARITY bits)
  wire                                 [NUM_TAG_BITS - 1: 0]        tag = addr[31: 31 - (NUM_TAG_BITS - 1)];
  wire                               [NUM_INDEX_BITS - 1: 0]      index = addr[NUM_BLOCK_OFFSET_BITS +: NUM_INDEX_BITS];
  wire [NUM_BLOCK_OFFSET_BITS - NUM_GRANULARITY_BITS - 1: 0]     offset = addr[NUM_BLOCK_OFFSET_BITS - 1: NUM_GRANULARITY_BITS];
  // NOTICE: way_update, way_hit is (NUM_WAY_BITS+1) bits total to store NUM_WAYS as value to indicate below
  //         (1) way_update: indicates there is no empty slot to store data in the set on the first iteration
  //         (2) way_hit: indicates there is no slot which is cache-hit, so that cache needs to use new slot or evict one among current slots
  reg                                      [NUM_WAY_BITS: 0] way_update;    // which way to be updated
  reg                                      [NUM_WAY_BITS: 0]    way_hit;    // which way to be hit

  // Data Memory Wire
  wire                        is_dmem_ready;
  wire                        is_dmem_input_valid;
  wire                        is_dmem_output_valid;
  wire [LINE_SIZE * 8 - 1: 0] dmem_din;
  wire [LINE_SIZE * 8 - 1: 0] dmem_dout;
  wire                [31: 0] dmem_addr;
  wire                        dmem_read;
  wire                        dmem_write;

  // Cache Interface
  assign        is_ready = (fsm_state == `IDLE);
  assign          is_hit = (way_hit != NUM_WAYS);
  assign is_output_valid = is_hit;
  assign            dout = data_bank[index][way_hit[NUM_WAY_BITS - 1: 0]]
                                [NUM_WORD_BITS * offset +: NUM_WORD_BITS];

  // Data Memory Interface(Input)
  assign is_dmem_input_valid = (fsm_state != `IDLE) && is_dmem_ready;
  assign           dmem_read = (fsm_state == `DMEM_READ) && !is_dmem_output_valid;
  assign          dmem_write = (fsm_state == `DMEM_WRITE) && !is_dmem_output_valid;
  assign            dmem_din = data_bank[index][way_update[NUM_WAY_BITS - 1: 0]];
  assign           dmem_addr = dmem_write ?
                               {tag_bank[index][way_update[NUM_WAY_BITS - 1: 0]], index, {NUM_BLOCK_OFFSET_BITS{1'b0}}} : 
                               {addr[31: NUM_BLOCK_OFFSET_BITS], {NUM_BLOCK_OFFSET_BITS{1'b0}}};

  // Reset LRU, Tag, Valid, Data, Dirty on Reset
  always @(posedge clk) begin
    if (reset) begin
      for (i = 0; i < NUM_SETS; i += 1) begin
        for (j = 0; j < NUM_WAYS; j += 1) begin
          tag_bank[i][j]  <= 0;
          valid[i][j]     <= 0;
          data_bank[i][j] <= 0;
          dirty[i][j]     <= 0;
          lru_table[i][j] <= NUM_WAYS;
        end
      end
    end
  end

  // FSM
  always @(posedge clk) begin
    if (reset) begin
      fsm_state <= `IDLE;
    end
    else begin
      case (fsm_state)
        `IDLE: begin
          if (is_input_valid && !is_hit) begin
            if (dirty[index][way_update[NUM_WAY_BITS - 1: 0]])
              fsm_state <= `DMEM_WRITE;
            else
              fsm_state <= `DMEM_READ;
          end else
            fsm_state <= `IDLE;
        end

        `DMEM_WRITE: begin
          if (is_dmem_ready)
            fsm_state <= `DMEM_READ;
          else
            fsm_state <= `DMEM_WRITE;
        end
        
        `DMEM_READ: begin
          if (is_dmem_output_valid)
            fsm_state <= `IDLE;
          else
            fsm_state <= `DMEM_READ;
        end

        default:
          fsm_state <= `IDLE;
      endcase
    end
  end

  // Data transfer
  always @(posedge clk) begin
    if (fsm_state == `IDLE) begin
      if (is_input_valid && is_hit) begin
        // LRU table update
        for (o = 0; o < NUM_WAYS; o += 1) begin
          if (lru_table[index][o] < lru_table[index][way_hit[NUM_WAY_BITS - 1: 0]])
            lru_table[index][o] <= lru_table[index][o] + 1;
        end
        lru_table[index][way_hit[NUM_WAY_BITS - 1: 0]] <= 0;

        if (mem_rw) begin
          data_bank[index][way_hit[NUM_WAY_BITS - 1: 0]][NUM_WORD_BITS * offset +: NUM_WORD_BITS] <= din;
          dirty[index][way_hit[NUM_WAY_BITS - 1: 0]] <= 1;
        end
      end
    end
    else if(fsm_state == `DMEM_READ) begin
      if (is_dmem_output_valid) begin
        valid[index][way_update[NUM_WAY_BITS - 1: 0]]     <= 1;
        tag_bank[index][way_update[NUM_WAY_BITS - 1: 0]]  <= tag;
        data_bank[index][way_update[NUM_WAY_BITS - 1: 0]] <= dmem_dout;
        dirty[index][way_update[NUM_WAY_BITS - 1: 0]]     <= 0;
      end
    end
  end
  
  // allocate way_hit
  always @(*) begin
    way_hit = NUM_WAYS;
    for (l = 0; l < NUM_WAYS; l += 1) begin
      if(valid[index][l] && (tag_bank[index][l] == tag))
        way_hit = l[NUM_WAY_BITS: 0];
    end
  end

  // allocate way_update
  always @(*) begin
    way_update = NUM_WAYS;
    
    // find empty
    for (m = 0; m < NUM_WAYS; m += 1) begin
      if (!valid[index][m]) begin
        way_update = m[NUM_WAY_BITS: 0];
        break;
      end
    end

    // when no empty
    // should be evicted
    if (way_update == NUM_WAYS) begin
      for (n = 0; n < NUM_WAYS; n += 1) begin
        if (lru_table[index][n] == NUM_WAYS - 1) begin
          way_update = n[NUM_WAY_BITS: 0];
          break;
        end
      end
    end
  end

  // Instantiate data memory
  DataMemory #(.BLOCK_SIZE(LINE_SIZE)) data_mem(
    .reset(reset),
    .clk(clk),

    .is_input_valid(is_dmem_input_valid),
    .addr(dmem_addr >> NUM_BLOCK_OFFSET_BITS),  // NOTE: address must be shifted by CLOG2(LINE_SIZE)
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
