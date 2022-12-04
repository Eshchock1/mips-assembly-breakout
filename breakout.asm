################ CSC258H1F Fall 2022 Assembly Final Project ##################
# This file contains our implementation of Breakout.
#
# Student 1: Rameshwara Chock, 1008353693
# Student 2: Edwin Chen, 1008134056
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       2
# - Unit height in pixels:      2
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
.eqv paddle_width 30
.eqv paddle_height 3  
.eqv ball_size 3
.eqv seg_len 3	    # length of segments for numbers

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
    .word   126			# x_pos
    .word   100			# y_pos
    .word   white		# ball_color 
    .word   5			# x_vel
    .word   -3			# y_vel
    .word   ball_size		# ball_size
paddle:
    .word   116			# x_pos
    .word   116			# y_pos
    .word   paddle_width	# paddle_width
    .word   red			# paddle_color    
    .word   paddle_speed	# paddle_speed

# == interface for each brick == 
# brick:
    #.space  4			# x_pos   
    #.space  4			# y_pos   
    #.space  4			# color
    #.word   0			# is_dead  

brick_array:
    .space  4			# number of bricks
    .space  1000		# memory for array of bricks

is_paused:
    .word 0
    
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

    lw $t0, is_paused  
    bne $t0, $zero, end_frame	# end the frame if the game is paused

    jal move_ball

    jal draw_bricks
    jal draw_paddle
    jal draw_ball
    jal draw_walls


   
    # Tell the display to update
    lw   $t8, ADDR_DSPL
    li   $t9, 1
    sb   $t9, 0($t8) 
    
    # sleep
    li $a0, sleep_time
    li $v0, 32
    syscall

    jal erase_screen

end_frame:

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


    li $a0, 10
    li $a1, 10
    jal draw_zero
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
    
    li $a0, 25 
    li $a1, 0 
    li $a2, red
    jal init_brick_line
    
    li $a0, 30 
    li $a1, 1 
    li $a2, orange
    jal init_brick_line
    
    li $a0, 35 
    li $a1, 2 
    li $a2, yellow
    jal init_brick_line
    
    li $a0, 40 
    li $a1, 3 
    li $a2, green
    jal init_brick_line
    
    li $a0, 45 
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
    addi $s0, $s0, 4
    lw $t0, 0($s0) # load is dead
    addi $s0, $s0, 4
    beq $t0, 1, skip_brick_draw 
    addi $sp, $sp, -4
    sw $t3, 0($sp)  # push color onto stack
    jal draw_rect
    addi $s2, $s2, 1  # increment i
    b draw_brick_loop 
    
skip_brick_draw:
   addi $s2, $s2, 1
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

    lw $t3, is_paused 

    bne $t3, $zero, handle_input_paused_mode # when is_paused only handle input to unpause

    beq $t2, 97, move_paddle_left	# a
    beq $t2, 100, move_paddle_right	# d
    beq $t2, 112, handle_pause_game	# p
    beq $t2, 113, quit	# q
    j handle_input_epi

handle_input_paused_mode:
    beq $t2, 117, handle_unpause_game	# u
    j handle_input_epi
    

move_paddle_left:
    li $a0, -1
    jal move_paddle
    j handle_input_epi
move_paddle_right:
    li $a0, 1
    jal move_paddle
    j handle_input_epi
handle_pause_game:
    li $t0, 1
    sw $t0, is_paused
    j handle_input_epi
handle_unpause_game:
    sw $zero, is_paused
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
    # PROLOGUE
    addi $sp, $sp, -24
    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $s2, 8($sp)
    sw $s3, 12($sp)
    sw $s4, 16($sp)
    sw $ra, 20($sp)

    # BODY
    la $s0, ball	# get ball address
    lw $t1, 0($s0)	# x
    lw $t2, 4($s0)	# y
    lw $s3, 12($s0)	# x_velocity
    lw $s4, 16($s0)	# y_velocty
    add $s1, $t1, $s3	# x = x + x_velocity
    add $s2, $t2, $s4	# y = y + y_velocity

    ble $t1, 7, handle_ball_left_wall_collision
    bge $t1, 246, handle_ball_right_wall_collision
    ble $t2, 7, handle_ball_top_wall_collision
    bge $t2, 125, handle_game_reset
    
    # handle ball and paddle collision
    move $a0, $s1
    move $a1, $s2
    move $a2, $s3
    move $a3, $s4
    la $t0, paddle
    lw $t1, 0($t0) # x loc
    lw $t2, 4($t0) # y loc
    lw $t3, 8($t0) # paddle width
    li $t4, paddle_height
    addi $sp, $sp, -16
    sw $t1, 0($sp)
    sw $t2, 4($sp)
    sw $t3, 8($sp)
    sw $t4, 12($sp)
    jal handle_ball_rect_collision
    
    beq $v0, 1, handle_vert_ball_paddle_collision
    beq $v0, 3, handle_vert_ball_paddle_collision
    
    move $a0, $s1 # ball x pos
    move $a1, $s2 # ball y pos
    move $a2, $s3 # ball x vel
    move $a3, $s4 # ball y vel
    jal handle_ball_brick_collision
    beq $v0, 1, move_ball_epi # branch if collision
    
    sw $s1, 0($s0)
    sw $s2, 4($s0)
    
    b move_ball_epi

