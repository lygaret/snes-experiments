.export main, nmi_handler, irq_handler

.segment "CODE"
.proc nmi_handler

	;; minimalist nmi handler
	;; TODO: literally anything

	rti

.endproc	

.proc irq_handler

	;; minimalist irq handler
	;; TODO: literally anything
	
	rti

.endproc
	
.segment "CODE1"
.proc main
	
	;; main entry point
	;; reset_handler sends us here, after getting the hardware into a sane state
	
	sep #$20 		; a8
	
	stz 	$2121		; edit color 0, which is default
	lda     #%00011111	; set color 0 with red
	sta 	$2122
	stz 	$2122
	
	lda 	#%00001111	; full bright, screen on
	sta 	$2100

forever:
	jmp forever

.endproc
