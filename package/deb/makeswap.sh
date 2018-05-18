#!/bin/sh
# Credits to Gary Stafford
# Source: https://gist.githubusercontent.com/garystafford/8050220/raw/6eb0aee9eb4c9d4557e0079e4870c5170da8134a/create_swap.sh

# size of swapfile in megabytes
swapsize=512

# does the swap file already exist?
grep -q "swapfile" /etc/fstab

# if not then create it
if [ $? -ne 0 ]; then
	echo 'swapfile not found. Adding swapfile.'
	fallocate -l ${swapsize}M /swapfile
	chmod 600 /swapfile
	mkswap /swapfile
	swapon /swapfile
	echo '/swapfile none swap defaults 0 0' >> /etc/fstab
else
	echo 'swapfile found. No changes made.'
fi

# output results to terminal
cat /proc/swaps
cat /proc/meminfo | grep Swap
