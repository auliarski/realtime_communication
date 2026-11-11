
const express = require("express");
const cors = require("cors");
const http = require("http");
const { WebSocketServer } = require("ws");

const app = express();

app.use(cors());
app.use(express.json());

// Membuat HTTP server.
const server = http.createServer(app);

// Membuat WebSocket server.
const wss = new WebSocketServer({ server });

// Menyimpan data dan koneksi client.
let counter = 0;
let history = [];
let submittedData = [];
let nextSubmittedDataId = 1;

const clients = new Set();
const sseClients = new Set();
const signalingRooms = new Map();

function sendSignalingError(socket, message) {
  if (socket.readyState === 1) {
    socket.send(JSON.stringify({ type: "error", message }));
  }
}

function leaveSignalingRoom(socket) {
  const roomId = socket.signalingRoom;
  if (!roomId) return;

  const room = signalingRooms.get(roomId);
  room?.delete(socket.signalingRole);
  socket.signalingRoom = undefined;
  socket.signalingRole = undefined;

  if (room) {
    for (const peer of room.values()) {
      if (peer.readyState === 1) {
        peer.send(JSON.stringify({ type: "peer-left" }));
      }
    }
    if (room.size === 0) signalingRooms.delete(roomId);
  }
}

// =====================================
// DATA GENERATOR
// =====================================

function publishData() {
  counter++;

  const data = {
    counter: counter,
    value: Math.floor(Math.random() * 100),
    timestamp: new Date().toISOString(),
  };

  // Menyimpan riwayat data.
  history.push(data);

  if (history.length > 100) {
    history.shift();
  }

  // =====================================
  // BROADCAST WEBSOCKET
  // =====================================

  for (const client of clients) {
    if (client.readyState === 1) {
      client.send(JSON.stringify(data));
    }
  }

  // =====================================
  // BROADCAST SSE
  // =====================================

  for (const res of sseClients) {
    if (!res.destroyed && !res.writableEnded) {
      res.write(`data: ${JSON.stringify(data)}\n\n`);
    }
  }

  console.log("Data diperbarui:", data);
}

// Mengirim data setiap 2 detik.
setInterval(publishData, 2000);


// =====================================
// PRAKTIKUM 1 - REST API
// =====================================

// GET: Mengambil data dari server.
app.get("/api/data", (req, res) => {
  const latest = history.at(-1) ?? {
      counter: 0,
      value: 0,
      timestamp: new Date().toISOString(),
  };

  res.json({
    ...latest,
    data: submittedData,
  });
});

app.post("/api/data", (req, res) => {
  const name = String(req.body?.name ?? "").trim();

  if (!name) {
    return res.status(400).json({
      received: false,
      error: "Nama tidak boleh kosong",
    });
  }

  const item = {
    id: nextSubmittedDataId++,
    name,
    timestamp: new Date().toISOString(),
  };

  submittedData.unshift(item);
  if (submittedData.length > 100) {
    submittedData.pop();
  }

  res.status(201).json({
    received: true,
    data: item,
  });
});

// POST: Menerima pesan dari client.
app.post("/api/message", (req, res) => {
  res.json({
    received: true,
    message: req.body.message ?? "",
    timestamp: new Date().toISOString(),
  });
});


// =====================================
// PRAKTIKUM 3 - SERVER SENT EVENTS (SSE)
// =====================================

app.get("/api/events", (req, res) => {
  res.setHeader("Content-Type", "text/event-stream");
  res.setHeader("Cache-Control", "no-cache");
  res.setHeader("Connection", "keep-alive");

  res.flushHeaders();

  // Menambahkan client ke daftar koneksi SSE.
  sseClients.add(res);

  // Mengirim event ketika client berhasil terhubung.
  res.write("event: connected\n");
  res.write("data: {}\n\n");

  console.log("Client SSE terhubung");

  // Menghapus client ketika koneksi ditutup.
  req.on("close", () => {
    sseClients.delete(res);
    console.log("Client SSE terputus");
  });
});


// =====================================
// PRAKTIKUM 4 - WEBSOCKET
// =====================================

wss.on("connection", (socket) => {
  // Menambahkan client WebSocket.
  clients.add(socket);

  console.log("Client WebSocket terhubung");

  // Menerima pesan dari Flutter.
  socket.on("message", (message) => {
    try {
      const received = JSON.parse(message.toString());

      if (received.type === "join") {
        const roomId = typeof received.room === "string"
          ? received.room.trim()
          : "";
        const role = received.role;

        if (!roomId || roomId.length > 100) {
          sendSignalingError(socket, "Room ID harus berisi 1-100 karakter");
          return;
        }
        if (role !== "caller" && role !== "callee") {
          sendSignalingError(socket, "Role harus caller atau callee");
          return;
        }
        if (socket.signalingRoom) {
          sendSignalingError(socket, "Koneksi ini sudah bergabung ke room");
          return;
        }

        let room = signalingRooms.get(roomId);
        if (!room) {
          room = new Map();
          signalingRooms.set(roomId, room);
        }
        if (room.size >= 2 || room.has(role)) {
          sendSignalingError(socket, "Room penuh atau role tersebut sudah dipakai");
          return;
        }

        const peerPresent = room.size > 0;
        room.set(role, socket);
        socket.signalingRoom = roomId;
        socket.signalingRole = role;

        if (socket.readyState === 1) {
          socket.send(JSON.stringify({ type: "joined", peerPresent }));
        }
        for (const peer of room.values()) {
          if (peer !== socket && peer.readyState === 1) {
            peer.send(JSON.stringify({ type: "peer-joined", role }));
          }
        }
        console.log(`Client signaling bergabung: room=${roomId}, role=${role}`);
        return;
      }

      if (["offer", "answer", "candidate"].includes(received.type)) {
        const room = signalingRooms.get(socket.signalingRoom);
        if (!room) {
          sendSignalingError(socket, "Bergabung ke room sebelum mengirim sinyal");
          return;
        }
        for (const peer of room.values()) {
          if (peer !== socket && peer.readyState === 1) {
            peer.send(JSON.stringify(received));
          }
        }
        return;
      }

      const reply = {
        type: "echo",
        message: received.message ?? message.toString(),
        timestamp: new Date().toISOString(),
      };

      // Mengirim balasan kepada client.
      if (socket.readyState === 1) {
        socket.send(JSON.stringify(reply));
      }

      console.log("Pesan diterima:", reply.message);

    } catch (error) {
      console.log("Pesan tidak valid:", error.message);
    }
  });

  // Menghapus client ketika koneksi terputus.
  socket.on("close", () => {
    clients.delete(socket);
    leaveSignalingRoom(socket);
    console.log("Client WebSocket terputus");
  });

  socket.on("error", (error) => {
    console.log("WebSocket error:", error.message);
  });
});

// =====================================
// MENJALANKAN SERVER
// =====================================

server.listen(3000, "0.0.0.0", () => {
  console.log("--------------------------------");
  console.log("Server berjalan pada port 3000");
  console.log("--------------------------------");
  console.log("REST API   : http://localhost:3000/api/data");
  console.log("SSE        : http://localhost:3000/api/events");
  console.log("WebSocket  : ws://localhost:3000");
});
