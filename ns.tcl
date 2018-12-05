set ns [new Simulator]
set nf [open out.nam w]
set f1 [open out1.tr w]
set f2 [open out2.tr w]
$ns trace-all $nf
$ns namtrace-all $nf
set src1 [$ns node]
set src2 [$ns node]
set R1 [$ns node]
set R2 [$ns node]
set rcv1 [$ns node]
set rcv2 [$ns node]
set thruput1 0
set thruput2 0
set counter 0
global delay
set delay "12.5ms"
set flav "Sack1"

$ns duplex-link $R1 $R2 1.0Mb 5ms DropTail
$ns duplex-link $src1 $R1 10.0Mb 5ms DropTail  
$ns duplex-link $rcv1 $R2 10.0Mb 5ms DropTail  
$ns duplex-link $src2 $R1 10.0Mb $delay DropTail  
$ns duplex-link $rcv2 $R2 10.0Mb $delay DropTail
set tcp1 [new Agent/TCP/$flav]
set tcp2 [new Agent/TCP/$flav]
$ns attach-agent $src1 $tcp1
$ns attach-agent $src2 $tcp2
$tcp1 set class_ 1
$tcp2 set class_ 2
set ftp1 [new Application/FTP]
set ftp2 [new Application/FTP]
$ftp1 attach-agent $tcp1
$ftp2 attach-agent $tcp2
set sink1 [new Agent/TCPSink]
set sink2 [new Agent/TCPSink]
$ns attach-agent $rcv1 $sink1
$ns attach-agent $rcv2 $sink2
$ns connect $tcp1 $sink1
$ns connect $tcp2 $sink2

proc finish {} {
global ns nf
$ns flush-trace
close $nf
exec nam out.nam &
exit 0
}
proc record {} {
# writes the data to the output files
global sink1 sink2 f1 f2 thruput1 thruput2 counter
# get an instance of the simulator
set ns [Simulator instance]
# set the time after which the procedure would be called again
set time 0.5
# how many bytes have been received by the traffic sinks?
set bw1 [$sink1 set bytes_]
set bw2 [$sink2 set bytes_]
# get the current time
set now [$ns now]
# calculate bandwidth in Mbit/s and write it to the files
puts $f1 "$now [expr $bw1/$time*8/1000000]"
puts $f2 "$now [expr $bw2/$time*8/1000000]"
set thruput1 [expr $thruput1+ $bw1/$time*8/1000000 ]
set thruput2 [expr $thruput2+ $bw2/$time*8/1000000 ]
set counter [expr $counter + 1]
# reset the bytes_ values on the traffic sinks
$sink1 set bytes_ 0
$sink2 set bytes_ 0
#Re-schedule the procedure
$ns at [expr $now+$time] "record"
}
$ns at 0 "record"
$ns at 0 "$ftp1 start"
$ns at 0 "$ftp2 start"
$ns at 400 "$ftp1 stop"
$ns at 400 "$ftp2 stop"
$ns at 400 "finish"
$ns run
