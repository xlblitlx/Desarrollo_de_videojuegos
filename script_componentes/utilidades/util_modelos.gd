extends RefCounted
## Utilidades para medir modelos importados (FBX/GLB) sin conocer su tama├▒o original.

static func meshes_de(raiz: Node) -> Array[MeshInstance3D]:
	var lista: Array[MeshInstance3D] = []
	if raiz is MeshInstance3D:
		lista.append(raiz as MeshInstance3D)
	for n in raiz.find_children("*", "MeshInstance3D", true, false):
		lista.append(n as MeshInstance3D)
	return lista


## AABB combinado de las mallas de `raiz`, en el espacio local de `referencia`.
## Si `excluir` no est├í vac├¡o, ignora las mallas cuyo nombre lo contenga (p. ej. "Ring").
static func aabb_relativo(raiz: Node3D, referencia: Node3D, excluir: String = "") -> AABB:
	var inv := referencia.global_transform.affine_inverse()
	var total := AABB()
	var primero := true
	for mi in meshes_de(raiz):
		if excluir != "" and String(mi.name).containsn(excluir):
			continue
		var a: AABB = (inv * mi.global_transform) * mi.get_aabb()
		if primero:
			total = a
			primero = false
		else:
			total = total.merge(a)
	return total
