`ifndef INCL_ASCONP
`define INCL_ASCONP

// Licensed under the Creative Commons 1.0 Universal License (CC0), see LICENSE
// for details.
//
// Author: Robert Primas (rprimas 'at' proton.me, https://rprimas.github.io)
//
// Implementation of the Ascon permutation (Ascon-p).
// Performs UROL rounds per clock cycle.

`include "config.sv"

module asconp_lut (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        upd_sbox,
    input  logic [20:0] sbox_new_data_i,
    input  logic [ 3:0] round_cnt,
    input  logic [63:0] x0_i,
    input  logic [63:0] x1_i,
    input  logic [63:0] x2_i,
    input  logic [63:0] x3_i,
    input  logic [63:0] x4_i,
    output logic [63:0] x0_o,
    output logic [63:0] x1_o,
    output logic [63:0] x2_o,
    output logic [63:0] x3_o,
    output logic [63:0] x4_o
);

  logic [UROL-1:0][63:0] x0_const_add, x0_aff2;
  logic [UROL-1:0][63:0] x1_const_add, x1_aff2;
  logic [UROL-1:0][63:0] x2_const_add, x2_aff2;
  logic [UROL-1:0][63:0] x3_const_add, x3_aff2;
  logic [UROL-1:0][63:0] x4_const_add, x4_aff2;
  logic [UROL : 0][63:0] x0, x1, x2, x3, x4;
  logic [UROL-1:0][3:0] t;

  assign x0[0] = x0_i;
  assign x1[0] = x1_i;
  assign x2[0] = x2_i;
  assign x3[0] = x3_i;
  assign x4[0] = x4_i;

  genvar i;
  generate
    for (i = 0; i < UROL; i++) begin : g_asconp

      // constant addition
      assign t[i] = (4'hC) - (round_cnt - i);
      assign x0_const_add[i] = x0[i];
      assign x1_const_add[i] = x1[i];
      assign x2_const_add[i] = x2[i] ^ {56'd0, (4'hF - t[i]), t[i]};
      assign x3_const_add[i] = x3[i];
      assign x4_const_add[i] = x4[i];

      sub_layer_lut sub_layer_inst(
          .clk     (clk),
          .rst_n   (rst_n),
          .upd_sbox(upd_sbox),
          .sbox_new_data_i(sbox_new_data_i),
          .x0_i   (x0_const_add),
          .x1_i   (x1_const_add),
          .x2_i   (x2_const_add),
          .x3_i   (x3_const_add),
          .x4_i   (x4_const_add),
          .x0_o   (x0_aff2),
          .x1_o   (x1_aff2),
          .x2_o   (x2_aff2),
          .x3_o   (x3_aff2),
          .x4_o   (x4_aff2)
        );

      // linear layer
      assign x0[i+1] = x0_aff2[i] ^ {x0_aff2[i][18:0], x0_aff2[i][63:19]} ^ {x0_aff2[i][27:0], x0_aff2[i][63:28]};
      assign x1[i+1] = x1_aff2[i] ^ {x1_aff2[i][60:0], x1_aff2[i][63:61]} ^ {x1_aff2[i][38:0], x1_aff2[i][63:39]};
      assign x2[i+1] = x2_aff2[i] ^ {x2_aff2[i][0:0], x2_aff2[i][63:01]} ^ {x2_aff2[i][05:0], x2_aff2[i][63:06]};
      assign x3[i+1] = x3_aff2[i] ^ {x3_aff2[i][9:0], x3_aff2[i][63:10]} ^ {x3_aff2[i][16:0], x3_aff2[i][63:17]};
      assign x4[i+1] = x4_aff2[i] ^ {x4_aff2[i][6:0], x4_aff2[i][63:07]} ^ {x4_aff2[i][40:0], x4_aff2[i][63:41]};
    end
  endgenerate

  assign x0_o = x0[UROL];
  assign x1_o = x1[UROL];
  assign x2_o = x2[UROL];
  assign x3_o = x3[UROL];
  assign x4_o = x4[UROL];

endmodule

`endif  // INCL_ASCONP
