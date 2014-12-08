import matplotlib as mpl
mpl.use("Agg")
import matplotlib.pyplot as plt
import argparse
import random
import subprocess
import sys
import os

sizes      = [10, 100, 1000, 5000, 10000, 50000 , 100000, 500000, 1000000]
numSamples = 20
maxSize    = 2**64

def generateTestData():
    for s in sizes:
        for n in range(numSamples):
            filename = "random" + str(s) + "-" + str(n+1)
            print ("Generating", filename)
            with open(filename, "wb", 0) as f:
                for i in range(s):
                    r = random.randint(1, maxSize)
                    f.write(bytes(str(r) + "\n", "UTF-8"))

def runCommand(cmd, inputfile):
    cmdTemplate = "/usr/bin/time --format %e {} {} > result"
    command = cmdTemplate.format(cmd, inputfile)
    p = subprocess.Popen(
            command
            , shell=True
            , universal_newlines=True
            , stderr=subprocess.PIPE
            )
    stdout, stderr = p.communicate()
    # Returns runtime
    return float(stderr)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run the test suite")
    # TODO: Add num samples argument
    parser.add_argument("-g", "--generate-test-data"
        , help="Generate the test data first."
        , action="store_true"
        )
    parser.add_argument("-n", "--num-samples"
            , help="Number of samples to try/generate for each file size."
            , default=20
            , type=int
            )
    parser.add_argument("filename"
        , help="Name of output graph."
        )
    args = parser.parse_args()

    numSamples = args.num_samples

    if not os.path.isfile("/usr/bin/time"):
        print("You need /usr/bin/time, not built-in time.")
        sys.exit(1)

    if not os.path.isfile("./sorter"):
        print("Please run make first.")
        sys.exit(1)

    if args.generate_test_data:
        generateTestData()

    if not os.path.isfile("random10-1"):
        print("Please run python testsuite.py -g first.")
        sys.exit(1)

    coreutilsAverages = []
    myAverages = []
    for s in sizes:
        coreutilsSum = 0
        myTimesSum = 0
        print("Running tests for size", s, "..")
        for i in range(numSamples):
            testfile = "random{}-{}".format(s, i + 1)
            coreTime = runCommand("sort -n", testfile)
            myTime = runCommand("./sorter", testfile)
            coreutilsSum += coreTime
            myTimesSum += myTime
        coreutilsAverages.append(coreutilsSum / numSamples)
        myAverages.append(myTimesSum / numSamples)

    plt.xlabel("Input size")
    plt.ylabel("Time (s)")
    plt.plot(sizes, coreutilsAverages)
    plt.plot(sizes, myAverages)
    plt.legend(["Coreutils sort", "My sort"], loc="upper left")
    plt.savefig(args.filename, bbox_inches="tight")
