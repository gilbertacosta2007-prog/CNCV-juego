extends Node2D

# CNBC - Campeonato Nacional de Coleo Venezolano
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

var screen := "menu"
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
var font: Font

func _ready():
	font = ThemeDB.fallback_font
	queue_redraw()

func _process(delta):
	if screen == "game":
		update_game(delta)
	queue_redraw()

func _input(event):
	if event is InputEventScreenTouch and event.pressed:
		handle_touch(event.position)
	elif event is InputEventMouseButton and event.pressed:
		handle_touch(event.position)
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			screen = "menu"
		if screen == "game" and event.keycode == KEY_SPACE:
			try_grab()

func handle_touch(p: Vector2):
	if screen == "game":
		if p.x < 300 and p.y > H-260:
			var center=Vector2(145,H-130)
			var dir=(p-center).normalized()
			player_vel=dir*170.0
		elif p.x > 1030 and p.y > H-260:
			if p.y < H-135:
				player_vel += Vector2(0,-85)
			else:
				try_grab()
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
		"next_horse":
			selected_horse=(selected_horse+1)%horse_names.size()
		"prev_horse":
			selected_horse=(selected_horse-1+horse_names.size())%horse_names.size()
		"buy_horse":
			if coins >= 500 and selected_horse != 0:
				coins -= 500
		"next_bull":
			selected_bull=(selected_bull+1)%bull_names.size()
		"prev_bull":
			selected_bull=(selected_bull-1+bull_names.size())%bull_names.size()
		"skin":
			skin=Color("#c88758") if skin==Color("#8a5a3b") else Color("#5a351f")
		"hair":
			hair=Color("#b36b32") if hair==Color("#241812") else Color("#241812")
		"beard":
			beard=hair
		"style":
			hair_style=(hair_style+1)%3

func start_game():
	screen="game"
	elapsed=0
	score=0
	grabbed=false
	qte_active=false
	qte_result=""
	player=Vector2(320,390)
	bull=Vector2(820,360)
	player_vel=Vector2(120,0)
	bull_vel=Vector2(-55,0)

func update_game(delta):
	elapsed += delta
	qte_cooldown=max(0.0,qte_cooldown-delta)
	var move=Input.get_vector("move_left","move_right","move_up","move_down")
	if move.length()>0:
		player_vel=move*190.0
	elif player_vel.length()>0:
		player_vel=player_vel.move_toward(Vector2.ZERO,75.0*delta)
	if Input.is_action_pressed("action_accel"):
		player_vel += Vector2(65,0)*delta
	player_vel.x=clamp(player_vel.x,-80,260)
	player += player_vel*delta
	bull += bull_vel*delta
	player.x=clamp(player.x,120,1050)
	player.y=clamp(player.y,190,570)
	if bull.x < 180:
		bull.x=1050
		bull.y=randf_range(240,520)
	var distance=player.distance_to(bull)
	if distance < 125 and not qte_active and qte_cooldown<=0 and not grabbed:
		qte_active=true
		qte_pos=Vector2(randf_range(420,940),randf_range(210,500))
		qte_radius=92
		qte_result=""
	if qte_active:
		qte_radius=max(18,qte_radius-qte_speed*delta)
	if grabbed:
		bull += Vector2(120,0)*delta
		player += Vector2(95,0)*delta
	if qte_active and Input.is_action_just_pressed("action_grab"):
		try_grab()
	if elapsed >= turn_time:
		total_score += score
		screen="result"

func try_grab():
	if not qte_active:
		return
	var perfect_min=34.0
	var good_min=52.0
	var regular_min=70.0
	if qte_radius <= perfect_min:
		qte_result="¡COLEO PERFECTO!"
		score += 3.5
		grabbed=true
	elif qte_radius <= good_min:
		qte_result="¡COLEO BUENO!"
		score += 2.5
		grabbed=true
	elif qte_radius <= regular_min:
		qte_result="COLEO REGULAR"
		score += 1.5
		grabbed=true
	else:
		qte_result="FALLO"
		score += 0
	qte_active=false
	qte_cooldown=1.5

