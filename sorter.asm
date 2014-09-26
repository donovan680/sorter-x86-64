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

    xor rax, rax
    xor rbx, rbx
    xor rsi, rsi
    xor rdi, rdi
    # Counters
    xor r9, r9
    xor r10, r10
    # Flag that indicates swaps have been done
    xor r11, r11
    # rsi points to number buffer
    mov numberCount, rcx
    mov numberBuffer, rsi

sort:
    inc r9
    cmp r9, rcx
    je maybeDone
    # Move current number into rax
    mov (rsi, r9, 8), rax
    # Move adjacent number into rdx
    mov r9, r10
    dec r10
    mov (rsi, r10, 8), rdx
    cmp rax, rdx
    jg swap
    jmp sort

swap:
    # We're swapping values
    mov $1, r11
    xchg rax, rdx
    mov rax, (rsi, r9, 8)
    mov rdx, (rsi, r10, 8)
    jmp sort

maybeDone:
    xor r9, r9
    cmp $0, r11
    je done
    xor r11, r11
    je sort

done:
    mov numberBuffer, rsi
    mov numberCount, rcx
    xor rdx, rdx

printNumbers:
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
    jl printNumbers

exit:
    mov $60, rax
    mov $0, rdi
    syscall

error:
    lea errorString, rax
    push rax
    call print_string
    jmp exit

