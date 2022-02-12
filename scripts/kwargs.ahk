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