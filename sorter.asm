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

    # TODO: Reduce register usage
    mov $0, r13

sortLoop:
    push r13
    push numberCount
    push numberBuffer
    call countingSort
    inc r13
    # We have a maximum length of 8 bytes
    cmp $8, r13
    jne sortLoop

    #push numberCount
    #push numberBuffer
    #call printNumbers

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
    # byte idx
    mov 32(rbp), rbx

    # TODO: Maybe use one buffer every time
    # rdi is count buffer / bucket
    sub $1024, rsp
    mov rsp, rdi

    # Use previously allocated copy buffer
    mov (copyBuffer), r14

    # Allocate space for key/digit buffer
    mov (keyBuffer), r15

    # Set all counts to zero
    xor r9, r9
zeroLoop:
    # TODO: Use SIMD to zero
    movq $0, (rdi, r9, 8)
    inc r9
    cmp $128, r9
    jne zeroLoop

    # r9 is index for current number
    xor r9, r9

    # Grab the byte, count them
countLoop:
    # Store rcx
    push rcx
    mov (rsi, r9, 8), rax
    mov rbx, rdx
    imul $8, rdx, rcx
    # r11 stores mask
    movq $0xff, r11
    shl cl, r11
    and r11, rax
    shr cl, rax
    # Restore rcx
    pop rcx

    # Current byte is now in rax,
    # use it as index for bucket
    xor r10, r10
    mov (rdi, rax, 4), r10w
    inc r10
    mov r10w, (rdi, rax, 4)
    # for that number
    mov al, (r15, r9)

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

