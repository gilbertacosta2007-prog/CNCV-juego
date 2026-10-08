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
	draw_string(font,Vector2(55,55),"CNBC",HORIZONTAL_ALIGNMENT_LEFT,-1,42,GOLD)
	draw_string(font,Vector2(55,88),"CAMPEONATO NACIONAL DE COLEO VENEZOLANO",HORIZONTAL_ALIGNMENT_LEFT,-1,18,MUTED)
	draw_string(font,Vector2(70,170),"TU MANGA. TU CABALLO. TU COLEO.",HORIZONTAL_ALIGNMENT_LEFT,-1,34,WHITE)
	draw_manga_preview(Vector2(780,180),Vector2(430,280))
	draw_button(Rect2(70,225,350,72),"JUGAR","play",RED)
	draw_button(Rect2(70,315,170,62),"CABALLOS","horses")
	draw_button(Rect2(250,315,170,62),"COLEADORES","coleadores")
	draw_button(Rect2(70,390,170,62),"TOROS","bulls")
	draw_button(Rect2(250,390,170,62),"TORNEOS","tournaments")
	draw_button(Rect2(70,465,170,62),"TIENDA","shop")
	draw_button(Rect2(250,465,170,62),"PERFIL","profile")
	draw_button(Rect2(70,540,170,62),"AJUSTES","settings")
	draw_button(Rect2(250,540,170,62),"MÚSICA","music")
	draw_string(font,Vector2(70,660),"Prototipo V1 • Android • Pixel art con profundidad",HORIZONTAL_ALIGNMENT_LEFT,-1,18,MUTED)

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
	draw_ellipse(p+Vector2(0,24),Vector2(62,25),Color("#2c2020"))
	draw_ellipse(p+Vector2(0,0),Vector2(58,30),hc)
	draw_circle(p+Vector2(15,-32),16,sc)
	draw_rect(Rect2(p+Vector2(0,-49),Vector2(38,7)),hairc,true)
	if hair_style==1:
		draw_circle(p+Vector2(28,-34),8,beardc)
	elif hair_style==2:
		draw_line(p+Vector2(8,-25),p+Vector2(28,-18),beardc,6)
	draw_line(p+Vector2(-38,3),p+Vector2(42,3),Color("#e8c27a"),5)
	draw_line(p+Vector2(42,3),p+Vector2(62,0),Color("#e8c27a"),5)

func draw_bull(p:Vector2,c:Color):
	draw_ellipse(p,Vector2(72,34),c)
	draw_circle(p+Vector2(60,-5),26,c)
	draw_line(p+Vector2(72,-18),p+Vector2(95,-35),Color("#eee1bd"),5)
	draw_line(p+Vector2(72,0),p+Vector2(96,12),Color("#eee1bd"),5)
	draw_line(p+Vector2(-50,22),p+Vector2(-62,58),Color("#302820"),7)
	draw_line(p+Vector2(-5,24),p+Vector2(-17,60),Color("#302820"),7)
	draw_line(p+Vector2(30,24),p+Vector2(18,60),Color("#302820"),7)
	draw_line(p+Vector2(65,15),p+Vector2(55,50),Color("#302820"),7)
	draw_line(p+Vector2(-72,0),p+Vector2(-105,-15),c,8)

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
