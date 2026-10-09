extends Node2D

# FEVECO - Campeonato Nacional de Coleo Venezolano
# First playable prototype: menu, customization, stable/shop, tournament,
# touch controls, chase, timed tail-grab QTE and scoring.

const W := 1280.0
const H := 720.0
const BG := Color("#07111c")
const PANEL := Color("#10263a")
const PANEL2 := Color("#17344b")
const GOLD := Color("#f4c542")
const WHITE := Color("#f4f7fb")
const MUTED := Color("#9db1c4")
const RED := Color("#d83b45")
const GREEN := Color("#43d17b")
const SKY := Color("#36b9e8")
const DIRT := Color("#9a6844")
const SAVE_PATH := "user://feveco_save.json"

var screen := "menu"
var selected_club := 0
var selected_category := 0
var selected_tournament := 0
var selected_venue := 0
var championship_points := 0.0
var championship_turns := 0
var championship_round := 0
var player_championship_position := 0
var championship_status := "EN CURSO"
var rival_names := ["Los Llaneros", "Sota Fuerte", "El Relámpago", "Cabo e Soga", "La Vaquera", "Palma Real", "Los Bolívar", "San Miguel"]
var rival_clubs := ["Los Herederos del Llano", "Sota de Oro", "Club Tinaquillo", "Cabo e Soga", "La Vaquera", "Palma Real", "Los Bolívar", "San Miguel"]
var rival_skill := [0.93, 0.96, 0.90, 0.97, 0.88, 0.95, 0.86, 0.91]
var rival_points := [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var buttons: Array[Dictionary] = []
var player := Vector2(360, 380)
var bull := Vector2(700, 340)
var player_vel := Vector2.ZERO
var bull_vel := Vector2.ZERO
var turn_time := 35.0
var elapsed := 0.0
var score := 0.0
var total_score := 0.0
var qte_active := false
var qte_pos := Vector2.ZERO
var qte_radius := 92.0
var qte_speed := 75.0
var qte_result := ""
var qte_cooldown := 0.0
var grabbed := false
var selected_horse := 0
var selected_bull := 0
var skin := Color("#8a5a3b")
var hair := Color("#241812")
var beard := Color("#241812")
var hair_style := 0
var horse_colors := [Color("#7b3f22"), Color("#1b1b20"), Color("#c58a52"), Color("#b9b7ae"), Color("#7f5a37"), Color("#d4a45f")]
var horse_names := ["Alazán", "Negro", "Palomino", "Tordillo", "Zaino", "Bayo"]
var bull_colors := [Color("#302820"), Color("#5c4636"), Color("#181818"), Color("#765d47")]
var bull_names := ["Castaño", "Colorado", "Negro", "Barcino"]
var coins := 1500
var owned_horses := [true, false, false, false, false, false]
var combo := 0
var best_combo := 0
var skin_index := 1
var hair_style_index := 0
var beard_style_index := 0
var hair_color_index := 0
var beard_color_index := 0
var hat_index := 0
var shirt_index := 0
var joystick_active := false
var joystick_touch_id := -1
var joystick_vector := Vector2.ZERO
var joystick_center := Vector2(145, H-128)
var animation_state := "idle"
var animation_timer := 0.0
var animation_result := ""
var animation_score_popup := 0.0
var bull_fall_angle := 0.0
var bull_fall_offset := Vector2.ZERO
var round_turns := 0
var tournament_complete := false

# Datos inspirados en registros públicos de FEVECO para dar identidad venezolana al V1.
var association_index := 0
var association_names := [
	"Apure","Aragua","Barinas","Bolívar","Carabobo","Cojedes","Delta Amacuro",
	"Falcón","Guárico","Lara","Miranda","Monagas","Nueva Esparta","Portuguesa",
	"Sucre","Táchira","Trujillo","Yaracuy","Zulia","Amazonas","La Guaira","Distrito Capital"
]
var club_names := [
	"Club de Coleo Sota de Oro","Club de Coleo Tinaquillo","Club San Juan Bautista",
	"Club de Coleo Naranjeros de Carabobo","Club de Coleo UDS","Club de Coleo Lara",
	"Club Deportivo de Coleo Yocoima","Los Herederos del Llano"
]
var club_states := ["Cojedes","Cojedes","Bolívar","Carabobo","Carabobo","Lara","Bolívar","Apure"]
var club_categories := ["B / A / AA","B / Master","A","A / B / Femenino","A","AA / Destete","B / A","A"]
var venue_names := ["Manga Juan Canelón","Manga Don Pedro Maya"]
var tournament_names := [
	"Campeonato Categoría C","Copa 67 Aniversario","Copa Cheo Hernández Prisco",
	"Campeonato Categoría B","Campeonato Categoría A","Campeonato Categoría AA",
	"Campeonato Categoría Master","Campeonato Categoría Supermaster"
]
var category_names := ["C","B","A","AA","Master","Supermaster"]
var tournament_dates := ["05–07 DIC 2025","23–25 ENE 2026","20–22 FEB 2026","27–29 MAR 2026","24–26 ABR 2026","29–31 MAY 2026","18–20 SEP 2026","18–20 SEP 2026"]
var tournament_categories := ["C","C / B / A / AA","C / B / A / AA","B","A","AA","Master","Supermaster"]
var font: Font
var horse_sprite: Sprite2D
var bull_sprite: Sprite2D
var horse_texture: Texture2D
var bull_texture: Texture2D
var arena_bg_texture: Texture2D
var menu_bg_texture: Texture2D

func _ready():
	font = ThemeDB.fallback_font
	load_state()
	_setup_game_sprites()
	queue_redraw()

func _setup_game_sprites():
	# Cachear las ilustraciones una sola vez evita cargas repetidas durante el juego.
	horse_texture = _make_horse_pixel_texture()
	bull_texture = _make_bull_pixel_texture()
	arena_bg_texture = _make_arena_pixel_texture()
	menu_bg_texture = _make_arena_pixel_texture()
	horse_sprite = Sprite2D.new()
	horse_sprite.texture = horse_texture
	horse_sprite.centered = true
	horse_sprite.scale = Vector2(0.48,0.48)
	horse_sprite.z_index = 20
	horse_sprite.visible = false
	add_child(horse_sprite)
	bull_sprite = Sprite2D.new()
	bull_sprite.texture = bull_texture
	bull_sprite.centered = true
	bull_sprite.scale = Vector2(0.50,0.50)
	bull_sprite.z_index = 19
	bull_sprite.visible = false
	add_child(bull_sprite)

func _update_game_sprites():
	# Los sprites se dibujan dentro de draw_game para controlar el orden:
	# sombras -> partículas -> personajes -> interfaz, sin tapar los botones.
	if horse_sprite != null:
		horse_sprite.visible = false
	if bull_sprite != null:
		bull_sprite.visible = false

func draw_sprite_layer(texture:Texture2D, center:Vector2, scale_value:Vector2, rotation_value:float, tint:Color):
	if texture == null:
		return
	var sprite_size=texture.get_size()
	draw_set_transform(center,rotation_value,scale_value)
	draw_texture_rect(texture,Rect2(-sprite_size*0.5,sprite_size),false,tint)
	draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)

func draw_ground_shadow(center:Vector2, width:float, alpha:float):
	draw_ellipse(center+Vector2(0,57),Vector2(width,18),Color(0.025,0.018,0.012,alpha))
	draw_ellipse(center+Vector2(0,60),Vector2(width*0.68,9),Color(0.025,0.018,0.012,alpha*0.55))

func draw_dust_cloud(center:Vector2, phase:float, intensity:float):
	for i in range(12):
		var drift=fposmod(phase*36.0+i*31.0,95.0)
		var rise=fposmod(phase*21.0+i*17.0,32.0)
		var radius=2.0+float(i%4)*1.4
		var alpha=(0.08+float(i%3)*0.025)*intensity
		draw_circle(center+Vector2(-drift-16.0,-rise+float(i%3)*5.0),radius,Color(0.96,0.76,0.53,alpha))


