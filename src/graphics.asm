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
;==============================================================================
; Protótipos
;==============================================================================

; Desenha um bitmap
draw_bitmap 	PROTO 	:HDC,
						:DWORD,
						:DWORD,
						:HBITMAP,
						:DWORD,
						:DWORD,
						:DWORD,
						:DWORD

;==============================================================================
; Seção de dados
;==============================================================================
.data?

	bitmap_mapfull  DWORD   ?	; Bitmap do mapa cheio
	bitmap_mapempty DWORD   ?	; Bitmap do mapa vazio
	bitmap_sprites	DWORD   ?	; Bitmap dos sprites

;==============================================================================
; Seção de código
;==============================================================================
.code
;------------------------------------------------------------------------------
; Constantes
;------------------------------------------------------------------------------
BMP_MAPFULL 	EQU		021h
BMP_MAPEMPTY	EQU		020h
BMP_SPRITES		EQU		010h
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

	invoke draw_bitmap, hDC, 0, 0, bitmap_mapfull, 0, 0, 224, 248

	;TODO: Desenhar objetos na tela

	ret
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
; draw_bitmap
;
;		Desenha um bitmap na tela
;
;	hDC			{HDC}		: Handle de contexto de desenho
;	dstX		{DWORD}		: Posição X de destino
;	dstY		{DWORD}		: Posição Y de destino
;	bitmap		{HBITMAP}	: Handle do bitmap
;	srcX		{DWORD}		: Posição X de origem
;	srcY		{DWORD}		: Posição Y de origem
;	srcWidth	{DWORD}		: Largura do bitmap
;	srcHeight	{DWORD}		: Altura do bitmap
;------------------------------------------------------------------------------
draw_bitmap PROC 	hDC 		: HDC,
					dstX		: DWORD,
					dstY		: DWORD,
					bitmap 		: HBITMAP,
					srcX 		: DWORD,
					srcY 		: DWORD,
					srcWidth	: DWORD,
					srcHeight 	: DWORD

	LOCAL 	memDC 		: HDC
	LOCAL 	dstWidth	: DWORD
	LOCAL	dstHeight	: DWORD

	invoke CreateCompatibleDC, hDC
	mov memDC, eax

	invoke SelectObject, memDC, bitmap

	m2m dstWidth, srcWidth
	shl dstWidth, 1

	m2m dstHeight, srcHeight
	shl dstHeight, 1

	invoke StretchBlt, 	hDC,
						dstX, dstY,
						dstWidth, dstHeight,
						memDC,
						srcX, srcY,
						srcWidth, srcHeight,
						SRCCOPY

	invoke DeleteObject, memDC

	ret
draw_bitmap ENDP

end