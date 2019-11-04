extends KinematicBody

const GRAVITY = -24.8
var vel = Vector3()
const MAX_SPEED = 20
const JUMP_SPEED = 18
const ACCEL = 4.5

var dir = Vector3()

const DEACCEL= 16
const MAX_SLOPE_ANGLE = 40

var camera
var rotation_helper

var MOUSE_SENSITIVITY = 0.05

const MAX_SPRINT_SPEED = 30
const SPRINT_ACCEL = 18
var is_sprinting = false

var flashlight

var animation_manager # conterrà il nodo AnimationPlayer e il suo script

var current_weapon_name = "UNARMED" #nome dell'arma che stiamomutilizzando, quattro possibili valori: UNARMED, KNIFE, PISTOL, e RIFLE.
var weapons = {"UNARMED":null, "KNIFE":null, "PISTOL":null, "RIFLE":null} # dizionario che conterrà tutti i nodi dell'arma
const WEAPON_NUMBER_TO_NAME = {0:"UNARMED", 1:"KNIFE", 2:"PISTOL", 3:"RIFLE"} #dizionario che ci consente di convertire dal numero di un'arma al suo nome. Lo useremo per cambiare le armi
const WEAPON_NAME_TO_NUMBER = {"UNARMED":0, "KNIFE":1, "PISTOL":2, "RIFLE":3} #Un dizionario che ci consente di convertire dal nome di un'arma al suo numero
var changing_weapon = false # booleano per tracciare se stiamo cambiando o meno le armi
var changing_weapon_name = "UNARMED" #nome dell'arma che vogliamo cambiare

var health = 100 #salute del giocatore

var UI_status_label #Un'etichetta per mostrare quanta salute abbiamo e quante munizioni abbiamo sia nella pistola che nella riserva

var reloading_weapon = false #variabile per tracciare se il giocatore sta attualmente tentando di ricaricare

func _ready():
    camera = $Rotation_Helper/Camera
    rotation_helper = $Rotation_Helper

    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

    flashlight = $Rotation_Helper/Flashlight

    camera = $Rotation_Helper/Camera #
    rotation_helper = $Rotation_Helper
#otteniamo il nodo AnimationPlayer e lo assegniamo alla animation_manager
    animation_manager = $Rotation_Helper/Model/Animation_Player
    animation_manager.callback_function = funcref(self, "fire_bullet") #funcrect chiamerà fire_bullet

    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
#otteniamo tutti i nodi dell'arma e li assegniamo a weapons
    weapons["KNIFE"] = $Rotation_Helper/Gun_Fire_Points/Knife_Point
    weapons["PISTOL"] = $Rotation_Helper/Gun_Fire_Points/Pistol_Point
    weapons["RIFLE"] = $Rotation_Helper/Gun_Fire_Points/Rifle_Point
#otteniamo la posizione globale in modo da poter ruotare le armi del giocatore per mirare
    var gun_aim_point_pos = $Rotation_Helper/Gun_Aim_Point.global_transform.origin

    for weapon in weapons:
        var weapon_node = weapons[weapon]
        if weapon_node != null:
            weapon_node.player_node = self
            weapon_node.look_at(gun_aim_point_pos, Vector3(0, 1, 0))
            weapon_node.rotate_object_local(Vector3(0, 1, 0), deg2rad(180))

    current_weapon_name = "UNARMED"
    changing_weapon_name = "UNARMED"

    UI_status_label = $HUD/Panel/Gun_label
    flashlight = $Rotation_Helper/Flashlight

func _physics_process(delta):
    process_input(delta)
    process_movement(delta)
    process_changing_weapons(delta)
    process_reloading(delta)
    process_UI(delta)

func process_input(delta):

    # ----------------------------------
    # Walking
    dir = Vector3()
    var cam_xform = camera.get_global_transform()

    var input_movement_vector = Vector2()

    if Input.is_action_pressed("movement_forward"):
        input_movement_vector.y += 1
    if Input.is_action_pressed("movement_backward"):
        input_movement_vector.y -= 1
    if Input.is_action_pressed("movement_left"):
        input_movement_vector.x -= 1
    if Input.is_action_pressed("movement_right"):
        input_movement_vector.x += 1

    input_movement_vector = input_movement_vector.normalized()

    # Basis vectors are already normalized.
    dir += -cam_xform.basis.z * input_movement_vector.y
    dir += cam_xform.basis.x * input_movement_vector.x
    # ----------------------------------

    # ----------------------------------
    # Jumping
    if is_on_floor():
        if Input.is_action_just_pressed("movement_jump"):
            vel.y = JUMP_SPEED
    # ----------------------------------

    # ----------------------------------
    # Capturing/Freeing the cursor
    if Input.is_action_just_pressed("ui_cancel"):
        if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
        else:
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    # ----------------------------------
    # Sprinting
    if Input.is_action_pressed("movement_sprint"):
        is_sprinting = true
    else:
        is_sprinting = false
# ----------------------------------

# ----------------------------------
# Turning the flashlight on/off
    if Input.is_action_just_pressed("flashlight"):
        if flashlight.is_visible_in_tree():
            flashlight.hide()
        else:
            flashlight.show()
# ----------------------------------
 # otteniamo il numero dell'arma corrente e lo assegniamo a weapon_change_number
    var weapon_change_number = WEAPON_NAME_TO_NUMBER[current_weapon_name]
