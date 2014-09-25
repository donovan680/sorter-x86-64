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
    mov $0, rsi
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
    lea fileSize, rdi
    mov rax, (rdi)

    # Allocate memory
    push rax
    call alloc_mem

    # Save address of buffer
    lea buffer, rdi
    mov rax, (rdi)

    # Read into buffer
    # sys_read = 0
    xor rax, rax
    mov fileHandle, rdi
    mov buffer, rsi
    mov fileSize, rdx
    syscall

    push fileSize
    push buffer
    call get_number_count

    mov rax, (numberCount)
    push rax
    call print_number


    imul $8, rax, r9
    push r9
    call alloc_mem
    mov rax, numberBuffer

    jmp done

error:
    lea errorString, rax
    push rax
    call print_string
    jmp done

done:
    mov $60, rax
    mov $0, rdi
    syscall
