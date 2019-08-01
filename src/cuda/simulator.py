
class Minute:
    def __init__(self, line):
        sp = line.split("-->")
        print sp[0]


class Main:
    lines = []
    def __init__(self):
        with open("result", "r") as f:
            lines = f.readlines()
        for line in lines:
            self.lines.append(Minute(line))

Main()