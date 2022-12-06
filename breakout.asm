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
.eqv seg_len 4	    # length of segments for numbers

.data

FRAMEBUFFER: 
    .space 0x20000	# reserved space for display
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display.
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard.
ADDR_KBRD:
    .word 0xffff0000

##############################################################################
# Mutable Data
##############################################################################
ball:
    .word   126			# x_pos
    .word   100			# y_pos
    .word   white		# ball_color 
    .word   0			# x_vel
    .word   0			# y_vel
    .word   ball_size		# ball_size
paddle:
    .word   112			# x_pos
    .word   116			# y_pos
    .word   paddle_width	# paddle_width
    .word   red			# paddle_color    
    .word   paddle_speed	# paddle_speed

# == interface for each brick in the brick_array == 
# brick:
    #.space  4			# x_pos   
    #.space  4			# y_pos   
    #.space  4			# color
    #.word   0			# is_dead  

brick_array:
    .space  4			# number of bricks
    .space  1000		# memory for array of bricks

is_paused:
    .word 0			# is_paused

score:
    .word 000			# current score
    
lives:
    .word 3 			# lives
    
##############################################################################
# Code
##############################################################################
	.text
	.globl main

# Initialize or reset all game data
main:
    jal init_bricks
    jal init_paddle
    jal init_ball
    jal init_score
    jal init_lives

# Main game loop
game_loop:
    jal handle_input	# handle inputs

    lw $t0, is_paused
    bne $t0, $zero, end_frame	# end the frame if the game is paused

    jal move_ball	# update the ball's position

    # Draw all game elements
    jal draw_bricks
    jal draw_paddle
    jal draw_ball
    jal draw_walls
    jal draw_lives
    li $a0, 10
    li $a1, 10
    jal draw_score
   
    # Tell the display to update
    lw $t8, ADDR_DSPL
    li $t9, 1
    sb $t9, 0($t8) 
    
    # Sleep before rerender
    li $a0, sleep_time
    li $v0, 32
    syscall

    # Reset the screen
    jal erase_screen

end_frame:
    # Fire the game loop
    b game_loop
    
quit_game:
    jal erase_screen	# Wipe the screen
    li $v0, 10		# Quit gracefully
    syscall

# get_location_address(x, y) -> address
#   Return the address of the unit on the display at location (x,y)
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
#	Draw a rectangle at a specified location on the bitmap
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

# draw_rect() -> void
#	Draw hearts for the lives
draw_lives:
   # PROLOGUE
   addi $sp, $sp, -16
   sw $s0, 0($sp)
   sw $s1, 4($sp)
   sw $s2, 8($sp)
   sw $ra, 12($sp)
   
   # BODY
   la $t0, lives
   lw $s0, 0($t0)
   li $s1, 0
   li $s2, 240

draw_lives_loop:
   beq $s1, $s0, draw_lives_epi
   move $a0, $s2
   li $a1, 13
   li $a2, 5
   li $a3, 5 
   li, $t0, red
   addi $sp, $sp, -4
   sw $t0, 0($sp)
   jal draw_rect	# Draw a heart
   subi $s2, $s2, 8
   addi $s1, $s1, 1
   b draw_lives_loop	# Reiterate

draw_lives_epi:
   # EPILOGUE
   lw $s0, 0($sp)
   lw $s1, 4($sp)
   lw $s2, 8($sp)
   lw $ra, 12($sp)
   addi $sp, $sp, 16
   jr $ra

# draw_walls() -> void
#	Draw the 3 game walls
draw_walls:
    # PROLOGUE
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    # BODY
    
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

# init_bricks() -> void
#	Initialze the bricks in the brick_array
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

# init_brick_line(y, brick_row, color) -> void
#	Initialze a row of bricks in the brick_array
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
    
# init_paddle() -> void
#	Resets the paddle
init_paddle:
    la $t0, paddle
    li $t1, 112
    li $t2, 116
    sw $t1, 0($t0)
    sw $t2, 4($t0)
    jr $ra

