# IDL_VOtable
VOtable reader and writer for IDL / GDL

Read and write VOtables using STILTS

- Relies on the STILTS library, which must be installed in the Unix path:
		set path = ($path /Applications/ApplisAstro/stilts)

- Writes a temporary file in /tmp, removes it when done

- Support for Windows (but java and stilts paths are hard written, TBC)