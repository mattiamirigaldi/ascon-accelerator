module ascon_regs
  import reg_pkg::*;
  (
    input logic clk_i,
    input logic rst_n_i,
    input reg_req_t reg_req_i,
    output reg_rsp_t reg_rsp_o,
    // Status
    output logic start_o,
    output logic finished_i,
    // State
    input logic update_state_i,
    input logic [4:0][63:0] state_i,
    output logic [4:0][63:0] state_o
  );

  ascon_hw2reg_t hw2reg;
  ascon_reg2hw_t reg2hw;

  ascon_reg_top #(
      .reg_req_t(reg_req_t),
      .reg_rsp_t(reg_rsp_t)
  ) ascon_reg_top_i (
      .clk_i(clk_i),
      .rst_ni(rst_n_i),
      .reg_req_i(reg_req_i),
      .reg_rsp_o(reg_rsp_o),
      .reg2hw(reg2hw),
      .hw2reg(hw2reg),
      .devmode_i(1'b1)
  );

  ////////////////////////////////
  //       Status signals       //
  ////////////////////////////////

  always_comb begin
    start_o = reg2hw.status.q;
    hw2reg.start.d = 1'b1;
    hw2reg.start.de = finished_i;
  end

  ////////////////////////////////
  //        ASCON State         //
  ////////////////////////////////
  always_comb begin
    for (int i = 0; i < 10; i = i + 2) begin
      state_o[i>>1][31:0]  = reg2hw.state[i].q;
      state_o[i>>1][63:32] = reg2hw.state[i+1].q;
    end

    for (int i = 0; i < 10; i = i + 2) begin
      hw2reg.state[i].d   = state_o[i>>1][31:0];
      hw2reg.state[i+1].d = state_o[i>>1][63:32];
    end

    for (int i = 0; i < 10; i++) begin
      hw2reg.state[i].de = update_state_i;
    end
  end


endmodule : ascon_regs