# init_ball() -> void
#	Resets the ball
init_ball:
    la $t0, ball
    li $t1, 126
    li $t2, 100
    li $t3, 0
    li $t4, 0
    sw $t1, 0($t0)
    sw $t2, 4($t0)
    sw $t3, 12($t0)
    sw $t4, 16($t0)
    jr $ra

# init_score() -> void
#	Resets the score
init_score:
    la $t0, score
    sw $0, 0($t0)
    jr $ra

# init_lives() -> void
#	Resets the lives
init_lives:
    # Initialize the game
    la $t0, lives
    li $t1, 3
    sw $t1, 0($t0) # lives
    jr $ra

# draw_bricks() -> void
#	Draws all the bricks from brick_array
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

# Skip a drawing a brick if it is dead
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
#	Draw the paddle
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

# draw_ball() -> void
#	Draws the ball
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
#	Wipes the screen black
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
#	Handles all valid keyboard inputs
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

    move $a0, $t2
    li $v0, 1
    syscall

    beq $t2, 97, move_paddle_left	# a
    beq $t2, 100, move_paddle_right	# d
    beq $t2, 112, handle_pause_game	# p
    beq $t2, 32, handle_launch_ball   	# space
    beq $t2, 113, quit			# q
    j handle_input_epi

# Only handles unpausing as a valid input
handle_input_paused_mode:
    beq $t2, 117, handle_unpause_game	# u
    j handle_input_epi
# Moves the paddle left one unit
move_paddle_left:
    li $a0, -1
    jal move_paddle
    j handle_input_epi
# Moves the paddle right one unit
move_paddle_right:
    li $a0, 1
    jal move_paddle
    j handle_input_epi
# Pauses the game
handle_pause_game:
    li $t0, 1
    sw $t0, is_paused
    j handle_input_epi
# Unpauses the game
handle_unpause_game:
    sw $zero, is_paused
    j handle_input_epi
# Launches requests to launch the ball
handle_launch_ball:
    la $t0, ball
    lw $t1, 16($t0)
    beq $t1, 0, launch_ball
    j handle_input_epi     
# Launches the ball
launch_ball:
    li $t2, -3
    sw $t2, 16($t0)
    j handle_input_epi
# Quits the game
quit:
    jal quit_game

handle_input_epi:
    # EPILOGUE
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
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
    bge $t1, 220, handle_paddle_right_collision
    
    la $t4, ball
    lw $t5, 16($t4)	# ball_y_vel
    beq $t5, 0, move_ball_to_match_paddle
    
    sw $t1, 0($t0)	# update x position of paddle
    b move_paddle_epi
# When in launch mode, move both the paddle and the ball
move_ball_to_match_paddle:
    lw $t5, 0($t4)
    add $t5, $t5, $t3
    sw $t5, 0($t4)
    sw $t1, 0($t0)	# update x position of paddle
    b move_paddle_epi
# Handles the collisions with paddle and left wall
handle_paddle_left_collision: 
    addi $t4, $0, 7
    sw $t4, 0($t0)
    b move_paddle_epi
# Handles collisions with paddle and right wall
handle_paddle_right_collision: 
    addi $t4, $0, 220
    sw $t4, 0($t0)
    b move_paddle_epi

move_paddle_epi:
    # EPILOGUE
    jr $ra

# move_ball() -> void
#	Updates the ball position and handles collisions
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

    ble $t1, 7, handle_ball_left_wall_collision		# ball and left wall collision
    bge $t1, 246, handle_ball_right_wall_collision	# ball and right wall collision
    ble $t2, 7, handle_ball_top_wall_collision		# ball and top wall collision
    bge $t2, 125, handle_death				# ball and bottom line collision
    
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
    
    bne $v0, 0, handle_ball_paddle_collision	# handle the ball and paddle collision if a collision occured
    
    move $a0, $s1 # ball x pos
    move $a1, $s2 # ball y pos
    move $a2, $s3 # ball x vel
    move $a3, $s4 # ball y vel
    jal handle_ball_brick_collision		# handle ball and brick collisions
    beq $v0, 1, move_ball_epi # branch if collision
    
    sw $s1, 0($s0)
    sw $s2, 4($s0)
    
    b move_ball_epi

