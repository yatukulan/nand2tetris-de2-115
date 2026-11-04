set rtl ../rtl
set tb ../tb
set sim .

# select the testbench to run, e.g.  set top tb_ALU ; do run.do
# testbenches: tb_PC (more are added commit by commit)
if {![info exists top]} {
	set top tb_PC
}

onbreak {resume}

transcript on

if {[file exists my_work]} {
	vdel -lib my_work -all
}

vlib my_work
vmap work my_work
