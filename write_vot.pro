pro write_vot, file, data, headcol, headtable, TNAME= Tname, PARAM =param, debug = debug, silent=silent;+; NOM:;	write_vot;;
;	PURPOSE
; Writes a minimal VOtable using STILTS (under Unix at least)
;
; CALLING SEQUENCE:
;	write_vot, file, data, [header], [headtable], [param=Param], [Tname=Tname]
;
; INPUT PARAMETERS:
;	File: name of file to be written, extension should be .vot or .xml
;		If file already exists, a message is issued
;	Data: Array containing the data table
;	headcol: column header / description
;	headtable: should be table header, not supported
;
;
; KEYWORDS
;	Silent 
;	Debug: messages on
;	param: Writes one parameter, expects an array of structures with definition:
;		  {Name:'Toto', unit:'"h"', ucd:'"meta.id"', desc:'"bloblo"', value:'"valeur"'}
;	TName: table name, optional (filename if absent)
;
; PRECAUTIONS:
;   - Relies on STILTS library, which must be installed in the Unix path
;			set path = ($path /Applications/ApplisAstro/stilts)
;	- Writes a temporary file in /tmp, removes it when done
;	- Does not describe FIELDs in details (only datatype and name)
;
; EXAMPLEQ
;  basic:
;	vartot = fltarr(6, 14)	
;	var2= ['coucou', 'coucou2'];	WRITE_vot,  'tutu3.vot', vartot ,var2, Tname='TableName'
;
; To add PARAM in the votable (beware of quotes)
;	param= replicate({Name:'Toto', unit:'"h"', ucd:'"meta.id"', desc:'"bloblo"', value:'"valeur"'},3)
;	param(1).name= 'Tata';	param(2).name= 'Tutu';	param(1).unit=  '"km"';	param(2).unit=  '"au"';	param(1).ucd=  '"meta.class"';	param(2).ucd=  '"meta.truc"';	param(1).value=  '3.';	param(2).value=  '9.';	param(1).desc= '"blabla1"';	param(2).desc= '""'
;	WRITE_vot,  'tutu5.vot', vartot ,var1, param= param
;
; MODIFICATION HISTORY:
;     S. Erard, LESIA, May 2015
;     S. Erard, LESIA, Sept 2015: added Param & Table name, optional - seems OK
;-
;******************************************************************************
if n_params() gt 4 or n_params() lt 2  then message,  'usage: write_vot= file, data, headcol)'silent = keyword_set(silent)

; must remove file first - STILTS won't erase it 
a = (b = '')	; grab error message if no file presentspawn, "rm /tmp/tmp.csv", a, b	

;If N_elements(headertable) EQ 0 then WRITE_CSV,  '/tmp/tmp.csv', data, HEADER=headcol else $
;	 WRITE_CSV,  '/tmp/tmp.csv', data, HEADER=headcol, table_header = headtable

; Column headers handled by stilts (includes FIELD definitions), not Table header
 WRITE_CSV,  '/tmp/tmp.csv', data, HEADER=headcol 
;print, headcol, headtable
;print, N_elements(headertable)


; Changes table name / type first
If Keyword_set(Tname) EQ 0 then Tname= file
sz = size(param, /dim)
cmd = ' '

; Then convert to VOtable with STILTS + PARAMs if any
If Keyword_set(param) EQ 0 then begin
  man_cmd = "stilts tpipe in=/tmp/tmp.csv ifmt=csv cmd='tablename "+Tname + "' omode=out ofmt=votable > " +file
endif else begin
  man_cmd = "stilts tpipe ifmt=csv in=/tmp/tmp.csv cmd='tablename "+Tname +string(39b) 
  for ii = 0, sz(0)-1 do begin
    cmd =  string(format="('setparam -desc ', A, ' -unit ',A,' -ucd ',A,' ',A,' ',A)", $
  	  param(ii).desc, param(ii).unit,param(ii).ucd, param(ii).name,param(ii).value)
    man_cmd = man_cmd + " cmd=" +string(39b)+cmd+string(39b) 
  endfor  man_cmd = man_cmd + " ofmt=votable > "+file
;  man_cmd = "stilts tpipe ifmt=csv in=/tmp/tmp.csv cmd='tablename "+Tname + "' cmd=" +string(39b)+cmd+string(39b) +" ofmt=votable > "+file
endelse

spawn, man_cmd, a1, b1

temp = strsplit(b1, 'exists', /reg, count=cc)
if cc(0) EQ 2 then message, 'File exists, not written', /cont

If keyword_set(debug) then print, a, b
If keyword_set(debug) then print, man_cmd
If keyword_set(debug) then print, a1, b1
;If keyword_set(debug) then print, sz
end