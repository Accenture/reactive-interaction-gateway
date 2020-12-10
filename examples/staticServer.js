// https://developer.mozilla.org/en-US/docs/Learn/Server-side/Node_server_without_framework
var http = require('http');
var fs = require('fs');
var path = require('path');

http
  .createServer(function(request, response) {
    console.log('request ', request.url);

    var filePath = '.' + request.url;
    if (filePath == './') {
      filePath = process.argv[2] || './lp-1-demo.html';
    }

    var extname = String(path.extname(filePath)).toLowerCase();
    var mimeTypes = {
      '.html': 'text/html',
      '.js': 'text/javascript',
      '.css': 'text/css',
      '.json': 'application/json',
      '.png': 'image/png',
      '.jpg': 'image/jpg',
      '.gif': 'image/gif',
      '.svg': 'image/svg+xml',
      '.wav': 'audio/wav',
      '.mp4': 'video/mp4',
      '.woff': 'application/font-woff',
      '.ttf': 'application/font-ttf',
      '.eot': 'application/vnd.ms-fontobject',
      '.otf': 'application/font-otf',
      '.wasm': 'application/wasm'
    };

    var contentType = mimeTypes[extname] || 'application/octet-stream';

    fs.readFile(filePath, function(error, content) {
      if (error) {
        if (error.code == 'ENOENT') {
          fs.readFile('./404.html', function(error, content) {
            response.writeHead(404, { 'Content-Type': 'text/html' });
            response.end(content, 'utf-8');
          });
        } else {
          response.writeHead(500);
          response.end(
            'Sorry, check with the site admin for error: ' + error.code + ' ..\n'
          );
        }
      } else {
        response.writeHead(200, { 'Content-Type': contentType });
        response.end(content, 'utf-8');
      }
    });
  })
  .listen(8080);
console.log('Server running at http://127.0.0.1:8080/');
