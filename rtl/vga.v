
// A simple system-on-a-chip (SoC) for the MiST
// (c) 2015 Till Harbaum

// VGA controller generating 160x100 pixles. The VGA mode ised is 640x400
// combining every 4 row and column

// http://tinyvga.com/vga-timing/640x400@70Hz

module vga (
	// pixel clock
	input pclk,

	input reset,

	// VGA output
	output reg hs,
	output reg vs,
	output [7:0] vga_r,
	output [7:0] vga_g,
	output [7:0] vga_b,
	output VGA_DE,

	output reg hblank,
	output reg vblank,
	
	input [3:0] patt_select
);


wire [23:0] IRE_0   = {8'd000, 8'd000, 8'd000};
wire [23:0] IRE_10  = {8'd026, 8'd026, 8'd026};
wire [23:0] IRE_20  = {8'd051, 8'd051, 8'd051};
wire [23:0] IRE_30  = {8'd077, 8'd077, 8'd077};
wire [23:0] IRE_40  = {8'd102, 8'd102, 8'd102};
wire [23:0] IRE_50  = {8'd128, 8'd128, 8'd128};
wire [23:0] IRE_60  = {8'd153, 8'd153, 8'd153};
wire [23:0] IRE_70  = {8'd178, 8'd178, 8'd178};
wire [23:0] IRE_80  = {8'd204, 8'd204, 8'd204};
wire [23:0] IRE_90  = {8'd229, 8'd229, 8'd229};
wire [23:0] IRE_100 = {8'd255, 8'd255, 8'd255};

wire [23:0] RED_100 = {8'd255, 8'd000, 8'd000};
wire [23:0] GRN_100 = {8'd000, 8'd255, 8'd000};
wire [23:0] BLU_100 = {8'd000, 8'd000, 8'd255};
wire [23:0] WHT_100 = {8'd255, 8'd255, 8'd255};


wire [9:0] TOP_BAR_WIDTH  = (H/7);		// Top bars are 1/7 the width of the screen.
wire [9:0] TOP_BAR_HEIGHT = (V/3)*2;	// Top bars are 2/3 of the screen height.

wire [9:0] MIDDLE_BAR_V_START = TOP_BAR_HEIGHT+1;				// Middle bar starts 2/3 of the way down,
wire [9:0] MIDDLE_BAR_V_END   = MIDDLE_BAR_V_START+1+(V/12);	// and is about 1/12 of the screen height.

wire [9:0] LOWER_BLOCK_WIDTH = (TOP_BAR_WIDTH*5)/4;

wire [9:0] PLUGE_H_START = LOWER_BLOCK_WIDTH*4;
wire [9:0] PLUGE_BAR_WIDTH = (TOP_BAR_WIDTH/3);



// Top bars...
wire TOP_BAR_V = v_cnt>=0 && v_cnt<=TOP_BAR_HEIGHT;
wire WHT_BAR = h_cnt>=0					  && h_cnt<=TOP_BAR_WIDTH*1 && TOP_BAR_V;
wire YEL_BAR = h_cnt>=(TOP_BAR_WIDTH*1)+1 && h_cnt<=TOP_BAR_WIDTH*2 && TOP_BAR_V;
wire CYA_BAR = h_cnt>=(TOP_BAR_WIDTH*2)+1 && h_cnt<=TOP_BAR_WIDTH*3 && TOP_BAR_V;
wire GRN_BAR = h_cnt>=(TOP_BAR_WIDTH*3)+1 && h_cnt<=TOP_BAR_WIDTH*4 && TOP_BAR_V;
wire MAG_BAR = h_cnt>=(TOP_BAR_WIDTH*4)+1 && h_cnt<=TOP_BAR_WIDTH*5 && TOP_BAR_V;
wire RED_BAR = h_cnt>=(TOP_BAR_WIDTH*5)+1 && h_cnt<=TOP_BAR_WIDTH*6 && TOP_BAR_V;
wire BLU_BAR = h_cnt>=(TOP_BAR_WIDTH*6)+1 && h_cnt<=TOP_BAR_WIDTH*7 && TOP_BAR_V;

// Middle bar...
wire MID_BAR_V = v_cnt>=MIDDLE_BAR_V_START && v_cnt<=MIDDLE_BAR_V_END;
wire MID_BAR_BLU = h_cnt>=0					  && h_cnt<=TOP_BAR_WIDTH*1 && MID_BAR_V;
wire MID_BAR_MAG = h_cnt>=(TOP_BAR_WIDTH*2)+1 && h_cnt<=TOP_BAR_WIDTH*3 && MID_BAR_V;
wire MID_BAR_CYA = h_cnt>=(TOP_BAR_WIDTH*4)+1 && h_cnt<=TOP_BAR_WIDTH*5 && MID_BAR_V;
wire MID_BAR_WHT = h_cnt>=(TOP_BAR_WIDTH*6)+1 && h_cnt<=TOP_BAR_WIDTH*7 && MID_BAR_V;

// Lower, first four blocks...
wire LOW_BLU  = h_cnt>=0							  && h_cnt<=LOWER_BLOCK_WIDTH*1 && v_cnt>=MIDDLE_BAR_V_END+1 && v_cnt<=V;
wire LOW_WHT  = h_cnt>=(LOWER_BLOCK_WIDTH*1)+1 && h_cnt<=LOWER_BLOCK_WIDTH*2 && v_cnt>=MIDDLE_BAR_V_END+1 && v_cnt<=V;
wire LOW_PUR  = h_cnt>=(LOWER_BLOCK_WIDTH*2)+1 && h_cnt<=LOWER_BLOCK_WIDTH*3 && v_cnt>=MIDDLE_BAR_V_END+1 && v_cnt<=V;
//wire LOW_BLK1 = h_cnt>=(LOWER_BLOCK_WIDTH*3)+1 && h_cnt<=LOWER_BLOCK_WIDTH*4 && v_cnt>=MIDDLE_BAR_V_END+1 && v_cnt<=V;

// PLUGE...
wire LOW_DAR  = h_cnt>=PLUGE_H_START							  && h_cnt<=PLUGE_H_START+(PLUGE_BAR_WIDTH*1) && v_cnt>=MIDDLE_BAR_V_END+1 && v_cnt<=V;
//wire LOW_BLK2 = h_cnt>=PLUGE_H_START+(PLUGE_BAR_WIDTH*1)+1 && h_cnt<=PLUGE_H_START+(PLUGE_BAR_WIDTH*2) && v_cnt>=MIDDLE_BAR_V_END+1 && v_cnt<=V;
wire LOW_LHT  = h_cnt>=PLUGE_H_START+(PLUGE_BAR_WIDTH*2)+1 && h_cnt<=PLUGE_H_START+(PLUGE_BAR_WIDTH*3) && v_cnt>=MIDDLE_BAR_V_END+1 && v_cnt<=V;
//wire LOW_BLK3 = h_cnt>=PLUGE_H_START+(PLUGE_BAR_WIDTH*3)+1 && h_cnt<=PLUGE_H_START+LOWER_BLOCK_WIDTH   && v_cnt>=MIDDLE_BAR_V_END+1 && v_cnt<=V;


// Not sure if the colour bars still have "9" for their "black" values? ElectronAsh.

						  // Top bars...
wire [23:0] SMPTE = (WHT_BAR) ? {8'd192, 8'd192, 8'd192} :
						  (YEL_BAR) ? {8'd192, 8'd192, 8'd009} :
						  (CYA_BAR) ? {8'd009, 8'd192, 8'd192} :
						  (GRN_BAR) ? {8'd009, 8'd192, 8'd009} :
						  (MAG_BAR) ? {8'd192, 8'd009, 8'd192} :
						  (RED_BAR) ? {8'd192, 8'd009, 8'd009} :
						  (BLU_BAR) ? {8'd009, 8'd009, 8'd192} :
						  
						  // Middle bars...
						  (MID_BAR_BLU) ? {8'd009, 8'd009, 8'd192} :	// Blue!
						  // Black.
						  (MID_BAR_MAG) ? {8'd192, 8'd009, 8'd192} :	// Magenta!
						  // Black.
						  (MID_BAR_CYA) ? {8'd009, 8'd192, 8'd192} :	// Cyan!
						  // Black.
						  (MID_BAR_WHT) ? {8'd192, 8'd192, 8'd192} :	// 75% White!
						  
						  // Lower four blocks...
						  (LOW_BLU)  ? {8'd009, 8'd033, 8'd076} :
						  (LOW_WHT)  ? {8'd255, 8'd255, 8'd255} : 
						  (LOW_PUR)  ? {8'd050, 8'd009, 8'd106} :
						  // Black.
							
						  // Pluge...
						  (LOW_DAR)  ? {8'd000, 8'd000, 8'd000} :	// Blacker-than-black (sync).
						  // Black.
						  (LOW_LHT)  ? {8'd029, 8'd029, 8'd029} :	// Just above black level (pedestal? I dunno).
						  
						  // Black.
											{8'd009, 8'd009, 8'd009};	// <- default is Black level!


reg [23:0] RGB_OUT;

always @(posedge pclk) begin

	RGB_OUT <= (patt_select==0) ? IRE_0 :
				  (patt_select==1) ? IRE_10 :
				  (patt_select==2) ? IRE_20 :
				  (patt_select==3) ? IRE_30 :
				  (patt_select==4) ? IRE_40 :
				  (patt_select==5) ? IRE_50 :
				  (patt_select==6) ? IRE_60 :
				  (patt_select==7) ? IRE_70 :
				  (patt_select==8) ? IRE_80 :
				  (patt_select==9) ? IRE_90 :
				  (patt_select==10) ? IRE_100 :
				  (patt_select==11) ? RED_100 :
				  (patt_select==12) ? GRN_100 :
				  (patt_select==13) ? BLU_100 :
				  (patt_select==14) ? WHT_100 :
											 SMPTE;

end

/*
(*keep*)wire [23:0] PATT_RGB;
(*keep*)wire PATT_DE;
(*keep*)wire PATT_HS_N;
(*keep*)wire PATT_VS_N;
(*keep*)wire [11:0] h_cnt;
(*keep*)wire [11:0] v_cnt;
top_sync_vg_pattern top_sync_vg_pattern_inst
(
	.clk_27m( pclk ) ,				// input  clk_27m
//	.clk_74m( DRAM_CONT_CLK ) ,	// input  clk_74m
//	.clk_148m( CLK_148M ) ,			// input  clk_148m
	.resetb( !RESET ) ,				// input  resetb
	.adv7513_hs_n( PATT_HS_N ) ,	// output  adv7513_hs_n
	.adv7513_vs_n( PATT_VS_N ) ,	// output  adv7513_vs_n
	.adv7513_clk( PATT_CLK ) ,		// output  adv7513_clk
	.adv7513_d( PATT_RGB ) ,		// output [23:0] adv7513_d
	.adv7513_de( PATT_DE ) ,		// output  adv7513_de
	.x_out( h_cnt ) ,		// output [11:0] x_out
	.y_out( v_cnt ) 		// output [11:0] y_out
);
*/


// 640x400 70HZ VESA according to  http://tinyvga.com/vga-timing/640x400@70Hz
/*
parameter H   = 640;	// width of visible area
parameter HFP = 16;	// unused time before hsync
parameter HS  = 96;	// width of hsync
parameter HBP = 48;	// unused time after hsync

parameter V   = 400;	// height of visible area
parameter VFP = 12;	// unused time before vsync
parameter VS  = 2;	// width of vsync
parameter VBP = 35;	// unused time after vsync
*/

// 240p. 6.75 MHz pixel clock, NO pixel duplication...
parameter H   = 336;// width of visible area
parameter HFP = 27;	// unused time before hsync
parameter HS  = 10;	// width of hsync
parameter HBP = 55;	// unused time after hsync

parameter V   = 240;	// height of visible area
parameter VFP = 5;	// unused time before vsync
parameter VS  = 4;	// width of vsync
parameter VBP = 20;	// unused time after vsync


reg [11:0]  h_cnt;		// horizontal pixel counter
reg [11:0]  v_cnt;		// vertical pixel counter


// both counters count from the begin of the visibla area

// horizontal pixel counter
always@(posedge pclk) begin
	if(h_cnt==H+HFP+HS+HBP-1)   h_cnt <= 10'b0;
	else                        h_cnt <= h_cnt + 10'b1;

	// generate negative hsync signal
	if(h_cnt == H+HFP)    hs <= 1'b0;
	if(h_cnt == H+HFP+HS) hs <= 1'b1;
	hblank <= (h_cnt > H+HFP+HS);
end


// veritical pixel counter
always@(posedge pclk) begin
	// the vertical counter is processed at the begin of each hsync
	if(h_cnt == H+HFP) begin
		if(v_cnt==VS+VBP+V+VFP-1)  v_cnt <= 10'b0; 
		else							   v_cnt <= v_cnt + 10'b1;

	        // generate positive vsync signal
		if(v_cnt == V+VFP)    vs <= 1'b1;
		if(v_cnt == V+VFP+VS) vs <= 1'b0;
		vblank <= (v_cnt > V+VFP+VS);
	end
end

// read VRAM
reg [13:0] video_counter;
reg [7:0] pixel;
reg de;

always@(posedge pclk) begin
        // The video counter is being reset at the begin of each vsync.
        // Otherwise it's increased every fourth pixel in the visible area.
        // At the end of the first three of four lines the counter is
        // decreased by the total line length to display the same contents
        // for four lines so 100 different lines are displayed on the 400
        // VGA lines.

	// visible area?
	if((v_cnt < V) && (h_cnt < H)) begin
		if(h_cnt[1:0] == 2'b11)
			video_counter <= video_counter + 14'd1;
		
		pixel <= (v_cnt[2] ^ h_cnt[2])?8'h00:8'hff;    // checkboard
		de<=1;
	end else begin
		if(h_cnt == H+HFP) begin
			if(v_cnt == V+VFP)
				video_counter <= 14'd0;
			else if((v_cnt < V) && (v_cnt[1:0] != 2'b11))
				video_counter <= video_counter - 14'd160;
		de<=0;
		end
			
		pixel <= 8'h00;   // black
	end
end

// seperate 8 bits into three colors (332)
//assign vga_r = { pixel[7:5],  3'b00000 };
//assign vga_g = { pixel[4:2],  3'b00000 };
//assign vga_b = { pixel[1:0], 4'b000000 };


assign vga_r = RGB_OUT[23:16];
assign vga_g = RGB_OUT[15:8];
assign vga_b = RGB_OUT[7:0];

//assign hs = !PATT_HS_N;
//assign vs = !PATT_VS_N;
//assign VGA_DE = PATT_DE;

//assign VGA_DE  = ~(hblank | vblank);
assign VGA_DE = de;

endmodule
