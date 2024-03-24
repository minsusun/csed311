module instruction_memory #(parameter MEM_DEPTH = 1024) (input reset,
                                                         input clk,
                                                         input [31:0] addr,   // address of the instruction memory
                                                         output reg [31:0] dout); // instruction at addr
  integer i;
  // Instruction memory
  reg [31:0] mem[0:MEM_DEPTH - 1];
  // Do not touch imem_addr
  wire [9:0] imem_addr;
  assign imem_addr = addr[11:2];
  // Do not touch or use this wire
  wire _unused_ok = &{1'b0,
                  addr[31:12],
                  addr[1:0],
                  1'b0};

  // TODO
  // Asynchronously read instruction from the memory 
  // (use imem_addr to access memory)

  always @(*) begin
    dout = mem[imem_addr];
  end

  // Initialize instruction memory (do not touch except path)
  always @(posedge clk) begin
    if (reset) begin
      for (i = 0; i < MEM_DEPTH; i = i + 1)
        // DO NOT TOUCH COMMENT BELOW
        /* verilator lint_off BLKSEQ */
        mem[i] = 32'b0;
        /* verilator lint_on BLKSEQ */
        // DO NOT TOUCH COMMENT ABOVE

      // Provide path of the file including instructions with binary format
      
      // Where should this file placed in? The same directory with the source code file or cwd when executing testbench?
      // -> The absolute path of the memory file needed. If you want to use relative path, place it into the directory where
      // simulation is run (The directory where verilator command is executed).
      $readmemh("student_tb/lui_auipc_mem.txt", mem);
    end
  end

endmodule


