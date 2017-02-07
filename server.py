from bottle import route, run, response
import subprocess
import json
import yaml
import os
import sys

# Config
cfg = None
with open("config.yml", 'r') as ymlfile:
    cfg = yaml.load(ymlfile)
port = cfg["port"]
interface = cfg["bind"]
external_prefix = cfg["external_prefix"]


def get_script_path():
    return os.path.dirname(os.path.realpath(sys.argv[0]))

def stopContainer(name):
    subprocess.Popen(["lxc-stop","-n",name,"-k"], stdout=subprocess.PIPE).stdout.read()

def startContainer(name):
    subprocess.Popen(["lxc-start","-n",name,"-d"], stdout=subprocess.PIPE).stdout.read()

def destroyContainer(name):
    subprocess.Popen([get_script_path()+"/delete_container.sh","-n",name], stdout=subprocess.PIPE).stdout.read()

def getPorts(name):
    output = subprocess.Popen([get_script_path()+"/showPorts.sh","-n",name], stdout=subprocess.PIPE).stdout.read()
    portsStrings = output.rstrip().split("\n")
    ports = []
    for line in portsStrings:
      ports.append(int(line))
    return ports

def containerInfos(name):
    output = subprocess.Popen(["lxc-info","-n",name], stdout=subprocess.PIPE).stdout.read()
    lines = output.rstrip().split("\n")
    props = {}
    for line in lines:
      kv = line.split(":")
      kv[0]=kv[0].lower().title().replace(" ", "")
      kv[1]=kv[1].strip()
      props[kv[0]]=kv[1]
    if 'Ip' in props.keys():
      internalIp = props['Ip']
      lastDigit = internalIp.split(".").pop()
      externalIp = external_prefix+lastDigit
      props['ExternalIp']=externalIp
      props['InternalIp']=internalIp
      del props['Ip']
    props['ports']=getPorts(name)
    return props

def listContainers():
    names = subprocess.Popen("lxc-ls", stdout=subprocess.PIPE).stdout.read().rstrip().split("\n")
    containers = {}
    for name in names:
      containers[name] = containerInfos(name)
    return containers   

@route('/containers/')
def containers():
    response.content_type = 'application/json'
    return json.dumps(listContainers())

@route('/containers/<name>')
def container(name):
    response.content_type = 'application/json'
    return json.dumps(listContainers()[name])

@route('/containers/<name>/destroy')
def destroy(name):
    response.content_type = 'application/json'
    destroyContainer(name)
    return json.dumps(listContainers())

@route('/containers/<name>/start')
def start(name):
    response.content_type = 'application/json'
    startContainer(name)
    return json.dumps(listContainers()[name])

@route('/containers/<name>/stop')
def stop(name):
    response.content_type = 'application/json'
    stopContainer(name)
    return json.dumps(listContainers()[name])

run(host=interface, port=port, debug=True)

