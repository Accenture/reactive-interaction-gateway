package loadtest

import (
	"errors"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/r3labs/sse"
)

// Receive & time measurement loop
func Receive(i, amount, printSteps int, sub string, ctrl chan bool) (float64, error) {
	var start time.Time

	count := 1
	events := make(chan *sse.Event)
	client := sse.NewClient("http://" + os.Getenv("RIG_HOST") + ":4000/_rig/v1/connection/sse?subscriptions=[{\"eventType\":\"" + sub + "\"}]")

	client.SubscribeChanRaw(events)

	ctrl <- true

	for event := range events {
		if string(event.Event) != sub {
			continue
		}

		count++

		if count == 2 {
			start = time.Now()
		}

		if count%printSteps == 0 {
			go fmt.Println("Count:", count, "\t| Thread:", i, "\t| Topic:", sub)
		}

		if count == amount {
			elapsed := time.Since(start).Seconds()
			return elapsed, nil
		}
	}

	return 0, errors.New("")
}

func handler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprint(w, "OK")
}

// StatusOk serves HTTP server to signal all is well
func StatusOk() {
	http.HandleFunc("/", handler)
	http.ListenAndServe(":9999", nil)
}

// GetEnv Checks env and returns amount of goroutines to start
func GetEnv() (int, string) {

	if os.Getenv("RIG_HOST") == "" {
		fmt.Println("RIG_HOST environment variable required!")
		os.Exit(1)
	}

	if os.Getenv("CLIENTS") == "" {
		fmt.Println("CLIENTS environment variable required!")
		os.Exit(1)
	}

	goroutines, err := strconv.Atoi(os.Getenv("CLIENTS"))

	if err != nil {
		fmt.Println("Error while parsing CLIENTS!")
		os.Exit(1)
	}

	if os.Getenv("TIMEOUT") == "" {
		fmt.Println("TIMEOUT environment variable required!")
		os.Exit(1)
	}

	fmt.Println("Waiting until RIG goes online...")

	for {
		resp, err := http.Get("http://" + os.Getenv("RIG_HOST") + ":4010/health")

		if err == nil {
			body, err := ioutil.ReadAll(resp.Body)
			resp.Body.Close()

			if err == nil {
				if strings.Contains(string(body), "OK") {
					break
				}
			}
		}
	}

	return goroutines, os.Getenv("TIMEOUT")
}
