#Winter20 Lab5 Template File

# Macro that stores the value in %reg on the stack 
#  and moves the stack pointer.
.macro push(%reg)
	addi $sp, $sp, -4
	sw %reg, 0($sp)
.end_macro 

# Macro takes the value on the top of the stack and 
#  loads it into %reg then moves the stack pointer.
.macro pop(%reg)
	lw %reg, 0($sp)
	addi $sp, $sp, 4	
.end_macro

# Macro that takes as input coordinates in the format
# (0x00XX00YY) and returns 0x000000XX in %x and 
# returns 0x000000YY in %y
.macro getCoordinates(%input %x %y)
	andi %y, %input, 0xFF # 0x000000YY
	srl %x, %input, 16 # 0x******XX
	andi %x, %x, 0xFF # 0x000000XX
.end_macro

# Macro that takes Coordinates in (%x,%y) where
# %x = 0x000000XX and %y= 0x000000YY and
# returns %output = (0x00XX00YY)
.macro formatCoordinates(%output %x %y)
	li %output, 0 # 0x00000000
	or %output, %output, %x # 0x000000XX
	sll %output, %output, 16 # 0x00XX0000
	or %output, %output, %y # 0x00XX00YY
.end_macro

.text
j done
   
    done: nop
    li $v0 10
    syscall

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#  Subroutines defined below
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#*****************************************************
# clear_bitmap:
#  Given a clor in $a0, sets all pixels in the display to
#  that color.	
#-----------------------------------------------------
# $a0 =  color of pixel
#-----------------------------------------------------
#clear_bitmap(color){
# a = 0xFFFF0000
# b = 0xFFFFFFFC
# while(true)
#	MEMORY[a] = color
#	if(a==b) break;
#	a += 4
# end while
#}
#*****************************************************
clear_bitmap: nop
li $t0, 0xFFFF0000 # load origin address into $t0
li $t1, 0xFFFFFFFC # load end address into $t1
	fill_loop: nop
		sw $a0, ($t0) # set current pixel to color in $a0
		beq $t0, $t1, fill_done # break loop if we have reached last pixel
		addi $t0, $t0, 4 # jump to next pixel
			j fill_loop # loop
	fill_done: nop
		jr $ra
	
#*****************************************************
# draw_pixel:
#  Given a coordinate in $a0, sets corresponding value
#  in memory to the color given by $a1
#  [(row * row_size) + column] to locate the correct pixel to color
#-----------------------------------------------------
# $a0 = coordinates of pixel in format (0x00XX00YY)
# $a1 = color of pixel
#-----------------------------------------------------
#draw_pixel(f1,color){
# getCoordinates(f1, x,y)
# offset = ((y*128)+x)*4
# location = offset+0xffff0000
# MEMORY[location] = color
#}
#*****************************************************
draw_pixel: nop
getCoordinates($a0, $t0, $t1) # $t0=x $t1=y; y is a row, x is a column
addi $t2, $zero, 0x80
mul $t3, $t1, $t2 # row * 0x80 (128) (row size)
add $t3, $t3, $t0 # + column
sll $t3, $t3, 2 # offset * 4
ori $t3, $t3, 0xFFFF0000 # 0xffff0000 + offset
sw $a1, ($t3)

	jr $ra

#*****************************************************
# get_pixel:
#  Given a coordinate, returns the color of that pixel	
#-----------------------------------------------------
# $a0 = coordinates of pixel in format (0x00XX00YY)
# returns pixel color in $v0	
#-----------------------------------------------------
#get_pixel(f1){
# getCoordinates(f1, x, y)
# offset = ((y*128)+x)*4
# location = offset+0xffff0000
# A = MEMORY[location]
# return A
#*****************************************************
get_pixel: nop
getCoordinates($a0, $t0, $t1) # $t0=x $t1=y; y is a row, x is a column
addi $t2, $zero, 0x80
mul $t3, $t1, $t2 # row * 0x80 (128) (row size)
add $t3, $t3, $t0 # + column
sll $t3, $t3, 2 # offset * 4
ori $t3, $t3, 0xFFFF0000 # 0xffff0000 + offset
lw $v0, ($t3)
	
	jr $ra
	

#***********************************************
# draw_line:
#  Given two coordinates, draws a line between them 
#  using Bresenham's incremental error line algorithm	
#-----------------------------------------------------
# 	Bresenham's line algorithm (incremental error)
# plotLine(int x0, int y0, int x1, int y1)
#    dx =  abs(x1-x0);
#    sx = x0<x1 ? 1 : -1;
#    dy = -abs(y1-y0);
#    sy = y0<y1 ? 1 : -1;
#    err = dx+dy;  /* error value e_xy */
#    while (true)   /* loop */
#        plot(x0, y0);
#        if (x0==x1 && y0==y1) break;
#        e2 = 2*err;
#        if (e2 >= dy) 
#           err += dy; /* e_xy+e_x > 0 */
#           x0 += sx;
#        end if
#        if (e2 <= dx) /* e_xy+e_y < 0 */
#           err += dx;
#           y0 += sy;
#        end if
#   end while
#-----------------------------------------------------
# $a0 = first coordinate (x0,y0) format: (0x00XX00YY)
# $a1 = second coordinate (x1,y1) format: (0x00XX00YY)
# $a2 = color of line format: (0x00RRGGBB)
#-----------------------------------------------------
# Pseudocode is just plotLine() function translated into
# mips
#***************************************************
draw_line: nop
push($s0)
push($s1)
push($s2)
push($s3)
getCoordinates($a0, $s0, $s1) # (x0, y0) = ($s0, $s1)
getCoordinates($a1, $s2, $s3) # (x1, y1) = ($s2, $s3)
move $a1, $a2 # $a1 = color of line format: (0x00RRGGBB)
# dx = $t0 = abs($s2-$s0);
sub $t0, $s2, $s0
abs $t0, $t0
# sx = $t1 = $s0<$s2 ? 1 : -1;
slt $t1, $s0, $s2
bnez $t1, draw_line_cont1
li $t1, -1
draw_line_cont1: nop
# dy = $t2 = -abs($s3-$s1);
sub $t2, $s3, $s1
abs $t2, $t2
li $t9, -1
mul $t2, $t2, $t9
# sy = $t3 = $s1<$s3 ? 1 : -1;
slt $t3, $s1, $s3
bnez $t3, draw_line_cont2
li $t3, -1
draw_line_cont2: nop
# err = $t4 = $t0+$t2;
add $t4, $t0, $t2
# while (true)
draw_line_loop: nop
# 	plot($s0, $s1);
	formatCoordinates($a0, $s0, $s1)
	push($ra)
	push($t0)
	push($t1)
	push($t2)
	push($t3)
	jal draw_pixel
	pop($t3)
	pop($t2)
	pop($t1)
	pop($t0)
	pop($ra)
