#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
#Warn LocalSameAsGlobal, Off
#SingleInstance Force
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

move_cursor(n) {
	if (n < 0) {
		n := -n
		Send {Left %n%}
	} else
		Send {Right %n%}
}

print_and_move(str, n) {
	Send %str%
	move_cursor(n)
}

get_selection() {
	ClipSaved := ClipboardAll 			; save clipboard
	clipboard := ""
	ret := ""
	Send ^c
	clipwait 0.1
	if not errorlevel
		ret := clipboard
	ClipSaved := ""
	clipboard := ClipSaved
	return ret
}

wrap_selected_text(before, after, offset:=-100, length:=-1) {
	if (offset == -100)
		offset := -StrLen(after)
	if (length == -1)
		length := StrLen(get_selection())
	if (not length){
		Send %before%%after%
		move_cursor(offset)
	} else {
		Send {Left}
		Send %before%
		move_cursor(length)
		Send %after%
		move_cursor(offset)
		Send +{Left %length%}		; select text again
	}
	return length
}

end_is_present(bra, ket){
	space := " "
	Send %space%
	move_cursor(1)
	Send +{Home}
	str := get_selection()
	Send {Right}
	
	length := StrLen(str)
	txt_arr := StrSplit(str)
	
	if (txt_arr[length] == space){
		Send {Backspace}
		return false
	}
	Send {Left}{Backspace}
	if (txt_arr[length] != ket)
		return false
	
	counter := 0
	Loop % length{
		if (txt_arr[length - A_index - 1] == ket)
			counter += 1
		else if (txt_arr[length - A_index - 1] == bra)
			counter -= 1
		; Send %counter%		; debug
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
		Send %ket%
	}	
}

^\::
	wrap_selected_text("\(", "\)")
	return

$(::
	wrap_selected_text("(", ")")
	return

${::
	wrap_selected_text("{{}", "{}}", -1)		; escaping '{' and '}'
	return
	
$[::
	wrap_selected_text("[", "]")
	return
	
$"::
	wrap_selected_text("""", """")
	return

$)::
	insert_end_bracket("(", ")") 
	return
:*:]::
	insert_end_bracket("[", "]") 
	return 
:*:}::
	insert_end_bracket("{", "}") 
	return