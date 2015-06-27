var express = require('express');
var app = express();

app.get('/', function (req, res) {
  console.log("hi")
  res.send('Hello World!');
});

app.post('/login', function (req, res) {
  res.json({session:'123456'});
});

app.post('/register', function (req, res) {
  res.json({session:'123456'});
});

app.get('/roster', function (req, res) {
  res.json([{name:'Superman',id:'Clark'},{name:'Batman',id:'Bruce'},{name:'Aquaman',id:'Alex'}]);
});

var server = app.listen(3000, function () {

  var host = server.address().address;
  var port = server.address().port;

  console.log('Example app listening at http://%s:%s', host, port);

});
