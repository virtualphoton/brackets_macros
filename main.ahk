#NoEnv
#SingleInstance Force
SendMode Input
SetWorkingDir %A_ScriptDir%

#include scripts/hotkeys_creator.ahk

brackets_start := {0:0						; for the sake of all keys being aligned
	,"(": 	["(", ")"]
	,"|": 	["|", "|"]
	,"{": 	["{{}", "{}}", {"ru_char":"Х", "offset":-1}]
	,"[": 	["[", "]", {"ru_char":"х"}]
	,"""":	["""", """", {"ru_char":"Э"}]
	,"'": 	["'", "'", {"ru_char":"э"}]
	,"$":	["$", "$"]
	,"^\":	["\(", "\)", {"offset":-2}]
	,"^[":	["\{{}", "\{}}", {"offset":-2}] }
	
brackets_end := {0:0
	,")": 	["(", ")"]
	,"}": 	["{{}", "{}}", {"ru_char":"Ъ"}]
	,"]": 	["[", "]", {"ru_char":"ъ"}] }
	
shortcuts := {0:0
	,"!b":"\bigcup"
	,"!n":"\varnothing"
	,"!e":"\varepsilon"
	,"!r":"\Rightarrow"
	,"!d":"\delta"
	,"^8":"{^}*" }



; analog of `if __name__ == "__main__"` (starts only when code is not imported)
if regexMatch(A_ScriptFullPath, ".*main\.ahk$"){
	create_wrappers(brackets_start)
	create_ends(brackets_end)
	create_shortcuts(shortcuts)
	Run, auxiliary.ahk
}