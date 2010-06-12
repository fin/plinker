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
import traceback


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

# global variables
nw_traffic_global = {}
nw_traffic_inout = {'in': 0, 'out': 0}


def main():
    oc = OSC.OSCClient()
    oc.connect(hostport)

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
                nw_traffic_global.setdefault(t.dport,0)
                try:
                    nw_traffic_global[t.dport]+=1
                except KeyError:
                    print 'race'
                nw_traffic_inout['in' if i.dst == interface_address else 'out']+=1
                    
            if e.haslayer(ICMP):
                x = OSC.OSCMessage()
                x.setAddress('/plinker/ping')
                x.append(1)
                oc.send(x)
                print 'sent'

            second = header.getts()[0] # [1] = miliseconds
            
            try:
                (header, payload) = p.next()
            except Exception,e:
                print type(e)
    except Exception,e:
        print traceback.print_exc(e)
    except KeyboardInterrupt:
        pass
        # shut down
    
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
        self.services = {80: 'web', 443: 'web',
                         22: 'ssh',
                         25: 'ftp', 26: 'ftp', 115: 'ftp', 445: 'ftp',  # 445 = samba
                         5222: 'chat', 5269: 'chat', 1863: 'chat', 5190: 'chat', 194: 'chat', 994: 'chat', '6667': 'chat',
                        }
        self.defaultservice = 'all'
        
    def run(self):
        oc = OSC.OSCClient()
        oc.connect(hostport)
        values_last = {}
        while self.status:
            traffic = copy.copy(nw_traffic_global)
            inout = copy.copy(nw_traffic_inout)
            nw_traffic_global.clear()
            nw_traffic_inout.clear()
            nw_traffic_inout['in']=0
            nw_traffic_inout['out']=0

            values = {}
            for (name,value) in values_last.iteritems():
                if value:
                    values[name]=0
            handledservices = []
            # send data to chuck
            # remove values in array
            keys = traffic.keys()
            for key in keys:
                service = self.services.get(key, self.defaultservice)
                current = float(traffic.get(key,0))
                values.setdefault(service, 0.)
                values[service]+=current
                handledservices.append(service)

            for (name, count) in values.iteritems():
                if values.get(name, None):
                    x = OSC.OSCMessage()
                    x.setAddress('/plinker/%s' % name) # no ,f; gets added automagically
                    print x.address
                    current = float(count)/(values_last.get(name, count) or 1)
                    x.append(current)
                    oc.send(x)
                    print (name, current,)

            x = OSC.OSCMessage()
            x.setAddress('/plinker/inout') # no ,f; gets added automagically
            x.append(float(inout['in'])/float(inout['out'] or 1))
            oc.send(x)

            values_last = values

            # wait
            time.sleep(self.interval)

main()

