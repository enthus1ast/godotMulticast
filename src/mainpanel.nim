import godot
import scene_tree, resource_loader, packed_scene, panel, global_constants,
       input_event_mouse_button, label, node
import times, os
import net, nativesockets
import "/home/z/.nimble/pkgs/multicast-0.1.0/multicast"
# import multicast # not found??

const
  MSG_LEN = 1024

proc announcingGameImpl*(multicastGroup: string, port: int) =
  ## Waits for find game request and answer to it.
  var
    data: string = ""
    address: string = ""
    answerPort: Port

  var socket = newSocket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
  socket.setSockOpt(OptReuseAddr, true)
  socket.bindAddr(Port(port))

  if not socket.joinGroup(multicastGroup):
    echo("Announce could not join multicast group")
    return

  while true:
    echo "a"
    try:
      discard socket.recvFrom(data, MSG_LEN, address, answerPort )
      if not address.isNil and data == "moin":
        print("got moin from:", address, " ", answerPort)
        discard socket.sendTo(address, Port(answerPort), "LOL") # we answer directly!
    except:
        print(getCurrentExceptionMsg())

proc findGameImpl*(timeout: float, multicastGroup: string, port: int): seq[string] =
  ## Finds open games in the lan
  print("start finding games (nim)")
  var
    data: string = ""
    address: string = ""
    answerPort: Port

  var socket = newSocket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
  socket.setSockOpt(OptReuseAddr, true)
  socket.getFd().setBlocking(false)
  socket.bindAddr(Port(port+1))

  if not socket.joinGroup(multicastGroup):
    echo "could not join multicast group"
  var disc = "moin"
  discard socket.sendTo(multicastGroup, Port(port), disc)
  result = @[]
  let startTime = epochTime()
  while true:
    print "f"
    try:
      address = ""
      data = ""
      discard socket.recvFrom(data, MSG_LEN, address, answerPort )
      if not address.isNil and address != "" and not data.isNil and data == "LOL":
        result.add(address)
    except:
      discard
    if (epochTime() - startTime) > timeout:
      echo "Timeouted"
      break
    sleep(50)
  discard socket.leaveGroup(multicastGroup)

gdobj LanScanner of Node:
  proc announcingGame*(multicastGroup: string, port: int){.gdExport.} =
      announcingGameImpl(multicastGroup, port)

  method findGame*(timeout: float, multicastGroup: string, port: int): seq[string]  =
    result = @[]
    for server in findGameImpl(timeout, multicastGroup, port):
      result.add server
