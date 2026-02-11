#nmap staging - work in progress

###################################################
# this file will stage different nmap scans against a target so i don't have to keep doing scans manually
###################################################

# pseudo-code
# ask for IP address/range $IP
# ask for timing integer $T = '-T$T'
# 
# then do `nmap $IP -n -Pn -T$T`
# save available IP addresses in IPs.txt
# then do `nmap IPs.txt -n -Pn -p- -T$T`
# save IP/port parings in IP-ports.txt
# then do `nmap IPs.txt -n -Pn -p ports.txt -sCV`
# and print results to the screen and/or output file 
# 
# 
# atleast, that's the idea about it. i always end up running these types of commands in stages and i'd 
# rather just be able to fire off a script that asks for the IP range and timing (-T4 for vm's, -T1 or -T2 for live environments)
# instead of always having to do this manually
# 
# 
# 
