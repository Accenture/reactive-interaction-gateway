import sys
import load as l
import time

def load_tbd():
    print("Loading to_be_delivered message...")
    l.produce(l.p, "rig", l.payload, "to_be_delivered")
    l.p.flush()

def load():
    start = time.time()

    for i in range(100):
        for _ in range(1000):
            l.produce(l.p, "rig", l.payload, "ignored")
        l.p.flush()

        l.print_progress(i)
    
    end = time.time()
    print(end - start)