# (ball_x, ball_y, ball_x_vel, ball_y_vel)
handle_ball_brick_collision: 
    # PROLOGUE
    addi $sp, $sp, -32
    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $s2, 8($sp)
    sw $s3, 12($sp)
    sw $s4, 16($sp)
    sw $s5, 20($sp)
    sw $s6, 24($sp)
    sw $ra, 28($sp)

    # BODY
    la $s0, brick_array  # store brick array address
    lw $s1, 0($s0)  # store the number of bricks in brick_array
    li $s2, 0  # i = 0
    addi $s0, $s0, 4  # skip first address
    
    move $s3, $a0
    move $s4, $a1
    move $s5, $a2
    move $s6, $a3
    
handle_ball_brick_collision_loop:
    beq $s1, $s2, handle_ball_brick_collision_no_collision  # exit when i == number of bricks
    lw $t0, 0($s0)  # load the x coord
    addi $s0, $s0, 4 
    lw $t1, 0($s0)  # load the y value
    addi $s0, $s0, 8
    li $t2, brick_width  # store rect width
    li $t3, brick_height  # store rect height
    lw $t4, 0($s0) # load is dead  
    beq $t4, 1, skip_brick # skip if dead
    addi $sp, $sp, -16
    sw $t0, 0($sp)
    sw $t1, 4($sp)
    sw $t2, 8($sp)
    sw $t3, 12($sp)
    move $a0, $s3
    move $a1, $s4
    move $a2, $s5
    move $a3, $s6
    jal handle_ball_rect_collision

    
    beq $v0, 1, handle_vert_ball_brick_collision
    beq $v0, 2, handle_hori_ball_brick_collision
    beq $v0, 3, handle_vert_ball_brick_collision
    beq $v0, 4, handle_hori_ball_brick_collision
    
    addi $s0, $s0, 4
    addi $s2, $s2, 1
    b handle_ball_brick_collision_loop

skip_brick:
    addi $s0, $s0, 4
    addi $s2, $s2, 1
    b handle_ball_brick_collision_loop

handle_vert_ball_brick_collision:
    la $t0, ball
    sub $s6, $0, $s6
    sw $v1, 4($t0)  # store new y position
    sw $s6, 16($t0)  # store new y vel
    li $t1, 1
    sw $t1, 0($s0) # mark as dead
    li $v0, 1
    jal beep_sound3
    b handle_ball_brick_collision_epi

handle_hori_ball_brick_collision:
    la $t0, ball
    sub $s5, $0, $s5
    sw $v1, 0($t0)  # store new x position
    sw $s5, 12($t0)  # store new x vel
    li $t1, 1
    sw $t1, 0($s0) # mark as dead
    li $v0, 1
    jal beep_sound3
    b handle_ball_brick_collision_epi
    
handle_ball_brick_collision_no_collision:
    li $v0, 0
    b handle_ball_brick_collision_epi

handle_ball_brick_collision_epi:
    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $s2, 8($sp)
    lw $s3, 12($sp)
    lw $s4, 16($sp)
    lw $s5, 20($sp)
    lw $s6, 24($sp)
    lw $ra, 28($sp)
    addi $sp, $sp, 32
    jr $ra

handle_vert_ball_paddle_collision:
    sub $s4, $0, $s4
    sw $v1, 4($s0)  # store new y position
    sw $s4, 16($s0)  # store new y vel
    jal beep_sound1
    b move_ball_epi

handle_ball_left_wall_collision:
    # jal make_beep2
    sub $s3, $0, $s3
    li $t5, 8
    sw $t5, 0($s0)
    sw $s3, 12($s0)
    jal beep_sound2
    b move_ball_epi

    
