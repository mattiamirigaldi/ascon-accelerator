typedef logic [4:0][63:0] state_t;

module ascon_init (
    input  logic                 clk_i,
    input  logic                 rst_n_i,
    // Register interface to Sbox
    input  reg_req_t             sbox_reg_req_i,
    output reg_rsp_t             sbox_reg_rsp_o,
    // Status
    input  logic                 start_i,
    output logic                 finished_o,
    // State
    input  state_t               state_i,
    output state_t               state_o,
    output logic                 update_state_o,
    // Interrupt
    output logic                 ascon_intr_o
);

  typedef enum logic {
    IDLE,
    BUSY
  } fsm_t;
  state_t state, asconp_o;

  fsm_t fsm;
  logic [3:0] round;
  logic [3:0] round_inc;

  assign round_inc = round + 1;

  // permutation ---------------------------------------------------------------
  asconp_lut asconp_i (
      .clk_i      (clk_i),
      .rst_n_i    (rst_n_i),
      .sbox_reg_req_i  (sbox_reg_req_i),
      .sbox_reg_rsp_o  (sbox_reg_rsp_o),
      .round_cnt  (round),
      .x0_i       (state[0]),
      .x1_i       (state[1]),
      .x2_i       (state[2]),
      .x3_i       (state[3]),
      .x4_i       (state[4]),
      .x0_o       (asconp_o[0]),
      .x1_o       (asconp_o[1]),
      .x2_o       (asconp_o[2]),
      .x3_o       (asconp_o[3]),
      .x4_o       (asconp_o[4])
  );

  always_comb begin

    state_o = asconp_o;
    update_state_o = fsm == BUSY;

    if (fsm == IDLE) begin
      state = state_i;
    end else begin
      state = asconp_o;
    end
  end

  // main FSM ------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i) begin
      fsm    <= IDLE;
      round  <= '0;
      finished_o <= 1'b0;
    end else begin
      unique case (fsm)
        IDLE: begin
          finished_o <= 1'b0;
          if (start_i) begin
            fsm   <= BUSY;
            round <= '0;
          end
        end

        BUSY: begin
          round <= round_inc;
          finished_o <= 1'b0;
          if (round_inc == 4'd12) begin  // 12 rounds done
            fsm    <= IDLE;
            finished_o <= 1'b1;
          end
        end
      endcase
    end
  end

  assign ascon_intr_o = finished_o;

endmodule
