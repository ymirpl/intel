

; zmienne lokalne f-cji glownej


%define IMGSIZE			[ebp-4]
%define ZERO			[ebp-16]

%define X			[ebp-20]
%define ALIGNJUNK		[ebp-24]
%define NEWSOURCE		[ebp-28]
%define HYPHEN			[ebp-52]

%define WINDOWWIDTH		[ebp-32]
%define WINDOWHEIGHT		[ebp-36]

%define SUMBFFR			[ebp-40]
%define SUMBFFG			[ebp-44]
%define SUMBFFB			[ebp-48]

%define WIDTH			[ebp+12]
%define HEIGHT			[ebp+16]
%define W			[ebp+20]
%define H			[ebp+24]



; global _filter
; extern _malloc
; extern _free
global filter
extern malloc

section .text

;
; void process (unsigned char* dealigned_src, int width, int height, unsigned char* dst, int w, int h, unsigned char* brightness_map);;		
;		Copies the image to the new memory block, omitting BMP "align to 4 bytes in row" bytes.
;		Additionally in the new array every pixel is aligned to 4 bytes, as in: [B G R 00].
;		TODO : make diff	
;		Args:
;		ebp - old ebp
;		ebp+4 ra
;		ebp+8 img etc.

;_filter:
filter:
	; liczymy ile jest smiecia na koniec kazdego wiersza
	push	ebp		; Prolog.
        mov	ebp, esp
	sub	esp, 52		; miejsce na locale
	push	edi
	push	esi
	push	ebx

	mov	eax, [ebp+12]	; eax = width
	shl	eax, 1		; eax = 2*eax
	add	eax, [ebp+12]	; eax = 3*eax
	and	eax, 0x03	; jezeli ostatnie dwa bity eax sa 00, to znaczy, ze wyrownany plik juz jest (hura!)
				; w eax jest %4
	jz	ok_aligned				
	sub	eax, 4
	neg	eax		; w eax "dopelnienie" tej reszty do 4
ok_aligned:
	mov	ALIGNJUNK, eax	;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; bedziemy liczyc mianownik
	mov	eax, [ebp+12]	; eax = width
	inc	eax		; eax = width + 1
	mov	edx, [ebp+16]	; edx = Height
	inc	edx		; edx = height + 1
	mul	edx		; edx = mianownik
	mov	HYPHEN, edx	; zapisujemy sobie mianownik
	
	; init WINDOWWIDTH
	mov	ebx, [ebp+24]	; width
	shl	ebx, 1
	inc	ebx
	mov	WINDOWWIDTH, ebx

	; init WHEIGHT
	mov	ebx, [ebp+28]
	shl	ebx, 1
	inc	ebx
	mov	WINDOWHEIGHT, ebx

	; init BUFFERs
	mov	eax, WINDOWWIDTH
	shl	eax, 2
	push	eax

	;call	_malloc		; Malloc wpisuje adres do eax
	call	malloc
	mov	SUMBFFR, eax
;	call	_malloc
	call 	malloc
	mov	SUMBFFG, eax
;	call	_malloc
	call	malloc
	mov	SUMBFFB, eax
	add	esp, 4		; usun eax ze stosu

	; init IMGSIZE
	mov	eax, [ebp+12]	; width
	mov	edx, [ebp+16]	; height 
	mul	edx		; wynik  w eax
	mov	IMGSIZE, eax


	; init src and dst
	mov	esi, [ebp+8]	; wejsciowy obrazek 
	mov	edi, [ebp+20]	; wyjsciowy obrazek

	; bedziemy filtrowac



	; najpierw wypelniamy cale buforki

	; przygotowanie ecx

	mov	ebx, ALIGNJUNK
	mov	edx, WIDTH
	lea	eax, [ebx + 02*edx]
	add	eax, edx
	mov	edx, H
	mul	edx
	mov	ecx, eax 	; ecx = (3*width + junk)*h	
	neg	ecx		; -ecx
loopX:
	
	loopY:
		movzx	eax, byte [esi+ecx]


	pop	ebx		; Epilog
	pop	esi
	pop	edi
	leave
	ret

