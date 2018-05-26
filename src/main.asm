;==============================================================================
; main.asm
;------------------------------------------------------------------------------
; Arquivo principal do jogo
;==============================================================================
.386
.model flat, stdcall
option casemap :none
;==============================================================================
; Cabeçalhos
;==============================================================================
include \MASM32\INCLUDE\windows.inc
include \MASM32\INCLUDE\user32.inc
include \MASM32\INCLUDE\gdi32.inc
include \MASM32\INCLUDE\kernel32.inc
include \MASM32\INCLUDE\masm32.inc

include include\macros.inc
include include\graphics.inc
include include\pacman.inc
;==============================================================================
; Bibliotecas
;==============================================================================
includelib \MASM32\LIB\masm32.lib
includelib \MASM32\LIB\gdi32.lib
includelib \MASM32\LIB\user32.lib
includelib \MASM32\LIB\kernel32.lib
;==============================================================================
; Protótipos
;==============================================================================

; Procedimento principal
WinMain 				PROTO :DWORD, :DWORD, :DWORD, :DWORD

; Procedimento da janela
WinProc 				PROTO :DWORD, :DWORD, :DWORD, :DWORD

; Cria a janela
create_window			PROTO :DWORD

; Registra a classe da janela
register_window_class	PROTO :DWORD

; Evento de criação da janela
on_create				PROTO :DWORD

; Evento de desenho
on_render 				PROTO :DWORD

; Evento de fechamento
on_destroy 				PROTO :DWORD

;==============================================================================
; Seção de dados
;==============================================================================
.data?

	this_instance	DWORD	?

;==============================================================================
; Seção de código
;==============================================================================
.code
;------------------------------------------------------------------------------
; Constantes
;------------------------------------------------------------------------------
RC_ICON			EQU		01h
WND_CLASS_NAME	EQU		"PacMan", 0
WND_TITLE		EQU		"Pac Man", 0
WND_WIDTH		EQU		454
WND_HEIGHT		EQU		524
;------------------------------------------------------------------------------
; Ponto de entrada
;------------------------------------------------------------------------------
start:

	invoke 	GetModuleHandle, NULL
	mov 	this_instance, eax

	invoke 	GetCommandLine

	invoke 	WinMain, this_instance, NULL, eax, SW_SHOWDEFAULT
	invoke 	ExitProcess, eax
;------------------------------------------------------------------------------
; register_window_class
;
;		Registra a classe da janela
;
; 	hInst     {HINSTANCE} : Instância do programa
;------------------------------------------------------------------------------
register_window_class PROC hInst : DWORD

	LOCAL 	wc      	:WNDCLASSEX

	; Nome da classe
	string 	class_name, WND_CLASS_NAME

	; Inicializa o WNDCLASSEX
	mov 	wc.cbSize,         sizeof WNDCLASSEX
	mov 	wc.style,          CS_BYTEALIGNWINDOW or CS_BYTEALIGNCLIENT
	mov 	wc.lpfnWndProc,    offset WndProc
	mov 	wc.cbClsExtra,     NULL
	mov 	wc.cbWndExtra,     NULL
	m2m 	wc.hInstance,      hInst
	m2m 	wc.hbrBackground,  NULL
	mov 	wc.lpszMenuName,   NULL
	mov 	wc.lpszClassName,  offset class_name

	; Ícone
	invoke 	LoadIcon, hInst, RC_ICON
	m2m 	wc.hIcon, eax
	m2m 	wc.hIconSm, eax

	; Cursor
	invoke 	LoadCursor, NULL, IDC_ARROW
	mov 	wc.hCursor, eax

	invoke 	RegisterClassEx, ADDR wc

	ret
