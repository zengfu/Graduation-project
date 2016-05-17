`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2016/03/30 14:53:11
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top(

input clk_100,
input rst,
output sclk,
inout sdat,
output led,
output clk_24,
input pclk,
input [7:0]dvp,
input href,
input vsync,
output reset,
output pwdn,
output [3:0]r,g,b,
output vs,hs
    );
    
wire clk_25,clk_24,clk_10;
wire rst_n;

assign rst_n=~rst;
assign reset=1'b1;
assign pwdn=1'b0;

 
 clk_wiz_0 clk
      (
      // Clock in ports
       .clk_in1(clk_100),      // input clk_in1
       // Clock out ports
       .clk_out1(clk_24),     // output clk_out1
       .clk_out2(clk_25),     // output clk_out2
       .clk_out3(clk_10),
       // Status and control signals
       .reset(), // input reset
       .locked());      // output locked
       
 reg_config	reg_config_inst(
           .clk_25M                 (clk_25),
           .camera_rstn             (rst_n),
           .initial_en              (1'b1),        
           .i2c_sclk                (sclk),
           .i2c_sdat                (sdat),
           .reg_conf_done           (led),
           .strobe_flash            (),
           .reg_index               (),
           .clock_20k               (),
           .key1                    ()
       );   
          
wire [23:0] odata,p;
wire [11:0] x;
wire [10:0] y;
wire opclk,ohsync,ovsync,dv;
wire we;
wire [15:0]DATA;
OV_CAPTURE  OV_CAPTURE(
           .OV_PCLK(pclk),       // PIXEL CLK
           .RST(rst),
           .CLK_24(clk_24),
           .OV_XCLK(),      // 24M
           .OV_DVP(dvp),  // Digital　vedio port
           .OV_HREF(href),      //  Data VALID
           .OV_VSYNC(vsync),      // Vertical
           .HSYNC(ohsync),        // hsync output  active high  for axi4_stream_video in 
           .VSYNC(ovsync),        // vsync output  active high   for axi4_stream_video in 
           .DV(dv),           // data valid  active high    for axi4_stream_video in 
           .PCLK(opclk),         // output pixel clk
           .PIXEL(odata),    // output pixel data 
           .X_Cont(x),
           .Y_Cont(y),
           .P_Cont(p),
           .we(we),
           .DATA(DATA)
           );  
                
//ila_0 ila (
//               .clk(clk_24), // input wire clk
           
           
//               .probe0(p), // input wire [23:0]  probe0  
//               .probe1(x), // input wire [11:0]  probe1 
//               .probe2(y), // input wire [10:0]  probe2 
//               .probe3(we), // input wire [0:0]  probe3 
//               .probe4(ovsync), // input wire [0:0]  probe4 
//               .probe5(dv), // input wire [0:0]  probe5 
//               .probe6(ohsync), // input wire [0:0]  probe6 
//               .probe7(pclk) // input wire [0:0]  probe7
//           );
wire[16:0] frame_addr;
wire [15:0] frame_pixel;
wire [3:0] bank;          
blk_mem_gen_0 ram (
             .clka(opclk),    // input wire clka
             .ena(1'b1),      // input wire ena
             .wea(1'b1),      // input wire [0 : 0] wea
             .addra(p[16:0]),  // input wire [16 : 0] addra
             .dina(DATA),    // input wire [15 : 0] dina
             .clkb(clk_25),    // input wire clkb
             .enb(1'b1),      // input wire enb
             .addrb(frame_addr),  // input wire [16 : 0] addrb
             .doutb(frame_pixel)  // output wire [15 : 0] doutb
           );

vga vga(
    .clk25(clk_25),
    .vga_red(r),
    .vga_green(g),
    .vga_blue(b),
    .vga_hsync(hs),
    .vga_vsync(vs),
    .HCnt(),
    .VCnt(),

    .frame_addr(frame_addr),
    .frame_pixel(frame_pixel)
    );
//vga vga(
//    .aclk(clk_25),
//    .rst(rst),
//    .vga_red(r),
//    .vga_green(g),
//    .vga_blue(b),
//    .vs(vs),
//    .hs(hs),
//    .addr(frame_addr),
//    .idata(frame_pixel),
//    .bank(bank),
//    .vCnt(),
//    .hCnt()
//); 
    
endmodule
