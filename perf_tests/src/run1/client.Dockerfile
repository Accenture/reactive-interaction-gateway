FROM golang:1.16

WORKDIR /go/src/app

COPY . .
RUN go get github.com/r3labs/sse/v2
# RUN go build client.go

RUN go get -d -v ./...
RUN go install -v ./...
RUN go build client.go

CMD ["./client"]
