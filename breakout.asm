################ CSC258H1F Fall 2022 Assembly Final Project ##################
# This file contains our implementation of Breakout.
#
# Student 1: Name, Student Number
# Student 2: Name, Student Number
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       8
# - Unit height in pixels:      8
# - Display width in pixels:    512
# - Display height in pixels:   256
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################


# .eqv brick_width 2
# .eqv paddle_width 2
# .eqv paddle_color
.eqv display_width  64
.eqv display_height 32
.eqv red    0xf05630
.eqv green  0x00ff00
.eqv blue   0x0000ff
.eqv grey   0x8e8e8e 


    .data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000

brick_width:	.word 2
ball_size:	.word 1
brick_colors:
    .word   red
    .word   green
    .word   blue


##############################################################################
# Mutable Data
##############################################################################
ball:
    .word   5	# x_loc
    .word   5	# y_loc
    .word   0	# x_vel
    .word   -1	# y_vel
paddle:
    .word   30	# x_loc
    .word   30	# y_loc
    .word   5	# paddle_width
    .word   red	# paddle_color    

##############################################################################
# Code
##############################################################################
	.text
	.globl main

	# Run the Brick Breaker game.
main:
    # Initialize the game
    
    # li $a0, 32
    # li $a1, 29
    # jal draw_paddle
    
    jal draw_walls
    jal draw_paddle

    
end:    
    li $v0, 10
    syscall

game_loop:
	# 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (paddle, ball)
	# 3. Draw the screen
	# 4. Sleep

    #5. Go back to 1
    b game_loop

# get_location_address(x, y) -> address
#   Return the address of the unit on the display at location (x,y)
#
#   Preconditions:
#       - x is between 0 and 63, inclusive
#       - y is between 0 and 31, inclusive
get_location_address:
    # BODY
    sll $a0, $a0, 2	# x = x * 4
    sll $a1, $a1, 8	# y = y * 256

    lw $v0, ADDR_DSPL	
    add $v0, $v0, $a0
    add $v0, $v0, $a1	# address = address + x + y

    # EPILOGUE
    jr $ra

# draw_rect(x, y, width, height, color) -> void
draw_rect:
    # PROLOGUE
    lw $t4, 0($sp) # obtain the color through the stack
    addi $sp, $sp, 4

    # create copies of width, height 
    move $t2, $a2 # width
    move $t3, $a3 # height

    addi $sp, $sp, -16
    sw $t2, 12($sp)
    sw $t3, 8($sp)
    sw $t4, 4($sp)
    sw $ra, 0($sp)

    # get_location address for (x,y)
    jal get_location_address
    # v0 now has the address for (x, y)

    lw $ra, 0($sp)
    lw $t4, 4($sp)
    lw $t3, 8($sp)
    lw $t2, 12($sp)
    addi $sp, $sp, 16

    li $t5, 0	# i = 0
draw_rect_loop1:
    beq $t5, $t3, draw_rect_epi

    li $t6, 0	# j = 0
draw_rect_loop2:
    beq $t6, $t2, draw_rect_loop2_end
	
	# calculate address of the point (x + j, y + i)
	move $t7, $t6
	move $t8, $t5
	
	sll $t7, $t7, 2 # x_bytes
	sll $t8, $t8, 8 # y_bytes

	add $t9, $v0, $t7
	add $t9, $t9, $t8

	sw $t4, 0($t9)

    addi $t6, $t6, 1
    j draw_rect_loop2
draw_rect_loop2_end: 
    addi $t5, $t5, 1
    j draw_rect_loop1
draw_rect_epi:
    # EPILOGUE     
    jr $ra

draw_walls:
    # PROLOGUE
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    # BODY
    
    # left wall
    li $a0, 0
    li $a1, 0
    li $a2, 3
    li $a3, 32

    addi $sp, $sp, -4
    li, $t0, grey
    sw $t0, 0($sp)

    jal draw_rect
    
    # top wall
    li $a0, 0
    li $a1, 0
    li $a2, 64 
    li $a3, 3

    addi $sp, $sp, -4
    li, $t0, grey
    sw $t0, 0($sp)

    jal draw_rect
    
    # right wall
    li $a0, 61
    li $a1, 0
    li $a2, 3 
    li $a3, 32 

    addi $sp, $sp, -4
    li, $t0, grey
    sw $t0, 0($sp)

    jal draw_rect


    # EPILOGUE
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


# draw_brick(startAddress, color) -> void
draw_brick:
    # bruh what
    lw $t0, 0($sp) # color
    addi $sp, $sp, 4
    lw $t1, 0($sp) # start address
    addi $sp, $sp, 4

    sw $t0, 0($t1)

# draw_paddle() -> void
draw_paddle:
    # PROLOGUE
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # BODY
    
    la $t0, paddle  # get address of paddle obj
    lw $a0, 0($t0)  # x
    lw $a1, 4($t0)  # y
    lw $a2, 8($t0)  # width
    li $a3, 1	    # height
    lw $t4, 12($t0) # color
    addi $sp, $sp, -4
    sw $t4, 0($sp)  # push color onto stack

    jal draw_rect

draw_paddle_epi:
    # EPILOGUE
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
