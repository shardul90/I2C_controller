module translator(
    input  wire [6:0] rx_addr,
    output reg  [6:0] mapped_addr
);
    always @(*) begin
        case (rx_addr)
            7'h49: mapped_addr = 7'h48;
            default: mapped_addr = rx_addr;
        endcase
    end
endmodule
