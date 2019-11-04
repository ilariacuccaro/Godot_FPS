extends RigidBody

const BASE_BULLET_BOOST = 9;

func _ready():
    pass

func bullet_hit(damage, bullet_global_trans):
    var direction_vect = bullet_global_trans.basis.z.normalized() * BASE_BULLET_BOOST; #otteniamo il vettore direzionale in avanti del proiettile
#possiamo dire da quale direzione il proiettile colpirà il RigidBody
#calcoliamo la posizione per l'impulso
    apply_impulse((bullet_global_trans.origin - global_transform.origin).normalized(), direction_vect * damage)