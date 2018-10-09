.data
str_buffer1:
	.space 64
expr_buffer1:
	.space 128
prompt_msg:
	.asciiz ">>>> "
invalid_msg:
	.asciiz "Invalid expression"

.text
main:
	# Print prompt message
	li	$v0, 4
	la	$a0, prompt_msg
	syscall
	
	# Read 64 characters to string buffer
	li	$v0, 8
	la	$a0, str_buffer1
	li	$a1, 64
	syscall
	
	jal 	lex_convert
	j	main_end
	
invalid_expression:
	# Print invalid message
	li	$v0, 4
	la	$a0, invalid_msg
	syscall
	j	main_end
	
main_end:
	j	main_end
	

	# lex_convert converts a string to tokens representing
	# a mathematical expression. The tokens are saved as
	# follows:
	#
	# Upper 16 bits - token type
	# Lower 16 bits - token value (if applicable)
	#
	# Token type 0 - End of expression
	# Token type 1 - Open paren
	# Token type 2 - Close paren
	# Token type 3 - + operator
	# Token type 4 - - operator
	# Token type 5 - * operator
	# Token type 6 - / operator
	# Token type 7 - = operator
	# Token type 8 - variable
	# Token type 9 - numeric literal
	#
	# Only numeric literals and variables have token values
	#
	# No arguments are needed:
	# The string is read from str_buffer1 and
	# the result is stored in expr_buffer1
lex_convert:
	# Using:
	# $t0 as string index
	# $t1 as current character
	# $t2 as FSM state
	# $t3 as token index
	# $t4 as token value
	#
	# Machne states are as follows:
	# State 0 - reading
	# State 1 - read basic token
	# State 2 - reading number
	# State 3 - read variable
	
	# Initialize registers
	li	$t0, 0
	li	$t1, 0
	li	$t2, 0
	li	$t3, 0
	li	$t4, 0

lex_convert_loop:
	# Read next character
	lb	$t1, str_buffer1($t0)
	
	# Jump to machine state
	beq	$t2, 0, lex_convert_state_0
	#beq	$t2, 1, lex_convert_state_1
	beq	$t2, 2, lex_convert_state_2
	#beq	$t2, 3, lex_convert_state_3


# Initial reading state
lex_convert_state_0:
	# Check for end of line characters
	beq	$t1, '\0', lex_convert_end
	beq	$t1, '\n', lex_convert_end


	# Check if number
	blt	$t1, '0', lex_convert_state_0_not_num
	bgt	$t1, '9', lex_convert_state_0_not_num
	
	# Set FSM state to number reading
	li	$t2, 2
	
	# Convert character to number
	subiu	$t4, $t1, '0'
	
lex_convert_state_0_not_num:
	# Check if (
	bne	$t1, '(', lex_convert_state_0_not_open_paren
	
	# Store ( token
	lui	$t4, 1
	sw	$t4, expr_buffer1($t3)
	addiu	$t3, $t3, 4
	
	# Jump to next iteration
	j	lex_convert_next_itr
	
lex_convert_state_0_not_open_paren:
	# Check f )
	bne	$t1, ')', lex_convert_state_0_not_close_paren
	
	# Store ) token
	lui	$t4, 2
	sw	$t4, expr_buffer1($t3)
	addiu	$t3, $t3, 4
	
	# Jump to next iteration
	j	lex_convert_next_itr
	
lex_convert_state_0_not_close_paren:
	
	j	lex_convert_next_itr
	
	
# Numeric reading state
lex_convert_state_2:
	# If not a number, move to state exit
	blt	$t1, '0', lex_convert_state_2_exit
	bgt	$t1, '9', lex_convert_state_2_exit
	
	# Otherwise, increment stored token value
	mulu	$t4, $t4, 10
	
	# Convert $t0 to digit
	subiu	$t1, $t1, '0'
	
	# Add digit to token value
	addu	$t4, $t4, $t1
	
	j lex_convert_next_itr

lex_convert_state_2_exit:	
	# Put token type in upper 16 bits
	lui	$t7, 9
	or	$t4, $t4, $t7
	sw	$t4, expr_buffer1($t3)
	addiu	$t3, $t3, 4
	
	# Move back to state 0 without looping
	li	$t2, 0
	j lex_convert_state_0
	
lex_convert_next_itr:
	addiu $t0, $t0, 1
	j lex_convert_loop

lex_convert_end:
	# Store an end of expression token before returning
	lui	$t4, 0
	sw	$t4, expr_buffer1($t3)
	jr	$ra
