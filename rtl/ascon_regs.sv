module ascon_regs
  import reg_pkg::*;
  import ascon_reg_pkg::*;
  (
    input logic clk_i,
    input logic rst_n_i,
    input reg_req_t reg_req_i,
    output reg_rsp_t reg_rsp_o,
    // Status
    output logic start_o,
    input logic finished_i,
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
// START at bit 0 (wo), DONE at bit 1 (rc/hwo)

  always_comb begin
    // Kick-off pulse when SW writes 1 to START
    start_o = reg2hw.status.start.qe & reg2hw.status.start.q;

    // Latch DONE=1 when hardware finishes; SW read will auto-clear (rc)
    hw2reg.status.done.de = finished_i; // write-enable from HW
    hw2reg.status.done.d  = 1'b1;       // value HW writes
  end

  ////////////////////////////////
  //        ASCON State         //
  ////////////////////////////////
  always_comb begin
    // Read registers and provide the intial state to ASCON
    for (int i = 0; i < 10; i = i + 2) begin
      state_o[i>>1][31:0]  = reg2hw.state[i].q;
      state_o[i>>1][63:32] = reg2hw.state[i+1].q;
    end

    // Write ASCON processed state back to registers
    for (int i = 0; i < 10; i = i + 2) begin
      hw2reg.state[i].d   = state_i[i>>1][31:0];
      hw2reg.state[i+1].d = state_i[i>>1][63:32];
    end

    // Enable updates when ASCON has processed the state
    for (int i = 0; i < 10; i++) begin
      hw2reg.state[i].de = update_state_i;
    end
  end


endmodule : ascon_regs
