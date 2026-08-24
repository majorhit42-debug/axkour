class_name CharacterRig
# Shared X Bot rig plumbing used by both the player and CPU racers.
# Static helpers only — same pattern as HatBuilder. Extracted from player.gd
# so bots get identical mesh/skin/hat handling without inheriting input or camera code.

static func find_first_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var found := find_first_mesh(child)
		if found:
			return found
	return null

static func find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var found := find_skeleton(child)
		if found:
			return found
	return null

# Builds the head hat mount and returns the node hats should be parented to.
# Returns null if the skeleton or head bone can't be found.
static func create_hat_mount(character_mesh: Node) -> Node3D:
	var skeleton := find_skeleton(character_mesh)
	if not skeleton:
		push_warning("CharacterRig: Skeleton3D not found in CharacterMesh")
		return null
	# Godot converts ':' to '_' on FBX import; try both spellings.
	var head_idx := skeleton.find_bone("mixamorig_Head")
	if head_idx < 0:
		head_idx = skeleton.find_bone("mixamorig:Head")
	if head_idx < 0:
		push_warning("CharacterRig: head bone not found (bone count: %d)" % skeleton.get_bone_count())
		return null
	# BoneAttachment3D's own transform is overridden by the bone every frame,
	# so the y-offset lives on a child node instead.
	var bone_attach := BoneAttachment3D.new()
	bone_attach.name = "HatBoneAttach"
	bone_attach.bone_idx = head_idx
	skeleton.add_child(bone_attach)
	var hat_offset := Node3D.new()
	hat_offset.name = "HatMount"
	hat_offset.position.y = 0.18
	bone_attach.add_child(hat_offset)
	return hat_offset

static func apply_skin_color(body_mesh: MeshInstance3D, color: Color) -> void:
	if not body_mesh:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.7
	body_mesh.set_surface_override_material(0, mat)

static func apply_hat(hat_mount: Node3D, hat_type: String, color: Color) -> void:
	if not hat_mount:
		return
	for child in hat_mount.get_children():
		child.queue_free()
	if hat_type.is_empty():
		return
	for mi in HatBuilder.make_meshes(hat_type, color, 1.0):
		hat_mount.add_child(mi)
