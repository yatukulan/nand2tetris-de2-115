# activate waveform simulation

view wave

# format signal names in waveform

configure wave -signalnamewidth 1
configure wave -timeline 0
configure wave -timelineunits ns

# add signals to waveform

add wave -divider -height 20 {}
add wave -bin control
add wave -hex ALU_x
add wave -hex ALU_y

add wave -divider -height 10 {}
add wave -hex ALU_out
add wave -dec ALU_out
add wave -bin zr
add wave -bin ng

add wave -divider -height 10 {}
add wave -uns number_of_checks
add wave -uns number_of_mismatches
