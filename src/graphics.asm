;==============================================================================
; graphics.asm
;------------------------------------------------------------------------------
; Implementação das funções de desenho do jogo
;==============================================================================
.386
.model flat, stdcall
option casemap :none

include \MASM32\INCLUDE\windows.inc
include \MASM32\INCLUDE\user32.inc
include \MASM32\INCLUDE\gdi32.inc
include \MASM32\INCLUDE\kernel32.inc
include \MASM32\INCLUDE\masm32.inc

include include\macros.inc
include include\graphics.inc

includelib \MASM32\LIB\masm32.lib
includelib \MASM32\LIB\gdi32.lib
includelib \MASM32\LIB\user32.lib
includelib \MASM32\LIB\kernel32.lib
includelib \MASM32\LIB\Msimg32.lib
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
						:DWORD,
						:HBITMAP,
						:DWORD,
						:DWORD,
						:DWORD,
						:DWORD

; Desenha o pacman
draw_pacman		PROTO 	:DWORD,
						:DWORD,
						:BYTE

; Desenha um fantasma
draw_ghost		PROTO 	:BYTE,
						:DWORD,
						:DWORD,
						:BYTE

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
; Seção de código
;==============================================================================
.code
;------------------------------------------------------------------------------
; Constantes
;------------------------------------------------------------------------------

; Dimensões da tela
SCREEN_WIDTH	EQU 	448
SCREEN_HEIGHT 	EQU 	496

REAL_WIDTH 		EQU 	224
REAL_HEIGHT 	EQU 	248

; Bitmaps
BMP_MAPFULL 	EQU		021h
BMP_MAPEMPTY	EQU		020h
BMP_SPRITES		EQU		010h

; Fantasmas
BLINKY			EQU		00h
PINKY			EQU		01h
INKY			EQU		02h
CLYDE			EQU		03h

; Direções
DIR_RIGHT		EQU 	00h
DIR_LEFT		EQU 	01h
DIR_UP 			EQU 	02h
DIR_DOWN		EQU 	03h

; Intervalo entre os frames
FRAME_INTERVAL	EQU 	256

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
; graphics_render
;
;		Desenha os objetos do jogo na tela
;
;	hDC		{HDC}	: Handle de contexto de desenho
;------------------------------------------------------------------------------
graphics_render PROC hDC : DWORD

	invoke begin_draw, hDC

	; Fundo
	invoke draw_bitmap, 0, 0, bitmap_mapfull, 0, 0, REAL_WIDTH, REAL_HEIGHT

	;TODO: Desenhar objetos na tela

	invoke draw_pacman, 5, 5, DIR_RIGHT

	invoke draw_ghost, BLINKY, 21, 4, DIR_LEFT
	invoke draw_ghost, PINKY, 37, 4, DIR_LEFT
	invoke draw_ghost, INKY, 53, 4, DIR_LEFT
	invoke draw_ghost, CLYDE, 69, 4, DIR_LEFT

	invoke end_draw, hDC

	; Contador de frames
	inc frame_count

	; MOD intervalo dos frames * 2
	mov edx, 0
	mov eax, frame_count
	mov ebx, FRAME_INTERVAL
	shl ebx, 1
	div ebx
	mov frame_count, edx

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
;	dstX		{DWORD}		: Posição X de destino
;	dstY		{DWORD}		: Posição Y de destino
;	bitmap		{HBITMAP}	: Handle do bitmap
;	srcX		{DWORD}		: Posição X de origem
;	srcY		{DWORD}		: Posição Y de origem
;	srcWidth	{DWORD}		: Largura do bitmap
;	srcHeight	{DWORD}		: Altura do bitmap
;------------------------------------------------------------------------------
draw_bitmap PROC	dstX		: DWORD,
					dstY		: DWORD,
					bitmap 		: HBITMAP,
					srcX 		: DWORD,
					srcY 		: DWORD,
					srcWidth	: DWORD,
					srcHeight	: DWORD

	LOCAL 	memDC 		: HDC

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
;
;	x 		{DWORD}	: Posição X
;	y 		{DWORD}	: Posição Y
;	dir 	{BYTE}	: Direção
;------------------------------------------------------------------------------
draw_pacman PROC x : DWORD, y : DWORD, dir : BYTE

	LOCAL srcX : DWORD
	LOCAL srcY : DWORD

	mov srcX, 0
	mov srcY, 0

	; Calcula a posição Y do sprite
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
	mov ebx, FRAME_INTERVAL
	div ebx

	; Calcula a posição X do sprite
	.if eax == 0
		add srcX, 16
	.endif

	; Desenha o bitmap
	invoke draw_bitmap, x, y, bitmap_sprites, srcX, srcY, 16, 16
	
	ret
draw_pacman ENDP
;------------------------------------------------------------------------------
; draw_ghost
;
;		Desenha um fantasma
;
;	id 		{BYTE}	: ID do fantasma
;	x 		{DWORD}	: Posição X
;	y 		{DWORD}	: Posição Y
;	dir 	{BYTE}	: Direção
;------------------------------------------------------------------------------
draw_ghost PROC id : BYTE, x : DWORD, y : DWORD, dir : BYTE

	LOCAL srcX : DWORD
	LOCAL srcY : DWORD

	mov srcX, 0
	mov srcY, 64

	; Calcula a posição Y do sprite
	y_inc:
		cmp id, 0
		je y_n_inc

		add srcY, 16
		dec id

		jmp y_inc
	y_n_inc:

	; Contador de frames DIV intervalo dos frames
	mov edx, 0
	mov eax, frame_count
	mov ebx, FRAME_INTERVAL
	div ebx

	; Calcula a posição X do spite
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
	invoke draw_bitmap, x, y, bitmap_sprites, srcX, srcY, 16, 16
	
	ret
draw_ghost ENDP

end