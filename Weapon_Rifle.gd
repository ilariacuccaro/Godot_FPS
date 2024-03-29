extends Spatial

const DAMAGE = 4

const IDLE_ANIM_NAME = "Rifle_idle"
const FIRE_ANIM_NAME = "Rifle_fire"

var is_weapon_enabled = false

var player_node = null

var ammo_in_weapon = 50
var spare_ammo = 100
const AMMO_IN_MAG = 50

const CAN_RELOAD = true
const CAN_REFILL = true

const RELOADING_ANIM_NAME = "Rifle_reload"

func _ready():
    pass

func fire_weapon():
    var ray = $Ray_Cast
    ray.force_raycast_update() #otteniamo il nodo Raycast, di cui è figlio Rifle_Point

    if ray.is_colliding():
        var body = ray.get_collider() #rileva le collisioni quando lo chiamiamo
   #verifichiamo che il corpo con cui ci scontriamo non sia il giocatore stesso
        if body == player_node:
            pass
        elif body.has_method("bullet_hit"): #Se il corpo non lo è, controlliamo se ha una funzione chiamata bullet_hit
            body.bullet_hit(DAMAGE, ray.global_transform) #passiamo la quantità di danno che questo proiettile fa
    ammo_in_weapon -= 1

func equip_weapon():
    if player_node.animation_manager.current_state == IDLE_ANIM_NAME:
        is_weapon_enabled = true
        return true

    if player_node.animation_manager.current_state == "Idle_unarmed":
        player_node.animation_manager.set_animation("Rifle_equip")

    return false

func unequip_weapon():

    if player_node.animation_manager.current_state == IDLE_ANIM_NAME:
        if player_node.animation_manager.current_state != "Rifle_unequip":
            player_node.animation_manager.set_animation("Rifle_unequip")

    if player_node.animation_manager.current_state == "Idle_unarmed":
        is_weapon_enabled = false
        return true

    return false

func reload_weapon():
    var can_reload = false

    if player_node.animation_manager.current_state == IDLE_ANIM_NAME:
        can_reload = true

    if spare_ammo <= 0 or ammo_in_weapon == AMMO_IN_MAG:
        can_reload = false

    if can_reload == true:
        var ammo_needed = AMMO_IN_MAG - ammo_in_weapon

        if spare_ammo >= ammo_needed:
            spare_ammo -= ammo_needed
            ammo_in_weapon = AMMO_IN_MAG
        else:
            ammo_in_weapon += spare_ammo
            spare_ammo = 0

        player_node.animation_manager.set_animation(RELOADING_ANIM_NAME)

        return true

    return false