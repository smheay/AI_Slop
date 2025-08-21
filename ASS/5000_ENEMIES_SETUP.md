# 5000 Enemies Setup Guide

This system is designed to handle **5000+ enemies simultaneously** with smooth performance using hierarchical collision and intelligent LOD systems.

## 🚀 Key Features

### Hierarchical Collision System
- **Tiny enemies** (< 50 units): Can't push through anything
- **Small enemies** (50-100 units): Can only push through tiny
- **Medium enemies** (100-300 units): Can push through tiny+small
- **Large enemies** (300-600 units): Can push through tiny+small+medium
- **Huge enemies** (>600 units): Bulldozer mode - push through everything!

### Performance Optimizations
- **LOD System**: Enemies update at different frequencies based on size/distance
- **Spatial Hashing**: Efficient neighbor queries for collision detection
- **Batch Processing**: AI and physics processed in optimized batches
- **Object Pooling**: Reuse enemy instances to reduce memory allocation
- **Frame Distribution**: Spread updates across frames to avoid spikes

## 🏗️ Setup Instructions

### 1. Scene Structure
```
Main
├── SystemsRunner
│   ├── AgentSim
│   ├── SpatialHash2D
│   ├── HierarchicalCollision  ← NEW!
│   ├── AIRunner
│   ├── PhysicsRunner
│   └── ObjectPool
├── HighPerformanceSpawner     ← NEW!
├── PerformanceMonitor         ← NEW!
└── Camera2D
```

### 2. Required Scripts
- `HierarchicalCollision.gd` - Handles size-based collision rules
- `HighPerformanceSpawner.gd` - Spawns 5000 enemies efficiently
- `BaseEnemy.gd` - Optimized enemy base class
- `PerformanceMonitor.gd` - Tracks performance metrics

### 3. Configuration

#### HierarchicalCollision Settings
```gdscript
# Adjust these thresholds based on your game scale
near_distance: 256.0
far_distance: 1024.0
adaptive_lod: true
target_fps: 60.0
```

#### HighPerformanceSpawner Settings
```gdscript
max_enemies: 5000
spawn_batch_size: 100
spawn_interval: 0.1
use_object_pooling: true
enable_lod: true

# Enemy size distribution
tiny_enemy_chance: 0.4    # 40% tiny enemies
small_enemy_chance: 0.3   # 30% small enemies
medium_enemy_chance: 0.2  # 20% medium enemies
large_enemy_chance: 0.08  # 8% large enemies
huge_enemy_chance: 0.02   # 2% huge enemies
```

#### PerformanceMonitor Settings
```gdscript
monitor_enabled: true
update_interval: 1.0
warning_thresholds: {
    "fps": 30.0,
    "frame_time": 33.0,
    "memory_mb": 512.0,
    "enemy_count": 4000.0
}
```

## 🎮 How It Works

### Collision Hierarchy
1. **Large enemies** act as "bulldozers" - they can push through smaller enemies
2. **Small enemies** get pushed around and can't push through each other
3. **Size-based rules** determine what can push through what
4. **Collision response** varies based on size difference

### Performance Scaling
1. **LOD Levels**: 
   - Level 0: Update every frame (large enemies, near camera)
   - Level 1: Update every 2 frames (medium enemies)
   - Level 2: Update every 3 frames (tiny enemies, far from camera)

2. **Batch Processing**:
   - AI decisions processed in batches of 128
   - Physics integration in batches of 128
   - Spatial hash updates batched for efficiency

3. **Memory Management**:
   - Object pooling for enemy instances
   - Pre-allocated temporary vectors
   - Cached size calculations

## 📊 Performance Expectations

### Target Performance (60 FPS)
- **1000 enemies**: 60+ FPS (easy)
- **2500 enemies**: 50+ FPS (good)
- **5000 enemies**: 35+ FPS (acceptable)
- **7500 enemies**: 25+ FPS (challenging)

### Performance Factors
- **Enemy size distribution**: More large enemies = better performance
- **LOD settings**: Higher LOD levels = better performance
- **Spatial hash cell size**: Larger cells = fewer queries but less precision
- **Update frequency**: Lower update rates = better performance

## 🔧 Troubleshooting

### If Performance is Poor
1. **Increase LOD levels** for distant enemies
2. **Reduce enemy count** temporarily
3. **Check spatial hash cell size** (should be 64-128 units)
4. **Enable object pooling** if not already enabled
5. **Monitor memory usage** - should stay under 512MB

### Common Issues
- **Lag at 600 enemies**: Usually means old collision system is still active
- **Memory spikes**: Check object pooling and enemy cleanup
- **FPS drops**: Monitor LOD levels and batch sizes

## 🎯 Best Practices

### For Maximum Performance
1. **Use size variety**: Mix of tiny, small, medium, large, and huge enemies
2. **Enable LOD**: Let the system automatically adjust update frequencies
3. **Batch spawning**: Spawn enemies in batches, not all at once
4. **Monitor metrics**: Use PerformanceMonitor to track performance
5. **Adjust thresholds**: Fine-tune size thresholds for your game scale

### Enemy Design
1. **Tiny enemies**: Fast, weak, many (40% of total)
2. **Small enemies**: Balanced, medium speed (30% of total)
3. **Medium enemies**: Stronger, slower (20% of total)
4. **Large enemies**: Powerful, slow, few (8% of total)
5. **Huge enemies**: Boss-like, very slow, rare (2% of total)

## 🚀 Advanced Features

### Custom Enemy Types
Extend `BaseEnemy` to create specialized enemy types:
```gdscript
extends BaseEnemy

func _compute_desired_velocity(delta: float) -> Vector2:
    # Custom AI behavior
    var player = get_tree().get_first_node_in_group("player")
    if player:
        return (player.global_position - global_position).normalized() * move_speed
    return Vector2.ZERO
```

### Dynamic LOD Adjustment
```gdscript
# Adjust LOD based on performance
func _on_performance_warning(metric: String, value: float, threshold: float):
    if metric == "fps" and value < 30:
        # Increase LOD levels for better performance
        for enemy in get_tree().get_nodes_in_group("enemies"):
            enemy.set_lod_level(enemy.lod_level + 1)
```

## 📈 Monitoring and Debugging

### Console Commands
```gdscript
# Print performance summary
get_node("PerformanceMonitor").print_performance_summary()

# Get current enemy count
print("Enemies: ", get_node("HighPerformanceSpawner").get_enemy_count())

# Clear all enemies (for testing)
get_node("HighPerformanceSpawner").clear_all_enemies()
```

### Performance Metrics
- **FPS**: Target 60, warn below 30
- **Frame Time**: Target 16.67ms, warn above 33ms
- **Memory**: Target under 256MB, warn above 512MB
- **Enemy Count**: Monitor approach to 5000 limit

## 🎮 Testing

### Performance Test
1. Start with 1000 enemies
2. Gradually increase to 5000
3. Monitor FPS and frame time
4. Adjust LOD and batch settings as needed

### Stress Test
1. Spawn 5000 enemies rapidly
2. Move camera around to test LOD system
3. Check memory usage over time
4. Verify collision behavior at all sizes

This system should handle 5000 enemies smoothly while maintaining the hierarchical collision behavior you want!