# resources/event_resource.gd
class_name EventResource
extends Resource

@export var event_name: String = ""
@export var description: String = ""
@export var choices: Array = []  # Array[EventChoiceResource]
@export var bgm_type: String = "encounter"  # mysterious / dark / encounter / fortune
