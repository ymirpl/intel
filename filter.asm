

; zmienne lokalne f-cji glownej


%define IMGSIZE			[ebp-4]
%define ZERO			[ebp-16]

%define X			[ebp-20]
%define ALIGNJUNK		[ebp-24]
%define XMASK			[ebp-28]
%define HYPHEN			[ebp-52]

%define LROWB			[ebp-56] ; lewy brzeg wiersza
%define RROWB			[ebp-60] ; prawy brzeg wiersza
%define ULIMIT			[ebp-64] ; gorny brzeg obrazka
%define DLIMIT			[ebp-68] ; dolny brzeg obrazka


;%define LVR			[ebp-72] ; lewy wartosc
;%define LVB			[ebp-73]
;%define LVG			[ebp-74]

%define YMASK			[ebp-76] ; prawy 
;%define RVG			[ebp-77]
;%define RVB			[ebp-78]

%define UVR			[ebp-80] ; gorny
%define UVB			[ebp-81]
%define UVG			[ebp-82]

%define Y			[ebp-84] ; dolny
;%define DVG			[ebp-85]
;%define DVB			[ebp-86]

%define MASKSTART		[ebp-88]
%define BOFF			[ebp-92]


%define WINDOWWIDTH		[ebp-32]
%define WINDOWHEIGHT		[ebp-36]
%define ROW			[ebp-96]

%define SUMBFFR			[ebp-40]
%define SUMBFFG			[ebp-44]
%define SUMBFFB			[ebp-48]

%define WIDTH			[ebp+12]
%define HEIGHT			[ebp+16]
%define W			[ebp+24]
%define H			[ebp+28]



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
	; bedziemy liczyc mianownik
hyphen:
	mov	eax, W 		; eax = w
	inc	eax		; eax = w + 1
	mov	edx, H		; edx = H
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
	shl	eax, 2
	push	eax

			; Malloc wpisuje adres do eax
	call	malloc
	mov	SUMBFFR, eax
	call 	malloc
	mov	SUMBFFG, eax
	call	malloc
	mov	SUMBFFB, eax
	add	esp, 4		; usun eax ze stosu

	; init IMGSIZE
	mov	eax, [ebp+12]	; width
	mov	edx, [ebp+16]	; height 
	mul	edx		; wynik  w eax
	mov	IMGSIZE, eax

	; init ROW
	mov eax, WIDTH
	mov edx, 0x3
	mul edx
	add eax, ALIGNJUNK
	mov ROW, eax


	; init src and dst
	mov	esi, [ebp+8]	; wejsciowy obrazek 
	mov	edi, [ebp+20]	; wyjsciowy obrazek

	; bedziemy filtrowac

	; najpierw wypelniamy cale buforki

	; init ecx

	mov	eax, ROW 
	mov	edx, WINDOWHEIGHT
	mul	edx
	mov	YMASK, eax	; dotad sie dobrze liczy
	mov	XMASK, dword 0x0
	mov	X, dword 0x0
	mov	eax, HEIGHT
	mov	Y, eax  

	
		; DEBUG


	; init LROWB i RROWB ULIMIT i DLIMIT


	mov	LROWB, esi
	mov	ebx, WIDTH
	lea	eax, [02*ebx]
	add	eax, ebx
	add	eax, esi
	mov	RROWB, eax	
	mov	eax, esi
	mov	ULIMIT, eax

	mov	eax, ALIGNJUNK
	mov	ecx, WIDTH
	lea	eax, [eax + 02*ecx]
	add	eax, ecx
	mov	edx, HEIGHT
	mul	edx
	mov	ecx, esi
	add	ecx, eax
	
	;add	eax, IMGSIZE
	mov	DLIMIT, ecx


	jmp debug
debug:	
	mov eax, esi
	movzx edx, byte [eax]
	mov UVB, edx
	movzx edx, byte [eax+1]
	mov UVG, edx
	movzx edx, byte [eax+2]
	mov UVR, edx
	
;	mov edx, WIDTH
;	mov ebx, ALIGNJUNK
;	lea eax, [ebx+ 02*edx]
;	add eax, edx
;	mov ecx, DLIMIT
;	sub ecx, eax
;	mov edx, [ecx]
;	mov DVB, edx
;	mov edx, [ecx+1]
;	mov DVG, edx
;	mov edx, [ecx+2]
;	mov DVR, edx

;	mov eax, LROWB
;	mov edx, [eax]
;	mov LVB, edx
;	mov edx, [eax+1]
;	mov LVG, edx
;	mov edx, [eax+2]
;	mov LVR, edx

;	mov eax, RROWB
;	mov edx, [eax-1]
;	mov RVR, edx
;	mov edx, [eax-2]
;	mov RVG, edx
;	mov edx, [eax-3]
;	mov RVB, edx



	; wiadomo jak wyglada start, 3/4 maski jest poza obrazkiem
	; do initu buforkow mozna te wiedze wykorzystac i nie patrzec czy wychodzi poza, bo wychodzi.


	mov BOFF, dword 0x0
	mov ecx, W
	; obieg tego prostokata co jest na lewo poza calkiem, 
	
	mov eax, WINDOWHEIGHT
	push eax

outside_rectangles:
	mov eax, [esp]	
	mov ebx, UVR
	mul ebx

	mov ebx, SUMBFFR
	add ebx, BOFF
	mov [ebx], eax


	mov eax, [esp]
	mov ebx, UVG
	mul ebx

	mov ebx, SUMBFFG
	add ebx, BOFF 
	mov [ebx], eax
	

	mov eax, [esp]
	mov ebx, UVB
	mul ebx

	mov ebx, SUMBFFB
	add ebx, BOFF
	mov [ebx], eax

	add BOFF, byte 0x4
	loop outside_rectangles
	pop eax 	; tylko w celu wyczyszczenia stotsu

	

loopX:
	;movs	LV, LROWB 	; init wartosci brzegowych
	;movs	RV, RROWB		 
	;cmp
	
	
	loopY:
	;	lea eax, [esi + ecx]	
	;	cmp eax, ULIMIT 
	
	;push	dword [esi]	; tu jest to co wstawimy, jak wyjdziemy za zakres z lewej albo z gory
	;	movzx	eax, byte [esi+ecx]


	pop	ebx		; Epilog
	pop	esi
	pop	edi
	leave
	ret

