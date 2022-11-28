################ CSC258H1F Fall 2022 Assembly Final Project ##################
# This file contains our implementation of Breakout.
#
# Student 1: Name, Student Number
# Student 2: Name, Student Number
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       4
# - Unit height in pixels:      4
# - Display width in pixels:    512
# - Display height in pixels:   256
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################


.eqv screen_width 256	# width in bitmap units
.eqv screen_height 128	# height in bitmap units
.eqv sleep_time 15	# set frame rate to ~60 FPS
# .eqv paddle_color
.eqv red	0xf05630
.eqv green  	0x73ff73
.eqv blue   	0x525afa
.eqv orange	0xfc8e49
.eqv yellow	0xeded42
.eqv white  	0xffffff
.eqv grey   	0x8e8e8e 
.eqv black	0x000000

.eqv wall_thickness 6
.eqv brick_width 20
.eqv brick_height 3
.eqv brick_gap 2
.eqv bricks_per_line 11
.eqv paddle_speed 8
.eqv paddle_width 24
.eqv paddle_height 3  
.eqv ball_size 3

.data

FRAMEBUFFER: 
    .space 0x20000
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
# ball_size:	.word 1


##############################################################################
# Mutable Data
##############################################################################
ball:
    .word   126 	    # x_loc
    .word   100	    # y_loc
    .word   white   # ball_color 
    .word   6	    # x_vel
    .word   -3	    # y_vel
    .word   ball_size # ball_size
paddle:
    .word   116			# x_loc
    .word   116			# y_loc
    .word   paddle_width	# paddle_width
    .word   red			# paddle_color    
    .word   paddle_speed	# paddle_speed
# brick:
    #.space  4	# x_loc   
    #.space  4	# y_loc   
    #.space  4	# color
    #.word   0	# is_dead  

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
    jal init_bricks
    

    

game_loop:
    # 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (paddle, ball)
	# 3. Draw the screen
	# 4. Sleep

    jal handle_input
    jal move_ball



    jal draw_bricks
    jal draw_paddle
    jal draw_ball
    jal draw_walls
   
    # Tell the display to update
    lw   $t8, ADDR_DSPL
    li   $t9, 1
    sw   $t9, 0($t8) 
    
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
get_location_address:
    # BODY

    sll $t0, $a0, 2 # t0 = a0 * 4 (x_bytes)

    # t1 = a1 * screen_width * 4 (y_bytes)
    li $t2, screen_width
    sll $t1, $a1, 2
    mult $t1, $t2
    mflo $t1

    lw $v0, ADDR_DSPL	
    add $v0, $v0, $t0
    add $v0, $v0, $t1	# address = initial address + x_bytes + y_bytes

    # EPILOGUE
    jr $ra

# draw_rect(x, y, width, height, color) -> void
draw_rect:
    # obtain the color through the stack
    lw $t4, 0($sp) 
    addi $sp, $sp, 4
    # PROLOGUE
    addi $sp, $sp, -24
    sw $s0, 20($sp)
    sw $s1, 16($sp)
    sw $s2, 12($sp)
    sw $s3, 8($sp)
    sw $s4, 4($sp)
    sw $ra, 0($sp)

    # create copies of x, y, width, height and color
    move $s0, $a0 # x
    move $s1, $a1 # y
    move $s2, $a2 # width
    move $s3, $a3 # height
    move $s4, $t4 # color

    li $t5, 0	# i = 0
draw_rect_loop1:
    beq $t5, $s3, draw_rect_epi

    li $t6, 0	# j = 0
draw_rect_loop2:
    beq $t6, $s2, draw_rect_loop2_end
	
	# calculate address of the point (x + j, y + i)
	add $a0, $s0, $t6
	add $a1, $s1, $t5

	jal get_location_address # v0 is now has the address for (x + j, y + i)

	sw $s4, 0($v0) # paint the pixel the correct color!

    addi $t6, $t6, 1
    j draw_rect_loop2
draw_rect_loop2_end: 
    addi $t5, $t5, 1
    j draw_rect_loop1
draw_rect_epi:
    # EPILOGUE     
    lw $ra, 0($sp)
    lw $s4, 4($sp)
    lw $s3, 8($sp)
    lw $s2, 12($sp)
    lw $s1, 16($sp)
    lw $s0, 20($sp)
    addi $sp, $sp, 24
    jr $ra

draw_walls:
    # PROLOGUE
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    # BODY

    # corner
    # li $a0, 10 
    # li $a1, 60 
    # li $a2, 1
    # li $a3, 1
    #
    # addi $sp, $sp, -4
    # li, $t0, grey
    # sw $t0, 0($sp)
    #
    # jal draw_rect
    
    # left wall
    li $a0, 1
    li $a1, 1
    li $a2, wall_thickness 
    li $a3, 127 # screen_height - 1

    addi $sp, $sp, -4
    li, $t0, grey
    sw $t0, 0($sp)

    jal draw_rect

    # top wall
    li $a0, 1
    li $a1, 1
    li $a2, 254 # screen_width - 2
    li $a3, wall_thickness 

    addi $sp, $sp, -4
    li, $t0, grey
    sw $t0, 0($sp)

    jal draw_rect

    # right wall
    li $a0, 249 # screen_width - 1 - wall_thickess
    li $a1, 1
    li $a2, wall_thickness 
    li $a3, 127 # screen_height - 1

    addi $sp, $sp, -4
    li, $t0, grey
    sw $t0, 0($sp)

    jal draw_rect

    # EPILOGUE
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


