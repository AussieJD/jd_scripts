#!/usr/bin/expect
set timeout 2
#set user [lindex $argv 0]
#set password [lindex $argv 1]
set user admin
set password sherw00d
spawn telnet 192.168.1.249

expect "login:"
send "$user\r"

expect "Password:"
send "$password\r"

expect "admin>"
send "voip list callfwdInfo \r"

expect "admin>"
send “35\r”

expect “telnet>”
send “quit\r”

expect eof
