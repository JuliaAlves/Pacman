;==============================================================================
; graphics.asm
;------------------------------------------------------------------------------
; Implementação das funções de desenho do jogo
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

includelib c:\MASM32\LIB\Msimg32.lib
;==============================================================================
; Funções externas
;==============================================================================
;------------------------------------------------------------------------------
; BOOL TransparentBlt(
;  	_In_ 	HDC  	hdcDest,
; 	_In_ 	int  	xoriginDest,
;  	_In_ 	int  	yoriginDest,
;  	_In_ 	int  	wDest,
;  	_In_ 	int  	hDest,
;  	_In_ 	HDC  	hdcSrc,
;  	_In_ 	int  	xoriginSrc,
;  	_In_ 	int  	yoriginSrc,
;  	_In_ 	int  	wSrc,
;  	_In_ 	int  	hSrc,
; 	_In_ 	UINT 	crTransparent
; );
;------------------------------------------------------------------------------
; Minimum supported client: 	Windows 2000 Professional [desktop apps only]
; Minimum supported server:		Windows 2000 Server [desktop apps only]
; Header:						WinGdi.h (include Windows.h)
; Library:						Msimg32.lib
; DLL:							Msimg32.dll
;------------------------------------------------------------------------------
TransparentBlt	PROTO 	:HDC,
						:DWORD, :DWORD,
						:DWORD, :DWORD,
						:HDC,
						:DWORD, :DWORD,
						:DWORD, :DWORD,
						:UINT
;==============================================================================
; Protótipos
;==============================================================================
; Prepara para desenho
begin_draw 		PROTO 	:HDC

; Termina o desenho
end_draw 		PROTO 	:HDC

; Desenha um bitmap
draw_bitmap 	PROTO 	:DWORD,
						:HBITMAP,
						:DWORD,
						:DWORD,
						:DWORD,
						:DWORD

; Desenha o pacman
draw_pacman		PROTO

; Desenha um fantasma
draw_ghost		PROTO 	:DWORD

; Desenha o mapa
draw_map 		PROTO

;==============================================================================
; Seção de dados
;==============================================================================
.data

	frame_count		DWORD	0	; Byte para frames de animação

.data?

	bitmap_mapfull  DWORD   ?	; Bitmap do mapa cheio
	bitmap_mapempty DWORD   ?	; Bitmap do mapa vazio
	bitmap_sprites	DWORD   ?	; Bitmap dos sprites

	buffer 			HBITMAP	? 	; Bitmap de buffer
	bufferDC 		HDC 	? 	; Contexto de desenho do buffer

;==============================================================================
; Constantes
;==============================================================================
.const

; Dimensões da tela
SCREEN_WIDTH	EQU 	448
SCREEN_HEIGHT 	EQU 	496

REAL_WIDTH 		EQU 	224
REAL_HEIGHT 	EQU 	248

; Bitmaps
BMP_MAPFULL 	EQU		021h
BMP_MAPEMPTY	EQU		020h
BMP_SPRITES		EQU		010h

; Intervalo entre os frames
FRAME_INTERVAL	EQU 	6

; Intervalo da animação (em frames)
ANIM_INTERVAL	EQU		10

;==============================================================================
; Seção de código
;==============================================================================
.code
;------------------------------------------------------------------------------
; graphics_load_bitmaps
;
;       Carrega os bitmaps do jogo
;
;   hInst   {HINSTANCE} : Instância do programa
;------------------------------------------------------------------------------
graphics_load_bitmaps PROC hInst : DWORD

	invoke LoadBitmap, hInst, BMP_MAPEMPTY
	mov bitmap_mapempty, eax

	invoke LoadBitmap, hInst, BMP_MAPFULL
	mov bitmap_mapfull, eax

	invoke LoadBitmap, hInst, BMP_SPRITES
	mov bitmap_sprites, eax

	ret
