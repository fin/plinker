from threading import Thread
import time
import json

# global variables
nw_traffic_global = {}
icmp_traffic_global = {}

def main():    
    network_interface = "eth0"

    # create and start threads
    network_traffic = communication_thread("no_icmp", 100)
    network_traffic.start()
    icmp_traffic = communication_thread("only_icmp", 100)
    icmp_traffic.start()

    nw_traffic_global.update({'bar': 'foo'}) 

    raw_input("press [enter] to stop.\n")

    # change nw_traffic_global and icmp_traffic_global
    nw_traffic_global.update({'foo': 'bar'})
    icmp_traffic_global.update({'icmp': 'awesome'})

    raw_input("press [enter] to stop.\n")

    # setting status to false ends the threadss
    network_traffic.status = False
    icmp_traffic.status = False
    
    #bar.status = False
    print "goodbye"

# thread class
class communication_thread(Thread):
    def __init__(self, mode, timeout):
        Thread.__init__(self)
        self.timeout = timeout
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
                print "synchronus. waiting a second. value: " + json.dumps(nw_traffic_global)
                self.value+=1
                # send data to chuck
                # remove values in array                
                nw_traffic_global.clear()
                # wait
                time.sleep(self.interval)

main()

