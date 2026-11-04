
# ---- RTL (add every new rtl file here AND in ../syn/hack_computer.qsf) ----
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/PC.sv

# ---- testbenches ----
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $tb/tb_PC.sv
