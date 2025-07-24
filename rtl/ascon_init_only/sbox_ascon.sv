`default_nettype none
`timescale 1ns / 1ps
//--------------------------------------------------------------------
// 5-bit × 4-column × 8-row programmable S-box
//--------------------------------------------------------------------
module sbox_ascon #(
    parameter int COL_W = 5,
    parameter int COLS  = 4,
    parameter int ROWS  = 8
)(
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  update_i, // write-enable (whole row)
    input  logic [4:0]            addr_i,   // [4:2]=row , [1:0]=col
    input  logic [COLS*COL_W-1:0] data_i,   // 20-bit row payload
    output logic [COL_W-1:0]      data_o
);

    // labels for readability
    typedef enum logic [2:0] {ROW0, ROW1, ROW2, ROW3, ROW4, ROW5, ROW6, ROW7} row_e;
    typedef enum logic [1:0] {COL0, COL1, COL2, COL3}                         col_e;

    // Storage: 8 rows × 20 bits
    logic [COLS*COL_W-1:0] sbox_lut [ROWS];

    // Synchronous reset / update
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            //TODO : remove this, set all rows to 0
            // default contents
            sbox_lut[0] <= 20'hA7D64;
            sbox_lut[1] <= 20'h126BA;
            sbox_lut[2] <= 20'h920BB;
            sbox_lut[3] <= 20'hE187D;
            sbox_lut[4] <= 20'h71E7E;
            sbox_lut[5] <= 20'hC45A0;
            sbox_lut[6] <= 20'hC8590;
            sbox_lut[7] <= 20'hBBD56;
        end
        else if (update_i) begin
            // write one row
            sbox_lut[addr_i[4:2]] <= data_i;
        end
    end

    // Combinational read
    always_comb begin
        row_e row_sel = row_e'(addr_i[4:2]);
        col_e col_sel = col_e'(addr_i[1:0]);

        // variable-part select :    [base +: width]
        data_o = sbox_lut[row_sel][col_sel*COL_W +: COL_W];
    end

endmodule

`default_nettype wire
