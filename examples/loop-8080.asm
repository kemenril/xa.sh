;; 
;; A simple loop from 1 to 5
;;  in 8080 assembly
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	ORG	0100H
	MVI	A, 1
LOOP:	INR	A
	CPI	5
	JNZ	LOOP

