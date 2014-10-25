import random


sizes = [10, 100, 1000, 5000, 10000, 50000, 100000, 500000, 1000000,
        10000000]
maxSize = 2**64

for s in sizes:
    for n in range(20):
        filename = "random" + str(s) + "-" + str(n+1)
        print ("Generating", filename)
        with open(filename, "wb", 0) as f:
            for i in range(s):
                r = random.randint(1, maxSize)
                f.write(bytes(str(r) + "\n", "UTF-8") )
