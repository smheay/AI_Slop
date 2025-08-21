extends Node
class_name GameBusSignals

signal player_spawned(player: Node)
signal enemy_spawned(enemy: Node)
signal enemy_despawned(enemy: Node)
signal ability_cast(caster: Node, ability: Resource)
signal item_picked_up(actor: Node, item: Node)
signal stats_modified(actor: Node, source: Object)
signal chat_command(user: String, command: String, args: Array)
