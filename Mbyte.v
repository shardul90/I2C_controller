module Mbyte_control (
    input  wire       clk,
    input  wire       reset,
    input  wire       start_gen,
    input  wire [6:0] tx_addr,
    input  wire [7:0] tx_data,
    input  wire       rw_flag,
    output reg        bit_start,
    output reg        bit_send,
    output reg        bit_stop,
    output reg  [7:0] byte_out,
    input  wire       bit_done,
    input  wire       bit_ack,
    output reg        data_ready
);
    localparam IDLE      = 4'b0000,
               LOAD      = 4'b0001,
               GEN_START = 4'b0010,
               SEND_ADDR = 4'b0011,
               WAIT_ADDR = 4'b0100,
               SEND_DATA = 4'b0101,
               WAIT_DATA = 4'b0110,
               CHECK_ACK = 4'b0111,
               GEN_STOP  = 4'b1000,
               FINISH    = 4'b1001;

    reg [3:0] st;
    reg [6:0] tx_addr_r;
    reg [7:0] tx_data_r;
    reg       rw_r;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            st <= IDLE;
            bit_start <= 0; bit_send <= 0; bit_stop <= 0;
            byte_out <= 8'b0;
            data_ready <= 0;
            tx_addr_r <= 7'b0; tx_data_r <= 8'b0; rw_r <= 1'b0;
        end else begin
            bit_start <= 0; bit_send <= 0; bit_stop <= 0; data_ready <= 0;
            case (st)
                IDLE: if (start_gen) st <= LOAD;
                LOAD: begin
                    tx_addr_r <= tx_addr;
                    tx_data_r <= tx_data;
                    rw_r <= rw_flag;
                    st <= GEN_START;
                end
                GEN_START: begin
                    bit_start <= 1;
                    st <= SEND_ADDR;
                end
                SEND_ADDR: begin
                    byte_out <= {tx_addr_r, rw_r};
                    bit_send <= 1;
                    st <= WAIT_ADDR;
                end
                WAIT_ADDR: begin
                    if (bit_done) st <= CHECK_ACK;
                end
                SEND_DATA: begin
                    byte_out <= tx_data_r;
                    bit_send <= 1;
                    st <= WAIT_DATA;
                end
                WAIT_DATA: begin
                    if (bit_done) st <= CHECK_ACK;
                end
                CHECK_ACK: begin
                    if (!bit_ack && rw_r == 1'b0)
                        st <= SEND_DATA;
                    else
                        st <= GEN_STOP;
                end
                GEN_STOP: begin
                    bit_stop <= 1;
                    st <= FINISH;
                end
                FINISH: begin
                    data_ready <= 1;
                    st <= IDLE;
                end
                default: st <= IDLE;
            endcase
        end
    end
endmodule
