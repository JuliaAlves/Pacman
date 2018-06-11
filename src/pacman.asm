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

include c:\MASM32\INCLUDE\msvcrt.inc
includelib c:\MASM32\LIB\msvcrt.lib

includelib libAStar.dll.lib

;------------------------------------------------------------------------------
; int AStarFindPath(
;           const int nStartX, const int nStartY,
;		    const int nTargetX, const int nTargetY,
;		    const unsigned char* pMap
; )
;------------------------------------------------------------------------------
; Library:						AStar.lib
; DLL:							AStar.dll
;------------------------------------------------------------------------------
AStarFindPath PROTO :BYTE, :BYTE,
                    :BYTE, :BYTE,
                    :DWORD
;==============================================================================
; Protótipos
;==============================================================================

; Verifica as colisões entre atores
pac_collision_update PROTO

; Come pontos
pac_points_update PROTO

; Atualiza a direção do Pacman
pacman_direction_update PROTO

; Atualiza a direção de um fantasma
ghost_direction_update PROTO :DWORD

; Atualiza a posição de um objeto do jogo
pac_position_update PROTO :DWORD

; Atualiza o giro de um objeto do jogo
pac_turn_update PROTO :DWORD

; Encontra a direção para o menor caminho de A para B
find_path PROTO :BYTE, :BYTE, :BYTE, :BYTE

;==============================================================================
; Constantes
;==============================================================================
.const

    ; Posição inicial dos objetos   (0XXYYh)
    PACMAN_START_POS        EQU     068B8h
    BLINKY_START_POS        EQU     06858h
    PINKY_START_POS         EQU     0686Ch
    INKY_START_POS          EQU     0586Ch
    CLYDE_START_POS         EQU     0786Ch
    
    ; ID da string do mapa
    ST_MAP                  EQU     00030h

    ; Intervalo de movimento em frames
    MOVEMENT_FRAME_INTERVAL EQU     2

;==============================================================================
; Seção de dados
;==============================================================================
.data
    
    objects     DWORD   5   DUP(0)
    map         DWORD   0
    pontos      BYTE    0

    pass_map        DWORD   0

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

    m2m DWORD PTR [eax + PACMAN], STATE_NORMAL or DIR_RIGHT or PACMAN_START_POS or TURN_NONE
    m2m DWORD PTR [eax + BLINKY], STATE_NORMAL or DIR_LEFT  or BLINKY_START_POS or TURN_NONE
    m2m DWORD PTR [eax + PINKY],  STATE_NORMAL or DIR_UP    or PINKY_START_POS  or TURN_NONE
    m2m DWORD PTR [eax + INKY],   STATE_NORMAL or DIR_UP    or INKY_START_POS   or TURN_NONE
    m2m DWORD PTR [eax + CLYDE],  STATE_NORMAL or DIR_UP    or CLYDE_START_POS  or TURN_NONE

    ; Carrega o mapa
    invoke crt_malloc, 869                      ; Aloca memória para o buffer
    mov map, eax

    invoke GetModuleHandle, NULL
    invoke LoadString, eax, ST_MAP, map, 869    ; Carrega o buffer dos resources
    
    invoke crt_malloc, 869                      ; Aloca memória para o buffer
    mov pass_map, eax

    ; Carrega o mapa usado para calcular o menor caminho entre dois pontos
    invoke GetModuleHandle, NULL
    invoke LoadString, eax, ST_MAP, pass_map, 869    ; Carrega o buffer dos resources

    mov ebx, pass_map
    mov esi, 0
    .while esi < 868
        .if BYTE PTR [ebx + esi] == MAP_WALL
            mov BYTE PTR [ebx + esi], 0
        .else
            mov BYTE PTR [ebx + esi], 1
        .endif

        inc esi
    .endw

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
pac_get_attr PROC USES ebx esi id : DWORD, attr : DWORD
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
;   x   {BYTE}  : Posição X (em píxels)
;   y   {BYTE}  : Posição Y (em píxels)
;------------------------------------------------------------------------------
pac_get_mapcell PROC USES ebx ecx edx esi x : BYTE, y : BYTE

    ; Posições X e Y do mapa (em células)
    LOCAL cellX : BYTE, cellY : BYTE

    .if x >= 224
        sub x, 224
    .endif
    
    .if y >= 248
        sub y, 248
    .endif

    ; Divide as posições em píxel para obter as posições das células
    mov al, x
    shr al, 3
    mov cellX, al

    mov al, y
    shr al, 3
    mov cellY, al

    ; Calcula o offset da célula na string
    xor eax, eax
    xor edx, edx

    mov al, cellY
    mov ecx, 28
    mul ecx
    mov esi, eax

    xor eax, eax
    xor edx, edx

    mov al, cellX
    add esi, eax

    mov ebx, map

    xor eax, eax
    mov al, BYTE PTR [ebx + esi]

    ret
