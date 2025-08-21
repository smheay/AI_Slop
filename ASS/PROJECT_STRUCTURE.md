res://
├─ autoload/
│  ├─ Logger.gd
│  ├─ ServiceLocator.gd
│  ├─ GameBus.gd
│  ├─ GameGlobals.gd
│  └─ TwitchClient.gd
│
├─ core/
│  ├─ managers/
│  │  ├─ ManagerBase.gd
│  │  ├─ SpawnManager.gd
│  │  ├─ EntityIndex.gd
│  │  └─ Balance.gd
│  ├─ pools/
│  │  ├─ ObjectPool.gd
│  │  └─ BulletPool.gd
│  ├─ sim/
│  │  ├─ AgentSim.gd
│  │  ├─ SpatialHash2D.gd
│  │  └─ LODController.gd
│  ├─ jobs/
│  │  ├─ AIRunner.gd
│  │  └─ PhysicsRunner.gd
│  └─ util/
│     ├─ NodeUtil.gd
│     ├─ MathUtil.gd
│     └─ RNG.gd
│
├─ integrations/
│  └─ twitch/
│     ├─ CommandParser.gd
│     └─ CommandBindings.gd
│
├─ features/
│  ├─ combat/
│  │  ├─ Attack.gd
│  │  └─ Damageable.gd
│  ├─ abilities/
│  │  ├─ Ability.gd
│  │  ├─ FireNova.gd
│  │  └─ FireNova.tres
│  ├─ spawning/
│  │  ├─ Spawner.tscn
│  │  └─ Spawner.gd
│  ├─ procgen/
│  │  ├─ MapGenerator.gd
│  │  ├─ LayerPainter.gd
│  │  └─ RoomGraph.gd
│  ├─ crowd/
│  │  ├─ CrowdRenderer2D.tscn
│  │  ├─ CrowdRenderer2D.gd
│  │  └─ FlowField.gd
│  └─ ai/
│     ├─ StateMachine.gd
│     ├─ BehaviourTree.gd
│     └─ EnemyAI.gd
│
├─ actors/
│  ├─ player/
│  │  ├─ Player.tscn
│  │  └─ Player.gd
│  ├─ enemies/
│  │  ├─ BaseEnemy.tscn
│  │  ├─ BaseEnemy.gd
│  │  ├─ Slime.tscn
│  │  ├─ Slime.gd
│  │  ├─ BossGolem.tscn
│  │  └─ BossGolem.gd
│  ├─ npcs/
│  │  ├─ BaseNPC.gd
│  │  ├─ Villager.tscn
│  │  ├─ Villager.gd
│  │  ├─ Shopkeeper.tscn
│  │  └─ Shopkeeper.gd
│  ├─ items/
│  │  ├─ BaseItem.tscn
│  │  ├─ BaseItem.gd
│  │  ├─ PowerUp.tscn
│  │  ├─ PowerUp.gd
│  │  ├─ HealthPotion.tscn
│  │  ├─ HealthPotion.gd
│  │  ├─ Armor.tscn
│  │  ├─ Armor.gd
│  │  ├─ Weapon.tscn
│  │  ├─ Weapon.gd
│  │  ├─ ItemSpawner.tscn
│  │  └─ ItemSpawner.gd
│  └─ components/
│     ├─ Health.gd
│     ├─ Mover.gd
│     ├─ Steering.gd
│     ├─ Stats.gd
│     ├─ ChatControlled.gd
│     └─ Pickup.gd
│
├─ world/
│  ├─ Main.tscn
│  ├─ Main.gd
│  ├─ LevelRuntime.tscn
│  ├─ LevelRuntime.gd
│  ├─ DungeonTileMap.tscn
│  ├─ DungeonTileMap.gd
│  ├─ SystemsRunner.gd
│  └─ Chunks/
│     ├─ Chunk.tscn
│     └─ Chunk.gd
│
├─ ui/
│  ├─ HUD.tscn
│  ├─ HUD.gd
│  ├─ PauseMenu.tscn
│  ├─ PauseMenu.gd
│  ├─ DebugOverlay.tscn
│  ├─ DebugOverlay.gd
│  ├─ MainMenu.tscn
│  ├─ MainMenu.gd
│  ├─ OptionsMenu.tscn
│  ├─ OptionsMenu.gd
│  ├─ SoundMenu.tscn
│  ├─ SoundMenu.gd
│  ├─ SaveSelect.tscn
│  └─ SaveSelect.gd
│
├─ resources/
│  ├─ DataTable.gd
│  ├─ EnemyDefs.tres
│  ├─ NPCDefs.tres
│  ├─ ItemDefs.tres
│  ├─ LootTables.tres
│  ├─ TwitchBindings.tres
│  └─ Settings.tres
│
└─ assets/
   ├─ textures/
   │  └─ vfx/
   ├─ audio/
   └─ fonts/
