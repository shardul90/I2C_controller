module clk_divider #(
    parameter integer DIV = 1000
)(
    input  wire sys_clk,
    input  wire reset_n,
    output reg  s_clk
);
    localparam integer DIV_BY_2 = DIV / 2;
    reg [31:0] counter;

    always @(posedge sys_clk or negedge reset_n) begin
        if (!reset_n) begin
            counter <= 0;
            s_clk <= 0;
        end else begin
            if (counter >= DIV_BY_2) begin
                s_clk <= ~s_clk;
                counter <= 0;
            end else begin
                counter <= counter + 1;
            end
        end
    end
endmodule
