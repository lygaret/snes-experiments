.export reset_handler
.import main, __ZEROPAGE_RUN__

;; masking the low byte allows use of $000000-$00000F as local vars

ZEROPAGE_BASE = __ZEROPAGE_RUN__ & $FF00

;; make sure these conform to the linker script (linker.cfg)

STACK_BASE 	= $0100
STACK_SIZE 	= $0100
LAST_STACK_ADDR = STACK_BASE + STACK_SIZE - 1

;; MMIO is mirrored into $21xx, $42xx, and $43xx of all banks $00-$3F and $80-$BF
;; To make it work no matter the current data bank, we can use a long address in
;; a long address in a nonzeno bank.

PPU_BASE	= $2100
CPUIO_BASE	= $4200
	
;; Bit 4 of the byte at $FFD5 in the cartridge header specifies fastrom setting
;; Full 24-bit, since D is relocated during register initialization
	
MAP_MODE        = $00FFD5
MAP_MODE_FAST   = $10
	
.segment "CODE7"
.proc reset_handler
	
	;; this should set 16-bit mode, turn off decimal mode, set the stack pointer
	;; set the direct page base, and get the MMIO ports into a predictable state
	
	rep #$38		; a/x/y 16-bits, binary arithmitic
	
	ldx #LAST_STACK_ADDR
	txs			; set the stack pointer
	
	;; initialize cpu io registers
	;; repoint direct page so we can refer to registers as single bytes

	lda #CPUIO_BASE
	tad

	lda #$FF00
	sta $00			; disabled NMI and H/V IRQs, don't drive controller port pin 6
	stz $02			; clear multiplier factors
	stz $04			; clear dividend
	stz $06			; clear divisor and low byte of hcount
	stz $08			; clear high bit of hcount and low byte of vcount
	stz $0A			; clear high bit of vcount and disable DMA copy
	stz $0C			; disabled HDMA and fast ROM
	
	;; initialize ppu registers
	;; repoint direct page so we can refer to registers as single bytes
	
	lda #PPU_BASE
	tad			; repoint direct page
	
	;; first all word registers (16bit write)
	
	lda #$0080
	sta $00			; forced blank, brightness 0, sprite size 8/16 from VRAM $0000
	stz $02			; OAM address = 0
	stz $05			; BG mode 0, no mosaic
	stz $07     		; BG 1-2 map 32x32 from VRAM $0000
	stz $09     		; BG 3-4 map 32x32 from VRAM $0000
	stz $0B     		; BG tiles from $0000
	stz $16     		; VRAM address $0000
	stz $23     		; disable BG window
	stz $26     		; clear window 1 x range
	stz $28     		; clear window 2 x range
	stz $2A     		; clear window mask logic
	stz $2C     		; disable all layers on main and sub
	stz $2E     		; disable all layers on main and sub in window
	ldx #$0030
	stx $30     		; disable color math and mode 3/4/7 direct color
	ldy #$00E0
	sty $32     		; clear RGB components of COLDATA; disable interlace+pseudo hires
	
	;; then all byte registers (8bit write)
	
	sep #$20		; 8bit a
	sta $15			; still $80: add 1 to VRAM pointer after high byte write
	stz $1A			; enable mode 8 wrapping and disable flipping
	stz $21			; set CGRAM address to color 0
	stz $25			; disable obj and math window
	
	;; scroll registers $0D-$14 need double 8-bit writes
	
	.repeat 8, I
	  stz $0D+I
	  stz $0D+I
	.endrepeat
	
	;; as do the mode 7 registers, 
        ;; which we set to the identity matrix, and center = 0,0

	;; [ 1: $0100 2: $0000 ]
	;; [ 3: $0000 4: $0100 ]
	
	lda #$01
	stz $1B 		; 1
	sta $1B
	stz $1C			; 2
	stz $1C
	stz $1D			; 3
	stz $1D
	stz $1E			; 4
	sta $1E
	stz $1F			; center x
	stz $1F
	stz $20			; center y
	stz $20

	;; initialize fast rom 
        ;; only if the cartridge requests it

	lda f:MAP_MODE  	; get the value of the fastrom setting flag in header
	and #MAP_MODE_FAST 	; check if the fast bit is set
	beq not_fastrom		; if it's not, skip 
	  inc a			; a = 1 in this case (was zero after and)
not_fastrom:
	sta $80420D		; set the flag into MEMSEL, using bank $80 for fast access
	
	;; repoint direct page to reserved memory
	
	rep #$20		; 16bit a
	
	lda #ZEROPAGE_BASE
	tad
	
	;; main takes it from here
	
	jml main

.endproc
