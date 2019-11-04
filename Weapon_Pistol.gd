extends Spatial

const DAMAGE = 15 #quantità di danno inflitta da un singolo proiettile

const IDLE_ANIM_NAME = "Pistol_idle" #nome dell'animazione inattiva della pistola
const FIRE_ANIM_NAME = "Pistol_fire" #nome dell'animazione del fuoco della pistola

var is_weapon_enabled = false #variabile per verificare se quest'arma è in uso / abilitata

var bullet_scene = preload("Bullet_Scene.tscn") #La scena del proiettile su cui abbiamo lavorato in precedenza

var player_node = null #variabile che contiene Player.gd

const CAN_RELOAD = true #booleano per tracciare se questa arma ha la capacità di ricaricare
const CAN_REFILL = true #booleano per tracciare se possiamo ricaricare le munizioni di riserva di quest'arma

const RELOADING_ANIM_NAME = "Pistol_reload" #nome dell'animazione di ricarica di quest'arma

func _ready():
    pass
var ammo_in_weapon = 10 #La quantità di munizioni attualmente nella pistola
var spare_ammo = 20 #quantità di munizioni che abbiamo lasciato in riserva per la pistola
const AMMO_IN_MAG = 10 #quantità di munizioni in un'arma / caricatore completamente ricaricato

func fire_weapon():
    var clone = bullet_scene.instance() #creiamo un nuovo nodo che contiene tutti i nodi nella scena che abbiamo istanziato, clonando quella scena
    var scene_root = get_tree().root.get_children()[0]
    scene_root.add_child(clone) #aggiungiamo clone al primo nodo, figlio della radice della scena in cui ci troviamo attualmente

    clone.global_transform = self.global_transform
    clone.scale = Vector3(4, 4, 4) #scaliamo di un fattore 4perché la scena del proiettile è troppo piccola per impostazione predefinita
    clone.BULLET_DAMAGE = DAMAGE
    ammo_in_weapon -= 1

func equip_weapon():
    if player_node.animation_manager.current_state == IDLE_ANIM_NAME:
        is_weapon_enabled = true #Se siamo in animazione stand-by del pistola, abbiamo impostato is_weapon_enabledper true
        return true

    if player_node.animation_manager.current_state == "Idle_unarmed":
        player_node.animation_manager.set_animation("Pistol_equip")

    return false

func unequip_weapon():
    if player_node.animation_manager.current_state == IDLE_ANIM_NAME: #controlliamo se il giocatore è inattivo
        if player_node.animation_manager.current_state != "Pistol_unequip":
            player_node.animation_manager.set_animation("Pistol_unequip") #Se il giocatore non è in animazione, vogliamo riprodurre l'animazione

    if player_node.animation_manager.current_state == "Idle_unarmed":
        is_weapon_enabled = false
        return true
    else:
        return false

func reload_weapon():
    var can_reload = false
#controlliamo per vedere se il giocatore è nello stato di animazione inattivo di quest'arma
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
# riproduce l'animazione di ricarica di questa arma
        player_node.animation_manager.set_animation(RELOADING_ANIM_NAME)

        return true
# Se il giocatore non è riuscito a ricaricare
    return false