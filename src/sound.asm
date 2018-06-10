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

include c:\MASM32\INCLUDE\winmm.inc
includelib c:\MASM32\LIB\winmm.lib

include include\macros.inc
include include\pacman.inc
include include\sound.inc

;==============================================================================
; Protótipos
;==============================================================================

; Toca um resource
play_resource PROTO :DWORD

;==============================================================================
; Constantes
;==============================================================================
.const

    SND_PACMAN_CHOMP    EQU 040h

;==============================================================================
; Seção de dados
;==============================================================================
.data?

    this_instance       DWORD ?

    pacman_chomp        DWORD ?

;==============================================================================
; Seção de código
;==============================================================================
.code
;------------------------------------------------------------------------------
; sound_load
;
;       Carrega os sons do jogo
;
;   hinstance   {DWORD} : Instância do executável do jogo
;------------------------------------------------------------------------------
sound_load PROC hinstance : DWORD
    m2m this_instance, hinstance

    invoke PlaySound, SND_PACMAN_CHOMP, this_instance, SND_RESOURCE or SND_LOOP or SND_ASYNC
    
    ret
sound_load ENDP
;------------------------------------------------------------------------------
; sound_update
;
;       Atualiza os sons do jogo
;------------------------------------------------------------------------------
sound_update PROC

    ret
sound_update ENDP

end