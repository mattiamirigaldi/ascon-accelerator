`include "sbox_ascon.sv"

module sub_layer_lut(
    input   logic           clk,
    input   logic           rst_n,
    input   logic           upd_sbox_i,
    input  logic [4:0]     sbox_addr_i,
    input   logic [20:0]    sbox_new_data_i,
    input   logic [63:0]    x0_i,
    input   logic [63:0]    x1_i,
    input   logic [63:0]    x2_i,
    input   logic [63:0]    x3_i,
    input   logic [63:0]    x4_i,
    output  logic [63:0]    x0_o,
    output  logic [63:0]    x1_o,
    output  logic [63:0]    x2_o,
    output  logic [63:0]    x3_o,
    output  logic [63:0]    x4_o
);

    genvar i;
    generate
        for (i = 0; i < 64; i++) begin
            sbox_ascon sbox_inst(
                .clk           (clk),
                .rst_n         (rst_n),
                .update_i      (upd_sbox_i),
                .addr_i        (upd_sbox_i ? sbox_addr_i :
                               {x0_i[i], x1_i[i], x2_i[i], x3_i[i], x4_i[i]}),
                .data_i        (sbox_new_data_i),
                .data_o        ({x0_o[i], x1_o[i], x2_o[i], x3_o[i], x4_o[i]})
            );
        end
    endgenerate
endmodule
