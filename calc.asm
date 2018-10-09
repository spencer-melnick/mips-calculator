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

invalid_lhs_msg:
	.asciiz "Left hand side of expression must be a variable name\n"
	
invalid_paren_msg:
	.asciiz "Mismatched parentheses\n"

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
	jal	validate_expression
	
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

invalid_lhs:
	# Print invalid message
	li	$v0, 4
	la	$a0, invalid_lhs_msg
	syscall
	j	main_end
	
invalid_paren:
	# Print invalid message
	li	$v0, 4
	la	$a0, invalid_paren_msg
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
	

	######################################################
	# lex_convert
	######################################################
	#
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

	###################################################
	# End lex_convert
	###################################################



	###################################################
	# validate_expression
	###################################################
	#
	# validate_expression checks the expression stored
	# at expr_buffer1 with a few simple checks:
	#
	# Only one = operator supported
	# Only one variable is allowed
	# The left hand side of must be only a variable token
	# Parentheses must be balanced
	# +* +/ -* -/ ** // */ /* (* (/ are invalid
	# ) must be followed by an operator
	#
	# validate_expression will jump unconditionally if
	# there are any errors
validate_expression:
	# $t0 as token index
	# $t1 as previous token
	# $t2 as current token
	# $t3 as paren counter
	# $t6 as previous token type
	# $t7 as current token type
	# $s0 as variable name
	li	$t0, 0
	li	$t1, 0
	li	$t2, 0
	li	$t3, 0
	li	$t6, 0
	li	$t7, 0

	# Check if expr[0] is =
	lw 	$t2, expr_buffer1
	srl	$t2, $t2, 16
	beq	$t2, 7, invalid_lhs

	# Check if expr[1] is =
	lw 	$t2, expr_buffer1+4
	srl	$t2, $t2, 16
	bne	$t2, 7, validate_expression_loop_start

	# Check if expr[0] is a variable
	lw	$t2, expr_buffer1
	srl	$t7, $t2, 16
	bne	$t7, 8, invalid_lhs

	# Set variable name
	andi	$s0, $t2, 0xffff

	# Set token index to 2
	li	$t0, 8
	j	validate_expression_loop_start

validate_expression_loop_start:
	li	$t2, 0
	li	$t7, 0
	j 	validate_expression_loop

validate_expression_loop:
	# Store old token and type
	move	$t1, $t2
	move	$t6, $t7
	
	# Load next token
	lw	$t2, expr_buffer1($t0)
	
	# Find current token type
	srl	$t7, $t2, 16
	
	# If token is end
	bne 	$t7, 0, validate_expression_not_end
	
	# Check paren counter
	bnez	$t3, invalid_expression
	j	validate_expression_exit
	
validate_expression_not_end:
	# Check for extra =
	beq	$t7, 7, invalid_expression
	
	# Check for variable
	bne	$t7, 8, validate_expression_not_variable
	
	# Get current token variable name
	andi	$t5, $t2, 0xffff
	
	# If using a different variable name, invalidate
	bne	$t5, $s0, invalid_expression
	
	# Cannot follow a )
	beq	$t6, 2, invalid_expression
	
	# Cannot follow a number
	beq	$t6, 9, invalid_expression
	
	j	validate_expression_next_itr
	
validate_expression_not_variable:
	# Check if (
	bne	$t7, 1, validate_expression_not_open_paren
	
	# Increment paren counter
	addiu	$t3, $t3, 1
	
	j	validate_expression_next_itr
	
validate_expression_not_open_paren:
	# Check if )
	bne	$t7, 2, validate_expression_not_close_paren
	
	# If paren counter goes below 0, invalid
	beqz	$t3, invalid_paren
	
	# Decrement paren counter
	subiu	$t3, $t3, 1
	
	# Can't have ()
	beq	$t6, 1, invalid_expression
	# Can't have +)
	beq	$t6, 3, invalid_expression
	# Can't have -)
	beq	$t6, 4, invalid_expression
	# Can't have *)
	beq	$t6, 5, invalid_expression
	# Can't have /)
	beq	$t6, 6, invalid_expression
	
	j	validate_expression_next_itr
	
validate_expression_not_close_paren:
	# Check for * or /
	blt	$t7, 5, validate_expression_not_mult_or_divide
	bgt	$t7, 6, validate_expression_not_mult_or_divide	

	# * or / can only be preceeded by a number or variable
	# (or skip)
	blt	$t6, 8, invalid_expression
	
	j	validate_expression_next_itr

validate_expression_not_mult_or_divide:

	j	validate_expression_next_itr
	
validate_expression_next_itr:
	addiu	$t0, $t0, 4
	j	validate_expression_loop

validate_expression_exit:
	jr	$ra

	
