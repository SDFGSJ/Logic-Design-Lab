`define c   32'd262   // C3
`define d   32'd294
`define e   32'd330
`define f   32'd349
`define g   32'd392   // G3
`define a   32'd440
`define b   32'd494   // B3
`define hc  32'd524   // C4
`define hd  32'd588   // D4
`define he  32'd660   // E4
`define hf  32'd698   // F4
`define hg  32'd784   // G4
`define ha  32'd880
`define hb  32'd988
`define sil   32'd50000000
`define silence   32'd50000000


module top(
    clk,        // clock from crystal
    rst,        // BTNC: active high reset
    play,      // SW0: Play/Pause
    mute,      // SW1: Mute
    slow,      // SW2: Slow
    mode,      // SW15: Mode
    volUP,     // BTNU: Vol up
    volDOWN,   // BTND: Vol down
    higherOCT, // BTNR: Oct higher
    lowerOCT,  // BTNL: Oct lower
    PS2_DATA,   // Keyboard I/O
    PS2_CLK,    // Keyboard I/O
    led,       // LED: [15:13] octave & [4:0] volume
    audio_mclk, // master clock
    audio_lrck, // left-right clock
    audio_sck,  // serial clock
    audio_sdin, // serial audio data input
    DISPLAY,    // 7-seg
    DIGIT       // 7-seg
);

    // I/O declaration
    input clk; 
    input rst; 
    input play, mute, slow, mode; 
    input volUP, volDOWN, higherOCT, lowerOCT; 
    inout PS2_DATA; 
	inout PS2_CLK; 
    output [15:0] led; 
    output audio_mclk; 
    output audio_lrck; 
    output audio_sck; 
    output audio_sdin; 
    output reg [6:0] DISPLAY; 
    output reg [3:0] DIGIT;

    // Internal Signal
    wire [15:0] audio_in_left, audio_in_right;

    wire [11:0] ibeatNum;               // Beat counter
    wire [31:0] freqL, freqR;           // Raw frequency, produced by music module
    reg [21:0] freq_outL, freq_outR;    // Processed frequency, adapted to the clock rate of Basys3

    // clkDiv22
    wire clkDiv22, clkDiv23, clkDiv24, clkDiv25, clkDiv26,display_clk;
    wire play_speed, led_clk;
    clock_divider #(.n(22)) clock_22(.clk(clk), .clk_div(clkDiv22));    // for keyboard and audio
    clock_divider #(.n(23)) clock_23(.clk(clk), .clk_div(clkDiv23));    // for keyboard and audio
    clock_divider #(.n(24)) clock_24(.clk(clk), .clk_div(clkDiv24));    // for keyboard and audio

    clock_divider #(.n(25)) clock_25(.clk(clk), .clk_div(clkDiv25));    // for led
    clock_divider #(.n(26)) clock_26(.clk(clk), .clk_div(clkDiv26));    // for led

    clock_divider #(.n(13)) display(.clk(clk), .clk_div(display_clk));  //7-segment display

    reg [2:0] volume=3'd3, volume_next;
    reg [2:0] octave=3'd2, octave_next;
    
    wire volUP_debounced, volDOWN_debounced, higherOCT_debounced, lowerOCT_debounced;
    wire volUP_1p, volDOWN_1p, higherOCT_1p, lowerOCT_1p;
    debounce vol_up_de(    .clk(clk), .pb(volUP),     .pb_debounced(volUP_debounced));
    debounce vol_down_de(  .clk(clk), .pb(volDOWN),   .pb_debounced(volDOWN_debounced));
    debounce oct_up_de(    .clk(clk), .pb(higherOCT), .pb_debounced(higherOCT_debounced));
    debounce oct_down_de(  .clk(clk), .pb(lowerOCT),  .pb_debounced(lowerOCT_debounced));

    onepulse vol_up_op(     .clk(clk), .signal(volUP_debounced),       .op(volUP_1p));
    onepulse vol_down_op(   .clk(clk), .signal(volDOWN_debounced),     .op(volDOWN_1p));
    onepulse oct_up_op(     .clk(clk), .signal(higherOCT_debounced),   .op(higherOCT_1p));
    onepulse oct_down_op(   .clk(clk), .signal(lowerOCT_debounced),    .op(lowerOCT_1p));

    always @(posedge clk,posedge rst) begin
        if(rst) begin
            volume<=3'd3;
            octave<=3'd2;
        end else begin
            volume<=volume_next;
            octave<=octave_next;
        end
    end

    //adjust volume,octave
    always @(*) begin
        volume_next=volume;
        octave_next=octave;
        if(volUP_1p) begin
            if(volume==5) begin
                volume_next=5;
            end else begin
                volume_next=volume+1;
            end
        end

        if(volDOWN_1p) begin
            if(volume==1) begin
                volume_next=1;
            end else begin
                volume_next=volume-1;
            end
        end

        if(higherOCT_1p) begin
            if(octave==3) begin
                octave_next=3;
            end else begin
                octave_next=octave+1;
            end
        end

        if(lowerOCT_1p) begin
            if(octave==1) begin
                octave_next=1;
            end else begin
                octave_next=octave-1;
            end
        end
    end

    led_controller lc(
        .clkdiv(led_clk),
        .rst(rst),
        .led(led)
    );
    
    assign led_clk = (slow)? clkDiv25 : clkDiv24;
    assign play_speed = (slow)? clkDiv23 : clkDiv22;

    // Player Control
    // [in]  reset, clock, play, slow, _music, and mode
    // [out] beat number
    player_control #(.LEN(64)) playerCtrl_00 (
        .clk(play_speed),
        .reset(rst),
        .play(play),
        .slow(slow),
        .mode(mode),
        .ibeat(ibeatNum)
    );

    // Music module
    // [in]  beat number and en
    // [out] left & right raw frequency
    music_example music_00 (
        .clk(clk),
        .rst(rst),
        .ibeatNum(ibeatNum),
        .en(mode),
        .toneL(freqL),
        .toneR(freqR),
        .PS2_CLK(PS2_CLK),
        .PS2_DATA(PS2_DATA)
    );

    // freq_outL, freq_outR
    // Note gen makes no sound, if freq_out = 50000000 / `silence = 1
    always @(*) begin
        if(!mode || (mode && play)) begin //user play mode || (demonstrate && play)
            freq_outL = 50000000 / (mute ? `silence : freqL);
            if(octave==1) begin
                freq_outL = 50000000 / (mute ? `silence : freqL/2);
            end else if(octave==2) begin
                freq_outL = 50000000 / (mute ? `silence : freqL);
            end else if(octave==3) begin
                freq_outL = 50000000 / (mute ? `silence : freqL*2);
            end
        end else begin
            freq_outL = 50000000 / `silence;
        end
    end

    always @(*) begin
        if(!mode || (mode && play)) begin    //user play mode || (demonstrate && play)
            freq_outR = 50000000 / (mute ? `silence : freqR);
            if(octave==1) begin
                freq_outR = 50000000 / (mute ? `silence : freqR/2);
            end else if(octave==2) begin
                freq_outR = 50000000 / (mute ? `silence : freqR);
            end else if(octave==3) begin
                freq_outR = 50000000 / (mute ? `silence : freqR*2);
            end
        end else begin
            freq_outR = 50000000 / `silence;
        end
    end




    //7-segment control, freqR = main melody
    /*reg [3:0] num;
    always @(*) begin
        if(!mode || (mode && play)) begin   //user play mode || (demonstrate && play)
            if(freqR == `a || freqR == `ha)
                num = 4'd5;
            else if(freqR == `b || freqR == `hb)
                num = 4'd6;
            else if(freqR == `c || freqR == `hc)
                num = 4'd0;
            else if(freqR == `d || freqR == `hd)
                num = 4'd1;
            else if(freqR == `e || freqR == `he)
                num = 4'd2;
            else if(freqR == `f || freqR == `hf)
                num = 4'd3;
            else if(freqR == `g || freqR == `hg)
                num = 4'd4;
            else if(`sil)
                num = 4'd7;
            else
                num = 4'd7;
        end else begin
            num = 4'd7;
        end
    end*/

    reg [3:0] value;
    always @(posedge display_clk) begin
        case(DIGIT)
            4'b1110: begin
                value=8;
                DIGIT=4'b1101;
            end
            4'b1101: begin
                value=volume;
                DIGIT=4'b1011;
            end
            4'b1011: begin
                value=octave;
                DIGIT=4'b0111;
            end
            4'b0111: begin
                value=8;
                DIGIT=4'b1110;
            end
            default: begin
                value=8;
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
            4'd8: DISPLAY=7'b011_1111;   //-
            default: DISPLAY=7'b111_1111;
        endcase
    end

    // Note generation
    // [in]  processed frequency
    // [out] audio wave signal (using square wave here)
    note_gen noteGen_00(
        .clk(clk), 
        .rst(rst), 
        .volume(volume),
        .note_div_left(freq_outL), 
        .note_div_right(freq_outR), 
        .audio_left(audio_in_left),     // left sound audio
        .audio_right(audio_in_right)    // right sound audio
    );

    // Speaker controller
    speaker_control sc(
        .clk(clk), 
        .rst(rst), 
        .audio_in_left(audio_in_left),      // left channel audio data input
        .audio_in_right(audio_in_right),    // right channel audio data input
        .audio_mclk(audio_mclk),            // master clock
        .audio_lrck(audio_lrck),            // left-right clock
        .audio_sck(audio_sck),              // serial clock
        .audio_sdin(audio_sdin)             // serial audio data input
    );
endmodule