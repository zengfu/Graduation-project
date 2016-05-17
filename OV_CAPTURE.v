module OV_CAPTURE(
    input OV_PCLK,       // PIXEL CLK
    input RST,
    input CLK_24,
    output OV_XCLK,      // 24M
    input [7:0] OV_DVP,  // Digital　vedio port
    input OV_HREF,      //  Data VALID
    input OV_VSYNC,      // Vertical
    output HSYNC,        // hsync output  active high  for axi4_stream_video in 
    output VSYNC,        // vsync output  active high   for axi4_stream_video in 
    output DV,           // data valid  active high    for axi4_stream_video in 
    output PCLK,         // output pixel clk
    output [23:0]PIXEL,    // output pixel data 
	output [11:0]X_Cont,
	output [10:0]Y_Cont,
	output [23:0]P_Cont,
	output we,
	output DATA
    //output OV_SCK,     // Driver the SCCB　
    //inout OV_SDA　　　 // Serial Data 
    );
reg PCLK;
reg [15:0] DATA;

reg dv1,dv2,dv3;
reg vsync1,vsync2;
always@(posedge OV_PCLK)
begin
	if(RST)
	begin
		dv1<=0;
		vsync1<=0;
		dv2<=0;
		dv3<=0;
		vsync2<=0;
	end
	else
	begin
		dv1<=OV_HREF;
		dv2<=dv1;
		dv3<=dv2;
		vsync1<=OV_VSYNC;
		vsync2<=vsync1;
	end
end

assign OV_XCLK = CLK_24;  
assign VSYNC=vsync2; //active high
assign HSYNC=~dv2;//active hig
assign DV=dv2;//active high


//         ____________________________________
//VS______|                                    |____________   
//HS		    _______	 	     _______
//_____________|       |__...___|       |___________________


reg hrr,hfr;      // hsync falling register

always@(posedge OV_PCLK)
begin
	if(RST)
		hfr <= 0;
	else
		hfr<= DV;		
end                                                                                                                       
wire	hff = ({hfr,DV} == 2'b10) ? 1'b1 : 1'b0;	//falling edge replace the frame end








//Change the sensor data from 8 bits to 16 bits. raw rgb is useless
reg			byte_state;		//byte state count
reg [7:0]  	ov_dh;      //ov input data half
always@(posedge OV_PCLK)
begin
	if(RST)
		begin
		byte_state <= 0;
		ov_dh <= 8'd0;
		DATA<= 16'd0;
		end
	else
		begin
		if(OV_HREF)			//DV=OV_HREF
			begin
			byte_state <= byte_state + 1'b1;	//（RGB565 = {first_byte, second_byte}）
			case(byte_state)
			1'b0 :	ov_dh[7:0] <= OV_DVP;
			1'b1 : 	DATA[15:0] <= {ov_dh[7:0], OV_DVP[7:0]}; //byte_state==1 replace the pixel is useful
			endcase
			end
		else
			begin
			byte_state <= 0;
			ov_dh <= 8'd0;
			DATA <= 16'b0;
			end
		end
end
assign PIXEL={DATA[15:11],3'b0,DATA[10:5],2'b0,DATA[4:0],3'b0};

reg		[11:0]	X_Cont;	//4098
reg		[10:0]	Y_Cont;	//2047
reg     [23:0]  P_Cont;
reg     we;

always@(posedge OV_PCLK)
begin
	if(RST)
		we <= 0;
	else if(P_Cont<17'h12c01)			//场信号有效
		we<=1;
	else
		we<=0;
end

always@(posedge OV_PCLK)
begin
	if(RST)
		P_Cont <= 0;
	else if(~VSYNC)			//场信号有效
		P_Cont <= (byte_state == 1'b1) ?  P_Cont + 1'b1 : P_Cont;
	else
		P_Cont <= 0;
end

always@(posedge OV_PCLK)
begin
	if(RST)
		X_Cont <= 0;
	else if(~VSYNC & OV_HREF)			//场信号有效
		X_Cont <= (byte_state == 1'b1) ?  X_Cont + 1'b1 : X_Cont;
	else
		X_Cont <= 0;
end

always@(posedge OV_PCLK )
begin
	if(RST)
		Y_Cont <= 0;
	else if(VSYNC == 1'b0) // among a frame
	begin
	   if(hff==1'b1)
		  Y_Cont <= Y_Cont + 1'b1;
	   else
	       Y_Cont <=Y_Cont;
	end
	else
		Y_Cont <= 0;
end


//-----------------------------------------------------
//sync the pixel clock
always@(posedge OV_PCLK)
begin
	if(RST)
		PCLK <= 0;
	else if(byte_state)  //make a rising edge
		PCLK <= ~PCLK;
	else
		PCLK <= 0;
end

endmodule