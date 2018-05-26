;==============================================================================
; macros.inc
;------------------------------------------------------------------------------
; Definição de alguns macros usados no jogo
;==============================================================================
;------------------------------------------------------------------------------
; string
;
;     Declara uma variável de texto
;
;   name          : Nome da variável
;   text {VARARG} : Texto
;------------------------------------------------------------------------------
string MACRO name, text:VARARG

	LOCAL 	lbl

	jmp 	lbl
		name db text, 0
	lbl:

ENDM
;------------------------------------------------------------------------------
; m2m
;
;     Move de memória para memória
;
;   dest  : Destino
;   src   : Origem
;------------------------------------------------------------------------------
m2m MACRO dest, src

	push 	src
	pop  	dest

ENDM
;------------------------------------------------------------------------------
; return
;
;     Retorna um valor de uma função usando o registrador de retorno
;
;   arg : Valor sendo retornado
;------------------------------------------------------------------------------
return MACRO arg

	mov 	eax, arg

	ret
ENDM