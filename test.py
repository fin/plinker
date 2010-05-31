import pcapy
from scapy.layers.all import IP, Ether,ICMP, TCP
import pydb
import netifaces
import OSC            # pyOSC

interface = 'wlan0'
interface_address = netifaces.ifaddresses(interface)[2][0]['addr']
print interface_address

p = pcapy.open_live(interface, 1024, False, 10240)
#p = pcapy.open_offline('test.tcpdump')

summary_in = {}
summary_out = {}

try:
    (header, payload) = p.next()
    while header:
        e = Ether(payload)
        t = e.getlayer(TCP)
        if t:
            i = e.getlayer(IP)
            if i.dst==interface_address:
                summary_in.setdefault(t.dport,0)
                summary_in[t.dport]+=1
            else:
                summary_out.setdefault(t.dport,0)
                summary_out[t.dport]+=1

        if e.haslayer(ICMP):
            print 'ping'

        second = header.getts()[0] # [1] = miliseconds
        (header, payload) = p.next()
except KeyboardInterrupt:
    pass
except Exception,e:
    print e
    

print summary_in
print summary_out

