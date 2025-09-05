const express = require('express');
const path = require('path');
const app = express();
const utils = require('./utils/utils') // utils.js

const port = 3000;
const hostname = '127.0.0.1';
const index = "index.html"

// Serve static files from the 'root' directory
app.use(express.static(__dirname));
app.use(express.static(path.join(__dirname, "docs")));

// Return home page
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, "docs", index));
});

app.get('/listfiles', (req, res) => {
  const hlslfiles = utils.search();
  res.send(hlslfiles)
});

app.get('/zip', (req, res) => {
  var type = req.query.type;
  if (type === "undefined") {
    type = 'hlsl';
  }

  const hlslfiles = utils.search();

  // Converts HLSL files to given type and then zips the results
  utils.zipFiles(hlslfiles, type)
    .then(buffer => {
      res.set('Content-Type', 'application/zip');
      res.set('Content-Disposition', 'attachment; filename="shaders.zip"');
      res.send(buffer);
    });
});

app.get('/preprocess', (req, res) => {
  const file = req.query.file;
  utils.preprocess(file).then(result => {
    res.send(result)
  });
});

app.get('/about', (req, res) => {
  res.send('About page');
});

app.use((req, res, next) => {
  res.status(404).send("Sorry can't find that!")
})

app.listen(port, () => {
  console.log(`Server listening on http://${hostname}:${port}/`);
});
