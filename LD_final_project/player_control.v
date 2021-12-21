module player_control (
	input clk, 
	input reset, 
	input play, 
	input slow, 
	input mode, 
	output reg [11:0] ibeat
);
	parameter LEN = 4095;
    reg [11:0] next_ibeat;

	always @(posedge clk, posedge reset) begin
		if (reset) begin
			ibeat <= 0;
		end else begin
            ibeat <= next_ibeat;
		end
	end

    always @* begin
		next_ibeat=ibeat;
		if(!play || !mode) begin	//pause || user play mode
			next_ibeat = ibeat;
		end else begin
			next_ibeat = (ibeat + 1 < LEN) ? (ibeat + 1) : 0;
		end
    end

endmodule