handle_ball_right_wall_collision:
    sub $s3, $0, $s3
    li $t5, 245
    sw $t5, 0($s0)
    sw $s3, 12($s0)
    jal beep_sound2
    b move_ball_epi

    
handle_ball_top_wall_collision:
    sub $s4, $0, $s4 
    li $t5, 8
    sw $t5, 4($s0)
    sw $s4, 16($s0)
    jal beep_sound2
    b move_ball_epi


handle_game_reset:
    li $t0, 126
    li $t1, 100
    li $t2, 3
    li $t3, -2
    sw $t0, 0($s0)
    sw $t1, 4($s0)
    sw $t2, 12($s0)
    sw $t3, 16($s0)
    b move_ball_epi

move_ball_epi:
    # EPILOGUE
    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $s2, 8($sp)
    lw $s3, 12($sp)
    lw $s4, 16($sp)
    lw $ra, 20($sp)
    addi $sp, $sp, 24
    jr $ra
    
# (x_ball, y_ball, x_ball_vel, y_vall_vel, x_target, y_target, target_width, target_height) - collision_side, collision_reset_val
handle_ball_rect_collision:
    lw $t0, 0($sp)  # target_x
    lw $t1, 4($sp)  # target_y
    lw $t2, 8($sp)  # target_width
    add $t2, $t0, $t2  # target right edge
    lw $t3, 12($sp)  # target_height
    add $t3, $t1, $t3  # target bottom edge
    addi $sp, $sp, 16
    addi $sp, $sp, -36
    sw $s0, 32($sp)
    sw $s1, 28($sp)
    sw $s2, 24($sp)
    sw $s3, 20($sp)
    sw $s4, 16($sp)
    sw $s5, 12($sp)
    sw $s6, 8($sp)
    sw $s7, 4($sp)
    sw $ra, 0($sp)
    addi $sp, $sp, -8
    sw $a2, 4($sp)  # store x_ball_vel
    sw $a3, 0($sp)  # store y_ball_vel
    
    move $s0, $t0 # target left edge
    move $s1, $t1 # target top edge
    move $s2, $t2 # target right edge
    move $s3, $t3 # target bottom edge
    
    move $s4, $a0  # ball left edge
    move $s5, $a1  # ball top edge
    addi $s6, $a0, ball_size  # ball right edge
    addi $s7, $a1, ball_size  # ball bottom edge
    
    move $a0, $s2
    move $a1, $s6
    move $a2, $s0
    move $a3, $s4
    jal get_overlap
    move $s4, $v0  # x overlap
    
    move $a0, $s3
    move $a1, $s7
    move $a2, $s1
    move $a3, $s5
    jal get_overlap
    move $s5, $v0  # y overlap
        
    sgt $t0, $s4, 0  # 1 if overlap x
    sgt $t1, $s5, 0  # 1 if overlap y
    and $t3, $t0, $t1  # 1 if both overlap
    
    beq $t3, 0, no_collision  # if no collision
    bge $s4, $s5, handle_y_collision  # if overlap x >= overlap y
    b handle_x_collision  # if overlap x < overlap y

no_collision:
    addi $sp, $sp, 8
    li $v0, 0  # no collision
    li $v1, 0  # irrelevant
    b handle_collision_epi
  
handle_y_collision:
    lw $t0, 0($sp)  # get y_ball_vel
    addi $sp, $sp, 8
    bgt $t0, 0, handle_top_collision  # is y_ball_vel positive
    b handle_bottom_collision

handle_x_collision:
    lw $t0, 4($sp)  # get x_ball_vel
    addi $sp, $sp, 8
    bgt $t0, 0, handle_left_collision  # is x_ball_vel positive
    b handle_right_collision

handle_top_collision:
    li $v0, 1
    subi $t0, $s1, 4
    move $v1, $t0
    b handle_collision_epi

handle_bottom_collision:
    li $v0, 3
    addi $t0, $s3, 1
    move $v1, $t0
    b handle_collision_epi
    
handle_left_collision:
    li $v0, 4
    subi $t0, $s0, 4
    move $v1, $t0
    b handle_collision_epi

handle_right_collision:
    li $v0, 2
    addi $t0, $s2, 1
    move $v1, $t0
    b handle_collision_epi

#handle_ball_paddle_y_collision:
 #   sub $t4, $0, $t4 
  #  li $t5, 115
   # sw $t1, 0($s0)
   # sw $t5, 4($s0)
   # sw $t4, 16($s0)
   # li $v0, 1
   # b move_ball_epi
    
