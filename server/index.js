const express = require("express");
var http = require("http");
const app = express();
const Room = require("./models/Room");
const getWord = require("./api/getWord");

const port = process.env.PORT || 3000;

var server = http.createServer(app);
// middleware
app.use(express.json());
// Comment to your MongoDB
const DB =
  "mongodb+srv://Starscream:18wMtc8oRiFEf0IG@cluster0.ecp1uuz.mongodb.net/";
const mongoose = require("mongoose");

var io = require("socket.io")(server);

mongoose
  .connect(DB)
  .then(() => {
    console.log("Connection Successful!");
  })
  .catch((err) => {
    console.log(err);
  });

io.on("connection", (socket) => {
  console.log("Connection Successful on socket.io!");

  //   Create game room
  socket.on(
    "create-game",
    async ({ nickname, roomName, occupancy, maxRounds }) => {
      try {
        const existingRoom = await Room.findOne({ roomName });
        if (existingRoom) {
          socket.emit("notCorrectGame", "Room already exists");
          return;
        }
        let room = new Room();
        const word = getWord();
        room.word = word;
        room.roomName = roomName;
        room.maxRounds = maxRounds;
        room.occupancy = occupancy;
        let player = {
          socketID: socket.id,
          nickname,
          isPartyLeader: true,
        };
        room.players.push(player);
        room = await room.save();
        socket.join(roomName);
        io.to(roomName).emit("updateRoom", room);
      } catch (err) {
        console.log(err);
      }
    }
  );

  //   Join game room
  socket.on("join-game", async ({ nickname, roomName }) => {
    try {
      let room = await Room.findOne({ roomName });
      if (!room) {
        socket.emit("notCorrectGame", "Please enter a valid room name");
        return;
      }
      if (room.isJoined) {
        let player = {
          socketID: socket.id,
          nickname,
        };
        room.players.push(player);
        socket.join(roomName);
        if (room.players.length === room.occupancy) {
          room.isJoined = false;
        }
        room.turn = room.players[room.turnIndex];
        room = await room.save();
        io.to(roomName).emit("updateRoom", room);
      } else {
        socket.emit(
          "notCorrectGame",
          "The game is in progress, please try later!"
        );
      }
    } catch (err) {
      console.log(err);
    }
  });

  // Change turn
  socket.on("change-turn", async (roomName) => {
    try {
      let room = await Room.findOne({ roomName });
      let idx = room.turnIndex;
      if (idx + 1 === room.players.length) {
        room.currentRounds += 1;
      }
      if (room.currentRounds <= room.maxRounds) {
        const word = getWord();
        room.word = word;
        room.turnIndex = (idx + 1) % room.players.length;
        room.turn = room.players[room.turnIndex];
        room = await room.save();
        io.to(roomName).emit("change-turn", room);
      } else {
        io.to(roomName).emit("show-leaderboard", room.players);
      }
    } catch (err) {
      console.log(err.toString());
    }
  });

  // Send message
  socket.on("msg", async (data) => {
    console.log(data);
    try {
      if (data.msg === data.word) {
        let room = Room.find({ name: data.roomName });
        let userPlayer = room[0].players.filter(
          (player) => player.nickname === data.username
        );
        if (data.timeTaken !== 0) {
          userPlayer[0].points += Math.round((200 / data.timeTaken) * 10);
        }
        room = await room[0].save();
        io.to(data.roomName).emit("msg", {
          username: data.username,
          msg: "Guessed it!",
          guessedUserCtr: data.guessedUserCtr,
        });
        socket.emit("closeInput", "");
      } else {
        io.to(data.roomName).emit("msg", {
          username: data.username,
          msg: data.msg,
          guessedUserCtr: data.guessedUserCtr,
        });
      }
    } catch (e) {
      console.log(e.toString());
    }
  });

  // Update score
  socket.on("updateScore", (roomName) => {
    try {
      const room = Room.find({ roomName });
      io.to(roomName).emit("updateScore", room);
    } catch (e) {
      console.log(e.toString());
    }
  });
  // White board sockets
  socket.on("paint", ({ details, roomName }) => {
    io.to(roomName).emit("points", { details: details });
  });

  // Color sockets
  socket.on("color-change", ({ color, roomName }) => {
    io.to(roomName).emit("color-change", color);
  });

  // Strokes sockets
  socket.on("stroke-width", ({ value, roomName }) => {
    io.to(roomName).emit("stroke-width", value);
  });

  // Clear screen
  socket.on("clean-screen", (roomName) => {
    io.to(roomName).emit("clear-screen", "");
    console.log("cleared screen");
  });

  socket.on("disconnect", async () => {
    try {
      let room = await Room.findOne({ "players.socketID": socket.id });
      for (let i = 0; io < room.players.length; i++) {
        if (room.players[i].socketID === socket.id) {
          room.players.splice(i, 1);
          break;
        }
      }
      room = await room.save();
      if (room.players.length === 1) {
        socket.broadcast
          .to(room.roomName)
          .emit("show-leaderboard", room.players);
      } else {
        socket.broadcast.to(room.roomName).emit("user-disconnected", room);
      }
    } catch (e) {
      console.log(e.toString());
    }
  });
});

server.listen(port, "0.0.0.0", (err) => {
  console.log("Server started and running on port " + port);
});
