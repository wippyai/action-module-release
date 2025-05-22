module upload

go 1.24

require (
	connectrpc.com/connect v1.18.1
	github.com/wippyai/module-registry-proto v0.0.0
)

require (
	buf.build/gen/go/bufbuild/protovalidate/protocolbuffers/go v1.36.6-20250425153114-8976f5be98c1.1 // indirect
	github.com/google/go-cmp v0.6.0 // indirect
	google.golang.org/protobuf v1.36.6 // indirect
)

replace github.com/wippyai/module-registry-proto => ./proto
