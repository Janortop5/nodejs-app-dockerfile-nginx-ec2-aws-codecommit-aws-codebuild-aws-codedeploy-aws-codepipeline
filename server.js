const http = require("http");
const os = require("os");
const express = require('express');
const app = express();
const path = require('path')

const hostname = os.hostname();
const interfaces = os.networkInterfaces();

let ipAddress = "unknown";

Object.keys(interfaces).forEach((name) => {
  const interface = interfaces[name];
  interface.forEach((address) => {
    if (address.family === "IPv4" && !address.internal) {
      ipAddress = address.address;
    }
  });
});

const server = http.createServer((req, res) => {
  res.statusCode = 200;
  res.setHeader("Content-Type", "text/html");
  res.end(`<html>
    <head>
      <style>
        h1 {
          text-align: center;
          padding-top: 30px;
        }
        p {
          text-align: center;
          padding-bottom: 120px;
        }
      </style>
    </head>
    <body>
      <h1>Hostname: ${hostname}</h1>
      <p>IP address: ${ipAddress}</p>
      <p>Assessment Complete!</p>
      <p>Copyright &copy; Emmanuel Aladejana</p>
    </body>
  </html>`);
});

// Serve static files from the 'public' directory
app.use(express.static(path.join(__dirname, 'public')));


// Default route
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});


app.listen(3000, () => {
  console.log("Server running at http://localhost:3000/");
});
