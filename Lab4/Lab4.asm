#Lab4.asm
#Christopher Llamas, chllamas, CSE12
#
#
#Print first two lines of output ("You entered the file:\n[input here]")
#CheckFirstByte
#	If byte is not within 65 and 90, or 97 and 122, then shoot error and exit
#	Continue to EvaluateInput
#EvaluateInput
#	LoopString
#	If invalid character, exit
#	If valid character, continue to AccessFile
#AccessFile
#	Open file
#	Read from file using $v0 from OpenFile arg
#	BufferLoop
#		Shoot readfromfile arg
#		BufferReadLoop
#			If open brace, push
#			If close brace, pop
#				If popped brace does not match current brace, shoot error exit
#				If empty stack, shoot error exit
#	BufferLoopEnd
#	Continue to FinalCheck
#FinalCheck
#If stack is not empty, shoot error exit
#Exit program safely
.text
main:
la $s0, ($a1) #s0 now carries the array address
li $s1, 0 #s1 holds the number of correct braces

la $a0, Msg_Intro
li $v0, 4
syscall

la $a0, NewLine
li $v0, 4
syscall

beqz $s0, PrintNothing
lw $t0, ($s0)
la $a0, ($t0)
li $v0, 4
syscall

PrintNothing:
la $a0, NewLine
li $v0, 4
syscall

la $a0, NewLine
li $v0, 4
syscall

# [65-90] or [97-122]
CheckFirstByte:
beqz $s0, InvalidArgument
lw $t1, ($s0)
lb $t0, ($t1) #t0 now has the first char
 	# evaluate the char
	# Is it a UpperCase?
sge $t1, $t0, 65
sle $t2, $t0, 90
and $t3, $t1, $t2
beq $t3, 1, EvaluateInput
	# Is it a LowerCase?
sge $t1, $t0, 97
sle $t2, $t0, 122
and $t3, $t1, $t2
beq $t3, 1, EvaluateInput
	j InvalidArgument # shoot error

# len<=20 AND ([65-90] or [97-122] or [48-75] or 95 or 46)
EvaluateInput:
li $t2, 0 #t0 is the charCount
li $t3, 0 #wordindex offset
	EI_LoopA:
		li $t4, 0
		lw $t0, ($s0)
		add $t0, $t0, $t3	#word + wordoffset
		add $t3, $t3, 4	#wordindex + 4
		j EI_LoopB

	EI_LoopB:
		lb $t1, ($t0)
			# Is it a UpperCase?
		sge $t5, $t1, 65
		sle $t6, $t1, 90
		and $t7, $t5, $t6
		beq $t7, 1, EI_LoopB_Cont
			# Is it a LowerCase?
		sge $t5, $t1, 97
		sle $t6, $t1, 122
		and $t7, $t5, $t6
		beq $t7, 1, EI_LoopB_Cont
			# Is it a Number?
		sge $t5, $t1, 48
		sle $t6, $t1, 75
		and $t7, $t5, $t6
		beq $t7, 1, EI_LoopB_Cont
			# Is it a .?
		beq $t1, 95, EI_LoopB_Cont
		beq $t1, 46, EI_LoopB_Cont
			# Is it the end?
		beq $t1, 0, AccessFile
			j InvalidArgument
	EI_LoopB_Cont:
		addi $t0, $t0, 1 # +1 address
		addi $t2, $t2, 1 # +1 charcount
		addi $t4, $t4, 1 # +1 charoffset
		# branch where necessary
		bgt $t2, 20, InvalidArgument
		bge $t4, 4, EI_LoopA
		j EI_LoopB
		
AccessFile:
lw $t0, ($s0)
la $a0, ($t0)
li $a1, 0
li $v0, 13
syscall #open the file
blt $v0, $zero, SuccessCase #file errored
move $s2, $v0 #move file descriptor into $s2

addi $s3, $zero, 0 #$s3 will hold the num of items on openbrace stack
addi $s4, $zero, 0 #$s4 will hold the current fileindex

BufferLoop:
la $a0, ($s2)
la $a1, Buffer
la $a2, 128
li $v0, 14
syscall #read buffer from file
move $t9, $v0 #move charsread into $t9
beqz $t9, FinalCheck
addi $t0, $zero, 0

