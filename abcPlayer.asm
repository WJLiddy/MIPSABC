# MIPS ABC Player
# Signify start of program.
.text	
.globl	main
main:
	# The magic of procedures:
	jal openfile	# open the file.
	jal readchar	# read a single character from the file and print.
	jal closefile	# close the file.
    	jal playnote	# play some note.
	jal exit	# exit.


# PROCEDURE DEFINITIONS

# Keep in mind, mips register conventions are:
# v0-v1 return value registers:	In most cases, use this to output data from procedures.
# a0-a3 argument registers: 	In most cases, use this to input data to procedures.
# t0-t9 general registers:	You can do whatever you want with these. 
# s0-s8 saved registers:	Special values we should save.

# SAVED REGISTER DEFINITIONS

# s0 is the address, or file descriptor, of the loaded midi file.

# Prompts the user for an input, then saves the file descriptor at $s0
# REGISTER INPUTS none
# REGISTER OUTPUTS file descriptior at $s0
# TODO have user specify inputs instead of loading them from data (at bottom of program)
# TODO correctly handle errors such as file note found.
openfile:
	li	$v0, 13		# Open File Syscall
	la	$a0, file	# Load File Name
	li	$a1, 0		# Read-only Flag
	li	$a2, 0		# (ignored)
	syscall
	move	$s0, $v0	# Save File Descriptor
	#blt	$v0, 0, err	# Goto Error
	jr $ra 

# Reads a character from the file. 
# REGISTER INPUTS file descriptor at $s0
# REGISTER OUTPUTS read value at $v0 
# TODO write a seperate procedure for print.
# TODO use a saved register (perhaps s1?) to store where we are in the file instead of starting over from the file every time.
readchar:
	li	$v0, 14		# Read File Syscall
	move	$a0, $s0	# Load File Descriptor
	la	$a1, buffer	# Load Buffer Address
	li	$a2, 1	# Buffer Size
	syscall
	
	# Print Data
	li	$v0, 4		# Print String Syscall
	la	$a0, cont	# Load Contents String
	syscall
	
	jr $ra 

# Closes the file
# REGISTER INPUTS file descriptor at $s0
# REGISTER OUTPUTS none
closefile:
	li	$v0, 16		# Close File Syscall
	move	$a0, $s0	# Load File Descriptor
	syscall
	jr $ra  


# REGISTER INPUTS $a0 the symbol of the note to play, $a1 the symbol of the musical duration of the note
# REGISTER OUTPUTS none
# TODO Blatantly ignores inputs and just plays a note.
playnote:
   	li $v0, 31  		# syscall to play midi  
    	li $a0, 60 	     	# set midi pitch to c
    	li $a1, 1000		# set midi duration to 1000 ms (1 second)  
    	li $a2, 0		# set midi instrument to piano d
	li $a3, 127		# TURN IT UP TO 11
    	syscall
	jr $ra 
	
# Quits the progam.
# REGISTER INPUTS none
# REGISTER OUTPUTS none
exit:
	li	$v0,10	
	syscall


# Start .data segment (data!)
	.data
file:	.asciiz	"C:\\ABC Project\\sample.abc"
cont:	.ascii  "File contents: "
buffer: .space 1024 
newline:   .asciiz	"\n"
