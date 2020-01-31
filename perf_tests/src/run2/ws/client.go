package main

import (
	"fmt"
	"os"
	"os/signal"
	"strconv"
	"sync"
	"time"

	"github.com/buger/jsonparser"
	"github.com/sacOO7/gowebsocket"
)

func receive(i int) {
	var start time.Time
	var wg sync.WaitGroup

	wg.Add(1)
	interrupt := make(chan os.Signal, 1)
	signal.Notify(interrupt, os.Interrupt)

	socket := gowebsocket.New("ws://localhost:4000/_rig/v1/connection/ws?subscriptions=[{\"eventType\":\"chatroom_message\"}]")
	count := 1

	socket.OnTextMessage = func(message string, socket gowebsocket.Socket) {
		etype, _ := jsonparser.GetString([]byte(message), "type")

		if etype == "chatroom_message" {
			count++
		}

		if count == 2 {
			start = time.Now()
		}

		if count%1000 == 0 {
			fmt.Println(count, i)
		}

		if count == 100000 {
			elapsed := time.Since(start).Seconds()
			fmt.Println("Thread", i, "finished in", elapsed, "s")
			wg.Done()
		}
	}

	socket.Connect()
	wg.Wait()
}

func main() {
	var wg sync.WaitGroup

	goroutines, _ := strconv.Atoi(os.Getenv("CLIENTS"))

	fmt.Println("Starting", goroutines, "goroutines")

	for i := 1; i <= goroutines; i++ {
		wg.Add(1)
		go func(i int) {
			receive(i)
			wg.Done()
		}(i)
	}

	fmt.Println("Waiting for goroutines to finish...")
	wg.Wait()
	fmt.Println("Done")
}
