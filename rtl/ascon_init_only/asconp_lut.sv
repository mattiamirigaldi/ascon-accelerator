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
`include "sub_layer_lut.sv"

module asconp_lut (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        upd_sbox_i,
    input  logic [4:0]  sbox_addr_i,
    input  logic [19:0] sbox_new_data_i,
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

  logic [63:0] x0_const_add, x0_aff2;
  logic [63:0] x1_const_add, x1_aff2;
  logic [63:0] x2_const_add, x2_aff2;
  logic [63:0] x3_const_add, x3_aff2;
  logic [63:0] x4_const_add, x4_aff2;
  logic [1:0][63:0] x0, x1, x2, x3, x4;
  logic [3:0] t;

  assign x0[0] = x0_i;
  assign x1[0] = x1_i;
  assign x2[0] = x2_i;
  assign x3[0] = x3_i;
  assign x4[0] = x4_i;

  // constant addition
  assign x0_const_add = x0[0];
  assign x1_const_add = x1[0];
  assign x2_const_add = x2[0] ^ (64'hf0 - (round_cnt * 1) * 64'h10 + (round_cnt * 1) * 64'h01);
  assign x3_const_add = x3[0];
  assign x4_const_add = x4[0];
  //#TODO : use the commented version also for the ascon python module
  //assign t = (4'hC) - (round_cnt - i);
  //assign x2_const_add = x2 ^ {56'd0, (4'hF - t), t};

  sub_layer_lut sub_layer_inst (
      .clk     (clk),
      .rst_n   (rst_n),
      .upd_sbox_i(upd_sbox_i),
      .sbox_addr_i(sbox_addr_i),
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
    assign x0[1] = x0_aff2 ^ {x0_aff2[18:0], x0_aff2[63:19]} ^ {x0_aff2[27:0], x0_aff2[63:28]};
    assign x1[1] = x1_aff2 ^ {x1_aff2[60:0], x1_aff2[63:61]} ^ {x1_aff2[38:0], x1_aff2[63:39]};
    assign x2[1] = x2_aff2 ^ {x2_aff2[0:0], x2_aff2[63:01]} ^ {x2_aff2[05:0], x2_aff2[63:06]};
    assign x3[1] = x3_aff2 ^ {x3_aff2[9:0], x3_aff2[63:10]} ^ {x3_aff2[16:0], x3_aff2[63:17]};
    assign x4[1] = x4_aff2 ^ {x4_aff2[6:0], x4_aff2[63:07]} ^ {x4_aff2[40:0], x4_aff2[63:41]};

  assign x0_o = x0[1];
  assign x1_o = x1[1];
  assign x2_o = x2[1];
  assign x3_o = x3[1];
  assign x4_o = x4[1];

endmodule

`endif  // INCL_ASCONP
