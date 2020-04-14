.import main, reset_handler, nmi_handler, irq_handler
	
;; constants for flags we'll be setting
	
MAPPER_LOROM = $20
ROMSPEED_120NS = $10
REGION_AMERICA = $01
	
;; helpful memory size constants
;; ciel(log2(byte size)) - 10

MEMSIZE_NONE  = $00
MEMSIZE_2KB   = $01
MEMSIZE_4KB   = $02
MEMSIZE_8KB   = $03
MEMSIZE_16KB  = $04
MEMSIZE_32KB  = $05
MEMSIZE_64KB  = $06
MEMSIZE_128KB = $07
MEMSIZE_256KB = $08
MEMSIZE_512KB = $09
MEMSIZE_1MB   = $0A
MEMSIZE_2MB   = $0B
MEMSIZE_4MB   = $0C
MEMSIZE_8MB   = $0D
	
.segment "SNESHEADER"
	
	;; snes cart starts with a fixed format header
	;; the end of the header is a jump table for interrupt vectors

	.byte "  "		; publisher id, ascii
	.byte "XLRW"		; game registration code (as in SNS-xxxx-USA)
	.res 6, $00		; reserved
	.byte MEMSIZE_NONE	; backup flash size 
	.byte MEMSIZE_NONE 	; expansion work RAM size
	.byte 0			; related to promo versions
	.byte 0			; coprocessor subtype
	
	;; romname must be 21 characters, space padded
	;;     012345678901234567890
	.byte "ACCIDENTALLY SNES    "

	.byte MAPPER_LOROM | ROMSPEED_120NS
	.byte $00		; cart type - 00 no RAM
	.byte MEMSIZE_256KB	; ROM size
	.byte MEMSIZE_NONE 	; backup RAM size

	.byte REGION_AMERICA
	.byte $33		; publisher, or $33 to 'see 16 bytes pre-header'
	.byte $00		; revision number

	.word $0000		; sum of all bytes will be poked here after linking
	.word $0000		; $FFFF minus above will also be poked here
	
	;; vector table
	
	.res 4			; unused
	.addr cop_stub
	.addr brk_stub
	.addr abort_stub
	.addr nmi_stub
	.res  2	 		; unused, would be reset but we always boot in emulation
	.addr irq_stub
	.res  4			; unused
	.addr ecop_stub
	.res  2			; unused, would be brk, but brk = irq in emulation
	.addr eabort_stub
	.addr enmi_stub
	.addr reset_stub
	.addr eirq_stub
	

.segment "CODE"

	;; reset leaves emulation mode and long jump to the rest of the
	;; initialization code in another bank, for fastrom purposes
	
reset_stub:
	sei 			; turn off interrupts
	clc
	xce                     ; turn off emulation mode
	cld
        jml reset_handler
        
        ;; interrupt stubs
        ;; stubs are generally just a jml to a handler linked somewhere in fast rom

irq_stub:
        jml irq_handler
        
nmi_stub:
        jml nmi_handler

        
        ;; unused exception handers
        
cop_stub:       
brk_stub:       
abort_stub:     
ecop_stub:      
eabort_stub:    
enmi_stub:      
eirq_stub:      
        rti
