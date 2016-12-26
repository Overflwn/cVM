# cVM
"Virtual Machine"-core for ComputerCraft. May or may not be finished


# How to use:
```
vmcore.lua
```
To get usage info.

# Important in this specific build
This version uses a "virtual" filesystem, using inodes
The problem currently is:
(Not hard to fix:) No deleting, I'll need to iterate through every folder containing a link to the file
(Maybe pretty hard:) No opening files in binarymode, idk if people even use it...
Some extra bugs I didn't find..

A bios file doesn't have to exist all the time!
You can make one, inject it, and then delete it :)

Please open up new issues on GitHub if you found any bugs (or post them in the forum :) )

Have fun!