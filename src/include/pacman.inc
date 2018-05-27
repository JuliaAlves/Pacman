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

; Obtém a passabilidade de uma posição no mapa
pac_is_passable	PROTO 	:BYTE, :BYTE

; Atualiza os objetos jogo
pac_update		PROTO

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

; Códigos de atributo
ATTR_POSITION   equ 00000FFFFh
ATTR_DIRECTION 	equ 000FF0000h
ATTR_STATE      equ 0FF000000h