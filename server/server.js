
const express = require("express");
const cors = require("cors");
const http = require("http");
const { WebSocketServer } = require("ws");

const app = express();
app.use(cors());
app.use(express.json());

const server = http.createServer(app);
const wss = new WebSocketServer({ server });

let counter = 0;
let history = [];
let clients = new Set();

function publishData() {
  counter++;

  const data = {
    counter,
    value: Math.floor(Math.random() * 100),
    timestamp: new Date().toISOString(),
  };

  history.push(data);
  if (history.length > 100) history.shift();

  // Broadcast ke seluruh client WebSocket.
  for (const client of clients) {
    if (client.readyState === 1) {
      client.send(JSON.stringify(data));
    }
  }

  // Kirim pembaruan ke koneksi SSE.
  for (const res of sseClients) {
    res.write(`data: ${JSON.stringify(data)}\n\n`);
  }
}

const sseClients = new Set();

setInterval(publishData, 2000);

// REST API
app.get("/api/data", (req, res) => {
  res.json(history.at(-1) ?? {
    counter: 0,
    value: 0,
    timestamp: new Date().toISOString(),
  });
});

app.post("/api/message", (req, res) => {
  res.json({
    received: true,
    message: req.body.message ?? "",
    timestamp: new Date().toISOString(),
  });
});

// SSE
app.get("/api/events", (req, res) => {
  res.setHeader("Content-Type", "text/event-stream");
  res.setHeader("Cache-Control", "no-cache");
  res.setHeader("Connection", "keep-alive");
  res.flushHeaders();

  sseClients.add(res);
  res.write("event: connected\ndata: {}\n\n");

  req.on("close", () => {
    sseClients.delete(res);
  });
});

// WebSocket
wss.on("connection", (socket) => {
  clients.add(socket);

  socket.on("message", (message) => {
    const reply = JSON.stringify({
      type: "echo",
      message: message.toString(),
      timestamp: new Date().toISOString(),
    });

    if (socket.readyState === 1) {
      socket.send(reply);
    }
  });

  socket.on("close", () => clients.delete(socket));
});

server.listen(3000, "0.0.0.0", () => {
  console.log("Server berjalan pada port 3000");
});
