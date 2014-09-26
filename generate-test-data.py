import random


sizes = [10, 100, 1000, 5000, 10000, 50000, 100000, 500000, 1000000]

for s in sizes:
    for n in range(20):
        filename = "random" + str(s) + "-" + str(n+1)
        print "Generating", filename
        with open(filename, "wa", 0) as f:
            for i in range(s):
                r = random.randint(1, 10000000000)
                f.write(str(r) + "\n")
