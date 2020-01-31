package main

import (
	"fmt"
	"strconv"
	"sync"

	loadtest ".."
)

func main() {
	var wg sync.WaitGroup

	goroutines, timeout := loadtest.GetEnv()
	topic := 1

	ctrl := make(chan bool)

	fmt.Println("Starting", goroutines, "goroutines")

	for i := 1; i <= goroutines; i++ {
		wg.Add(1)
		go func(i, topic int) {
			elapsed, err := loadtest.Receive(i, 1000, 100, "chatroom_message"+strconv.Itoa(topic), ctrl)

			if err != nil {
				fmt.Println("Error:", err)
				return
			}

			fmt.Println("Thread", i, "finished in", elapsed, "s")

			wg.Done()
		}(i, topic)

		<-ctrl

		topic = topic + 1

		if topic > 100 {
			topic = 1
		}
	}

	go loadtest.StatusOk()

	fmt.Println("Waiting for goroutines to finish...")

	if loadtest.WaitTimeout(&wg, timeout) {
		fmt.Println("Timed out waiting for wait group")
	} else {
		fmt.Println("Wait group finished")
	}
}
