# Z0rbputerCraft


Set of Lua libraries and scripts to automate operations with ComputerCraft-based scripts.


The filesystem structure is a rudimentary version of what you'd find in a unix system:

/lib contains custom APIs (the "libraries")
/bin contains the programs.

The startup file adds /bin to the path, removes "." from the path and runs /startup.local




Installation/update:


If it is the initial installation you're doing, then run
wget https://raw.githubusercontent.com/z0rb1n0/Z0rbputerCraft/master/update_zc /update_zc



From the CC console:
/update_zc




reboot (or run /startup if you don't feel like rebooting)

