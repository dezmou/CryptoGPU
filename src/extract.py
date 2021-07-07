import struct

# unix,date,symbol,open,high,low,close,Volume BTC,Volume USD

with open("all.csv", "r") as f:
    final = ""
    with open("data", "wb") as ff:
        lines = f.read().split("\n")[:1]
        lines.reverse()
        for i in range(0, len(lines)):
            line = lines[i]
            try:
                if (line == ""):
                    break
                chien = lines[i]
                data = line.split(",")
                time = int(data[0])
                timeStr = data[1]
                symbol = data[2]
                open = float(data[3])
                high = float(data[4])
                low = float(data[5])
                close = float(data[6])
                volumeBtc = float(data[7])
                volumeUsd = float(data[8])
                # ff.write(struct.pack("ifffff", time, open, high, low, close,volumeUsd))
                ff.write(struct.pack("qddddd", time, open, high, low, close,volumeUsd))

            except Exception as e:
                print data[0]
                print e
                break