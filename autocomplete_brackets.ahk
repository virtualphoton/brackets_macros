#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
#Warn LocalSameAsGlobal, Off
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

print_and_move(str, n) {
	SendInput %str%
	move_cursor(n)
}

get_selection() {
	ClipSaved := ClipboardAll 			; save clipboard
	clipboard := ""
	ret := ""
	SendInput ^c
	global CLIPBOARD_TIMEOUT
	clipwait CLIPBOARD_TIMEOUT
	if not errorlevel
		ret := clipboard
	clipboard := ClipSaved
	ClipSaved := ""
	return ret
}

wrap_selected_text(before, after, offset:=-100, length:=-1) {
	if (offset == -100)
		offset := -StrLen(after)
	if (length == -1)
		length := StrLen(get_selection())
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
	ControlGetFocus Focused, A
	ControlGet CtrlID, Hwnd,, % Focused, A
	ThreadID := DllCall("GetWindowThreadProcessId", "Ptr", CtrlID, "Ptr", 0)
	InputLocaleID := DllCall("GetKeyboardLayout", "UInt", ThreadID, "Ptr")
	return InputLocaleID != RU_LANG_CODE 
}

class Mutex{
	static counter := 0
	__new(ms_wait:=100) {
		this.ms_wait := ms_wait
		this.mutex_name := "bracket_autocomplete_mutex_" Mutex.counter
		
		this.mutex_handle  := DllCall( "CreateMutex"
		                            ,  Ptr, 0
									,  Int, False
									,  Str, this.mutex_name)
	}
	
	__delete(){
		DllCall("CloseHandle",  Ptr, this.mutex_handle)
	}
	
	lock(signal:=False) {
		while (True){
			mutex_status := DllCall("WaitForSingleObject"
									, Ptr, this.mutex_handle
									, UInt, this.ms_wait)
			if (signal)
				MsgBox %mutex_status%
			if (mutex_status == 0) 				; success
				return 0
			if (mutex_status == 258)				; WAIT_TIMEOUT
				continue
			return 1
		}
	}
	unlock() {
		return not DllCall("ReleaseMutex", Ptr, this.mutex_handle)
	}
}

print_mutex := new Mutex()

^\::
	wrap_selected_text("\(", "\)")
	return

$(::
	global print_mutex
	print_mutex.lock(True)
	sleep 4000
	wrap_selected_text("(", ")")
	print_mutex.unlock()
	return

${::
	global print_mutex
	print_mutex.lock()
	wrap_selected_text("{{}", "{}}", -1)		; escaping '{' and '}'
	print_mutex.unlock()
	return
	
$[::
	global print_mutex
	print_mutex.lock()
	wrap_selected_text("[", "]")
	print_mutex.unlock()
	return
	
$"::
	wrap_selected_text("""", """")
	return

$)::
	global print_mutex
	print_mutex.lock(True)
	insert_end_bracket("(", ")") 
	print_mutex.unlock()
	return
	
$]::
	global print_mutex
	; print_mutex.lock()
	insert_end_bracket("[", "]") 
	; print_mutex.unlock()
	return 
	
$}::
	global print_mutex
	print_mutex.lock()
	insert_end_bracket("{", "}") 
	print_mutex.unlock()
	return