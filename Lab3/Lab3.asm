.data
     prompt: .asciiz "Enter the height of the triangle (must be greater than 0): "
     errormsg: .asciiz "Invalid entry!\n"
     tabtext: .asciiz "\t*\t"
     tabchar: .asciiz "\t"
     newlinechar: .asciiz "\n"
	
.text
	# Prompt function
     begin:
     	nop
          # Prompt user for height
     	li $v0, 4
     	la $a0, prompt
     	syscall
     
     	# Wait for user input
     	li $v0, 5
     	syscall

     	# Save the height in $t0
     	
     	move $t0, $v0
     	
     	# Start the current line
     	li $t1, 1
     	
     	# start the current tabs
     	move $t2, $t0
     	sub $t2 $t2 $t1
     	
     	# start teh current numToPrint
     	li $t4, 1
     	
     	# start the nums for current line left
     	li $t3, 1
     
     	# Check if the height is valid
     	bgtz $t0, printTab
     	nop
     
     	# Height was not valid; re-prompt
     	li $v0, 4
     	la $a0 errormsg
     	syscall
     	j begin
     	nop
     
    	# print out the initial tabs if necessary
    	printTab:
    		nop
    		blez $t2, printNum1	# if no more tabs then continue to next func
    		nop
    		
    		# print a tab character
    		li $v0, 4
    		la $a0, tabchar
    		syscall
    		
    		subi $t2 $t2 1		# one less tabchar
    		j printTab		# recurse to beginning of func
    		nop
    		
    	printNum1:
    		nop
    		# print the currrent number we're at
    		li $v0, 1
    		la $a0, ($t4)
    		syscall
    		
    		# go up one num
    		addi $t4, $t4, 1
    		j printNum2
    		nop
    		
    	printNum2:
    		nop
    		ble $t3, 1, LOOP
    		nop
    		
    		# print a tabtext
    		li $v0, 4
    		la $a0, tabtext
    		syscall
    		
    		# print a num
    		li $v0, 1
    		la $a0, ($t4)
    		syscall
    		
    		# go up one num
    		addi $t4, $t4, 1
    		
    		# go down one line left for line
    		subi $t3, $t3, 1
    		
    		# recurse
    		j printNum2
    		nop
    		
    	# loop is necessary
    	LOOP:
    		nop
    		addi $t1 $t1 1		# go up one line
    		bgt $t1 $t0 exit	# if current line is past height num, exit
    		nop
    		
    		# print a new line character
    		li $v0, 4
    		la $a0, newlinechar
    		syscall
    		
    		# reset tabs
    		move $t2, $t0
    		sub $t2 $t2 $t1
    		
    		# reset nums left for line
    		move $t3, $t1
    		
    		j printTab		# recurse to beginning of func
    		nop
    		
	# Finished
     exit:
     	nop
          li $v0 10
          syscall
