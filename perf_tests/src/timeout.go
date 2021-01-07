package loadtest

import (
	"fmt"
	"os"
	"sync"
	"time"
)

// WaitTimeout Wait for a wg to finish within a certain time, if the wg finishes before, false is returned
func WaitTimeout(wg *sync.WaitGroup, timeout string) bool {
	duration, err := time.ParseDuration(timeout)

	if err != nil {
		fmt.Println("Error while parsing timeout!")
		os.Exit(1)
	}

	c := make(chan struct{})
	go func() {
		defer close(c)
		wg.Wait()
	}()
	select {
	case <-c:
		return false // completed normally
	case <-time.After(duration):
		return true // timed out
	}
}
