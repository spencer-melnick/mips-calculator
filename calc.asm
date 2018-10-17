.data
str_buffer1:
	.space 64
expr_buffer1:
	.space 128
expr_buffer2:
	.space 128

stack:
	.space 128

prompt_msg:
	.asciiz ">>>> "
invalid_msg:
	.asciiz "Invalid expression\n"
result_msg:
	.asciiz "\n"

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
	
divide_by_zero_msg:
	.asciiz "Divide by zero error\n"

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
	jal	convert_expr
	jal	evaluate_expr
	
	
	beqz	$s2, display_result
	#If $s2 is nonzero, assign temp variable
	move	$s1, $v0
display_result:	
	# Display result
	move	$a0, $v0
	li	$v0, 1
	syscall
	
	# Print result message
	li	$v0, 4
	la	$a0, result_msg
	syscall
	
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
	
divide_by_zero:
	# Print error message
	li	$v0, 4
	la	$a0, divide_by_zero_msg
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
	# Token type 7 - negate operator
	# Token type 8 - = operator
	# Token type 9 - variable
	# Token type 10 - numeric literal
	#
	# Numeric literals and variables have token values
	# representing either their numeric value or variable
	# name. Operators have token values equal to their
	# operator precedence.
	#
	# The most significant bit of the token value for a
	# variable represents whether or not to negate the
	# variable.
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
	# $t6 as previous token type
	#
	# Machine states are as follows:
	# State 0 - reading
	# State 1 - reading number
	
	# Initialize registers
	li	$t0, 0
	li	$t1, 0
	li	$t2, 0
	li	$t3, 0
	li	$t4, 0
	li	$t5, 0
	li	$t6, 0

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
	li	$t6, 1
	lui	$t4, 1
	ori	$t4, $t4, 0
	j	lex_convert_store_token
	
lex_convert_state_0_not_open_paren:
	# Check if )
	bne	$t1, ')', lex_convert_state_0_not_close_paren
	
	# Store ) token
	li	$t6, 2
	lui	$t4, 2
	ori	$t4, $t4, 0
	j	lex_convert_store_token
	
lex_convert_state_0_not_close_paren:
	# Check if +
	bne 	$t1, '+', lex_convert_state_0_not_plus

	# If previous token was an operator or left paren
	# skip
	ble	$t6, 1, lex_convert_next_itr
	bgt	$t6, 8, lex_convert_state_0_plus_passed_check
	beq	$t6, 2, lex_convert_state_0_plus_passed_check
	j	lex_convert_next_itr
	
lex_convert_state_0_plus_passed_check:
	# Store + token
	li	$t6, 3
	lui 	$t4, 3
	ori	$t4, $t4, 1
	j	lex_convert_store_token

lex_convert_state_0_not_plus:
	# Check if -
	bne	$t1, '-', lex_convert_state_0_not_minus

	# If previous token was an operator, left paren,
	# or empty, add an inversion operator
	ble	$t6, 1, lex_convert_state_0_invert_sign
	bgt	$t6, 8, lex_convert_state_0_minus_passed_check
	beq	$t6, 2, lex_convert_state_0_minus_passed_check
	
lex_convert_state_0_invert_sign:
	# Store invert token
	li	$t6, 7
	lui	$t4, 7
	ori	$t4, 3
	j	lex_convert_store_token
	
lex_convert_state_0_minus_passed_check:
	# Store - token
	li	$t6, 4
	lui 	$t4, 4
	ori	$t4, $t4, 1
	j	lex_convert_store_token


lex_convert_state_0_not_minus:
	# Check if *
	bne	$t1, '*', lex_convert_state_0_not_mult

	# Store * token
	li	$t6, 5
	lui 	$t4, 5
	ori	$t4, $t4, 2
	j	lex_convert_store_token

lex_convert_state_0_not_mult:
	# Check if /
	bne	$t1, '/', lex_convert_state_0_not_div

	# Store / token
	li	$t6, 6
	lui 	$t4, 6
	ori	$t4, $t4, 2
	j	lex_convert_store_token

lex_convert_state_0_not_div:
	# Check if =
	bne	$t1, '=', lex_convert_state_0_not_equals

	# Store = token
	li	$t6, 8
	lui 	$t4, 8
	ori	$t4, $t4, 4
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
	li	$t6, 9
	lui	$t4, 9
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
	li	$t6, 10
	lui	$t8, 10
	or	$t4, $t4, $t8
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
	#
	# The variable name will be stored in $s0
	# If the expression is an assignment, then 8 will
	# be stored in $s2
