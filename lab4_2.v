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

module debounce(
    input clk,
    input pb,
    output pb_debounced
);
    reg [3:0] shift_reg;

    always @(posedge clk) begin
        shift_reg[3:1] <= shift_reg[2:0];
        shift_reg[0] <= pb;
    end

    assign pb_debounced = (shift_reg==4'b1111) ? 1'b1 : 1'b0;
endmodule

module onepulse(
    input clk,
    input pb_debounced,
    output reg pb_1pulse
);
    reg pb_debounced_delay;

    always @(posedge clk) begin
        if(pb_debounced==1'b1 && pb_debounced_delay==1'b0) begin
            pb_1pulse <= 1'b1;
        end else begin
            pb_1pulse <= 1'b0;
        end
        pb_debounced_delay <= pb_debounced;
    end
endmodule

module lab4_2(
    input clk,
    input rst,
    input en,
    input input_number,
    input enter,
    input count_down,
    output reg [3:0] DIGIT,
    output reg [6:0] DISPLAY,
    output reg led0
);
    parameter START = 1'b0;
    parameter PAUSE = 1'b1;
    parameter [2:0] DIRECTION=0;    //direction setting state
    parameter [2:0] MINUTE=1;
    parameter [2:0] TENSEC=2;
    parameter [2:0] SECOND=3;
    parameter [2:0] POINTSEC=4;
    parameter [2:0] COUNTING=5; //counting state
    
    reg [3:0] value;
    reg countdown=0;    //initial is countup
    reg mode=START;
    reg [2:0] state=DIRECTION, state_next;

    reg [3:0] mytime[0:3];  //{min, 10s, 1s, 0.1s}
    reg [3:0] set_time_next[0:3];    //{min, 10s, 1s, 0.1s}
    reg [3:0] cntdown_time_next[0:3];    //{min, 10s, 1s, 0.1s}
    reg [3:0] cntup_time_next[0:3]; //{min, 10s, 1s, 0.1s}
    reg [3:0] goal[0:3];    //{min, 10s, 1s, 0.1s}

    wire display_clk,myclk;
    clock_divider #(.n(10)) cnt(.clk(clk), .clk_div(display_clk));  //clock to display 7-segment
    clock_divider #(.n(23)) myclkdiv(.clk(clk), .clk_div(myclk));    //not sure abouot the exact time
    
    //7-segment control
    always @(posedge display_clk) begin
        case(DIGIT)
            4'b1110: begin
                if(state==DIRECTION) begin
                    value=10;
                end else begin
                    value=mytime[2];//second;
                end
                DIGIT=4'b1101;
            end
            4'b1101: begin
                if(state==DIRECTION) begin
                    value=10;
                end else begin
                    value=mytime[1];//tensec;
                end
                DIGIT=4'b1011;
            end
            4'b1011: begin
                if(state==DIRECTION) begin
                    value=10;
                end else begin
                    value=mytime[0];//minute;
                end
                DIGIT=4'b0111;
            end
            4'b0111: begin
                if(state==DIRECTION) begin
                    value=10;
                end else begin
                    value=mytime[3];//pointsec;
                end
                DIGIT=4'b1110;
            end
            default: begin
                value=0;
                DIGIT=4'b1110;
            end
        endcase
    end
    always @(*) begin
        case(value) //0 means on,1 means off(GFEDCBA)
            4'd0: DISPLAY=7'b100_0000;
            4'd1: DISPLAY=7'b111_1001;
            4'd2: DISPLAY=7'b010_0100;
            4'd3: DISPLAY=7'b011_0000;
            4'd4: DISPLAY=7'b001_1001;
            4'd5: DISPLAY=7'b001_0010;
            4'd6: DISPLAY=7'b000_0010;
            4'd7: DISPLAY=7'b111_1000;
            4'd8: DISPLAY=7'b000_0000;
            4'd9: DISPLAY=7'b001_0000;
            4'd10: DISPLAY=7'b011_1111; //'-'
            default: DISPLAY=7'b111_1111;
        endcase
    end

    wire rst_debounced, input_number_debounced, enter_debounced, count_down_debounced;
    debounce rst_de(            .clk(clk), .pb(rst),         .pb_debounced(rst_debounced));
    debounce input_number_de(   .clk(clk), .pb(input_number),.pb_debounced(input_number_debounced));
    debounce enter_de(          .clk(clk), .pb(enter),       .pb_debounced(enter_debounced));
    debounce count_down_de(     .clk(clk), .pb(count_down),  .pb_debounced(count_down_debounced));

    wire rst_1pulse, input_number_1pulse, enter_1pulse, count_down_1pulse;
    onepulse rst_1(         .clk(clk), .pb_debounced(rst_debounced),         .pb_1pulse(rst_1pulse));
    onepulse input_number_1(.clk(clk), .pb_debounced(input_number_debounced),.pb_1pulse(input_number_1pulse));
    onepulse enter_1(       .clk(clk), .pb_debounced(enter_debounced),       .pb_1pulse(enter_1pulse));
    onepulse count_down_1(  .clk(clk), .pb_debounced(count_down_debounced),  .pb_1pulse(count_down_1pulse));


    always @(posedge myclk,posedge rst) begin
        if(rst) begin
            //led0<=0;

            //countdown<=0;
            //mode<=START;
            state<=DIRECTION;
            mytime[0]<=0;
            mytime[1]<=0;
            mytime[2]<=0;
            mytime[3]<=0;

        end else begin
            state<=state_next;
            if(state==MINUTE || state==TENSEC || state==SECOND || state==POINTSEC) begin
                mytime[0]<=set_time_next[0];
                mytime[1]<=set_time_next[1];
                mytime[2]<=set_time_next[2];
                mytime[3]<=set_time_next[3];
            end else if(state==COUNTING) begin
                if(countdown) begin
                    mytime[0]<=cntdown_time_next[0];
                    mytime[1]<=cntdown_time_next[1];
                    mytime[2]<=cntdown_time_next[2];
                    mytime[3]<=cntdown_time_next[3];
                end else begin
                    mytime[0]<=cntup_time_next[0];
                    mytime[1]<=cntup_time_next[1];
                    mytime[2]<=cntup_time_next[2];
                    mytime[3]<=cntup_time_next[3];
                end
            end else begin
                mytime[0]<=0;
                mytime[1]<=0;
                mytime[2]<=0;
                mytime[3]<=0;
            end
        end
    end

    //start/pause(en is switch,dont need to debounce/one pulse)
    always @(*) begin
        if(en) begin
            mode=START;
        end else begin
            mode=PAUSE;
        end
    end

    //count up/down,led0
    always @(posedge count_down_1pulse/*,posedge rst*/) begin
        /*if(rst) begin
            countdown<=0;
            led0<=0;
        end else begin*/
            if(state==DIRECTION) begin
                if(count_down_1pulse) begin
                    countdown = ~countdown;
                    led0 = ~led0;
                end else begin
                    countdown = countdown;
                    led0=led0;
                end
            end else begin
                countdown = countdown;
                led0=led0;
            end
        //end
    end

    //(enter)state transition logic
    always @(posedge enter_1pulse,posedge rst) begin
        if(rst) begin
            state_next<=DIRECTION;
        end else begin
            if(state==DIRECTION) begin
                state_next <= MINUTE;
            end else if(state==MINUTE) begin
                state_next <= TENSEC;
            end else if(state==TENSEC) begin
                state_next <= SECOND;
            end else if(state==SECOND) begin
                state_next <= POINTSEC;
            end else if(state==POINTSEC) begin
                state_next <= COUNTING;
            end else if(state==COUNTING) begin
                state_next <= COUNTING;
            end else begin
                state_next <= DIRECTION;
            end
        end
    end

    //number setting
    always @(posedge input_number_1pulse,posedge rst) begin
        if(rst) begin
            set_time_next[0]=0;
            set_time_next[1]=0;
            set_time_next[2]=0;
            set_time_next[3]=0;
        end else begin
            //maintain every variable no matter at which state(including default)
            //then change the digit depend on the corresponding state
            set_time_next[0]=mytime[0];
            set_time_next[1]=mytime[1];
            set_time_next[2]=mytime[2];
            set_time_next[3]=mytime[3];

            if(state==MINUTE) begin
                if(mytime[0]==1) begin //minute has reach its max 1
                    set_time_next[0]=0;
                end else begin
                    set_time_next[0]=mytime[0]+1;
                end
            end else if(state==TENSEC) begin
                if(mytime[1]==5) begin //tensec has reach its max 5
                    set_time_next[1]=0;
                end else begin
                    set_time_next[1]=mytime[1]+1;
                end
            end else if(state==SECOND) begin
                if(mytime[2]==9) begin //second has reach its max 9
                    set_time_next[2]=0;
                end else begin
                    set_time_next[2]=mytime[2]+1;
                end
            end else if(state==POINTSEC) begin
                if(mytime[3]==9) begin   //pointsec has reach its max 9
                    set_time_next[3]=0;
                end else begin
                    set_time_next[3]=mytime[3]+1;
                end
            end

            //record the goal number
            goal[0]=(countdown) ? 0 : set_time_next[0];
            goal[1]=(countdown) ? 0 : set_time_next[1];
            goal[2]=(countdown) ? 0 : set_time_next[2];
            goal[3]=(countdown) ? 0 : set_time_next[3];
        end
    end

    //counting
    always @(*) begin
        //PAUSE || has count to goal => maintain the number
        if(countdown) begin
            cntdown_time_next[0]=mytime[0];
            cntdown_time_next[1]=mytime[1];
            cntdown_time_next[2]=mytime[2];
            cntdown_time_next[3]=mytime[3];
        end else begin
            cntup_time_next[0]=mytime[0];
            cntup_time_next[1]=mytime[1];
            cntup_time_next[2]=mytime[2];
            cntup_time_next[3]=mytime[3];
        end

        if(mode==START) begin
            if(mytime[0]!=goal[0] || mytime[1]!=goal[1] || mytime[2]!=goal[2] || mytime[3]!=goal[3]) begin  //havent reach the goal
                if(countdown) begin
                    if(mytime[0]==0 && mytime[1]==0 && mytime[2]==0 && mytime[3]==0) begin
                        cntdown_time_next[0]=0;
                        cntdown_time_next[1]=0;
                        cntdown_time_next[2]=0;
                        cntdown_time_next[3]=0;
                    end else begin
                        if(mytime[3]==0) begin   //ex.1:11.0=>1:10.9
                            cntdown_time_next[3]=9;
                            if(mytime[2]==0) begin //ex.1:10.0=>1:09.9
                                cntdown_time_next[2]=9;
                                if(mytime[1]==0) begin //ex.1:00.0=>0:59.9
                                    cntdown_time_next[0]=0;
                                    cntdown_time_next[1]=5;
                                end else begin  //ex.0:10.0=>0:09.9
                                    cntdown_time_next[1]=mytime[1]-1;
                                end
                            end else begin  //ex.0:05.0=>0:04.9
                                cntdown_time_next[2]=mytime[2]-1;
                            end
                        end else begin  //ex.0:00.5=>0:00.4
                            cntdown_time_next[3]=mytime[3]-1;
                        end
                    end
                end else begin  //countup
                    if(mytime[0]==goal[0] && mytime[1]==goal[1] && mytime[2]==goal[2] && mytime[3]==goal[3]) begin  //should be goal here
                        cntup_time_next[0]=goal[0];
                        cntup_time_next[1]=goal[1];
                        cntup_time_next[2]=goal[2];
                        cntup_time_next[3]=goal[3];
                    end else begin
                        if(mytime[3]==9) begin   //ex.0:00.9=>0:01.0
                            cntup_time_next[3]=0;
                            if(mytime[2]==9) begin //ex.0:09.9=>0:10.0
                                cntup_time_next[2]=0;
                                if(mytime[1]==5) begin //ex.0:59.9=>1:00.0
                                    cntup_time_next[0]=1;
                                    cntup_time_next[1]=0;
                                end else begin  //ex.0:49.9=>0:50.0
                                    cntup_time_next[1]=mytime[1]+1;
                                end
                            end else begin  //ex.0:04.9=>0:05.0
                                cntup_time_next[2]=mytime[2]+1;
                            end
                        end else begin  //ex.0:00.1=>0:00.2
                            cntup_time_next[3]=mytime[3]+1;
                        end
                    end
                end
            end
        end
    end
endmodule