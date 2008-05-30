

; zmienne lokalne f-cji glownej


%define IMGSIZE			[ebp-4]
%define ZERO			[ebp-16]

%define X			[ebp-20]
%define ALIGNJUNK		[ebp-24]
%define SB			[ebp-28]
%define HYPHEN			[ebp-52]

%define LROWB			[ebp-56] ; lewy brzeg wiersza
%define RROWB			[ebp-60] ; prawy brzeg wiersza
%define ULIMIT			[ebp-64] ; gorny brzeg obrazka
%define DLIMIT			[ebp-68] ; dolny brzeg obrazka


;%define LVR			[ebp-72] ; lewy wartosc
;%define LVB			[ebp-73]
;%define LVG			[ebp-74]

%define SG			[ebp-76] 
;%define RVG			[ebp-77]
;%define RVB			[ebp-78]

;%define UVR			[ebp-80] ; gorny
;%define UVB			[ebp-81]
;%define UVG			[ebp-82]

%define Y			[ebp-84] ; dolny
;%define DVG			[ebp-85]
;%define DVB			[ebp-86]

%define MASKSTARTUP		[ebp-88]
%define BOFF			[ebp-92]


%define WINDOWWIDTH		[ebp-32]
%define WINDOWHEIGHT		[ebp-36]
%define ROW			[ebp-96]

%define BUFF			[ebp-40]
%define BUFFEND			[ebp-44]
%define SR			[ebp-48]

%define WIDTH			[ebp+12]
%define HEIGHT			[ebp+16]
%define W			[ebp+24]
%define H			[ebp+28]
%define IN			[ebp+8]
%define OUT			[ebp+20]



; global _filter
; extern _malloc
; extern _free
global filter
extern malloc

section .text




	Ygora:

		mov	SB, dword 0 ; ustawiamy sumy na zero
		mov	SR, dword 0
		mov	SG, dword 0
		
		push 	ecx ; ten counter to na pozniej tez potrzebny
		mov	ecx, WINDOWHEIGHT
		
		mov 	esi, MASKSTARTUP

		loopYgora:	

			push 	esi	; 0x696 leci na stos
			mov	eax, X
			lea 	eax, [eax +02*eax]  ; ustawiamy sie na dobra kolumne
			add	esi, eax

			mov	eax, [esi]
			mov	ebx, eax		; potem sobie wartosc bajtu z ebx bierzemy

			and	eax, 0x00FF0000 ; moze to i czerwony	
			shr	eax, 16
			add	SR, eax	

			mov	eax, ebx
			and	eax, 0x0000FF00
			shr	eax, 8
			add	SG, eax

			mov	eax, ebx
			and	eax, 0x000000FF
			add	SB, eax

			pop 	esi
			sub	esi, ROW

			cmp	esi, IN
			cmovl	esi, IN
		loop loopYgora	
		
		pop ecx	
	ret

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
	sub	esp, 100	; miejsce na locale
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

	; init ZERO
	mov ZERO, dword 0x0

	;init HYPHEN 
hyphen:
	mov	eax, W 		; eax = w
	shl	eax, 1
	inc	eax		; eax = w + 1
	mov	edx, H		; edx = H
	shl	edx, 1
	inc	edx		; edx = h + 1
	mul	edx		; edx = mianownik
	mov	HYPHEN, eax	; zapisujemy sobie mianownik
	
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
	shl	eax, 4 		; na kazdy kolorek po 4 bajty, tzymamy RGB pusty RGB pusty
	push	eax

	; Malloc wpisuje adres do eax
	call	malloc
	mov	BUFF, eax
	pop	eax 
	add	eax, BUFF
	sub 	eax, 4
	mov	BUFFEND, eax	; buffend pokazuje na ostatni

	; init IMGSIZE
	mov	eax, [ebp+12]	; width
	mov	edx, [ebp+16]	; height 
	mul	edx		; wynik  w eax
	mov	IMGSIZE, eax

	; init ROW
	mov 	eax, WIDTH
	mov 	edx, 0x3
	mul 	edx
	add 	eax, ALIGNJUNK
	mov 	ROW, eax


	; init src and dst
	mov	esi, [ebp+8]	; wejsciowy obrazek 
	mov	edi, [ebp+20]	; wyjsciowy obrazek

	; bedziemy filtrowac

	; najpierw wypelniamy cale buforki
	
	; esi na 0x696
	jmp debug
debug:
	mov 	esi, IN
	mov	eax, ROW
	mov	edx, H
	mul 	edx ; edx = row * h
	add	esi, eax ; esi ustawione
	mov	MASKSTARTUP, esi

	mov	ebx, BUFF
	mov	eax, W
	mov	X, eax ; X = W (zaczynamy od prawej strony maski)


	mov	BOFF, dword 0x0

	; init countera w poziomie
	mov	ecx, WINDOWWIDTH 
	Xloop:
		call Ygora
		mov 	edi, BUFFEND	; wypelniamy bufor od konca
		sub	edi, BOFF
		mov	eax, SR
		mov 	[edi-12], eax
	        mov	eax, SG	
	        mov	[edi-8], eax
		mov	eax, SB
		mov	[edi-4], eax
		add	BOFF, dword 16	; przestawiamy sie na nowe miejsce w buforku	trzymamy tak : RGB, puste, RGB, puste itp

		mov	edi, X
		dec	edi
		cmp	edi, 0
		cmovl	edi, ZERO
		mov	X, edi ; aktualizujemy X
	loop Xloop	

	; mamy z gory buforek wypelniony, czas najwyzszy cos podzielic i przepisac

	mov	esi, BUFF
	xor	eax, eax
	xor	edx, edx
	xor	ebx, ebx

	mov	ecx, WINDOWWIDTH
	loopSumR:
		add	eax, [esi]
		add	edx, [esi+4]
		add	ebx, [esi+8]
		add	esi, dword 0x10
	loop loopSumR	

	;; jest posumowane dzielic budziem

	shl	eax, 16
	;div	dword HYPHEN
	mov	eax, dword 0x19
	mov	edx, HYPHEN
        div 	dl	
	movzx	eax, al
	
	jmp	endlabel






endlabel:
	pop	ebx		; Epilog
	pop	esi
	pop	edi
	leave
	ret

