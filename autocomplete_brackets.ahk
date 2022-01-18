#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance Force
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#Warn

CLIPBOARD_TIMEOUT := 0.05
RU_LANG_CODE := 0x4190419
turned_off_ids := {}

msg(args*){
	str := ""
	for _, arg in args
        str .= arg . " "
	MsgBox %str%
}

class Timer {
	__New(){
		this.last_time := A_TickCount
	}
	tick(){
		this.last_time := A_TickCount
	}
	show_time(){
		dt := A_TickCount - this.last_time
		MsgBox %dt%
		this.tick()
	}
}

move_cursor(n) {
	if (n < 0) {
		n := -n
		SendInput {Left %n%}
	} else
		SendInput {Right %n%}
}

get_selection(cut:=false) {
	ClipSaved := ClipboardAll 			; save clipboard
	clipboard := ""
	ret := ""
	if (cut)
		SendInput ^x
	else
		SendInput ^c
	global CLIPBOARD_TIMEOUT
	clipwait CLIPBOARD_TIMEOUT
	if not errorlevel
		ret := clipboard
	clipboard := ClipSaved
	ClipSaved := ""
	return ret
}

select(dir, length){
	SendInput +{%dir% %length%}
}
get(dict, item, default) {
	return
}

__get(this, key, default:=""){
			if this.haskey(key)
				return this[key]
			return default
}
KwargsObj(kwargs_obj){
	if (kwargs_obj == 0)
		kwargs_obj := {}
	if (kwargs_obj.__class != "kwarg_obj"){
		kwargs_obj.get := Func("__get")
		kwargs_obj.__class := "kwarg_obj"
	}
	return kwargs_obj
}

wrap_selected_text(before, after, kwargs:=0) {
	kwargs := KwargsObj(kwargs)
	offset := kwargs.get("offset", -StrLen(after))
	length := StrLen(StrReplace(get_selection(), "`r"))
	if (not length){
		SendInput %before%%after%
		move_cursor(offset)
	} else {
		SendInput {Left}
		SendInput %before%
		move_cursor(length)
		SendInput %after%
		move_cursor(offset)
		select("left", length)		; select text again
	}
	return length
}

end_is_present(bra, ket){
	space := "᠎"				; zero width space
	;space := " "
	SendInput %space%
	SendInput {Right}
	SendInput +{Left}+{Home}			; because just SendInputing +{Home} bugs at the end of the line
	str := get_selection()
	SendInput {Right}
	
	length := StrLen(str)
	txt_arr := StrSplit(str)
	
	if (txt_arr[length] == space){
		SendInput {Backspace}
		return false
	}
	SendInput {Left}
	SendInput {Backspace}
	if (txt_arr[length] != ket)
		return false
	counter := 0
	Loop % length{
		if (txt_arr[length - A_index - 1] == ket)
			counter += 1
		else if (txt_arr[length - A_index - 1] == bra)
			counter -= 1
		; SendInput %counter%		; debug
		if (counter < 0)
			return true
	}
	return false
}

insert_end_bracket(bra, ket){
	if end_is_present(bra, ket)
		move_cursor(1)
	else {
		if (ket == "}")
			ket := "{}}"
		SendInput %ket%
	}	
}

layout_is_good() {
	; check if layout is not russian, because [, ], {, } and " are assigned to different characters there
	global RU_LANG_CODE
	ControlGetFocus Focused, A
	ControlGet CtrlID, Hwnd,, % Focused, A
	ThreadID := DllCall("GetWindowThreadProcessId", "Ptr", CtrlID, "Ptr", 0)
	InputLocaleID := DllCall("GetKeyboardLayout", "UInt", ThreadID, "Ptr")
	return InputLocaleID != RU_LANG_CODE 
}

