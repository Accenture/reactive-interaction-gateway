const http = require("http");
const port = 3000;
const handler = (req, res) => {
  console.log(`Request URL: ${req.url}`);
  console.log(JSON.stringify(req.headers));
  res.end("Hi, I'm a demo service!\n");
}
const server = http.createServer(handler);
server.listen(port, err => {
  if (err) {
    return console.error(err);
  }
  console.log(`server is listening on ${port}`);
})
