#include scripts/constants.ahk

move_cursor(n) {
	; move cursor n characters to the right
	if (n < 0) {
		n := -n
		SendInput {Left %n%}
	} else
		SendInput {Right %n%}
}

get_selection() {
	; returns selected text. If none is selected, returns empty string
	; when none is selected, it will wait for CLIPBOARD_TIMEOUT_SEC seconds
	
	clip_saved := ClipboardAll 			; save clipboard
	clipboard := ""
	ret := ""
	SendInput ^c
	global CLIPBOARD_TIMEOUT_SEC
	clipwait CLIPBOARD_TIMEOUT_SEC
	
	if not errorlevel
		ret := clipboard
	clipboard := clip_saved
	return ret
}



_wrap_selected_text(bra, ket, kwargs:=0) {
	; wraps selected text in brackets and selects it again
	; parameters are in dictionary kwargs:
	;	offset - how much to move after `ket` was printed (mainly for {})
	
	kwargs := KwargsObj(kwargs)
	offset := kwargs.get("offset", -StrLen(ket))
	length := StrLen(StrReplace(get_selection(), "`r"))
	if (not length){
		SendInput %bra%%ket%
		move_cursor(offset)
	} else {
		SendInput {Left}
		SendInput %bra%
		move_cursor(length)
		SendInput %ket%
		move_cursor(offset)
		SendInput +{left %length%}		; select text again
	}
	return length
}

closing_is_present(bra, ket){
	; return true if closing bracket is present
	; e.g., in situation '(|)' - cursor between brackets and ')' was pressed 
	;	=> just move cursor to the right
	; it is skipped if there's an unclosed bracket before it (selects using Home)
	;	and next symbol is closing bracket
	
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

_print_closing_bracket(bra, ket){
	if closing_is_present(bra, ket)
		move_cursor(1)
	else {
		if (ket == "}")
			ket := "{}}"
		SendInput %ket%
	}	
}