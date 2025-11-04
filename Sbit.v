module Sbit_control(
    input  wire clk,
    input  wire reset,
    input  wire sda,
    input  wire scl,
    output reg  start_detect,
    output reg  stop_detect,
    output reg  shift_en
);
    reg sda_prev;
    reg scl_prev;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sda_prev <= 1'b1;
            scl_prev <= 1'b1;
            start_detect <= 1'b0;
            stop_detect <= 1'b0;
            shift_en <= 1'b0;
        end else begin
            start_detect <= (scl == 1'b1 && sda_prev == 1'b1 && sda == 1'b0);
            stop_detect  <= (scl == 1'b1 && sda_prev == 1'b0 && sda == 1'b1);
            shift_en     <= (scl_prev == 1'b0 && scl == 1'b1);
            scl_prev <= scl;
            sda_prev <= sda;
        end
    end
endmodule
