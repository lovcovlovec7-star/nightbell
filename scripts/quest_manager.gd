extends Node
class_name QuestManager

signal objective_changed(text)
signal evidence_changed(count)

var step = 0
var evidence_count = 0
var objectives = [
	"Поговорить с Кадзуо Сато у стойки охраны.",
	"Поговорить с Аей Морита на ресепшене.",
	"Пройти в open-space и найти рабочий компьютер.",
	"Открыть компьютер и прочитать письмо Night Bell.",
	"Включить радио в комнате охраны.",
	"Распечатать документ на принтере.",
	"Посмотреть CCTV: камеры ресепшен, open-space, архив, серверная.",
	"Взять улику в архиве.",
	"Вернуться к Кадзуо или Ае с уликами.",
	"Смена раскрыта: дождаться следующего звонка."
]

func current_objective():
	return objectives[min(step, objectives.size() - 1)]

func ready_state():
	emit_signal("objective_changed", current_objective())
	emit_signal("evidence_changed", evidence_count)

func advance(required, clue_gain):
	if step == required:
		step += 1
		if clue_gain > 0:
			evidence_count += clue_gain
		emit_signal("objective_changed", current_objective())
		emit_signal("evidence_changed", evidence_count)
		return true
	return false

func add_evidence_once(flag_name, owner):
	if owner.get_meta(flag_name, false):
		return false
	owner.set_meta(flag_name, true)
	evidence_count += 1
	emit_signal("evidence_changed", evidence_count)
	return true
