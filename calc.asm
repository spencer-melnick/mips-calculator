.data
str_buffer1:
	.space 64
expr_buffer1:
	.space 128
prompt_msg:
	.asciiz ">>>> "
invalid_msg:
	.asciiz "Invalid expression\n"

invalid_char_msg_p1:
	.asciiz "Invalid character \""
invalid_char_msg_p2:
	.asciiz "\" at index ["
invalid_char_msg_p3:
	.asciiz "]\n"

invalid_num_msg_p1:
	.asciiz "Numeral length exceeds 4 at index ["
invalid_num_msg_p2:
	.asciiz "]\n"

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

	# Display invalid character and location
invalid_character:
	# Display message part 1
	li	$v0, 4
	la	$a0, invalid_char_msg_p1
	syscall

	# Display character
	li	$v0, 11
	move	$a0, $t1
	syscall

	# Display message part 2
	li	$v0, 4
	la	$a0, invalid_char_msg_p2
	syscall

	# Display index
	li	$v0, 1
	move	$a0, $t0
	syscall
	
	# Display message part 3
	li	$v0, 4
	la	$a0, invalid_char_msg_p3
	syscall

	j	main_end

invalid_numeral:
	# Display message part 1
	li	$v0, 4
	la	$a0, invalid_num_msg_p1
	syscall

	# Display index
	li	$v0, 1
	move	$a0, $t0
	syscall

	# Display message part 2
	li	$v0, 4
	la	$a0, invalid_num_msg_p2
	syscall

	j	main_end
	
invalid_expression:
	# Print invalid message
	li	$v0, 4
	la	$a0, invalid_msg
	syscall
	j	main_end
	
main_end:
	j	main
	

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
	# Token type 10 - skip token
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
	# $t5 as numeral length
	#
	# Machne states are as follows:
	# State 0 - reading
	# State 1 - reading number
	
	# Initialize registers
	li	$t0, 0
	li	$t1, 0
	li	$t2, 0
	li	$t3, 0
	li	$t4, 0
	li	$t5, 0

lex_convert_loop:
	# Read next character
	lb	$t1, str_buffer1($t0)
	
	# Jump to machine state
	beq	$t2, 0, lex_convert_state_0
	beq	$t2, 1, lex_convert_state_1


# Initial reading state
lex_convert_state_0:
	# Check for end of line characters
	beq	$t1, '\0', lex_convert_end
	beq	$t1, '\n', lex_convert_end

	# If ' ', skip
	beq	$t1, ' ', lex_convert_next_itr

	# Check if number
	blt	$t1, '0', lex_convert_state_0_not_num
	bgt	$t1, '9', lex_convert_state_0_not_num
	
	# Set FSM state to number reading
	li	$t2, 1

	# Set numeral length to 1
	li	$t5, 1
	
	# Convert character to number
	subiu	$t4, $t1, '0'
	
	j	lex_convert_next_itr
	
lex_convert_state_0_not_num:
	# Check if (
	bne	$t1, '(', lex_convert_state_0_not_open_paren
	
	# Store ( token
	lui	$t4, 1
	j	lex_convert_store_token
	
lex_convert_state_0_not_open_paren:
	# Check if )
	bne	$t1, ')', lex_convert_state_0_not_close_paren
	
	# Store ) token
	lui	$t4, 2
	j	lex_convert_store_token
	
lex_convert_state_0_not_close_paren:
	# Check if +
	bne 	$t1, '+', lex_convert_state_0_not_plus
	
	# Store + token
	lui 	$t4, 3
	j	lex_convert_store_token

lex_convert_state_0_not_plus:
	# Check if -
	bne	$t1, '-', lex_convert_state_0_not_minus

	# Store - token
	lui 	$t4, 4
	j	lex_convert_store_token


lex_convert_state_0_not_minus:
	# Check if *
	bne	$t1, '*', lex_convert_state_0_not_mult

	# Store * token
	lui 	$t4, 5
	j	lex_convert_store_token

lex_convert_state_0_not_mult:
	# Check if /
	bne	$t1, '/', lex_convert_state_0_not_div

	# Store / token
	lui 	$t4, 6
	j	lex_convert_store_token

lex_convert_state_0_not_div:
	# Check if =
	bne	$t1, '=', lex_convert_state_0_not_equals

	# Store / token
	lui 	$t4, 7
	j	lex_convert_store_token

lex_convert_state_0_not_equals:
	# Check if uppercase letter
	blt	$t1, 'A', lex_convert_not_character
	ble	$t1, 'Z', lex_convert_store_character
	blt	$t1, 'a', lex_convert_not_character
	ble	$t1, 'z', lex_convert_store_character

	j 	lex_convert_not_character

lex_convert_store_character:
	# Store variable token
	lui	$t4, 8
	or	$t4, $t4, $t1
	j	lex_convert_store_token

lex_convert_not_character:

	j	invalid_character
	
	
# Numeric reading state
lex_convert_state_1:
	# If not a number, move to state exit
	blt	$t1, '0', lex_convert_state_1_exit
	bgt	$t1, '9', lex_convert_state_1_exit
	
	# Otherwise, check numeral length
	addiu	$t5, $t5, 1
	bgt	$t5, 4, invalid_numeral
	
	# Increment stored token value
	mulu	$t4, $t4, 10
	
	# Convert $t0 to digit
	subiu	$t1, $t1, '0'
	
	# Add digit to token value
	addu	$t4, $t4, $t1
	
	j lex_convert_next_itr

lex_convert_state_1_exit:	
	# Put token type in upper 16 bits
	lui	$t7, 9
	or	$t4, $t4, $t7
	sw	$t4, expr_buffer1($t3)
	addiu	$t3, $t3, 4
	
	# Move back to state 0 without looping
	li	$t2, 0
	j lex_convert_state_0

lex_convert_store_token:
	# Store token and increment token index
	sw	$t4, expr_buffer1($t3)
	addiu	$t3, $t3, 4

	# Jump to next iteration
	j	lex_convert_next_itr
	
lex_convert_next_itr:
	addiu $t0, $t0, 1
	j lex_convert_loop

lex_convert_end:
	# Store an end of expression token before returning
	lui	$t4, 0
	sw	$t4, expr_buffer1($t3)
	jr	$ra
