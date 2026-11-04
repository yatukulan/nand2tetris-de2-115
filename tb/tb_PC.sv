/*
Hack computer on the DE2-115 - Program Counter testbench
Self-checking: a behavioural reference model runs beside the DUT and
every cycle is compared on the falling edge
*/

`timescale 1ns/100ps
`default_nettype none

module tb_PC;

	logic clock_50;
	logic resetn;

	logic PC_clear, PC_load, PC_inc;
	logic [14:0] PC_load_value;
	logic [14:0] PC_out;

	logic [14:0] expected_PC;
	int number_of_mismatches;
	int number_of_checks;

	// unit under test
	PC UUT (
		.CLOCK_50_I(clock_50),
		.resetn(resetn),
		.PC_clear(PC_clear),
		.PC_load(PC_load),
		.PC_inc(PC_inc),
		.PC_load_value(PC_load_value),
		.PC_out(PC_out)
	);

	// 50 MHz clock
	always begin
		#10;
		clock_50 = ~clock_50;
	end

	// reference model: same priority as nand2tetris PC.hdl
	always @ (posedge clock_50 or negedge resetn) begin
		if (resetn == 1'b0) expected_PC <= 15'd0;
		else if (PC_clear) expected_PC <= 15'd0;
		else if (PC_load) expected_PC <= PC_load_value;
		else if (PC_inc) expected_PC <= expected_PC + 15'd1;
	end

	// checker: sample in the middle of the low phase
	always @ (negedge clock_50) begin
		if (resetn) begin
			number_of_checks++;
			if (PC_out !== expected_PC) begin
				number_of_mismatches++;
				$write("Mismatch at %t: PC_out = %h, expected = %h\n", $realtime, PC_out, expected_PC);
			end
		end
	end

	// drive one cycle of control inputs; inputs change on the falling edge
	task automatic drive(input logic clr, input logic ld, input logic inc, input logic [14:0] val);
		@(negedge clock_50);
		PC_clear = clr;
		PC_load = ld;
		PC_inc = inc;
		PC_load_value = val;
	endtask

	initial begin
		$dumpfile("tb_PC.vcd");
		$dumpvars(0, tb_PC);

		clock_50 = 1'b0;
		resetn = 1'b0;
		PC_clear = 1'b0;
		PC_load = 1'b0;
		PC_inc = 1'b0;
		PC_load_value = 15'd0;
		number_of_mismatches = 0;
		number_of_checks = 0;

		repeat (2) @(negedge clock_50);
		resetn = 1'b1;

		// ---- directed tests (these are the cycles shown in the waveform) ----
		drive(0, 0, 1, 15'h0000);  // inc        0 -> 1
		drive(0, 0, 1, 15'h0000);  // inc        1 -> 2
		drive(0, 0, 1, 15'h0000);  // inc        2 -> 3
		drive(0, 0, 0, 15'h0000);  // hold       3
		drive(0, 1, 0, 15'h0010);  // load       -> 0x0010
		drive(0, 0, 1, 15'h0000);  // inc        -> 0x0011
		drive(0, 1, 1, 15'h0040);  // load + inc -> load wins: 0x0040
		drive(1, 1, 1, 15'h0055);  // clr + load + inc -> clear wins: 0
		drive(0, 1, 0, 15'h7FFF);  // load       -> 0x7FFF
		drive(0, 0, 1, 15'h0000);  // inc        -> wraps to 0
		drive(0, 0, 0, 15'h0000);  // hold

		// asynchronous reset in the middle of a run
		drive(0, 1, 0, 15'h1234);
		drive(0, 0, 1, 15'h0000);
		#3 resetn = 1'b0;
		#5 if (PC_out !== 15'd0) begin
			number_of_mismatches++;
			$write("Mismatch: async reset did not clear PC (PC_out = %h)\n", PC_out);
		end
		@(negedge clock_50);
		resetn = 1'b1;

		// ---- random tests, weighted like a running program (mostly inc) ----
		repeat (5000) begin
			drive(($urandom % 64) == 0,
			      ($urandom % 4) == 0,
			      ($urandom % 4) != 0,
			      $urandom);
		end

		drive(0, 0, 0, 15'h0000);
		@(negedge clock_50);

		$write("\nPC testbench: %0d checks, %0d mismatches\n", number_of_checks, number_of_mismatches);
		if (number_of_mismatches == 0) $write("PASS\n");
		else $write("FAIL\n");
		$stop;
	end

endmodule