BufferReadLoop:
lb $t1, Buffer($t0)
beq $t1, 40, Push #(
beq $t1, 91, Push #[
beq $t1, 123, Push #{
beq $t1, 41, Pop #)
beq $t1, 93, Pop #]
beq $t1, 125, Pop #}
BufferReadLoop_Cont:
addi $t0, $t0, 1 #bufferindex offset + 1
addi $s4, $s4, 1 #fileindex offset + 1
addi $t9, $t9, -1 #charsread - 1
beqz $t9, BufferLoop #recurse to bufferloop if we have read all chars in this buffer
j BufferReadLoop #

Push:
addi $sp, $sp, -4 #make space for a new index
sw $s4, ($sp) #store the index
addi $sp, $sp, -4 #make space for a new char
sb $t1, ($sp) #store the char
addi $s3, $s3, 1 #stack+1
j BufferReadLoop_Cont

Pop:
beqz $s3, BraceMismatchToNull #empty stack so error, and exit
lb $t2, ($sp) #store the char in $t2
addi $sp, $sp, 4 #return the space
lw $t3, ($sp) #store the index in $t3
addi $sp, $sp, 4 #return the space
addi $s3, $s3, -1 #stack-1
	# ( ) ???
beq $t1, 41, Evaluate41
	# [ ] ???
beq $t1, 93, Evaluate93
	# { } ???
beq $t1, 125, Evaluate125
FinishPop:
addi $s1, $s1, 1
	j BufferReadLoop_Cont

Evaluate41:
bne $t2, 40, BraceMismatch
	j FinishPop

Evaluate93:
bne $t2, 91, BraceMismatch
	j FinishPop
	
Evaluate125:
bne $t2, 123, BraceMismatch
	j FinishPop

FinalCheck:
beqz $s3, SuccessCase #stack is empty, we're good

la $a0, Msg_Stack
li $v0, 4
syscall 
# print out the entire stack
FinalCheck_Loop:
beqz $s3, Exit
lb $t0, ($sp)
addi $sp, $sp, 8

la $a0, ($t0)
li $v0, 11
syscall #print the char

addi $s3, $s3, -1
j FinalCheck_Loop

BraceMismatch:
la $a0, Msg_Mismatch1
li $v0, 4
syscall

la $a0, ($t2)
li $v0, 11
syscall

la $a0, Msg_Mismatch2
li $v0, 4
syscall

la $a0, ($t3)
li $v0, 1
syscall

la $a0, Space
li $v0, 4
syscall

la $a0, ($t1)
li $v0, 11
syscall

la $a0, Msg_Mismatch2
li $v0, 4
syscall

la $a0, ($s4)
li $v0, 1
syscall
	j Exit

BraceMismatchToNull:
la $a0, Msg_Mismatch1
li $v0, 4
syscall

la $a0, ($t1)
li $v0, 11
syscall

la $a0, Msg_Mismatch2
li $v0, 4
syscall

la $a0, ($s4)
li $v0, 1
syscall
	j Exit

# FirstChar was not valid
InvalidArgument:
li $v0, 4
la $a0, Msg_InvArg
syscall
	j Exit # close program

# Everything worked good
SuccessCase:
la $a0, Msg_Success1
li $v0, 4
syscall

la $a0, ($s1)
li $v0, 1
syscall

la $a0, Msg_Success2
li $v0, 4
syscall

Exit:
la $a0, NewLine
li $v0, 4
syscall

li $v0, 10
syscall





.data
Buffer: .space 128
Msg_Intro: .asciiz "You entered the file:"
Msg_InvArg: .asciiz "ERROR: Invalid program argument."
Msg_Stack: .asciiz "ERROR - Brace(s) still on stack: "
Msg_Mismatch1:.asciiz "ERROR - There is a brace mismatch: "
Msg_Mismatch2: .asciiz " at index "
Msg_Success1: .asciiz "SUCCESS: There are "
Msg_Success2: .asciiz " pairs of braces."
NewLine: .asciiz "\n"
Space: .asciiz " "
