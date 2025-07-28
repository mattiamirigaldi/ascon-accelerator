typedef logic [4:0][63:0] state_t;

module ascon_wrapper
    import reg_pkg::*;
    (
    input logic                    clk_i,
    input logic                    rst_n_i,
    // Register interface
    input reg_req_t                reg_req_i,
    output reg_rsp_t               reg_rsp_o,
    // Interrupt
    output logic                   intr_o
);

    logic start, finished, update_state;
    state_t input_state, ascon_state;

    ascon_init ascon_init_inst (
        .clk_i          (clk_i),
        .rst_n_i        (rst_n_i),
        // Register interface to Sbox
        .sbox_reg_req_i      (reg_req_i),
        .sbox_reg_rsp_o      (reg_rsp_o),
        // Status
        .start_i(start),
        .finished_o(finished),
        // State
        .state_i(input_state),
        .state_o(ascon_state),
        .update_state_o(update_state),
        // Interrupt
        .ascon_intr_o(intr_o)
    );

    ascon_regs ascon_regs_inst (
        .clk_i          (clk_i),
        .rst_n_i        (rst_n_i),
        // Register interface
        .reg_req_i      (reg_req_i),
        .reg_rsp_o      (reg_rsp_o),
        // Start
        .start_o(start),
        .finished_i(finished),
        // State
        .update_state_i(update_state),
        .state_i(input_state),
        .state_o(ascon_state)
    );

endmodule : ascon_wrapper
