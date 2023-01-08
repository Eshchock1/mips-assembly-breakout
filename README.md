# Breakout
Created in MIPS Assembly

## How to play

#### Running instructions
1. Open `breakout.asm` in EMARS
2. Open the bitmap display through Tools $>$ Bitmap Display++
3. Ensure the bitmap display configuration matches the configuration at the top of `breakout.asm`
4. Toggle `Attach Keyboard++` and click `Connect to to MIPS`
5. Assemble and run `breakout.asm` to play

#### Controls
- Press `spacebar` to launch the ball.
- Press `a` and `d` to move the paddle left and right.
- Press `p` and `u` to pause and unpause.
- Press `q` to quit the game.


## Additional Features

**Multiple lives**

Achieved by allocating memory for a `lives` variable and implementing a `draw_lives`
function which draws a red heart on the screen for each of the player's lives.
Whenever a collision is detected between the ball and the bottom of the screen,
the `lives` variable is decremented until it reaches 0 at which point the game completely resets.

**Different ball speeds**

Achieved by creating multiple `set_ball_speed` functions
which changes the velocity attributes of the ball.
Depending on where the ball hits on the paddle, a different
`set_ball_speed` function is called 
changing the direction and speed of the ball.


**Sound effects**

Achieved using the `MIDI out` syscall.
We created a function that performs the syscall which is called
every time a collision with the ball is detected.

**Pausing and unpausing**

Achieved by allocating memory for an `is_paused` variable.
If the value of `is_paused` is true, then the game loop will
only call the function for handling input and will
not call the function for drawing and moving objects.

**Launching the ball**

Achieved by initially setting the velocity of the ball to 0 and
then after detecting a `space` key press, setting the 
velocity of the ball to its normal value. The ball also follows the paddle until the space bar is clicked, allowing the ball to be launched at any desired location. 


**Displaying score**

We created methods for manually drawing each digit on the screen using the `draw_rect` function.
Allocated memory for a `score` variable which tracks the player's score
and increments every time the ball collides with a brick.
By extracting each digit of the `score` variable, 
we can draw each digit of the score on the screen.