#handle_ball_paddle_x_collision:
 #   sub $t3, $0, $t3
  #  li $t5, 115
  #  sw $t1, 0($s0)
  #  sw $t5, 4($s0)
  #  sw $t3, 12($s0)
  #  li $v0, 1
  #  b move_ball_epi

handle_collision_epi:
    lw $s0, 32($sp)
    lw $s1, 28($sp)
    lw $s2, 24($sp)
    lw $s3, 20($sp)
    lw $s4, 16($sp)
    lw $s5, 12($sp)
    lw $s6, 8($sp)
    lw $s7, 4($sp)
    lw $ra, 0($sp)
    addi $sp, $sp, 36
    jr $ra

# (Aright, Bright, Aleft, Bleft) -> overlap
get_overlap:
    addi $sp, $sp, -12
    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $ra, 8($sp)
    
    jal min
    move $s0, $v0
    move $a0, $a2
    move $a1, $a3
    jal max
    move $s1, $v0
    
    sub $t0, $s0, $s1
    move $v0, $t0

    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $ra, 8($sp)
    addi $sp, $sp, 12
    jr $ra

max:
    bgt $a0, $a1, return_first
    b return_second
    
min:
    blt $a0, $a1, return_first
    b return_second
    
return_first:
    move $v0, $a0
    jr $ra

return_second:
    move $v0, $a1
    jr $ra


beep_sound1:
    li $a0, 65	    # pitch
    li $a1, 150	    # duration
    li $a2, 24 	    # instrument
    li $a3, 127	    # volume
    li $v0, 31
    syscall

    jr $ra

beep_sound2:
    li $a0, 80	    # pitch
    li $a1, 150	    # duration
    li $a2, 24 	    # instrument
    li $a3, 127	    # volume
    li $v0, 31
    syscall

    jr $ra

beep_sound3:
    li $a0, 45	    # pitch
    li $a1, 150	    # duration
    li $a2, 24 	    # instrument
    li $a3, 127	    # volume
    li $v0, 31
    syscall

    jr $ra

# draw_num0(x, y) -> void
#   draw a zero with left corner at (x, y)
draw_num0:
    # PROLOGUE
    addi $sp, $sp, -12
    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $ra, 8($sp)

    # BODY
    move $s0, $a0
    move $s1, $a1

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg1

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg2

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg3

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg4

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg5

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg6

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg7

    # EPILOGUE
    lw $ra, 8($sp)
    lw $s1, 4($sp)
    lw $s0, 0($sp)
    addi $sp, $sp, 12
    jr $ra

draw_num1:
    # PROLOGUE
    addi $sp, $sp, -12
    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $ra, 8($sp)

    # BODY
    move $s0, $a0
    move $s1, $a1

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg2

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg3

    # EPILOGUE
    lw $ra, 8($sp)
    lw $s1, 4($sp)
    lw $s0, 0($sp)
    addi $sp, $sp, 12
    jr $ra

draw_num2:
    # PROLOGUE
    addi $sp, $sp, -12
    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $ra, 8($sp)

    # BODY
    move $s0, $a0
    move $s1, $a1

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg1

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg2

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg4

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg5

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg7

    # EPILOGUE
    lw $ra, 8($sp)
    lw $s1, 4($sp)
    lw $s0, 0($sp)
    addi $sp, $sp, 12
    jr $ra


draw_num3:
    # PROLOGUE
    addi $sp, $sp, -12
    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $ra, 8($sp)

    # BODY
    move $s0, $a0
    move $s1, $a1

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg1

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg2

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg3

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg4

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg7

    # EPILOGUE
    lw $ra, 8($sp)
    lw $s1, 4($sp)
    lw $s0, 0($sp)
    addi $sp, $sp, 12
    jr $ra

draw_num4:
    # PROLOGUE
    addi $sp, $sp, -12
    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $ra, 8($sp)

    # BODY
    move $s0, $a0
    move $s1, $a1

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg2

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg3

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg6

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg7

    # EPILOGUE
    lw $ra, 8($sp)
    lw $s1, 4($sp)
    lw $s0, 0($sp)
    addi $sp, $sp, 12
    jr $ra