# Handle ball collision with bottom line
handle_death:
    la $t0, lives
    lw $t1, 0($t0)
    subi $t1, $t1, 1
    beq $t1, 0, main
    sw $t1, 0($t0) # store new lives
    jal init_ball
    jal init_paddle
    b move_ball_epi

# handle_ball_brick_collision(ball_x, ball_y, ball_x_vel, ball_y_vel) -> (collsion_side, new_ball_pos)
#	Returns the side on which the collision occured and a new_ball_pos outside the object it just collided with
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

# Loop through brick array
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
    jal handle_ball_rect_collision	# check for a collision with the current brick
    beq $v0, 1, handle_vert_ball_brick_collision	# top collision
    beq $v0, 2, handle_hori_ball_brick_collision	# right collision
    beq $v0, 3, handle_vert_ball_brick_collision	# bottom collision
    beq $v0, 4, handle_hori_ball_brick_collision	# left collision
    
    addi $s0, $s0, 4
    addi $s2, $s2, 1
    b handle_ball_brick_collision_loop		# Reiterate

# skip collision handling if the brick is dead
skip_brick:
    addi $s0, $s0, 4
    addi $s2, $s2, 1
    b handle_ball_brick_collision_loop

# handle a vertical collision with a brick 
handle_vert_ball_brick_collision:
    la $t0, ball
    sub $s6, $0, $s6
    sw $v1, 4($t0)  # store new y position
    sw $s6, 16($t0)  # store new y vel
    li $t1, 1
    sw $t1, 0($s0) # mark as dead
    li $v0, 1
    jal increment_score
    jal beep_sound3
    b handle_ball_brick_collision_epi

# handle a horizontal collision with a brick
handle_hori_ball_brick_collision:
    la $t0, ball
    sub $s5, $0, $s5
    sw $v1, 0($t0)  # store new x position
    sw $s5, 12($t0)  # store new x vel
    li $t1, 1
    sw $t1, 0($s0) # mark as dead
    li $v0, 1
    jal increment_score
    jal beep_sound3
    b handle_ball_brick_collision_epi
    
# handle the case where no collision has occured
handle_ball_brick_collision_no_collision:
    li $v0, 0
    b handle_ball_brick_collision_epi

handle_ball_brick_collision_epi:
    # EPILOGUE
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

# handle a ball's collision with the paddle
handle_ball_paddle_collision:
    li $t0, 112
    sw $t0, 4($s0)  # store new y position
    la $t3, ball
    lw $t0, 0($t3)
    la $t1, paddle
    lw $t1, 0($t1)
    sub $t2, $t0, $t1
    addi $t2, $t2, 2 # distance of ball from 2 pixels before left edge of paddle (this value is between 0 and 31 inclusive)    
    bge $t2, 27, set_ball_speed_3	# make the ball bounce sharp right
    bge $t2, 22, set_ball_speed_2	# make the ball bounce right
    bge $t2, 18, set_ball_speed_1	# make the ball bounce a bit right
    bge $t2, 14, set_ball_speed_0	# make the ball bounce straight up
    bge $t2, 10, set_ball_speed_neg_1   # make the ball bounce a bit left
    bge $t2, 5, set_ball_speed_neg_2	# make the ball bounce left
    b set_ball_speed_neg_3		# make the ball bounce sharp left
# make the ball bounce sharp right
set_ball_speed_3:
   li $t4, 5
   li $t5, -3
   sw $t4, 12($t3)
   sw $t5, 16($t3)
   b handle_ball_paddle_collision_epi
# make the ball bounce right
set_ball_speed_2:
   li $t4, 3
   li $t5, -3
   sw $t4, 12($t3)
   sw $t5, 16($t3)
   b handle_ball_paddle_collision_epi
# make the ball bounce a bit right
set_ball_speed_1:
   li $t4, 2
   li $t5, -2
   sw $t4, 12($t3)
   sw $t5, 16($t3)
   b handle_ball_paddle_collision_epi
# make the ball bounce straight up
set_ball_speed_0:
   li $t4, 0
   li $t5, -2
   sw $t4, 12($t3)
   sw $t5, 16($t3)
   b handle_ball_paddle_collision_epi
