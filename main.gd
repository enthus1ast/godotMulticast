extends Panel

signal foundServers
export var timeout = 2.5
export var multicastGroup = "239.255.255.249"
export var port = 1900

var findThread
var findGameTimer
var announceThread
#
#func _ready():
#	pass

func _on_timer_timeout():
	var servers = findThread.wait_to_finish()
	findGameTimer.stop()
	emit_signal("foundServers", servers)
#	findGameTimer.queue_free()

func threadFuncFinding(userdata):
#	print("threadfunc find gd")
	var servers = get_node("Node2D")._find_game(timeout, multicastGroup, port)
	return servers

func startFindingGame():
	if findThread != null and findThread.is_active():
		print("Already finding games!")
		return	
	findThread = Thread.new()
	print("Start finding game")
	findThread.start(self, "threadFuncFinding" )
	findGameTimer = Timer.new()
	findGameTimer.wait_time = timeout
	findGameTimer.connect("timeout",self,"_on_timer_timeout") 
	add_child(findGameTimer)
	findGameTimer.start()
	
func threadFuncAnnouncing(userdata):
	var scanner = get_node("Node2D")
	scanner.announcing_game(multicastGroup, port)	

func startAnnouncingGame():
	if announceThread != null and announceThread.is_active():
		print("Already announcing games!")
		return
	announceThread = Thread.new()
	print("Start announcing game")
	announceThread.start(self, "threadFuncAnnouncing")

#### USAGE DEMO! ##################################
onready var labelStatus = get_node("LabelStatus")
func _on_Button_pressed():
	labelStatus.text = "Searching games...."
	startFindingGame()

func _on_Button2_pressed():
	startAnnouncingGame()

func _on_Panel_foundServers(servers):
	pass # replace with function body
	labelStatus.text += "DONE!"
	print(servers)
	var labelServer = get_node("LabelServers")
	labelServer.text = ""
	for server in servers:
		labelServer.text += server + "\n"		
