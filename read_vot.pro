function read_vot, file, headtable, PARAM =param, header_fits= header1, debug = debug

;+
; NOM:
;	read_vot
;
;
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
;	structure containing the data table, according to VOTable definition
;
; OUTPUT PARAMETERS, optional:
;	headtable: ~original header of VOTable (+ Resource element with dummy Data element)
;
; KEYWORDS
;	PARAM: in output, contains param definitions in an array of structures
;		param= replicate({Name:'Toto', unit:'""', ucd:'""', desc:'""', value:'""'},Nb)
;	HEADER_FITS: outputs fits header containing a description of fields
;	Debug - print messages
;
; EXAMPLE
;	qd=read_vot('test.xml', head) 
;	print, qd(0).session  ; scalar: elt 0 of column session
;	
;
; PRECAUTIONS:
;   - Relies on STILTS library, which must be installed in the Unix path
;			set path = ($path /Applications/ApplisAstro/stilts)
;	- Writes a temporary file in /tmp, removes it when done
;
;
; COMMENT
;
; ** To edit a VOTable: 
; 	read VOTable
;qd=read_vot('TitanV2.retour2.xml', head) 
;	 Read intermediate fits
;headtable = mrdfits('/tmp/tmp.fits', 0, header0, silent=silent)
;headtable= string(headtable) 
;t1=mrdfits('/tmp/tmp.fits', 1, header1, silent=silent)
; 	modify headtable / t1 / header1
;t1(10).target_name= 'Jupiter'	
; (should also modify arraysize of target_name in headtable)
; 	then write new fits-plus
;mwrfits, headtable, 'tmp.fits', header0, /create
;mwrfits, t1, 'tmp.fits', header1 
;	 convert back to VOtable
;man_cmd = "stilts tcopy  tmp.fits bid2.vot ofmt=votable ifmt=fits-plus" 
;spawn, man_cmd 
;
;
; MODIFICATION HISTORY:
;     S. Erard, LESIA, May 2015
;     S. Erard, LESIA, March 2016: parse parameters and pass them in output; 
;								   also pass the intermediate fits header
;-
;******************************************************************************


on_error, 2
if n_params() gt 2 or n_params() lt 1  then message,  'usage: result = read_vot(file, [headtable])'
silent = ~keyword_set(debug)

;man_cmd = "stilts tpipe ifmt=votable in="+ file + "ofmt=fits-plus > /tmp/vvex.fits" 
; this preserves all info in the VOtable


;temp = file_search(file)	; does not work with Mac escape \
temp = file_search(strjoin(strsplit(file, '\', /ext)))
If ~temp then message, 'File not found'
;spawn, "ls " + file, rep, rep2  
;If ~temp then message, 'File not found'


; must remove file first - STILTS won't erase it 
a = (b = '')	; grab error message if no fits present
spawn, "rm /tmp/tmp.fits", a, b	
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

; parsing the PARAM definition, first step
;If ~keyword_set(Param) then goto, endpar	; no simple way to do this & won't gain significantly
tab = ' '
param = -1
indf= '<'+strsplit(headtable, '<', /ex)	
for i=0,n_elements(indf)-1 do if StRegEx(strlowcase(indf(i)),'<param') NE -1 and StRegEx(strlowcase(indf(i)),'/>') NE -1 then tab = [tab, indf(i)]
ind2 = 0 & ind3 = 0
for i=0,n_elements(indf)-1 do if StRegEx(strlowcase(indf(i)),'<param') NE -1 and StRegEx(strlowcase(indf(i)),'/>') EQ -1 then ind2 = [ind2, i]
for i=0,n_elements(indf)-1 do if StRegEx(strlowcase(indf(i)),'/param>') NE -1 then ind3 = [ind3, i]
if size(ind2, /dim) NE 1 then $
for ii = 1, N_elements(ind3) -1 do tab = [tab, strjoin(indf(ind2(ii):ind3(ii)), /sin)]
If size(tab, /dim) EQ 0 then goto, endpar
If size(tab, /dim) NE 1 then tab = tab[1:*]

; parse tab for name, unit, ucd, description, value
Nparam = N_elements(tab)
If Nparam NE 0 then begin
	param= replicate({Name:'Toto', unit:'""', ucd:'""', desc:'"desc"', value:'""'},Nparam)
for ii = 0, Nparam -1 do begin
 tsplit = strsplit(tab[ii], '"', /ext)
 bid = where(StRegEx(strlowcase(tsplit),'name') NE -1)
 param[ii].Name = tsplit[bid[0]+1]
 bid = where(StRegEx(strlowcase(tsplit),'unit') NE -1)
 If bid[0] NE -1 then param[ii].unit = '"'+tsplit[bid[0]+1]+'"'
 bid = where(StRegEx(strlowcase(tsplit),'ucd') NE -1)
 If bid[0] NE -1 then param[ii].ucd = '"'+tsplit[bid[0]+1]+'"'
 bid = where(StRegEx(strlowcase(tsplit),'value') NE -1)
 If bid[0] NE -1 then param[ii].value = '"'+tsplit[bid[0]+1]+'"'
 bid = where(StRegEx(strlowcase(tsplit),'description') NE -1)	; this one is different
; If bid[0] NE -1 then param[ii].desc = tsplit[bid+1]

 If bid[0] EQ -1 then continue
  bid2 = strsplit(tsplit[bid], '><', /ext)
  bid3 = where(StRegEx(strlowcase(bid2),'description') NE -1)
  If bid3[0] NE -1 then param[ii].desc = '"'+bid2[bid3[0]+1]+'"'
endfor
endif


endpar:
return, t1
end
