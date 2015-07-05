/*
var apn = require('apn');
var options = { cert: 'cert.pem',
    key: 'key.pem',
    passphrase: '1234',
    production: false
};
var apnConnection = new apn.Connection(options);
var myDevice = new apn.Device('a3966798c193d8ddb46710c20cd1f6f765836efd2ff26a510ec5380659352afb');
var note = new apn.Notification();

note.expiry = Math.floor(Date.now() / 1000) + 3600; // Expires 1 hour from now.
note.badge = 3;
note.sound = 'ping.aiff';
note.alert = '\uD83D\uDCE7 \u2709 You have a new message';
note.payload = {'messageFrom': 'Caroline'};

apnConnection.pushNotification(note, myDevice);
*/

// requires

var util = require('util')
var express = require('express');
var app = express();
var bodyParser = require('body-parser')
var apn = require('apn');

// apns

var options = { cert: 'cert.pem',
    key: 'key.pem',
    passphrase: '1234',
    production: false
};
var apnConnection = new apn.Connection(options);

// mongodb

var mongoose = require('mongoose'),
                 Schema = mongoose.Schema,
                 ObjectId = Schema.ObjectId;
mongoose.connect('mongodb://localhost/my_database')
  
var PersonSchema = new Schema({
    uid	  : String,
    hashed  : String,
    salt	  : String,
    name	  : String,
    pubkey  : String,
    password: String
});
var PersonModel = mongoose.model('Person', PersonSchema);

var PostingSchema = new Schema({
    from	: ObjectId,
    to	: ObjectId,
    body	: String
});
var PostingModel = mongoose.model('Posting', PostingSchema);


// express

app.get('/', function (req, res) {
  console.log("hi")
  res.send('Hello World!');
});

app.post('/login', function (req, res) {
  res.json({session:'123456'});
});

app.post('/register', bodyParser.json(), function (req, res) {
  
  var person = new PersonModel();
  console.log('body: ' + util.inspect(req.body))
  person.name = req.body.username;
  person.password = req.body.password;
  person.save(function (err) {
      if (!err)
        console.log('saved ' + req.body.username);
      else
        console.log('failed to save ' + req.body.username);
  });
  
  res.json({session:'123456'});
});

app.get('/roster', function (req, res) {
  res.json([{name:'Superman',id:'Clark'},{name:'Batman',id:'Bruce'},{name:'Aquaman',id:'Alex'}]);
});


app.post('/push', bodyParser.json(), function (req, res) { 

  console.log('body: ' + util.inspect(req.body))

  var token = req.body.token;
  console.log('push to ' + token)
  var device = new apn.Device(token);

  var note = new apn.Notification();
  
  note.expiry = Math.floor(Date.now() / 1000) + 3600; // Expires 1 hour from now.
  note.badge = 3;
  note.sound = "ping.aiff";
  note.alert = "\uD83D\uDCE7 \u2709 You have a new message";
  note.payload = {'messageFrom': 'Caroline'};
  
  apnConnection.pushNotification(note, device);

});



var server = app.listen(3000, function () {

  var host = server.address().address;
  var port = server.address().port;

  console.log('Example app listening at http://%s:%s', host, port);

});

