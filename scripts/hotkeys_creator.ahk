#include scripts/debug.ahk

hotkeys(file_path, obj, append_left, command){
	file := FileOpen(file_path, "w")
	if !IsObject(file)
		msg("File for", path, "not found")
	for key in obj {
		if (key == "0")
			continue
		out = %append_left%%key%::`n
		file.write(out)
	}
	file.write(command)
	file.write("`n`treturn`n")
	file.close()
}

create_wrappers(brackets_start){
	hotkeys("temp/starts.ahk"
			, brackets_start
			, "$"
			, "`twrap_selected_text(A_ThisHotkey)")
}

create_ends(brackets_end){
	hotkeys("temp/ends.ahk"
			, brackets_end
			, "$"
			, "`tprint_closing_bracket(A_ThisHotkey)")
}

create_shortcuts(shortcuts){
	hotkeys("temp/shortcuts.ahk"
			, shortcuts
			, ""
			, "`tsend(shortcuts[A_ThisHotkey])")
}