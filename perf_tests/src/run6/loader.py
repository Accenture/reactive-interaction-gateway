import sys
import load as l
import time

def load_for_multiple_topics(messages_in_k, topics):
    start = time.time()
    topic = 1
    for i in range(messages_in_k):
        # Because we're using SSE, we can't guarantee that every message reaches its destinations
        # Package loss running locally is about 4 in 100k, so I am appending 10 events just to be safe
        for _ in range(1010): 
            l.produce(l.p, "rig", l.payload, "chatroom_message" + str(topic))

            topic = topic + 1

            if topic > topics:
                topic = 1
        l.p.flush()

        l.print_progress(i)
    end = time.time()
    print(end - start)
