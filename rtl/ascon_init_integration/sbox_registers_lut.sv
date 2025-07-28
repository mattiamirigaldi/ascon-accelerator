module sbox_registers_lut (
    input logic clk_i,
    input logic rst_n_i,
    // Register interface
    input reg_req_t  sbox_reg_req_i,
    output reg_rsp_t sbox_reg_rsp_o,
    // SBox interface
    input logic [63:0][4:0] addr_i,
    output logic [63:0][4:0] data_o
);

  ascon_sbox_hw2reg_t hw2reg;
  ascon_sbox_reg2hw_t reg2hw;

  ascon_reg_top #(
      .reg_req_t(reg_req_t),
      .reg_rsp_t(reg_rsp_t)
  ) ascon_reg_top_i (
      .clk_i(clk_i),
      .rst_ni(rst_n_i),
      .reg_req_i(sbox_reg_req_i),
      .reg_rsp_o(sbox_reg_rsp_o),
      .reg2hw(reg2hw),
      .hw2reg(hw2reg),
      .devmode_i(1'b1)
  );

  logic [63:0][2:0] addr_sbox_row;
  logic [63:0][1:0] addr_sbox_col;

  ////////////////////////////////
  //         ASCON SBox         //
  ////////////////////////////////

  always_comb begin
    for (int i = 0; i < 63; i++) begin
      
      addr_sbox_row[i] = addr_i[i][4:2];
      addr_sbox_col[i] = addr_i[i][1:0];

      case (addr_sbox_col[i])
        2'b00:   data_o[i] = reg2hw.sbox[addr_sbox_row].entry_0;
        2'b01:   data_o[i] = reg2hw.sbox[addr_sbox_row].entry_1;
        2'b10:   data_o[i] = reg2hw.sbox[addr_sbox_row].entry_2;
        2'b11:   data_o[i] = reg2hw.sbox[addr_sbox_row].entry_3;
        default: data_o[i] = 6'b0;
      endcase

    end
  end

endmodule