# make the ball bounce a bit left
set_ball_speed_neg_1:
   li $t4, -2
   li $t5, -2
   sw $t4, 12($t3)
   sw $t5, 16($t3)
   b handle_ball_paddle_collision_epi
# make the ball bounce left
set_ball_speed_neg_2:
   li $t4, -3
   li $t5, -4
   sw $t4, 12($t3)
   sw $t5, 16($t3)
   b handle_ball_paddle_collision_epi
# make the ball bounce sharp left
set_ball_speed_neg_3:
   li $t4, -3
   li $t5, -5
   sw $t4, 12($t3)
   sw $t5, 16($t3)
   b handle_ball_paddle_collision_epi
   
handle_ball_paddle_collision_epi:
    # EPILOGUE
    jal beep_sound1
    b move_ball_epi

# handle the ball's collision with the left wall
handle_ball_left_wall_collision:
    sub $s3, $0, $s3
    li $t5, 8
    sw $t5, 0($s0)
    sw $s3, 12($s0)
    jal beep_sound2
    b move_ball_epi

# handle the ball's collision with the right wall
handle_ball_right_wall_collision:
    sub $s3, $0, $s3
    li $t5, 245
    sw $t5, 0($s0)
    sw $s3, 12($s0)
    jal beep_sound2
    b move_ball_epi

# handle the ball's collision with the top wall
handle_ball_top_wall_collision:
    sub $s4, $0, $s4 
    li $t5, 8
    sw $t5, 4($s0)
    sw $s4, 16($s0)
    jal beep_sound2
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
    
# handle_ball_rect_collision(x_ball, y_ball, x_ball_vel, y_vall_vel, x_target, y_target, target_width, target_height) - (collision_side, collision_reset_val)
#	Returns the side on which the ball collided, and 0 if no collision, as well as a position value to set the ball to after this collision
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

# handle no collision
no_collision:
    addi $sp, $sp, 8
    li $v0, 0  # no collision
    li $v1, 0  # irrelevant
    b handle_collision_epi
  
# handle a vertical collision
handle_y_collision:
    lw $t0, 0($sp)  # get y_ball_vel
    addi $sp, $sp, 8
    bgt $t0, 0, handle_top_collision  # is y_ball_vel positive
    b handle_bottom_collision

# handle a horizontal collision
handle_x_collision:
    lw $t0, 4($sp)  # get x_ball_vel
    addi $sp, $sp, 8
    bgt $t0, 0, handle_left_collision  # is x_ball_vel positive
    b handle_right_collision

# handle a collision from the top
handle_top_collision:
    li $v0, 1
    subi $t0, $s1, 4
    move $v1, $t0
    b handle_collision_epi

# handle a collision from the bottom
handle_bottom_collision:
    li $v0, 3
    addi $t0, $s3, 1
    move $v1, $t0
    b handle_collision_epi
    
# handle a collision from the left 
handle_left_collision:
    li $v0, 4
    subi $t0, $s0, 4
    move $v1, $t0
    b handle_collision_epi

# handle a collision from the right
handle_right_collision:
    li $v0, 2
    addi $t0, $s2, 1
    move $v1, $t0
    b handle_collision_epi

handle_collision_epi: 
    # EPILOGUE
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

# get_overlap(Amax, Bmax, Amin, Bmin) -> overlap
# 	Returns and integer representing the overlap in a certain direction between 2 rectangles
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

# max() -> int
#	Returns the max of 2 elements
max:
    bgt $a0, $a1, return_first
    b return_second

# min() -> int
#	Returns the min of 2 elements  
min:
    blt $a0, $a1, return_first
    b return_second
    
# Returns the first of two elements
return_first:
    move $v0, $a0
    jr $ra

# Returns the second of two elements
return_second:
    move $v0, $a1
    jr $ra

# beep_sound1() -> void
# 	Makes beep sound 1
beep_sound1:
    li $a0, 65	    # pitch
    li $a1, 150	    # duration
    li $a2, 24 	    # instrument
    li $a3, 127	    # volume
    li $v0, 31
    syscall
    jr $ra

