dnslinter - A DNS consistency checker
=====================================

This tool allows you to easily spot DNS consistency errors.  Given an IP range,
or set of IP ranges, it will compare forward and reverse DNS entries and point
out mismatches.  It can also, optionally, use ping to find hosts with no
forward DNS present.


```
:~$ sudo ./dnslinter -n 10.19.41.0/24 -p -s
FAIL: 10.19.41.2 responds to pings but has no PTR.
FAIL: 10.19.41.110 responds to pings but has no PTR.
Summary: 254 IPs tested, 202 okay, 2 errors, 187 pingable, 67 unpingable.

```
