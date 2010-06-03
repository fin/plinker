from optparse import OptionParser
from threading import Thread
import time
import json

import pcapy
from scapy.layers.all import IP, Ether,ICMP, TCP
import pydb
import netifaces
import OSC            # pyOSC



parser = OptionParser()
parser.add_option('-c', '--connect', default='localhost:9999', help='osc host:port to connect to')
parser.add_option('-i', '--interface', default='eth0', help='network interface to listen on')

(options, args) = parser.parse_args()
print options
print args

# global variables
nw_traffic_in_global = {}
nw_traffic_out_global = {}
icmp_traffic_global = {}


def main():
    kbints = 0

    # begin listening to network traffic
    interface = options['interface']
    interface_address = netifaces.ifaddresses(interface)[2][0]['addr']

    # create and start threads
    network_traffic = communication_thread("no_icmp")
    network_traffic.start()
    icmp_traffic = communication_thread("only_icmp")
    icmp_traffic.start()

    p = pcapy.open_live(interface, 1024, False, 10240)

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
                icmp_traffic_global.update({'ping': True})

            second = header.getts()[0] # [1] = miliseconds
            (header, payload) = p.next()
    except KeyboardInterrupt:
        print 'kbint %d' % kbints
        kbints+=1
        if kbints>2:
            print 'quitting %d' % kbints
            return
    except Exception,e:
        print e
    
    
    # setting status to false ends the threadss
    network_traffic.status = False
    icmp_traffic.status = False
    
    #bar.status = False
    print "goodbye"

# thread class
class communication_thread(Thread):
    def __init__(self, mode):
        Thread.__init__(self)
        self.mode = mode
        self.value = 1

        # the interval in which the synchronized mode
        # sends data to chuck in seconds.
        self.interval = 1
        # if status turns to False, thread will stop.
        self.status = True
        
    def run(self):
        if self.mode == "only_icmp":
            # asynchronus mode. get icmp packets and 
            # send them directly to chuck via osc      
            while self.status == True:
                if icmp_traffic_global:            
                    print "asynchronus. value: " + json.dumps(icmp_traffic_global)
                    # send data to chuck
                    # remove values in array
                    icmp_traffic_global.clear()                

        else:
            # synchronus mode. every n (interval) seconds we send 
            # the data to chuck
            while self.status == True:
                print "inbound : " + json.dumps(nw_traffic_in_global)
                print "outbound: " + json.dumps(nw_traffic_out_global)
                # send data to chuck
                # remove values in array                
                nw_traffic_in_global.clear()
                nw_traffic_out_global.clear()                
                # wait
                time.sleep(self.interval)

main()

