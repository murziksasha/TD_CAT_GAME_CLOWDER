class_name PresentationAudio
extends RefCounted

# Audio is intentionally optional: a missing stream is a silent cue, never a match failure.
func note(_event: Dictionary) -> void:
	pass
