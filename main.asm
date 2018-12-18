; ______________________________________________________________________________________________________________________
; Mikrokontroller alapú rendszerek házi feladat
; Készítette: Kisteleki Gergely
; Neptun code: DHE9EJ
; Feladat leírása:
;		Regiszterekben található 4 digites BCD kódú szám átalakítása bináris számmá.
;
;		Belépéskor az első regiszter tartalmazza a nagyobb helyiértékű két digitet, a másik regiszter a kisebb helyiértékű 2 digitet.
;		Az eredmény 16 bites bináris szám 2 regiszterben.
;
;		Bemenet: átalakítandó BCD szám.
;		Kimenet: átalakított bináris szám.
; ______________________________________________________________________________________________________________________

$NOMOD51 						; a sztenderd 8051 regiszter definíciók nem szükségesek
$INCLUDE (SI_EFM8BB3_Defs.inc)	; regiszter és SFR definíciók

; Ugrótábla létrehozása
	CSEG AT 0
	SJMP Main

myprog SEGMENT CODE				;saját kódszegmens létrehozása
RSEG myprog 					;saját kódszegmens kiválasztása

; ----------------------------------------------------------------------
; Főprogram
; ----------------------------------------------------------------------
; Feladata: a szükséges inicializációs lépések elvégzése és a
;			feladatot megvalósító szubrutin meghívása
; ----------------------------------------------------------------------
Main:
	CLR IE_EA 					; interruptok tiltása watchdog tiltás idejére
	MOV WDTCN,#0DEh 			; watchdog timer tiltása
	MOV WDTCN,#0ADh
	SETB IE_EA 					; interruptok engedélyezése

; bemeneti paraméterek előkészítése a szubrutin híváshoz:
	MOV R0, #136					;
	MOV R1, #136

	CALL BCDtoBINARY	 		; Átalakítás elvégzése
	JMP $						; végtelen ciklusban várunk

; -----------------------------------------------------------------------
; BCDtoBINARY szubrutin
; -----------------------------------------------------------------------
; Funkció: 		4 digites BCD szám binárissá konvertálása
; Bementek:		R0 - BCD szám két kisebb helyiértékű digitje
;			 	R1 - BCD szám két nagyobb helyiértékű digitje
; Kimenetek:  	R2 - bináris szám alsó bájtja
;				R3 - bináris szám felső bájtja
; Regisztereket módosítja:
;				A, PSW, R4, R5, R6
; -----------------------------------------------------------------------
BCDtoBINARY:
; ----- INPUT ALSÓ BÁJTJA > alsó 4 bit -----
	MOV A,R0
	ANL A,#0xF					; bejövő szám alsó bájtjának maszkolása - az alsó 4 bit szükséges
	MOV R2,A

; ----- INPUT ALSÓ BÁJTJA > felső 4 bit ----
	MOV A, R0
	ANL A,#0xF0					; bejövő szám alsó bájtjának maszkolása - a felső 4 bit szükséges

	MOV R6,#4					; 4-szer fut le a ciklus, mert 4-et léptetünk
	Loop:						; a kiválasztott 4 bitet az alsó 4 helyiértékre shifteljük
		RR A
		DJNZ R6,Loop

	MOV B,#10
	MUL AB						; az input alsó bájtjának felső 4 bitjét 10-zel szorozzuk
								;	az eredmény mindig kisebb 256-nál, így annak tárolásához elegendő az akkumulátor
	ADD A,R2					; a szorzathoz hozzáadjuk az input ajsó bájtjának alsó 4 bitjét
								; 	ez az első összeadás a programba, így nem kell ADDC-t használni
	MOV R2,A					; az így keletkezett 1. részeredményt az R2-ben tároljuk

; ---- INPUT FELSŐ BÁJTJA > alsó 4 bit -----
	MOV A,R1
	ANL A,#0xF					; az input felső bájtjának maszkolása - az alsó 4 bit szükséges

	MOV B,#100
	PUSH PSW					; PSW-t kimentjük a stackbe, mert a MUL törli a carryt, és a továbbiakban még szükség lesz rá
	MUL AB						; az input felső bájtjának alsó 4 bitjét 100-zal szorozzuk
								;	 a szorzás eredményének alső bájtja az A-ban, felső bájtja B-ben keletkezik
	POP PSW						; a carry visszaírása

	ADDC A,R2					; a szorzathoz hozzáadjuk az 1. részeredményt, és ezzel megkapjuk a 2. részeredményt

	MOV R2,A					; a 2. részeredmény alsó bájtját R2-ben tároljuk
	MOV R3,B					; a 2. részeredmény felső bájtját R3-ben tároljuk

; ---- INPUT FELSŐ BÁJTJA > felső 4 bit ----
	MOV A,R1
	ANL A,#0xF0					; az input felső bájtjának maszkolása - a felső 4 bit szükséges

	MOV R6,#4					; 4-szer fut le a ciklus, mert 4-et léptetünk
	Loop_two:					; a kiválasztott 4 bitet az alsó 4 helyiértékre shifteljük
		RR A
		DJNZ R6,Loop_two

	MOV B,#20
	PUSH PSW					; PSW-t kimentjük a stackbe, mert a MUL törli a carryt, és a továbbiakban még szükség lesz rá
	MUL AB						; az input felső bájtjának felső 4 bitjét először 20-szal szorozzuk
								; 	az eredmény mindig kisebb 256-nál, így annak tárolásához elegendő az akkumulátor
	MOV B,#50
	MUL AB						; a kapott szorzatot 50-nel szorozzuk, így áll elő az 1000-es szorzás
	POP PSW						; a PSW visszaírása
	MOV R4,A					; a szorzás eredményének alsó bájtját az R4-ben,
	MOV R5,B					;  	felső bájtját az R5-ben tároljuk

	MOV A,R4
	ADDC A,R2					; a szorzás eredményének alsó bájtjához hozzáadjuk a 2. részeredmény alsó bájtját
	MOV R2,A					; az összeget az R2-be írjuk - ez a végeredmény alsó bájtja

	MOV A,R5
	ADDC A,R3					; a szorzás eredményének felső bájtjához hozzáadjuk a 2. részeredmény felső bájtját
	MOV R3,A					; az összeget az R3-be írjuk - ez a végeredmény felső bájtja

	RET

END
