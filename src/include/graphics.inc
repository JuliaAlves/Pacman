;==============================================================================
; graphics.inc
;------------------------------------------------------------------------------
; Definição das funções de desenho do jogo
;==============================================================================

; Carrega os bitmaps necessários
graphics_load_bitmaps PROTO :DWORD

; Obtém o contador de frames
graphics_frame_count PROTO

; Desenha os objetos do jogo na tela
graphics_render PROTO :DWORD

; Libera os bitmaps da memória
graphics_dispose_bitmaps PROTO
