FROM golang:latest
COPY . .
RUN go get github.com/r3labs/sse
RUN go build run1/client.go
CMD ["./client"]
