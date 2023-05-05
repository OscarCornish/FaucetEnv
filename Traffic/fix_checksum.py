import sys
import scapy.all as scapy

def null_checksum(packet):
    for layer in (scapy.IP, scapy.TCP, scapy.UDP, scapy.ICMP):
        if packet.haslayer(layer):
            print(layer)
            packet[layer].chksum = None
    return packet

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: ./fix_checksum.py <input_pcap_file> <output_pcap_file>")
        exit(-1)
    _packets = scapy.rdpcap(sys.argv[1])
    packets = map(null_checksum, _packets)
    scapy.wrpcap(sys.argv[2], packets)
    exit(0)
