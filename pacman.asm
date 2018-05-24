; #########################################################################
;                                Pac-Man
; #########################################################################

.386
.model flat, stdcall  ; 32 bit STDCALL
option casemap :none  ; case sensitive
      
; Includes
include \MASM32\INCLUDE\windows.inc
include \MASM32\INCLUDE\masm32.inc
include \MASM32\INCLUDE\gdi32.inc
include \MASM32\INCLUDE\user32.inc
include \MASM32\INCLUDE\kernel32.inc
include \MASM32\INCLUDE\Comctl32.inc
include \MASM32\INCLUDE\comdlg32.inc
include \MASM32\INCLUDE\shell32.inc

; Bibliotecas
includelib \MASM32\LIB\masm32.lib
includelib \MASM32\LIB\gdi32.lib
includelib \MASM32\LIB\user32.lib
includelib \MASM32\LIB\kernel32.lib
includelib \MASM32\LIB\Comctl32.lib
includelib \MASM32\LIB\comdlg32.lib
includelib \MASM32\LIB\shell32.lib

; Protótipos
WinMain     PROTO :DWORD,:DWORD,:DWORD,:DWORD
WndProc     PROTO :DWORD,:DWORD,:DWORD,:DWORD
TopXY       PROTO :DWORD,:DWORD
Paint_Proc  PROTO :DWORD,:DWORD

; Macros
szText MACRO Name, Text:VARARG
  LOCAL lbl
  jmp lbl
    Name db Text,0
  lbl:
ENDM

m2m MACRO M1, M2
  push M2
  pop  M1
ENDM

return MACRO arg
  mov eax, arg
  ret
ENDM

; #########################################################################

.data?

    hInstance     DWORD ?
    hIcon         DWORD ?
    hWnd          DWORD ?
    CommandLine   DWORD ?
    szDisplayName DWORD ?

    mapFullBitmap   DWORD ?
    mapEmptyBitmap  DWORD ?
    spritesBitmap   DWORD ?

; #########################################################################

.code

start:
      invoke GetModuleHandle, NULL
      mov hInstance, eax

      invoke WinMain,hInstance,NULL,CommandLine,SW_SHOWDEFAULT
      invoke ExitProcess,eax

; #########################################################################

WinMain proc hInst     :DWORD,
             hPrevInst :DWORD,
             CmdLine   :DWORD,
             CmdShow   :DWORD

      ;====================
      ; Put LOCALs on stack
      ;====================

      LOCAL wc      :WNDCLASSEX
      LOCAL msg     :MSG
      LOCAL Wwd     :DWORD
      LOCAL Wht     :DWORD
      LOCAL Wtx     :DWORD
      LOCAL Wty     :DWORD
      LOCAL hBrush  :DWORD
      LOCAL wrect   :RECT

      ;==================================================
      ; Fill WNDCLASSEX structure with required variables
      ;==================================================

      invoke LoadIcon,hInst,500    ; icon ID
      mov hIcon, eax

      szText szClassName,"Project_Class"

      invoke CreateSolidBrush, 0
      mov hBrush, eax

      mov wc.cbSize,         sizeof WNDCLASSEX
      mov wc.style,          CS_BYTEALIGNWINDOW or CS_BYTEALIGNCLIENT
      mov wc.lpfnWndProc,    offset WndProc
      mov wc.cbClsExtra,     NULL
      mov wc.cbWndExtra,     NULL
      m2m wc.hInstance,      hInst
      m2m wc.hbrBackground,  hBrush
      mov wc.lpszMenuName,   NULL
      mov wc.lpszClassName,  offset szClassName
      m2m wc.hIcon,          hIcon
      invoke LoadCursor,NULL,IDC_ARROW
      mov wc.hCursor,        eax
      m2m wc.hIconSm,        hIcon

      invoke RegisterClassEx, ADDR wc

      ;================================
      ; Centre window at following size
      ;================================

      mov wrect.left, 0
      mov wrect.top, 0
      mov wrect.right, 454    ; 448 + 6
      mov wrect.bottom, 524   ; 496 + 28

      invoke GetSystemMetrics,SM_CXSCREEN
      invoke TopXY,wrect.right,eax
      mov Wtx, eax

      invoke GetSystemMetrics,SM_CYSCREEN
      invoke TopXY,wrect.bottom,eax
      mov Wty, eax

      invoke CreateWindowEx,WS_EX_LEFT,
                            ADDR szClassName,
                            ADDR szDisplayName,
                            WS_OVERLAPPED or WS_SYSMENU,
                            Wtx,Wty,wrect.right,wrect.bottom,
                            NULL,NULL,
                            hInst,NULL
      mov hWnd,eax

      invoke ShowWindow,hWnd,SW_SHOWNORMAL
      invoke UpdateWindow,hWnd

      invoke InvalidateRect, hWnd, NULL, FALSE
      ;===================================
      ; Loop until PostQuitMessage is sent
      ;===================================

    StartLoop:

      invoke GetMessage,ADDR msg,NULL,0,0
      cmp eax, 0
      je ExitLoop
      invoke TranslateMessage, ADDR msg
      invoke DispatchMessage,  ADDR msg
      jmp StartLoop
    ExitLoop:

      return msg.wParam

WinMain endp

; #########################################################################

WndProc proc hWin   :DWORD,
             uMsg   :DWORD,
             wParam :DWORD,
             lParam :DWORD

    LOCAL var    :DWORD
    LOCAL caW    :DWORD
    LOCAL caH    :DWORD
    LOCAL Rct    :RECT
    LOCAL hDC    :DWORD
    LOCAL Ps     :PAINTSTRUCT

    .if uMsg == WM_CREATE

      invoke LoadBitmap, hInstance, 100
      mov spritesBitmap, eax

      invoke LoadBitmap, hInstance, 200
      mov mapFullBitmap, eax

      invoke LoadBitmap, hInstance, 300
      mov mapEmptyBitmap, eax

    .elseif uMsg == WM_PAINT
        invoke BeginPaint,hWin,ADDR Ps
        mov hDC, eax

        invoke Paint_Proc,hWin,hDC

        invoke EndPaint,hWin,ADDR Ps
        invoke InvalidateRect, hWnd, NULL, FALSE

    .elseif uMsg == WM_DESTROY
        invoke PostQuitMessage,NULL
        return 0 
    .endif

    invoke DefWindowProc,hWin,uMsg,wParam,lParam

    ret

WndProc endp

; ########################################################################

TopXY proc wDim:DWORD, sDim:DWORD

    shr sDim, 1      ; divide screen dimension by 2
    shr wDim, 1      ; divide window dimension by 2
    mov eax, wDim    ; copy window dimension into eax
    sub sDim, eax    ; sub half win dimension from half screen dimension

    return sDim

TopXY endp

; ########################################################################

Paint_Proc proc hWin:DWORD, hDC:DWORD
    LOCAL memDC:DWORD

    invoke CreateCompatibleDC,hDC
    mov memDC, eax
    
    invoke SelectObject,memDC,hBmp

    invoke StretchBlt, hDC, 0, 0, 448, 496, memDC, 0, 0, 224, 248, SRCCOPY 

    invoke DeleteDC,memDC

    return 0

Paint_Proc endp

; ########################################################################

end start
