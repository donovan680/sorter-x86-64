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
errorString:
    .string "Unable to open file.\n"

.section .text
.global _start
.att_syntax noprefix
.type _start, @function
_start:
    # Filename to rdi
    mov 16(rsp), rdi
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
    # PROT_READ
    mov $3, rdx
    # MAP_PRIVATE | MAP_POPULATE
    mov $0x8002, r10
    mov fileHandle, r8
    xor r9, r9
    syscall

    mov rax, (buffer)

    push fileSize
    push buffer
    call get_number_count

    mov rax, (numberCount)

    # Allocate memory for num_count numbers(each number is 8 bytes)
    imul $8, rax, r9
    push r9
    call alloc_mem
    # Store address
    mov rax, (numberBuffer)

    push rax
    push fileSize
    push buffer
    call parse_number_buffer
    # Numbers have now been parsed and stored in numberBuffer

    mov $1, rcx

sortLoop:
    push rcx
    push numberCount
    push numberBuffer
    call countingSort
    inc rcx
    # TODO: this shouldn't be hardcoded
    # This is num digits we want to sort
    cmp $10, rcx
    jne sortLoop

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

# countingSort -- performs counting sort on the given list of numbers
# parameters:
#             buffer address on the stack
#             number count on the stack
#             power of 10 number designating digit to sort by
.type countingSort, @function
countingSort:
    push rbp
    mov rsp, rbp
    # buffer
    mov 16(rbp), rsi
    # num count
    mov 24(rbp), rcx
    # power of 10
    mov 32(rbp), rbx
    # Counter for zero loop
    xor r9, r9

    # Space for count buffer
    # rdi is count buffer
    sub $80, rsp
    mov rsp, rdi

    # Space for digit buffer
    # TODO: Maybe not allocate 80 bytes
    # for 10 single digit numbers.
    # r15 is digit buffer
    sub $80, rsp
    mov rsp, r15


    # Allocate space for copy buffer
    imul $8, rcx, r14
    push rcx
    push r14
    call alloc_mem
    mov rax, r14
    # TODO: Save rcx better here
    pop rcx
    pop rcx

    # Set all counts to zero
zeroLoop:
    movq $0, (rdi, r9, 8)
    inc r9
    cmp $10, r9
    jne zeroLoop

    # r9 is index for current number
    xor r9, r9

    # Grab the digits, count them
countLoop:
    mov (rsi, r9, 8), rax
    # Store old value of rbx
    push rbx

    # (number / base^(n-1)) % base
getdigitloop:
    xor rdx, rdx
    mov $10, r12
    div r12
    dec rbx
    cmp $0, rbx
    jne getdigitloop

    # Restore it
    pop rbx

    # Remainder is now in rdx
    # use it as index for bucket
    mov (rdi, rdx, 8), r10
    inc r10
    mov r10, (rdi, rdx, 8)
    # Store digit (key) in key buffer
    # for that number
    mov rdx, (r15, r9, 8)

    inc r9
    cmp rcx, r9
    jne countLoop

    # Done counting digits
    # Total
    xor rax, rax
    # Old count
    xor rbx, rbx
    # Counter
    xor r12, r12

calculateIndex:
    # oldCount = count[i]
    mov (rdi, r12, 8), rbx
    # count[i] = total
    mov rax, (rdi, r12, 8)
    # total += oldCount
    add rbx, rax
    # i ++
    inc r12
    cmp $10, r12
    jne calculateIndex

    # Index for current number
    xor r9, r9

outputLoop:
    #output[count[key(x)]] = x
    # rax = key(x)
    mov (r15, r9, 8), rax

    # rbx = count[key(x)]
    mov (rdi, rax, 8), rbx

    # r11 = x
    mov (rsi, r9, 8), r11

    # output[count[key(x)]] = r11
    mov r11, (r14, rbx, 8)

    #count[key(x)] += 1
    inc rbx
    mov rbx, (rdi, rax, 8)

    inc r9
    cmp r9, rcx
    jne outputLoop

    xor r9, r9

copyBack:
    # SIMD, baby
    movdqa (r14, r9), xmm1
    movdqa xmm1, (rsi, r9)
    add $16, r9
    # TODO: This shouldn't be hardcoded
    cmp $80, r9
    jne copyBack

    leave
    ret

# printNumbers -- prints a buffer of 8 byte numbers, each on a newline
# parameters:
#             buffer address on the stack
#             number count on the stack
# push arguments in reverse order.
# Clobbers registers
.type printNumbers, @function
printNumbers:
    push rbp
    mov rsp, rbp
    mov 16(rbp), rsi
    mov 24(rbp), rcx
    xor rdx, rdx
loop:
    push rsi
    push rdx
    push rcx
    push (rsi, rdx, 8)
    call print_number
    pop rcx
    pop rcx
    pop rdx
    pop rsi

    inc rdx
    cmp rcx, rdx
    jl loop
    leave
    ret

