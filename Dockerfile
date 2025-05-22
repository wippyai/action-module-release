FROM golang:1.24-alpine

# Install required tools
RUN apk add --no-cache \
    protobuf \
    git \
    make \
    curl

# Set working directory
WORKDIR /app

# Copy upload tool and proto files
COPY main.go /app/main.go
COPY go.mod /app/go.mod
COPY go.sum /app/go.sum
COPY proto /app/proto

# Build the upload tool
RUN cd /app && \
    go mod tidy && \
    go build -o /app/upload-tool

# Set entrypoint
ENTRYPOINT ["/app/upload-tool"] 