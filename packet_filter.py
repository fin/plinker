from threading import Thread
import time

# global variables
value_global = "5"

def main():    
    network_interface = "eth0"

    # create and start threads
    network_traffic = communication_thread("no_icmp", 100)
    network_traffic.start()

    raw_input("press [enter] to stop.\n")

    # change value_global
    value_global = "23"

    raw_input("press [enter] to stop.\n")

    # setting status to false ends the threadss
    network_traffic.status = False
    #bar.status = False
    print "goodbye"

# thread class
class communication_thread(Thread):
    def __init__(self, mode, timeout):
        Thread.__init__(self)
        self.timeout = timeout
        self.mode = mode
        self.value =         

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
                print "asynchronus."  

        else:
            # synchronus mode. every n (interval) seconds we send 
            # the data to chuck
            while self.status == True:
                print "synchronus. waiting a second. value: " + value_global
                time.sleep(self.interval)

main()

