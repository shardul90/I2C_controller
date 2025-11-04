module shift_register(
    input  wire       clk,
    input  wire       reset,
    input  wire       shift_en,
    input  wire       sda_in,
    output wire       sda_out,
    output wire [7:0] d_out
);
    reg [7:0] shift;

    always @(posedge clk or posedge reset) begin
        if (reset)
            shift <= 8'h00;
        else if (shift_en)
            shift <= {shift[6:0], sda_in};
    end

    assign d_out  = shift;
    assign sda_out = shift[7];
endmodule
