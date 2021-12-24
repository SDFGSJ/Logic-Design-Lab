module player_control (
	input clk, 
	input reset,
	input play_pause,
	input loop_de,
	output reg [11:0] ibeat
);
	parameter LEN = 4095;
    reg [11:0] next_ibeat;
	reg [11:0] bound, bound_next;

	always @(posedge clk, posedge reset) begin
		if (reset) begin
			ibeat <= 0;
			bound <= 0;
		end else begin
            ibeat <= next_ibeat;
			bound <= bound_next;
		end
	end

	/*
	looping idea:
		once pressed the loop button, variable 'bound' will record the upper bound of current ibeat,
		and ibeat will immediately jump 4 notes to the front, then ibeat increase by 1 as usual.
		When ibeat == bound, ibeat will jump 4 notes to the front again...so on and so forth.
		(notice that this effect doesnt work on the rightmost three leds, since we jumps 4 notes)

	always update 'bound' when not pressing loop button
	once the loop button is pressed, we can directly use this information
	*/
    always @* begin
		next_ibeat = ibeat;
		bound_next = bound;
		if(play_pause) begin	//play
			if(!loop_de) begin
				next_ibeat = (ibeat + 1 < LEN) ? (ibeat + 1) : 0;
				bound_next = (ibeat + 1 < LEN) ? (ibeat + 3 - (ibeat%4)) : 0;	//check the boundary case, (ibeat + 3 - (ibeat%4)) is the upper bound of the current ibeat
			end else begin
				if(ibeat < 12 || ibeat != bound) begin
					next_ibeat = (ibeat + 1 < LEN) ? (ibeat + 1) : 0;
				end else begin
					next_ibeat = ibeat-15;	//when reaching the bound, go back 4 notes(ex. from ibeat = 63 -> 48)
				end
			end
			
		end
    end

endmodule