pac_get_mapcell ENDP
;------------------------------------------------------------------------------
; pac_set_mapcell
;
;       Obtém o valor de uma célula no mapa
;
;   x   {BYTE}  : Posição X (em píxels)
;   y   {BYTE}  : Posição Y (em píxels)
;   n   {BYTE}  : Novo estado
;------------------------------------------------------------------------------
pac_set_mapcell PROC USES ebx ecx edx esi x : BYTE, y : BYTE, n: BYTE

    ; Posições X e Y do mapa (em células)
    LOCAL cellX : BYTE, cellY : BYTE

    .if x >= 224
        sub x, 224
    .endif
    
    .if y >= 248
        sub y, 248
    .endif

    ; Divide as posições em píxel para obter as posições das células
    mov ecx, 8

    xor eax, eax
    xor edx, edx
    mov al, x
    div ecx
    mov cellX, al

    xor eax, eax
    xor edx, edx
    mov al, y
    div ecx
    mov cellY, al

    ; Calcula o offset da célula na string
    xor eax, eax
    xor edx, edx

    mov al, cellY
    mov ecx, 28
    mul ecx
    mov esi, eax

    xor eax, eax
    xor edx, edx

    mov al, cellX
    add esi, eax

    mov ebx, map

    xor eax, eax
    mov al, n

    mov BYTE PTR [ebx + esi], al

    ret
pac_set_mapcell ENDP
;------------------------------------------------------------------------------
; pacman_get_pontos
;
;       Devolve os pontos
;------------------------------------------------------------------------------
pacman_get_pontos PROC
    xor eax, eax
    mov eax, DWORD ptr pontos
pacman_get_pontos ENDP
;------------------------------------------------------------------------------
; pac_update
;
;       Atualiza os objetos do jogo
;------------------------------------------------------------------------------
pac_update PROC USES edx ecx eax

    invoke pacman_direction_update

    ; Aplica o movimento
    invoke graphics_frame_count

    xor     edx, edx
    mov     ecx, MOVEMENT_FRAME_INTERVAL
    div     ecx

    .if edx == 0

        invoke pac_turn_update, PACMAN
        invoke pac_turn_update, BLINKY
        invoke pac_turn_update, PINKY
        invoke pac_turn_update, INKY
        invoke pac_turn_update, CLYDE

        invoke ghost_direction_update, BLINKY
        invoke ghost_direction_update, PINKY
        invoke ghost_direction_update, INKY
        invoke ghost_direction_update, CLYDE

        invoke pac_position_update, PACMAN
        invoke pac_position_update, BLINKY
        invoke pac_position_update, PINKY
        invoke pac_position_update, INKY
        invoke pac_position_update, CLYDE

        invoke pac_collision_update

        invoke pac_points_update
    .endif

    ret