func draw_button(rect:Rect2, label:String, id:String, accent:=Color("#17344b")):
	buttons.append({"id":id,"pos":rect.position,"size":rect.size})
	draw_rect(rect,accent,true)
	draw_rect(rect,Color("#2e526d"),false,3)
	draw_string(font,rect.position+Vector2(20,rect.size.y*0.63),label,HORIZONTAL_ALIGNMENT_CENTER,rect.size.x-40,24,WHITE)

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
		"tournaments": draw_tournaments()
		"shop": draw_shop()
		"profile": draw_profile()
		"settings": draw_settings()
		"music": draw_music()

func title(text:String, y:=70.0, size:=44):
	draw_string(font,Vector2(0,y),text,HORIZONTAL_ALIGNMENT_CENTER,W,size,WHITE)

func draw_menu():
	# Fondo principal tipo portada deportiva
	draw_rect(Rect2(0,0,W,H),Color("#06101a"),true)
	draw_rect(Rect2(0,0,W,235),Color("#102c3b"),true)
	draw_rect(Rect2(0,235,W,H-235),Color("#091824"),true)
	
	# Luces de estadio
	draw_circle(Vector2(1110,90),170,Color(0.25,0.75,0.9,0.07))
	draw_circle(Vector2(160,620),190,Color(0.95,0.55,0.15,0.05))
	for i in 0..7:
		var beam_x=520+i*92
		draw_polygon(PackedVector2Array([
			Vector2(beam_x,0),Vector2(beam_x+18,0),Vector2(beam_x+110,235),Vector2(beam_x+60,235)
		]),PackedColorArray([Color(0.7,0.9,1.0,0.025),Color(0.7,0.9,1.0,0.025),Color(0.7,0.9,1.0,0.025),Color(0.7,0.9,1.0,0.025)]))
	
	# Marca
	draw_string(font,Vector2(48,62),"CNBC",HORIZONTAL_ALIGNMENT_LEFT,-1,48,GOLD)
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
	for i in 0..11:
		var sx=630+i*49
		draw_line(Vector2(sx,132),Vector2(sx,198),Color("#d7cfad"),3)
		draw_circle(Vector2(sx,126),8,Color("#d83b45") if i%3==0 else Color("#eee6c9"))
	for i in 0..16:
		draw_circle(Vector2(625+i*34,178+(i%3)*5),4,Color("#d7dde0"))
	
	# Acción principal de la portada
	draw_speed_dust(Vector2(870,310))
	draw_character(Vector2(850,300),horse_colors[selected_horse],skin,hair,beard)
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
	
	# Pie de navegación
	draw_rect(Rect2(48,540,522,58),Color("#0e2533"),true)
	draw_string(font,Vector2(70,576),"⚙  AJUSTES",HORIZONTAL_ALIGNMENT_LEFT,-1,18,WHITE)
	draw_string(font,Vector2(270,576),"ANDROID  •  V1",HORIZONTAL_ALIGNMENT_LEFT,-1,16,MUTED)
	draw_string(font,Vector2(415,576),"●  EN DESARROLLO",HORIZONTAL_ALIGNMENT_LEFT,-1,15,GREEN)
	
	# Perfil rápido
	draw_rect(Rect2(612,535,598,48),Color(0.02,0.06,0.08,0.78),true)
	draw_string(font,Vector2(635,566),"COLEADOR NOVATO",HORIZONTAL_ALIGNMENT_LEFT,-1,16,WHITE)
	draw_string(font,Vector2(900,566),"MONEDAS  %d"%coins,HORIZONTAL_ALIGNMENT_LEFT,-1,16,GOLD)
	draw_string(font,Vector2(1060,566),"● ONLINE",HORIZONTAL_ALIGNMENT_LEFT,-1,15,GREEN)


func draw_manga_preview(pos:Vector2,size:Vector2):
	draw_rect(Rect2(pos,size),Color("#1c3440"),true)
	draw_rect(Rect2(pos+Vector2(18,18),size-Vector2(36,36)),Color("#9b6b43"),true)
	for i in 0..9:
		draw_line(pos+Vector2(25+i*40,25),pos+Vector2(25+i*40,55),Color("#b7b7a4"),4)
	draw_circle(pos+Vector2(170,145),42,horse_colors[selected_horse])
	draw_circle(pos+Vector2(265,135),31,bull_colors[selected_bull])
	draw_line(pos+Vector2(180,160),pos+Vector2(250,145),Color("#e8c27a"),5)
	draw_string(font,pos+Vector2(105,255),"MANGA DE COLEO",HORIZONTAL_ALIGNMENT_LEFT,-1,20,WHITE)

