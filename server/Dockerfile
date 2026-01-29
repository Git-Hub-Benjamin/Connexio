FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY go.mod go.sum* ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o connexio-server .

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /app
COPY --from=builder /app/connexio-server .

EXPOSE 8080
VOLUME ["/data"]

CMD ["./connexio-server", "-port", "8080", "-data", "/data"]