validate_expression:
	# $t0 as token index
	# $t1 as previous token
	# $t2 as current token
	# $t3 as paren counter
	# $t4 as value counter
	# $t6 as previous token type
	# $t7 as current token type
	# $t9 as new variable name
	# $s0 as variable name
	li	$t0, 0
	li	$t1, 0
	li	$t2, 0
	li	$t3, 0
	li	$t4, 0
	li	$t6, 0
	li	$t7, 0
	move	$t9, $s0
	li	$s2, 0

	# Check if expr[0] is =
	lw 	$t2, expr_buffer1
	srl	$t2, $t2, 16
	beq	$t2, 8, invalid_lhs

	# Check if expr[1] is =
	lw 	$t2, expr_buffer1+4
	srl	$t2, $t2, 16
	bne	$t2, 8, validate_expression_loop_start

	# Check if expr[0] is a variable
	lw	$t2, expr_buffer1
	srl	$t7, $t2, 16
	bne	$t7, 9, invalid_lhs

	# Set variable name
	andi	$t9, $t2, 0xffff

	# Set token index to 2
	li	$t0, 8
	li	$s2, 8

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
	beq	$t7, 8, invalid_expression
	
	# Check for variable
	bne	$t7, 9, validate_expression_not_variable
	
	# Get current token variable name
	andi	$t5, $t2, 0xffff
	
	# Increment value counter
	addiu	$t4, $t4, 1
	
	# If using a different variable name, invalidate
	bne	$t5, $s0, invalid_expression
	
	# Cannot follow a )
	beq	$t6, 2, invalid_expression
	
	# Cannot follow a number
	beq	$t6, 10, invalid_expression
	
	# Cannot follow another variable
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
	# Can't have -)
	beq	$t6, 7, invalid_expression
	
	j	validate_expression_next_itr
	
validate_expression_not_close_paren:
	# Check for * or /
	blt	$t7, 5, validate_expression_not_mult_or_divide
	bgt	$t7, 6, validate_expression_not_mult_or_divide	

	# * or / can only be preceeded by a number, variable
	# or close paren
	beq	$t6, 2, validate_expression_next_itr
	blt	$t6, 9, invalid_expression
	
	j	validate_expression_next_itr

validate_expression_not_mult_or_divide:
	# Check for number
	bne	$t7, 10, validate_expression_not_number

	# Increment value counter
	addiu	$t4, $t4, 1
	
	# Number preceeded by number or variable is invalid
	beq	$t6, 10, invalid_expression
	beq	$t6, 9, invalid_expression
	
validate_expression_not_number:
	j	validate_expression_next_itr
	
validate_expression_next_itr:
	addiu	$t0, $t0, 4
	j	validate_expression_loop

validate_expression_exit:
	# Must have at least 1 variable or numeric literal
	# in expression
	beqz	$t4, invalid_expression

	beq	$t6, 2, validate_expression_final_check_passed
	blt	$t6, 9, invalid_expression

validate_expression_final_check_passed:
	# Store new variable
	move	$s0, $t9
	jr	$ra
	
	########################################################
	# End validate_expression
	########################################################
	

	########################################################
	# convert_expression
	########################################################
	#
	# convert_expression converts the expression in
	# expr_buffer1 from infix notation to postfix notation
	# following the shunting-yard algorithm. The resulting
	# expression is stored in expr_buffer2, following the
	# same token format as lex_convert
convert_expr:
	# $t0 as token index
	# $t1 as token
	# $t2 as token type
	# $t3 as token output index
	# $t4, $t5, $t6 as temp
	# $t8 as stack pointer
	# $t9 as stack top token
	move	$t0, $s2
	li	$t1, 0
	li	$t2, 0
	li	$t3, 0
	li	$t8, 0
	li	$t9, 0

convert_expr_loop:
	# Load token value and type
	lw	$t1, expr_buffer1($t0)
	srl	$t2, $t1, 16

	# Check for end
	beq	$t2, 0, convert_expr_exit

	# Check if literal or variable
	blt	$t2, 9, convert_expr_not_value

	# Store in ouput
	sw	$t1, expr_buffer2($t3)
	addiu	$t3, $t3, 4
	j convert_expr_next_itr

convert_expr_not_value:
	# If left paren
	bne	$t2, 1, convert_expr_not_left_paren

	# Push to stack
	sw	$t1, stack($t8)
	addiu	$t8, $t8, 4
	move	$t9, $t1
	j convert_expr_next_itr

convert_expr_not_left_paren:
	# If right paren
	bne	$t2, 2, convert_expr_operator

	# $t5 as token type
	convert_expr_inner_loop1:
		# Peek token on stack
		srl	$t5, $t9, 16

		# Exit loop once left paren is found
		beq	$t5, 1, convert_expr_inner_loop1_end

		# Otherwise pop from the stack onto the result
		sw	$t9, expr_buffer2($t3)
		addiu	$t8, $t8, -8
		lw	$t9, stack($t8)
		addiu	$t8, $t8, 4
		addiu	$t3, $t3, 4

		j	convert_expr_inner_loop1

	convert_expr_inner_loop1_end:
		# Pop without storing for left paren
		addiu	$t8, $t8, -8

		# Update top stack value
		lw	$t9, stack($t8)
		addiu	$t8, $t8, 4

		j	convert_expr_next_itr


