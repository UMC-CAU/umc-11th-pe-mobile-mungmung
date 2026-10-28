const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');

http.createServer((req, res) => {
  if (req.url !== '/' && req.url !== '/index.html') {
    res.writeHead(404);
    return res.end('Not found');
  }
  res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
  fs.createReadStream(path.join(__dirname, 'index.html')).pipe(res);
}).listen(5173, '127.0.0.1', () => {
  console.log('Movie Room: http://localhost:5173');
});
