extends Control


var type: int = 0: set = set_type


func advance_animation(amount: float):
	%animator.advance(amount)

func fill():
	%full.show()
	%empty.hide()

func empty():
	%full.hide()
	%empty.show()


func set_type(what: int):
	type = what
	
	match what:
		-1:
			empty()
		0:
			fill()