draw_num5:
    # PROLOGUE
    addi $sp, $sp, -12
    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $ra, 8($sp)

    # BODY
    move $s0, $a0
    move $s1, $a1

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg1

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg3

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg4

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg6

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg7

    # EPILOGUE
    lw $ra, 8($sp)
    lw $s1, 4($sp)
    lw $s0, 0($sp)
    addi $sp, $sp, 12
    jr $ra

draw_num6:
    # PROLOGUE
    addi $sp, $sp, -12
    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $ra, 8($sp)

    # BODY
    move $s0, $a0
    move $s1, $a1

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg1

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg3

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg4

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg5

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg6

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg7

    # EPILOGUE
    lw $ra, 8($sp)
    lw $s1, 4($sp)
    lw $s0, 0($sp)
    addi $sp, $sp, 12
    jr $ra

draw_num7:
    # PROLOGUE
    addi $sp, $sp, -12
    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $ra, 8($sp)

    # BODY
    move $s0, $a0
    move $s1, $a1

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg1

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg2

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg3

    # EPILOGUE
    lw $ra, 8($sp)
    lw $s1, 4($sp)
    lw $s0, 0($sp)
    addi $sp, $sp, 12
    jr $ra

draw_num8:
    # PROLOGUE
    addi $sp, $sp, -12
    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $ra, 8($sp)

    # BODY
    move $s0, $a0
    move $s1, $a1

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg1

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg2

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg3

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg4

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg5

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg6

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg7

    # EPILOGUE
    lw $ra, 8($sp)
    lw $s1, 4($sp)
    lw $s0, 0($sp)
    addi $sp, $sp, 12
    jr $ra

draw_num9:
    # PROLOGUE
    addi $sp, $sp, -12
    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $ra, 8($sp)

    # BODY
    move $s0, $a0
    move $s1, $a1

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg1

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg2

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg3

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg4

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg7

    # EPILOGUE
    lw $ra, 8($sp)
    lw $s1, 4($sp)
    lw $s0, 0($sp)
    addi $sp, $sp, 12
    jr $ra


# draw_seg1(x, y) -> void
draw_seg1:
    # PROLOGUE
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # BODY
    move $a0, $a0 
    move $a1, $a1 
    li $a2, seg_len 
    addi $a2, $a2, 1
    li $a3, 1 
    addi $sp, $sp, -4
    li, $t0, white
    sw $t0, 0($sp)
    jal draw_rect

    # EPILOGUE
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

draw_seg2:
    # PROLOGUE
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # BODY
    addi $a0, $a0, seg_len
    move $a1, $a1 
    li $a2, 1
    li $a3, seg_len
    addi $a3, $a3, 1
    addi $sp, $sp, -4
    li, $t0, white
    sw $t0, 0($sp)
    jal draw_rect

    # EPILOGUE
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

draw_seg3:
    # PROLOGUE
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # BODY
    addi $a0, $a0, seg_len
    addi $a1, $a1, seg_len
    li $a2, 1
    li $a3, seg_len
    addi $a3, $a3, 1
    addi $sp, $sp, -4
    li, $t0, white
    sw $t0, 0($sp)
    jal draw_rect

    # EPILOGUE
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

draw_seg4:
    # PROLOGUE
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # BODY
    move $a0, $a0 
    addi $a1, $a1, seg_len 
    addi $a1, $a1, seg_len 
    li $a2, seg_len 
    addi $a2, $a2, 1 
    li $a3, 1 
    addi $sp, $sp, -4
    li, $t0, white
    sw $t0, 0($sp)
    jal draw_rect

    # EPILOGUE
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

draw_seg5:
    # PROLOGUE
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # BODY
    move $a0, $a0
    move $a1, $a1 
    li $a2, 1
    li $a3, seg_len
    addi $a3, $a3, 1
    addi $sp, $sp, -4
    li, $t0, white
    sw $t0, 0($sp)
    jal draw_rect

    # EPILOGUE
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

draw_seg6:
    # PROLOGUE
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # BODY
    move $a0, $a0
    addi $a1, $a1, seg_len
    li $a2, 1
    li $a3, seg_len
    addi $a3, $a3, 1
    addi $sp, $sp, -4
    li, $t0, white
    sw $t0, 0($sp)
    jal draw_rect

    # EPILOGUE
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

draw_seg7:
    # PROLOGUE
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # BODY
    move $a0, $a0 
    addi $a1, $a1, seg_len 
    li $a2, seg_len 
    add $a2, $a2, 1
    li $a3, 1 
    addi $sp, $sp, -4
    li, $t0, white
    sw $t0, 0($sp)
    jal draw_rect

    # EPILOGUE
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

