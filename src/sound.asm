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
    SND_PACMAN_DIE    	EQU 050h

;==============================================================================
; Seção de dados
;==============================================================================
.data?

    this_instance       DWORD ?

   	current_state       DWORD ?

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
    mov current_state, STATE_NORMAL

    ret
sound_load ENDP
;------------------------------------------------------------------------------
; sound_update
;
;       Atualiza os sons do jogo
;------------------------------------------------------------------------------
sound_update PROC
	
	invoke pac_get_attr, PACMAN, ATTR_STATE
    
    .if current_state != eax
    	mov current_state, eax

    	.if current_state == STATE_NORMAL
			invoke PlaySound, SND_PACMAN_CHOMP, this_instance, SND_RESOURCE or SND_LOOP or SND_ASYNC
		.elseif current_state == STATE_DEAD
			invoke PlaySound, SND_PACMAN_DIE, this_instance, SND_RESOURCE or SND_LOOP or SND_ASYNC
		.endif
    .endif

    ret
sound_update ENDP

end