graphics_load_bitmaps ENDP
;------------------------------------------------------------------------------
; graphics_frame_count
;
;		Obtém o contador de frames do jogo
;------------------------------------------------------------------------------
graphics_frame_count PROC
	return frame_count
graphics_frame_count ENDP
;------------------------------------------------------------------------------
; graphics_render
;
;		Desenha os objetos do jogo na tela
;
;	hDC		{HDC}	: Handle de contexto de desenho
;------------------------------------------------------------------------------
graphics_render PROC hDC : DWORD

	invoke begin_draw, hDC

	; Fundo
	invoke draw_map

	; Desenha os objetos na tela

	invoke draw_pacman

	invoke draw_ghost, BLINKY
	invoke draw_ghost, PINKY
	invoke draw_ghost, INKY
	invoke draw_ghost, CLYDE

	invoke end_draw, hDC

	; Contador de frames
	inc frame_count

	; MOD ANIM_INTERVAL * 2
	mov edx, 0
	mov eax, frame_count
	mov ebx, ANIM_INTERVAL
	shl ebx, 1
	div ebx
	mov frame_count, edx

	invoke Sleep, FRAME_INTERVAL

	return frame_count
graphics_render ENDP
;------------------------------------------------------------------------------
; graphics_dispose_bitmaps
;
;		Libera os bitmaps da memória
;------------------------------------------------------------------------------
graphics_dispose_bitmaps PROC

	invoke DeleteObject, bitmap_mapempty
	invoke DeleteObject, bitmap_mapfull
	invoke DeleteObject, bitmap_sprites

	ret
graphics_dispose_bitmaps ENDP
;------------------------------------------------------------------------------
; begin_draw
;
;		Prepara o programa para desenho
;
;	hDC 	{HDC}	: Handle do contexto de desenho
;------------------------------------------------------------------------------
begin_draw PROC hDC : HDC

	invoke CreateCompatibleDC, hDC
	mov bufferDC, eax

	invoke CreateCompatibleBitmap, hDC, REAL_WIDTH, REAL_HEIGHT
	mov buffer, eax

	invoke SelectObject, bufferDC, buffer

	ret
begin_draw ENDP
;------------------------------------------------------------------------------
; end_draw
;
;		Transfere tudo do buffer de desenho para a tela e finaliza o desenho
;
;	hDC 	{HDC}	: Handle do contexto de desenho
;------------------------------------------------------------------------------
end_draw PROC hDC : HDC

	; Copia o buffer para a tela
	invoke StretchBlt, 	hDC,
						0, 0,
						SCREEN_WIDTH, SCREEN_HEIGHT,
						bufferDC,
						0, 0,
						REAL_WIDTH, REAL_HEIGHT,
						SRCCOPY

	; Finaliza o desenho
	invoke DeleteObject, bufferDC
	invoke DeleteObject, buffer

	ret
end_draw ENDP
;------------------------------------------------------------------------------
; draw_bitmap
;
;		Desenha um bitmap na tela
;
;	pos			{DWORD}		: Posição de destino (0XXYYh)
;	bitmap		{HBITMAP}	: Handle do bitmap
;	srcX		{DWORD}		: Posição X de origem
;	srcY		{DWORD}		: Posição Y de origem
;	srcWidth	{DWORD}		: Largura do bitmap
;	srcHeight	{DWORD}		: Altura do bitmap
;------------------------------------------------------------------------------
draw_bitmap PROC	pos 		: DWORD,
					bitmap 		: HBITMAP,
					srcX 		: DWORD,
					srcY 		: DWORD,
					srcWidth	: DWORD,
					srcHeight	: DWORD

	LOCAL 	memDC 		: HDC
	LOCAL 	dstX		: DWORD
	LOCAL 	dstY 		: DWORD

	; Decodifica a posição do objeto
	m2m dstX, pos
	and dstX, 0FF00h
	shr dstX, 8

	m2m dstY, pos
	and dstY, 000FFh

	; Cria uma contexto de desenho compatível
	invoke CreateCompatibleDC, bufferDC
	mov memDC, eax

	; Seleciona o bitmap a ser desenhado
	invoke SelectObject, memDC, bitmap

	; Transfere os bits
	invoke TransparentBlt, 	bufferDC,
							dstX, dstY,
							srcWidth, srcHeight,
							memDC,
							srcX, srcY,
							srcWidth, srcHeight,
							0

	; Limpa a memória
	invoke DeleteObject, memDC

	ret
