import sys
import load as l
import time

def load_10k_include_all():
    start = time.time()
    for i in range(10):
        for _ in range(1001):
            l.produce(l.p, "rig", l.payload, "chatroom_message")
        l.p.flush()

        l.print_progress(i)
    end = time.time()
    print(end - start)
