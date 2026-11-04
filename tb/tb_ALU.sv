/*
Hack computer on the DE2-115 - ALU testbench

Part 1, directed: the 18 Hack comp codes, checked against what they MEAN
        (D+1, A-D, D|A ...) using plain integer arithmetic, not the
        zx/nx/zy/ny/f/no recipe. This is the independent check.
Part 2, exhaustive: all 64 control-bit combinations x (corner pairs +
        random pairs), checked against a bit-level reference model.
Part 3, waveform: a short sequence (x = 7, y = 3) for the timing view.
*/

`timescale 1ns/100ps
`default_nettype none

module tb_ALU;

	logic [15:0] ALU_x, ALU_y;
	logic [5:0] control;            // {zx, nx, zy, ny, f, no} = instruction[11:6]
	logic [15:0] ALU_out;
	logic zr, ng;

	int number_of_mismatches;
	int number_of_checks;

	logic [15:0] corner_values [0:11];

	ALU UUT (
		.ALU_x(ALU_x),
		.ALU_y(ALU_y),
		.zx(control[5]),
		.nx(control[4]),
		.zy(control[3]),
		.ny(control[2]),
		.f(control[1]),
		.no(control[0]),
		.ALU_out(ALU_out),
		.zr(zr),
		.ng(ng)
	);

	// compare outputs and flags with an expected value
	task automatic check(input logic [15:0] expected, input string what);
		#1;
		number_of_checks++;
		if (ALU_out !== expected || zr !== (expected == 16'd0) || ng !== expected[15]) begin
			number_of_mismatches++;
			$write("Mismatch %s: control %b x %h y %h -> out %h zr %b ng %b, expected %h\n",
				what, control, ALU_x, ALU_y, ALU_out, zr, ng, expected);
		end
	endtask

	// bit-level reference model of the nand2tetris ALU
	function automatic logic [15:0] reference(input logic [5:0] c, input logic [15:0] x, input logic [15:0] y);
		logic [15:0] xx, yy, r;
		xx = c[5] ? 16'h0000 : x;
		if (c[4]) xx = ~xx;
		yy = c[3] ? 16'h0000 : y;
		if (c[2]) yy = ~yy;
		r = c[1] ? (xx + yy) : (xx & yy);
		if (c[0]) r = ~r;
		return r;
	endfunction

	// the 18 documented Hack computations, by meaning (x = D, y = A)
	task automatic check_named(input logic [15:0] x, input logic [15:0] y);
		ALU_x = x;
		ALU_y = y;
		control = 6'b101010; check(16'd0,         "0");
		control = 6'b111111; check(16'd1,         "1");
		control = 6'b111010; check(-16'sd1,       "-1");
		control = 6'b001100; check(x,             "D");
		control = 6'b110000; check(y,             "A");
		control = 6'b001101; check(~x,            "!D");
		control = 6'b110001; check(~y,            "!A");
		control = 6'b001111; check(-x,            "-D");
		control = 6'b110011; check(-y,            "-A");
		control = 6'b011111; check(x + 16'd1,     "D+1");
		control = 6'b110111; check(y + 16'd1,     "A+1");
		control = 6'b001110; check(x - 16'd1,     "D-1");
		control = 6'b110010; check(y - 16'd1,     "A-1");
		control = 6'b000010; check(x + y,         "D+A");
		control = 6'b010011; check(x - y,         "D-A");
		control = 6'b000111; check(y - x,         "A-D");
		control = 6'b000000; check(x & y,         "D&A");
		control = 6'b010101; check(x | y,         "D|A");
	endtask

	initial begin
		$dumpfile("tb_ALU.vcd");
		$dumpvars(0, tb_ALU);

		number_of_mismatches = 0;
		number_of_checks = 0;
		corner_values[0]  = 16'h0000;  corner_values[1]  = 16'h0001;
		corner_values[2]  = 16'hFFFF;  corner_values[3]  = 16'h7FFF;
		corner_values[4]  = 16'h8000;  corner_values[5]  = 16'h8001;
		corner_values[6]  = 16'h5555;  corner_values[7]  = 16'hAAAA;
		corner_values[8]  = 16'h00FF;  corner_values[9]  = 16'hFF00;
		corner_values[10] = 16'h0007;  corner_values[11] = 16'h0003;

		// ---- part 3 first, so the waveform starts at time 0 ----
		ALU_x = 16'd7;
		ALU_y = 16'd3;
		control = 6'b000010; #20;   // D+A = 10
		control = 6'b010011; #20;   // D-A = 4
		control = 6'b000111; #20;   // A-D = -4 (ng)
		control = 6'b000000; #20;   // D&A = 3
		control = 6'b010101; #20;   // D|A = 7
		control = 6'b001111; #20;   // -D  = -7 (ng)
		control = 6'b011111; #20;   // D+1 = 8
		control = 6'b101010; #20;   // 0   (zr)

		// ---- part 1: named computations ----
		for (int i = 0; i < 12; i++)
			for (int j = 0; j < 12; j++)
				check_named(corner_values[i], corner_values[j]);
		repeat (200) check_named($urandom, $urandom);

		// ---- part 2: exhaustive over the 64 control combinations ----
		for (int c = 0; c < 64; c++) begin
			control = c;
			for (int i = 0; i < 12; i++) begin
				for (int j = 0; j < 12; j++) begin
					ALU_x = corner_values[i];
					ALU_y = corner_values[j];
					check(reference(control, ALU_x, ALU_y), "exhaustive");
				end
			end
			repeat (100) begin
				ALU_x = $urandom;
				ALU_y = $urandom;
				check(reference(control, ALU_x, ALU_y), "exhaustive");
			end
		end

		$write("\nALU testbench: %0d checks, %0d mismatches\n", number_of_checks, number_of_mismatches);
		if (number_of_mismatches == 0) $write("PASS\n");
		else $write("FAIL\n");
		$stop;
	end

endmodule