wait_for_backspace(was_wrapped){
	if (was_wrapped)
		; TODO make ctrl+Z if `was_wrapped`, because text editors handle it incorrectly
		return
	xpos := 0, ypos := 0, xpos1 := 0, ypos1 := 0
	MouseGetPos xpos,ypos
	
	out := ""
	Input out, L1 V, {LControl}{RControl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}{AppsKey}{F1}{F2}{F3}{F4}{F5}{F6}{F7}{F8}{F9}{F10}{F11}{F12}{Left}{Right}{Up}{Down}{Home}{End}{PgUp}{PgDn}{Del}{Ins}{BS}{CapsLock}{NumLock}{PrintScreen}{Pause},
	
	MouseGetPos xpos1,ypos1
	; if user has moved mouse, then they supposedly don't want to erase brackets
	if (xpos != xpos1 or ypos != ypos1)
		return
	
	if (ErrorLevel == "EndKey:Backspace")
		SendInput {Delete}
	return
}
get_active_id(){
	winid := 0
	WinGet, winid ,, A
	return winid
}
change_window_status(){
	global turned_off_ids
	msg(turned_off_ids.HasKey(0))
	winid := get_active_id()
	if turned_off_ids.haskey(winid)
		turned_off_ids.delete(winid)
	else
		turned_off_ids[winid] := 0
	for key, value in turned_off_ids
	 	msg(key)
	return
}
brackets_allowed(){
	global turned_off_ids
	return not turned_off_ids.haskey(get_active_id())
}
_wrap(bra, ket, kwargs:=0){
	kwargs := KwargsObj(kwargs)
	ru_char := kwargs.get("ru_char", "")
	if (ru_char == "" or layout_is_good()){
		has_wrapped_sth := wrap_selected_text(bra, ket, kwargs)
		wait_for_backspace(has_wrapped_sth)
	} else
		SendInput %ru_char%
}
delete_dollar(str){
	if (SubStr(str, 1, 1) == "$")
		return SubStr(str, 2)		 ;omitting '$' sign
	return str
}
wrap(hotkey){
	global brackets_start
	key := delete_dollar(hotkey)
	_wrap(brackets_start[key]*)
	return
}

_end(bra, ket, kwargs:=0){
	kwargs := KwargsObj(kwargs)
	ru_char := kwargs.get("ru_char", "")
	if (ru_char == "" or layout_is_good())
		insert_end_bracket(bra, ket)
	else
		SendInput %ru_char%
}
end(hotkey){
	global brackets_end
	key := delete_dollar(hotkey)
	_end(brackets_end[key]*)
	return
}

brackets_start := {0:0						; for the sake of all keys being aligned
	,"(": 	["(", ")"]
	,"|": 	["|", "|"]
	,"{": 	["{{}", "{}}", {"ru_char":"Х", "offset":-1}]
	,"[": 	["[", "]", {"ru_char":"х"}]
	,"""":	["""", """", {"ru_char":"Э"}]
	,"'": 	["'", "'", {"ru_char":"э"}]
	,"^\":	["\(", "\)", {"offset":-2}]
	,"^[":	["\{{}", "\{}}", {"offset":-2}]}
brackets_end := {0:0
	,")": 	["(", ")"]
	,"}": 	["{{}", "{}}", {"ru_char":"Ъ"}]
	,"]": 	["[", "]", {"ru_char":"ъ"}]}

shortcuts := {0:0
	,"!b":"\bigcup"
	,"!n":"\varnothing"
	,"!e":"\varepsilon"
	,"!r":"\Rightarrow"
	,"!d":"\delta"
	,"^8":"{^}*"}

$(::
$|::
${::
$[::
$"::
$'::
^\::
^[::
	wrap(A_ThisHotkey)
	return

$)::
$]::
$}::
	end(A_ThisHotKey)
	return

; Shortcuts for anki
!b::
!n::
!e::
!r::
!d::
^8::
	SendInput .shortcuts[A_ThisHotkey]
	return
	
Alt & l::
	Send \limits_{{}{}}
	Send {Left}
	return
	


Alt & u::
	wrap_selected_text("\underset{{}\mbox{{}{}}{}}{{}", "{}}", -1)
	return

^J::
	Suspend
	return