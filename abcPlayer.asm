# MIPS ABC Player
.text	
.globl	main
main:

	# Allocate space for the note queue
	jal allocnotequeue
	# Opens the ABC file
	jal openfile
	# Read the information in the header.
	jal readheader	
	# Put the notes in a queue and play them
	jal playnotes 

# SAVED REGISTER DEFINITIONS
# s0 : the address, or file descriptor, of the loaded abc file. 

# s1 : key encoding
# bit # ........  7  6  5  4  3  2  1  0
# MEANING ......  A  B  C  D  E  F  G  SHARP?

# s2 is the base note length. It is denoted by L: in the file. 
# s3 is the memory start
# s4 is the memory pointer
# s5 is the note count

allocnotequeue:
	# allocate a bunch of bytes
	li $a0, 100000
	li $v0, 9
	syscall
	move $s3, $v0
	move $s4, $v0
	li $s5, 0
	jr $ra

# Opens ABC file specified by user.
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
    	
    	# Converts file input to something the machine can read.
   	li $t0, 0       
    	li $t1, 21    
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
    	

# Reads a character from the file.
readchar:
	li	$v0, 14		# Read File Syscall
	move	$a0, $s0	# Load File Descriptor
	la	$a1, buffer	# Load Buffer Address
	li	$a2, 1	# Buffer Size
	syscall
	# convert to an int	
	li $t0, 0
	lbu $v0, buffer($t0)
	jr $ra 

# Extract data from header such as tempo and note length
readheader:

	jal readchar		#Read character
	move $t1, $v0
	li $t0, 'K'			#K
	beq $t1, $t0, key	#If we find K 
	li $t3, 'L' 			#L
	beq $t1, $t3, tempo	#if we find L
	j readheader	#If we haven't hit K or L yet, read again

key: #initial read
	li $t0, 'K'			#K
	jal readchar			#after reading K, read next char
	li $t0, ':'			#:
	move $t1, $v0
	bne $t1, $t0, readheader	#if we just encountered a K, not K: as in the key code, keep looking: 58
	
	#at this point we are in the key code section: encountered K:
	jal readchar #should contain char code for key. check for space 
	move $t4, $v0 #t4 holds key code
	jal readchar 	#finish reading key
	move $t1, $v0
	li $t0, 109 #'m'
	seq $t3, $t2, $t1 	#t3 contains if minor or not
	mul $t3, $t1, $t3	#if minor: t3 stores m decimal val, else 0
	add $t4, $t4, $t3	#add this val into t4: holds adjusted key val now
	j setkey
	
readkey: #secondary read: tempo already set
	li $t0, 'K'		#K
	move $t1, $v0
	beq $t1, $t0, k	#if encountered k value
	jal readchar	#else readchar
	j readkey
	k:
	jal readchar
	li $t0, ':'		#:
	move $t1, $v0
	bne $t0, $t1, readkey	#if found K, not K:, keep looking
	##in key section K:
	jal readchar #should contain char code for key. check for space 
	move $t4, $v0 #t4 holds key code
	jal readchar 	#finish reading key
	move $t1, $v0
	li $t0, 'm' #'m'
	seq $t3, $t2, $t1 	#t3 contains if minor or not
	mul $t3, $t1, $t3	#if minor: t3 stores m decimal val, else 0
	add $t4, $t4, $t3	#add this val into t4: holds adjusted key val now
	j setkey


tempo: #initial read
	jal readchar			#after reading L, read next char
	li $t0, ':'			#:
	move $t1, $v0
	bne $t1, $t0, readheader	#if we just encountered an L, not L: as in the key code, keep looking: 58
	
	#at this point we are in the tempo code section: encountered L:
	jal readchar #should contain 1
	move $t1, $v0 #t1 holds first tempo #
	jal readchar 	#if contains /, else t = 1
	move $t2, $v0
	li $t0, '/' #'/'
	bne $t0, $t2, settempo #if there's no /, tempo is simply '1': held in t1
	add $t1, $t2, $t1	#update tempo value with /
	jal readchar		#next val must be a number
	move $t2, $v0
	add $t1, $t2, $t1	#update tempo code with next number
	jal readchar		#check if there's a second final following number
	move $t2, $v0
	li $t3, 9		#make sure number
	bgt $t2, $t3, settempo	#if not a number, set tempo
	add $t1, $t2, $t1	#if a number, add to tempo val
	j settempo		#tempo val completed: go to settempo
	

