function read_vot, file, headtable, debug = debug, silent=silent;+; NOM:;	read_vot;;
;	PURPOSE
; Read VOtable using STILTS (under Unix at least)
;
; CALLING SEQUENCE:
;	result = read_vot(file, [headtable])
;
; INPUT PARAMETERS:
;	file: name and path of file to be read
;
; RESULT
;	structure containing the data table, according to VOTable
;
; OUTPUT PARAMETERS, optional:
;	headtable: original header of VOTable
;
; KEYWORDS
;	Silent 
;	Debug - whatever...
;
; PRECAUTIONS:
;   - Relies on STILTS library, which must be installed in the Unix path
;			set path = ($path /Applications/ApplisAstro/stilts)
;	- Writes a temporary file in /tmp, removes it when done
;
;
; MODIFICATION HISTORY:
;     S. Erard, LESIA, May 2015
;-
;******************************************************************************
if n_params() gt 2 or n_params() lt 1  then message,  'usage: result = read_vot(file, [headtable])'silent = keyword_set(silent)
;man_cmd = "stilts tpipe ifmt=votable in="+ file + "ofmt=fits-plus > /tmp/vvex.fits" 
; this preserves all info in the VOtable

; must remove file first - STILTS won't erase it 
a = (b = '')	; grab error message if no fits presentspawn, "rm /tmp/tmp.fits", a, b	
man_cmd = "stilts tcopy " +file+ " /tmp/tmp.fits ifmt=votable ofmt=fits-plus" 
spawn, man_cmd 

If keyword_set(debug) then print, man_cmd
If keyword_set(debug) then print, a, b
;wait , 10	; has to wait for stilts?

headtable = mrdfits('/tmp/tmp.fits', 0, header0, silent=silent)
headtable= string(headtable) 	; contains all description (= VOtable header)

; Then fits extension + a fits header 
t1=mrdfits('/tmp/tmp.fits', 1, header1, silent=silent)
	; t1 is a structure containing the table itself	- result

return, t1end