pac_update ENDP
;------------------------------------------------------------------------------
; pac_collision_update
;
;       Verifica colisões entre o pacman e os fantasmas
;------------------------------------------------------------------------------
pac_collision_update PROC USES ebx
    

        LOCAL ghostX : BYTE, ghostY : BYTE, 
          pacState : DWORD

    invoke pac_get_attr, PACMAN, ATTR_POSITION

    mov bh, ah
    mov bl, al
    shr bh, 3
    shr bl, 3

    invoke pac_get_attr, PACMAN, ATTR_STATE
    mov pacState, eax

    invoke pac_get_attr, BLINKY, ATTR_POSITION
    mov ghostX, ah
    mov ghostY, al
    shr ghostX, 3
    shr ghostY, 3

    .if ghostX == bh
        .if ghostY == bl
            ; BLINKY se encontrou com o pacman
            .if pacState == STATE_POWER
                invoke pac_set_attr, BLINKY, ATTR_STATE, STATE_DEAD
            .else
                invoke pac_set_attr, PACMAN, ATTR_STATE, STATE_DEAD
                invoke ExitProcess, 0 ; PERDEU
            .endif
        .endif
    .endif

    invoke pac_get_attr, PINKY, ATTR_POSITION
    mov ghostX, ah
    mov ghostY, al
    shr ghostX, 3
    shr ghostY, 3

    .if ghostX == bh
        .if ghostY == bl
            ; PINKY se encontrou com o pacman
            .if pacState == STATE_POWER
                invoke pac_set_attr, PINKY, ATTR_STATE, STATE_DEAD
            .else
                invoke pac_set_attr, PACMAN, ATTR_STATE, STATE_DEAD
            .endif
        .endif
    .endif

    invoke pac_get_attr, INKY, ATTR_POSITION
    mov ghostX, ah
    mov ghostY, al
    shr ghostX, 3
    shr ghostY, 3

    .if ghostX == bh
        .if ghostY == bl
            ; INKY se encontrou com o pacman
            .if pacState == STATE_POWER
                invoke pac_set_attr, INKY, ATTR_STATE, STATE_DEAD
            .else
                invoke pac_set_attr, PACMAN, ATTR_STATE, STATE_DEAD
            .endif
        .endif
    .endif

    invoke pac_get_attr, CLYDE, ATTR_POSITION
    mov ghostX, ah
    mov ghostY, al
    shr ghostX, 3
    shr ghostY, 3

    .if ghostX == bh
        .if ghostY == bl
            ; CLYDE se encontrou com o pacman
            .if pacState == STATE_POWER
                invoke pac_set_attr, CLYDE, ATTR_STATE, STATE_DEAD
            .else
                invoke pac_set_attr, PACMAN, ATTR_STATE, STATE_DEAD
            .endif
        .endif
    .endif

    ret
pac_collision_update ENDP
;------------------------------------------------------------------------------
; pac_points_update
;
;       Verifica o pacman comendo pontos
;------------------------------------------------------------------------------
pac_points_update PROC
    xor     ebx, ebx
    xor     edi, edi
    invoke pac_get_attr, PACMAN, ATTR_POSITION
    mov     ebx, eax

    invoke pac_get_mapcell, bh, bl

    .if al == MAP_SMALLPOINT
        
        invoke pac_set_mapcell, bh, bl, MAP_NONE
        mov al, byte ptr [pontos]
        inc al
        mov byte ptr [pontos], al

    .elseif al == MAP_BIGPOINT
        invoke pac_set_mapcell, bh, bl, MAP_NONE
        invoke pac_set_attr, PACMAN, ATTR_STATE, STATE_POWER
    .endif

    .if pontos == 242
        invoke ExitProcess, 0 ; GANHOU
    .endif

    ret
pac_points_update ENDP
;------------------------------------------------------------------------------
; pacman_direction_update
;
;       Atualiza a direção do pacman
;------------------------------------------------------------------------------
pacman_direction_update PROC
    invoke pac_keystate, VK_UP
    .if ax == 1
        invoke pac_set_attr, PACMAN, ATTR_TURN, TURN_UP
    .endif
    
    invoke pac_keystate, VK_DOWN
    .if ax == 1
        invoke pac_set_attr, PACMAN, ATTR_TURN, TURN_DOWN
    .endif

    invoke pac_keystate, VK_RIGHT
    .if ax == 1
        invoke pac_set_attr, PACMAN, ATTR_TURN, TURN_RIGHT
    .endif  

    invoke pac_keystate, VK_LEFT
    .if ax == 1
        invoke pac_set_attr, PACMAN, ATTR_TURN, TURN_LEFT
    .endif

    ret
