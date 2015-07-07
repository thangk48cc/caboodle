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
    uid	    : String,
    hashed  : String,
    salt	: String,
    name    : String,
    pubkey  : String,
    password: String,
    friends : [String]
});
var PersonModel = mongoose.model('Person', PersonSchema);

var PostingSchema = new Schema({
    from	: ObjectId,
    to      : ObjectId,
    body	: String
});
var PostingModel = mongoose.model('Posting', PostingSchema);


// express

function reject(res, status, message) {
    res.status(status).send({ error: message });
}

app.get('/', function (req, res) {
  console.log("hi")
  res.send('Hello World!');
});

app.post('/login', bodyParser.json(), function (req, res) { 
    console.log('login: ' + util.inspect(req.body))

    var who = req.body.username
    var password = req.body.password

    PersonModel.find({name:who}, function (err, docs) {
		if (err)
			reject(res, 500, "find error. " + err.message);
		else if (!docs.length)
			reject(res, 403, 'login: user ' + who + ' does not exist');
		else {
			try {
				var passwordFromDB = docs[0].password;
				console.log('password from db: ' + passwordFromDB);

				if (password != passwordFromDB)
					reject(res, 401, 'login: user ' + who + ' password mismatch: ' + password + ' != ' + passwordFromDB);
				else
                    res.json({session:'123456'});
			} catch (err) {
                reject(res, 500, "could not get password from DB. " + err);
			}
		}
	});
});

app.post('/register', bodyParser.json(), function (req, res) {
  
    console.log('register: ' + util.inspect(req.body))
    var who = req.body.username

	PersonModel.find({name:who}, function (err, docs) {
		if (err)
			reject(res, 500, err);
		else if (docs.length)
			reject(res, 401, 'register: user ' + who + ' exists');
        else {
            var person = new PersonModel();
            person.name = who;
            person.password = req.body.password;
            person.save(function (err) {
                if (err) {
                    reject(res, 500, err);
                } else {
                    console.log('saved ' + who);
                    res.json({session:'123456'});
                }
            });
        }
    });
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

app.post('/befriend', bodyParser.json(), function (req, res) { 

  console.log('befriend: ' + util.inspect(req.body))

  var username = req.body.username

});

var server = app.listen(3000, function () {

  var host = server.address().address;
  var port = server.address().port;

  console.log('Example app listening at http://%s:%s', host, port);

});

