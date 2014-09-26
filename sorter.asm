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

    push numberCount
    push (numberBuffer)
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

# printNumbers -- prints a buffer of 8 byte numbers, each on a newline
# parameters: buffer address on the stack
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

