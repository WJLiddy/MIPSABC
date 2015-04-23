# MIPS ABC Player
# Signify start of program.
.text	
.globl	main
main:

	jal openfile	# open the file
	jal readheader	# encodes the key, gets readchar ready to read the first note.
	jal playnotes 	# loops until a '|' is found. then breaks.


# SAVED REGISTER DEFINITIONS
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

# s2 is the base note length. It is denoted by L: in the file. 
# convert to milliseconds please.

# s7 is used to save a note length when we read rhythms. do not bother with right now.

# Opens ABC file specified by user.
# REGISTER OUTPUTS file descriptior at $s0
openfile:
	
	# Ask for file name
	li $v0, 4
	la $a0, plzenter
    	syscall
    	
	# Get file string.
  	li $v0, 8
   	la $a0, file
    	li $a1, 21
    	syscall
    	
    	# Don't know how this works but it does. Converts file input to something the machine can read.
    	# Shamelessly stolen from google
   	li $t0, 0       #loop counter
    	li $t1, 21      #loop end
	clean:
    	beq $t0, $t1, L5
    	lb $t3, file($t0)
    	bne $t3, 0x0a, L6
    	sb $zero, file($t0)
    	L6:
    	addi $t0, $t0, 1
	j clean
	L5:
    	
    	# Opens up the file and saves descriptor
	li	$v0, 13		# Open File Syscall
	la	$a0, file	# Load File Name
	li	$a1, 0		# Read-only Flag
	li	$a2, 0		# (ignored)
	syscall
	move	$s0, $v0	# Save File Descriptor
	blt	$v0, 0, err	# Goto Error
	jr $ra 

# calls if the file does't load properly
err:
	li $v0, 4
	la $a0, fileerr
    	syscall
    	j exit
    	

# Reads a character from the file. The char is output in $v0. As a shortcut, this char be accessed as an int by using
#	li $t0, 0
#	lbu $t0, buffer($t0)
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
playnotes:

	#ignore for now.
	noteplayed:

	jal readchar
		
	# convert read char to an int	
	li $t0, 0
	lbu $t0, buffer($t0)


	#If it's a pipe exit.	
	li $t1, '|'
	beq $t0, $t1, exit
	
	li $t1, 'a'
	beq $t0, $t1, lowA
	li $t1, 'b'
	beq $t0, $t1, lowB
	li $t1, 'c'
	beq $t0, $t1, lowC
	li $t1, 'd'
	beq $t0, $t1, lowD
	li $t1, 'e'
	beq $t0, $t1, lowE
	li $t1, 'f'
	beq $t0, $t1, lowF
	li $t1, 'g'
	beq $t0, $t1, lowG
	li $t1, 'A'
	beq $t0, $t1, hiA
	li $t1, 'B'
	beq $t0, $t1, hiB
	li $t1, 'C'
	beq $t0, $t1, hiC
	li $t1, 'D'
	beq $t0, $t1, hiD
	li $t1, 'E'
	beq $t0, $t1, hiE
	li $t1, 'F'
	beq $t0, $t1, hiF
	li $t1, 'G'
	beq $t0, $t1, hiG

	#TODO throw error, don't skip space
	j noteplayed
		
	lowA:
	li $a0, 57
	jal playnote
	j noteplayed
	lowB:
	li $a0, 59
	jal playnote
	j noteplayed
	lowC:
	li $a0, 60
	jal playnote
	j noteplayed
	lowD:
	li $a0, 62
	jal playnote
	j noteplayed
	lowE:
	li $a0, 64
	jal playnote
	j noteplayed
	lowF:
	li $a0, 65
	jal playnote
	j noteplayed
	lowG:
	li $a0, 67
	jal playnote
	j noteplayed
	
	hiA:
	li $a0, 69
	jal playnote
	j noteplayed
	hiB:
	li $a0, 71
	jal playnote
	j noteplayed
	hiC:
	li $a0, 72
	jal playnote
	j noteplayed
	hiD:
	li $a0, 74
	jal playnote
	j noteplayed
	hiE:
	li $a0, 76
	jal playnote
	j noteplayed
	hiF:
	li $a0, 77
	jal playnote
	j noteplayed
	hiG:
	li $a0, 79
	jal playnote
	j noteplayed
	
# REGISTER INPUTS $a0 ID
# REGISTER OUTPUTS none
# TODO William play the right note based the pitch and key. Eventually add length too.
playnote:
	# a0 is the midi note name
	# s1 is the enconding (A-G) (S-BIT)

	# t0 will hold the sharp/flat bit.
	andi $t0, $s1, 1 	
	# t1 now stores the key encoding
	srl $t1, $s1, 1
	# t2 stores an octave, for moduluo
	li $t2, 12
	# now i need to get the note mod 12
	div $a0, $t2
	# note mod 12 in t3
	mfhi $t3
	
	# At this point: Here's what' in t1
	# MIPS BIT # ...  6  5  4  3  2  1  0
	# MEANING ......  A  B  C  D  E  F  G 
	
	# t3 conversion chart
	# C:0 D:2 E:4 F:5 G=7 A=9 B=11
	# 2^4 2^3 2^2 2^1 2^0 2^6 2^5
	#need to convert t3 to this style.
	li $t4, 0
	beq $t4, $t3, convertC
	li $t4, 2
	beq $t4, $t3, convertD
	li $t4, 4
	beq $t4, $t3, convertE
	li $t4, 5
	beq $t4, $t3, convertF
	li $t4, 7
	beq $t4, $t3, convertG
	li $t4, 9
	beq $t4, $t3, convertA	
	li $t4, 11
	beq $t4, $t3, convertB
	
	convertG:
	li $t5 , 1 
	j convertDone
	convertF:
	li $t5 , 2 
	j convertDone
	convertE:
	li $t5 , 4 
	j convertDone
	convertD:
	li $t5 , 8 
	j convertDone
	convertC:
	li $t5 , 16 
	j convertDone
	convertB:
	li $t5 , 32 
	j convertDone
	convertA:
	li $t5 , 64 
	
	convertDone:
	
	# and the note with the key
	and $t6, $t5, $t1	
	# did we get zero? then no note change! jump!
	beqz $t6, playnotewkey		
	
	# The key hit us!! flat or not?
	beqz $t0, flatmode
	
	addi $a0, $a0, 1
	j playnotewkey
	
	flatmode:
	subi $a0, $a0, 1
	j playnotewkey
	
	
	
	playnotewkey:
	
   	li $v0, 31 		# syscall to play midi  
    	li $a1, 300		# set midi duration to 100 ms (1 second)  
    	li $a2, 12		# set midi instrument to piano d
	li $a3, 127		# TURN IT UP TO 11
    	syscall

    	
    	li $v0, 32
    	li $a0, 250
    	syscall	
    	
	jr $ra 
	
# Quits the progam.
# REGISTER INPUTS none
# REGISTER OUTPUTS none
exit:
	jal closefile
	li	$v0,10	
	syscall

# Start .data segment (data!)
	.data
file:	.asciiz	"ABC Project\\sample.txt"
fileerr:.asciiz	"File not found"
plzenter:.asciiz	"Enter the name of the ABC file \n"
#file:	.asciiz ""
cont: 	.ascii "\nqprint : " 
buffer: .space 1024 
newline:.asciiz	"\n"