draw_bitmap ENDP
;------------------------------------------------------------------------------
; draw_pacman
;
;		Desenha o pacman
;------------------------------------------------------------------------------
draw_pacman PROC

	LOCAL srcX : DWORD
	LOCAL srcY : DWORD
	LOCAL pos  : DWORD
	LOCAL dir  : DWORD

	invoke pac_get_attr, PACMAN, ATTR_POSITION
	mov pos, eax
	sub pos, 00707h

	invoke pac_get_attr, PACMAN, ATTR_DIRECTION
	mov dir, eax

	mov srcX, 0
	mov srcY, 0

	; Calcula a posição Y do sprite
	shr dir, 16
	y_inc:
		cmp dir, 0
		je y_n_inc

		add srcY, 16
		dec dir

		jmp y_inc
	y_n_inc:

	; Contador de frames DIV intervalo dos frames
	mov edx, 0
	mov eax, frame_count
	mov ebx, ANIM_INTERVAL
	div ebx

	; Calcula a posição X do sprite
	.if eax == 0
		add srcX, 16
	.endif

	; Desenha o bitmap
	invoke draw_bitmap, pos, bitmap_sprites, srcX, srcY, 16, 16
	
	ret
draw_pacman ENDP
;------------------------------------------------------------------------------
; draw_ghost
;
;		Desenha um fantasma
;
;	id 	{DWORD}	: ID do fantasma
;------------------------------------------------------------------------------
draw_ghost PROC id : DWORD

	LOCAL srcX : DWORD
	LOCAL srcY : DWORD
	LOCAL pos  : DWORD
	LOCAL dir  : DWORD
	
	invoke pac_get_attr, id, ATTR_POSITION
	mov pos, eax
	sub pos, 7

	invoke pac_get_attr, id, ATTR_DIRECTION
	mov dir, eax

	mov srcX, 0
	mov srcY, 64

	; Calcula a posição Y do sprite
	y_inc:
		sub id, 004h
		cmp id, 0
		je y_n_inc

		add srcY, 16

		jmp y_inc
	y_n_inc:

	; Contador de frames DIV intervalo dos frames
	mov edx, 0
	mov eax, frame_count
	mov ebx, ANIM_INTERVAL
	div ebx

	; Calcula a posição X do sprite
	shr dir, 16
	x_inc:
		cmp dir, 0
		je x_n_inc

		add srcX, 32
		dec dir

		jmp x_inc
	x_n_inc:

	.if eax == 0
		add srcX, 16
	.endif

	; Desenha o bitmap
	invoke draw_bitmap, pos, bitmap_sprites, srcX, srcY, 16, 16
	
	ret
draw_ghost ENDP
;------------------------------------------------------------------------------
; draw_map
;
;		Desenha o mapa do jogo
;------------------------------------------------------------------------------
draw_map PROC
	
	mov esi, 0
	.while esi < 868

		xor edx, edx
		mov eax, esi
		mov ecx, 28
		div ecx

		mov ecx, edx
		mov ebx, eax

		shl ecx, 3
		shl ebx, 3

		invoke pac_get_mapcell, cl, bl

		mov edx, ebx
		mov bh, cl

		.if eax == MAP_NONE
			invoke draw_bitmap, ebx, bitmap_mapempty, ecx, edx, 8, 8
		.else
			invoke draw_bitmap, ebx, bitmap_mapfull, ecx, edx, 8, 8
		.endif

		inc esi
	.endw

	ret

draw_map ENDP

end