pacman_direction_update ENDP
;------------------------------------------------------------------------------
; ghost_direction_update
;
;       Atualiza a posição de um fantasma
;
;   id  {DWORD} : ID do fantasma
;------------------------------------------------------------------------------
ghost_direction_update PROC USES ebx ecx esi id : DWORD
    
    LOCAL dstX : BYTE, dstY : BYTE,
          ghostX : BYTE, ghostY : BYTE,
          direction : DWORD,
          turn : DWORD

    mov turn, 0

    invoke pac_get_attr, PACMAN, ATTR_POSITION
    mov dstX, ah
    mov dstY, al
    shr dstX, 3
    shr dstY, 3
    
    invoke pac_get_attr, id, ATTR_POSITION
    mov ghostX, ah
    mov ghostY, al
    shr ghostX, 3
    shr ghostY, 3
    
    xor eax, eax
    mov al, dstY
    mov edi, 28
    mul edi
    add al, dstX
    mov edi, eax

    ; Marca o pacman como impassável
    invoke GetModuleHandle, NULL
    invoke LoadString, eax, ST_MAP, pass_map, 869    ; Carrega o buffer dos resources
    mov ebx, pass_map
    mov esi, 0
    .while esi < 868
        .if BYTE PTR [ebx + esi] == MAP_WALL
            mov BYTE PTR [ebx + esi], 0
        .elseif esi == edi
            mov BYTE PTR [ebx + esi], 0
        .else
            mov BYTE PTR [ebx + esi], 1
        .endif

        inc esi
    .endw

    ; Fantasma vermelho
    ; Segue o pacman por trás
    .if id == BLINKY

        mov bh, ghostX
        mov bl, ghostY

        mov ch, dstX
        mov cl, dstY

        invoke pac_get_attr, PACMAN, ATTR_DIRECTION
        .if eax == DIR_UP
            inc cl
        .elseif eax == DIR_DOWN
            dec cl
        .elseif eax == DIR_RIGHT
            dec ch
        .elseif eax == DIR_LEFT
            inc ch
        .endif

        invoke find_path, bh, bl, ch, cl
        mov turn, eax

    ; Fantasma rosa
    ; Segue o pacman pela frente
    .elseif id == PINKY

        mov bh, ghostX
        mov bl, ghostY

        mov ch, dstX
        mov cl, dstY
        
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

        invoke find_path, bh, bl, ch, cl
        mov turn, eax

    ; Fantasma azul
    ; Flick: de vez em quando segue o pacman, de vez em quando é noiado
    .elseif id == INKY

        invoke graphics_frame_count
        and eax, 1

        .if eax == 0

            mov bh, ghostX
            mov bl, ghostY

            mov ch, dstX
            mov cl, dstY

            invoke pac_get_attr, PACMAN, ATTR_DIRECTION
            .if eax == DIR_UP
                inc cl
            .elseif eax == DIR_DOWN
                dec cl
            .elseif eax == DIR_RIGHT
                dec ch
            .elseif eax == DIR_LEFT
                inc ch
            .endif

            invoke find_path, bh, bl, ch, cl
            mov turn, eax

        .elseif

            mov bh, ghostX
            mov bl, ghostY

            mov ch, 1
            mov cl, 29
            
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

            invoke find_path, bh, bl, ch, cl
            mov turn, eax

        .endif

    ; Fantasma amarelo
    ; É noiado
    .elseif id == CLYDE
        mov bh, ghostX
        mov bl, ghostY

        mov ch, dstX
        mov cl, dstY

        .if bh > ch
            mov ah, bh
            sub ah, ch
        .else
            mov ah, ch
            sub ah, bh
        .endif

        .if bl > cl
            mov al, bl
            sub al, cl
        .else
            mov al, cl
            sub al, bl
        .endif

        mov dh, 0
        add dh, ah
        add dh, al

        .if dh < 16
            mov ch, 1
            mov cl, 29
        .endif

        invoke pac_get_attr, PACMAN, ATTR_DIRECTION
        .if eax == DIR_UP
            inc cl
        .elseif eax == DIR_DOWN
            dec cl
        .elseif eax == DIR_RIGHT
            dec ch
        .elseif eax == DIR_LEFT
            inc ch
        .endif

        invoke find_path, bh, bl, ch, cl
        mov turn, eax
    .endif

    invoke pac_set_attr, id, ATTR_TURN, turn

    ret
