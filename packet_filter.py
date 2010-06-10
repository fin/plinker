from optparse import OptionParser
from threading import Thread
import time
import json

import pcapy
from scapy.layers.all import IP, Ether,ICMP, TCP
import pydb
import netifaces
import OSC            # pyOSC
import copy


parser = OptionParser()
parser.add_option('-c', '--connect', default='localhost:9999', help='osc host:port to connect to')
parser.add_option('-i', '--interface', default='eth0', help='network interface to listen on')
parser.add_option('-f', '--file', default=None, help='pcap file to load instead of interface')
parser.add_option('-a', '--interface_address', default='127.0.0.1', help='interface-address to help with incoming/outgoing sorting')

(options, args) = parser.parse_args()
print options
print args

hostport = options.connect.split(':')
hostport[1] = int(hostport[1])
hostport = tuple(hostport)

openfile = options.file

oc = OSC.OSCClient()
oc.connect(hostport)

# global variables
nw_traffic_in_global = {}
nw_traffic_out_global = {}


def main():
    kbints = 0

    interface_address=options.interface_address

    if openfile:
        p = pcapy.open_offline(openfile)
    else:
        # begin listening to network traffic
        interface = options.interface
        interface_address = netifaces.ifaddresses(interface)[2][0]['addr']

        p = pcapy.open_live(interface, 1024, False, 10240)

    # create and start threads
    network_traffic = communication_thread()
    network_traffic.start()


    try:
        (header, payload) = p.next()
        while header:
            e = Ether(payload)
            t = e.getlayer(TCP)
            if t:
                i = e.getlayer(IP)
                if i.dst==interface_address:
                    nw_traffic_in_global.setdefault(t.dport,0)
                    nw_traffic_in_global[t.dport]+=1
                else:
                    nw_traffic_out_global.setdefault(t.dport,0)
                    nw_traffic_out_global[t.dport]+=1
                    
            if e.haslayer(ICMP):
                x = OSC.OSCMessage()
                x.setAddress('/plinker/ping')
                x.append(1)
                oc.send(x)
                print 'sent'

            second = header.getts()[0] # [1] = miliseconds
            (header, payload) = p.next()
    except KeyboardInterrupt:
        pass
        # shut down
    except Exception,e:
        print e
    
    try:
        p.close()
    except Exception,e:
        print e
    
    time.sleep(1)
    # setting status to false ends the threadss
    print 'setting status'
    network_traffic.status = False
    print 'set status'
    
    #bar.status = False
    print "goodbye"
    oc.close()

# thread class
class communication_thread(Thread):
    def __init__(self):
        Thread.__init__(self)
        self.value = 1

        self.interval = 0.42
        self.status = True
        
    def run(self):
        traffic_in_last = {}
        traffic_out_last = {}
        while self.status:
            print self.status
            traffic_in = copy.copy(nw_traffic_in_global)
            traffic_out = copy.copy(nw_traffic_in_global)
            nw_traffic_in_global.clear()
            nw_traffic_out_global.clear()

            # send data to chuck
            # remove values in array
            s = 0
            keys = traffic_in.keys()
            keys.extend(traffic_in_last.keys())
            for key in keys:
                current = float(traffic_in.get(key,0))
                if current:
                    current/=traffic_in_last.get(key,current)
                x = OSC.OSCMessage()
                x.setAddress('/plinker/in/port/%s' % current)
                x.append(float(current))
                oc.send(x)
                print (key, current)

            keys = traffic_out.keys()
            keys.extend(traffic_out_last.keys())
            for key in keys:
                current = float(traffic_out.get(key,0))
                if current:
                    current/=traffic_out_last.get(key,current)
                x = OSC.OSCMessage()
                x.setAddress('/plinker/out/port/%s' % key)
                x.append(float(current))
                oc.send(x)
                print (key, current)

            traffic_in_last = traffic_in
            traffic_out_last = traffic_out

            # wait
            time.sleep(self.interval)

main()

