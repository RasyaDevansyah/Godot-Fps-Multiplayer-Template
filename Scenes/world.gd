extends Node3D

@onready var main_menu: PanelContainer = $"CanvasLayer/Main Menu"
@onready var address: LineEdit = $"CanvasLayer/Main Menu/MarginContainer/VBoxContainer/Address"
@onready var hud: Control = $CanvasLayer/HUD
@onready var progress_bar: ProgressBar = $CanvasLayer/HUD/ProgressBar

const PORT := 9999
var enet_peer = ENetMultiplayerPeer.new()
const PLAYER = preload("uid://cyomswi4ra1s")



# This function should ONLY run on the server
func add_player(peer_id):
	var player = PLAYER.instantiate() as Player
	player.name = str(peer_id) # Name the node by the peer ID for uniqueness
	add_child(player)
	print("new spawn: " + str(peer_id))
	if player.is_multiplayer_authority():
		player.connect("health_updated", on_health_updated)

func on_health_updated(value : float):
	progress_bar.value = value
	pass

func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()
		
		
# --- CORRECTED HOST FUNCTION ---
func _on_host_pressed() -> void:
	main_menu.hide()
	hud.show()
	enet_peer.create_server(PORT)
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	multiplayer.multiplayer_peer = enet_peer
	
	# Spawn the host's player (ID is always 1)
	add_player(multiplayer.get_unique_id())
	
	# The SERVER listens for new players connecting
	# so it can spawn them.
	#upnp_setup()
	

# --- CORRECTED JOIN FUNCTION ---
func _on_join_pressed() -> void:
	main_menu.hide()
	hud.show()
	enet_peer.create_client(address.text, PORT) # Using "localhost" is fine for testing
	multiplayer.multiplayer_peer = enet_peer
	
	# --- DO NOT CONNECT ANY SIGNALS HERE ---
	# The client just connects. The server's MultiplayerSpawner
	# will automatically handle spawning this client's player
	# and all other existing players (like the host).
	pass



func upnp_setup():
	var upnp = UPNP.new()
	
	if upnp.discover() != UPNP.UPNP_RESULT_SUCCESS:
		print("UPNP Discover Failed. Host must port forward manually.")
		return

	var gateway = upnp.get_gateway()
	if not (gateway and gateway.is_valid_gateway()):
		print("UPNP Invalid Gateway. Host must port forward manually.")
		return
		
	var map_result = upnp.add_port_mapping(PORT)
	if map_result != UPNP.UPNP_RESULT_SUCCESS:
		print("UPNP Port Mapping Failed. Host must port forward manually.")
		return
		
	print("Success! Public Join Address: %s" % upnp.query_external_address())
	print("If friends cannot connect, host must manually forward port 9999.")


func _on_multiplayer_spawner_spawned(node: Node) -> void:
	if node.is_multiplayer_authority():
		node.connect("health_updated", on_health_updated)
	pass # Replace with function body.
