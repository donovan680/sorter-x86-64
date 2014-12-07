import matplotlib as mpl
import matplotlib.pyplot as plt
import subprocess
import sys
sizes = [10, 100, 1000, 5000, 10000, 50000 , 100000, 500000, 1000000]

#sizes = [100000, 500000, 1000000]

cmpCount = {
    10: 409
    , 100: 634
    , 1000: 2884
    , 5000: 12884
    , 10000: 25384
    , 50000: 125384
    , 100000: 250384
    , 500000: 1250384
    , 1000000: 2500384
}
allTimes = []
for s in sizes:
    times = []
    print(str(s) + "_time: ", end="", flush=True)
    for i in range(20):
        testfile = "random{}-{}".format(s, i + 1)
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
        print(str(time), end="\t", flush=True)
        times.append(time)
    print()
    print(str(s) + "_mcips: ", end="", flush=True)
    for t in times:
        print(str(int(cmpCount[s]/(t + 0.01))), end="\t", flush=True)
    print()
    allTimes.append(times)

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
