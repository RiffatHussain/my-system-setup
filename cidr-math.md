Think of it like a House Address System
Imagine your IP is like a complete house address:

For Example
95.216.116.101 = Your full house address

But your neighborhood (subnet) is determined by the netmask:

255.255.255.192 = The neighborhood boundary


The Simple 3-Step Process:
Step 1: Focus ONLY on the LAST NUMBER
Your IP: 95.216.116.101
Netmask: 255.255.255.192
Step 2: Remember this ONE rule
Take the last number of your IP (101)
Round it DOWN to the nearest multiple of the last netmask number (192)

101 → rounds down to → 64
How?

192 ÷ 2 = 96 (too high)
192 ÷ 4 = 48 (too low, but close)
So the block size is 64
101 is between 64-127, so it belongs to the 64 block

Step 3: Build your subnet
95.216.116.64/26

Cheat Sheet (Netmask to CIDR):
Last Netmask NumberCIDRBlock Size
0    /24     256
128  /25     128
192  /26     64
224  /27     32
240  /28     16
248  /29     8
252  /30     4
Your case: 192 → /26 → Block size 64

The One Thing to Remember:

Your last IP number determines which "block" you're in. Round it DOWN using the netmask block size.

101 in the 64-block → Network address is 64 → Subnet is 64/26 ✅