ghost_direction_update ENDP
;------------------------------------------------------------------------------
; find_path
;
;       Encontra a direção do melhor caminho de A para B
;
;   srcX    {BYTE}  : X (célula) de A
;   srcY    {BYTE}  : Y (célula) de A
;   dstX    {BYTE}  : X (célula) de B
;   dstY    {BYTE}  : Y (célula) de A
;------------------------------------------------------------------------------
find_path PROC USES ebx ecx edx esi srcX : BYTE, srcY : BYTE, dstX : BYTE, dstY : BYTE

    invoke AStarFindPath, srcX, srcY, dstX, dstY, pass_map

    ; Converte o ID para posições
    mov ecx, 28
    div ecx

    xor ebx, ebx
    mov dstX, dl
    mov dstY, al

    mov bh, dstX
    mov bl, dstY

    .if bh > srcX
        return TURN_RIGHT
    .elseif bh < srcX
        return TURN_LEFT
    .elseif bl > srcY
        return TURN_DOWN
    .elseif bl < srcY
        return TURN_UP
    .endif

    return TURN_NONE
find_path ENDP
;------------------------------------------------------------------------------
; pac_position_update
;
;       Atualiza a posição de um objeto do jogo
;
;   id  {DWORD} : ID do objeto a ser atualizado
;------------------------------------------------------------------------------
pac_position_update PROC USES ebx ecx edx id : DWORD
    invoke pac_get_attr, id, ATTR_POSITION
    mov ecx, eax
    
    invoke pac_get_attr, id, ATTR_DIRECTION

    .if eax == DIR_UP

        push ecx    ; Salva a posição anterior

        ; Anda para cima
        dec cl

        .if cl == 0FFh
            mov cl, 240
        .endif

        ; Se for uma parede, volta para onde estava
        invoke pac_get_mapcell, ch, cl

        .if eax == MAP_WALL
            pop ecx
        .else
            pop edx
        .endif
        
    .elseif eax == DIR_DOWN

        push ecx    ; Salva a posição anterior

        inc cl
        
        xor     edx, edx
        xor     eax, eax
        mov     al, cl
        mov     ebx, 248
        div     ebx
        mov     cl, dl
        
        ; Se for uma parede, volta para onde estava
        add cl, 7
        invoke pac_get_mapcell, ch, cl
        sub cl, 7

        .if eax == MAP_WALL
            pop ecx
        .else
            pop edx
        .endif

    .elseif eax == DIR_RIGHT

        push ecx    ; Salva a posição anterior

        inc ch
        
        xor     edx, edx
        xor     eax, eax
        mov     al, ch
        mov     ebx, 224
        div     ebx
        mov     ch, dl

        ; Se for uma parede, volta para onde estava
        add ch, 7
        invoke pac_get_mapcell, ch, cl
        sub ch, 7

        .if eax == MAP_WALL
            pop ecx
        .else
            pop edx
        .endif

    .elseif eax == DIR_LEFT

        push ecx    ; Salva a posição anterior

        dec ch

        .if ch == 0FFh
            mov ch, 216
        .endif

        ; Se for uma parede, volta para onde estava
        invoke pac_get_mapcell, ch, cl

        .if eax == MAP_WALL
            pop ecx
        .else
            pop edx
        .endif

    .endif

    invoke pac_set_attr, id, ATTR_POSITION, ecx

    ret