readtempo: #secondary read: key already set
	jal readchar
	move $t1, $v0 
	li $t0, 'L'		#L
	bne $t0, $t1, readtempo
	jal readchar
	move $t1, $v0
	li $t0, ':'		#:
	bne $t0, $t1, readtempo #if just L, not L:
	jal readchar 	#in L: block, should contain 1
	move $t1, $v0 #t1 holds first tempo #
	jal readchar 	#if contains /, else t = 1
	move $t2, $v0
	li $t0, '/' #'/'
	bne $t0, $t2, settempo #if there's no /, tempo is simply '1': held in t1
	add $t1, $t2, $t1	#update tempo value with /
	jal readchar		#next val must be a number
	move $t2, $v0
	add $t1, $t2, $t1	#update tempo code with next number
	jal readchar		#check if there's a second final following number
	move $t2, $v0
	li $t3, 9		#make sure number
	bgt $t2, $t3, settempo	#if not a number, set tempo
	add $t1, $t2, $t1	#if a number, add to tempo val
	j settempo		#tempo val completed: go to settempo

settempo:	#tempo code held in t1
	#####################back up one position in readchar
	li $t0, 1
	beq $t1, $t0, full
	li $t0, 49
	beq $t1, $t0, full
	li $t0, 50
	beq $t1, $t0, half
	li $t0, 52
	beq $t1, $t0, quarter
	li $t0, 56
	beq $t1, $t0, eighth
	li $t0, 64
	beq $t1, $t0, sixteenth
	li $t0, 80
	beq $t1, $t0, thirtysecondth
	full:
	li $t0, 1000
	move $s2, $t0
	j checkk
	half:
	li $t0, 500
	move $s2, $t0
	j checkk
	quarter:
	li $t0, 250
	move $s2, $t0
	j checkk
	eighth:
	li $t0, 125
	move $s2, $t0
	j checkk
	sixteenth:
	li $t0, 62
	move $s2, $t0
	j checkk
	thirtysecondth: 
	li $t0, 31
	move $s2, $t0
	j checkk
	
#sharps		sum of symbols	ABCDEFG
#C/Am:		67,174		00000001 
#G/Em: F	71,178		00000101
#D/Bm: FC	68,175		00100101
#A/F#m: FCG	65,214		00100111
#E/C#m: FCGD	69,211		00110111
#B/G#m: FCGDA	66,215		10110111
#F#/D#m: FCGDAE	105,212		10111111
#C#/A#m: FCGDAEB102,209 	11111111
#flats
#F/Dm: B	70,177		01000000
#Bb/Gm: BE	164,180		01001000
#Eb/Cm: BEA	167,176		11001000
#Ab/Fm: BEAD	163,179		11011000
#Db/Bbm: BEADG	166,273		11011010
#Gb/Ebm: BEADGC	169,276		11111010
#Cb/Abm: BEADGCF165,272		11111110
	
setkey: #t4 contains keycode, set s1 based on value
	#C, Am:
	li $t0, 67
	beq $t4, $t0, C
	li $t0, 174
	beq $t4, $t0, C
	#G, Em:
	li $t0, 71
	beq $t4, $t0, G
	li $t0, 178
	beq $t4, $t0, G
	#D/Bm
	li $t0, 68
	beq $t4, $t0, D
	li $t0, 175
	beq $t4, $t0, D
	#A, F#m
	li $t0, 65
	beq $t4, $t0, A
	li $t0, 214
	beq $t4, $t0, A
	#E, C#m
	li $t0, 69 
	beq $t4, $t0, E
	li $t0, 211
	beq $t4, $t0, E
	#B, G#m
	li $t0, 66
	beq $t4, $t0, B
	li $t0, 215
	beq $t4, $t0, B
	#F#, D#m
	li $t0, 105
	beq $t4, $t0, Fs
	li $t0, 212
	beq $t4, $t0, Fs
	#C#, A#m
	li $t0, 102
	beq $t4, $t0, Cs
	li $t0, 209
	beq $t4, $t0, Cs
	#F, Dm
	li $t0, 70
	beq $t4, $t0, F
	li $t0, 177
	beq $t4, $t0, F
	#Bb, Gm
	li $t0, 164
	beq $t4, $t0, Bb
	li $t0, 180
	beq $t4, $t0, Bb
	#Eb, Cm
	li $t0, 167
	beq $t4, $t0, Eb
	li $t0, 176
	beq $t4, $t0, Eb
	#Ab, Fm
	li $t0, 163
	beq $t4, $t0, Ab
	li $t0, 179
	beq $t4, $t0, Ab
	#Db, Bbm
	li $t0, 166
	beq $t4, $t0, Db
	li $t0, 273
	beq $t4, $t0, Db
	#Gb, Ebm
	li $t0, 169
	beq $t4, $t0, Gb
	li $t0, 276
	beq $t4, $t0, Gb
	#Cb, Abm
	li $t0, 165
	beq $t4, $t0, Cb 
	li $t0, 272
	beq $t4, $t0, Cb
	#sharps
	C: 
	addi $s1, $zero, 0x00000001
	j checkt
	G: 
	addi $s1, $zero, 0x00000101
	j checkt
	D:
	addi $s1, $zero, 0x00100101
	j checkt
	A:
	addi $s1, $zero, 0x00100111
	j checkt
	E:
	addi $s1, $zero, 0x00110111
	j checkt
	B:
	addi $s1, $zero, 0x10110111
	j checkt
	Fs:
	addi $s1, $zero, 0x10111111
	j checkt
	Cs:
	addi $s1, $zero, 0x11111111
	j checkt
	
	#flats
	F:
	addi $s1, $zero, 0x01000000
	j checkt
	Bb:
	addi $s1, $zero, 0x01001000
	j checkt
	Eb:
	addi $s1, $zero, 0x11001000
	j checkt
	Ab:
	addi $s1, $zero, 0x11011000
	j checkt
	Db:
	addi $s1, $zero, 0x11011010
	j checkt
	Gb:
	addi $s1, $zero, 0x11111010
	j checkt
	Cb:
	addi $s1, $zero, 0x11111110
	j checkt

