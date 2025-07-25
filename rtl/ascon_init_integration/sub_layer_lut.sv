`include "sbox_ascon.sv"

module sub_layer_lut (
    input  logic            clk_i,
    input  logic            rst_n_i,
    input  reg_req_t        reg_req_i,
    output reg_rsp_t        reg_rsp_o,
    input  logic     [63:0] x0_i,
    input  logic     [63:0] x1_i,
    input  logic     [63:0] x2_i,
    input  logic     [63:0] x3_i,
    input  logic     [63:0] x4_i,
    output logic     [63:0] x0_o,
    output logic     [63:0] x1_o,
    output logic     [63:0] x2_o,
    output logic     [63:0] x3_o,
    output logic     [63:0] x4_o
);

  logic [63:0][4:0] addr;
  logic [63:0][4:0] data;

  always_comb begin
    for (int i = 0; i < 64; i++) begin
      addr[i] = {x0_i[i], x1_i[i], x2_i[i], x3_i[i], x4_i[i]};
      x0_o[i] = data[i][4];
      x1_o[i] = data[i][3];
      x2_o[i] = data[i][2]; 
      x3_o[i] = data[i][1];
      x4_o[i] = data[i][0];
    end
  end

  sbox_registers_lut sbox_registers_lut_inst (
      .clk_i    (clk_i),
      .rst_n_i  (rst_n_i),
      .reg_req_i(reg_req_i),
      .reg_rsp_o(reg_rsp_o),
      .addr_i   (addr),
      .data_o   (data)
  );

endmodule
