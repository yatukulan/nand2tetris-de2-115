/*
Hack computer on the DE2-115 - ALU
Functional spec: nand2tetris ALU (zx, nx, zy, ny, f, no; flags zr, ng)
COMPENG 3DQ5 coding rules
*/

`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

// Purely combinational. In the CPU: ALU_x = D, ALU_y = A or M,
// control bits = instruction[11:6] (c1..c6)
module ALU (
	input logic [15:0] ALU_x,
	input logic [15:0] ALU_y,

	input logic zx,                 // zero x
	input logic nx,                 // invert x
	input logic zy,                 // zero y
	input logic ny,                 // invert y
	input logic f,                  // 1: x + y, 0: x & y
	input logic no,                 // invert out

	output logic [15:0] ALU_out,
	output logic zr,                // ALU_out == 0
	output logic ng                 // ALU_out < 0
);

logic [15:0] x_zeroed, x_final;
logic [15:0] y_zeroed, y_final;
logic [15:0] f_result;

// Input conditioning, both operands in parallel
// Hardware: zero = 16 AND gates (x & ~zx), invert = 16 XOR gates (x ^ nx)
assign x_zeroed = zx ? 16'd0 : ALU_x;
assign x_final = nx ? ~x_zeroed : x_zeroed;

assign y_zeroed = zy ? 16'd0 : ALU_y;
assign y_final = ny ? ~y_zeroed : y_zeroed;

// Function select
// Hardware: 16-bit adder on the carry chain, 16 AND gates, 16 2:1 muxes
always_comb begin
	if (f) begin
		f_result = x_final + y_final;
	end else begin
		f_result = x_final & y_final;
	end
end

// Output conditioning and flags
// Hardware: 16 XOR gates (no), 16-input NOR tree for zr, ng is a wire
assign ALU_out = no ? ~f_result : f_result;
assign zr = (ALU_out == 16'd0);
assign ng = ALU_out[15];

endmodule
