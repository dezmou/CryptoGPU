import struct

with open("ETH_USDT.csv", "r") as f:
    final = ""
    with open("ETHUSDT", "wb") as ff:
        i = 0
        for line in f.read().split("\n")[1:]:
            if (line == ""):
                break
            data = line.split(",")
            time = int(data[0])
            open = float(data[1])
            high = float(data[2])
            low = float(data[3])
            close = float(data[4])
            volume = float(data[5])
            
            i += 1
            # ff.write(struct.pack("qddddd", time, open, high, low, close,volume))