convert_expr_operator:

	# Get token operator precedence
	andi	$t4, $t1, 0xffff
	
	# Use $t4 as current token precedence
	# $t5 as stack token precedence
	# $t6 as stack token type
	convert_expr_inner_loop2:
		# Get stack token precedence
		andi	$t5, $t9, 0xffff

		# If current token has higher precedence
		# than stack token, or stack is at end,
		# or both tokens are invert,
		# exit loop
		beq	$t8, 0, convert_expr_inner_loop2_end
		bne	$t2, 7, convert_expr_no_negate_token
		srl	$t6, $t9, 16
		beq	$t6, 7, convert_expr_inner_loop2_end
	convert_expr_no_negate_token:
		bgt	$t4, $t5, convert_expr_inner_loop2_end

		# Otherwise pop stack onto result
		sw	$t9, expr_buffer2($t3)
		addiu	$t3, $t3, 4
		addiu	$t8, $t8, -8
		lw	$t9, stack($t8)
		addiu	$t8, $t8, 4

		j convert_expr_inner_loop2

	convert_expr_inner_loop2_end:
		# Push current token onto stack
		sw	$t1, stack($t8)
		addiu	$t8, $t8, 4
		move	$t9, $t1


convert_expr_next_itr:
	addiu	$t0, $t0, 4
	j convert_expr_loop

convert_expr_exit:

	convert_expr_inner_loop3:
		# If at the end of the stack, exit
		beq	$t8, 0, convert_expr_inner_loop3_end

		# Otherwise pop from the stack onto result
		sw	$t9, expr_buffer2($t3)
		addiu	$t3, $t3, 4
		addiu	$t8, $t8, -8
		lw	$t9, stack($t8)
		addiu	$t8, $t8, 4

		j convert_expr_inner_loop3
		
	convert_expr_inner_loop3_end:
		sw	$zero, expr_buffer2($t3)

	jr	$ra

	#####################################################
	# End convert_expr
	#####################################################



	#####################################################
	# evaluate_expr
	#####################################################
	#
	# evaluate_expr evaluates the postfix expression
	# stored in expr_buffer2
evaluate_expr:
	# $t0 as token index
	# $t1 as token
	# $t2 as token type
	# $t3 as operand 1
	# $t4 as operand 2
	# $t5 as temp
	# $t8 as stack pointer
	li	$t0, 0
	li	$t1, 0
	li	$t2, 0
	li	$t3, 0
	li	$t4, 0
	li	$t8, 0

evaluate_expr_loop:
	# Load token
	lw	$t1, expr_buffer2($t0)
	srl	$t2, $t1, 16

	# Check for end token
	beq	$t2, 0, evaluate_expr_exit

	# Check for operator
	bgt	$t2, 8, evaluate_expr_no_op

	# Load operands from stack
	addiu	$t8, $t8, -4
	lw	$t4, stack($t8)
	addiu	$t8, $t8, -4
	lw	$t3, stack($t8)

	# Perform + operation and store on stack
	bne	$t2, 3, evaluate_expr_no_add
	add	$t3, $t3, $t4
	sw	$t3, stack($t8)
	addiu	$t8, $t8, 4
	j 	evaluate_expr_next_itr

evaluate_expr_no_add:
	# Perform - operation and store on stack
	bne	$t2, 4, evaluate_expr_no_sub
	sub	$t3, $t3, $t4
	sw	$t3, stack($t8)
	addiu	$t8, $t8, 4
	j 	evaluate_expr_next_itr

evaluate_expr_no_sub:
	# Perform * operation and store on stack
	bne	$t2, 5, evaluate_expr_no_mult
	mul	$t3, $t3, $t4
	sw	$t3, stack($t8)
	addiu	$t8, $t8, 4
	j 	evaluate_expr_next_itr

evaluate_expr_no_mult:
	# Perform / operation and store on stack
	bne	$t2, 6, evaluate_expr_no_div
	beqz	$t4, divide_by_zero
	div	$t3, $t3, $t4
	sw	$t3, stack($t8)
	addiu	$t8, $t8, 4
	j 	evaluate_expr_next_itr

evaluate_expr_no_div:
	# Perform negate operation and store on stack
	bne	$t2, 7, evaluate_expr_next_itr
	sub	$t4, $zero, $t4
	sw	$t3, stack($t8)
	addiu	$t8, $t8, 4
	sw	$t4, stack($t8)
	addiu	$t8, $t8, 4
	j 	evaluate_expr_next_itr

evaluate_expr_no_op:
	bne	$t2, 9, evaluate_expr_no_variable
	# Push stored variable to stack
	sw	$s1, stack($t8)
	addiu	$t8, $t8, 4
	j 	evaluate_expr_next_itr

evaluate_expr_no_variable:
	andi	$t1, 0xffff
	sw	$t1, stack($t8)
	addiu	$t8, $t8, 4

evaluate_expr_next_itr:
	addiu	$t0, $t0, 4
	j evaluate_expr_loop


evaluate_expr_exit:
	# Pop from the top of the stack
	lw	$v0, stack
	jr	$ra
	
