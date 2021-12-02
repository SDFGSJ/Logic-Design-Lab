module clock_divider #(parameter n=25)(
    input clk,
    output clk_div
);
    reg [n-1:0] num=0;
    wire [n-1:0] next_num;

    always @(posedge clk) begin
        num <= next_num;
    end
    assign next_num = num+1;
    assign clk_div = num[n-1];
endmodule

//maybe have pass as output
module mem_addr_gen2(
    input clk,
    input rst,
    input hold,
    inout PS2_CLK,
    inout PS2_DATA,
    input [9:0] h_cnt,
    input [9:0] v_cnt,
    output reg [16:0] pixel_addr,
    output ispass
);
    parameter [8:0] LEFT_SHIFT_CODES  = 9'b0_0001_0010;
	parameter [8:0] RIGHT_SHIFT_CODES = 9'b0_0101_1001;
	parameter [8:0] KEY_CODES [0:11] = {
		9'b0_0100_0100,	// o => 44
		9'b0_0100_1101,	// p => 4d
		9'b0_0101_0100,	// [ => 54
		9'b0_0101_1011,	// ] => 5b
		9'b0_0100_0010,	// k => 42
		9'b0_0100_1011,	// l => 4b
		9'b0_0100_1100,	// ; => 4c
		9'b0_0101_0010,	// ' => 52
		9'b0_0011_1010,	// m => 3a
		9'b0_0100_0001,	// , => 41
		9'b0_0100_1001, // . => 49
		9'b0_0100_1010 // / => 4a
	};

    wire [511:0] key_down;
    wire [8:0] last_change;
    wire key_valid;
	reg [3:0] key_num;

    wire shift_down;
    assign shift_down = (key_down[LEFT_SHIFT_CODES] == 1'b1 || key_down[RIGHT_SHIFT_CODES] == 1'b1) ? 1'b1 : 1'b0;

    KeyboardDecoder keydecode(
        .key_down(key_down),
        .last_change(last_change),
        .key_valid(key_valid),
        .PS2_DATA(PS2_DATA),
        .PS2_CLK(PS2_CLK),
        .rst(rst),
        .clk(clk)
    );
    
    integer i;
    reg [1:0] cnt[0:11];
    reg [1:0] cnt_next[0:11];
    reg [16:0] pixel_addr_next;
    reg done, done_next;

    always @(posedge clk,posedge rst) begin
        if(rst) begin
            cnt[0]<=1;cnt[1]<=1;cnt[2]<=1;cnt[3]<=1;
            cnt[4]<=1;cnt[5]<=1;cnt[6]<=1;cnt[7]<=1;
            cnt[8]<=0;cnt[9]<=0;cnt[10]<=0;cnt[11]<=0;
            done<=1;

            //1st row,all clockwise 90
            //formula:(Max-(h_cnt>>1))*320 + (min+(v_cnt>>1)). Max/min = max/min num of the horizontal range
            if(0 <= h_cnt>>1 && h_cnt>>1 < 80 && 0 <= v_cnt>>1 && v_cnt>>1 < 80) begin
                pixel_addr <= ( (80-(h_cnt>>1) )*320 + (v_cnt>>1) ) % 76800;
            end else if(80 <= h_cnt>>1 && h_cnt>>1 < 160 && 0 <= v_cnt>>1 && v_cnt>>1 < 80) begin
                pixel_addr <= ((160-(h_cnt>>1) )*320 + 80+(v_cnt>>1) )% 76800;
            end else if(160 <= h_cnt>>1 && h_cnt>>1 < 240 && 0 <= v_cnt>>1 && v_cnt>>1 < 80) begin
                pixel_addr <= ((240-(h_cnt>>1) )*320 + 160+(v_cnt>>1) )% 76800;
            end else if(240 <= h_cnt>>1 && h_cnt>>1 < 320 && 0 <= v_cnt>>1 && v_cnt>>1 < 80) begin
                pixel_addr <= ((320-(h_cnt>>1) )*320 + 240+(v_cnt>>1) )% 76800;

            //2nd row,all counter clockwise 90
            //formula:((h_cnt>>1)+80-min)*320 + (80+Max-(v_cnt>>1)) Max/min=max/min num of the horizontal range
            end else if(0 <= h_cnt>>1 && h_cnt>>1 < 80 && 80 <= v_cnt>>1 && v_cnt>>1 < 160) begin
                pixel_addr <= ( ((h_cnt>>1)+80-0)*320 + (80+80-(v_cnt>>1)) ) % 76800;
            end else if(80 <= h_cnt>>1 && h_cnt>>1 < 160 && 80 <= v_cnt>>1 && v_cnt>>1 < 160) begin
                pixel_addr <= ( ((h_cnt>>1)+80-80)*320 + (80+160-(v_cnt>>1)) ) % 76800;
            end else if(160 <= h_cnt>>1 && h_cnt>>1 < 240 && 80 <= v_cnt>>1 && v_cnt>>1 < 160) begin
                pixel_addr <= ( ((h_cnt>>1)+80-160)*320 + (80+240-(v_cnt>>1)) ) % 76800;
            end else if(240 <= h_cnt>>1 && h_cnt>>1 < 320 && 80 <= v_cnt>>1 && v_cnt>>1 < 160) begin
                pixel_addr <= ( ((h_cnt>>1)+80-240)*320 + (80+320-(v_cnt>>1)) ) % 76800;

            //3rd row
            end else if(0 <= h_cnt>>1 && h_cnt>>1 < 80 && 160 <= v_cnt>>1 && v_cnt>>1 < 240) begin
                pixel_addr <= ( (h_cnt>>1) + 320*(v_cnt>>1) )% 76800;  //640*480 --> 320*240 original
            end else if(80 <= h_cnt>>1 && h_cnt>>1 < 160 && 160 <= v_cnt>>1 && v_cnt>>1 < 240) begin
                pixel_addr <= ( (h_cnt>>1) + 320*(v_cnt>>1) )% 76800;  //640*480 --> 320*240 original
            end else if(160 <= h_cnt>>1 && h_cnt>>1 < 240 && 160 <= v_cnt>>1 && v_cnt>>1 < 240) begin
                pixel_addr <= ( (h_cnt>>1) + 320*(v_cnt>>1) )% 76800;  //640*480 --> 320*240 original
            end else if(240 <= h_cnt>>1 && h_cnt>>1 < 320 && 160 <= v_cnt>>1 && v_cnt>>1 < 240) begin
                pixel_addr <= ( (h_cnt>>1) + 320*(v_cnt>>1) )% 76800;  //640*480 --> 320*240 original
            end else begin
                pixel_addr <= ( (h_cnt>>1) + 320*(v_cnt>>1) )% 76800;  //640*480 --> 320*240 original
            end
        end else begin
            for(i=0;i<12;i=i+1) begin
                cnt[i]<=cnt_next[i];
            end
            done<=done_next;
            pixel_addr <= pixel_addr_next;
        end
    end


    always @(*) begin
        pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;
        if(hold || ispass) begin
            pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;
        end else begin
            if(key_valid && key_down[last_change]) begin
                if(key_num!=4'b1111) begin
                    if(!shift_down) begin
                        cnt_next[key_num]=cnt[key_num]+1;
                        if(key_num==4'b0000) begin  //o, m=0, M=79
                            if(cnt_next[key_num]==0) begin  //0
                                pixel_addr_next = ( 320*(79-(h_cnt>>1)) + (0+v_cnt>>1) )%76800; //90
                            end else if(cnt_next[key_num]==1) begin //90
                                pixel_addr_next = ( 320*(79-(v_cnt>>1)) + (0+79-(h_cnt>>1)) )%76800; //180
                            end else if(cnt_next[key_num]==2) begin //180
                                pixel_addr_next = ( 320*((h_cnt>>1)-0) + (79-(v_cnt>>1)) )%76800; //270
                            end else if(cnt_next[key_num]==3) begin //270
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;    //0
                            end else begin
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;
                            end
                        end else if(key_num==4'b0001) begin //p, m=80,  M=159
                            if(cnt_next[key_num]==0) begin  //0
                                pixel_addr_next = ( 320*(159-(h_cnt>>1)) + (80+(v_cnt>>1)) )%76800; //90
                            end else if(cnt_next[key_num]==1) begin //90
                                pixel_addr_next = ( 320*(79-(v_cnt>>1)) + (80+159-(h_cnt>>1)) )%76800; //180
                            end else if(cnt_next[key_num]==2) begin //180
                                pixel_addr_next = ( 320*((h_cnt>>1)-80) + (159-(v_cnt>>1)) )%76800; //270
                            end else if(cnt_next[key_num]==3) begin //270
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;    //0
                            end else begin
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;
                            end
                        end else if(key_num==4'b0010) begin //[, m=160, M=239
                            if(cnt_next[key_num]==0) begin  //0
                                pixel_addr_next = ( 320*(239-(h_cnt>>1)) + (160+(v_cnt>>1)) )%76800;    //90
                            end else if(cnt_next[key_num]==1) begin //90
                                pixel_addr_next = ( 320*(79-(v_cnt>>1)) + (160+239-(h_cnt>>1)) )%76800; //180
                            end else if(cnt_next[key_num]==2) begin //180
                                pixel_addr_next = ( 320*((h_cnt>>1)-160) + (239-(v_cnt>>1)) )%76800; //270
                            end else if(cnt_next[key_num]==3) begin //270
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;    //0
                            end else begin
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;
                            end
                        end else if(key_num==4'b0011) begin //], m=240, M=319
                            if(cnt_next[key_num]==0) begin  //0
                                pixel_addr_next = ( 320*(319-(h_cnt>>1)) + (240+(v_cnt>>1)) )%76800; //90
                            end else if(cnt_next[key_num]==1) begin //90
                                pixel_addr_next = ( 320*(79-(v_cnt>>1)) + (240+319-(h_cnt>>1)) )%76800; //180
                            end else if(cnt_next[key_num]==2) begin //180
                                pixel_addr_next = ( 320*((h_cnt>>1)-240) + (319-(v_cnt>>1)) )%76800; //270
                            end else if(cnt_next[key_num]==3) begin //270
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;    //0
                            end else begin
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;
                            end
                        end else if(key_num==4'b0100) begin //k, m=0,   M=79
                            if(cnt_next[key_num]==0) begin  //0
                                pixel_addr_next = ( 320*(79-(h_cnt>>1)+80) + ((v_cnt>>1)+0-80) )%76800; //90
                            end else if(cnt_next[key_num]==1) begin //90
                                pixel_addr_next = ( 320*(239-(v_cnt>>1)) + (0+79-(h_cnt>>1)) )%76800; //180
                            end else if(cnt_next[key_num]==2) begin //180
                                pixel_addr_next = ( 320*((h_cnt>>1)-0+80) + (79-(v_cnt>>1)+80) )%76800; //270
                            end else if(cnt_next[key_num]==3) begin //270
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;    //0
                            end else begin
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;
                            end
                        end else if(key_num==4'b0101) begin //l, m=80,  M=159
                            if(cnt_next[key_num]==0) begin  //0
                                pixel_addr_next = ( 320*(159-(h_cnt>>1)+80) + ((v_cnt>>1)+80-80) )%76800; //90
                            end else if(cnt_next[key_num]==1) begin //90
                                pixel_addr_next = ( 320*(239-(v_cnt>>1)) + (80+159-(h_cnt>>1)) )%76800; //180
                            end else if(cnt_next[key_num]==2) begin //180
                                pixel_addr_next = ( 320*((h_cnt>>1)-80+80) + (159-(v_cnt>>1)+80) )%76800; //270
                            end else if(cnt_next[key_num]==3) begin //270
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;    //0
                            end else begin
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;
                            end
                        end else if(key_num==4'b0110) begin //;, m=160, M=239
                            if(cnt_next[key_num]==0) begin  //0
                                pixel_addr_next = ( 320*(239-(h_cnt>>1)+80) + (160+(v_cnt>>1)-80) )%76800; //90
                            end else if(cnt_next[key_num]==1) begin //90
                                pixel_addr_next = ( 320*(239-(v_cnt>>1)) + (160+239-(h_cnt>>1)) )%76800; //180
                            end else if(cnt_next[key_num]==2) begin //180
                                pixel_addr_next = ( 320*((h_cnt>>1)-160+80) + (239-(v_cnt>>1)+80) )%76800; //270
                            end else if(cnt_next[key_num]==3) begin //270
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;    //0
                            end else begin
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;
                            end
                        end else if(key_num==4'b0111) begin //', m=240, M=319
                            if(cnt_next[key_num]==0) begin  //0
                                pixel_addr_next = ( 320*(319-(h_cnt>>1)+80) + (240+(v_cnt>>1)-80) )%76800;  //90
                            end else if(cnt_next[key_num]==1) begin //90
                                pixel_addr_next = ( 320*(239-(v_cnt>>1)) + (240+319-(h_cnt>>1)) )%76800; //180
                            end else if(cnt_next[key_num]==2) begin //180
                                pixel_addr_next = ( 320*((h_cnt>>1)-240+80) + (319-(v_cnt>>1)+80) )%76800; //270
                            end else if(cnt_next[key_num]==3) begin //270
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;    //0
                            end else begin
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;
                            end
                        end else if(key_num==4'b1000) begin //m, m=0,   M=79
                            if(cnt_next[key_num]==0) begin  //0
                                pixel_addr_next = ( 320*(79-(h_cnt>>1)+160) + (0+(v_cnt>>1)-160) )%76800; //90
                            end else if(cnt_next[key_num]==1) begin //90
                                pixel_addr_next = ( 320*(399-(v_cnt>>1)) + (0+79-(h_cnt>>1)) )%76800; //180
                            end else if(cnt_next[key_num]==2) begin //180
                                pixel_addr_next = ( 320*((h_cnt>>1)-0+160) + (79-(v_cnt>>1)+160) )%76800; //270
                            end else if(cnt_next[key_num]==3) begin //270
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;    //0
                            end else begin
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;
                            end
                        end else if(key_num==4'b1001) begin //,, m=80,  M=159
                            if(cnt_next[key_num]==0) begin  //0
                                pixel_addr_next = ( 320*(159-(h_cnt>>1)+160) + (80+(v_cnt>>1)-160) )%76800; //90
                            end else if(cnt_next[key_num]==1) begin //90
                                pixel_addr_next = ( 320*(399-(v_cnt>>1)) + (80+159-(h_cnt>>1)) )%76800; //180
                            end else if(cnt_next[key_num]==2) begin //180
                                pixel_addr_next = ( 320*((h_cnt>>1)-80+160) + (159-(v_cnt>>1)+160) )%76800; //270
                            end else if(cnt_next[key_num]==3) begin //270
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;    //0
                            end else begin
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;
                            end
                        end else if(key_num==4'b1010) begin //., m=160, M=239
                            if(cnt_next[key_num]==0) begin  //0
                                pixel_addr_next = ( 320*(239-(h_cnt>>1)+160) + (160+(v_cnt>>1)-160) )%76800;  //90
                            end else if(cnt_next[key_num]==1) begin //90
                                pixel_addr_next = ( 320*(399-(v_cnt>>1)) + (160+239-(h_cnt>>1)) )%76800; //180
                            end else if(cnt_next[key_num]==2) begin //180
                                pixel_addr_next = ( 320*((h_cnt>>1)-160+160) + (239-(v_cnt>>1)+160) )%76800; //270
                            end else if(cnt_next[key_num]==3) begin //270
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;    //0
                            end else begin
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;
                            end
                        end else if(key_num==4'b1011) begin ///, m=240, M=319
                            if(cnt_next[key_num]==0) begin  //0
                                pixel_addr_next = ( 320*(319-(h_cnt>>1)+160) + (240+(v_cnt>>1)-160) )%76800; //90
                            end else if(cnt_next[key_num]==1) begin //90
                                pixel_addr_next = ( 320*(399-(v_cnt>>1)) + (240+319-(h_cnt>>1)) )%76800; //180
                            end else if(cnt_next[key_num]==2) begin //180
                                pixel_addr_next = ( 320*((h_cnt>>1)-240+160) + (319-(v_cnt>>1)+160) )%76800; //270
                            end else if(cnt_next[key_num]==3) begin //270
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;    //0
                            end else begin
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;
                            end
                        end
                    end else begin  //shift pressed
                        cnt_next[key_num]=cnt[key_num]-1;
                        if(key_num==4'b0000) begin
                            if(cnt_next[key_num]==0) begin  //0
                                pixel_addr_next = ( 320*((h_cnt>>1)-0) + (79-(v_cnt>>1)) )%76800; //270
                            end else if(cnt_next[key_num]==1) begin //90
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;    //0
                            end else if(cnt_next[key_num]==2) begin //180
                                pixel_addr_next = ( 320*(79-(h_cnt>>1)) + (0+v_cnt>>1) )%76800; //90
                            end else if(cnt_next[key_num]==3) begin //270
                                pixel_addr_next = ( 320*(79-(v_cnt>>1)) + (0+79-(h_cnt>>1)) )%76800; //180
                            end else begin
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;
                            end
                        end else if(key_num==4'b0001) begin
                            if(cnt_next[key_num]==0) begin  //0
                                pixel_addr_next = ( 320*((h_cnt>>1)-80) + (159-(v_cnt>>1)) )%76800; //270
                            end else if(cnt_next[key_num]==1) begin //90
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;    //0
                            end else if(cnt_next[key_num]==2) begin //180
                                pixel_addr_next = ( 320*(159-(h_cnt>>1)) + (80+(v_cnt>>1)) )%76800; //90
                            end else if(cnt_next[key_num]==3) begin //270
                                pixel_addr_next = ( 320*(79-(v_cnt>>1)) + (80+159-(h_cnt>>1)) )%76800; //180
                            end else begin
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;
                            end
                        end else if(key_num==4'b0010) begin
                            if(cnt_next[key_num]==0) begin  //0
                                pixel_addr_next = ( 320*((h_cnt>>1)-160) + (239-(v_cnt>>1)) )%76800; //270
                            end else if(cnt_next[key_num]==1) begin //90
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;    //0
                            end else if(cnt_next[key_num]==2) begin //180
                                pixel_addr_next = ( 320*(239-(h_cnt>>1)) + (160+(v_cnt>>1)) )%76800;    //90
                            end else if(cnt_next[key_num]==3) begin //270
                                pixel_addr_next = ( 320*(79-(v_cnt>>1)) + (160+239-(h_cnt>>1)) )%76800; //180
                            end else begin
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;
                            end
                        end else if(key_num==4'b0011) begin
                            if(cnt_next[key_num]==0) begin  //0
                                pixel_addr_next = ( 320*((h_cnt>>1)-240) + (319-(v_cnt>>1)) )%76800; //270
                            end else if(cnt_next[key_num]==1) begin //90
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;    //0
                            end else if(cnt_next[key_num]==2) begin //180
                                pixel_addr_next = ( 320*(319-(h_cnt>>1)) + (240+(v_cnt>>1)) )%76800; //90
                            end else if(cnt_next[key_num]==3) begin //270
                                pixel_addr_next = ( 320*(79-(v_cnt>>1)) + (240+319-(h_cnt>>1)) )%76800; //180
                            end else begin
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;
                            end
                        end else if(key_num==4'b0100) begin
                            if(cnt_next[key_num]==0) begin  //0
                                pixel_addr_next = ( 320*((h_cnt>>1)-0+80) + (79-(v_cnt>>1)+80) )%76800; //270
                            end else if(cnt_next[key_num]==1) begin //90
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;    //0
                            end else if(cnt_next[key_num]==2) begin //180
                                pixel_addr_next = ( 320*(79-(h_cnt>>1)+80) + ((v_cnt>>1)+0-80) )%76800; //90
                            end else if(cnt_next[key_num]==3) begin //270
                                pixel_addr_next = ( 320*(239-(v_cnt>>1)) + (0+79-(h_cnt>>1)) )%76800; //180
                            end else begin
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;
                            end
                        end else if(key_num==4'b0101) begin
                            if(cnt_next[key_num]==0) begin  //0
                                pixel_addr_next = ( 320*((h_cnt>>1)-80+80) + (159-(v_cnt>>1)+80) )%76800; //270
                            end else if(cnt_next[key_num]==1) begin //90
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;    //0
                            end else if(cnt_next[key_num]==2) begin //180
                                pixel_addr_next = ( 320*(159-(h_cnt>>1)+80) + ((v_cnt>>1)+80-80) )%76800; //90
                            end else if(cnt_next[key_num]==3) begin //270
                                pixel_addr_next = ( 320*(239-(v_cnt>>1)) + (80+159-(h_cnt>>1)) )%76800; //180
                            end else begin
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;
                            end
                        end else if(key_num==4'b0110) begin
                            if(cnt_next[key_num]==0) begin  //0
                                pixel_addr_next = ( 320*((h_cnt>>1)-160+80) + (239-(v_cnt>>1)+80) )%76800; //270
                            end else if(cnt_next[key_num]==1) begin //90
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;    //0
                            end else if(cnt_next[key_num]==2) begin //180
                                pixel_addr_next = ( 320*(239-(h_cnt>>1)+80) + (160+(v_cnt>>1)-80) )%76800; //90
                            end else if(cnt_next[key_num]==3) begin //270
                                pixel_addr_next = ( 320*(239-(v_cnt>>1)) + (160+239-(h_cnt>>1)) )%76800; //180
                            end else begin
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;
                            end
                        end else if(key_num==4'b0111) begin
                            if(cnt_next[key_num]==0) begin  //0
                                pixel_addr_next = ( 320*((h_cnt>>1)-240+80) + (319-(v_cnt>>1)+80) )%76800; //270
                            end else if(cnt_next[key_num]==1) begin //90
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;    //0
                            end else if(cnt_next[key_num]==2) begin //180
                                pixel_addr_next = ( 320*(319-(h_cnt>>1)+80) + (240+(v_cnt>>1)-80) )%76800;  //90
                            end else if(cnt_next[key_num]==3) begin //270
                                pixel_addr_next = ( 320*(239-(v_cnt>>1)) + (240+319-(h_cnt>>1)) )%76800; //180
                            end else begin
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;
                            end
                        end else if(key_num==4'b1000) begin
                            if(cnt_next[key_num]==0) begin  //0
                                pixel_addr_next = ( 320*((h_cnt>>1)-0+160) + (79-(v_cnt>>1)+160) )%76800; //270
                            end else if(cnt_next[key_num]==1) begin //90
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;    //0
                            end else if(cnt_next[key_num]==2) begin //180
                                pixel_addr_next = ( 320*(79-(h_cnt>>1)+160) + (0+(v_cnt>>1)-160) )%76800; //90
                            end else if(cnt_next[key_num]==3) begin //270
                                pixel_addr_next = ( 320*(399-(v_cnt>>1)) + (0+79-(h_cnt>>1)) )%76800; //180
                            end else begin
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;
                            end
                        end else if(key_num==4'b1001) begin
                            if(cnt_next[key_num]==0) begin  //0
                                pixel_addr_next = ( 320*((h_cnt>>1)-80+160) + (159-(v_cnt>>1)+160) )%76800; //270
                            end else if(cnt_next[key_num]==1) begin //90
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;    //0
                            end else if(cnt_next[key_num]==2) begin //180
                                pixel_addr_next = ( 320*(159-(h_cnt>>1)+160) + (80+(v_cnt>>1)-160) )%76800; //90
                            end else if(cnt_next[key_num]==3) begin //270
                                pixel_addr_next = ( 320*(399-(v_cnt>>1)) + (80+159-(h_cnt>>1)) )%76800; //180
                            end else begin
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;
                            end
                        end else if(key_num==4'b1010) begin
                            if(cnt_next[key_num]==0) begin  //0
                                pixel_addr_next = ( 320*((h_cnt>>1)-160+160) + (239-(v_cnt>>1)+160) )%76800; //270
                            end else if(cnt_next[key_num]==1) begin //90
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;    //0
                            end else if(cnt_next[key_num]==2) begin //180
                                pixel_addr_next = ( 320*(239-(h_cnt>>1)+160) + (160+(v_cnt>>1)-160) )%76800;  //90
                            end else if(cnt_next[key_num]==3) begin //270
                                pixel_addr_next = ( 320*(399-(v_cnt>>1)) + (160+239-(h_cnt>>1)) )%76800; //180
                            end else begin
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;
                            end
                        end else if(key_num==4'b1011) begin
                            if(cnt_next[key_num]==0) begin  //0
                                pixel_addr_next = ( 320*((h_cnt>>1)-240+160) + (319-(v_cnt>>1)+160) )%76800; //270
                            end else if(cnt_next[key_num]==1) begin //90
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;    //0
                            end else if(cnt_next[key_num]==2) begin //180
                                pixel_addr_next = ( 320*(319-(h_cnt>>1)+160) + (240+(v_cnt>>1)-160) )%76800; //90
                            end else if(cnt_next[key_num]==3) begin //270
                                pixel_addr_next = ( 320*(399-(v_cnt>>1)) + (240+319-(h_cnt>>1)) )%76800; //180
                            end else begin
                                pixel_addr_next = ((h_cnt>>1)+320*(v_cnt>>1))%76800;
                            end
                        end
                    end
                end
            end
        end
        
        for(i=0;i<12;i=i+1) begin
            if(cnt[i]==1) begin
                done_next=0;
            end else begin
                done_next=done;
            end
        end
    end
    
    assign ispass = (done) ? 1'b1 : 1'b0;

    always @ (*) begin
		case (last_change)
			KEY_CODES[00] : key_num = 4'b0000;
			KEY_CODES[01] : key_num = 4'b0001;
			KEY_CODES[02] : key_num = 4'b0010;
			KEY_CODES[03] : key_num = 4'b0011;
			KEY_CODES[04] : key_num = 4'b0100;
			KEY_CODES[05] : key_num = 4'b0101;
			KEY_CODES[06] : key_num = 4'b0110;
			KEY_CODES[07] : key_num = 4'b0111;
			KEY_CODES[08] : key_num = 4'b1000;
			KEY_CODES[09] : key_num = 4'b1001;
			KEY_CODES[10] : key_num = 4'b1010;
			KEY_CODES[11] : key_num = 4'b1011;
			default		  : key_num = 4'b1111;
		endcase
	end
endmodule

module lab7_2(
    input clk,
    input rst,
    input hold,
    inout PS2_CLK,
    inout PS2_DATA,
    output [3:0] vgaRed,
    output [3:0] vgaGreen,
    output [3:0] vgaBlue,
    output hsync,
    output vsync,
    output pass
);
    wire [11:0] data;
    wire clk_25MHz;
    wire clk_22;
    wire [16:0] pixel_addr;
    wire [11:0] pixel;
    wire valid;
    wire [9:0] h_cnt; //640
    wire [9:0] v_cnt;  //480

    assign {vgaRed, vgaGreen, vgaBlue} = (valid) ? pixel : 12'h0;
    assign data = {vgaRed, vgaGreen, vgaBlue};

    clock_divider #(.n(2)) c25MHz(.clk(clk), .clk_div(clk_25MHz)); //100/4 = 25Mhz
    clock_divider #(.n(22)) c22(.clk(clk), .clk_div(clk_22));

    mem_addr_gen2 mem_addr_gen_inst(
        .clk(clk_22),
        .rst(rst),
        .hold(hold),
        .PS2_CLK(PS2_CLK),
        .PS2_DATA(PS2_DATA),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt),
        .pixel_addr(pixel_addr),
        .ispass(pass)
    );
    
    blk_mem_gen_0 blk_mem_gen_0_inst(
        .clka(clk_25MHz),
        .wea(0),
        .addra(pixel_addr),
        .dina(data[11:0]),
        .douta(pixel)
    ); 

    vga_controller vga_inst(
        .pclk(clk_25MHz),
        .reset(rst),
        .hsync(hsync),
        .vsync(vsync),
        .valid(valid),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt)
    );
endmodule