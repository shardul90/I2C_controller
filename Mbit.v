module Mbit_control(
    input  wire       clk,
    input  wire       reset,
    input  wire       start_req,
    input  wire       send_req,
    input  wire       stop_req,
    input  wire [7:0] byte_in,
    input  wire       sda_in,
    output reg        sda_drive,
    output reg        sda_dir,
    output reg        scl_drive,
    output reg        done,
    output reg        busy,
    output reg        ack_sample
);
    localparam IDLE            = 4'd0,
               START_PULL_SDA = 4'd1,
               START_WAIT     = 4'd2,
               BIT_SETUP      = 4'd3,
               BIT_CLK_HIGH   = 4'd4,
               BIT_CLOCK_LOW  = 4'd5,
               ACK_SAMPLE     = 4'd7,
               STOP_RELEASE_SCL = 4'd9,
               STOP_RELEASE_SDA = 4'd10,
               FINISH         = 4'd11;

    reg [3:0] state;
    reg [7:0] shift;
    reg [2:0] bit_cnt;
    reg start_req_ff, send_req_ff, stop_req_ff;
    reg start_edge, send_edge, stop_edge;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            start_req_ff <= 1'b0;
            send_req_ff <= 1'b0;
            stop_req_ff <= 1'b0;
            start_edge <= 1'b0;
            send_edge <= 1'b0;
            stop_edge <= 1'b0;
        end else begin
            start_edge <= start_req & ~start_req_ff;
            send_edge  <= send_req  & ~send_req_ff;
            stop_edge  <= stop_req  & ~stop_req_ff;

            start_req_ff <= start_req;
            send_req_ff  <= send_req;
            stop_req_ff  <= stop_req;
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            busy <= 1'b0;
            done <= 1'b0;
            ack_sample <= 1'b1;
            sda_drive <= 1'b0;
            sda_dir <= 1'b0;
            scl_drive <= 1'b0;
            shift <= 8'h00;
            bit_cnt <= 3'd0;
        end else begin
            done <= 1'b0;
            case (state)
                IDLE: begin
                    busy <= 1'b0;
                    sda_drive <= 1'b0;
                    sda_dir <= 1'b0;
                    scl_drive <= 1'b0;
                    if (start_edge) begin
                        busy <= 1'b1;
                        state <= START_PULL_SDA;
                    end else if (send_edge) begin
                        busy <= 1'b1;
                        shift <= byte_in;
                        bit_cnt <= 3'd7;
                        state <= BIT_SETUP;
                    end else if (stop_edge) begin
                        busy <= 1'b1;
                        sda_drive <= 1'b1;
                        sda_dir <= 1'b1;
                        scl_drive <= 1'b1;
                        state <= STOP_RELEASE_SCL;
                    end
                end

                START_PULL_SDA: begin
                    sda_drive <= 1'b1; 
                    sda_dir <= 1'b1;
                    scl_drive <= 1'b0; 
                    state <= START_WAIT;
                end

                START_WAIT: begin
                    sda_drive <= 1'b1;
                    sda_dir <= 1'b1;
                    scl_drive <= 1'b0;
                    if (send_edge) begin
                        shift <= byte_in;
                        bit_cnt <= 3'd7;
                        state <= BIT_SETUP;
                    end else begin
                        done <= 1'b1;
                        busy <= 1'b0;
                        state <= IDLE;
                    end
                end

                BIT_SETUP: begin
                  
                    if (shift[bit_cnt]) begin
                        sda_dir <= 1'b0;   
                        sda_drive <= 1'b0;
                    end else begin
                        sda_dir <= 1'b1;  
                        sda_drive <= 1'b1;
                    end
                    scl_drive <= 1'b1; 
                    state <= BIT_CLK_HIGH;
                end

                BIT_CLK_HIGH: begin
                   
                    scl_drive <= 1'b0; 
                    state <= BIT_CLOCK_LOW;
                end

                BIT_CLOCK_LOW: begin
               
                    scl_drive <= 1'b1;  
                    if (bit_cnt == 0) begin
                        
                        sda_dir <= 1'b0;
                        sda_drive <= 1'b0;
                        state <= ACK_SAMPLE;
                    end else begin
                        bit_cnt <= bit_cnt - 1;
                        state <= BIT_SETUP;
                    end
                end

                ACK_SAMPLE: begin
                    
                    ack_sample <= sda_in;
                    state <= FINISH;
                end

                STOP_RELEASE_SCL: begin
                    scl_drive <= 1'b0;
                    sda_drive <= 1'b1;
                    sda_dir <= 1'b1;
                    state <= STOP_RELEASE_SDA;
                end

                STOP_RELEASE_SDA: begin
                    sda_drive <= 1'b0;
                    sda_dir <= 1'b0;
                    scl_drive <= 1'b0;
                    state <= FINISH;
                end

                FINISH: begin
                    done <= 1'b1;
                    busy <= 1'b0;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule
