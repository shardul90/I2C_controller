`timescale 1ns/1ps
module tb_top;
    reg  sys_clk = 0;
    reg  reset_n = 0;
    reg  sel_dev  = 0;
    wire ext_sda_up;
    reg  ext_scl_up;
    tri  ext_sda_dev1;
    tri  ext_sda_dev2;
    wire ext_sda_dev1_en;
    wire ext_sda_dev2_en;

    reg tb_sda_up_drive_en;
    reg tb_sda_up_drive;
    reg tb_dev1_drive_en;
    reg tb_dev1_drive_val;
    reg tb_dev2_drive_en;
    reg tb_dev2_drive_val;

    assign ext_sda_up   = tb_sda_up_drive_en ? tb_sda_up_drive   : 1'bz;
    assign ext_sda_dev1 = tb_dev1_drive_en     ? tb_dev1_drive_val : 1'bz;
    assign ext_sda_dev2 = tb_dev2_drive_en     ? tb_dev2_drive_val : 1'bz;

    top dut (
        .sys_clk(sys_clk),
        .reset_n(reset_n),
        .sel_dev(sel_dev),
        .ext_sda_up(ext_sda_up),
        .ext_scl_up(ext_scl_up),
        .ext_sda_dev1(ext_sda_dev1),
        .ext_sda_dev2(ext_sda_dev2),
        .ext_sda_dev1_en(ext_sda_dev1_en),
        .ext_sda_dev2_en(ext_sda_dev2_en)
    );

    
    always #5 sys_clk = ~sys_clk;

    initial begin
        tb_sda_up_drive_en = 0; tb_sda_up_drive = 1'b1;
        ext_scl_up = 1'b1;
        tb_dev1_drive_en = 0; tb_dev1_drive_val = 1'b1;
        tb_dev2_drive_en = 0; tb_dev2_drive_val = 1'b1;
        sel_dev = 0;
    end

    task i2c_start;
    begin
        tb_sda_up_drive_en = 0;
        ext_scl_up = 1;
        @(posedge dut.clkgen.s_clk);
        tb_sda_up_drive_en = 1;
        tb_sda_up_drive = 1'b1;
        @(posedge dut.clkgen.s_clk);
        tb_sda_up_drive = 1'b0;
        @(posedge dut.clkgen.s_clk);
    end
    endtask

    task i2c_stop;
    begin
        tb_sda_up_drive_en = 1;
        tb_sda_up_drive = 1'b0;
        ext_scl_up = 1;
        @(posedge dut.clkgen.s_clk);
        tb_sda_up_drive = 1'b1;
        @(posedge dut.clkgen.s_clk);
        tb_sda_up_drive_en = 0;
        @(posedge dut.clkgen.s_clk);
    end
    endtask

    task i2c_write_byte(input [7:0] data);
        integer i;
    begin
        for (i = 7; i >= 0; i = i - 1) begin
            ext_scl_up = 0;
            tb_sda_up_drive_en = 1;
            tb_sda_up_drive = data[i];
            @(posedge dut.clkgen.s_clk);
            ext_scl_up = 1;
            @(posedge dut.clkgen.s_clk);
        end
        ext_scl_up = 0;
        tb_sda_up_drive_en = 0;
        @(posedge dut.clkgen.s_clk);
        ext_scl_up = 1;
        @(posedge dut.clkgen.s_clk);
        ext_scl_up = 0;
        @(posedge dut.clkgen.s_clk);
    end
    endtask

    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);

        reset_n = 0;
        #50;
        reset_n = 1;
        @(posedge sys_clk);

        $display("TB: Starting upstream write at time %0t", $time);

        i2c_start();
        i2c_write_byte({7'h49, 1'b0});
        i2c_write_byte(8'hAA);
        i2c_stop();

        repeat (200) @(posedge dut.clkgen.s_clk);

        $display("TB: ext_sda_dev1_en=%b ext_sda_dev2_en=%b at time %0t",
                 ext_sda_dev1_en, ext_sda_dev2_en, $time);

        #20;
        $display("TB: finished at time %0t", $time);
        $finish;
    end

endmodule
