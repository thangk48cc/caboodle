// requires

var util = require('util')
var express = require('express');
var app = express();
var expressSession = require('express-session');
var bodyParser = require('body-parser')
var apn = require('apn');

// array prototype

Array.prototype.contains = function(k) {
    return this.indexOf(k) > -1;
}

Array.prototype.add = function(k) {
    var index = this.indexOf(k);
    if (index == -1) {
        this.push(k)
    }
    else {
        return true;
    }
}

Array.prototype.remove = function(k) {
    var index = this.indexOf(k);
    if (index > -1) {
        this.splice(index, 1);
    }
    else {
        return true;
    }
}

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
mongoose.connect('mongodb://localhost/ckdb')
  
var PersonSchema = new Schema({
    name    : String,
    hashed  : String,
    salt	: String,
    name    : String,
    pubkey  : String,
    password: String,
    friends : [String]
}, { "collection": "persons" });
var PersonModel = mongoose.model('Person', PersonSchema);


// express

app.use(expressSession({
    secret:'likethisissupposedtobesomesecretstringorsomething',
    resave: false,
    saveUninitialized: true
}));

function reject(res, status, message) {
    res.status(status).send({ error: message });
}

app.get('/', function (req, res) {
  console.log("hi " + req.session)
  res.send("Hello World! " + req.session);
});

app.post('/login', bodyParser.json(), function (req, res) { 
    console.log('login: ' + util.inspect(req.body))

    var who = req.body.username
    var password = req.body.password

    PersonModel.find({name:who}, function (err, docs) {
        console.log('login: found ' + docs);
		if (err)
			reject(res, 500, "find error. " + err.message);
		else if (!docs.length)
			reject(res, 403, 'login: user ' + who + ' does not exist');
		else {
			try {
                var person = docs[0];
				var passwordFromDB = person.password;
				console.log('password from db: ' + passwordFromDB);

				if (password != passwordFromDB) {
					reject(res, 401, 'login: user ' + who + ' password mismatch: ' + password + ' != ' + passwordFromDB);
				} else {
                    //res.json({session:'123456'});
                    req.session.username = who;
                    res.json(person.friends);
				}
			} catch (err) {
                reject(res, 500, "could not get password from DB. " + err);
			}
		}
	});
});

app.get('/logout',function(req,res) {
    req.session.destroy(function(err) {
        if (err) {
            console.log(err);
            reject(res, 500, "could not logout. " + err);
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
                    req.session.username = who;
                    res.status(204).send();
                    //res.json({session:'123456'});
                }
            });
        }
    });
});

app.get('/roster', function (req, res) {
    //res.json([{name:'Superman',id:'Clark'},{name:'Batman',id:'Bruce'},{name:'Aquaman',id:'Alex'}]);
    var person = loadPerson(req.session.username, res)
    res.json(person.friends)
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

function personLoad(who, res) {
    PersonModel.find({name:who}, function (err, docs) {
        if (err) {
            reject(res, 500, err);
        } else if (docs.length != 0) {
            return docs[0]
        }    
    });
}

function personSave(person, res) {
    person.save(function (err) {
        if (err) {
            reject(res, 500, err);
        } else {
            console.log('saved ' + person.name);
        }
    });    
}

app.post('/befriend', bodyParser.json(), function (req, res) { 

    console.log('befriend: ' + util.inspect(req.body))
    var whom = personLoad(req.body.username, res)
    var who = personLoad(req.session.username, res)
    var action = req.body.action;

    if (action == "add") {
        if (whom == nil) {
            reject(res, 404, 'befriend: user ' + whom.name + ' does not exist');
            return
        }
        if (who.friends.add(whom.name)) {
            reject(res, 422, 'befriend: user ' + whom.name + ' is already a friend');
            return
        }

    } else if (action == "del") { // unfriend
        if (who.friends.remove(whom.name)) {
            reject(res, 404, 'befriend: user ' + whom.name + ' is not a friend');
            return
        }
    } else {
        reject(res, 422, 'befriend: unknown action ' + action);
        return
    }

    personSave(who)
});



var server = app.listen(3000, function () {

    var host = server.address().address;
    var port = server.address().port;

    console.log('CK server listening at http://%s:%s', host, port);
});