# init_brick_line(y, brick_row, color) -> void
# TODO: MAKE THIS UPDATE THE BRICK_ARRAY
init_brick_line:
    # BODY
    li $t0, 8    # x
    li $t1, 0    # i = 0
    la $t2, brick_array  # load brick array
    addi $t2, $t2, 4  # add 4 to skip the space
    li $t3, bricks_per_line  # load bricks per line
    mult $a1, $t3  # multiply brick row number by bricks per line
    mflo $t3 # store result in t3
    sll $t3, $t3, 4  # multiply by 4 x 4 for brick
    add $t2, $t2, $t3  # add it to brick array address to get the starting address
	
init_brick_line_loop:
    li $t4, bricks_per_line
    beq $t1, $t4, init_brick_line_epi # exit when i = bricks per line
    sw $t0, 0($t2)  # store the x value
    addi $t0, $t0, brick_width
    addi $t0, $t0, brick_gap # update x value
    addi $t2, $t2, 4
    sw $a0, 0($t2)  # store the y value
    addi $t2, $t2, 4
    sw $a2, 0($t2)  # store the color 
    addi $t2, $t2, 4
    sw $0, 0($t2)  # store isDead
    addi $t2, $t2, 4
    addi $t1, $t1, 1  # increase t1
    b init_brick_line_loop
    
init_brick_line_epi:
    # EPILOGUE
    jr $ra

# init_bricks() -> void
init_bricks:
    # PROLOGUE
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    # BODY
    
    la $t0, brick_array
    li $t1, 5
    li $t2, bricks_per_line
    
    mult $t1, $t2
    mflo $t3
    sw $t3, 0($t0)
    
    li $a0, 10 
    li $a1, 0 
    li $a2, red
    jal init_brick_line
    
    li $a0, 15 
    li $a1, 1 
    li $a2, orange
    jal init_brick_line
    
    li $a0, 20 
    li $a1, 2 
    li $a2, yellow
    jal init_brick_line
    
    li $a0, 25 
    li $a1, 3 
    li $a2, green
    jal init_brick_line
    
    li $a0, 30 
    li $a1, 4 
    li $a2, blue
    jal init_brick_line
    
    # EPILOGUE
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
draw_bricks:
    # PROLOGUE
    addi $sp, $sp, -16
    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $s2, 8($sp)
    sw $ra, 12($sp)

        
    # BODY
    la $s0, brick_array  # store brick array address
    lw $s1, 0($s0)  # store the number of bricks in brick_array
    li $s2, 0  # i = 0
    addi $s0, $s0, 4

draw_brick_loop:
    beq $s1, $s2, draw_brick_epi  # exit when i == number of bricks
    lw $a0, 0($s0)  # load the x coord
    addi $s0, $s0, 4 
    lw $a1, 0($s0)  # load the y value
    addi $s0, $s0, 4
    li $a2, brick_width  # store rect width
    li $a3, brick_height  # store rect height
    lw $t3, 0($s0)  # load color
    addi $s0, $s0, 8 
    addi $sp, $sp, -4
    sw $t3, 0($sp)  # push color onto stack
    jal draw_rect
    addi $s2, $s2, 1  # increment i
    b draw_brick_loop 
    
draw_brick_epi:
    # EPILOGUE
    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $s2, 8($sp)
    lw $ra, 12($sp)
    addi $sp, $sp, 16
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
    li $a3, paddle_height	    # height
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
    li $a2, ball_size		# width 
    li $a3, ball_size		# height 

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
    li $a2, screen_width
    li $a3, screen_height
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
    
    ble $t1, 7, handle_paddle_left_collision
    bge $t1, 225, handle_paddle_right_collision
    
    sw $t1, 0($t0)	# update x position of paddle
    b move_paddle_epi
    
handle_paddle_left_collision: 
    addi $t4, $0, 7
    sw $t4, 0($t0)
    b move_paddle_epi

handle_paddle_right_collision: 
    addi $t4, $0, 225
    sw $t4, 0($t0)
    b move_paddle_epi
    
move_paddle_epi:
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

    ble $t1, 7, handle_ball_left_wall_collision
    bge $t1, 246, handle_ball_right_wall_collision
    ble $t2, 7, handle_ball_top_wall_collision
   
    sw $t1, 0($t0)
    sw $t2, 4($t0)
    
    b move_ball_epi

handle_ball_left_wall_collision:
    sub $t3, $0, $t3
    li $t5, 7
    sw $t5, 0($t0)
    sw $t2, 4($t0)
    sw $t3, 12($t0)
    b move_ball_epi
    
handle_ball_right_wall_collision:
    sub $t3, $0, $t3
    li $t5, 246
    sw $t5, 0($t0)
    sw $t2, 4($t0)
    sw $t3, 12($t0)
    b move_ball_epi
    
handle_ball_top_wall_collision:
    sub $t4, $0, $t4 
    li $t5, 7
    sw $t1, 0($t0)
    sw $t5, 4($t0)
    sw $t4, 16($t0)
    b move_ball_epi

move_ball_epi:
    # EPILOGUE
    jr $ra
