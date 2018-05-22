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
FillBuffer  PROTO :DWORD,:DWORD,:BYTE
Paint_Proc  PROTO :DWORD,:DWORD,:DWORD

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
    hBmp          DWORD ?

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

      mov Wwd, 448
      mov Wht, 496

      invoke GetSystemMetrics,SM_CXSCREEN
      invoke TopXY,Wwd,eax
      mov Wtx, eax

      invoke GetSystemMetrics,SM_CYSCREEN
      invoke TopXY,Wht,eax
      mov Wty, eax

      invoke CreateWindowEx,WS_EX_LEFT,
                            ADDR szClassName,
                            ADDR szDisplayName,
                            WS_OVERLAPPED or WS_SYSMENU,
                            Wtx,Wty,Wwd,Wht,
                            NULL,NULL,
                            hInst,NULL
      mov   hWnd,eax

      invoke ShowWindow,hWnd,SW_SHOWNORMAL
      invoke UpdateWindow,hWnd

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
    LOCAL buffer1[128]:BYTE  ; these are two spare buffers
    LOCAL buffer2[128]:BYTE  ; for text manipulation etc..

    .if uMsg == WM_COMMAND
      .if wParam == 500
          invoke GetDC,hWin
          mov hDC, eax
          invoke Paint_Proc,hWin,hDC,1
          invoke ReleaseDC,hWin,hDC
        return 0
      .endif

    ;======== menu commands ========
    .elseif uMsg == WM_CREATE

      invoke LoadBitmap, hInstance, 200
      mov hBmp, eax

    .elseif uMsg == WM_SIZE

    .elseif uMsg == WM_PAINT
        invoke BeginPaint,hWin,ADDR Ps
        mov hDC, eax
        invoke Paint_Proc,hWin,hDC,0
        invoke EndPaint,hWin,ADDR Ps
        return 0

    .elseif uMsg == WM_CLOSE

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

Paint_Proc proc hWin:DWORD, hDC:DWORD, movit:DWORD

    LOCAL hOld :DWORD
    LOCAL memDC:DWORD
    LOCAL var1 :DWORD
    LOCAL var2 :DWORD
    LOCAL var3 :DWORD  

    invoke CreateCompatibleDC,hDC
    mov memDC, eax
    
    invoke SelectObject,memDC,hBmp

    invoke StretchBlt, hDC, 0, 0, 448, 496, memDC, 0, 0, 224, 248, SRCCOPY 

    invoke DeleteDC,memDC

    return 0

Paint_Proc endp

; ########################################################################

end start
