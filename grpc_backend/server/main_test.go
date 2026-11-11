package main

import (
	"context"
	"net"
	"testing"
	"time"

	monitoring "example.com/realtime-grpc/gen/monitoring"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/status"
	"google.golang.org/grpc/test/bufconn"
)

func TestGetLatestRequiresDeviceID(t *testing.T) {
	server := &sensorServer{}

	_, err := server.GetLatest(context.Background(), &monitoring.SensorRequest{})
	if status.Code(err) != codes.InvalidArgument {
		t.Fatalf("GetLatest error code = %v, want %v", status.Code(err), codes.InvalidArgument)
	}
}

func TestGetLatestReturnsSensorReading(t *testing.T) {
	server := &sensorServer{}
	const deviceID = "sensor-test"

	reading, err := server.GetLatest(
		context.Background(),
		&monitoring.SensorRequest{DeviceId: deviceID},
	)
	if err != nil {
		t.Fatalf("GetLatest returned error: %v", err)
	}
	if reading.GetDeviceId() != deviceID {
		t.Errorf("device ID = %q, want %q", reading.GetDeviceId(), deviceID)
	}
	if reading.GetValue() < 25 || reading.GetValue() >= 35 {
		t.Errorf("sensor value = %v, want a value in [25, 35)", reading.GetValue())
	}
	if reading.GetTimestamp() <= 0 {
		t.Errorf("timestamp = %d, want a positive Unix timestamp", reading.GetTimestamp())
	}
}

func TestSensorServiceGRPC(t *testing.T) {
	listener := bufconn.Listen(1024 * 1024)
	server := grpc.NewServer()
	monitoring.RegisterSensorServiceServer(server, &sensorServer{})
	go func() {
		_ = server.Serve(listener)
	}()
	defer server.Stop()

	conn, err := grpc.NewClient(
		"passthrough:///bufnet",
		grpc.WithContextDialer(func(context.Context, string) (net.Conn, error) {
			return listener.Dial()
		}),
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)
	if err != nil {
		t.Fatalf("failed to create gRPC client: %v", err)
	}
	defer conn.Close()

	client := monitoring.NewSensorServiceClient(conn)
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	reading, err := client.GetLatest(
		ctx,
		&monitoring.SensorRequest{DeviceId: "sensor-rpc-test"},
	)
	if err != nil {
		t.Fatalf("GetLatest RPC failed: %v", err)
	}
	if reading.GetDeviceId() != "sensor-rpc-test" {
		t.Errorf("device ID = %q, want %q", reading.GetDeviceId(), "sensor-rpc-test")
	}

	stream, err := client.WatchSensor(
		ctx,
		&monitoring.SensorRequest{DeviceId: "sensor-stream-test"},
	)
	if err != nil {
		t.Fatalf("WatchSensor RPC failed: %v", err)
	}
	streamReading, err := stream.Recv()
	if err != nil {
		t.Fatalf("failed to receive sensor stream reading: %v", err)
	}
	if streamReading.GetDeviceId() != "sensor-stream-test" {
		t.Errorf(
			"stream device ID = %q, want %q",
			streamReading.GetDeviceId(),
			"sensor-stream-test",
		)
	}
}
