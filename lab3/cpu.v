// TODO: Make 'ecall detecting unit'.

// Submit this file with other files you created.
// Do not touch port declarations of the module 'CPU'.

// Guidelines
// 1. It is highly recommened to `define opcodes and something useful.
// 2. You can modify the module.
// (e.g., port declarations, remove modules, define new modules, ...)
// 3. You might need to describe combinational logics to drive them into the module (e.g., mux, and, or, ...)
// 4. `include files if required

module cpu(
    input reset, // positive reset signal
    input clk, // clock signal
    output is_halted, // Whether to finish simulation
    output [31:0] print_reg[0:31]
);
    /***** Wire declarations *****/
    wire pc_update;
    wire [31:0] next_pc;
    wire [31:0] current_pc;
    wire [31:0] rd_din;
    wire [31:0] rs1_dout;
    wire [31:0] rs2_dout;
    wire [31:0] addr;
    wire [31:0] mem_dout;
    wire [31:0] immediate;
    wire [31:0] alu_in_a;
    wire [31:0] alu_in_b;
    wire [31:0] alu_result;
    wire alu_bcond;
    wire [3:0] alu_ctrl;
    wire [4:0] rs1;

    wire pc_write_cond;
    wire pc_write;
    wire i_or_d;
    wire mem_read;
    wire mem_write;
    wire [1:0] reg_src;
    wire ir_write;
    wire pc_src;
    wire [1:0] alu_op;
    wire alu_src_a;
    wire [1:0] alu_src_b;
    wire reg_write;
    wire is_ecall;

    /***** Register declarations *****/
    reg [31:0] IR/*verilator public*/; // instruction register
    reg [31:0] MDR; // memory data register
    reg [31:0] A; // Read 1 data register
    reg [31:0] B; // Read 2 data register
    reg [31:0] ALUOut; // ALU output register
    // Do not modify and use registers declared above.

    /***** Combinational logics *****/
    assign pc_update = (pc_write_cond && alu_bcond) || pc_write;
    assign rd_din = (reg_src[1]) ? current_pc : ((reg_src[0]) ? ALUOut : MDR);
    assign addr = i_or_d ? ALUOut : current_pc;
    assign alu_in_a = alu_src_a ? current_pc : A;
    assign next_pc = pc_src ? ALUOut : alu_result;

    assign alu_in_b = 
        (alu_src_b[1]) ? 
        ((alu_src_b[0]) ? 10 : immediate) : 
        ((alu_src_b[0]) ? 4 : B);
    
    assign rs1 = (is_ecall) ? 17 : IR[19:15];
    assign is_halted = is_ecall && alu_bcond;

    /***** Register update sequential logics *****/
    always @(posedge clk) begin
        if(reset) begin
            IR <= 32'b0;
            MDR <= 32'b0;
            A <= 32'b0;
            B <= 32'b0;
            ALUOut <= 32'b0;
        end else begin
            if(ir_write)
                IR <= mem_dout;
            MDR <= mem_dout;
            A <= rs1_dout;
            B <= rs2_dout;
            ALUOut <= alu_result;
        end
    end

    // ---------- Update program counter ----------
    // PC must be updated on the rising edge (positive edge) of the clock.
    PC pc(
        .reset(reset),
        .clk(clk),
        .pc_update(pc_update),
        .next_pc(next_pc),
        .current_pc(current_pc)
    );

    // ---------- Register File ----------
    RegisterFile reg_file(
        .reset(reset),  
        .clk(clk),       
        .rs1(rs1),
        .rs2(IR[24:20]),
        .rd(IR[11:7]),   
        .rd_din(rd_din), 
        .reg_write(reg_write), 
        .rs1_dout(rs1_dout), 
        .rs2_dout(rs2_dout), 
        .print_reg(print_reg) 
    );

    // ---------- Memory ----------
    Memory memory(
        .reset(reset),
        .clk(clk),
        .addr(addr),
        .din(B),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .dout(mem_dout)
    );

    // ---------- Control Unit ----------
    ControlUnit ctrl_unit(
        .part_of_inst(IR[6:0]),  // input
        .clk(clk),
        .reset(reset),
        .pc_write_cond(pc_write_cond),
        .pc_write(pc_write),
        .i_or_d(i_or_d),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .reg_src(reg_src),
        .ir_write(ir_write),
        .pc_src(pc_src),
        .alu_op(alu_op),
        .alu_src_a(alu_src_a),
        .alu_src_b(alu_src_b),
        .reg_write(reg_write),
        .is_ecall(is_ecall)
    );

    // ---------- Immediate Generator ----------
    ImmediateGenerator imm_gen(
        .inst(IR),
        .immediate(immediate)
    );

    // ---------- ALU Control Unit ----------
    ALUControlUnit alu_ctrl_unit(
        .opcode(IR[6:0]),
        .funct3(IR[14:12]),
        .funct7(IR[31:25]),
        .alu_op(alu_op),
        .alu_ctrl(alu_ctrl)
    );

    // ---------- ALU ----------
    ALU alu(
        .alu_ctrl(alu_ctrl),
        .alu_in_a(alu_in_a),
        .alu_in_b(alu_in_b),
        .alu_result(alu_result),
        .alu_bcond(alu_bcond)
    );
endmodule
