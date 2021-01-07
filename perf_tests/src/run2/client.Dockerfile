FROM golang:latest
COPY . .
RUN go get github.com/r3labs/sse
RUN go build run2/client.go
CMD ["./client"]
