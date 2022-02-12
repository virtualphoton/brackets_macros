#include scripts/brackets_inserter.ahk
#include scripts/kwargs.ahk
#include scripts/debug.ahk
#include main.ahk

RU_LANG_CODE := 0x4190419 

wrap_selected_text(hotkey){
	global brackets_start
	key := delete_dollar(hotkey)
	_wrap(brackets_start[key]*)
}

print_closing_bracket(hotkey){
	global brackets_end
	key := delete_dollar(hotkey)
	_print_closing(brackets_end[key]*)
}

delete_dollar(str){
	if (SubStr(str, 1, 1) == "$")
		return SubStr(str, 2)		 ;omitting '$' sign
	return str
}

_wrap(bra, ket, kwargs:=0){
	kwargs := KwargsObj(kwargs)
	ru_char := kwargs.get("ru_char", "")
	if (ru_char == "" or layout_is_good()){
		has_wrapped_sth := _wrap_selected_text(bra, ket, kwargs)
		wait_for_backspace(has_wrapped_sth)
	} else
		SendInput %ru_char%
}

_print_closing(bra, ket, kwargs:=0){
	kwargs := KwargsObj(kwargs)
	ru_char := kwargs.get("ru_char", "")
	if (ru_char == "" or layout_is_good())
		_print_closing_bracket(bra, ket)
	else
		SendInput %ru_char%
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
	; waits for backspace to be pressed after brackets
	; if it was pressed (and text was not wrapped), inserted brackets will be deleted

	if (was_wrapped)
		; TODO make ctrl+Z if `was_wrapped`, because text editors handle it incorrectly
		return
	xpos := 0, ypos := 0, xpos1 := 0, ypos1 := 0
	MouseGetPos xpos,ypos
	
	out := ""
	; list of keys which could move cursos
	Input out, L1 V, {LControl}{RControl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}{AppsKey}{F1}{F2}{F3}{F4}{F5}{F6}{F7}{F8}{F9}{F10}{F11}{F12}{Left}{Right}{Up}{Down}{Home}{End}{PgUp}{PgDn}{Del}{Ins}{BS}{CapsLock}{NumLock}{PrintScreen}{Pause},
	
	MouseGetPos xpos1,ypos1
	; if user has moved mouse, then they supposedly don't want to erase brackets
	if (xpos = xpos1 and ypos == ypos1)
		if (ErrorLevel == "EndKey:Backspace")
			SendInput {Delete}
}