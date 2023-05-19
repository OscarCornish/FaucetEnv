from netfilterqueue import NetfilterQueue
import scapy.all as scapy
import os, sys

os.system("iptables -F")
os.system("iptables -F -t nat")
os.system("iptables -A FORWARD -j NFQUEUE --queue-num 0")

def null_IP_Identification(_packet):
    packet = scapy.IP(_packet.get_payload())
    if packet.haslayer(scapy.IP) and packet[scapy.IP].id != 0:
        print("IP ID: " + str(packet[scapy.IP].id) + " -> 0")
        packet[scapy.IP].id = 0
        packet[scapy.IP].chksum = None
        _packet.set_payload(bytes(packet))
    _packet.accept()

def map_TCP_ACK(_packet):
    packet = scapy.IP(_packet.get_payload())
    if packet.haslayer(scapy.TCP):
        packet[scapy.TCP].ack = 0
        packet[scapy.TCP].chksum = None
        _packet.set_payload(bytes(packet))
    _packet.accept()

if __name__ == "__main__":
    queue = NetfilterQueue()
    queue.bind(0, globals()[sys.argv[1]])
    try:
        print("Using filter: '" + sys.argv[1] + "'")
        queue.run()
    except KeyboardInterrupt:
        print("\nFlushing iptables...")
        os.system("iptables -F")
        os.system("iptables -F -t nat")
        print("Exiting...")
        exit(0)