`define c   32'd262   // C3
`define d   32'd294
`define e   32'd330
`define f   32'd349
`define g   32'd392   // G3
`define a   32'd440
`define b   32'd494   // B3
`define hc  32'd524   // C4 524
`define hd  32'd588   // D4 588
`define he  32'd660   // E4 660
`define hf  32'd698   // F4 698
`define hg  32'd784   // G4
`define ha  32'd880
`define hb  32'd988
`define sil   32'd50000000
`define silence   32'd50000000

module lab8(
    clk,        // clock from crystal
    rst,        // BTNC: active high reset
    _play,      // SW0: Play/Pause
    _mute,      // SW1: Mute
    _slow,      // SW2: Slow
    _music,     // SW3: Music
    _mode,      // SW15: Mode
    _volUP,     // BTNU: Vol up
    _volDOWN,   // BTND: Vol down
    _higherOCT, // BTNR: Oct higher
    _lowerOCT,  // BTNL: Oct lower
    PS2_DATA,   // Keyboard I/O
    PS2_CLK,    // Keyboard I/O
    _led,       // LED: [15:13] octave & [4:0] volume
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
    input _play, _mute, _slow, _music, _mode; 
    input _volUP, _volDOWN, _higherOCT, _lowerOCT; 
    inout PS2_DATA; 
	inout PS2_CLK; 
    output [15:0] _led; 
    output audio_mclk; 
    output audio_lrck; 
    output audio_sck; 
    output audio_sdin; 
    output reg [6:0] DISPLAY; 
    output reg [3:0] DIGIT; 
    
    // Modify these
    assign _led = 16'b1110_0000_0001_1111;
    /*assign DIGIT = 4'b0000;
    assign DISPLAY = 7'b0111111;*/

    // Internal Signal
    wire [15:0] audio_in_left, audio_in_right;

    wire [11:0] ibeatNum;               // Beat counter
    wire [31:0] freqL, freqR;           // Raw frequency, produced by music module
    wire [21:0] freq_outL, freq_outR;    // Processed frequency, adapted to the clock rate of Basys3

    // clkDiv22
    wire clkDiv22, display_clk;
    clock_divider #(.n(22)) clock_22(.clk(clk), .clk_div(clkDiv22));    // for keyboard and audio
    clock_divider #(.n(13)) display(.clk(clk), .clk_div(display_clk));  //7-segment display

    // Player Control
    // [in]  reset, clock, _play, _slow, _music, and _mode
    // [out] beat number
    player_control #(.LEN(512)) playerCtrl_00 ( 
        .clk(clkDiv22),
        .reset(rst),
        ._play(1'b1),
        ._slow(1'b0), 
        ._mode(1'b0),
        .ibeat(ibeatNum)
    );

    // Music module
    // [in]  beat number and en
    // [out] left & right raw frequency
    music_example music_00 (
        .ibeatNum(ibeatNum),
        .en(1'b1),
        .toneL(freqL),
        .toneR(freqR)
    );

    // freq_outL, freq_outR
    // Note gen makes no sound, if freq_out = 50000000 / `silence = 1
    assign freq_outL = 50000000 / freqL;
    assign freq_outR = 50000000 / freqR;

    reg [3:0] num;
    always @(*) begin
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
    end

    //7-segment control
    reg [3:0] value;
    always @(posedge display_clk) begin
        case(DIGIT)
            4'b1110: begin
                value=7;
                DIGIT=4'b1101;
            end
            4'b1101: begin
                value=7;
                DIGIT=4'b1011;
            end
            4'b1011: begin
                value=7;
                DIGIT=4'b0111;
            end
            4'b0111: begin
                value=num;
                DIGIT=4'b1110;
            end
            default: begin
                value=7;
                DIGIT=4'b1110;
            end
        endcase
    end
    always @(*) begin
        case(value) //0 means on,1 means off(GFEDCBA)
            4'd0: DISPLAY=7'b0100111;   //C
            4'd1: DISPLAY=7'b0100001;   //D
            4'd2: DISPLAY=7'b0000110;   //E
            4'd3: DISPLAY=7'b0001110;   //F
            4'd4: DISPLAY=7'b1000010;   //G
            4'd5: DISPLAY=7'b0100000;   //A
            4'd6: DISPLAY=7'b0000011;   //B
            4'd7: DISPLAY=7'b0111111;   //-
            default: DISPLAY=7'b1111111;
        endcase
    end




    // Note generation
    // [in]  processed frequency
    // [out] audio wave signal (using square wave here)
    note_gen noteGen_00(
        .clk(clk), 
        .rst(rst), 
        .volume(3'b000),
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