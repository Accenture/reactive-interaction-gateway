package main

import (
	"fmt"
	"sync"

	loadtest ".."
)

func main() {
	var wg sync.WaitGroup
	var mutex = &sync.Mutex{}

	goroutines, timeout := loadtest.GetEnv()

	ctrl := make(chan bool)

	fmt.Println("Starting", goroutines, "goroutines")

	for i := 1; i <= goroutines; i++ {
		wg.Add(1)
		go func(i int) {
			elapsed, _ := loadtest.Receive(i, 100000, 1000, "chatroom_message", ctrl)

			mutex.Lock()
			fmt.Println("Thread", i, "finished in", elapsed, "s")
			mutex.Unlock()

			wg.Done()
		}(i)
		<-ctrl
	}

	go loadtest.StatusOk()

	fmt.Println("Waiting for goroutines to finish...")

	if loadtest.WaitTimeout(&wg, timeout) {
		fmt.Println("Timed out waiting for wait group")
	} else {
		fmt.Println("Wait group finished")
	}
}
