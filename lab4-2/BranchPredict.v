/*** 2-bit Saturated Branch Predictor ***/

`define BP_ST 0     // Branch Prediction Strongly Taken
`define BP_WT 1     // Branch Prediction Weakly Taken
`define BP_WN 2     // Branch Prediction Weakly Not taken
`define BP_SN 3     // Branch Prediction Strongly Not taken

module BranchPredict(
    input reset,
    input clk,
    input is_branch,        // Is branch prediction needed ?
    input is_taken,         // Branch taken or not in real
    output prediction       // 1: Predict the branch to be taken, 0: Predict the branch not to be taken
);

reg [ 1: 0] state;

assign prediction = (state == `BP_ST || state == `BP_WT) ? 1 : 0;

always @(posedge clk) begin
    if (reset)
        state = `BP_ST;
    else if (is_branch) begin
        case(state)
            `BP_ST:
                state = is_taken ? `BP_ST : `BP_WT;
            `BP_WT:
                state = is_taken ? `BP_ST : `BP_WN;
            `BP_WN:
                state = is_taken ? `BP_WT : `BP_SN;
            `BP_SN:
                state = is_taken ? `BP_WN : `BP_SN;
            default:
                state = 0;
        endcase
    end
end

endmodule