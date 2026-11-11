# gRPC Sensor Backend

## Menjalankan server

Pastikan Go 1.26 atau lebih baru tersedia. Server harus tetap berjalan saat
menggunakan Praktikum 7. Dari root project jalankan:

```powershell
cd grpc_backend
go run ./server
```

Server membuka gRPC plaintext pada port `50051`. Terminal akan menampilkan
`gRPC Server berjalan pada port 50051` saat siap menerima koneksi. Biarkan
proses ini berjalan saat menguji aplikasi Flutter dan pastikan port tersebut
tidak sedang dipakai aplikasi lain.

## Menjalankan Flutter

Jalankan aplikasi pada Android Emulator dari root project:

```powershell
flutter run
```

Pada layar **Praktikum 7 - gRPC**, host default Android Emulator adalah
`10.0.2.2`, sedangkan Flutter desktop menggunakan `127.0.0.1`. Untuk perangkat
fisik, ganti host dengan alamat IP komputer yang menjalankan backend dan pastikan
keduanya berada di jaringan yang sama serta firewall mengizinkan koneksi TCP ke
port `50051`.

Layar ini menguji RPC unary `GetLatest` dan server streaming `WatchSensor`.
Streaming mengirim pembacaan sensor baru setiap dua detik.

## Menjalankan tes backend

Dari folder `grpc_backend`:

```powershell
go test ./...
```

## Menghasilkan ulang kode protobuf Dart

Jika `proto/sensor.proto` berubah, pasang plugin Dart dan jalankan perintah
berikut dari root project:

```powershell
dart pub global activate protoc_plugin
protoc -I grpc_backend/proto --dart_out=grpc:lib/generated grpc_backend/proto/sensor.proto
```
