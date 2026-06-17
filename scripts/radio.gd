extends Node
class_name RadioLogic
var enabled = false
var mode = 0
var tracks = ["Офисный шум 88.1", "Полицейский канал", "...ночной звонок уже внутри здания..."]
func toggle(quest_step):
	enabled = not enabled
	if enabled:
		mode = (mode + 1) % tracks.size()
		if quest_step < 4:
			mode = 0
		return "Радио включено: " + tracks[mode]
	return "Радио выключено."
