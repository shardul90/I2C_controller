`timescale 1ns/1ps


module top(
    input  wire        sys_clk,
    input  wire        reset_n,     
    input  wire        sel_dev,        
    inout  wire        ext_sda_up,     
    input  wire        ext_scl_up,     
    inout  wire        ext_sda_dev1,   
    inout  wire        ext_sda_dev2,   
    output wire        ext_sda_dev1_en,
    output wire        ext_sda_dev2_en
);
   
    wire reset = ~reset_n;

    
    wire i2c_clk;
    clk_divider clkgen (
        .sys_clk(sys_clk),
        .reset_n(reset_n),
        .s_clk(i2c_clk)
    );

    
    wire sda_up_i = ext_sda_up;
    wire scl_up_i = ext_scl_up;

  
    wire start_detected, stop_detected, shift_en, byte_done;
    wire [7:0] sda_shifted;

    Sbit_control slave_bit_ctl (
        .clk(i2c_clk),
        .reset(reset),
        .scl(scl_up_i),
        .sda(sda_up_i),
        .start_detect(start_detected),
        .stop_detect(stop_detected),
        .shift_en(shift_en)
    );

    shift_register slave_shiftreg (
        .clk(i2c_clk),
        .reset(reset),
        .shift_en(shift_en),
        .sda_in(sda_up_i),
        .d_out(sda_shifted)
    );

    bytc slave_byte_counter (
        .clk(i2c_clk),
        .reset(reset),
        .count_en(shift_en),
        .count(),         
        .done(byte_done)
    );

    
    wire [6:0] rx_addr;
    wire [7:0] rx_data;
    wire       rw_flag;
    wire       data_valid;
    wire       drive_ack_to_upstream;
    wire       addr_match;

    Sbyte_control slave_byte_fsm (
        .clk(i2c_clk),
        .reset(reset),
        .start_detect(start_detected),
        .byte_done(byte_done),
        .sda_data(sda_shifted),
        .stop_detect(stop_detected),
        .rx_addr(rx_addr),
        .rx_data(rx_data),
        .rw_flag(rw_flag),
        .data_valid(data_valid),
        .drive_ack(drive_ack_to_upstream),
        .addr_match(addr_match)
    );

    
    wire [6:0] mapped_addr;
    translator t_int (
        .rx_addr(rx_addr),
        .mapped_addr(mapped_addr)
    );

  
    wire        bit_start_req, bit_send_req, bit_stop_req;
    wire [7:0]  byte_out;
    wire        master_byte_done;
    wire        master_bit_ack;
    wire        data_ready;

    Mbyte_control Mbyte_fsm (
        .clk(i2c_clk),
        .reset(reset),
        .start_gen(data_valid),
        .tx_addr(mapped_addr),
        .tx_data(rx_data),
        .rw_flag(rw_flag),
        .bit_start(bit_start_req),
        .bit_send(bit_send_req),
        .bit_stop(bit_stop_req),
        .byte_out(byte_out),
        .bit_done(master_byte_done),
        .bit_ack(master_bit_ack),
        .data_ready(data_ready)
    );


    wire sda_dev1_i = ext_sda_dev1;
    wire sda_dev2_i = ext_sda_dev2;
    wire sda_down_i  = (sel_dev == 1'b0) ? sda_dev1_i : sda_dev2_i;

  
    wire m_sda_drive, m_sda_dir, m_scl_drive;
    wire mbc_busy, mbc_done, master_ack_sample;

    Mbit_control Mbit (
        .clk(i2c_clk),
        .reset(reset),
        .start_req(bit_start_req),
        .send_req(bit_send_req),
        .stop_req(bit_stop_req),
        .byte_in(byte_out),
        .sda_in(sda_down_i),
        .sda_drive(m_sda_drive),
        .sda_dir(m_sda_dir),
        .scl_drive(m_scl_drive),
        .done(mbc_done),
        .busy(mbc_busy),
        .ack_sample(master_ack_sample)
    );

    assign master_byte_done = mbc_done;
    assign master_bit_ack  = master_ack_sample;

    
    wire master_drive_dev1 = (sel_dev == 1'b0) && m_sda_dir && m_sda_drive;
    wire master_drive_dev2 = (sel_dev == 1'b1) && m_sda_dir && m_sda_drive;

    assign ext_sda_dev1     = (master_drive_dev1) ? 1'b0 : 1'bz;
    assign ext_sda_dev2     = (master_drive_dev2) ? 1'b0 : 1'bz;
    assign ext_sda_dev1_en  = master_drive_dev1;
    assign ext_sda_dev2_en  = master_drive_dev2;

endmodule
