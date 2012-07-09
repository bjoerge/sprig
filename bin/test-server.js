#!/usr/bin/env node

var express = require('express'),
    app = express.createServer(),
    browserify = require('browserify');

app.use(express.static(__dirname+"/.."));

app.get('/', function(req, res) {
  res.redirect('/test/browser.html');
});

var bundle = browserify({
  ignore: ['ws', 'mocha', 'buster-format', 'jsdom', 'xmlhttprequest', 'location', 'navigator'],
  entry: 'extra/browserify.coffee',
  watch: true
});

app.use(bundle);

app.listen(8080);

reload = require("../extra/reloader").serve({host: null, port: 8081});
bundle.on("bundle", function() {
  console.log("Rebundle...");
  reload();
});


console.log("Run tests by pointing your browser to http://localhost:8080")