func draw_game():
	# Cielo y graderío
	draw_rect(Rect2(0,0,W,H),Color("#7db8d0"),true)
	draw_rect(Rect2(0,0,W,155),Color("#6da9c3"),true)
	draw_circle(Vector2(1060,72),34,Color("#f4d98a"))
	
	# Gradas en profundidad
	draw_rect(Rect2(0,88,W,70),Color("#263844"),true)
	for row in 0..2:
		var ry=102+row*20
		draw_line(Vector2(20,ry),Vector2(1260,ry),Color("#455866"),7)
		for i in 0..31:
			var sx=25+i*40+(row%2)*10
			var shirt=Color("#d9e1e5") if i%4 else Color("#c93d46")
			draw_circle(Vector2(sx,ry-7),4,shirt)
	
	# Banderas y postes
	for i in 0..15:
		var fx=25+i*82
		draw_line(Vector2(fx,55),Vector2(fx,178),Color("#6b5140"),3)
		var fc=Color("#c93743") if i%2==0 else Color("#f0e4b5")
		draw_colored_polygon(PackedVector2Array([
			Vector2(fx,58),Vector2(fx+32,68),Vector2(fx,78)
		]),fc)
	
	# Baranda de la manga
	draw_rect(Rect2(0,154,W,12),Color("#e9dfb7"),true)
	draw_line(Vector2(0,166),Vector2(W,166),Color("#71583f"),5)
	for i in 0..25:
		var bx=i*52
		draw_line(Vector2(bx,145),Vector2(bx,183),Color("#d8d0b2"),4)
	
	# Piso de arena con zonas de rodada
	draw_rect(Rect2(0,184,W,H-184),Color("#9a6844"),true)
	draw_rect(Rect2(0,184,W,H-184),Color("#a9754b"),false,8)
	for i in 0..20:
		var gx=40+i*61
		draw_line(Vector2(gx,205),Vector2(gx+120,680),Color(0.34,0.22,0.14,0.12),2)
	for i in 0..10:
		var gy=225+i*42
		draw_line(Vector2(20,gy),Vector2(1260,gy+28),Color(0.95,0.78,0.55,0.08),3)
	
	# Polvo y huellas
	for i in 0..18:
		var dx=60+i*67
		var dy=585-(i%4)*23
		draw_circle(Vector2(dx,dy),3+(i%3)*2,Color(0.92,0.78,0.58,0.18))
	
	draw_string(font,Vector2(28,38),"CNBC  •  MANGA DE COLEO",HORIZONTAL_ALIGNMENT_LEFT,-1,27,WHITE)
	draw_string(font,Vector2(930,38),"PUNTOS  %.2f"%score,HORIZONTAL_ALIGNMENT_LEFT,-1,24,GOLD)
	draw_string(font,Vector2(1110,38),"%.0f s"%max(0.0,turn_time-elapsed),HORIZONTAL_ALIGNMENT_LEFT,-1,22,WHITE)
	
	# Placa de turno
	draw_rect(Rect2(24,202,245,54),Color(0.03,0.08,0.12,0.78),true)
	draw_rect(Rect2(24,202,245,54),Color("#e6c24d"),false,2)
	draw_string(font,Vector2(42,237),"TURNO  •  COLEO VENEZOLANO",HORIZONTAL_ALIGNMENT_LEFT,-1,17,GOLD)
	
	# Polvo detrás de los animales para sensación de velocidad
	draw_speed_dust(player)
	draw_speed_dust(bull)
	
	draw_character(player,horse_colors[selected_horse],skin,hair,beard)
	draw_bull(bull,bull_colors[selected_bull])
	
	if qte_active:
		# Indicador de oportunidad: objetivo externo + zona exacta
		draw_circle(qte_pos,qte_radius,Color(0.98,0.83,0.22,0.12))
		draw_arc(qte_pos,qte_radius,0,TAU,64,GOLD,7)
		draw_arc(qte_pos,34,0,TAU,48,WHITE,4)
		draw_circle(qte_pos,13,Color("#f6f3df"))
		draw_string(font,qte_pos+Vector2(-78,-qte_radius-18),"¡AGARRA LA COLA!",HORIZONTAL_ALIGNMENT_CENTER,156,19,GOLD)
		draw_string(font,qte_pos+Vector2(-70,62),"ENCUENTRA EL MOMENTO",HORIZONTAL_ALIGNMENT_CENTER,140,14,WHITE)
	
	if grabbed:
		draw_rect(Rect2(430,108,420,55),Color(0.02,0.09,0.10,0.82),true)
		draw_string(font,Vector2(430,146),qte_result,HORIZONTAL_ALIGNMENT_CENTER,420,31,GREEN)
	
	# Joystick táctil izquierdo
	draw_circle(Vector2(145,H-128),108,Color(0.02,0.06,0.09,0.72))
	draw_arc(Vector2(145,H-128),108,0,TAU,48,Color(0.75,0.84,0.88,0.32),3)
	draw_circle(Vector2(145,H-128),58,Color(0.10,0.18,0.23,0.9))
	draw_arc(Vector2(145,H-128),58,0,TAU,40,Color(0.9,0.9,0.82,0.32),3)
	draw_string(font,Vector2(95,H-122),"MOVER",HORIZONTAL_ALIGNMENT_CENTER,100,17,WHITE)
	
	# Botones de acción derecha
	draw_circle(Vector2(1035,H-130),67,Color(0.02,0.06,0.09,0.78))
	draw_arc(Vector2(1035,H-130),67,0,TAU,40,Color("#e8d18a"),4)
	draw_string(font,Vector2(985,H-125),"FRENAR",HORIZONTAL_ALIGNMENT_CENTER,100,16,WHITE)
	draw_circle(Vector2(1135,H-130),72,Color(0.52,0.12,0.13,0.88))
	draw_arc(Vector2(1135,H-130),72,0,TAU,40,Color("#f3d16b"),4)
	draw_string(font,Vector2(1080,H-125),"AGARRAR",HORIZONTAL_ALIGNMENT_CENTER,110,17,WHITE)
	draw_string(font,Vector2(1080,H-77),"COLA",HORIZONTAL_ALIGNMENT_CENTER,110,15,GOLD)
	
	# Aceleración y mini guía
	draw_rect(Rect2(950,520,260,52),Color(0.02,0.06,0.09,0.68),true)
	draw_string(font,Vector2(968,553),"↑ ACELERAR     •     FRENAR",HORIZONTAL_ALIGNMENT_LEFT,-1,16,WHITE)

