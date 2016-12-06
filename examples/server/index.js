var express = require('express')
var multer = require('multer')
// var upload = multer({ dest: 'uploads/' })
var upload = multer();
var cors = require('cors');


var app = express();
app.use(cors());

app.get('/', function (req, res) {
//   res.send('Hello World!')
  res.sendFile(__dirname+'/index.html');
})

app.get('/test', function (req, res) {
  res.sendFile(__dirname+'/test.html');
})

app.post('/upload', upload.single('simtest'), function (req, res, next) {
  console.log(req.file);
  console.log(req.body);
  res.send({"message": "received"});
})

app.listen(5000, function () {
  console.log('Example app listening on port 5000!')
});
