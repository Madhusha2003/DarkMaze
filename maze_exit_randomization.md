# 🎮 Maze Exit Randomization System (Shuffle Bag Method)

## 🧠 Concept

This system generates multiple exit types in a maze but ensures:

- No repetition
- Fair randomness
- Clean and scalable design

Instead of calling multiple functions randomly, we use a **pool system (shuffle bag)**.

---

## 🚀 Core Idea

1. Store exit types in a list (pool)
2. Shuffle or randomly pick one
3. Remove it so it cannot repeat
4. Reset pool when maze regenerates

---

## ⚙️ Implementation

### 🧱 Step 1: Create Pool

```gdscript
var exit_pool = []
```

### 🔄 Step 2: Build Pool on Maze Start

```gdscript
func build_exit_pool():
    exit_pool.clear()

    for i in range(5):
        exit_pool.append(i)
```

### 🎲 Step 3: Pick Random Without Repeating

```gdscript
func get_random_exit_type():
    var index = randi() % exit_pool.size()
    var chosen = exit_pool[index]
    exit_pool.remove_at(index)
    return chosen
```

### 🚪 Step 4: Spawn Exit Based on Type

```gdscript
func add_random_exit():
    var type = get_random_exit_type()

    match type:
        0:
            spawn_exit_left()
        1:
            spawn_exit_right()
        2:
            spawn_exit_top()
        3:
            spawn_exit_bottom()
        4:
            spawn_exit_center_edge()
```

---

## ⚡ Even Cleaner Version (Built-in Shuffle Bag)

Instead of manual random indexing:

```gdscript
exit_pool.shuffle()
var type = exit_pool.pop_back()
```

This achieves the same result with less code.

---

## 🧠 Why This Works Well

- ✔ No duplicate exits
- ✔ Predictable randomness
- ✔ Easy to expand (add more exit types anytime)
- ✔ Clean separation of logic
- ✔ Good for procedural generation systems

---

## 🔥 Summary

This is a **Shuffle Bag Pattern**, commonly used in games for controlled randomness.

It ensures:

- Every exit type is used once per cycle
- No immediate repeats
- Balanced randomness

> Perfect for maze generation systems 🎮
