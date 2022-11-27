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


.eqv sleep_time 60 # ~15 FPS
.eqv brick_width 2
.eqv paddle_speed 2
# .eqv paddle_color
.eqv red	0xf05630
.eqv green  	0x73ff73
.eqv blue   	0x525afa
.eqv orange	0xfc8e49
.eqv yellow	0xeded42
.eqv white  	0xffffff
.eqv grey   	0x8e8e8e 
.eqv black	0x000000


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

# brick_width:	.word 2
ball_size:	.word 1


##############################################################################
# Mutable Data
##############################################################################
ball:
    .word   32 	    # x_loc
    .word   25	    # y_loc
    .word   white   # ball_color 
    .word   0	    # x_vel
    .word   -1	    # y_vel
paddle:
    .word   30			# x_loc
    .word   30			# y_loc
    .word   5			# paddle_width
    .word   red			# paddle_color    
    .word   paddle_speed	# paddel_speed
brick:
    .space  4	# x_loc   
    .space  4	# y_loc   
    .space  4	# color
    .word   0	# is_dead  

brick_array:
    .space  4	    # ending address
    .space  1000    # don't know what this should be

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
    

    

game_loop:
	# 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (paddle, ball)
	# 3. Draw the screen
	# 4. Sleep
    jal handle_input
    jal move_ball


    jal draw_walls
    jal draw_paddle
    jal init_bricks
    jal draw_ball
   
    
    
    # sleep
    li $a0, sleep_time
    li $v0, 32
    syscall

    jal erase_screen

    #5. Go back to 1
    b game_loop

end:    
    li $v0, 10
    syscall

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
    li $a0, 1
    li $a1, 1
    li $a2, 2
    li $a3, 31

    addi $sp, $sp, -4
    li, $t0, grey
    sw $t0, 0($sp)

    jal draw_rect
    
    # top wall
    li $a0, 1
    li $a1, 1
    li $a2, 62 
    li $a3, 2 

    addi $sp, $sp, -4
    li, $t0, grey
    sw $t0, 0($sp)

    jal draw_rect
    
    # right wall
    li $a0, 61
    li $a1, 1
    li $a2, 2 
    li $a3, 31 

    addi $sp, $sp, -4
    li, $t0, grey
    sw $t0, 0($sp)

    jal draw_rect


    # EPILOGUE
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


# init_brick_line(x, y, num_bricks, color) -> void
# TODO: MAKE THIS UPDATE THE BRICK_ARRAY
init_brick_line:
    # PROLOGUE
    addi $sp, $sp, -24
    sw $s0, 20($sp)
    sw $s1, 16($sp)
    sw $s2, 12($sp)
    sw $s3, 8($sp)
    sw $s4, 4($sp)
    sw $ra, 0($sp)

    # BODY
    
    # create copies of function arguments
    move $s0, $a0   # x
    move $s1, $a1   # y
    move $s2, $a2   # num_bricks
    move $s3, $a3   # color

    move $s4, $zero # i = 0

init_brick_line_loop:
    beq $s4, $s2, init_brick_line_epi

	move $a0, $s0
	move $a1, $s1
	li $a2, brick_width
	li $a3, 1
	addi $sp, $sp, -4
	sw $s3, 0($sp)

	mult $a2, $s4	    # calculate x offset
	mflo $t0
	add $a0, $a0, $t0   # add offset to x

	jal draw_rect

    addi $s4, $s4, 1
    j init_brick_line_loop
    
init_brick_line_epi:
    # EPILOGUE
    lw $ra, 0($sp)
    lw $s4, 4($sp)
    lw $s3, 8($sp)
    lw $s2, 12($sp)
    lw $s1, 16($sp)
    lw $s0, 20($sp)
    addi $sp, $sp, 24
    jr $ra

# init_bricks() -> void
init_bricks:
    # PROLOGUE
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    # BODY
    
    li $a0, 3 
    li $a1, 6
    li $a2, 29
    li $a3, red
    jal init_brick_line

    li $a0, 3 
    li $a1, 7
    li $a2, 29
    li $a3, orange
    jal init_brick_line

    li $a0, 3 
    li $a1, 8
    li $a2, 29
    li $a3, yellow
    jal init_brick_line


    li $a0, 3 
    li $a1, 9
    li $a2, 29
    li $a3, green
    jal init_brick_line

    li $a0, 3 
    li $a1, 10  
    li $a2, 29
    li $a3, blue
    jal init_brick_line

    # EPILOGUE
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
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


draw_ball:
    # PROLOGUE
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # BODY
    la $t0, ball # get the address of ball object

    lw $a0, 0($t0)	# x
    lw $a1, 4($t0)	# y
    li $a2, 1		# width 
    li $a3, 1		# height 

    lw $t1, 8($t0)	# get color of ball
    addi $sp, $sp, -4
    sw $t1, 0($sp)	# load color onto stack
    jal draw_rect

    # EPILOGUE
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# erase_screen() -> void
erase_screen:
    # PROLOGUE
    addi $sp, $sp, -4 
    sw $ra, 0($sp)
    
    # BODY
    li $a0, 0
    li $a1, 0
    li $a2, 64
    li $a3, 32
    li $t0, black
    addi $sp, $sp, -4
    sw $t0, 0($sp)

    jal draw_rect

    # EPILOGUE
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    


# handle_input() -> void
handle_input:
    # PROLOGUE
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # BODY
    lw $t0, ADDR_KBRD			# $t0 = base address for keyboard
    lw $t1, 0($t0)			# Load first word from keyboard
    bne $t1, 1, handle_input_epi	# If first word 1, key is pressed

    lw $t2, 4($t0)  # $t2 = keycode
    beq $t2, 97, move_paddle_left	# a
    beq $t2, 100, move_paddle_right	# d
    beq $t2, 113, quit	# q
    
    j handle_input_epi

move_paddle_left:
    li $a0, -1
    jal move_paddle
    j handle_input_epi
move_paddle_right:
    li $a0, 1
    jal move_paddle
    j handle_input_epi
quit:
    jal quit_game

handle_input_epi:
    # EPILOGUE
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
quit_game:
    li $v0, 10                      # Quit gracefully
    syscall

# move_paddle(dir) -> void
#   Move the paddle direction depending on dir
#	- dir = -1 => move left
#	- dir = 1 => move right
move_paddle:
    # BODY

    la $t0, paddle
    lw $t1, 0($t0)	# x
    lw $t2, 16($t0)	# speed
    mult $a0, $t2
    mflo $t3		# x delta
    add $t1, $t1, $t3	# calculate new x

    sw $t1, 0($t0)	# update x position of paddle

    move $a0, $t1
    li $v0, 1
    syscall

    # EPILOGUE
    jr $ra

move_ball:
    # BODY
    la $t0, ball	# get ball address
    lw $t1, 0($t0)	# x
    lw $t2, 4($t0)	# y
    lw $t3, 12($t0)	# x_velocity
    lw $t4, 16($t0)	# y_velocty
    add $t1, $t1, $t3	# x = x + x_velocity
    add $t2, $t2, $t4	# y = y + y_velocity

    sw $t1, 0($t0)
    sw $t2, 4($t0)

    # EPILOGUE
    jr $ra