# 	if ($s0==$s2 && $s1==$s3) break;
	seq $t9, $s0, $s2
	seq $t8, $s1, $s3
	and $t7, $t8, $t9
	beq $t7, 1, draw_line_loop_end
# 	e2 = $t5 = 2*$t4;
	sll $t5, $t4, 1
# 	if ($t5 >= $t2)
	sge $t9, $t5, $t2
	beqz $t9, draw_line_if1
#		$t4 += $t2;
		add $t4, $t4, $t2
#		$s0 += $t1;
		add $s0, $s0, $t1
# 	end if
	draw_line_if1: nop
#	if ($t5 <= $t0)
	sle $t9, $t5, $t0
	beqz $t9, draw_line_if2
#		$t4 += $t0;
		add $t4, $t4, $t0
#         $s1 += $t3;
		add $s1, $s1, $t3
#    end if
	draw_line_if2: nop
	b draw_line_loop
# end while
draw_line_loop_end: nop
pop($s3)
pop($s2)
pop($s1)
pop($s0)
	jr $ra
	
#*****************************************************
# draw_rectangle:
#  Given two coordinates for the upper left and lower 
#  right coordinate, draws a solid rectangle	
#-----------------------------------------------------
# $a0 = first coordinate (x0,y0) format: (0x00XX00YY)
# $a1 = second coordinate (x1,y1) format: (0x00XX00YY)
# $a2 = color of line format: (0x00RRGGBB)
#-----------------------------------------------------
#draw_rectangle(f1, f2, color){
# getCoordinates(f1, x0, y0);
# getCoordinates(f2, x1, y1);
# while (true)
# 	formatCoordinates(f1, x0, y0);
#	formatCoordinates(f2, x1, y0);
#	drawLine(f1, f2, color);
#	if(y0==y1) break;
#	y0++;
# end while
#}
#***************************************************
draw_rectangle: nop
push($s0)
push($s1)
push($s2)
push($s3)

getCoordinates($a0, $s0, $s1) # (x0,y0) = ($s0, $s1)
getCoordinates($a1, $s2, $s3) # (x1,y1) = ($s2, $s3)

draw_rectangle_loop: nop
formatCoordinates($a0, $s0, $s1)
formatCoordinates($a1, $s2, $s1)
push($ra)
push($a0)
push($a1)
push($a2)
push($s0)
push($s1)
push($s2)
push($s3)
jal draw_line
pop($s3)
pop($s2)
pop($s1)
pop($s0)
pop($a2)
pop($a1)
pop($a0)
pop($ra)
beq $s1, $s3, draw_rectangle_loop_end
addi $s1, $s1, 1
b draw_rectangle_loop
draw_rectangle_loop_end: nop

pop($s3)
pop($s2)
pop($s1)
pop($s0)

	jr $ra
	
#*****************************************************
#Given three coordinates, draws a triangle
#-----------------------------------------------------
# $a0 = coordinate of point A (x0,y0) format: (0x00XX00YY)
# $a1 = coordinate of point B (x1,y1) format: (0x00XX00YY)
# $a2 = coordinate of point C (x2, y2) format: (0x00XX00YY)
# $a3 = color of line format: (0x00RRGGBB)
#-----------------------------------------------------
# Traingle should look like:
#               B
#             /   \
#            A --  C
#-----------------------------------------------------
#draw_triangle(f1,f2,f3,color){
# draw_line(f1,f2,color)
# a = f2
# f2 = f3
# draw_line(f1,f2,color)
# f1 = a
# draw_line(f1,f2,color)
#}
#***************************************************	
draw_triangle: nop
move $t0, $a2 # C is in $t0
move $a2, $a3

# Line AB
push($ra)
push($a0)
push($a1)
push($a2)
push($a3)
push($t0)
jal draw_line
pop($t0)
pop($a3)
pop($a2)
pop($a1)
pop($a0)
pop($ra)

move $t1, $a1 # B is in $t1
move $a1, $t0 # C is in $a1
move $t0, $t1 # B is in $t0

# Line AC
push($ra)
push($a0)
push($a1)
push($a2)
push($a3)
push($t0)
jal draw_line
pop($t0)
pop($a3)
pop($a2)
pop($a1)
pop($a0)
pop($ra)

move $a0, $t0

# Line BC
push($ra)
jal draw_line
pop($ra)

	jr $ra	
	
	
	
