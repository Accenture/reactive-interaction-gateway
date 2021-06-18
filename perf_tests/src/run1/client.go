package main

import (
	"fmt"
	"sync"

	utils "client.go/utils"
)

func main() {
	var wg sync.WaitGroup
	var mutex = &sync.Mutex{}

	goroutines, timeout := utils.GetEnv()

	ctrl := make(chan bool)

	fmt.Println("Starting", goroutines, "goroutines")

	for i := 1; i <= goroutines; i++ {
		wg.Add(1)
		go func(i int) {
			elapsed, _ := utils.Receive(0, 3, 1, "to_be_delivered", ctrl)

			mutex.Lock()
			fmt.Println("Thread", i, "finished in", elapsed, "s")
			mutex.Unlock()

			wg.Done()
		}(i)
		<-ctrl
	}

	go utils.StatusOk()

	fmt.Println("Waiting for goroutines to finish...")

	if utils.WaitTimeout(&wg, timeout) {
		fmt.Println("Timed out waiting for wait group")
	} else {
		fmt.Println("Wait group finished")
	}
}
