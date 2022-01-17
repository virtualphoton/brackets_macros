#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance Force
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

CLIPBOARD_TIMEOUT = 0.05
RU_LANG_CODE := 0x4190419

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
git
wrap_selected_text(before, after, offset:=-100, length:=-1) {
	if (offset == -100)
		offset := -StrLen(after)
	if (length == -1)
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
		SendInput +{Left %length%}		; select text again
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

$(::
	wrap_selected_text("(", ")")
	return

$|::
	wrap_selected_text("|", "|")
	return

${::
	if layout_is_good()
		wrap_selected_text("{{}", "{}}", -1)		; escaping '{' and '}'
	else
		Send Х
	return
	
$[::
	if layout_is_good()
		wrap_selected_text("[", "]")
	else
		Send х
	return
	
$"::
	if layout_is_good()
		wrap_selected_text("""", """")
	else
		Send Э
	return	
$'::
	if layout_is_good()
		wrap_selected_text("'", "'")
	else
		Send э
	return

$)::
	global print_mutex
	
	print_mutex.lock()
	insert_end_bracket("(", ")") 
	print_mutex.unlock()
	return
	
$]::
	if layout_is_good()
		insert_end_bracket("[", "]") 
	else
		Send ъ
	return 
	
$}::
	if layout_is_good()
		insert_end_bracket("{", "}")
	else
		Send Ъ
	return

; Anki
^\::
	wrap_selected_text("\(", "\)")
	return

:*:\rar::\Rightarrow
::\v::\vec
^[::
	wrap_selected_text("\{{}", "\{}}", -2)
	return

Alt & b::
	Send \bigcup
	return
	
Alt & n::
	Send \varnothing
	return
	
Alt & l::
	Send \limits_{{}{}}
	Send {Left}
	return
	
Alt & e::
	Send \varepsilon
	return

^8::
	Send {^}*
	return
Alt & u::
	wrap_selected_text("\underset{{}\mbox{{}{}}{}}{{}", "{}}", -1)
	return
Alt & r::
	Send \Rightarrow
	return 
Alt & d::
	Send \delta
	return
^J::
	out := ""
	Input out, L2 V,"j ",k
	MsgBox %out%
	return 