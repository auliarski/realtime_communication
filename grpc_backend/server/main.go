package main

import (
	"context"
	"log"
	"math/rand"
	"net"
	"time"

	monitoring "example.com/realtime-grpc/gen/monitoring"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type sensorServer struct {
	monitoring.UnimplementedSensorServiceServer
}

// Unary RPC: mengirim satu data sensor
func (s *sensorServer) GetLatest(
	ctx context.Context,
	req *monitoring.SensorRequest,
) (*monitoring.SensorReading, error) {

	if req.GetDeviceId() == "" {
		return nil, status.Error(
			codes.InvalidArgument,
			"device_id tidak boleh kosong",
		)
	}

	return createReading(req.GetDeviceId()), nil
}

// Server Streaming RPC: mengirim data setiap 2 detik
func (s *sensorServer) WatchSensor(
	req *monitoring.SensorRequest,
	stream grpc.ServerStreamingServer[monitoring.SensorReading],
) error {

	if req.GetDeviceId() == "" {
		return status.Error(
			codes.InvalidArgument,
			"device_id tidak boleh kosong",
		)
	}

	log.Println("Streaming dimulai:", req.GetDeviceId())

	ticker := time.NewTicker(2 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-stream.Context().Done():
			log.Println("Streaming dihentikan:", req.GetDeviceId())
			return nil

		case <-ticker.C:
			reading := createReading(req.GetDeviceId())

			if err := stream.Send(reading); err != nil {
				return err
			}

			log.Printf(
				"Sensor %s: %.2f",
				reading.GetDeviceId(),
				reading.GetValue(),
			)
		}
	}
}

func createReading(deviceID string) *monitoring.SensorReading {
	value := 25 + rand.Float64()*10

	return &monitoring.SensorReading{
		DeviceId:  deviceID,
		Value:     value,
		Timestamp: time.Now().Unix(),
	}
}

func main() {
	listener, err := net.Listen("tcp", ":50051")
	if err != nil {
		log.Fatal("Gagal membuka port:", err)
	}

	server := grpc.NewServer()

	monitoring.RegisterSensorServiceServer(
		server,
		&sensorServer{},
	)

	log.Println("gRPC Server berjalan pada port 50051")

	if err := server.Serve(listener); err != nil {
		log.Fatal("Server error:", err)
	}
}
