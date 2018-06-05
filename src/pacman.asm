;==============================================================================
; pacman.asm
;------------------------------------------------------------------------------
; Implementação das funções do jogo
;==============================================================================
.386
.model flat, stdcall
option casemap :none

include c:\MASM32\INCLUDE\windows.inc
include c:\MASM32\INCLUDE\user32.inc
include c:\MASM32\INCLUDE\gdi32.inc
include c:\MASM32\INCLUDE\kernel32.inc
include c:\MASM32\INCLUDE\masm32.inc

include include\macros.inc
include include\pacman.inc
include include\graphics.inc

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
    
    ; ID da string do mapa
    ST_MAP              EQU     00030h

;==============================================================================
; Seção de dados
;==============================================================================
.data
    
    objects     DWORD   5   DUP(0)

.data?

    map         DWORD   ?

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

    ; Inicializa os objetos
    mov eax, offset objects

    m2m DWORD PTR [eax + PACMAN], STATE_NORMAL or DIR_RIGHT or PACMAN_START_POS
    m2m DWORD PTR [eax + BLINKY], STATE_NORMAL or DIR_LEFT  or BLINKY_START_POS
    m2m DWORD PTR [eax + PINKY],  STATE_NORMAL or DIR_DOWN  or PINKY_START_POS
    m2m DWORD PTR [eax + INKY],   STATE_NORMAL or DIR_UP    or INKY_START_POS
    m2m DWORD PTR [eax + CLYDE],  STATE_NORMAL or DIR_UP    or CLYDE_START_POS

    ; Carrega o mapa
    invoke GetProcessHeap
    invoke HeapAlloc, eax, 0, 869                    ; Aloca memória para o buffer
    mov map, eax

    invoke GetModuleHandle, NULL
    invoke LoadString, eax, ST_MAP, map, 869    ; Carrega o buffer dos resources

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
; pac_set_attr
;
;       Define um atributo de um objeto do jogo
;
;   id      {DWORD} : ID do objeto
;   attr    {DWORD} : Atributo desejado
;   val     {DWORD} : Valor desejado
;------------------------------------------------------------------------------
pac_set_attr PROC USES ebx ecx esi id : DWORD, attr : DWORD, val : DWORD
    mov ebx, offset objects
    mov esi, id

    mov ebx, DWORD PTR [ebx + esi]

    mov ecx, attr
    xor ecx, 0FFFFFFFFh

    and ebx, ecx
    or  ebx, val

    mov [offset objects + esi], ebx

    ret
pac_set_attr ENDP
;------------------------------------------------------------------------------
; pac_keystate
; 
;      Determina o estado de uma tecla do teclado
;
;   key     {DWORD} : Código da tecla
;------------------------------------------------------------------------------
pac_keystate PROC key : DWORD
    invoke GetAsyncKeyState, key
    shr ax, 15

    ret
pac_keystate ENDP
;------------------------------------------------------------------------------
; pac_get_mapcell
;
;       Obtém o valor de uma célula no mapa
;
;   x   {BYTE}  : Posição X
;   y   {BYTE}  : Posição Y
;------------------------------------------------------------------------------
pac_get_mapcell PROC USES ebx esi x : BYTE, y : BYTE
    mov ebx, offset map
    
    xor esi, esi

    xor eax, eax
    xor ecx, ecx
    mov cl, y
    mov eax, 21
    mul ecx

    xor ecx, ecx
    mov cl, x

    add eax, ecx
    mov esi, eax

    return DWORD PTR [ebx + esi]
pac_get_mapcell ENDP
;------------------------------------------------------------------------------
; pac_update
;
;       Atualiza os objetos do jogo
;------------------------------------------------------------------------------
pac_update PROC

    invoke pac_keystate, VK_UP
    .if ax == 1
        invoke pac_set_attr, PACMAN, ATTR_DIRECTION, DIR_UP
    .endif
    
    invoke pac_keystate, VK_DOWN
    .if ax == 1
        invoke pac_set_attr, PACMAN, ATTR_DIRECTION, DIR_DOWN
    .endif

    invoke pac_keystate, VK_RIGHT
    .if ax == 1
        invoke pac_set_attr, PACMAN, ATTR_DIRECTION, DIR_RIGHT
    .endif

    invoke pac_keystate, VK_LEFT
    .if ax == 1
        invoke pac_set_attr, PACMAN, ATTR_DIRECTION, DIR_LEFT
    .endif

    ; Movimento
    invoke graphics_frame_count

    xor     edx, edx
    mov     ecx, 64
    div     ecx

    .if edx == 0
        invoke pac_get_attr, PACMAN, ATTR_POSITION
        mov ecx, eax
        
        invoke pac_get_attr, PACMAN, ATTR_DIRECTION

        .if eax == DIR_UP
            dec cl
        .elseif eax == DIR_DOWN
            inc cl
        .elseif eax == DIR_RIGHT
            inc ch
        .elseif eax == DIR_LEFT
            dec ch
        .endif

        invoke pac_set_attr, PACMAN, ATTR_POSITION, ecx
    .endif

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