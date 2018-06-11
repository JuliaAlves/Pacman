;==============================================================================
; pacman.inc
;------------------------------------------------------------------------------
; Definição das funções que implementam a lógica do jogo em si
;==============================================================================
;==============================================================================
; Protótipos
;==============================================================================

; Inicializa o jogo
pac_init		PROTO

; Obtém um atributo de um objeto do jogo
pac_get_attr	PROTO 	:DWORD, :DWORD

; Define um atributo de um objeto do jogo
pac_set_attr    PROTO   :DWORD, :DWORD, :DWORD

; Determina o estado de uma tecla do teclado
pac_keystate    PROTO   :DWORD

; Obtém o valor de uma posição no mapa
pac_get_mapcell PROTO   :BYTE, :BYTE

; Define uma célula do mapa
pac_set_mapcell PROTO   :BYTE, :BYTE, :BYTE

; Obtém os pontos do pacman
pacman_get_pontos PROTO

; Obtém o timer de morte
pacman_get_dead_timer PROTO

; Atualiza os objetos jogo
pac_update		PROTO

; Atualiza os objetos jogo
pac_collision_update		PROTO

; Finaliza o jogo
pac_finish		PROTO

;==============================================================================
; Constantes
;==============================================================================
.const

; IDs
PACMAN			equ 000h
BLINKY			equ 004h
PINKY			equ 008h
INKY			equ 00Ch
CLYDE			equ 010h

; Estados
STATE_NORMAL	equ 000000000h
STATE_POWER		equ 001000000h
STATE_DEAD 		equ 0FF000000h

; Direções
DIR_RIGHT		equ 000000000h
DIR_LEFT		equ 000010000h
DIR_UP			equ 000020000h
DIR_DOWN		equ 000030000h

; Direção desejada
TURN_RIGHT		equ 000000000h
TURN_LEFT		equ 000100000h
TURN_UP			equ 000200000h
TURN_DOWN		equ 000300000h
TURN_NONE       equ 000400000h

; Códigos de atributo
ATTR_POSITION   equ 00000FFFFh
ATTR_DIRECTION 	equ 0000F0000h
ATTR_TURN       equ 000F00000h
ATTR_STATE      equ 0FF000000h

; Códigos de célula do mapa
MAP_WALL        equ 000000078h
MAP_NONE        equ 00000002Fh
MAP_SMALLPOINT  equ 00000002Eh
MAP_BIGPOINT    equ 00000006Fh