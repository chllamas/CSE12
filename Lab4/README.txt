Christopher Llamas
chllamas
Winter 2020
Lab 4: Syntax Checker

-----------------
Description

This lab is involved developing a simple syntax checker that
opens a file and determines whether it has balanced braces, 
brackets, and parantheses.  It uses stacks to check the 
balance and report either the location of a mismatch or the
number of matched items on success.

-----------------
Files

-
Lab4.asm

This file is the saved .asm from MARS that contains the source
code for the program as well as the pseudocode documentation.

-
test1.txt

Test file for Lab4.asm; tests lots of spaces between the braces.
Should successfully end.

-
test2.txt

Test file for Lab4.asm; tests having a ton of braces leftover
in the stack at the end of the file.

-
test3.txt

Test file for Lab4.asm; tests having a mismatched brace far
from the index of the first open brace.

-------------------
Instructions

The program can be opened using MARS.  In order to run, enter
a textfile name into the Program Arguments line.  The filename
must be no more than 20 characters, and have valid ASCII chars
(letters, numbers, period, and underscore) as well as start
with a letter.