func draw_speed_dust(p:Vector2):
	for i in 0..7:
		var off=Vector2(-55-i*11,24+(i%3)*8)
		var r=3+(i%3)*2
		draw_circle(p+off,r,Color(0.95,0.82,0.62,0.12+(i%3)*0.025))

func draw_character(p:Vector2, hc:Color, sc:Color, hairc:Color, beardc:Color):
	# Sombra de contacto
	draw_ellipse(p+Vector2(0,45),Vector2(78,16),Color(0.10,0.06,0.04,0.28))
	# Patas y cascos
	for leg_x in [-38.0,-10.0,18.0,45.0]:
		draw_line(p+Vector2(leg_x,18),p+Vector2(leg_x-4,60),Color("#3a251c"),9)
		draw_rect(Rect2(p+Vector2(leg_x-9,57),Vector2(18,7)),Color("#1b1716"),true)
	# Cuerpo del caballo
	draw_ellipse(p+Vector2(0,8),Vector2(72,34),hc)
	draw_ellipse(p+Vector2(-28,-3),Vector2(40,25),hc.lightened(0.12))
	# Cuello y cabeza
	draw_polygon(PackedVector2Array([
		p+Vector2(36,-12),p+Vector2(57,-61),p+Vector2(88,-67),p+Vector2(97,-43),p+Vector2(73,-18)
	]),PackedColorArray([hc,hc.lightened(0.1),hc,hc]))
	draw_circle(p+Vector2(82,-51),24,hc.lightened(0.08))
	# Orejas
	draw_colored_polygon(PackedVector2Array([
		p+Vector2(70,-67),p+Vector2(70,-93),p+Vector2(82,-70)
	]),hc)
	draw_colored_polygon(PackedVector2Array([
		p+Vector2(88,-68),p+Vector2(100,-91),p+Vector2(101,-58)
	]),hc.darkened(0.05))
	# Crin
	for i in 0..4:
		draw_line(p+Vector2(48+i*7,-57-i*2),p+Vector2(36+i*5,-42+i*3),hairc,5)
	# Ojo y hocico
	draw_circle(p+Vector2(90,-55),4,Color("#10151a"))
	draw_circle(p+Vector2(91,-56),1.5,WHITE)
	draw_circle(p+Vector2(101,-43),8,hc.lightened(0.18))
	# Silla y cincha
	draw_rect(Rect2(p+Vector2(-28,-12),Vector2(58,11)),Color("#6b3825"),true)
	draw_rect(Rect2(p+Vector2(-17,-2),Vector2(42,8)),Color("#d9ad57"),true)
	draw_line(p+Vector2(-8,-4),p+Vector2(-8,28),Color("#35231c"),4)
	# Coleador encima de la silla
	draw_circle(p+Vector2(-3,-42),17,sc)
	draw_rect(Rect2(p+Vector2(-19,-61),Vector2(34,8)),hairc,true)
	draw_colored_polygon(PackedVector2Array([
		p+Vector2(-22,-52),p+Vector2(20,-52),p+Vector2(15,-24),p+Vector2(-16,-24)
	]),Color("#274e68"))
	draw_line(p+Vector2(-14,-24),p+Vector2(-28,7),Color("#274e68"),8)
	draw_line(p+Vector2(12,-24),p+Vector2(29,5),Color("#274e68"),8)
	# Brazos y riendas
	draw_line(p+Vector2(12,-45),p+Vector2(45,-25),sc,6)
	draw_line(p+Vector2(45,-25),p+Vector2(82,-42),Color("#d8b26c"),3)
	draw_line(p+Vector2(0,-43),p+Vector2(38,-27),Color("#d8b26c"),3)
	# Barba configurable
	if hair_style==1:
		draw_circle(p+Vector2(92,-37),8,beardc)
	elif hair_style==2:
		draw_line(p+Vector2(83,-35),p+Vector2(99,-30),beardc,6)
	# Cola del caballo
	draw_line(p+Vector2(-68,2),p+Vector2(-94,-20),hairc,7)
	draw_line(p+Vector2(-92,-19),p+Vector2(-106,-3),hairc,5)

