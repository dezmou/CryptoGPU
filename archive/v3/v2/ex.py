import struct

def getData(line):
    return {
            "time" : int(data[0]),
            "open" : float(data[1]),
            "high" : float(data[2]),
            "low" : float(data[3]),
            "close" : float(data[4]),
            "volume" : float(data[5])
    }

with open("BTCUSDT.csv", "r") as f:
    final = ""
    with open("chien", "wb") as ff:
        lines = f.read().split("\n")[1:]
        for i in range(0, len(lines)):
            line = lines[i]
            if (line == ""):
                break
            chien = lines[i]
            data = line.split(",")
            time = int(data[0])
            open = float(data[1])
            high = float(data[2])
            low = float(data[3])
            close = float(data[4])
            volume = float(data[5])
            if (i > 1500):
                totalAvg = 0.0
                nbr = 0
                for y in range(-900, -100):
                    nbr += 1
                    chien1 = lines[i+y]
                    data1 = chien1.split(",")
                    totalAvg +=  1-(float(data[2]) / float(data[3]))
                    print(totalAvg)
                    # input()

                # print("{}".format(totalAvg / nbr))
        

            # ff.write(struct.pack("qddddd", time, open, high, low, close,volume))