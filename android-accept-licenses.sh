#!/usr/bin/expect -f

set timeout 1800
set cmd [lindex $argv 0]
set licenses [lindex $argv 1]

spawn {*}$cmd
expect {
    "License" {
        log_user 0
        exp_continue
    }
    "Do you accept the license '*'*" {
        log_user 1
        exp_send "y\r"
        exp_continue
    }
    "Accept? (y/N):" {
        log_user 1
        exp_send "y\r"
        exp_continue
    }
    eof
}

lassign [wait] pid spawnid os_error_flag value

if {$os_error_flag == 0} {
    if {$value != 0} {
        puts "exit status: $value"
        exit $value
    }
} else {
    puts "errno: $value"
    exit 1
}
