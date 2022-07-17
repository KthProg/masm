    global  _main
    extern  _printf
    
    ; starting with a population of 10
    ; every 4 numbers is an individual "life" strategy
    section .data
population db 5, 4, 3, 2, 4, 3, 2, 3, 3, 2, 1, 4, 2, 1, 2, 5, 1, 0, 3, 4, 0, 1, 4, 3, 1, 2, 5, 2, 2, 3, 4, 1, 3, 4, 3, 2, 4, 5, 2, 3;

    section .text
_main:
    ; TODO: loop a few times
test_code:
    jmp test_function
    ; expected result at top of stack now

    ; TODO: load specific life not just first
    push [population + 3*4]
    push [population + 2*4]
    push [population + 1*4]
    push [population]
    jmp heuristic

    ; for testing purposes we're just
    ; tweaking the values for now
    jmp adjust_population
    ret

; hueristic result on edx
adjust_population:
    ; heuristic result on edx
    pop edx
    mov ecx, 4 ; max index to adjust + 1
make_adjustment:
    dec ecx
    cmp ecx 0
    jl done_adjusting

    cmp edx, 0
    je done_adjusting
    jl adjust_down
    adjust_up:
        add 0.5, [population + ecx*4]
        jmp make_adjustment
    adjust_down:
        sub 0.5, [population + ecx*4]
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
    jmp real_function
    pop eax ; result
    pop ebx ; expected result
    sub eax, ebx ; subtract expected result from result
    push eax ; push heuristic result onto stack

test_function:
    ; 2X^2 + 3X + 4
    push 0, 2, 3, 4
    jmp real_function
    pop eax; result


; caller must load 5 genetic params
; into stack x, a (aX^3), b (bX^2), c (cX), d (constant)
; with x on the top of the stack
; result is at the top of the stack when subroutine exits
; ecx => result
; edx => x
; eax, temp stores power of X for one argument of equation, e.g. X^2, X^3, etc.
; ah => number of multiplications to carry out for this argument of equation
; al => number of multiplication currently remaining
real_function:
    ; ecx stores our result, starts as 0
    mov ecx, 0
    ; copy x into edx, stack is now (a,b,c,d)
    pop edx
    ; number of multiplications of x to carry out
    mov ah, 3
start_mul_x:
    ; copy remaining multiplications into al
    mov al, ah
    ; copy 1 into eax
    ; will multiply by X 0-3 times, if 0 then
    ; remains 1 before multiplication by constant from stack
    mov eax, 1
mul_x:
    cmp al 0
    ; if no multiplications left, jump to constant multiplication
    je mul_const
    ; mult x into eax (x, x^2, x^3, etc.)
    mul edx
    ; dec remaining multiplications
    dec al
    ; multiply again
    jmp mul_x
mul_const:
    ; multiplications for next loop one less than previous
    ; e.g., x^3, X^2, etc.
    dec ah
    ; copy a, b, c, d (constant) into ebx
    pop ebx
    ; mult X^y by current constant, store in eax => c, cX, cX^2, etc
    mul ebx
    ; add current result to ecx
    add eax, ecx
    cmp ah, 0
    ; calc next argument of quadratic function
    jge start_mul_x
    ; if not multiplying again, no args left,
    ; push result to stack, return
    push ecx
    ret