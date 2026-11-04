# activate waveform simulation

view wave

# format signal names in waveform

configure wave -signalnamewidth 1
configure wave -timeline 0
configure wave -timelineunits ns

# add signals to waveform

add wave -divider -height 20 {}
add wave -bin UUT/CLOCK_50_I
add wave -bin UUT/resetn

add wave -divider -height 10 {}
add wave -bin UUT/PC_clear
add wave -bin UUT/PC_load
add wave -bin UUT/PC_inc
add wave -hex UUT/PC_load_value

add wave -divider -height 10 {}
add wave -hex UUT/PC_out
add wave -hex expected_PC
add wave -uns number_of_mismatches
