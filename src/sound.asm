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
    SND_PACMAN_DIE      EQU 050h
    SND_PACMAN_POWER   	EQU 060h

;==============================================================================
; Seção de dados
;==============================================================================
.data?

    this_instance       DWORD ?

    current_state       DWORD ?
   	current_state_ghosts       DWORD ?

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
	
    mov esi, BLINKY
    .while esi <= CLYDE
        invoke pac_get_attr, esi, ATTR_STATE
        cmp eax, STATE_POWER
        je som_power

        add esi, 4
    .endw
    jmp fim
    som_power:
        .if current_state_ghosts != STATE_POWER
            invoke PlaySound, SND_PACMAN_POWER, this_instance, SND_RESOURCE or SND_LOOP or SND_ASYNC
            mov current_state_ghosts, STATE_POWER
        .endif
        jmp n_fim
    fim:

        .if current_state_ghosts != STATE_NORMAL
            invoke PlaySound, SND_PACMAN_CHOMP, this_instance, SND_RESOURCE or SND_LOOP or SND_ASYNC
        .endif

        mov current_state_ghosts, STATE_NORMAL

        invoke pac_get_attr, PACMAN, ATTR_STATE

        .if current_state != eax
        	mov current_state, eax

        	.if current_state == STATE_NORMAL
                invoke PlaySound, SND_PACMAN_CHOMP, this_instance, SND_RESOURCE or SND_LOOP or SND_ASYNC

            .elseif current_state == STATE_DEAD
                invoke PlaySound, SND_PACMAN_DIE, this_instance, SND_RESOURCE or SND_LOOP or SND_ASYNC
            .endif  
        .endif
    n_fim:
    ret
sound_update ENDP

end