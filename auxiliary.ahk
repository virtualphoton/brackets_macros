#NoEnv
#SingleInstance Force
SendMode Input
SetWorkingDir %A_ScriptDir%

#include scripts/debug.ahk
#include scripts/brackets_inserter_wrapper.ahk
#include temp/ends.ahk
#include temp/shortcuts.ahk
#include temp/starts.ahk
#include main.ahk

send(text){
	SendInput %text%
}


^J::
	Suspend
	return 