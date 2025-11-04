module Sbyte_control(
    input  wire       clk,
    input  wire       reset,
    input  wire       start_detect,
    input  wire       byte_done,
    input  wire [7:0] sda_data,
    input  wire       stop_detect,
    output reg  [6:0] rx_addr,
    output reg  [7:0] rx_data,
    output reg        rw_flag,
    output reg        data_valid,
    output reg        drive_ack,
    output reg        addr_match
);
    parameter [6:0] MY_ADDR = 7'h49;

    localparam IDLE       = 3'b000,
               GOT_START  = 3'b001,
               RECV_ADDR  = 3'b010,
               CHECK_MATCH= 3'b011,
               RECV_DATA  = 3'b100,
               RESP_ACK   = 3'b101;

    reg [2:0] state;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            rx_addr <= 7'b0;
            rx_data <= 8'b0;
            data_valid <= 1'b0;
            drive_ack <= 1'b0;
            rw_flag <= 1'b0;
            addr_match <= 1'b0;
        end else begin
            data_valid <= 1'b0;
            drive_ack <= 1'b0;
            case (state)
                IDLE: begin
                    if (start_detect)
                        state <= GOT_START;
                end

                GOT_START: begin
                    if (byte_done)
                        state <= RECV_ADDR;
                end

                RECV_ADDR: begin
                    rx_addr <= sda_data[7:1];
                    rw_flag <= sda_data[0];
                    state <= CHECK_MATCH;
                end

                CHECK_MATCH: begin
                    if (rx_addr == MY_ADDR) begin
                        addr_match <= 1'b1;
                        drive_ack <= 1'b1;
                        state <= RECV_DATA;
                    end else begin
                        addr_match <= 1'b0;
                        drive_ack <= 1'b0;
                        state <= IDLE;
                    end
                end

                RECV_DATA: begin
                    if (byte_done) begin
                        rx_data <= sda_data;
                        data_valid <= 1'b1;
                        drive_ack <= 1'b1;
                        state <= RESP_ACK;
                    end
                end

                RESP_ACK: begin
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase

            if (stop_detect)
                state <= IDLE;
        end
    end
endmodule
