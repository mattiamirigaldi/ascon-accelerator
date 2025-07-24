`include "asconp_lut.sv"

typedef logic [4:0][63:0] state_t;

module ascon_init (
    input  logic                    clk,
    input  logic                    rst_n,
    input  state_t                  state_i,
    input  logic                    start_i,
    input  logic                    upd_sbox_i,
    input  logic  [4:0]             sbox_addr_i,
    input  logic       [19:0]       sbox_new_data_i,
    output logic                    busy_o,
    output state_t                  state_o,
    output logic                    ascon_intr
);

typedef enum logic {IDLE, BUSY} fsm_t;

state_t state, asconp_o;
fsm_t   fsm;
logic   [3:0] round;
logic   [3:0] round_inc;

assign round_inc = round + 1;

// permutation ---------------------------------------------------------------
asconp_lut asconp_i (
    .clk   (clk),
    .rst_n (rst_n),
    .upd_sbox_i (upd_sbox_i),
    .sbox_addr_i (sbox_addr_i),
    .sbox_new_data_i (sbox_new_data_i),
    .round_cnt       (round),
    .x0_i (state[0]),
    .x1_i (state[1]),
    .x2_i (state[2]),
    .x3_i (state[3]),
    .x4_i (state[4]),
    .x0_o (asconp_o[0]),
    .x1_o (asconp_o[1]),
    .x2_o (asconp_o[2]),
    .x3_o (asconp_o[3]),
    .x4_o (asconp_o[4])
);

// main FSM ------------------------------------------------------------------
always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    fsm    <= IDLE;
    round  <= '0;
    state  <= '0;
    busy_o <= 1'b0;
    ascon_intr <= 1'b0;
  end else begin
    unique case (fsm)
      IDLE : begin
        busy_o <= 1'b0;
        ascon_intr <= 1'b0;
        if (start_i) begin
          fsm   <= BUSY;
          round <= '0;
          state <= state_i;
          busy_o<= 1'b1;
        end
      end

      BUSY : begin
        state <= asconp_o;
        round <= round_inc;
        busy_o<= 1'b1;
        if (round_inc == 4'd12) begin     // 12 rounds done
          fsm    <= IDLE;
          busy_o <= 1'b0;
          ascon_intr <= 1'b1;
        end
      end
    endcase
  end
end

assign state_o = state;   // valid when busy_o == 0

endmodule
