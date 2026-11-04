/*
Hack computer on the DE2-115 - Program Counter
Functional spec: nand2tetris PC.hdl (priority: reset > load > inc)
*/

`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

// 15-bit program counter
// Its output drives the address port of the instruction ROM (32K x 16)
// The control FSM decides when it moves: PC_inc once per instruction,
// PC_load when a jump is taken, PC_clear to restart the program
module PC (
	input logic CLOCK_50_I,                 // 50 MHz clock
	input logic resetn,                     // asynchronous active-low reset (power-up)

	input logic PC_clear,                   // synchronous restart, highest priority
	input logic PC_load,                    // jump taken: PC <= PC_load_value
	input logic PC_inc,                     // next instruction: PC <= PC + 1
	input logic [14:0] PC_load_value,       // jump target, A[14:0]

	output logic [14:0] PC_out              // to instruction ROM address
);

// Hardware inferred:
//   15 flip-flops with asynchronous clear (resetn)
//   15-bit incrementer (+1 on the carry chain)
//   2:1 mux selecting PC_load_value or PC_out + 1
//   synchronous clear and a clock enable (PC_clear | PC_load | PC_inc)
// In a Cyclone IV LE this maps onto the register's sclr / sload / ena
// inputs, so the whole counter is about one LE per bit
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		PC_out <= 15'd0;
	end else begin
		if (PC_clear) begin
			PC_out <= 15'd0;
		end else if (PC_load) begin
			PC_out <= PC_load_value;
		end else if (PC_inc) begin
			PC_out <= PC_out + 15'd1;
		end
		// no enable asserted: PC_out holds its value
	end
end

endmodule