checkt:
	beq $s2, $zero, readtempo	#if tempo hasn't been set yet
	j readthrough

checkk:
	beq $s1, $zero, readkey		#if key isn't set yet
	j readthrough
	
	
readthrough:	#read until pipe, symbolizing start of music
	move $t1, $v0	#load read char
	li $t0, '|' #'|'
	beq $t1, $t0, playnotes	# if hit '|', start reading music	
	jal readchar 
	j readthrough	
		
# Closes the file
closefile:
	li	$v0, 16		# Close File Syscall
	move	$a0, $s0	# Load File Descriptor
	syscall
	jr $ra  

# Parses through notes, adding them to a queue and playing them all at the end.
playnotes:

	noteplayed:

	jal readchar
	move $t0, $v0
	

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

	# Not a note? Simply skip it!
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
	
# Converts a note based on the key and adds it to the queue.
playnote:

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
	
	# The key affected us!! flat or not?
	beqz $t0, flatmode
	
	addi $a0, $a0, 1
	j playnotewkey
	
	flatmode:
	subi $a0, $a0, 1
	j playnotewkey
	
	# This acutally stores the note
	playnotewkey:

	# Note name
	sw  $a0, ($s4)
	add $s4, $s4, 4
	
	# Note Duration - Not implemented because tempo isn't
	li  $a1, 300
	sw  $a1, ($s4)
	add $s4, $s4, 4
	
	add $s5, $s5, 1
    	
	jr $ra 
	
#play all notes in queue
playallqueue:
	move $t0, $a0  #temp register $t0, note pointer
	move $t3, $a1  #length of note list
	
	playnoteloop:
		beq  $t3, $zero, end    #end loop when total number of notes left is 0
		lw   $t1, ($t0) 	#load name of current note into $t1
		addi $t0, $t0, 4 	#increament note pointer to note duration
		lw   $t2, ($t0)		#load duraetion current note into $t2
		subi $t3, $t3, 1	#decremnent length of note list
		addi $t0, $t0, 4	#increment note pointer to next name of note
		li   $v0, 33  		#syscall 33 to play note synchronous
		
		move $a0, $t1		#argument $a0 -> note name
		move $a1, $t2 		#argument $a1 -> note duration
		li   $a2, 12		# set midi instrument to piano 
		li   $a3, 127		# TURN IT UP TO 11
		syscall		
		j    playnoteloop
		
	end:	
		jr $ra 
	
# Quits the progam, but plays all notes in queue first.
exit:
	jal closefile
	
	move $a0, $s3
	move $a1, $s5	
	jal playallqueue
	
	li	$v0,10	
	syscall


	.data
file:	.asciiz	"sample.txt"
fileerr:.asciiz	"File not found"
plzenter:.asciiz	"Enter the name of the ABC file \n"
cont: 	.ascii "\nqprint : " 
buffer: .space 1024 
newline:.asciiz	"\n"
