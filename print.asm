###############################################################################
# This function prints a number to std-out. The number is given on the stack
#
# The function is register save
###############################################################################

###############################################################################
# This function prints a zero terminated String to the screen. The address of
# the String is given on the stack
#
# The function is not register save
###############################################################################

.global print_string
.type print_string, @function
print_string:
    push    %rbp
    mov     %rsp,%rbp       #Function Prolog

    mov     16(%rbp),%rax   #Address of the String
    xor     %rcx,%rcx       #Counter
string_length:
    movb    (%rax,%rcx), %bl    #Load byte
    cmp     $0,%bl          #End of String?
    jz      string_length_finished
    add     $1,%rcx         #Increase counter
    jmp     string_length

string_length_finished:
    mov     $1, %rax        # In "syscall" style 1 means: write
    mov     $1, %rdi        # File descriptor (std out)
    mov     16(%rbp),%rsi   # Address of the String
    mov     %rcx,%rdx       # Length of the String
    syscall                 #Call the kernel, 64Bit variant

    mov     %rbp,%rsp       #Function Epilog
    pop     %rbp
    ret