func draw_bull(p:Vector2,c:Color):
	# Sombra
	draw_ellipse(p+Vector2(0,48),Vector2(86,15),Color(0.10,0.06,0.04,0.25))
	# Patas
	for leg_x in [-55.0,-22.0,22.0,57.0]:
		draw_line(p+Vector2(leg_x,18),p+Vector2(leg_x-3,62),c.darkened(0.28),10)
		draw_rect(Rect2(p+Vector2(leg_x-8,58),Vector2(16,7)),Color("#191817"),true)
	# Tronco musculoso
	draw_ellipse(p,Vector2(86,39),c)
	draw_ellipse(p+Vector2(-18,-5),Vector2(55,28),c.lightened(0.10))
	# Cuello y cabeza
	draw_ellipse(p+Vector2(70,-13),Vector2(34,31),c.darkened(0.05))
	draw_ellipse(p+Vector2(94,-22),Vector2(37,28),c)
	# Cuernos
	draw_line(p+Vector2(104,-43),p+Vector2(128,-69),Color("#eee1bd"),7)
	draw_line(p+Vector2(122,-45),p+Vector2(148,-64),Color("#eee1bd"),7)
	draw_line(p+Vector2(128,-69),p+Vector2(136,-75),Color("#cbb98e"),4)
	draw_line(p+Vector2(148,-64),p+Vector2(156,-68),Color("#cbb98e"),4)
	# Ojo, nariz y frente
	draw_circle(p+Vector2(113,-27),5,Color("#111214"))
	draw_circle(p+Vector2(114,-28),2,WHITE)
	draw_circle(p+Vector2(124,-10),7,c.darkened(0.2))
	draw_circle(p+Vector2(127,-9),2,Color("#151515"))
	# Cola con punta de pelo
	draw_line(p+Vector2(-82,2),p+Vector2(-125,22),c.darkened(0.18),8)
	draw_line(p+Vector2(-124,22),p+Vector2(-139,14),Color("#211a16"),7)
	# Destellos de polvo en patas
	for i in 0..5:
		draw_circle(p+Vector2(-60+i*22,64+(i%2)*5),3,Color(0.95,0.78,0.56,0.22))


