`include "opcodes.v"

`define IF    4'b0000 // Instruction Fetch
`define ID    4'b0001 // Instruction Decode
`define MAC   4'b0010 // Memory Adress Computation
`define EXR   4'b0011 // Execution R-type
`define EXI   4'b0100 // Execution I-type (except LOAD and JALR)
`define BC    4'b0101 // Branch Completion
`define JALC  4'b0110 // JAL Completion
`define JALRC 4'b0111 // JALR Completion
`define MR    4'b1000 // Memory Read
`define MW    4'b1001 // Memory Write
`define AC    4'b1010 // Arithmetic Completion (includes I-type arithmetics)
`define MRC   4'b1011 // Memory Read Completion
`define ED    4'b1100 // Ecall Detection

module ControlUnit(
    input [6:0] part_of_inst,
    input clk,
    input reset,
    output reg pc_write_cond,
    output reg pc_write,
    output reg i_or_d,
    output reg mem_read,
    output reg mem_write,
    output reg [1:0] reg_src,
    output reg ir_write,
    output reg pc_src,
    output reg [1:0] alu_op,
    output reg alu_src_a,
    output reg [1:0] alu_src_b,
    output reg reg_write,
    output reg is_ecall
);
    reg [3:0] state, next_state;
    wire [6:0] opcode = part_of_inst;

    assign is_ecall = (opcode == `ECALL);

    // Update microsequencer state synchronously.
    always @(posedge clk) begin
        if(reset)
            state <= `IF;
        else
            state <= next_state;
    end

    // Calculate the next state.
    always @(*) begin
        case(state)
        `IF: next_state = `ID;

        `ID: begin
            case(opcode)
            `ARITHMETIC:     next_state = `EXR;
            `ARITHMETIC_IMM: next_state = `EXI;
            `LOAD:           next_state = `MAC;
            `JALR:           next_state = `JALRC;
            `STORE:          next_state = `MAC;
            `BRANCH:         next_state = `BC;
            `JAL:            next_state = `JALC;
            `ECALL:          next_state = `ED;
            default:         next_state = state;
            endcase
        end

        `MAC: begin
            if(opcode == `LOAD)
                next_state = `MR;
            else if(opcode == `STORE)
                next_state = `MW;
            else
                next_state = state;
        end

        `EXR:    next_state = `AC;
        `EXI:    next_state = `AC;
        `BC:     next_state = `IF;
        `JALC:   next_state = `IF;
        `JALRC:  next_state = `IF;
        `MR:     next_state = `MRC;
        `MW:     next_state = `IF;
        `AC:     next_state = `IF;
        `MRC:    next_state = `IF;
        default: next_state = state;
        endcase
    end

    // Compute output signal with respect to the current state.
    always @(*) begin
        pc_write_cond = (state == `BC);
        pc_write      = (state == `IF) || (state == `JALC) || (state == `JALRC);
        i_or_d        = (state == `MR) || (state == `MW);
        mem_read      = (state == `IF) || (state == `MR);
        mem_write     = (state == `MW);

        reg_src = {
            (state == `JALC) || (state == `JALRC),
            (state == `MRC)
        };

        ir_write = (state == `IF);
        pc_src   = (state == `JALC) || (state == `BC);

        alu_op = {
            (state == `EXR) || (state == `EXI) || 
            (state == `ED)  || (state == `BC),
            1'b0
        };

        alu_src_a = (
            (state == `MAC) || (state == `EXR)   || (state == `EXI) || 
            (state == `BC)  || (state == `JALRC) || (state == `ED)
        );

        alu_src_b = {
            (state == `ID)    || (state == `EXI) || (state == `MAC) ||
            (state == `JALRC) || (state == `ED),
            (state == `IF)    || (state == `ED)
        };

        reg_write = (
            (state == `JALC) || (state == `JALRC) ||
            (state == `AC)   || (state == `MRC)
        );
    end
endmodule
