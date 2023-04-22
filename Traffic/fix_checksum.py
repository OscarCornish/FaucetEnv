import sys
from scapy.all import *

if len(sys.argv) != 3: 
    print("Usage:./ChecksumFixer  <input_pcap_file> <output_pcap_file>")
    print("Example: ./ChecksumFixer input.pcap output.pcap")
    sys.exit(1)

#------------------------Command Line Argument---------------------------------------

input_file = sys.argv[1]
output_file = sys.argv[2]

#------------------------Get The layer and Fix Checksum-------------------------------

def getLayer(p):
    for paktype in (IP, TCP, UDP, ICMP):
        try:
            p.getlayer(paktype).chksum = None
        except: AttributeError
        pass
    return p
#-----------------------FixPcap in input file and write to output file----------------

def fixpcap():
    paks = rdpcap(input_file)
    fc = map(getLayer, paks)
    wrpcap(output_file, fc) 

if __name__ == "__main__":
    fixpcap()