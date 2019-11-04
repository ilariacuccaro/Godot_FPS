extends Spatial

var BULLET_SPEED = 70 #velocità con cui il proiettile viaggia
var BULLET_DAMAGE = 15 #danno causato dal proiettile quando si scontra con qualcosa

const KILL_TIMER = 4 #Quanto tempo può durare il proiettile senza colpire nulla
var timer = 0 #per tenere traccia di quanto tempo il proiettile è rimasto vivo

var hit_something = false #valore booleano per tracciare se abbiamo colpito o meno qualcosa

func _ready():
    $Area.connect("body_entered", self, "collided") #body_entered chiama la funzione collided quando un corpo entra nell'area


func _physics_process(delta): #ottiene l'asse z del proiettile
    var forward_dir = global_transform.basis.z.normalized()
    global_translate(forward_dir * BULLET_SPEED * delta)

    timer += delta
    if timer >= KILL_TIMER: #se il timer ha raggiunto un valore maggiore della nostra KILL_TIME, elimino il proiettile
        queue_free()


func collided(body): #controlliamo se abbiamo colpito qualcosa
    if hit_something == false:
        if body.has_method("bullet_hit"):
            body.bullet_hit(BULLET_DAMAGE, global_transform) #chiamiamo bullet.hit e passiamo il danno del proiettile e la trasformazione

    hit_something = true
    queue_free()