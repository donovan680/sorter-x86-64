import matplotlib as mpl
import matplotlib.pyplot as plt
import subprocess
import sys
sizes = [10, 100, 1000, 5000, 10000, 50000 , 100000, 500000, 1000000]

#sizes = [100000, 500000, 1000000]

def generateTestData():
    for s in sizes:
        for n in range(numSamples):
            filename = "random" + str(s) + "-" + str(n+1)
            print ("Generating", filename)
            with open(filename, "wb", 0) as f:
                for i in range(s):
                    r = random.randint(1, maxSize)
                    f.write(bytes(str(r) + "\n", "UTF-8"))

for s in sizes:
    for t in ["asc", "desc"]:
        print(t + "_"+ str(s) + "_time: ", end="", flush=True)
        testfile = "random{}-{}".format(s, t)
        command = "/usr/bin/time --format %e ./sorter {} > result".format(testfile)
        if len(sys.argv) > 1:
            command = "/usr/bin/time --format %e ./sorter {} 0 > result".format(testfile)
        p = subprocess.Popen(
                command
                , shell=True
                , universal_newlines=True
                , stderr=subprocess.PIPE
                )
        stdout, stderr = p.communicate()
        time = float(stderr)
        print(str(time))
        mcips = int(cmpCount[s]/(time + 0.01))
        print(t + "_" + str(s) + "_" + "mcips: ", str(mcips))

fig = plt.figure(1, figsize=(9,6))
ax = fig.add_subplot(111)
bp = ax.boxplot(allTimes, patch_artist=True)
for box in bp['boxes']:
    # change outline color
    box.set( color='#7570b3', linewidth=2)
    # change fill color
    box.set( facecolor = '#1b9e77' )

ax.set_xticklabels(list(map(lambda n: str(n), sizes)))

## Remove top axes and right axes ticks
ax.get_xaxis().tick_bottom()
ax.get_yaxis().tick_left()
plt.xlabel("Input size")
plt.ylabel("Time (s)")
if len(sys.argv) > 1:
    plt.savefig("boxplot0.png", bbox_inches="tight")
else:
    plt.savefig("boxplot.png", bbox_inches="tight")
plt.close()
plt.xlabel("Input size")
plt.ylabel("Time (s)")
plt.plot(sizes, list(map(lambda l: sum(l) / len(l), allTimes)))
if len(sys.argv) > 1:
    plt.savefig("graph0.png", bbox_inches="tight")
else:
    plt.savefig("graph.png", bbox_inches="tight")