# beep_sound2() -> void
#	Makes beep sound 2
beep_sound2:
    li $a0, 80	    # pitch
    li $a1, 150	    # duration
    li $a2, 24 	    # instrument
    li $a3, 127	    # volume
    li $v0, 31
    syscall
    jr $ra

# beep_sound3() -> void
# 	Makes beep sound 3
beep_sound3:
    li $a0, 45	    # pitch
    li $a1, 150	    # duration
    li $a2, 24 	    # instrument
    li $a3, 127	    # volume
    li $v0, 31
    syscall
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

draw_seg6:
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


# draw_score(x, y, num) -> void
draw_num:
    addi $sp, $sp, -12
    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $ra, 8($sp)

    # BODY
    # copy (x, y) parameters
    move $s0, $a0
    move $s1, $a1
    
    li $t0, 0
    beq $a2, $t0, draw_num0
    li $t0, 1
    beq $a2, $t0, draw_num1
    li $t0, 2
    beq $a2, $t0, draw_num2
    li $t0, 3
    beq $a2, $t0, draw_num3
    li $t0, 4
    beq $a2, $t0, draw_num4
    li $t0, 5
    beq $a2, $t0, draw_num5
    li $t0, 6
    beq $a2, $t0, draw_num6
    li $t0, 7
    beq $a2, $t0, draw_num7
    li $t0, 8
    beq $a2, $t0, draw_num8
    li $t0, 9
    beq $a2, $t0, draw_num9
    
    # error if ever reach this point
draw_num0:
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

    j draw_num_epi
draw_num1:
    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg2

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg3
    j draw_num_epi
draw_num2:
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
    j draw_num_epi
draw_num3:
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

    j draw_num_epi
draw_num4:
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

    j draw_num_epi
draw_num5:
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

    j draw_num_epi
draw_num6:
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

    move $a0, $s0 
    move $a1, $s1 

    j draw_num_epi
draw_num7:
    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg1

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg2

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg3

    j draw_num_epi

draw_num8:
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

    j draw_num_epi

draw_num9:
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
    jal draw_seg6

    move $a0, $s0 
    move $a1, $s1 
    jal draw_seg7

    j draw_num_epi
draw_num_epi:
    lw $ra, 8($sp)
    lw $s1, 4($sp)
    lw $s0, 0($sp)
    addi $sp, $sp, 12
    jr $ra

# draw_score(x, y) -> void
draw_score:
    addi $sp, $sp, -12
    sw $s0, 8($sp)
    sw $s1, 4($sp)
    sw $ra, 0($sp)
    
    # create copies of parameters
    move $s0, $a0
    move $s1, $a0
    
    # get hundreds digit
    lw $t0, score
    li $t1, 100
    li $t2, 10
    div $t0, $t1
    mflo $t1
    div $t1, $t2
    mfhi $a2
    # draw hundreds digit
    move $a0, $s0
    move $a1, $s1
    jal draw_num

    # get ten's digit
    lw $t0, score
    li $t1, 10
    li $t2, 10
    div $t0, $t1
    mflo $t1
    div $t1, $t2
    mfhi $a2
    # draw tens digit
    addi $s0, $s0, seg_len 
    addi $s0, $s0, 3 # padding
    move $a0, $s0
    move $a1, $s1
    jal draw_num

    # get ones's digit
    lw $t0, score
    li $t1, 1
    li $t2, 10
    div $t0, $t1
    mflo $t1
    div $t1, $t2
    mfhi $a2
    # draw ones digit
    addi $s0, $s0, seg_len 
    addi $s0, $s0, 3 # padding
    move $a0, $s0
    move $a1, $s1
    jal draw_num

    # EPILOGUE
    lw $ra, 0($sp)
    lw $s1, 4($sp)
    lw $s0, 8($sp)
    addi $sp, $sp, 12

    jr $ra
    
# increment_score() -> void
#	Increments the score in data
increment_score:
    lw $t0, score
    addi $t0, $t0, 1
    sw $t0, score
    jr $ra