func save_state():
	var data = {
		"coins": coins,
		"owned_horses": owned_horses,
		"combo": combo,
		"best_combo": best_combo,
		"selected_horse": selected_horse,
		"selected_bull": selected_bull,
		"skin_index": skin_index,
		"hair_style_index": hair_style_index,
		"beard_style_index": beard_style_index,
		"hair_color_index": hair_color_index,
		"beard_color_index": beard_color_index,
		"hat_index": hat_index,
		"shirt_index": shirt_index,
		"selected_club": selected_club,
		"selected_category": selected_category,
		"selected_tournament": selected_tournament,
		"selected_venue": selected_venue,
		"association_index": association_index,
		"championship_points": championship_points,
		"championship_turns": championship_turns,
		"championship_round": championship_round,
		"total_score": total_score,
		"rival_points": rival_points
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func load_state():
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	coins = int(parsed.get("coins", coins))
	var saved_horses = parsed.get("owned_horses", owned_horses)
	if saved_horses is Array:
		for i in range(min(saved_horses.size(), owned_horses.size())):
			owned_horses[i] = bool(saved_horses[i])
	combo = int(parsed.get("combo", combo))
	best_combo = int(parsed.get("best_combo", best_combo))
	selected_horse = int(parsed.get("selected_horse", selected_horse))
	selected_bull = int(parsed.get("selected_bull", selected_bull))
	skin_index = int(parsed.get("skin_index", skin_index))
	hair_style_index = int(parsed.get("hair_style_index", hair_style_index))
	beard_style_index = int(parsed.get("beard_style_index", beard_style_index))
	hair_color_index = int(parsed.get("hair_color_index", hair_color_index))
	beard_color_index = int(parsed.get("beard_color_index", beard_color_index))
	hat_index = int(parsed.get("hat_index", hat_index))
	shirt_index = int(parsed.get("shirt_index", shirt_index))
	selected_club = int(parsed.get("selected_club", selected_club))
	selected_category = int(parsed.get("selected_category", selected_category))
	selected_tournament = int(parsed.get("selected_tournament", selected_tournament))
	selected_venue = int(parsed.get("selected_venue", selected_venue))
	association_index = int(parsed.get("association_index", association_index))
	championship_points = float(parsed.get("championship_points", championship_points))
	championship_turns = int(parsed.get("championship_turns", championship_turns))
	championship_round = int(parsed.get("championship_round", championship_round))
	total_score = float(parsed.get("total_score", total_score))
	var saved_rivals = parsed.get("rival_points", [])
	if saved_rivals is Array:
		for i in range(min(saved_rivals.size(), rival_points.size())):
			rival_points[i] = float(saved_rivals[i])
	_apply_custom_colors()

func _process(delta):
	if screen == "game":
		update_game(delta)
	_update_game_sprites()
	if animation_timer > 0.0:
		animation_timer=max(0.0,animation_timer-delta)
		if (animation_state=="fall" or animation_state=="miss") and animation_timer <= 0.0:			animation_state="idle"
			bull_fall_angle=0.0
			bull_fall_offset=Vector2.ZERO
			grabbed=false
			qte_cooldown=0.8
	queue_redraw()

func _apply_custom_colors():
	var skins=[Color("#3d2418"),Color("#6b4028"),Color("#8a5a3b"),Color("#ad744a"),Color("#c88758"),Color("#e0a979")]
	var hc=[Color("#17110e"),Color("#3b2115"),Color("#6b3c20"),Color("#9a5728"),Color("#c08a3d"),Color("#d7b16a")]
	skin = skins[clamp(skin_index,0,skins.size()-1)]
	hair = hc[clamp(hair_color_index,0,hc.size()-1)]
	beard = hc[clamp(beard_color_index,0,hc.size()-1)]

func update_joystick(p: Vector2):
	var delta=p-joystick_center
	if delta.length()>88.0:
		delta=delta.normalized()*88.0
	joystick_vector=delta/88.0
	player_vel=joystick_vector*215.0

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			if screen == "game" and event.position.x < 360 and event.position.y > H-270:
				joystick_active=true
				joystick_touch_id=event.index
				update_joystick(event.position)
			else:
				handle_touch(event.position)
		elif event.index == joystick_touch_id:
			joystick_active=false
			joystick_touch_id=-1
			joystick_vector=Vector2.ZERO
	elif event is InputEventScreenDrag and screen == "game" and event.index == joystick_touch_id:
		update_joystick(event.position)
	elif event is InputEventMouseButton and event.pressed:
		handle_touch(event.position)
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			screen = "menu"
		if screen == "game" and event.keycode == KEY_SPACE:
			try_grab()

func handle_touch(p: Vector2):
	if screen == "game":
		if Rect2(40,35,175,58).has_point(p):
			activate_button("game_menu")
			return
		if Rect2(225,35,175,58).has_point(p):
			activate_button("game_exit")
			return
		if Rect2(1080,H-235,150,92).has_point(p):
			player_vel.x=min(280.0,player_vel.x+95.0)
		elif Rect2(930,H-145,135,95).has_point(p):
			player_vel.x=max(0.0,player_vel.x-120.0)
		elif Rect2(1040,H-175,205,145).has_point(p):
			# Primer toque: iniciar la maniobra. Segundo toque: ejecutar el agarre.
			# Antes se iniciaba el QTE y se evaluaba en el mismo toque, causando FALLO inmediato.
			if qte_active:
				try_grab()
			elif not grabbed and player.distance_to(bull) < 220.0 and qte_cooldown <= 0.0:
				qte_active=true
				qte_pos=Vector2(clamp(bull.x-95,360,980),clamp(bull.y-90,220,500))
				qte_radius=92.0
				qte_speed=[68.0,74.0,84.0,78.0][selected_bull]
				qte_result=""
		return
	for b in buttons:
		if Rect2(b.pos,b.size).has_point(p):
			activate_button(b.id)
			return

func activate_button(id: String):
	match id:
		"play":
			start_game()
		"horses":
			screen="horses"
		"bulls":
			screen="bulls"
		"coleadores":
			screen="custom"
		"clubs":
			screen="clubs"
		"tournaments":
			screen="tournaments"
		"shop":
			screen="shop"
		"profile":
			screen="profile"
		"settings":
			screen="settings"
		"music":
			screen="music"
		"back":
			screen="menu"
			joystick_active=false
			joystick_touch_id=-1
			joystick_vector=Vector2.ZERO
		"game_menu":
			screen="menu"
			joystick_active=false
			joystick_touch_id=-1
			joystick_vector=Vector2.ZERO
			player_vel=Vector2.ZERO
			qte_active=false
			grabbed=false
		"game_exit":
			screen="tournaments"
			joystick_active=false
			joystick_touch_id=-1
			joystick_vector=Vector2.ZERO
			player_vel=Vector2.ZERO
			qte_active=false
			grabbed=false
		"next_horse":
			selected_horse=(selected_horse+1)%horse_names.size()
			horse_texture=_make_horse_pixel_texture()
			horse_sprite.texture=horse_texture
		"prev_horse":
			selected_horse=(selected_horse-1+horse_names.size())%horse_names.size()
			horse_texture=_make_horse_pixel_texture()
			horse_sprite.texture=horse_texture
		"buy_horse":
			if owned_horses[selected_horse]:
				pass
			elif coins >= 500:
				coins -= 500
				owned_horses[selected_horse] = true
		"next_bull":
			selected_bull=(selected_bull+1)%bull_names.size()
			bull_texture=_make_bull_pixel_texture()
			bull_sprite.texture=bull_texture
		"prev_bull":
			selected_bull=(selected_bull-1+bull_names.size())%bull_names.size()
			bull_texture=_make_bull_pixel_texture()
			bull_sprite.texture=bull_texture
		"skin":
			skin_index=(skin_index+1)%6
			var skins=[Color("#3d2418"),Color("#6b4028"),Color("#8a5a3b"),Color("#ad744a"),Color("#c88758"),Color("#e0a979")]
			skin=skins[skin_index]
		"hair":
			hair_style_index=(hair_style_index+1)%6
		"beard":
			beard_style_index=(beard_style_index+1)%6
		"hair_color":
			hair_color_index=(hair_color_index+1)%6
			var hc=[Color("#17110e"),Color("#3b2115"),Color("#6b3c20"),Color("#9a5728"),Color("#c08a3d"),Color("#d7b16a")]
			hair=hc[hair_color_index]
		"beard_color":
			beard_color_index=(beard_color_index+1)%6
			var bc=[Color("#17110e"),Color("#3b2115"),Color("#6b3c20"),Color("#9a5728"),Color("#c08a3d"),Color("#d7b16a")]
			beard=bc[beard_color_index]
		"hat":
			hat_index=(hat_index+1)%5
		"shirt":
			shirt_index=(shirt_index+1)%6
		"association":
			association_index=(association_index+1)%association_names.size()
		"next_club":
			selected_club=(selected_club+1)%club_names.size()
		"prev_club":
			selected_club=(selected_club-1+club_names.size())%club_names.size()
		"next_category":
			selected_category=(selected_category+1)%category_names.size()
			validate_championship_selection()
		"prev_category":
			selected_category=(selected_category-1+category_names.size())%category_names.size()
			validate_championship_selection()
		"next_tournament":
			selected_tournament=(selected_tournament+1)%tournament_names.size()
			validate_championship_selection()
		"prev_tournament":
			selected_tournament=(selected_tournament-1+tournament_names.size())%tournament_names.size()
			validate_championship_selection()
		"next_venue":
			selected_venue=(selected_venue+1)%venue_names.size()
		"prev_venue":
			selected_venue=(selected_venue-1+venue_names.size())%venue_names.size()
		"venue":
			selected_venue=(selected_venue+1)%venue_names.size()
		"reset_campaign":
			reset_campaign()
		"start_championship":
			start_game()
	save_state()

func start_game():
	validate_championship_selection()
	if tournament_complete:
		reset_campaign()
	screen="game"
	elapsed=0
	score=0
	championship_turns += 1
	grabbed=false
	qte_active=false
	qte_result=""
	combo=0
	player=Vector2(320,390)
	bull=Vector2(820,360)
	var horse_speed=[1.10,0.96,1.04,0.92,1.07,1.12][selected_horse]
	var bull_speed=[55.0,62.0,70.0,66.0][selected_bull]
	player_vel=Vector2(120*horse_speed,0)
	bull_vel=Vector2(bull_speed,0)
	championship_status="EN CURSO"
	animation_state="ride"
	animation_timer=0.0
	animation_result=""
	round_turns += 1
	save_state()

func update_game(delta):
	elapsed += delta
	qte_cooldown=max(0.0,qte_cooldown-delta)
	var move=Input.get_vector("move_left","move_right","move_up","move_down")
	if move.length()>0:
		var horse_control=[1.08,0.94,1.02,0.90,1.05,1.10][selected_horse]
		player_vel=move*190.0*horse_control
	elif player_vel.length()>0:
		player_vel=player_vel.move_toward(Vector2.ZERO,75.0*delta)
	if Input.is_action_pressed("action_accel"):
		player_vel += Vector2(65,0)*delta
	player_vel.x=clamp(player_vel.x,-80,260)
	player += player_vel*delta
	bull += bull_vel*delta
	player.x=clamp(player.x,120,1050)
	player.y=clamp(player.y,190,570)
	if bull.x > 1110:
		bull.x=180
		bull.y=randf_range(240,520)
	var tail_point=bull+Vector2(-145,0)
	var distance=player.distance_to(tail_point)
	if distance < 155 and not qte_active and qte_cooldown<=0 and not grabbed:
		qte_active=true
		qte_pos=Vector2(clamp(tail_point.x+20,360,980),clamp(tail_point.y-75,220,500))
		qte_radius=92
		qte_speed=[68.0,74.0,84.0,78.0][selected_bull]
		qte_result=""
	if qte_active:
		qte_radius=max(18,qte_radius-qte_speed*delta)
		if qte_radius <= 18.0:
			resolve_grab("FALLO",0.0,false)
	if animation_state=="fall":
		# Caída mucho más visible: el toro se inclina de lado y baja hasta la arena.
		var fall_progress=clamp((1.8-animation_timer)/0.42,0.0,1.0)
		bull_fall_angle=-1.28*fall_progress
		bull_fall_offset=Vector2(0,fall_progress*62.0)
	elif grabbed:
		bull += Vector2(120,0)*delta
		player += Vector2(95,0)*delta
	if qte_active and Input.is_action_just_pressed("action_grab"):
		try_grab()
	if elapsed >= turn_time:
		finish_championship_turn()
		screen="result"
		save_state()
func validate_championship_selection():
	# Los torneos nacionales por categoría solo aceptan categorías compatibles.
	var allowed=tournament_categories[selected_tournament].split(" / ")
	var wanted=category_names[selected_category]
	if wanted not in allowed:
		if allowed.size() > 0:
			for i in range(category_names.size()):
				if category_names[i] == allowed[0]:
					selected_category=i
					break

func reset_campaign():
	championship_points=0.0
	championship_turns=0
	championship_round=0
	round_turns=0
	tournament_complete=false
	player_championship_position=0
	championship_status="EN CURSO"
	for i in range(rival_points.size()):
		rival_points[i]=0.0
	screen="tournaments"
	save_state()

func finish_championship_turn():
	total_score += score
	championship_points += score * 10.0
	# CPU fuerte e independiente: cada rival obtiene su propia actuación.
	for i in range(rival_points.size()):
		var performance=randf_range(2.4, 5.2) * rival_skill[i]
		if i == 3:
			performance += 0.6
		rival_points[i] += performance
	var table=[]
	table.append({"name":"TÚ • "+club_names[selected_club],"points":championship_points,"player":true})
	for i in range(rival_names.size()):
		table.append({"name":rival_names[i]+" • "+rival_clubs[i],"points":rival_points[i],"player":false})
	table.sort_custom(func(a,b): return a.points > b.points)
	player_championship_position=1
	for row in range(table.size()):
		if table[row].player:
			player_championship_position=row+1
			break
	if player_championship_position > 4:
		championship_status="ELIMINADO"
		tournament_complete=true
	elif championship_round < 2:
		if round_turns >= 2:
			championship_round += 1
			round_turns=0
			championship_status="CLASIFICADO"
		else:
			championship_status="EN CURSO"
	else:
		championship_status="CAMPEÓN" if player_championship_position == 1 else ("PODIO" if player_championship_position <= 3 else "FINALISTA")
		tournament_complete=true

func get_round_name()->String:
	if championship_round == 0:
		return "CLASIFICACIÓN"
	if championship_round == 1:
		return "SEMIFINAL"
	return "FINAL"

func get_championship_table()->Array:
	var table=[]
	table.append({"name":"TÚ • "+club_names[selected_club],"points":championship_points,"player":true})
	for i in range(rival_names.size()):
		table.append({"name":rival_names[i],"points":rival_points[i],"player":false})
	table.sort_custom(func(a,b): return a.points > b.points)
	return table

func try_grab():
	if not qte_active:
		return
	var perfect_min=34.0
	var good_min=52.0
	var regular_min=70.0
	if qte_radius <= perfect_min:
		resolve_grab("¡COLEO PERFECTO!",3.5,true)
	elif qte_radius <= good_min:
		resolve_grab("¡COLEO BUENO!",2.5,true)
	elif qte_radius <= regular_min:
		resolve_grab("COLEO REGULAR",1.5,true)
	else:
		resolve_grab("FALLO",0.0,false)

func resolve_grab(result:String, points:float, success:bool):
	if not qte_active and result=="FALLO":
		return
	qte_active=false
	qte_cooldown=1.5
	qte_result=result
	if success:
		combo += 1
		best_combo=max(best_combo,combo)
		points += min(2.0, float(combo-1)*0.25)
	else:
		combo=0
	score += points
	animation_result=result
	animation_score_popup=points
	if success:
		grabbed=true
		animation_state="fall"
		animation_timer=1.8
		bull_fall_angle=0.0
		bull_fall_offset=Vector2.ZERO
	else:
		grabbed=false
		animation_state="miss"
		animation_timer=0.9

func draw_button(rect:Rect2, label:String, id:String, accent:=Color("#17344b")):
	buttons.append({"id":id,"pos":rect.position,"size":rect.size})
	# Botón con sombra, borde luminoso y una pestaña de color para dar profundidad.
	draw_rect(Rect2(rect.position+Vector2(0,5),rect.size),Color(0.0,0.0,0.0,0.34),true)
	draw_rect(rect,accent,true)
	draw_rect(Rect2(rect.position+Vector2(2,2),Vector2(max(0.0,rect.size.x-4),4)),Color(1,1,1,0.13),true)
	draw_rect(Rect2(rect.position,Vector2(6,rect.size.y)),GOLD if id=="play" or id=="start_championship" else Color("#2f6075"),true)
	draw_rect(rect,Color("#668a9b"),false,2)
	draw_string(font,rect.position+Vector2(18,rect.size.y*0.63),label,HORIZONTAL_ALIGNMENT_CENTER,rect.size.x-36,24,WHITE)

func _draw():
	buttons.clear()
	draw_rect(Rect2(0,0,W,H),BG)
	match screen:
		"menu": draw_menu()
		"game": draw_game()
		"result": draw_result()
		"horses": draw_horses()
		"bulls": draw_bulls()
		"custom": draw_custom()
		"clubs": draw_clubs()
		"tournaments": draw_tournaments()
		"shop": draw_shop()
		"profile": draw_profile()
		"settings": draw_settings()
		"music": draw_music()

func title(text:String, y:=70.0, size:=44):
	draw_string(font,Vector2(0,y),text,HORIZONTAL_ALIGNMENT_CENTER,W,size,WHITE)

func draw_menu():
	# Portada cinematográfica con una manga ilustrada en pantalla completa.
	if menu_bg_texture != null:
		draw_texture_rect(menu_bg_texture,Rect2(0,0,W,H),false)
	else:
		draw_rect(Rect2(0,0,W,H),Color("#06101a"),true)
	# Oscurecer el lateral izquierdo para que el menú y los textos siempre destaquen.
	draw_rect(Rect2(0,0,590,H),Color(0.015,0.045,0.075,0.82),true)
	draw_rect(Rect2(590,0,690,H),Color(0.015,0.045,0.075,0.20),true)
	
	# Luces de estadio
	draw_circle(Vector2(1110,90),170,Color(0.25,0.75,0.9,0.07))
	draw_circle(Vector2(160,620),190,Color(0.95,0.55,0.15,0.05))
	for i in range(8):
		var beam_x=520+i*92
		draw_line(Vector2(beam_x,0),Vector2(beam_x+110,235),Color(0.7,0.9,1.0,0.035),2)
	
	# Marca
	draw_string(font,Vector2(48,62),"FEVECO",HORIZONTAL_ALIGNMENT_LEFT,-1,48,GOLD)
	draw_string(font,Vector2(51,91),"CAMPEONATO NACIONAL DE COLEO VENEZOLANO",HORIZONTAL_ALIGNMENT_LEFT,-1,16,MUTED)
	
	# Encabezado de temporada
	draw_rect(Rect2(48,120,520,82),Color(0.02,0.07,0.10,0.88),true)
	draw_rect(Rect2(48,120,520,82),Color("#284b5e"),false,2)
	draw_string(font,Vector2(72,151),"LA MANGA TE ESPERA",HORIZONTAL_ALIGNMENT_LEFT,-1,20,WHITE)
	draw_string(font,Vector2(72,183),"DOMINA EL TIEMPO. AGARRA LA COLA.",HORIZONTAL_ALIGNMENT_LEFT,-1,25,GOLD)
	
	# Panel protagonista
	draw_rect(Rect2(590,38,642,560),Color("#0c202d"),true)
	draw_rect(Rect2(590,38,642,560),Color("#36566a"),false,3)
	draw_rect(Rect2(612,60,598,330),Color("#17323d"),true)
	
	# Mini manga dentro de portada
	draw_rect(Rect2(612,60,598,330),Color("#4e7180"),true)
	draw_rect(Rect2(612,205,598,185),Color("#9a6844"),true)
	draw_rect(Rect2(612,193,598,14),Color("#e2d5a5"),true)
	for i in range(12):
		var sx=630+i*49
		draw_line(Vector2(sx,132),Vector2(sx,198),Color("#d7cfad"),3)
		draw_circle(Vector2(sx,126),8,Color("#d83b45") if i%3==0 else Color("#eee6c9"))
	for i in range(17):
		draw_circle(Vector2(625+i*34,178+(i%3)*5),4,Color("#d7dde0"))
	
	# Ilustraciones de caballo/coleador y toro de alta resolución.
	if horse_texture != null:
		draw_texture_rect(horse_texture,Rect2(690,175,300,205),false)
	else:
		draw_character(Vector2(850,300),horse_colors[selected_horse],skin,hair,beard)
	if bull_texture != null:
		draw_texture_rect(bull_texture,Rect2(925,190,270,190),false)
	else:
		draw_bull(Vector2(1025,294),bull_colors[selected_bull])
	draw_line(Vector2(930,287),Vector2(988,290),Color("#e8c27a"),4)
	
	# QTE decorativo
	draw_circle(Vector2(1065,145),43,Color(0.95,0.78,0.18,0.12))
	draw_arc(Vector2(1065,145),43,0,TAU,48,GOLD,5)
	draw_circle(Vector2(1065,145),13,WHITE)
	draw_string(font,Vector2(988,96),"AGARRA LA COLA",HORIZONTAL_ALIGNMENT_CENTER,154,17,GOLD)
	
	# Nombre del juego dentro de la portada
	draw_string(font,Vector2(650,440),"COLEO",HORIZONTAL_ALIGNMENT_LEFT,-1,48,WHITE)
	draw_string(font,Vector2(650,478),"VENEZOLANO",HORIZONTAL_ALIGNMENT_LEFT,-1,28,GOLD)
	draw_string(font,Vector2(650,513),"Una manga. Un caballo. Una oportunidad.",HORIZONTAL_ALIGNMENT_LEFT,-1,18,MUTED)
	
	# Menú principal en dos columnas
	draw_button(Rect2(48,235,255,68),"JUGAR","play",RED)
	draw_button(Rect2(315,235,255,68),"CABALLOS","horses",PANEL2)
	draw_button(Rect2(48,315,255,60),"COLEADORES","coleadores",PANEL2)
	draw_button(Rect2(315,315,255,60),"TOROS","bulls",PANEL2)
	draw_button(Rect2(48,387,255,60),"TORNEOS","tournaments",PANEL2)
	draw_button(Rect2(315,387,255,60),"TIENDA","shop",PANEL2)
	draw_button(Rect2(48,459,255,60),"PERFIL","profile",PANEL2)
	draw_button(Rect2(315,459,255,60),"MÚSICA","music",PANEL2)
	draw_button(Rect2(48,531,255,60),"CLUBES","clubs",PANEL2)
	draw_button(Rect2(315,531,255,60),"AJUSTES","settings",PANEL2)
	
	# Pie de navegación
	draw_string(font,Vector2(48,616),"ANDROID  •  V1",HORIZONTAL_ALIGNMENT_LEFT,-1,16,MUTED)
	draw_string(font,Vector2(315,616),"●  EN DESARROLLO",HORIZONTAL_ALIGNMENT_LEFT,-1,15,GREEN)
	
	# Perfil rápido
	draw_rect(Rect2(612,535,598,48),Color(0.02,0.06,0.08,0.78),true)
	draw_string(font,Vector2(635,566),"COLEADOR NOVATO",HORIZONTAL_ALIGNMENT_LEFT,-1,16,WHITE)
	draw_string(font,Vector2(900,566),"MONEDAS  %d"%coins,HORIZONTAL_ALIGNMENT_LEFT,-1,16,GOLD)
	draw_string(font,Vector2(1060,566),"● ONLINE",HORIZONTAL_ALIGNMENT_LEFT,-1,15,GREEN)


func draw_manga_preview(pos:Vector2,size:Vector2):
	draw_rect(Rect2(pos,size),Color("#1c3440"),true)
	draw_rect(Rect2(pos+Vector2(18,18),size-Vector2(36,36)),Color("#9b6b43"),true)
	for i in range(10):
		draw_line(pos+Vector2(25+i*40,25),pos+Vector2(25+i*40,55),Color("#b7b7a4"),4)
	draw_circle(pos+Vector2(170,145),42,horse_colors[selected_horse])
	draw_circle(pos+Vector2(265,135),31,bull_colors[selected_bull])
	draw_line(pos+Vector2(180,160),pos+Vector2(250,145),Color("#e8c27a"),5)
	draw_string(font,pos+Vector2(105,255),"MANGA DE COLEO",HORIZONTAL_ALIGNMENT_LEFT,-1,20,WHITE)

func draw_game():
	# La manga se pinta PRIMERO. Antes el fondo se dibujaba encima de los botones,
	# ocultando la navegación y haciendo que la arena pareciera no responder.
	if arena_bg_texture != null:
		draw_texture_rect(arena_bg_texture,Rect2(0,0,W,H),false)
	else:
		draw_rect(Rect2(0,0,W,H),Color("#95613f"),true)
		draw_rect(Rect2(0,0,W,250),Color("#527f91"),true)		draw_rect(Rect2(0,250,W,70),Color("#354b46"),true)
	# La manga siempre conserva su profundidad y el HUD queda por encima del fondo.
	# HUD premium.
	draw_rect(Rect2(20,14,455,52),Color(0.02,0.06,0.09,0.76),true)
	draw_rect(Rect2(20,14,455,52),Color("#e7c756"),false,2)
	draw_string(font,Vector2(38,47),"FEVECO  •  MANGA DE COLEO",HORIZONTAL_ALIGNMENT_LEFT,-1,21,WHITE)
	draw_rect(Rect2(900,14,330,52),Color(0.02,0.06,0.09,0.76),true)
	draw_string(font,Vector2(925,47),"PUNTOS  %.0f"%score,HORIZONTAL_ALIGNMENT_LEFT,-1,22,GOLD)
	draw_string(font,Vector2(1100,47),"%.0f s"%max(0.0,turn_time-elapsed),HORIZONTAL_ALIGNMENT_LEFT,-1,21,WHITE)
	draw_rect(Rect2(25,202,290,58),Color(0.02,0.06,0.09,0.82),true)
	draw_rect(Rect2(25,202,290,58),Color("#d8b94f"),false,2)
	draw_string(font,Vector2(45,238),"TURNO  •  COLEO VENEZOLANO",HORIZONTAL_ALIGNMENT_LEFT,-1,18,GOLD)
	var gait_phase=elapsed*12.0
	var gait=sin(gait_phase)
	var rider_bob=sin(gait_phase)*4.0
	var rider_pos=player+Vector2(0,rider_bob)
	if player_vel.length()>25.0:
		rider_pos += Vector2(0,abs(sin(gait_phase))*3.0)
	if animation_state=="miss":
		rider_pos += Vector2(-sin(elapsed*18.0)*8.0,abs(sin(elapsed*18.0))*3.0)
	var bull_pos=bull+bull_fall_offset
	if animation_state=="miss":
		bull_pos += Vector2(sin(elapsed*16.0)*4.0,0)
	# Renderizado por capas: sombras suaves, polvo animado, sprites y finalmente HUD.
	draw_ground_shadow(rider_pos,142.0,0.34)
	draw_ground_shadow(bull_pos,112.0,0.31 if animation_state!="fall" else 0.20)
	if player_vel.length()>45.0:
		draw_dust_cloud(rider_pos+Vector2(-35,48),elapsed,1.0)
	if abs(bull_vel.x)>25.0 and animation_state!="fall":
		draw_dust_cloud(bull_pos+Vector2(-25,46),elapsed+1.7,0.75)
	if animation_state=="fall":
		draw_dust_cloud(bull_pos+Vector2(-25,52),elapsed*1.8,1.65)
	# Sombras y polvo quedan debajo de los personajes; los sprites nunca tapan el HUD.
	var horse_gait_scale=Vector2(2.55+abs(gait)*0.07,2.45-abs(gait)*0.05)
	if grabbed:
		horse_gait_scale*=1.04+sin(elapsed*18.0)*0.025
	var horse_tint=Color.WHITE # Conserva los degradados y detalles originales del arte.
	var horse_rotation=clamp(-player_vel.y/1800.0,-0.10,0.10)
	draw_sprite_layer(horse_texture,rider_pos,horse_gait_scale,horse_rotation,horse_tint)
	var bull_tint=Color.WHITE # No teñir toda la anatomía: mantiene luces, hocico y cuernos naturales.
	var bull_rotation=bull_fall_angle
	if animation_state=="fall":
		bull_rotation=-1.42*clamp((1.8-animation_timer)/0.42,0.0,1.0)
		draw_sprite_layer(bull_texture,bull_pos,Vector2(2.70,2.70),bull_rotation,bull_tint)
	else:
		draw_sprite_layer(bull_texture,bull_pos,Vector2(2.70,2.70),0.0,bull_tint)
	if qte_active:
		draw_circle(qte_pos,qte_radius+10,Color(1,0.76,0.16,0.08))
		draw_arc(qte_pos,qte_radius,0,TAU,72,GOLD,8)
		draw_arc(qte_pos,34,0,TAU,64,WHITE,4)
		draw_circle(qte_pos,13,Color("#fff4c7"))
		draw_string(font,qte_pos+Vector2(-105,-qte_radius-18),"¡AGARRA LA COLA!",HORIZONTAL_ALIGNMENT_CENTER,210,20,GOLD)
	if animation_state=="miss":
		draw_rect(Rect2(390,96,500,66),Color(0.25,0.02,0.02,0.88),true)
		draw_string(font,Vector2(390,139),"¡FALLO!  INTÉNTALO DE NUEVO",HORIZONTAL_ALIGNMENT_CENTER,500,30,WHITE)
	elif animation_state=="fall":
		draw_rect(Rect2(390,96,500,66),Color(0.02,0.09,0.10,0.88),true)
		draw_string(font,Vector2(390,139),animation_result,HORIZONTAL_ALIGNMENT_CENTER,500,32,GOLD)
		draw_string(font,Vector2(545,178),"+"+("%.1f"%animation_score_popup)+" PUNTOS",HORIZONTAL_ALIGNMENT_CENTER,190,20,WHITE)
	# Controles limpios.
	draw_circle(joystick_center,112,Color(0.01,0.03,0.05,0.88))
	draw_arc(joystick_center,112,0,TAU,64,Color("#b5c7cd"),4)
	var knob=joystick_center+joystick_vector*72.0
	draw_circle(knob,55,Color("#183b4d"))
	draw_arc(knob,55,0,TAU,48,Color("#e5cb72"),3)
	draw_string(font,knob+Vector2(-48,7),"MOVER",HORIZONTAL_ALIGNMENT_CENTER,96,16,WHITE)
	draw_circle(Vector2(995,H-190),58,Color("#162b36"))
	draw_arc(Vector2(995,H-190),58,0,TAU,48,GOLD,4)
	draw_string(font,Vector2(940,H-197),"FRENAR",HORIZONTAL_ALIGNMENT_CENTER,110,15,WHITE)
	draw_circle(Vector2(1125,H-190),72,Color("#a92d35"))
	draw_circle(Vector2(1125,H-190),61,Color("#7d222b"))
	draw_arc(Vector2(1125,H-190),72,0,TAU,64,Color("#f5d66d"),6)
	draw_arc(Vector2(1125,H-190),52,-1.2,1.2,24,Color("#ffffff"),3)
	draw_string(font,Vector2(1055,H-199),"AGARRAR",HORIZONTAL_ALIGNMENT_CENTER,140,18,WHITE)
	draw_string(font,Vector2(1055,H-171),"COLA",HORIZONTAL_ALIGNMENT_CENTER,140,15,GOLD)
	draw_rect(Rect2(920,H-95,300,48),Color(0.02,0.06,0.09,0.88),true)
	draw_string(font,Vector2(940,H-64),"ACELERAR  ▶",HORIZONTAL_ALIGNMENT_LEFT,-1,18,WHITE)
	# Dibujar la navegación al final garantiza que nunca quede tapada por el fondo.
	draw_button(Rect2(40,35,175,58),"‹  MENÚ","game_menu",Color("#16374b"))
	draw_button(Rect2(225,35,175,58),"SALIR","game_exit",Color("#4a2730"))


func draw_speed_dust(p:Vector2):
	for i in range(20):
		var off=Vector2(-48-i*9,28+(i%5)*7)
		draw_circle(p+off,2+(i%4),Color(0.98,0.82,0.58,0.11+(i%4)*0.025))


func draw_character(p:Vector2,hc:Color,sc:Color,hairc:Color,beardc:Color):
	draw_ellipse(p+Vector2(8,51),Vector2(96,20),Color(0.03,0.02,0.015,0.38))
	var dark=hc.darkened(0.38)
	var leg_swing=sin(elapsed*12.0)*7.0 if screen=="game" else 0.0
	var leg_xs=[-44.0,-16.0,18.0,48.0]
	for i in range(4):
		var x=leg_xs[i]
		var swing=leg_swing if i%2==0 else -leg_swing
		draw_line(p+Vector2(x,12),p+Vector2(x+swing*0.35,48),dark,11)
		draw_line(p+Vector2(x+swing*0.35,44),p+Vector2(x-7+swing,61),hc.darkened(0.18),8)
		draw_rect(Rect2(p+Vector2(x-11+swing,58),Vector2(20,8)),Color("#141313"),true)
	draw_ellipse(p+Vector2(-2,7),Vector2(80,39),hc.darkened(0.08))
	draw_ellipse(p+Vector2(-24,-2),Vector2(54,25),hc.lightened(0.18))
	draw_poly(PackedVector2Array([p+Vector2(30,15),p+Vector2(46,-28),p+Vector2(60,-70),p+Vector2(88,-69),p+Vector2(100,-40),p+Vector2(73,-7),p+Vector2(60,20)]),PackedColorArray([hc,hc.lightened(0.14),hc,hc.darkened(0.08),hc,hc,hc]))
	draw_ellipse(p+Vector2(84,-54),Vector2(28,22),hc.lightened(0.10))
	draw_ellipse(p+Vector2(105,-45),Vector2(19,14),hc.lightened(0.16))
	draw_circle(p+Vector2(113,-43),4,Color("#111"))
	draw_circle(p+Vector2(114,-44),1.5,WHITE)
	draw_poly(PackedVector2Array([p+Vector2(67,-68),p+Vector2(67,-98),p+Vector2(83,-71)]),PackedColorArray([hc,hc.lightened(0.1),hc]))
	draw_poly(PackedVector2Array([p+Vector2(88,-69),p+Vector2(105,-94),p+Vector2(101,-58)]),PackedColorArray([hc.darkened(0.05),hc,hc]))
	for i in range(8):
		draw_line(p+Vector2(43+i*6,-58-i*2),p+Vector2(30+i*5,-38+i*2),hairc,5)
	draw_poly(PackedVector2Array([p+Vector2(-40,-17),p+Vector2(25,-18),p+Vector2(31,-4),p+Vector2(-32,0)]),PackedColorArray([Color("#5e321f"),Color("#9b6036"),Color("#6e3b23"),Color("#41251b")]))
	draw_rect(Rect2(p+Vector2(-25,-4),Vector2(49,9)),Color("#d9ae58"),true)
	draw_line(p+Vector2(-7,-2),p+Vector2(-7,29),Color("#2b211c"),5)
	var shirts=[Color("#254f70"),Color("#b72f3d"),Color("#1e7055"),Color("#d3a43f"),Color("#5c3c8c"),Color("#e5e0d4")]
	draw_line(p+Vector2(-10,-25),p+Vector2(-18,10),Color("#20252b"),9)
	draw_line(p+Vector2(12,-25),p+Vector2(28,10),Color("#20252b"),9)
	draw_poly(PackedVector2Array([p+Vector2(-24,-58),p+Vector2(20,-58),p+Vector2(16,-25),p+Vector2(-17,-25)]),PackedColorArray([shirts[shirt_index],shirts[shirt_index].lightened(0.12),shirts[shirt_index],shirts[shirt_index].darkened(0.12)]))
	draw_circle(p+Vector2(-2,-70),18,sc)
	draw_circle(p+Vector2(3,-73),11,sc.lightened(0.08))
	draw_poly(PackedVector2Array([p+Vector2(-18,-79),p+Vector2(-10,-94),p+Vector2(11,-94),p+Vector2(18,-80),p+Vector2(5,-84),p+Vector2(-7,-82)]),PackedColorArray([hairc,hairc.lightened(0.1),hairc,hairc.darkened(0.15)]))
	draw_line(p+Vector2(13,-48),p+Vector2(44,-28),sc,7)
	draw_line(p+Vector2(-8,-48),p+Vector2(34,-27),sc,7)
	draw_circle(p+Vector2(44,-28),5,sc)
	draw_line(p+Vector2(34,-27),p+Vector2(82,-43),Color("#d9b66b"),3)
	if beard_style_index==1: draw_circle(p+Vector2(7,-59),8,beardc)
	elif beard_style_index==2: draw_line(p+Vector2(0,-59),p+Vector2(13,-57),beardc,5)
	elif beard_style_index==3:
		draw_line(p+Vector2(0,-60),p+Vector2(15,-57),beardc,8)
		draw_line(p+Vector2(6,-55),p+Vector2(7,-48),beardc,5)
	elif beard_style_index==4: draw_line(p+Vector2(-1,-59),p+Vector2(14,-59),beardc,5)
	elif beard_style_index==5: draw_circle(p+Vector2(7,-57),10,beardc)
	if hat_index>0:
		var hats=[Color("#6a3b22"),Color("#d5ad62"),Color("#1c1d20"),Color("#b34a36")]
		var hatc=hats[hat_index-1]
		draw_ellipse(p+Vector2(-2,-93),Vector2(39,9),hatc.darkened(0.18))
		draw_rect(Rect2(p+Vector2(-18,-107),Vector2(33,18)),hatc,true)
		draw_ellipse(p+Vector2(-2,-107),Vector2(17,6),hatc.lightened(0.1))
		draw_rect(Rect2(p+Vector2(-19,-93),Vector2(35,4)),Color("#4a2e20"),true)
	draw_line(p+Vector2(-73,2),p+Vector2(-101,-21),hairc,8)
	draw_line(p+Vector2(-98,-21),p+Vector2(-114,-4),hairc,6)


func draw_bull(p:Vector2,c:Color):
	draw_ellipse(p+Vector2(4,54),Vector2(104,19),Color(0.03,0.02,0.015,0.38))
	var dark=c.darkened(0.34)
	var bull_gait=sin(elapsed*11.0)*8.0 if screen=="game" else 0.0
	var bull_legs=[-59.0,-28.0,25.0,59.0]
	for i in range(4):
		var x=bull_legs[i]
		var swing=bull_gait if i%2==0 else -bull_gait
		draw_line(p+Vector2(x,17),p+Vector2(x+swing*0.25,49),dark,12)
		draw_line(p+Vector2(x+swing*0.25,45),p+Vector2(x-6+swing,64),c.darkened(0.18),8)
		draw_rect(Rect2(p+Vector2(x-10+swing,61),Vector2(20,8)),Color("#141313"),true)
	draw_ellipse(p+Vector2(-5,2),Vector2(99,44),c.darkened(0.08))
	draw_ellipse(p+Vector2(-30,-6),Vector2(61,29),c.lightened(0.11))
	draw_ellipse(p+Vector2(69,-18),Vector2(40,35),c.darkened(0.03))
	draw_ellipse(p+Vector2(101,-27),Vector2(40,31),c)
	draw_ellipse(p+Vector2(120,-16),Vector2(25,19),c.lightened(0.08))
	draw_circle(p+Vector2(113,-34),5,Color("#101010"))
	draw_circle(p+Vector2(114,-35),2,WHITE)
	draw_circle(p+Vector2(124,-17),5,Color("#111"))
	draw_poly(PackedVector2Array([p+Vector2(84,-47),p+Vector2(76,-70),p+Vector2(97,-53)]),PackedColorArray([c,c.lightened(0.1),c]))
	draw_poly(PackedVector2Array([p+Vector2(111,-48),p+Vector2(130,-69),p+Vector2(127,-43)]),PackedColorArray([c,c.darkened(0.05),c]))
	draw_line(p+Vector2(102,-51),p+Vector2(126,-77),Color("#f1e4bd"),8)
	draw_line(p+Vector2(126,-77),p+Vector2(140,-81),Color("#c6b48b"),5)
	draw_line(p+Vector2(119,-49),p+Vector2(145,-70),Color("#f1e4bd"),8)
	draw_line(p+Vector2(145,-70),p+Vector2(159,-72),Color("#c6b48b"),5)
	draw_line(p+Vector2(-94,2),p+Vector2(-141,25),c.darkened(0.2),8)
	draw_line(p+Vector2(-141,25),p+Vector2(-157,12),Color("#171313"),8)
	for i in range(14):
		draw_circle(p+Vector2(-78+i*15,66+(i%3)*5),2+(i%3),Color(0.98,0.80,0.58,0.16))


func draw_poly(points:PackedVector2Array, colors):
	if points.size() < 3:
		return
	var fill := Color.WHITE
	if colors is Color:
		fill = colors
	elif colors is PackedColorArray and colors.size() > 0:
		fill = colors[0]
	draw_colored_polygon(points, fill)


func draw_ellipse(center:Vector2,r:Vector2,c:Color):
	var pts=PackedVector2Array()
	for i in range(32):
		var a=TAU*i/32.0
		pts.append(center+Vector2(cos(a)*r.x,sin(a)*r.y))
	draw_poly(pts,c)


func draw_result():
	title("FIN DEL TURNO",70,44)
	draw_string(font,Vector2(50,125),"PUNTUACIÓN: %.2f"%score,HORIZONTAL_ALIGNMENT_LEFT,-1,30,GOLD)
	draw_string(font,Vector2(50,158),get_round_name()+"  •  "+championship_status,HORIZONTAL_ALIGNMENT_LEFT,-1,21,GREEN if championship_status=="CLASIFICADO" else RED)
	draw_rect(Rect2(45,190,590,390),Color("#0d1e2a"),true)
	draw_rect(Rect2(45,190,590,390),Color("#345365"),false,3)
	draw_string(font,Vector2(70,228),"CLASIFICACIÓN CPU",HORIZONTAL_ALIGNMENT_LEFT,-1,24,WHITE)
	var table=get_championship_table()
	for i in range(table.size()):
		var y=265+i*34
		var is_player=table[i].player
		draw_rect(Rect2(65,y-22,550,29),Color("#24485b") if is_player else Color("#132b39"),true)
		draw_string(font,Vector2(78,y),str(i+1)+". "+table[i].name,HORIZONTAL_ALIGNMENT_LEFT,390,15,GOLD if is_player else WHITE)
		draw_string(font,Vector2(500,y),"%.1f"%table[i].points,HORIZONTAL_ALIGNMENT_LEFT,90,15,GREEN if is_player else MUTED)
	draw_string(font,Vector2(680,235),"TU POSICIÓN",HORIZONTAL_ALIGNMENT_LEFT,-1,16,MUTED)
	draw_string(font,Vector2(680,275),"#%d / 9"%player_championship_position,HORIZONTAL_ALIGNMENT_LEFT,-1,52,GOLD)
	draw_string(font,Vector2(680,330),"CPU: DIFÍCIL",HORIZONTAL_ALIGNMENT_LEFT,-1,22,RED)
	draw_string(font,Vector2(680,365),"CPU: actuaciones independientes y alta dificultad.",HORIZONTAL_ALIGNMENT_LEFT,500,17,MUTED)
	draw_string(font,Vector2(680,395),"MEJOR COMBO: x%d"%best_combo,HORIZONTAL_ALIGNMENT_LEFT,-1,18,GOLD)
	var msg="¡Clasificaste! Prepárate para la siguiente ronda."
	if championship_status=="ELIMINADO": msg="El CPU fue superior. Repite la ronda y mejora tu técnica."
	elif championship_status=="CAMPEÓN": msg="¡CAMPEÓN NACIONAL! Dominaste la clasificación."
	elif championship_status=="PODIO": msg="¡Gran final! Terminaste en el podio."
	draw_string(font,Vector2(680,420),msg,HORIZONTAL_ALIGNMENT_LEFT,490,20,WHITE)
	draw_button(Rect2(680,500,245,62),"CONTINUAR","play",RED)
	draw_button(Rect2(940,500,245,62),"CAMPEONATO","tournaments",PANEL2)
	draw_button(Rect2(680,575,505,55),"REINICIAR CAMPAÑA","reset_campaign",PANEL2)

func draw_horses():
	title("CABALLEROS DE LA MANGA",68,40)
	draw_string(font,Vector2(55,112),"ELIGE TU CABALLO",HORIZONTAL_ALIGNMENT_LEFT,-1,25,GOLD)
	draw_string(font,Vector2(55,140),"Pelajes inspirados en la tradición ecuestre venezolana.",HORIZONTAL_ALIGNMENT_LEFT,-1,17,MUTED)
	
	# Tarjeta principal
	draw_rect(Rect2(45,170,720,410),Color("#102a39"),true)
	draw_rect(Rect2(45,170,720,410),Color("#3e6070"),false,3)
	draw_rect(Rect2(70,195,670,250),Color("#6e8e95"),true)
	draw_rect(Rect2(70,330,670,115),Color("#9a6844"),true)
	
	# Caballo/coleador mostrado con el sprite detallado de alta resolución.
	if horse_texture != null:
		draw_texture_rect(horse_texture,Rect2(215,205,390,256),false)
	else:
		draw_character(Vector2(400,355),horse_colors[selected_horse],skin,hair,beard)
	
	# Navegación
	draw_button(Rect2(95,485,105,55),"‹","prev_horse")
	draw_button(Rect2(210,485,250,55),"ELEGIR","buy_horse",RED)
	draw_button(Rect2(470,485,105,55),"›","next_horse")
	
	# Ficha
	draw_rect(Rect2(790,170,445,410),Color("#0d1e2a"),true)
	draw_rect(Rect2(790,170,445,410),Color("#345365"),false,3)
	draw_string(font,Vector2(825,220),horse_names[selected_horse],HORIZONTAL_ALIGNMENT_LEFT,-1,34,WHITE)
	draw_string(font,Vector2(825,250),"PELaje DE COMPETENCIA",HORIZONTAL_ALIGNMENT_LEFT,-1,16,GOLD)
	
	var desc=["Alazán clásico","Negro profundo","Dorado luminoso","Tordillo elegante","Zaino oscuro","Bayo de campo"]
	draw_string(font,Vector2(825,292),desc[selected_horse],HORIZONTAL_ALIGNMENT_LEFT,-1,21,MUTED)	
	draw_string(font,Vector2(825,340),"VELOCIDAD",HORIZONTAL_ALIGNMENT_LEFT,-1,16,WHITE)
	draw_rect(Rect2(955,328,210,12),Color("#203c4b"),true)
	draw_rect(Rect2(955,328,155+selected_horse*8,12),GOLD,true)
	draw_string(font,Vector2(825,380),"CONTROL",HORIZONTAL_ALIGNMENT_LEFT,-1,16,WHITE)
	draw_rect(Rect2(955,368,210,12),Color("#203c4b"),true)
	draw_rect(Rect2(955,368,185-selected_horse*6,12),Color("#4acb83"),true)
	draw_string(font,Vector2(825,420),"RESISTENCIA",HORIZONTAL_ALIGNMENT_LEFT,-1,16,WHITE)
	draw_rect(Rect2(955,408,210,12),Color("#203c4b"),true)
	draw_rect(Rect2(955,408,140+(selected_horse%3)*20,12),Color("#63b9df"),true)
	
	draw_string(font,Vector2(825,468),"VALOR: 500 MONEDAS",HORIZONTAL_ALIGNMENT_LEFT,-1,20,GOLD)
	var horse_status="SELECCIONADO" if selected_horse==0 else ("EN TU CUADRA" if owned_horses[selected_horse] else "BLOQUEADO • COMPRA POR 500")
	draw_string(font,Vector2(825,510),horse_status,HORIZONTAL_ALIGNMENT_LEFT,390,17,GREEN if owned_horses[selected_horse] else RED)
	draw_button(Rect2(850,620,300,55),"VOLVER","back")

func draw_bulls():
	title("TOROS DE COMPETENCIA",68,40)
	draw_string(font,Vector2(55,112),"ELIGE TU TORO",HORIZONTAL_ALIGNMENT_LEFT,-1,25,GOLD)
	draw_string(font,Vector2(55,140),"Cada variante cambia el carácter visual de la manga.",HORIZONTAL_ALIGNMENT_LEFT,-1,17,MUTED)
	
	draw_rect(Rect2(45,170,720,410),Color("#102a39"),true)
	draw_rect(Rect2(45,170,720,410),Color("#3e6070"),false,3)
	draw_rect(Rect2(70,195,670,250),Color("#718b91"),true)
	draw_rect(Rect2(70,330,670,115),Color("#9a6844"),true)
	if bull_texture != null:
		draw_texture_rect(bull_texture,Rect2(205,200,400,252),false)
	else:
		draw_bull(Vector2(400,355),bull_colors[selected_bull])
	
	draw_button(Rect2(95,485,105,55),"‹","prev_bull")
	draw_button(Rect2(210,485,250,55),"SELECCIONAR","next_bull",RED)
	draw_button(Rect2(470,485,105,55),"›","next_bull")
	
	draw_rect(Rect2(790,170,445,410),Color("#0d1e2a"),true)
	draw_rect(Rect2(790,170,445,410),Color("#345365"),false,3)
	draw_string(font,Vector2(825,220),bull_names[selected_bull],HORIZONTAL_ALIGNMENT_LEFT,-1,34,WHITE)
	draw_string(font,Vector2(825,250),"TORO DE MANGA",HORIZONTAL_ALIGNMENT_LEFT,-1,16,GOLD)
	
	var bull_desc=["Castaño: equilibrado","Colorado: potente","Negro: impredecible","Barcino: resistente"]
	draw_string(font,Vector2(825,292),bull_desc[selected_bull],HORIZONTAL_ALIGNMENT_LEFT,-1,21,MUTED)
	
	draw_string(font,Vector2(825,340),"IMPULSO",HORIZONTAL_ALIGNMENT_LEFT,-1,16,WHITE)
	draw_rect(Rect2(955,328,210,12),Color("#203c4b"),true)
	draw_rect(Rect2(955,328,145+selected_bull*18,12),RED,true)
	draw_string(font,Vector2(825,380),"AGILIDAD",HORIZONTAL_ALIGNMENT_LEFT,-1,16,WHITE)
	draw_rect(Rect2(955,368,210,12),Color("#203c4b"),true)
	draw_rect(Rect2(955,368,180-selected_bull*10,12),GOLD,true)
	draw_string(font,Vector2(825,420),"DESAFÍO",HORIZONTAL_ALIGNMENT_LEFT,-1,16,WHITE)
	draw_rect(Rect2(955,408,210,12),Color("#203c4b"),true)
	draw_rect(Rect2(955,408,130+selected_bull*22,12),Color("#d76b6b"),true)
	
	draw_string(font,Vector2(825,468),"CATEGORÍA  •  COMPETENCIA",HORIZONTAL_ALIGNMENT_LEFT,-1,18,GOLD)
	draw_string(font,Vector2(825,510),"LISTO PARA LA MANGA",HORIZONTAL_ALIGNMENT_LEFT,-1,17,GREEN)
	draw_button(Rect2(850,620,300,55),"VOLVER","back")

func draw_custom():
	title("COLEADOR",55,40)
	draw_string(font,Vector2(55,100),"CREA TU COLEADOR",HORIZONTAL_ALIGNMENT_LEFT,-1,25,GOLD)
	draw_string(font,Vector2(55,128),"Personaliza rostro, cabello, barba, sombrero y uniforme.",HORIZONTAL_ALIGNMENT_LEFT,-1,16,MUTED)
	draw_rect(Rect2(35,155,585,500),Color("#0b1d29"),true)
	draw_rect(Rect2(35,155,585,500),Color("#476779"),false,3)
	draw_rect(Rect2(55,175,545,340),Color("#244555"),true)
	draw_circle(Vector2(330,315),130,Color(0.18,0.52,0.65,0.10))
	draw_character(Vector2(330,405),horse_colors[selected_horse],skin,hair,beard)
	draw_string(font,Vector2(70,555),"PIEL  "+str(skin_index+1)+"/6",HORIZONTAL_ALIGNMENT_LEFT,-1,15,GOLD)
	draw_string(font,Vector2(210,555),"CABELLO  "+str(hair_style_index+1)+"/6",HORIZONTAL_ALIGNMENT_LEFT,-1,15,GOLD)
	draw_string(font,Vector2(385,555),"BARBA  "+str(beard_style_index+1)+"/6",HORIZONTAL_ALIGNMENT_LEFT,-1,15,GOLD)
	draw_string(font,Vector2(70,585),"SOMBRERO  "+str(hat_index+1)+"/5",HORIZONTAL_ALIGNMENT_LEFT,-1,15,GOLD)
	draw_string(font,Vector2(230,585),"UNIFORME  "+str(shirt_index+1)+"/6",HORIZONTAL_ALIGNMENT_LEFT,-1,15,GOLD)

	draw_rect(Rect2(650,155,585,500),Color("#0d1e2a"),true)
	draw_rect(Rect2(650,155,585,500),Color("#476779"),false,3)
	draw_string(font,Vector2(680,195),"PERSONALIZACIÓN",HORIZONTAL_ALIGNMENT_LEFT,-1,27,WHITE)
	draw_button(Rect2(680,220,260,55),"TONO DE PIEL","skin",PANEL2)
	draw_button(Rect2(950,220,245,55),"CORTE DE CABELLO","hair",PANEL2)
	draw_button(Rect2(680,290,260,55),"TIPO DE BARBA","beard",PANEL2)
	draw_button(Rect2(950,290,245,55),"COLOR DE CABELLO","hair_color",PANEL2)
	draw_button(Rect2(680,360,260,55),"COLOR DE BARBA","beard_color",PANEL2)
	draw_button(Rect2(950,360,245,55),"SOMBRERO","hat",PANEL2)
	draw_button(Rect2(680,430,260,55),"UNIFORME","shirt",PANEL2)
	draw_button(Rect2(950,430,245,55),"ASOCIACIÓN","association",PANEL2)
	draw_string(font,Vector2(680,520),"CLUB",HORIZONTAL_ALIGNMENT_LEFT,-1,13,MUTED)
	draw_string(font,Vector2(680,545),club_names[selected_club],HORIZONTAL_ALIGNMENT_LEFT,510,18,GOLD)
	draw_string(font,Vector2(680,580),"CATEGORÍA  C  •  B  •  A  •  AA",HORIZONTAL_ALIGNMENT_LEFT,-1,16,MUTED)
	draw_button(Rect2(915,610,280,45),"VOLVER","back")

func draw_clubs():
	title("CLUBES Y ASOCIACIONES",68,40)
	draw_string(font,Vector2(55,112),"REPRESENTA A TU TIERRA",HORIZONTAL_ALIGNMENT_LEFT,-1,25,GOLD)
	draw_string(font,Vector2(55,140),"Clubes tomados como referencias de registros públicos de FEVECO.",HORIZONTAL_ALIGNMENT_LEFT,-1,17,MUTED)

	draw_rect(Rect2(45,170,760,420),Color("#102a39"),true)
	draw_rect(Rect2(45,170,760,420),Color("#3e6070"),false,3)

	# Identidad visual del club
	draw_rect(Rect2(70,195,300,345),Color("#183747"),true)
	draw_circle(Vector2(220,305),92,Color("#0b1720"))
	draw_circle(Vector2(220,305),72,Color("#e2b83f"))
	draw_circle(Vector2(220,305),58,Color("#17344b"))
	draw_string(font,Vector2(145,315),"FEVECO",HORIZONTAL_ALIGNMENT_CENTER,150,30,WHITE)
	draw_string(font,Vector2(108,385),"REPRESENTACIÓN",HORIZONTAL_ALIGNMENT_CENTER,225,16,GOLD)

	# Datos reales de referencia
	draw_string(font,Vector2(410,230),club_names[selected_club],HORIZONTAL_ALIGNMENT_LEFT,350,25,WHITE)
	draw_string(font,Vector2(410,275),"ESTADO",HORIZONTAL_ALIGNMENT_LEFT,-1,14,MUTED)
	draw_string(font,Vector2(410,302),club_states[selected_club],HORIZONTAL_ALIGNMENT_LEFT,-1,25,GOLD)
	draw_string(font,Vector2(410,345),"CATEGORÍAS REGISTRADAS",HORIZONTAL_ALIGNMENT_LEFT,-1,14,MUTED)
	draw_string(font,Vector2(410,373),club_categories[selected_club],HORIZONTAL_ALIGNMENT_LEFT,-1,22,WHITE)
	draw_string(font,Vector2(410,418),"ESTATUS EN CNBC",HORIZONTAL_ALIGNMENT_LEFT,-1,14,MUTED)
	draw_string(font,Vector2(410,446),"REFERENCIA VENEZOLANA",HORIZONTAL_ALIGNMENT_LEFT,-1,20,GREEN)
	draw_string(font,Vector2(410,495),"Clubes reales de referencia.",HORIZONTAL_ALIGNMENT_LEFT,-1,16,MUTED)
	draw_string(font,Vector2(410,518),"Las estadísticas jugables son del videojuego.",HORIZONTAL_ALIGNMENT_LEFT,-1,15,MUTED)

	draw_button(Rect2(95,545,105,55),"‹","prev_club")
	draw_button(Rect2(210,545,250,55),"REPRESENTAR","next_club",RED)
	draw_button(Rect2(470,545,105,55),"›","next_club")
	draw_button(Rect2(885,620,300,55),"VOLVER","back")

	# Lista lateral
	draw_rect(Rect2(835,170,400,420),Color("#0d1e2a"),true)
	draw_rect(Rect2(835,170,400,420),Color("#345365"),false,3)
	draw_string(font,Vector2(865,215),"CLUBES DESTACADOS",HORIZONTAL_ALIGNMENT_LEFT,-1,28,WHITE)
	for i in range(club_names.size()):
		var y=245+i*40
		var selected=i==selected_club
		draw_rect(Rect2(860,y-24,350,34),Color("#24485b") if selected else Color("#132b39"),true)
		draw_string(font,Vector2(875,y),club_names[i],HORIZONTAL_ALIGNMENT_LEFT,325,14,GOLD if selected else WHITE)

func draw_tournaments():
	title("CAMPEONATO NACIONAL",68,40)
	draw_string(font,Vector2(55,112),"ELIGE TU RUTA AL TÍTULO",HORIZONTAL_ALIGNMENT_LEFT,-1,25,GOLD)
	draw_string(font,Vector2(55,140),"Calendario basado en FEVECO; la competición jugable es propia de CNBC.",HORIZONTAL_ALIGNMENT_LEFT,-1,15,MUTED)
	draw_rect(Rect2(45,170,650,420),Color("#102a39"),true)
	draw_rect(Rect2(45,170,650,420),Color("#3e6070"),false,3)
	for i in range(tournament_names.size()):
		var y=188+i*48
		var selected=i==selected_tournament
		draw_rect(Rect2(70,y,600,38),Color("#24485b") if selected else Color("#132f3e"),true)
		draw_rect(Rect2(70,y,6,38),GOLD if selected else Color("#294858"),true)
		draw_string(font,Vector2(88,y+25),tournament_names[i],HORIZONTAL_ALIGNMENT_LEFT,330,15,WHITE)
		draw_string(font,Vector2(425,y+25),tournament_dates[i],HORIZONTAL_ALIGNMENT_LEFT,110,13,GOLD if selected else MUTED)
		draw_string(font,Vector2(550,y+25),tournament_categories[i],HORIZONTAL_ALIGNMENT_LEFT,100,13,MUTED)
	draw_rect(Rect2(725,170,510,420),Color("#0d1e2a"),true)
	draw_rect(Rect2(725,170,510,420),Color("#345365"),false,3)
	draw_string(font,Vector2(755,212),"TU CAMPAÑA",HORIZONTAL_ALIGNMENT_LEFT,-1,26,WHITE)
	draw_string(font,Vector2(755,246),"CLUB",HORIZONTAL_ALIGNMENT_LEFT,-1,13,MUTED)
	draw_string(font,Vector2(755,273),club_names[selected_club],HORIZONTAL_ALIGNMENT_LEFT,440,20,GOLD)
	draw_string(font,Vector2(755,310),"ASOCIACIÓN",HORIZONTAL_ALIGNMENT_LEFT,-1,13,MUTED)
	draw_string(font,Vector2(755,337),club_states[selected_club],HORIZONTAL_ALIGNMENT_LEFT,-1,21,WHITE)
	draw_string(font,Vector2(755,375),"CATEGORÍA",HORIZONTAL_ALIGNMENT_LEFT,-1,13,MUTED)
	draw_string(font,Vector2(755,402),category_names[selected_category],HORIZONTAL_ALIGNMENT_LEFT,-1,23,GOLD)
	draw_string(font,Vector2(755,440),"MANGA",HORIZONTAL_ALIGNMENT_LEFT,-1,13,MUTED)
	draw_string(font,Vector2(755,467),venue_names[selected_venue],HORIZONTAL_ALIGNMENT_LEFT,-1,20,WHITE)
	draw_string(font,Vector2(755,505),"PUNTOS DE CAMPEONATO  %.1f"%championship_points,HORIZONTAL_ALIGNMENT_LEFT,-1,17,GREEN)
	draw_string(font,Vector2(755,535),"POSICIÓN ACTUAL  #%d / 9"%player_championship_position,HORIZONTAL_ALIGNMENT_LEFT,-1,16,GOLD)
	draw_button(Rect2(75,545,150,50),"‹","prev_category")
	draw_button(Rect2(230,545,240,50),"CATEGORÍA  "+category_names[selected_category],"next_category",PANEL2)
	draw_button(Rect2(475,545,150,50),"›","next_category")
	draw_button(Rect2(655,545,270,50),"CAMBIAR MANGA","next_venue")
	draw_button(Rect2(955,545,270,50),"COMPETIR","start_championship",RED)
	draw_button(Rect2(75,620,270,55),"‹  TORNEO","prev_tournament")
	draw_button(Rect2(355,620,270,55),"TORNEO  ›","next_tournament")
	draw_button(Rect2(655,620,270,55),"REINICIAR CAMPAÑA","reset_campaign",PANEL2)
	draw_string(font,Vector2(955,620),"RONDA: "+get_round_name(),HORIZONTAL_ALIGNMENT_CENTER,270,17,GOLD)
	draw_string(font,Vector2(955,652),"TURNOS: %d  •  CPU: DIFÍCIL"%championship_turns,HORIZONTAL_ALIGNMENT_CENTER,270,15,MUTED)

func draw_shop():
	title("TIENDA",80)
	draw_string(font,Vector2(0,135),"MONEDAS: %d"%coins,HORIZONTAL_ALIGNMENT_CENTER,W,24,GOLD)
	draw_button(Rect2(340,205,600,72),"Caballo especial: 500 monedas","horses")
	draw_button(Rect2(340,300,600,72),"Equipamiento de coleador","custom")
	draw_button(Rect2(340,395,600,72),"Decoraciones de perfil","profile")
	draw_button(Rect2(470,630,340,55),"VOLVER","back")

func draw_profile():
	title("PERFIL",80)
	draw_string(font,Vector2(0,155),"COLEADOR NOVATO",HORIZONTAL_ALIGNMENT_CENTER,W,34,WHITE)
	draw_string(font,Vector2(0,215),"Puntos acumulados: %.2f"%total_score,HORIZONTAL_ALIGNMENT_CENTER,W,24,GOLD)
	draw_string(font,Vector2(0,250),"Puntos de campeonato: %.1f"%championship_points,HORIZONTAL_ALIGNMENT_CENTER,W,23,GREEN)
	draw_string(font,Vector2(0,285),"Club: %s"%club_names[selected_club],HORIZONTAL_ALIGNMENT_CENTER,W,20,WHITE)
	draw_string(font,Vector2(0,320),"Categoría: %s  •  Manga: %s" % [category_names[selected_category], venue_names[selected_venue]],HORIZONTAL_ALIGNMENT_CENTER,W,20,MUTED)
	draw_string(font,Vector2(0,355),"Torneos disputados: %d"%championship_turns,HORIZONTAL_ALIGNMENT_CENTER,W,20,MUTED)
	draw_string(font,Vector2(0,390),"Caballo: %s  •  Combo máximo: x%d" % [horse_names[selected_horse],best_combo],HORIZONTAL_ALIGNMENT_CENTER,W,22,MUTED)
	draw_string(font,Vector2(0,300),"Modo: Campeonato Nacional",HORIZONTAL_ALIGNMENT_CENTER,W,22,MUTED)
	draw_button(Rect2(470,630,340,55),"VOLVER","back")

func draw_settings():
	title("CONFIGURACIONES",80)
	draw_button(Rect2(360,190,560,65),"VIBRACIÓN: ACTIVADA","back")
	draw_button(Rect2(360,275,560,65),"CALIDAD: ALTA","back")
	draw_button(Rect2(360,360,560,65),"CONTROLES TÁCTILES","back")
	draw_button(Rect2(360,445,560,65),"IDIOMA: ESPAÑOL","back")
	draw_button(Rect2(470,630,340,55),"VOLVER","back")

func draw_music():
	title("MÚSICA",80)
	draw_string(font,Vector2(0,150),"MÚSICA PERSONALIZADA",HORIZONTAL_ALIGNMENT_CENTER,W,30,GOLD)
	draw_string(font,Vector2(210,215),"En Android, la V1 reservará una carpeta de música",HORIZONTAL_ALIGNMENT_LEFT,-1,22,WHITE)
	draw_string(font,Vector2(210,250),"para que puedas elegir tus propios archivos de audio.",HORIZONTAL_ALIGNMENT_LEFT,-1,22,MUTED)
	draw_string(font,Vector2(210,315),"Esta pantalla es la base de la futura integración",HORIZONTAL_ALIGNMENT_LEFT,-1,22,MUTED)
	draw_string(font,Vector2(210,350),"con el selector de archivos de Android.",HORIZONTAL_ALIGNMENT_LEFT,-1,22,MUTED)
	draw_button(Rect2(470,630,340,55),"VOLVER","back")

func draw_manga_background():
	pass

# Raster pixel-art textures generated from indexed pixel grids. No SVG assets are used for these sprites.
func _texture_from_pixel_rows(rows: Array, palette: Array) -> Texture2D:
	var width := String(rows[0]).length()
	var img := Image.create(width, rows.size(), false, Image.FORMAT_RGBA8)
	for y in range(rows.size()):
		var row := String(rows[y])
		for x in range(width):
			var idx := "0123456789ABCDEF".find(row.substr(x, 1))
			img.set_pixel(x, y, palette[idx] if idx >= 0 and idx < palette.size() else Color.TRANSPARENT)
	return ImageTexture.create_from_image(img)

func _make_bull_pixel_texture() -> Texture2D:
	var rows := [
		"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
		"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
		"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
		"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
		"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
		"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
		"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
		"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000BB00000000",
		"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000BB00000000",
		"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000BB000000000000000000000777000000000",
		"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000BB770000000000000000777770000000000",
		"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000777700000000000000777770000000000",
		"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077770000000000000777770000000000",
		"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077777000000000007777700000000000",
		"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777000000000007777700000000000",
		"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000607777700000000077777700000000000",
		"000000000000000000000000000000000000000000000000000000000000000000000000000000000033333366777770000000077777000000000000",
		"000000000000000000000000000000000000000000000000000000000000000000000000000000000063333336777770000000777777000000000000",
		"000000000000000000000000000000000000000000000000000000040000000000000000000000466666333333666777004464777777000000000000",
		"000000000000000000000000000000000000000000000044444444444444444440000000046666666666633333366664666667777770000000000000",
		"000000000000000000000000000000000000000000444443444444444444444444444004666666666666363333334446666666677770333000000000",
		"000000000000000000000000000000000000000033333333333333344444444444444446666666666666333333333666666666666333333300000000",
		"000000000000000000000000000000000000033333333333333333333344444444444666666646666663333333644666663333333333333333000000",
		"000000000000000000000000000000000003333333333333333333334444444444446666666646666333333333333666666BBBB33333333300000000",
		"000000000000000000000000000000000333333333333336666666344444444444446666666666666666333333333666666BBBB83333330000000000",
		"000000000000000000000000000000033333336666666666666666666664444444466666666666666666663333333666666888888888600000000000",
		"000000000000000000000000000000333336666666666666666666666666444644466666666666666666666663336666668888888988860000000000",
		"000000000000000000000000000003333366666666666666666666666666666644666666666666666666666666446666688888999999980000000000",
		"00000000000000000000000000000333366666666666666666666666666666664466666666666666666666666644666668888AABB99BBA0000000000",
		"00000000000000000000000000003333666666666666666666666666666666644466666666666666666666666444666688889AABB99BBA9000000000",
		"000000000000000000000000000333333666666666666666666666666666666444666666664666666666666666644666688889999999990000000000",
		"000000000000000000000000000333333366666666666666666666666666666446666666664666666666666666664666688888999999980000000000",
		"000000000000000000000000004333333336666666666666666666666666664444666666634666666666666666333346668888888988800000000000",
		"000000000000000000000000004333333333336666666666666666666666664444666666336666666666666633333334666888888888000000000000",
		"000000000000000000000000043333333333333333333336344446666666664444666663344666666666666633333333366660080000000000000000",
		"000000000000000000000000044333333333333333333333344444446666664444666663344666666666666333333333336600000000000000000000",
		"000000000000000000000000044333333333333333333333344444444444444444466633344666666666666333333333336600000000000000000000",
		"000000000000000000000000044333333333333333333333444444444444444444466633444666666666663333333333333640000000000000000000",
		"000000000000000000000000044333333333333333333333344444444444444444446633344666666666663333333333333640000000000000000000",
		"000000000000000000000000444433333333333333333333344444444444444444446633334666666666663333333333333644000000000000000000",
		"000000000000000000000000044443333333333333333333344444444434444444444333334466666666663333333333333440000000000000000000",
		"000000000000000000000000044443333333333333333333333333336666634444444433333466666666663333333333333400000000000000000000",
		"000000000000000000000000344444333333333333333333333333336666666644444433333333666666633333333333333300000000000000000000",
		"000000000000000000000003344444433333333333333333333333336666666666644433333333366666663333333333333000000000000000000000",
		"000000000000000000000033344444444333333333333333333333333336666666664433333333336666663333333333333000000000000000000000",
		"000000000000000000000333334444444443333333333333333333333333336666664443333333333666663333333333333400000000000000000000",
		"000000000000000000033333334444444444433333332222233333333333333446664443333333333666663333333333333400000000000000000000",
		"000000000000000000333333330444444444443333332222222233333333333422222222344444333666663333333333333400000000000000000000",
		"000000000000000003333333300444444444433333332222222222333333333222222222444444446666666333333333334400000000000000000000",
		"000000000000000033333333000044444444443333333332222222233333333222222222444444444466666333333333334400000000000000000000",
		"000000000333330333333300000004444444443333333333332222233333333222444444444444444336666633333333344400000000000000000000",
		"000000000333333333333000000000444444444333333333333322233333333333444444444444444333333633333333344400000000000000000000",
		"000000000333333333330000000000044444444433333333333333333333333333444444444444444344433333333334444400000000000000000000",
		"000000000000333333300000000000004444444444333333333333333333333333344444444444444444433333333044444400000000000000000000",
		"000000000000003333000000000000000044444444444333333333333333333333334444444444444444433333333044444400000000000000000000",
		"000000000000000000000000000000000004444444444444333333333333333333333444444444444444433333333044444400000000000000000000",
		"000000000000000000000000000000000000044444444444444444444434444444444444444444444444443333333044444400000000000000000000",
		"000000000000000000000000000000000000044444444444444444444444444444444440044444444444443333333044444400000000000000000000",
		"000000000000000000000000000000000000044444444444444444444444444444444000044444444444443333333044444400000000000000000000",
		"000000000000000000000000000000000000044444400044444444444444444440000000044444444444443333333044444400000000000000000000",
		"000000000000000000000000000000000000044444400000000000040044444400000000044444444444443333333344444400000000000000000000",
		"000000000000000000000000000000000000044444400000000000000044444400000000044444444444445555555555555555000000000000000000",
		"000000000000000000000000000000000000044444400000000000000044444400000000555555555444445555555555555555000000000000000000",
		"000000000000000000000000000000000000044444400000000000000044444400000000555555555555555555555555555555000000000000000000",
		"000000000000000000000000000000000000555555500000000000000055555555000000555555555555555555555555555555000000000000000000",
		"000000000000000000000000000000000000555555511111111111111155555555111111555555555555555555555555555555000000000000000000",
		"000000000000000000000000000111111111555555511111111111111155555555111111555555555555555555555555555555000000000000000000",
		"000000000000000000000011111111111111555555511111111111111155555555111111555555555555555551111111111110000000000000000000",
		"000000000000000000011111111111111111555555511111111111111155555555111111111111111111111111111111111111110000000000000000",
		"000000000000000000111111111111111111111111111111111111111111111111111111111111111111111111111111111111111000000000000000",
		"000000000000000000011111111111111111111111111111111111111111111111111111111111111111111111111111111111110000000000000000",
		"000000000000000000000011111111111111111111111111111111111111111111111111111111111111111111111111111110000000000000000000",
		"000000000000000000000000000111111111111111111111111111111111111111111111111111111111111111111111000000000000000000000000",
		"000000000000000000000000000000000000111111111111111111111111111111111111111111111111111000000000000000000000000000000000",
		"000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000",
		"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
		"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
		"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
		"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
		"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
	]
	var palette := [Color.TRANSPARENT, Color("#29202b"), Color("#49313a"), Color("#754332"), Color("#a45d36"), Color("#34252a"), Color("#c17a45"), Color("#e4ad63"), Color("#c3a0a0"), Color("#e2c5b1"), Color("#2d6d4c"), Color("#fff0ce"), Color("#4b352d"), Color("#d9d6cf"), Color("#c94c38"), Color("#f0cb4d")]
	var coat_sets := [
		[Color("#302820"), Color("#513b2c"), Color("#765d47"), Color("#b18b63")],
		[Color("#5c4636"), Color("#795a43"), Color("#a17b59"), Color("#c9a27a")],
		[Color("#181818"), Color("#292626"), Color("#484444"), Color("#77716e")],
		[Color("#765d47"), Color("#9d7a5a"), Color("#c3a17b"), Color("#e0c5a0")]
	]
	var coat = coat_sets[clampi(selected_bull, 0, coat_sets.size()-1)]
	palette[3] = coat[0]
	palette[4] = coat[1]
	palette[6] = coat[2]
	palette[7] = coat[3]
	return _texture_from_pixel_rows(rows, palette)

func _make_horse_pixel_texture() -> Texture2D:
	var rows := [
		"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
		"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
		"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
		"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
		"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
		"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
		"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
		"000000000000000000000000000000000000000000000000022222222220000000000000000000000000000000000000000000000000000000000000",
		"000000000000000000000000000000000000000000000000022222222222000000000000000000000000000000000000000000000000000000000000",
		"000000000000000000000000000000000000000000000000222222222222200000000000000000000000000400000000000000000000000000000000",
		"000000000000000000000000000000000000000000000000222222222222220000000000000000000000000440000004000000000000000000000000",
		"000000000000000000000000000000000000000000000002222222222222222000000000000000000000000044000004000000000000000000000000",
		"000000000000000000000000000000000000000000002222222222222222222222000000000000000222222044400044000000000000000000000000",
		"000000000000000000000000000000000000000000002222222222222222222222000000000000000222222244400444000000000000000000000000",
		"000000000000000000000000000000000000000000002222222222222222222222000000000000000222222244444444000000000000000000000000",
		"000000000000000000000000000000000000000000000000888999999988800000000000000000000222222244444444400000000000000000000000",
		"000000000000000000000000000000000000000000000000088999999988000000000000000000022222222244444444440000000000000000000000",
		"000000000000000000000000000000000000000000000000088899999888000000000000000000022222224444444444444000000000000000000000",
		"000000000000000000000000000000000000000000000000088888988888000000000000000000222222264444444BB4444000000000000000000000",
		"000000000000000000000000000000000000000000000000008888888880000000000000000000222222244444444BB4666400000000000000000000",
		"000000000000000000000000000000000000000000000000AAB8888888BB000000000000000002222222664444444446666666000000000000000000",
		"000000000000000000000000000000000000000000000000AABBBB8BBBBB000000000000000002222222664444AA4466666660000000000000000000",
		"00000000000000000000000000000000000000000000000AAABBBBBBBBBBA000000000000000222222226664AAAA4666666660000000000000000000",
		"00000000000000000000000000000000000000000666666AAABBBBBBBBBBA44444400000000222222222666AAAA46666666600000000000000000000",
		"0000000000000000000000000000000000000006666666AAAA6666666AAAAA444443444000046222222666AAA4444000000000000000000000000000",
		"0000000000000000000000000000000000000666666666AAA66666666AAAAAAA33333333334666677776AAAA44444000000000000000000000000000",
		"000000000000000000000000000000000006666666666AAAA66666666AAAAAAAA333333334446667777AAAA444444000000000000000000000000000",
		"00000000000000000000000000000000006666666677AAAA6666666666AAAAAAAA3333334444666666AAA44444440000000000000000000000000000",
		"000000000000000000000000000000000666666777777AAAAA666666666AAAAAAAAA333344446666AAAA644444400000000000000000000000000000",
		"0000000000000000000000000000000066666677777888AAAAA6666666666AAAAAAAA3344444466AAAA6444444000000000000000000000000000000",
		"0000000000000000000000000000000066666677777788AAAAAA666666AAAAAAAAAAAA4444444AAAA664444440000000000000000000000000000000",
		"00000000000000000000000000000006666666777666889AAAAAAAAAAAAAAAAAAAAAAA444444AAAA6644444400000000000000000000000000000000",
		"00000000000000000000000000000006666666666666889AAAAAAAAAAAAAAAA33AAAAA44444AAA666444444000000000000000000000000000000000",
		"000000000000000000000000000000066666666666666888AAAAAAAAAAAAAAA333AAAA444AAAA4664444440000000000000000000000000000000000",
		"000000000000000000000000000000666666666666677777AAAAAAAAAAAAAA3333333334AAAA44644444400000000000000000000000000000000000",
		"0000000000000000000000000000004666666666666777778888AAAAAAAAAA8336666634AA4444444444400000000000000000000000000000000000",
		"0000000000000000000000000003334666666666666666888888888AAAAAA83336666633444444444444300000000000000000000000000000000000",
		"0000000000000000000000000033334666666666666666888888888AAAA8833333333333444444444433400000000000000000000000000000000000",
		"0000000000000000000000000333334466666666666666888888888AAAA8833333333333344444444333400000000000000000000000000000000000",
		"00000000000000000000000033333444666666666666668882222222AAA8333333333333344444443333440000000000000000000000000000000000",
		"000000000000000000000003333333444666666666666666622222222AAA333333333333334444433333400000000000000000000000000000000000",
		"000000000000000000000033333330444466666666666666662222222AAA366666666666664444333334400000000000000000000000000000000000",
		"0000000000000000000003333333004444466666666666666622222222AAA66666666666666443333344400000000000000000000000000000000000",
		"0000000000000000000033333330004444444666666666666662222222AAA66666666666666633333444433330000000000000000000000000000000",
		"00000000000000333333333333000004444444466666666666622222222AA33333333333366633334444333333000000000000000000000000000000",
		"000000000000003333333333300000044444444446666666666222222223333333333333333333344444333333000000000000000000000000000000",
		"000000000000003333333333000000004444444444444444644422222222333333333333333334444443333333000000000000000000000000000000",
		"000000000000000003333330000000000444444444444444444442222222433333333333334444444403333333000000000000000000000000000000",
		"000000000000000000333300000000000044444444444444444444555555544444434444444444444003333333000000000000000000000000000000",
		"000000000000000000000000000000000004444444444444444444555555544444444444444444440003333333000000000000000000000000000000",
		"000000000000000000000000000000000000444444444444444444555555524444444444444444440003333333000000000000000000000000000000",
		"000000000000000000000000000000000000004444444444444444555555544444444444444444440003333333000000000000000000000000000000",
		"000000000000000000000000000000000000000444444444444444555555544444444444444444440003333333000000000000000000000000000000",
		"000000000000000000000000000000000000000444444444444444444444444444444444404444440003333333000000000000000000000000000000",
		"000000000000000000000000000000000000000444444444444444444444444444444440004444444003333333000000000000000000000000000000",
		"000000000000000000000000000000000000000444440000444444444444444444400000004444444003333333000000000000000000000000000000",
		"000000000000000000000000000000000000004444440000000333333400000000000000004444444003333333000000000000000000000000000000",
		"000000000000000000000000000000000000004444440000000333333300000000000000004444444003333333000000000000000000000000000000",
		"000000000000000000000000000000000000004444440000000333333300000000000000004444444003333333000000000000000000000000000000",
		"000000000000000000000000000000000000004444440000000333333300000000000000004444444003333333000000000000000000000000000000",
		"000000000000000000000000000000000000004444440000000333333300000000000000004444444005555555550000000000000000000000000000",
		"000000000000000000000000000000000000004444440000000333333300000000000000004444444005555555550000000000000000000000000000",
		"000000000000000000000000000000000000004444440000000333333330000000000000005555555555555555550000000000000000000000000000",
		"000000000000000000000000000000000000004444440000000555555555000000000000005555555555555555550000000000000000000000000000",
		"000000000000000000000000000000000000055555555000000555555555000000000000005555555555555555550000000000000000000000000000",
		"000000000000000000000000000000000000055555555000000555555555000000000000005555555555555555550000000000000000000000000000",
		"000000000000000000000000000000000000055555555000000555555555000000000000005555555550000000000000000000000000000000000000",
		"000000000000000000000000000000000111155555555111111555555555111111111111115555555551000000000000000000000000000000000000",
		"000000000000000000000000011111111111155555555111111111111111111111111111111111111111111111110000000000000000000000000000",
		"000000000000000000000111111111111111111111111111111111111111111111111111111111111111111111111111000000000000000000000000",
		"000000000000000000011111111111111111111111111111111111111111111111111111111111111111111111111111110000000000000000000000",
		"000000000000000000000111111111111111111111111111111111111111111111111111111111111111111111111111000000000000000000000000",
		"000000000000000000000000011111111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000",
		"000000000000000000000000000000000111111111111111111111111111111111111111111111111111000000000000000000000000000000000000",
		"000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000",
		"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
		"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
		"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
		"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
		"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
	]
	var palette := [Color.TRANSPARENT, Color("#29202b"), Color("#49313a"), Color("#754332"), Color("#a45d36"), Color("#34252a"), Color("#c17a45"), Color("#e4ad63"), Color("#c3a0a0"), Color("#e2c5b1"), Color("#2d6d4c"), Color("#fff0ce"), Color("#4b352d"), Color("#d9d6cf"), Color("#c94c38"), Color("#f0cb4d")]
	var coat_sets := [
		[Color("#754332"), Color("#a45d36"), Color("#c17a45"), Color("#e4ad63")],
		[Color("#29272a"), Color("#3b373b"), Color("#5b5558"), Color("#8a8587")],
		[Color("#9b6030"), Color("#c58a43"), Color("#e3b969"), Color("#f1d68b")],
		[Color("#8a8984"), Color("#b9b7ae"), Color("#d4d2cb"), Color("#eee9dc")],
		[Color("#4b352d"), Color("#7f5a37"), Color("#a98155"), Color("#d1b080")],
		[Color("#9a6a28"), Color("#d4a45f"), Color("#e8c47a"), Color("#f3dfa5")]
	]
	var coat = coat_sets[clampi(selected_horse, 0, coat_sets.size()-1)]
	palette[3] = coat[0]
	palette[4] = coat[1]
	palette[6] = coat[2]
	palette[7] = coat[3]
	return _texture_from_pixel_rows(rows, palette)

func _make_arena_pixel_texture() -> Texture2D:
	var rows := [
		"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
		"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
		"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000000",
		"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077777777700000000000000000000000000000",
		"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777777777000000000000000000000000000",
		"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777777B777777700000000000000000000000000",
		"000000000000BBB000000000000000BBB000000000000000BBB000000000000000BBB000000000000000BBB000000000000000BBB000000000000077BBBBBBBBBB77777000BBB0000000000000000000",
		"000000000000BBB000000000000000BBB000000000000000BBB000000000000000BBB000000000000000BBB000000000000000BBB000000000000777BBBBBBBBBBB7777700BBB0000000000000000000",
		"000000000000BBB000000000000000BBB000000000000000BBB000000000000000BBB000000000000000BBB000000000000000BBB000000000000777BBBBBBBBBBBB777700BBB0000000000000000000",
		"000000000000BBB000000022222222BBB222222222222222BBB000000000000000BBB000000000000000BBB000000000000000BBB000000000000777BBBBBBBBBBBB777700BBB0000000000000000000",
		"000000000000BBB000222222222222BBB222222222222222BBB222222222222222BBB222222222222222BBB222222222222222BBB222222222222227BBBBBBBBBBBBB77770BBB0000000000000000000",
		"000000000000BBB222222222222222BBB222222222222222BBB222222222222222BBB222222222222222BBB222222222222222BBB222222222222222BBB2222BBBBB777700BBB0000000000000000000",
		"0000000000777777772222222222777777772222222222777777772222222222777777772222222222777777772222222222777777772222222222777777772222222227777777770000000000000000",
		"0000000022777777772222222222777777772222222222777777772222222222777777772222222222777777772222222222777777772222222222777777772222222222777777770000000000000000",
		"0000277777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777700000",
		"2222277777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777722220",
		"2222277777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777722220",
		"22222222BB2222222222222222222222BB2222222222222222222222BB2222222222222222222222BB2222222222222222222222BB2222222222222222222222BB2222222222222222222222BB222220",
		"22222222BB3333333333333333333333BB3333333333333333333333BB3333333333333333333333BB3333333333333333333333BB3333333333333333333333BB3333333333333333333333BB222220",
		"22222222BB3333333333333333333333BB3333333333333333333333BB3333333333333333333333BB3333333333333333333333BB3333333333333333333333BB3333333333333333333333BB222220",
		"22222222B99999999333333333333333B99999999333333333333333B99999999333333333333333B99999999333333333333333B99999999333333333333333B99999999333333333333333B9999999",
		"22222222B99999999222222222222222B99999999222222222222222B99999999222222222222222B99999999222222222222222B99999999222222222222222B99999999222222222222222B9999999",
		"66666666B77777777666666666666666B77777777666666666666666B77777777666666666666666B77777777666666666666666B77777777666666666666666B77777777666666666666666B7777777",
		"66666666B77777777666666666666666B77777777666666666666666B77777777666666666666666B77777777666666666666666B77777777666666666666666B77777777666666666666666B7777777",
		"66666666BAAAAAAAA666666666666666BAAAAAAAA666666666666666BAAAAAAAA666666666666666BAAAAAAAA666666666666666BAAAAAAAA666666666666666BAAAAAAAA666666666666666BAAAAAAA",
		"66666666BAAAAAAAA666666666666666BAAAAAAAA666666666666666BAAAAAAAA666666666666666BAAAAAAAA666666666666666BAAAAAAAA666666666666666BAAAAAAAA666666666666666BAAAAAAA",
		"33333333BAAAAAAAA333333333333333BAAAAAAAA333333333333333BAAAAAAAA333333333333333BAAAAAAAA333333333333333BAAAAAAAA333333333333333BAAAAAAAA333333333333333BAAAAAAA",
		"33443336BB338833399333AA33344333BB3338833399333AA3334433BB63338833399333AA333443BB663338833399333AA33344BB3663338833399333AA3334BB33663338833399333AA333BB333663",
		"33443336BB338833399333AA33344333BB3338833399333AA3334433BB63338833399333AA333443BB663338833399333AA33344BB3663338833399333AA3334BB33663338833399333AA333BB333663",
		"3333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333",
		"3333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333",
		"33663338833399333AA33344333663338833399333AA33344333663338833399333AA33344333663338833399333AA33344333663338833399333AA33344333663338833399333AA3334433366333883",
		"33663338833399333AA33344333663338833399333AA33344333663338833399333AA33344333663338833399333AA33344333663338833399333AA33344333663338833399333AA3334433366333883",
		"3333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333",
		"3333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333",
		"338833399333AA33344333663338833399333AA33344333663338833399333AA33344333663338833399333AA33344333663338833399333AA33344333663338833399333AA333443336633388333993",
		"338833399333AA33344333663338833399333AA33344333663338833399333AA33344333663338833399333AA33344333663338833399333AA33344333663338833399333AA333443336633388333993",
		"3333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333",
		"3333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333",
		"3399333AA33344333663338833399333AA33344333663338833399333AA33344333663338833399333AA33344333663338833399333AA33344333663338833399333AA33344333663338833399333AA3",
		"3399333AA33344333663338833399333AA33344333663338833399333AA33344333663338833399333AA33344333663338833399333AA33344333663338833399333AA33344333663338833399333AA3",
		"3333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333",
		"3333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333",
		"33AA33344333663338833399333AA33344333663338833399333AA33344333663338833399333AA33344333663338833399333AA33344333663338833399333AA33344333663338833399333AA333443",
		"33AA33344333663338833399333AA33344333663338833399333AA33344333663338833399333AA33344333663338833399333AA33344333663338833399333AA33344333663338833399333AA333443",
		"3333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333",
		"7733333333773333333377333333337733333333773333333377333333337733333333773333333377333333337733333333773333333377333333337733333333773333333377333333337733333333",
		"7777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777",
		"7777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777",
		"7777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777",
		"7700000000770000000077000000007700000000770000000077000000007700000000770000000077000000007700000000770000000077000000007700000000770000000077000000007700000000",
		"7700000000770000000077000000007700000000770000000077000000007700000000770000000077000000007700000000770000000077000000007700000000770000000077000000007700000000",
		"7700000000770000000077000000007700000000770000000077000000007700000000770000000077000000007700000000770000000077000000007700000000770000000077000000007700000000",
		"7700000000770000000077000000007700000000770000000077000000007700000000770000000077000000007700000000770000000077000000007700000000770000000077000000007700000000",
		"7766666666776666666677666666667766666666776666666677666666667766666666776666666677666666667766666666776666666677666666667766666666776666666677666666667766666666",
		"7766666666776666666677666666667766666666776666666677666666667766666666776666666677666666667766666666776666666677666666667766666666776666666677666666667766666666",
		"7700000000770000000077000000007700000000770000000077000000007700000000770000000077000000007700000000770000000077000000007700000000770000000077000000007700000000",
		"4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440",
		"4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440",
		"4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440",
		"4433444444444334444444443344444444433444444444334444444443344444444433444444444334444444443344444444433444444444334444444443344444444433444444444334444444443340",
		"4433444444444334444444443344444444433444444444334444444443344444444433444444444334444444443344444444433444444444334444444443344444444433444444444334444444443340",
		"3333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333330",
		"3333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333330",
		"3333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333330",
		"3333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333330",
		"3333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333330",
		"4334444444443344444444433444444444334444444443344444444433444444444334444444443344444444433444444444334444444443344444444433444444444334444444443344444444433440",
		"4334444444443344444444433444444444334444444443344444444433444444444334444444443344444444433444444444334444444443344444444433444444444334444444443344444444433440",
		"3334444444433344444444333444444443334444444433344444444333444444443334444444433344444444333444444443334444444433344444444333444444443334444444433344444444333440",
		"7777744444433444477777334444444443777774444433444447777734444444443377777444433444444777774444444443347777744433444444477777444444443344777774433444444447777740",
		"3344444444433444444444334444444443344444444433444444444334444444443344444444433444444444334444444443344444444433444444444334444444443344444444433444444444334440",
		"3344444444433444444444334444444443344444444433444444444334444444443344444444433444444444334444444443344444444433444444444334444444443344444444433444444444334440",
		"3344444444433444444444334444444443344444444433444444444334444444443344444444433444444444334444444443344444444433444444444334444444443344444444433444444444334440",
		"3344444444433444444444334444444443344444444433444444444334444444443344444444433444444444334444444443344444466633666666666336666666663366666666633666666666336660",
		"3344444444333444444443334444444433344444444333444444443336666666633366666666333666666663336666666633366666666333666666663336666666633366666666333666666663336660",
		"3666666666336666666663366666666633666666666336666666663366666666633666666666336666666663366666666633666666666336666666663366666666633666666666336666666663366660",
		"3666666666336666666663366666666633666666666336666666663366666666633666666666336666666663366666666633666666666336666666663366666666633666666666336666666663366660",
		"3666666666336666666663366666666633666666666336666666663366666666633666666666336666666663366666666633666666666336666666663366666666633666666666336666666663366660",
		"3666666666336666666663366666666633666666666336666666663366666666633666666666336666666663366666666633666666666336666666663366666666633666666666336666666663366660",
		"3666666663336666666633366666666333666666663336666666633366666666333666666663336666666633366666666333666666663336666666633366666666333666666663336666666633366660",
		"6666666663366666666633666666666336666666663366666666633666666666336666666663366666666633666666666336666666663366666666633666666666336666666663366666666633666660",
		"6666667777366666666633677776666336666666777766666666633667777666336666666677776666666633666777766336666666667777666666633666677776336666666663777766666633666667",
		"6666666663366666666633666666666336666666663366666666633666666666336666666663366666666633666666666336666666663366666666633666666666336666666663366666666633666660",
		"6666666663366666666633666666666336666666663366666666633666666666336666666663366666666633666666666336666666663366666666633666666666336666666663366666666633666660",
		"6666666663366666666633666666666336666666663366666666633666666666336666666663366666666633666666666336666666663366666666633666666666336666666663366666666633666660",
		"6666666633366666666333666666663336666666633366666666333666666663336666666633366666666333666666663336666666633366666666333666666663336666666633366666666333666660",
		"6666666633666666666336666666663366666666633666666666336666666663366666666633666666666336666666663366666666633666666666336666666663366666666633666666666336666660",
		"6666666633666666666336666666663366666666633666666666336666666663366666666633666666666336666666663366666666633666666666336666666663366666666633666666666336666660",
		"0000000033000000000330000000003300000000033000000000330000000003300000000033000000000330000000003300000000033000000000330000000003300000000033000000000330000000"
	]
	var palette := [Color("#7fa9c9"), Color("#29202b"), Color("#49313a"), Color("#754332"), Color("#a45d36"), Color("#34252a"), Color("#c17a45"), Color("#e4ad63"), Color("#c3a0a0"), Color("#e2c5b1"), Color("#2d6d4c"), Color("#fff0ce"), Color("#4b352d"), Color("#d9d6cf"), Color("#c94c38"), Color("#f0cb4d")]
	return _texture_from_pixel_rows(rows, palette)