func draw_ellipse(center:Vector2,r:Vector2,c:Color):
	var pts=PackedVector2Array()
	for i in 0..31:
		var a=TAU*i/32.0
		pts.append(center+Vector2(cos(a)*r.x,sin(a)*r.y))
	draw_colored_polygon(pts,c)

func draw_result():
	title("FIN DEL TURNO",100,48)
	draw_string(font,Vector2(0,190),"RESULTADO",HORIZONTAL_ALIGNMENT_CENTER,W,28,MUTED)
	draw_string(font,Vector2(0,245),"PUNTUACIÓN: %.2f"%score,HORIZONTAL_ALIGNMENT_CENTER,W,52,GOLD)
	var msg="Sigue entrenando para dominar la manga."
	if score>=7: msg="¡Actuación de campeón!"
	elif score>=4: msg="¡Buen turno!"
	draw_string(font,Vector2(0,305),msg,HORIZONTAL_ALIGNMENT_CENTER,W,28,WHITE)
	draw_button(Rect2(460,410,360,70),"VOLVER AL MENÚ","back",RED)
	draw_button(Rect2(460,500,360,70),"OTRO TURNO","play",PANEL2)

func draw_horses():
	title("CABALLOS",80)
	draw_string(font,Vector2(0,125),"Pelajes inspirados en el caballo criollo venezolano",HORIZONTAL_ALIGNMENT_CENTER,W,22,MUTED)
	draw_circle(Vector2(640,300),90,horse_colors[selected_horse])
	draw_string(font,Vector2(0,430),horse_names[selected_horse],HORIZONTAL_ALIGNMENT_CENTER,W,40,WHITE)
	draw_string(font,Vector2(0,470),"Precio de establo: 500 monedas",HORIZONTAL_ALIGNMENT_CENTER,W,20,MUTED)
	draw_button(Rect2(300,540,150,65),"‹","prev_horse")
	draw_button(Rect2(465,540,350,65),"COMPRAR / SELECCIONAR","buy_horse",RED)
	draw_button(Rect2(830,540,150,65),"›","next_horse")
	draw_button(Rect2(470,630,340,55),"VOLVER","back")

func draw_bulls():
	title("TOROS",80)
	draw_string(font,Vector2(0,125),"Variantes para la primera temporada",HORIZONTAL_ALIGNMENT_CENTER,W,22,MUTED)
	draw_bull(Vector2(640,315),bull_colors[selected_bull])
	draw_string(font,Vector2(0,430),bull_names[selected_bull],HORIZONTAL_ALIGNMENT_CENTER,W,40,WHITE)
	draw_button(Rect2(300,540,150,65),"‹","prev_bull")
	draw_button(Rect2(465,540,350,65),"SELECCIONAR","next_bull",RED)
	draw_button(Rect2(830,540,150,65),"›","next_bull")
	draw_button(Rect2(470,630,340,55),"VOLVER","back")

func draw_custom():
	title("COLEADOR",80)
	draw_string(font,Vector2(0,125),"Personaliza tu atleta",HORIZONTAL_ALIGNMENT_CENTER,W,22,MUTED)
	draw_character(Vector2(430,310),horse_colors[selected_horse],skin,hair,beard)
	draw_button(Rect2(650,200,420,58),"CAMBIAR PIEL","skin")
	draw_button(Rect2(650,275,420,58),"CAMBIAR CABELLO","hair")
	draw_button(Rect2(650,350,420,58),"ESTILO DE CABELLO / BARBA","style")
	draw_button(Rect2(650,425,420,58),"COLOR DE BARBA","beard")
	draw_button(Rect2(650,510,420,58),"GUARDAR PERSONAJE","back",RED)
	draw_button(Rect2(470,630,340,55),"VOLVER","back")

func draw_tournaments():
	title("TORNEOS",80)
	draw_string(font,Vector2(0,135),"Campeonatos y copas",HORIZONTAL_ALIGNMENT_CENTER,W,22,MUTED)
	var names=["Copa Cheo Hernández","Campeonato Categoría C","Campeonato Categoría B","Campeonato Categoría A"]
	for i in names.size():
		draw_button(Rect2(340,185+i*85,600,62),names[i],"play",PANEL2)
	draw_button(Rect2(470,630,340,55),"VOLVER","back")

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
	draw_string(font,Vector2(0,260),"Caballo: %s"%horse_names[selected_horse],HORIZONTAL_ALIGNMENT_CENTER,W,22,MUTED)
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
