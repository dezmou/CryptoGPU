import json

with open("brebisGaleuse.json", "r") as f:
    res = json.loads(f.read()).items()


res = sorted(res, key=lambda x: x[1])

for chien in res:
    print(chien)