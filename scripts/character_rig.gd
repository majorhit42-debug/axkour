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

# Costume mounts: head (hat), chest (torso piece), and both ankles (footwear).
# Returns {"head", "torso", "foot_l", "foot_r"} -> Node3D; missing bones are skipped.
static func create_costume_mounts(character_mesh: Node) -> Dictionary:
	var mounts := {}
	var head := create_hat_mount(character_mesh)
	if head:
		mounts["head"] = head
	var skeleton := find_skeleton(character_mesh)
	if not skeleton:
		return mounts
	for entry in [["torso", "Spine2"], ["foot_l", "LeftFoot"], ["foot_r", "RightFoot"]]:
		var mount := create_bone_mount(skeleton, entry[1], entry[0].capitalize().replace(" ", "") + "Mount")
		if mount:
			mounts[entry[0]] = mount
	return mounts

# Attaches a node to a bone with the bone's rest rotation cancelled out, so children
# can be authored in character space (Y up, +Z forward) no matter how the bone is
# oriented — Mixamo foot bones point down-and-forward, for example. The node still
# follows the bone when it moves.
static func create_bone_mount(skeleton: Skeleton3D, bone: String, mount_name: String) -> Node3D:
	var idx := skeleton.find_bone("mixamorig_" + bone)
	if idx < 0:
		idx = skeleton.find_bone("mixamorig:" + bone)
	if idx < 0:
		push_warning("CharacterRig: bone %s not found" % bone)
		return null
	var attach := BoneAttachment3D.new()
	attach.name = mount_name + "Attach"
	attach.bone_idx = idx
	skeleton.add_child(attach)
	var mount := Node3D.new()
	mount.name = mount_name
	mount.basis = skeleton.get_bone_global_rest(idx).basis.orthonormalized().inverse()
	attach.add_child(mount)
	return mount

# Dresses a racer in a full costume (hat + torso + footwear), keyed by hat_type.
# An empty hat_type strips everything.
static func apply_costume(mounts: Dictionary, hat_type: String, hat_color: Color) -> void:
	for key in mounts:
		for child in mounts[key].get_children():
			child.queue_free()
	if hat_type.is_empty():
		return
	if mounts.has("head"):
		for mi in HatBuilder.make_meshes(hat_type, hat_color, 1.0):
			mounts["head"].add_child(mi)
	if mounts.has("torso"):
		for mi in CostumeBuilder.make_torso(hat_type):
			mounts["torso"].add_child(mi)
	for key in ["foot_l", "foot_r"]:
		if mounts.has(key):
			for mi in CostumeBuilder.make_foot(hat_type):
				mounts[key].add_child(mi)

static func apply_skin_color(body_mesh: MeshInstance3D, color: Color) -> void:
	if not body_mesh:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.7
	body_mesh.set_surface_override_material(0, mat)
