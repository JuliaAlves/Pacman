;==============================================================================
; pacman.asm
;------------------------------------------------------------------------------
; Implementação das funções do jogo
;==============================================================================
.386
.model flat, stdcall
option casemap :none

include include\macros.inc
include include\pacman.inc

;==============================================================================
; Constantes
;==============================================================================
.const

    ; Posição inicial dos objetos   (0XXYYh)
    PACMAN_START_POS    EQU     068B4h
    BLINKY_START_POS    EQU     06854h
    PINKY_START_POS     EQU     0686Ch
    INKY_START_POS      EQU     0586Ch
    CLYDE_START_POS     EQU     0786Ch

;==============================================================================
; Seção de dados
;==============================================================================
.data
    
    objects     DWORD   5   DUP(0)

;==============================================================================
; Seção de código
;==============================================================================
.code
;------------------------------------------------------------------------------
; pac_init
;
;       Inicializa o jogo
;------------------------------------------------------------------------------
pac_init PROC

    mov eax, offset objects

    m2m DWORD PTR [eax + PACMAN], STATE_NORMAL or DIR_RIGHT or PACMAN_START_POS
    m2m DWORD PTR [eax + BLINKY], STATE_NORMAL or DIR_LEFT  or BLINKY_START_POS
    m2m DWORD PTR [eax + PINKY],  STATE_NORMAL or DIR_DOWN  or PINKY_START_POS
    m2m DWORD PTR [eax + INKY],   STATE_NORMAL or DIR_UP    or INKY_START_POS
    m2m DWORD PTR [eax + CLYDE],  STATE_NORMAL or DIR_UP    or CLYDE_START_POS

    xor eax, eax

    ret
pac_init ENDP
;------------------------------------------------------------------------------
; pac_get_attr
;
;       Obtém um atributo de um objeto do jogo
;
;   id      {DWORD} : ID do objeto
;   attr    {DWORD} : Atributo desejado
;------------------------------------------------------------------------------
pac_get_attr PROC id : DWORD, attr : DWORD
    mov ebx, offset objects
    mov esi, id
    
    mov eax, DWORD PTR [ebx + esi]
    and eax, attr

    ret
pac_get_attr ENDP
;------------------------------------------------------------------------------
; pac_update
;
;       Atualiza os objetos do jogo
;------------------------------------------------------------------------------
pac_update PROC


    ret
pac_update ENDP
;------------------------------------------------------------------------------
; pac_finish
;
;       Finaliza o jogo
;------------------------------------------------------------------------------
pac_finish PROC


    ret
pac_finish ENDP

end