register_window_class ENDP
;------------------------------------------------------------------------------
; create_window
;
;		Cria a janela e salva na variável `window`
;
; 	hInst     {HINSTANCE} : Instância do programa
;------------------------------------------------------------------------------
create_window PROC hInst : DWORD

	LOCAL	window 	:HWND

	; Nome da classe da janela
	string 	window_title, WND_TITLE

	; Registra a classe da janela
	invoke 	register_window_class, hInst

	; Cria a janela
	invoke 	CreateWindowEx,	WS_EX_LEFT,
							ADDR class_name,
							ADDR window_title,
							WS_OVERLAPPED or WS_SYSMENU,
							CW_USEDEFAULT, CW_USEDEFAULT,
							WND_WIDTH, WND_HEIGHT,
							NULL,
							NULL,
							hInst,
							NULL
	mov 	window, eax

	; Mostra e prepara a janela
	invoke 	ShowWindow, window,SW_SHOWNORMAL
	invoke 	UpdateWindow, window
	invoke 	InvalidateRect, window, NULL, FALSE

	ret
create_window ENDP
;------------------------------------------------------------------------------
; WinMain
;
;     	Procedimento principal
;
; 	hInst     {HINSTANCE} : Instância do programa
;   hPrevInst {HINSTANCE} : Instância anterior do programa
;   CmdLine   {LPCSTR}    : Linha de comando que chamou o programa
;   CmdShow   {DWORD}     : Determina se deve exibir a janela
;------------------------------------------------------------------------------
WinMain PROC hInst : DWORD, hPrevInst : DWORD, CmdLine : DWORD, CmdShow : DWORD

	; Variáveis locais
	LOCAL 	msg     :MSG
	
	; Cria a janela e salva em `window`
	invoke 	create_window, hInst

	; Loop principal
	main_loop:
		invoke 	GetMessage, ADDR msg, NULL, 0, 0
		cmp 	eax, 0
		je 		exit

		; Se não, trata e volta pro loop
		invoke 	TranslateMessage, ADDR msg
		invoke 	DispatchMessage,  ADDR msg
		jmp 	main_loop
	exit:

	return 	msg.wParam

WinMain ENDP
;------------------------------------------------------------------------------
; WinProc
;
;       Procedimento da janela
;
;   hWnd    {HWND}  : Handle da janela
;   uMsg    {DWORD} : Mensagem
;   wParam  {DWORD} : Parâmetro wide
;   lParam  {DWORD} : Parâmetro long
;------------------------------------------------------------------------------
WndProc PROC hWnd : DWORD, uMsg : DWORD, wParam : DWORD, lParam : DWORD

	.if uMsg == WM_CREATE
		invoke 	on_create, hWnd
		ret

	.elseif uMsg == WM_PAINT
		invoke 	on_render, hWnd
		ret

	.elseif uMsg == WM_DESTROY
		invoke 	on_destroy, hWnd
		ret

	.endif

	invoke 	DefWindowProc, hWnd, uMsg, wParam, lParam

	ret
WndProc ENDP
;------------------------------------------------------------------------------
; on_create
;
;       Evento de criação da janela
;
;   hWnd    {HWND}  : Handle da janela
;------------------------------------------------------------------------------
on_create PROC hWnd : DWORD

	invoke 	graphics_load_bitmaps, this_instance

	ret
on_create ENDP
;------------------------------------------------------------------------------
; on_render
;
;       Evento de desenho
;
;   hWnd    {HWND}  : Handle da janela
;------------------------------------------------------------------------------
on_render PROC hWnd : DWORD

  	LOCAL 	hDC   	:DWORD
  	LOCAL 	Ps     	:PAINTSTRUCT

	; Configura a janela para desenho e obtém o contexto
	invoke 	BeginPaint, hWnd, ADDR Ps
	mov 	hDC, eax

	; Atualiza e renderiza o jogo
	;call 	pacman_update
	invoke 	graphics_render, hDC

	; Finaliza o desenho e libera os recursor
	invoke 	EndPaint, hWnd, ADDR Ps

	; Invalida de novo, para chamar a função a 16 fps
	invoke 	InvalidateRect, hWnd, NULL, FALSE

	ret
on_render ENDP
;------------------------------------------------------------------------------
; on_destroy
;
;		Evento de destruição da janela
;
;   hWnd    {HWND}  : Handle da janela
;------------------------------------------------------------------------------
on_destroy PROC hWnd : DWORD

	;invoke 	graphics_dispose_bitmaps
	invoke 	ExitProcess, 0

	ret
on_destroy ENDP

end start