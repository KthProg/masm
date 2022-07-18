    global  _main
    extern  _printf
    
    ; starting with a population of 10
    ; every 4 numbers is an individual "life" strategy
    section .data
population db 5, 4, 3, 2, 4, 3, 2, 3, 3, 2, 1, 4, 2, 1, 2, 5, 1, 0, 3, 4, 0, 1, 4, 3, 1, 2, 5, 2, 2, 3, 4, 1, 3, 4, 3, 2, 4, 5, 2, 3
result db 0, 0, 0, 0
heuristic_result db 0, 0, 0, 0
expected_result db 0, 0, 0, 0
return_addr db 0, 0, 0, 0
return_addr_2 db 0, 0, 0, 0

    section .text
_main:
    mov ebp, esp; for correct debugging
    ; TODO: loop a few times
test_code:
    call test_function
    ; result in [result] now
    mov eax, [result]
    mov [expected_result], eax

    ; TODO: load specific life not just first
    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    mov al, [population + 3]
    mov bl, [population + 2]
    mov cl, [population + 1]
    mov dl, [population]

    ; TODO: need to test multiple values of x
    push eax
    push ebx
    push ecx
    push edx
    push 5
    call heuristic

    ; for testing purposes we're just
    ; tweaking the values for now
    call adjust_population
    
    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    mov al, [population + 3]
    mov bl, [population + 2]
    mov cl, [population + 1]
    mov dl, [population]

    ; TODO: need to test multiple values of x
    push eax
    push ebx
    push ecx
    push edx
    push 5
    call heuristic
    ret

; hueristic result on edx
adjust_population:
    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    ; heuristic result on edx
    mov edx, [heuristic_result]
    mov ecx, 4 ; max index to adjust + 1
make_adjustment:
    dec ecx
    cmp ecx, 0
    jl done_adjusting

    cmp edx, 0
    je done_adjusting
    jg adjust_down
    adjust_up:
        mov bl, [population + ecx]
        add ebx, 1
        mov [population + ecx], bl
        jmp make_adjustment
    adjust_down:
        mov bl, [population + ecx]
        sub ebx, 1
        mov [population + ecx], bl
        jmp make_adjustment
        
done_adjusting:
    ret

; the closer to 0 the better
; caller must load 4 genetic params
; into stack x, a (aX^3), b (bX^2), c (cX), d (constant), expected result
; with x on the top of the stack
; after real_function, the stack will be [
;   result,
;   expected result
;]
heuristic:
    ; return address
    pop ebx
    mov [return_addr_2], ebx
    
    call real_function
    
    mov eax, [result]
    mov ebx, [expected_result]
    sub eax, ebx ; subtract expected result from result
    mov [heuristic_result], eax
    
    mov ebx, [return_addr_2]
    push ebx ; push return addr onto stack
    ret

test_function:
    ; 2X^2 + 3X + 4
    push 0 ; d
    push 2 ; c
    push 3 ; b
    push 4 ; a
    push 5 ; x
    call real_function
    ret


; caller must load 5 genetic params
; into stack x, a (aX^3), b (bX^2), c (cX), d (constant)
; with x on the top of the stack
; result is at the top of the stack when subroutine exits
; [result]/eax => result
; ebx => x
; eax, temp stores power of X for one argument of equation, e.g. X^2, X^3, etc.
; ecx => constant multiple of x (ax^y, bx^z, etc.)
; dh => number of multiplications to carry out for this argument of equation
; dl => number of multiplication currently remaining
real_function:
    ; r8 stores our result, starts as 0
    mov [result], word 0
    ; return address
    pop ebx
    mov [return_addr], ebx
    ; copy x into ebx, stack is now (a,b,c,d)
    pop ebx
    ; number of multiplications of x to carry out
    mov dl, 3
start_mul_x:
    ; copy remaining multiplications into dh
    mov dh, dl
    ; copy 1 into eax
    ; will multiply by X 0-3 times, if 0 then
    ; remains 1 before multiplication by constant from stack
    mov eax, 1
mul_x:
    cmp dh, 0
    ; if no multiplications left, jump to constant multiplication
    je mul_const
    ; mult x into eax (x, x^2, x^3, etc.)
    mul bl ; mul low bit to avoid flowign into d register
    ; dec remaining multiplications
    dec dh
    ; multiply again
    jmp mul_x
mul_const:
    ; multiplications for next loop one less than previous
    ; e.g., x^3, X^2, etc.
    dec dl
    ; copy a, b, c, d (constant) into ecx
    pop ecx
    ; mult X^y by current constant, store in eax => c, cX, cX^2, etc
    mul cl ; mul low bit to avoid flowign into d register
    ; add current result to eax
    add [result], eax
    cmp dl, 0
    ; calc next argument of quadratic function
    jge start_mul_x
    ; if not multiplying again, no args left
    mov eax, [return_addr]
    push eax
    ret