#controlliamo se viene premuto uno qualsiasi dei tasti numerici tra 1-4
    if Input.is_key_pressed(KEY_1):
        weapon_change_number = 0
    if Input.is_key_pressed(KEY_2):
        weapon_change_number = 1
    if Input.is_key_pressed(KEY_3):
        weapon_change_number = 2
    if Input.is_key_pressed(KEY_4):
        weapon_change_number = 3

    if Input.is_action_just_pressed("shift_weapon_positive"):
        weapon_change_number += 1
    if Input.is_action_just_pressed("shift_weapon_negative"):
        weapon_change_number -= 1

    weapon_change_number = clamp(weapon_change_number, 0, WEAPON_NUMBER_TO_NAME.size() - 1)

    if changing_weapon == false:
        if reloading_weapon == false:
            if WEAPON_NUMBER_TO_NAME[weapon_change_number] != current_weapon_name:
                changing_weapon_name = WEAPON_NUMBER_TO_NAME[weapon_change_number]
                changing_weapon = true
# ----------------------------------
# Per sparare l'arma controlliamo prima se l'azione fire è premuta
   # Firing the weapons
    if Input.is_action_pressed("fire"):
        if reloading_weapon == false:
            if changing_weapon == false:
                var current_weapon = weapons[current_weapon_name]
                if current_weapon != null:
                  if current_weapon.ammo_in_weapon > 0:
                      if animation_manager.current_state == current_weapon.IDLE_ANIM_NAME:
                          animation_manager.set_animation(current_weapon.FIRE_ANIM_NAME)
# ----------------------------------

func process_movement(delta):
    dir.y = 0
    dir = dir.normalized()

    vel.y += delta * GRAVITY

    var hvel = vel
    hvel.y = 0

    var target = dir
   # target *= MAX_SPEED
#controlliamo se il giocatore sta scattando
    if is_sprinting:
        target *= MAX_SPRINT_SPEED
    else:
        target *= MAX_SPEED

    var accel
  #  if dir.dot(hvel) > 0:
    if is_sprinting:
        accel = SPRINT_ACCEL
    else:
        accel = ACCEL
     

    hvel = hvel.linear_interpolate(target, accel * delta)
    vel.x = hvel.x
    vel.z = hvel.z
    vel = move_and_slide(vel, Vector3(0, 1, 0), 0.05, 4, deg2rad(MAX_SLOPE_ANGLE))

    if reloading_weapon == false:
        if changing_weapon == false:
            if Input.is_action_just_pressed("reload"):
                var current_weapon = weapons[current_weapon_name]
                if current_weapon != null:
                    if current_weapon.CAN_RELOAD == true:
                        var current_anim_state = animation_manager.current_state
                        var is_reloading = false
                        for weapon in weapons:
                            var weapon_node = weapons[weapon]
                            if weapon_node != null:
                                if current_anim_state == weapon_node.RELOADING_ANIM_NAME:
                                     is_reloading = true
                        if is_reloading == false:
                            reloading_weapon = true

func _input(event):
    if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
        rotation_helper.rotate_x(deg2rad(event.relative.y * MOUSE_SENSITIVITY))
        self.rotate_y(deg2rad(event.relative.x * MOUSE_SENSITIVITY * -1))

        var camera_rot = rotation_helper.rotation_degrees
        camera_rot.x = clamp(camera_rot.x, -70, 70)
        rotation_helper.rotation_degrees = camera_rot

func process_changing_weapons(delta):
    if changing_weapon == true: # ci assicuriamo di aver ricevuto input per cambiare le armi
#definiamo una variabile in modo da poter verificare se l'arma attuale non è stata equipaggiata correttamente
        var weapon_unequipped = false
        var current_weapon = weapons[current_weapon_name] #prendiamo l'arma attuale da weapons

        if current_weapon == null:
            weapon_unequipped = true
        else:
            if current_weapon.is_weapon_enabled == true:
                weapon_unequipped = current_weapon.unequip_weapon()
            else:
                weapon_unequipped = true

        if weapon_unequipped == true:

            var weapon_equipped = false
            var weapon_to_equip = weapons[changing_weapon_name]

            if weapon_to_equip == null:
                weapon_equipped = true
            else:
                if weapon_to_equip.is_weapon_enabled == false:
                    weapon_equipped = weapon_to_equip.equip_weapon()
                else:
                    weapon_equipped = true

            if weapon_equipped == true:
                changing_weapon = false
                current_weapon_name = changing_weapon_name
                changing_weapon_name = ""
				
func fire_bullet():
    if changing_weapon == true: # controlliamo se il giocatore sta cambiando le armi
        return #in questo caso non vogliamo sparare

    weapons[current_weapon_name].fire_weapon()

func process_UI(delta):
    if current_weapon_name == "UNARMED" or current_weapon_name == "KNIFE":
        UI_status_label.text = "HEALTH: " + str(health)
    else:
        var current_weapon = weapons[current_weapon_name]
        UI_status_label.text = "HEALTH: " + str(health) + \
                "\nAMMO: " + str(current_weapon.ammo_in_weapon) + "/" + str(current_weapon.spare_ammo)
				
func process_reloading(delta):
    if reloading_weapon == true: #controlliamo che il giocatore stia provando a ricaricare
        var current_weapon = weapons[current_weapon_name]
        if current_weapon != null:
            current_weapon.reload_weapon()
        reloading_weapon = false