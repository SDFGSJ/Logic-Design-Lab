module top(
    input clk,
    input rst,      // BTNC
    input play,     // BTNU: play/pause
    input speedup,  // BTNR
    input speeddown,// BTNL
    input loop, //temp loop effect
    inout PS2_DATA,
    inout PS2_CLK,
    input [15:0] sw,
    output [15:0] led,
    output audio_mclk, // master clock
    output audio_lrck, // left-right clock
    output audio_sck,  // serial clock
    output audio_sdin, // serial audio data input
    output [6:0] DISPLAY,
    output [3:0] DIGIT
);
    // Internal Signal
    wire [15:0] audio_in_left, audio_in_right;
    wire [11:0] ibeatNum;               // Beat counter
    wire [31:0] freqL, freqR;           // Raw frequency, produced by music module
    reg [21:0] freq_outL, freq_outR;    // Processed frequency, adapted to the clock rate of Basys3

    //clocks
    wire play_clk;    //for playing music
    wire display_clk;   //for 7 segment
    clock_divider #(.n(13)) display(.clk(clk), .clk_div(display_clk));  //7-segment display

    wire [2:0] volume, octave;
    wire play_pause;
    wire play_debounced, loop_debounced;    //loop only have debounced
    wire play_1p;
    debounce play_or_pause_de(.clk(clk), .pb(play), .pb_debounced(play_debounced));
    debounce loop_de(.clk(clk), .pb(loop), .pb_debounced(loop_debounced));
    onepulse play_or_pause_op(.clk(clk), .signal(play_debounced), .op(play_1p));


    //[in] clk, rst, play_1p
    //[out] play_pause
    play_pause_controller playPauseCtrl(
        .clk(clk),
        .rst(rst),
        .play_1p(play_1p),
        .play_or_pause(play_pause)
    );


    //debounce, onepulse inside this module
    //[in] clk, rst, speedup, speeddown
    //[out] play_clk
    speed_controller speedCtrl(
        .clk(clk),
        .rst(rst),
        .speedup(speedup),
        .speeddown(speeddown),
        .play_clk(play_clk)
    );


    //[in] clk, rst, play_pause, loop_debounced
    //[out] beat number
    player_control #(.LEN(64)) playerCtrl(
        .clk(play_clk),
        .reset(rst),
        .play_pause(play_pause),
        .loop_de(loop_debounced),
        .ibeat(ibeatNum)
    );


    //Music module
    //[in]  beat number, play_pause, sw
    //[out] left & right raw frequency, led
    music_example musicExCtrl(
        .clk(clk),
        .rst(rst),
        .ibeatNum(ibeatNum),
        .en(play_pause),
        .switch(sw),
        .toneL(freqL),
        .toneR(freqR),
        .led(led)
    );


    //[in] clk, rst, PS2_CLK, PS2_DATA
    //[out] volume, octave
    volume_octave_controller volOctCtrl(
        .clk(clk),
        .rst(rst),
        .PS2_CLK(PS2_CLK),
        .PS2_DATA(PS2_DATA),
        .volume(volume),
        .octave(octave)
    );


    // freq_outL, freq_outR
    // Note gen makes no sound, if freq_out = 50000000 / `silence = 1
    always @(*) begin
        freq_outL = 50000000 / freqL;
        if(octave==1) begin
            freq_outL = 50000000 / (freqL/2);
        end else if(octave==2) begin
            freq_outL = 50000000 / freqL;
        end else if(octave==3) begin
            freq_outL = 50000000 / (freqL*2);
        end
    end

    always @(*) begin
        freq_outR = 50000000 / freqR;
        if(octave==1) begin
            freq_outR = 50000000 / (freqR/2);
        end else if(octave==2) begin
            freq_outR = 50000000 / freqR;
        end else if(octave==3) begin
            freq_outR = 50000000 / (freqR*2);
        end
    end

    //[in] display_clk, volume, octave
    //[out] DIGIT, DISPLAY
    seven_segment_controller sevenSegCtrl(
        .display_clk(display_clk),
        .volume(volume),
        .octave(octave),
        .DIGIT(DIGIT),
        .DISPLAY(DISPLAY)
    );


    // Note generation
    // [in]  processed frequency
    // [out] audio wave signal (using square wave here)
    note_gen noteGen(
        .clk(clk), 
        .rst(rst), 
        .volume(volume),
        .note_div_left(freq_outL), 
        .note_div_right(freq_outR), 
        .audio_left(audio_in_left),     // left sound audio
        .audio_right(audio_in_right)    // right sound audio
    );


    // Speaker controller
    speaker_control speakerCtrl(
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