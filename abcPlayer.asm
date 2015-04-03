# MIPS ABC Player
# Signify start of program.
.text	
.globl	main
main:
	jal openfile	# open the file
	jal readheader	# encodes the key, gets readchar ready to read the first note.
	jal playnotes 	# read and play notes from readchar.
	jal closefile	# close the file.
	jal exit	# exit.


# SAVED REGISTER DEFINITIONS

# Keep in mind, MIPS register conventions are:
# v0-v1 return value registers:	Use this to output data from procedures.
# a0-a3 argument registers: 	Use this to input data to procedures.
# t0-t9 general registers:	You can do whatever you want with these. 
# s0-s8 saved registers:	Special values we should save.
# And be sure to use the stack if you need more registers.

# s0 
# This is the address, or file descriptor, of the loaded abc file. 

# s1 
# This is the list of sharps and flats. You determine this by reading K: in the file. We will support the keys of A-G and A-G minor.
# Do not consider other modes. The job will be to convert the key into a list of sharps and flats.
# Here is my suggestion. Use this encoding:
# MIPS BIT # ...  7  6  5  4  3  2  1  0
# MEANING ......  A  B  C  D  E  F  G  SHARP?
# So for each key, A thru G including minors, get the notes in the key that are sharp or flat and flip the appropriate bits.
# Here is a good website to quickly find this information. http://www.playpiano.com/wordpress/flats-sharps/flats-sharps
# For Example, the key of A has 3 sharps, and they are F C G.
# So Encode $s1 as 0 0 1 0 0 1 1 1
# Another Example, D flat major. B E A D G all flat.
# So Encode $s1 as 1 1 0 1 1 0 1 0

# s2 is the Note Length. It is denoted by L: in the file. 
# I can't think of a good way to manipulate this so ignore for now.

# Opens ABC file specified by user.
# REGISTER INPUTS none
# REGISTER OUTPUTS file descriptior at $s0
# Daniel TODO have the user type in a filepath instead of loading the file from .data (at bottom of program)
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
readchar:
	li	$v0, 14		# Read File Syscall
	move	$a0, $s0	# Load File Descriptor
	la	$a1, buffer	# Load Buffer Address
	li	$a2, 1	# Buffer Size
	syscall
	jr $ra 

# REGISTER INPUTS file desciptor at $s0
# REGISTER OUTPUTS Key encoding at $s1
# TODO Larissa
readheader:
	# Use readchar and extract the key from the header. It is denoted by K:
	# Encode the header into $s1 using the method described above.
	# When the header ends and the notes start, (singified by |) end the routine.
	jr $ra

# Quick and dirty way to print value after readchar
qprint:
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

# REGISTER INPUTS none
# REGISTER OUTPUTS none
# TODO - Juheena
playnotes:
	# go for a basic implementation here.
	# For each note (letter) in the file, convert the pitch  denotated by that letter to a number.
	# put that number in $a0 and call playnote.
	# You can read this for more info on notes:
	# http://trillian.mit.edu/~jc/music/abc/doc/ABCtut_Notes.html
	# Also we encode like this
	# http://newt.phys.unsw.edu.au/jw/notes.html
	# For now, please encode the notes like this:
	# a 57	A 69
	# b 59	B 71
	# c 60	C 72
	# d 62	D 74
	# e 64	E 76
	# f 65	F 77
	# g 67	G 79
	# Ignore numbers and | for now.

	# End when you run out of notes to play.
	jr $ra
	
# REGISTER INPUTS none
# REGISTER OUTPUTS none
# TODO William play the right note based the pitch and key. Eventually add length too.
playnote:
	#http://newt.phys.unsw.edu.au/jw/notes.html
   	li $v0, 31  		# syscall to play midi  
    	li $a0, 60 	     	# set midi pitch to c
    	li $a1, 100		# set midi duration to 1000 ms (1 second)  
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
file:	.asciiz	"C:\\ABC Project\\sample.txt"
cont: 	.ascii "\nqprint : " 
buffer: .space 1024 
newline:.asciiz	"\n"
