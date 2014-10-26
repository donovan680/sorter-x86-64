.section .data
fileHandle:
    .space 8
fileSize:
    .space 8
buffer:
    .space 8
numberBuffer:
    .space 8
numberCount:
    .space 8
copyBuffer:
    .space 8
keyBuffer:
    .space 8
errorString:
    .string "Unable to open file.\n"

.section .text
.global _start
# Removes requirement for pesky % sign everywhere
.att_syntax noprefix
.type _start, @function
_start:
############################################################################
#                             Reading the file                             #
############################################################################

    mov rsp, rbp
    # Filename to rdi
    mov 16(rbp), rdi
    # sys_open = 2
    mov $2, rax
    # O_RDONLY = 0
    # O_WRONLY = 1
    # O_RDWR   = 2
    mov $2, rsi
    mov $0, rdx
    syscall
    # Ensure we got a valid file handle
    cmp $0, rax
    jl error

    # Save file handle
    lea fileHandle, rdi
    mov rax, (rdi)

    # Get file size
    push fileHandle
    call get_file_size

    # Save file size
    mov rax, (fileSize)

    # mmap file into memory
    mov $9, rax
    xor rdi, rdi
    mov (fileSize), rsi
    # PROT_READ | PROT_WRITE
    mov $3, rdx
    # MAP_PRIVATE | MAP_POPULATE
    mov $0x8002, r10
    mov fileHandle, r8
    xor r9, r9
    syscall
    # Store buffer
    mov rax, (buffer)

############################################################################
#                              Parse the file                              #
############################################################################
    push fileSize
    push buffer
    call get_number_count

    # Store number count
    mov rax, (numberCount)

    # Allocate memory for num_count numbers(each number is 8 bytes)
    imul $8, rax, r9
    push r9
    call alloc_mem
    # Store address
    mov rax, (numberBuffer)
    # Allocate space for copy buffer *ONCE*
    call alloc_mem
    mov rax, (copyBuffer)

    # Allocate space for key buffer *ONCE*
    push numberCount
    call alloc_mem
    mov rax, (keyBuffer)

    push numberBuffer
    push fileSize
    push buffer
    call parse_number_buffer
    # Numbers have now been parsed and stored in numberBuffer

############################################################################
#                              Sort the file                               #
############################################################################

    xor r13, r13
sortLoop:
    push r13
    push numberCount
    push numberBuffer
    call countingSort
    inc r13
    # We have a maximum length of 8 bytes
    cmp $8, r13
    jne sortLoop

    # Skip printing if program gets more than
    # one argument
    cmp $3, (rbp)
    jge exit
    push fileSize
    push buffer
    push numberCount
    push numberBuffer
    call printNumbers

exit:
    mov $60, rax
    mov $0, rdi
    syscall

error:
    lea errorString, rax
    push rax
    call print_string
    jmp exit

############################################################################
#                              Counting sort                               #
############################################################################
# countingSort -- performs counting sort on
# parameters, in order they should be pushed:
#    Byte index to sort by counting from least significant byte
#    Number count
#    Number buffer
.type countingSort, @function
countingSort:
    push rbp
    mov rsp, rbp
    # Buffer
    mov 16(rbp), rsi
    # Number count
    mov 24(rbp), rcx
    # Which byte we're sorting on, counting from least significant byte
    mov 32(rbp), rbx

    # Allocate space on the stack for the bucket / count buffer.
    # 256 different values * 4 bytes = 1 kilobyte
    sub $1024, rsp
    mov rsp, rdi

    # Use previously allocated copy buffer
    mov (copyBuffer), r14

    # Use previously allocated key buffer
    mov (keyBuffer), r15

    # Set all counts to zero
    xor r9, r9
zeroLoop:
    # TODO: Use SIMD to zero
    movq $0, (rdi, r9, 8)
    inc r9
    cmp $128, r9
    jne zeroLoop

############################################################################
#                       Count the occurences of keys                       #
############################################################################
    # r9 is index for current number
    xor r9, r9
countLoop:
    # Store rcx
    push rcx
    mov (rsi, r9, 8), rax
    # For some reason, shl/r only works with cl
    imul $8, rbx, rcx
    # Get the correct byte using a bitmask
    movq $0xff, r11
    shl cl, r11
    and r11, rax
    shr cl, rax
    # Restore rcx
    pop rcx

    # Current byte is now in rax,
    # use it as index for bucket
    xor r10, r10
    mov (rdi, rax, 4), r10d
    inc r10
    mov r10d, (rdi, rax, 4)

    # This stores the key so we don't have to calculate it again later
    mov al, (r15, r9)

    inc r9
    cmp rcx, r9
    jne countLoop

############################################################################
#               Calculate the new positions for the numbers                #
############################################################################
    # Total
    xor rax, rax
    # Old count
    xor rbx, rbx
    # Counter
    xor r12, r12
calculateIndex:
    # oldCount = count[i]
    xor rbx, rbx
    mov (rdi, r12, 4), ebx
    # count[i] = total
    mov eax, (rdi, r12, 4)
    # total += oldCount
    add rbx, rax
    # i ++
    inc r12
    cmp $256, r12
    jne calculateIndex

############################################################################
#      Write the numbers to their new positions in the output buffer       #
############################################################################
    # Index for current number
    xor r9, r9
outputLoop:
    #output[count[key(x)]] = x
    # rax = key(x)
    xor rax, rax
    mov (r15, r9), al

    # rbx = count[key(x)]
    xor ebx, ebx
    mov (rdi, rax, 4), ebx

    # r11 = x
    mov (rsi, r9, 8), r11

    # output[count[key(x)]] = r11
    mov r11, (r14, rbx, 8)

    #count[key(x)] += 1
    inc rbx
    mov ebx, (rdi, rax, 4)

    inc r9
    cmp r9, rcx
    jne outputLoop

############################################################################
#                      Copy back into original buffer                      #
############################################################################
    xor r9, r9
    # Store size of buffer in r11
    imul $8, rcx, r11
copyBack:
    # SIMD, baby
    movdqa (r14, r9), xmm1
    movdqa xmm1, (rsi, r9)
    add $16, r9
    cmp r11, r9
    jne copyBack

    leave
    ret

# printNumbers -- prints a buffer of 8 byte numbers, each on a newline
# parameters on stack, in order they should be pushed:
#    Length of input buffer
#    Buffer address
#    Number count in sorted buffer
#    Address of number bufferj
# Clobbers registers
.type printNumbers, @function
printNumbers:
    push rbp
    mov rsp, rbp
    # Number buffer
    mov 16(rbp), rsi
    # Number count
    mov 24(rbp), rcx
    # Input buffer
    mov 32(rbp), rdi
    # Input buffer size
    mov 40(rbp), r10
    sub $2, r10
    dec rcx

convertLoop:
    mov (rsi, rcx, 8), rax

digitLoop:
    # Grab digit, convert to ascii
    # store in correct place
    xor rdx, rdx
    mov $10, rbx
    div rbx
    add $0x30, rdx
    movb dl, (rdi, r10)
    # If the quotient is zero, the number is done
    cmp $0, rax
    je numberDone
    dec r10
    jmp digitLoop

numberDone:
    # Point to next number
    dec rcx
    # Are we done converting all numbers?
    cmp $0, rcx
    jl doneConverting
    # Nope, write newline, point to next good place
    dec r10
    movb $10, (rdi, r10)
    dec r10
    jmp convertLoop

doneConverting:
    # Write buffer to stdout
    mov $1, rax
    mov rdi, rsi
    mov $1, rdi
    mov 40(rbp), rdx
    syscall
    leave
    ret
