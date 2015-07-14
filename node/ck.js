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

if (!Array.prototype.forEach)
{
   Array.prototype.forEach = function(fun /*, thisp*/)
   {
      var len = this.length;
      if (typeof fun != "function")
      throw new TypeError();
      
      var thisp = arguments[1];
      for (var i = 0; i < len; i++)
      {
         if (i in this)
         fun.call(thisp, this[i], i, this);
      }
   };
}

// apns

var options = { cert: 'cert.pem',
    key: 'key.pem',
    passphrase: '1234',
    production: false
};
var apnConnection = new apn.Connection(options);

var tokens = {};

function tokenAdd(whose, token) {
    if (!tokens[whose]) {
        tokens[whose] = [];
    }
    tokens[whose].add(token);
}

function tokenDel(whose, token) {
    if (tokens[whose]) {
        tokens[whose].remove(token);
    }
}

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

var StorageSchema = new Schema({
    name    : String,
    key     : String,
    value   : String
}, { "collection": "storage" });
var StorageModel = mongoose.model('Storage', StorageSchema);


// express

app.use(expressSession({
    secret:'likethisissupposedtobesomesecretstringorsomething',
    resave: false,
    saveUninitialized: true
}));

function reject(res, status, message) {
    console.log(message);
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

				if (password != passwordFromDB) {
					reject(res, 401, 'login: user ' + who + ' password mismatch: ' + password + ' != ' + passwordFromDB);
				} else {
                    authenticated(req, res, who, person);
				}
			} catch (err) {
                console.log('login error: ' + err);
                reject(res, 500, "could not get password from DB. " + err);
			}
		}
	});
});

function authenticated(req, res, who, person) {
    req.session.username = req.body.username;
    res.json(person.friends);
    tokenAdd(who, req.body.pushToken)
}

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
                    authenticated(req, res, who, person);
                }
            });
        }
    });
});

app.get('/roster', function (req, res) {
    //res.json([{name:'Superman',id:'Clark'},{name:'Batman',id:'Bruce'},{name:'Aquaman',id:'Alex'}]);
    personLoad(req.session.username, res, function(person) {
        res.json(person.friends)
    });
});


app.post('/push', bodyParser.json(), function (req, res) { 

    console.log('body: ' + util.inspect(req.body))

    var token = req.body.token;
    console.log('push to ...' + token + '...')

    var device = new apn.Device(token);
    var note = new apn.Notification();
  
    note.expiry = Math.floor(Date.now() / 1000) + 3600; // Expires 1 hour from now.
    note.badge = 3;
    note.sound = "ping.aiff";
    note.alert = "\uD83D\uDCE7 \u2709 You have a new message";
    note.payload = {'messageFrom': 'Caroline'};
  
    apnConnection.pushNotification(note, device);
});

function push(token, payload) {

    console.log('push to ---' + token + '---')

    var device = new apn.Device(token);
    var note = new apn.Notification();
    note.expiry = Math.floor(Date.now() / 1000) + 3600; // Expires 1 hour from now.
    note.badge = 3;
    note.sound = "ping.aiff";
    note.alert = "\uD83D\uDCE7 \u2709 You have a new message";
    note.payload = payload;
  
    apnConnection.pushNotification(note, device);
}

app.post('/send', bodyParser.json(), function (req, res) { 
    console.log('send: ' + util.inspect(req.body))
        tokens[req.body.addressee].forEach( function (token, index, array) {
    	var payload = {'from':req.session.username, 'message':req.body.message};
    	push(token, payload);
    });
});

app.post('/store', bodyParser.json(), function (req, res) { 
    console.log('store: ' + util.inspect(req.body))

    var query = {'name':req.session.username, 'key':req.body.key};
    var update = {value: req.body.value};
    var options = {upsert: true};
    Storage.findOneAndUpdate(query, update, options, function(err, person) {
        if (err) {
            reject(res, 500, err);
        } else {
            console.log('saved ' + storage.key);
           
        }
    });
});    
    
//    var storage = new StorageModel();
//    storage.name = req.session.username
//    storage.key = req.body.key
//    storage.value = req.body.value
//    storage.save(function (err) {
//        if (err) {
//            reject(res, 500, err);
//        } else {
//            console.log('saved ' + storage.key);
//            res.status(204).send();
//        }    
//    });
//});

app.post('/load', bodyParser.json(), function (req, res) { 
    console.log('load: ' + util.inspect(req.query))

    var n = req.session.username
    var k = req.body.key
    console.log('load ' + n +','+ k)
    StorageModel.find({name :n, key:k}, function (err, docs) {
        if (err) {
            reject(res, 500, err);
        } else if (docs.length != 0) {
            console.log('\load result : ' + docs[0].value)
            res.json({'value':docs[0].value});
            //res.send(docs[0].value);
        } else {
            console.log('no docs')
            res.status(404)
        }
    });
});

function personLoad(who, res, callback) {
    console.log('personLoad ' + who);
    PersonModel.find({name:who}, function (err, docs) {
        if (err) {
            reject(res, 500, err);
        } else if (docs.length != 0) {
            callback(docs[0]);
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
    console.log('\tsession: ' + util.inspect(req.session));
    personLoad(req.body.username, res, function (whom) {
        personLoad(req.session.username, res, function (who) {

            var action = req.body.action;
            if (action == "add") {
                if (!whom) {
                    reject(res, 404, 'befriend: user ' + req.body.username + ' does not exist');
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
            console.log('\tbefriend result : ' + who.friends)
            res.json(who.friends);
        });
    });
});



var server = app.listen(3000, function () {

    var host = server.address().address;
    var port = server.address().port;

    console.log('CK server listening at http://%s:%s', host, port);
});

