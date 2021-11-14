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

module lab06(
    input clk,
    input rst,
    //inout PS2_CLK,
    //inout PS2_DATA,
    output reg [3:0] DIGIT,
    output reg [6:0] DISPLAY,
    output reg [15:0] LED,
    input addb1,
    input addb2
);
    parameter BOTTOM = 0;
    parameter TOP = 1;
    parameter STANDBY = 2;
    parameter G2 = 3;
    parameter RUN = 4;


    wire display_clk, work_clk,work_clk_1p;
    clock_divider #(.n(13)) display(.clk(clk), .clk_div(display_clk));  //7-segment display
    clock_divider #(.n(26)) work(.clk(clk), .clk_div(work_clk));    //clk to operate FSM
    onepulse workclk_1p(.clk(clk),.pb_debounced(work_clk),.pb_1pulse(work_clk_1p));

    wire addbottom_debounced, addtop_debounced, addbottom_1pulse, addtop_1pulse;
    debounce addb1_de(.clk(clk),.pb(addb1),.pb_debounced(addbottom_debounced));
    debounce addb2_de(.clk(clk),.pb(addb2),.pb_debounced(addtop_debounced));
    onepulse addb1_op(.clk(clk),.pb_debounced(addbottom_debounced),.pb_1pulse(addbottom_1pulse));
    onepulse addb2_op(.clk(clk),.pb_debounced(addtop_debounced),.pb_1pulse(addtop_1pulse));


    /*wire [511:0] key_down;
    wire [8:0] last_change;
    wire key_valid;
    KeyboardDecoder keydecode(
        .key_down(key_down),
        .last_change(last_change),
        .key_valid(key_valid),
        .PS2_DATA(PS2_DATA),
        .PS2_CLK(PS2_CLK),
        .rst(rst),
        .clk(clk)
    );*/


    integer i;
    reg [3:0] value;
    reg [3:0] my[0:3], my_next[0:3]; //used for display
    reg [15:0] led_next;
    reg [2:0] state=STANDBY, state_next;
    reg climbup=1, climbup_next;
    //reg [1:0] b1_people=0, b1_people_next;
    //reg [1:0] b2_people=0, b2_people_next;
    reg [1:0] passenger=0, passenger_next;
    reg [6:0] revenue=0, revenue_next;
    reg [6:0] gas_amount=0, gas_amount_next;

    //flags
    reg getdown_finish=0, getdown_finish_next;
    reg getup_finish=0, getup_finish_next;
    reg get_revenue_finish=0, get_revenue_finish_next;
    reg addfuel_finish=0, addfuel_finish_next;

    always @(posedge clk,posedge rst) begin
        if(rst) begin
            for(i=0;i<4;i=i+1) begin
                my[i]<=0;
            end
            LED<=1; //bus stops at bottom
            state<=STANDBY;//BOTTOM;
            climbup<=1;
            passenger<=0;
            revenue<=0;
            gas_amount<=0;

            //flags
            getdown_finish<=0;
            getup_finish<=0;
            get_revenue_finish<=0;
            addfuel_finish<=0;
        end else begin
            for(i=0;i<4;i=i+1) begin
                my[i]<=my_next[i];
            end
            LED<=led_next;
            state<=state_next;
            climbup<=climbup_next;
            passenger<=passenger_next;
            revenue<=revenue_next;
            gas_amount<=gas_amount_next;

            //flags
            getdown_finish<=getdown_finish_next;
            getup_finish<=getup_finish_next;
            get_revenue_finish<=get_revenue_finish_next;
            addfuel_finish<=addfuel_finish_next;
        end
    end


    //[6:0] bus position
    //[15:14] bottom�����H��
    //[12:11] top�����H��
    //[10:9] ���W�H��
    always @(*) begin
        for(i=0;i<4;i=i+1) begin
            my_next[i]=my[i];
        end
        led_next=LED;
        state_next=state;
        climbup_next=climbup;
        passenger_next=passenger;
        revenue_next=revenue;
        gas_amount_next=gas_amount;

        //flags
        getdown_finish_next = getdown_finish;
        getup_finish_next = getup_finish;
        get_revenue_finish_next = get_revenue_finish;
        addfuel_finish_next = addfuel_finish;



        //can control led at any state,detect keyboard input(����buttton����)
        if(addbottom_1pulse) begin
            if(LED[15:14]==2'b00) begin
                led_next[15:14]=2'b10;
            end else if(LED[15:14]==2'b10) begin
                led_next[15:14]=2'b11;
            end else begin
                led_next[15:14]=2'b11;
            end
        end else if(addtop_1pulse) begin
            if(LED[12:11]==2'b00) begin
                led_next[12:11]=2'b10;
            end else if(LED[12:11]==2'b10) begin
                led_next[12:11]=2'b11;
            end else begin
                led_next[12:11]=2'b11;
            end
        end

        if(work_clk_1p) begin
            if(state==BOTTOM) begin
                climbup_next=1;
                //�W�U��=>�W�U����}�A�U�����ˬd�����H�ơA�S�H�N�]��standby
                if(passenger>0 && getdown_finish==1'b0) begin   //have passenger => get down one by one
                    led_next[10:9] = {LED[9], 1'b0};    //left shift

                    passenger_next = passenger - 1; //update passenger count
                end else begin  //no one on the bus => get on all at once
                    getdown_finish_next=1;

                    if(getup_finish==1'b0) begin
                        led_next[10:9] = LED[15:14];    //people waiting at b1 get on the bus at once
                        led_next[15:14] = 2'b00;
                        getup_finish_next=1;
                    end
                    
                    if(LED[15:14]==2'b11) begin //update passenger count
                        passenger_next = passenger + 2;
                    end else if(LED[15:14]==2'b10) begin
                        passenger_next = passenger + 1;
                    end
                end

                //��$
                if(getup_finish && !get_revenue_finish) begin
                    revenue_next=revenue + passenger*30;

                    my_next[2]= (revenue + passenger*30) / 10;
                    my_next[3]=0;

                    get_revenue_finish_next=1;
                end
                
                //�[�o
                if(get_revenue_finish) begin
                    if(gas_amount==20) begin    //fuel already full,go to run state
                        addfuel_finish_next=1;
                    end else begin  //fuel not full,add fuel
                        if(revenue>10) begin
                            revenue_next=revenue-10;
                            my_next[2]=my[2]-1;
                            my_next[3]=0;

                            if(gas_amount+10 >20) begin //�W�L�̤j�o�q
                                gas_amount_next=20;
                                my_next[0]=2;
                                my_next[1]=0;
                            end else begin
                                gas_amount_next=gas_amount+10;
                                my_next[0]=my[0]+1;
                                my_next[1]=my[1];
                            end
                        end else begin  //�S���R�o or �o�w��
                            addfuel_finish_next=1;
                        end
                    end
                end

                if(addfuel_finish) begin
                    state_next=RUN;

                    //reset all flags before change state
                    getdown_finish_next=0;
                    getup_finish_next=0;
                    get_revenue_finish_next=0;
                    addfuel_finish_next=0;
                end
            end else if(state==TOP) begin
                climbup_next=0;
                //�W�U��
                if(passenger>0 && !getdown_finish) begin   //have passenger => get down one by one
                    led_next[10:9] = {LED[9], 1'b0};    //left shift

                    passenger_next = passenger - 1; //update passenger count
                end else begin  //no one on the bus => get on all at once
                    getdown_finish_next=1;

                    if(getup_finish==1'b0) begin
                        led_next[10:9] = LED[12:11];    //people waiting at b1 get on the bus at once
                        led_next[12:11] = 2'b00;
                        getup_finish_next=1;
                    end
                    

                    if(LED[12:11]==2'b11) begin //update passenger count
                        passenger_next = passenger + 2;
                    end else if(LED[12:11]==2'b10) begin
                        passenger_next = passenger + 1;
                    end
                end

                //��$
                if(getup_finish && !get_revenue_finish) begin
                    revenue_next=revenue + passenger*20;

                    my_next[2] = (revenue + passenger*20) / 10;
                    my_next[3]=0;

                    get_revenue_finish_next=1;
                end
                
                //�[�o
                if(get_revenue_finish) begin
                    if(gas_amount==20) begin    //fuel already full,go to run state
                        addfuel_finish_next=1;
                    end else begin  //fuel not full,add fuel
                        if(revenue>10) begin
                            revenue_next=revenue-10;
                            my_next[2]=my[2]-1;
                            my_next[3]=0;

                            if(gas_amount+10 >20) begin //�W�L�̤j�o�q
                                gas_amount_next=20;
                                my_next[0]=2;
                                my_next[1]=0;
                            end else begin
                                gas_amount_next=gas_amount+10;
                                my_next[0]=my[0]+1;
                                my_next[1]=my[1];
                            end
                        end else begin  //�S���R�o or �o�w��
                            addfuel_finish_next=1;
                        end
                    end
                end

                if(addfuel_finish) begin
                    state_next=RUN;

                    //reset all flags before change state
                    getdown_finish_next=0;
                    getup_finish_next=0;
                    get_revenue_finish_next=0;
                    addfuel_finish_next=0;
                end
            end else if(state==RUN) begin
                //�쯸(TOP,BOTTOM,G2)�A��s�o�q
                if(climbup) begin   //���W��(left shift)
                    if(LED[6:0]==7'b0000100) begin  //�ǳƨ줤�����[�o��
                        //���o�q
                        if(passenger>0) begin   //�����ȴN���o�q
                            gas_amount_next = gas_amount - passenger*5;
                            my_next[0] = (gas_amount - passenger*5)/10;
                            my_next[1] = (gas_amount - passenger*5)%10;
                        end/* else begin  //�S���ȴN���Φ�
                            
                        end*/
                        led_next[6:0]=7'b0001000;
                    end else if(LED[6:0]==7'b0001000) begin  //�줤�����[�o��
                        if(gas_amount==20) begin    //�o�w���A�~��
                            led_next[6:0]=7'b0010000;
                        end else begin  //fuel not full,add fuel
                            if(revenue>10) begin
                                led_next[6:0]=7'b0001000;
                                
                                revenue_next=revenue-10;
                                my_next[2]=my[2]-1;
                                my_next[3]=0;

                                if(gas_amount+10 >20) begin //�W�L�̤j�o�q
                                    gas_amount_next=20;
                                    my_next[0]=2;
                                    my_next[1]=0;
                                end else begin
                                    gas_amount_next=gas_amount+10;
                                    my_next[0]=my[0]+1;
                                    my_next[1]=my[1];
                                end
                            end else begin  //�S���R�o => �~��
                                led_next[6:0]=7'b0010000;
                            end
                        end
                    end else if(LED[6:0]==7'b0100000) begin //�ǳƨ�top
                        //���o�q
                        if(passenger>0) begin   //�����ȴN���o�q
                            gas_amount_next = gas_amount - passenger*5;
                            my_next[0] = (gas_amount - passenger*5)/10;
                            my_next[1] = (gas_amount - passenger*5)%10;
                        end/* else begin  //�S���ȴN���Φ�
                            
                        end*/
                        led_next[6:0]=7'b1000000;
                    end else if(LED[6:0]==7'b1000000) begin //��top
                        getdown_finish_next=0;
                        getup_finish_next=0;
                        addfuel_finish_next=0;
                        get_revenue_finish_next=0;
                        climbup_next=0;
                        state_next=TOP;
                    end else begin
                        led_next[6:0]={LED[5:0],1'b0};  //���W��
                    end
                end else begin  //���U��(right shift)
                    if(LED[6:0]==7'b0010000) begin  //�ǳƨ줤�����[�o��
                        //���o�q
                        if(passenger>0) begin   //�����ȴN���o�q
                            gas_amount_next = gas_amount - passenger*5;
                            my_next[0] = (gas_amount - passenger*5)/10;
                            my_next[1] = (gas_amount - passenger*5)%10;
                        end/* else begin  //�S���ȴN���Φ�
                            
                        end*/
                        led_next[6:0]=7'b0001000;
                    end else if(LED[6:0]==7'b0001000) begin //�줤�����[�o��
                        if(gas_amount==20) begin    //�o�w���A�~��
                            led_next[6:0]=7'b0000100;
                        end else begin  //fuel not full,add fuel
                            if(revenue>10) begin
                                led_next[6:0]=7'b0001000;
                                
                                revenue_next=revenue-10;
                                my_next[2]=my[2]-1;
                                my_next[3]=0;

                                if(gas_amount+10 >20) begin //�W�L�̤j�o�q
                                    gas_amount_next=20;
                                    my_next[0]=2;
                                    my_next[1]=0;
                                end else begin
                                    gas_amount_next=gas_amount+10;
                                    my_next[0]=my[0]+1;
                                    my_next[1]=my[1];
                                end
                            end else begin  //�S���R�o => �~��
                                led_next[6:0]=7'b0000100;
                            end
                        end
                    end else if(LED[6:0]==7'b0000010) begin //�ǳƨ�bottom
                        //���o�q
                        if(passenger>0) begin   //�����ȴN���o�q
                            gas_amount_next = gas_amount - passenger*5;
                            my_next[0] = (gas_amount - passenger*5)/10;
                            my_next[1] = (gas_amount - passenger*5)%10;
                        end/* else begin  //�S���ȴN���Φ�
                            
                        end*/
                        led_next[6:0]=7'b0000001;
                    end else if(LED[6:0]==7'b0000001) begin //��bottom
                        getdown_finish_next=0;
                        getup_finish_next=0;
                        addfuel_finish_next=0;
                        get_revenue_finish_next=0;
                        climbup_next=1;
                        state_next=BOTTOM;
                    end else begin
                        led_next[6:0]={1'b0,LED[6:1]};  //���U��
                    end
                end
            end else if(state==STANDBY) begin
                //maintain everything
                //check both bus stop
                if(LED[6:0]==7'b0000001 && (LED[15:14]==2'b10 || LED[15:14]==2'b11)) begin //���bbottom && bottom���H
                    state_next=BOTTOM;
                end else if(LED[6:0]==7'b1000000 && (LED[12:11]==2'b10 || LED[12:11]==2'b11)) begin   //���btop && top���H
                    state_next=TOP;
                end else if((LED[6:0]==7'b0000001 && (LED[12:11]==2'b10 || LED[12:11]==2'b11)) ||
                            (LED[6:0]==7'b1000000 && (LED[15:14]==2'b10 || LED[15:14]==2'b11)) ) begin  //���bbottom,top���H || ���btop,bottom���H
                    state_next=RUN;
                end else begin
                    state_next=STANDBY;
                end
            end
        end
    end

    //7-segment control
    always @(posedge display_clk) begin
        case(DIGIT)
            4'b1110: begin
                value=my[2];
                DIGIT=4'b1101;
            end
            4'b1101: begin
                value=my[1];
                DIGIT=4'b1011;
            end
            4'b1011: begin
                value=my[0];
                DIGIT=4'b0111;
            end
            4'b0111: begin
                value=my[3];
                DIGIT=4'b1110;
            end
            default: begin
                value=my[3];
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
            default: DISPLAY=7'b111_1111;
        endcase
    end
endmodule