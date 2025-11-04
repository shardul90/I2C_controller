module bytc(
    input  wire       clk,
    input  wire       reset,
    input  wire       count_en,
    output reg  [2:0] count,
    output wire       done
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            count <= 3'b000;
        else if (count_en) begin
            if (count == 3'b111)
                count <= 3'b000;
            else
                count <= count + 1;
        end
    end

    assign done = (count == 3'b111);
endmodule
