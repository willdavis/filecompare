filecompare
===========
recursively hexdump and compare two files (including sub-files)

How it works!
-------------
* fcomp.asm handles the file streams and main program flow.
* treewalker.asm recursively steps through the directory structure. (http://linux.die.net/man/3/ftw)
* hexdump.asm uses fgetc() to grab a character from each file and compares them.

This was my final project for CMPE102 (Assembly Language Programming) at San Jose State.