pac_position_update ENDP
;------------------------------------------------------------------------------
; pac_turn_update
;
;       Atualiza o giro de um objeto do jogo
;
;   id  {DWORD} : ID do objeto a ser atualizado
;------------------------------------------------------------------------------
pac_turn_update PROC USES ebx ecx edx id : DWORD
    invoke pac_get_attr, id, ATTR_TURN

    .if eax == TURN_UP

        invoke pac_get_attr, id, ATTR_POSITION
        mov ebx, eax

        ; Se estiver indo para a direção oposta, não muda de direção até bater
        ; na parede
        invoke pac_get_attr, id, ATTR_DIRECTION
        .if eax == DIR_DOWN
            push ebx

            add bl, 8
            invoke pac_get_mapcell, bh, bl
            .if eax != MAP_WALL
                pop ebx
                ret
            .endif

            pop ebx
        .endif

        ; Simula o movimento e vê se é possível, se for, então muda a direção
        sub bl, 8

        ; Como o pacman não é um ponto, precisamos testar duas posições (os 
        ; vértices do retângulo que podem bater em uma parede com o movimento)
        invoke pac_get_mapcell, bh, bl
        .if eax == MAP_WALL
            ret
        .endif

        add bh, 7

        invoke pac_get_mapcell, bh, bl
        .if eax != MAP_WALL
            invoke pac_set_attr, id, ATTR_DIRECTION, DIR_UP
        .endif

    .elseif eax == TURN_DOWN

        invoke pac_get_attr, id, ATTR_POSITION
        mov ebx, eax

        ; Se estiver indo para a direção oposta, não muda de direção até bater
        ; na parede
        invoke pac_get_attr, id, ATTR_DIRECTION
        .if eax == DIR_UP
            push ebx

            sub bl, 1
            invoke pac_get_mapcell, bh, bl
            .if eax != MAP_WALL
                pop ebx
                ret
            .endif

            pop ebx
        .endif

        ; Simula o movimento e vê se é possível, se for, então muda a direção
        add bl, 8

        ; Como o pacman não é um ponto, precisamos testar duas posições (os 
        ; vértices do retângulo que podem bater em uma parede com o movimento)
        invoke pac_get_mapcell, bh, bl
        .if eax == MAP_WALL
            ret
        .endif

        add bh, 7

        invoke pac_get_mapcell, bh, bl
        .if eax != MAP_WALL
            invoke pac_set_attr, id, ATTR_DIRECTION, DIR_DOWN
        .endif

    .elseif eax == TURN_LEFT

        invoke pac_get_attr, id, ATTR_POSITION
        mov ebx, eax

        ; Se estiver indo para a direção oposta, não muda de direção até bater
        ; na parede
        invoke pac_get_attr, id, ATTR_DIRECTION
        .if eax == DIR_RIGHT
            push ebx

            add bh, 8
            invoke pac_get_mapcell, bh, bl
            .if eax != MAP_WALL
                pop ebx
                ret
            .endif

            pop ebx
        .endif

        ; Simula o movimento e vê se é possível, se for, então muda a direção
        sub bh, 8

        ; Como o pacman não é um ponto, precisamos testar duas posições (os 
        ; vértices do retângulo que podem bater em uma parede com o movimento)
        invoke pac_get_mapcell, bh, bl
        .if eax == MAP_WALL
            ret
        .endif

        add bl, 7

        invoke pac_get_mapcell, bh, bl
        .if eax != MAP_WALL
            invoke pac_set_attr, id, ATTR_DIRECTION, DIR_LEFT
        .endif

    .elseif eax == TURN_RIGHT
        
        invoke pac_get_attr, id, ATTR_POSITION
        mov ebx, eax

        ; Se estiver indo para a direção oposta, não muda de direção até bater
        ; na parede
        invoke pac_get_attr, id, ATTR_DIRECTION
        .if eax == DIR_LEFT
            push ebx

            sub bh, 1
            invoke pac_get_mapcell, bh, bl
            .if eax != MAP_WALL
                pop ebx
                ret
            .endif

            pop ebx
        .endif

        ; Simula o movimento e vê se é possível, se for, então muda a direção
        add bh, 8
        
        ; Como o pacman não é um ponto, precisamos testar duas posições (os 
        ; vértices do retângulo que podem bater em uma parede com o movimento)
        invoke pac_get_mapcell, bh, bl
        .if eax == MAP_WALL
            ret
        .endif

        add bl, 7

        invoke pac_get_mapcell, bh, bl
        .if eax != MAP_WALL
            invoke pac_set_attr, id, ATTR_DIRECTION, DIR_RIGHT
        .endif

    .endif

    ret
pac_turn_update ENDP
;------------------------------------------------------------------------------
; pac_finish
;
;       Finaliza o jogo
;------------------------------------------------------------------------------
pac_finish PROC


    ret
pac_finish ENDP


end