extends Node

var keys: int = 0
var batteries: int = 0

func add_key():
    keys += 1
    print("Keys: ", keys)

func add_battery():
    batteries += 1
    print("Batteries: ", batteries)

func use_key() -> bool:
    if keys > 0:
        keys -= 1
        return true
    return false

func use_battery() -> bool:
    if batteries > 0:
        batteries -= 1
        return true
    return false

func has_key() -> bool:
    return keys > 0

func has_battery() -> bool:
    return batteries > 0
