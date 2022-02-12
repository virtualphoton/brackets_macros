msg(args*){
	str := ""
	for _, arg in args
        str .= arg . " "
	MsgBox %str%
}

class Timer {
	__new(){
		this.last_time := A_TickCount
	}
	tick(){
		this.last_time := A_TickCount
	}
	show_time(){
		dt := A_TickCount - this.last_time
		msg(dt)
		this.tick()
	}
}