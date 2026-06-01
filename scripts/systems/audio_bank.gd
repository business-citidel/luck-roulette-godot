class_name AudioBank
extends Node

const AUDIO_BASE := "res://assets/audio/kenney_casino-audio/Audio/"

var sfx_players: Array[AudioStreamPlayer] = []
var sfx_bank: Dictionary = {}
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	if sfx_bank.is_empty():
		rng.randomize()
		build()

func build() -> void:
	_load_sfx("dice_roll", [
		AUDIO_BASE + "dice-throw-1.ogg",
		AUDIO_BASE + "dice-throw-2.ogg",
		AUDIO_BASE + "dice-throw-3.ogg",
		AUDIO_BASE + "die-throw-1.ogg"
	])
	_load_sfx("dice_lock", [
		AUDIO_BASE + "dice-grab-1.ogg",
		AUDIO_BASE + "dice-grab-2.ogg"
	])
	_load_sfx("marble_pick", [
		AUDIO_BASE + "chips-handle-1.ogg",
		AUDIO_BASE + "chips-handle-2.ogg",
		AUDIO_BASE + "chips-handle-3.ogg"
	])
	_load_sfx("marble_drop", [
		AUDIO_BASE + "chip-lay-1.ogg",
		AUDIO_BASE + "chip-lay-2.ogg",
		AUDIO_BASE + "chip-lay-3.ogg"
	])
	_load_sfx("wheel_tick", [
		AUDIO_BASE + "chips-stack-1.ogg",
		AUDIO_BASE + "chips-stack-2.ogg",
		AUDIO_BASE + "chips-stack-3.ogg"
	])
	_load_sfx("coin_spill", [
		AUDIO_BASE + "chips-collide-1.ogg",
		AUDIO_BASE + "chips-collide-2.ogg",
		AUDIO_BASE + "chips-collide-3.ogg",
		AUDIO_BASE + "chips-collide-4.ogg"
	])
	_load_sfx("table_hit", [
		AUDIO_BASE + "cards-pack-take-out-1.ogg",
		AUDIO_BASE + "card-shove-1.ogg",
		AUDIO_BASE + "card-shove-2.ogg"
	])
	for i in range(10):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = "Master"
		player.max_polyphony = 2
		add_child(player)
		sfx_players.append(player)

func has_sfx(key: String) -> bool:
	var streams: Array = sfx_bank.get(key, [])
	return not streams.is_empty()

func play_sfx(key: String, pitch: float = 1.0, volume_db: float = -6.0, pitch_variation: float = 0.045) -> void:
	var streams: Array = sfx_bank.get(key, [])
	if streams.is_empty():
		return
	var player: AudioStreamPlayer = _free_sfx_player()
	if player == null:
		return
	var stream_index: int = rng.randi_range(0, streams.size() - 1)
	player.stream = streams[stream_index]
	player.pitch_scale = clamp(pitch + rng.randf_range(-pitch_variation, pitch_variation), 0.6, 1.55)
	player.volume_db = volume_db
	player.play()

func _load_sfx(key: String, paths: Array[String]) -> void:
	var streams: Array = []
	for path in paths:
		var stream: AudioStream = AudioStreamOggVorbis.load_from_file(path)
		if stream != null:
			streams.append(stream)
	sfx_bank[key] = streams

func _free_sfx_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	return sfx_players[0] if not sfx_players.is_empty() else null
