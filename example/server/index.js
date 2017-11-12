const fs = require('fs');
const path = require('path');

var express = require('express')
var multer = require('multer')
var upload = multer({ dest: 'uploads/' });
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

app.post('/upload', upload.single('upload'), function (req, res, next) {
  console.log(req.file);
  console.log(req.body);
  // fs.writeFileSync(req.body, path.join(__dirname, 'uploads', req.file.originalname));
  res.send({"message": req.file.filename});
})

app.listen(5000, function () {
  console.log('Example app listening on port 5000!')
});
