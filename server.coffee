express = require "express"
color   = require "bash-color"
async   = require "async"
fs      = require "fs"

# Setup server
app = do express

app.configure ->
  # Setup view Engine
  app.set "views", "#{__dirname}/views"
  app.set "view engine", "jade"

  # Set the public folder as static assets
  app.use express.static "#{__dirname}/public"

  # Set up middleware
  app.use require("express-jquery") "/javascript/jquery.js"

  # Set up routes
  get = (routes...) ->
    routes.forEach (route) ->
      app.get "/#{route}", (req, res) ->
        # res.set "Content-Type": "application/xhtml+xml; charset=utf-8"
        res.render route, require "./views/#{route}.json"

  get "gitarr", "splice", "ui"

  app.get "/", (req, res) ->
    # res.set "Content-Type": "application/xhtml+xml; charset=utf-8"
    res.render "index", require "./views/index.json"

  app.get "/ui/laptop.svg", (req, res) ->
    res.set "Content-Type": "image/svg+xml; charset=utf-8"
    res.render "laptop", require "./views/laptop.json"

loadAudiolet = (extension) ->
  path = "./Audiolet/src/audiolet/Audiolet#{extension}"
  async.parallel
    audiofile: async.apply fs.readFile, "./Audiolet/src/audiofile/audiofile.js", encoding: "utf-8"
    audiolet:  async.apply fs.readFile, path, encoding: "utf-8"
  , (err, files) ->
    audiolet = "#{files.audiofile}\n#{files.audiolet}"
    app.get "/javascript/Audiolet.js", (req, res) ->
      res.set "Content-Type": "application/javascript; charset=utf-8"
      res.send audiolet

app.configure "production", ->
  loadAudiolet ".min.js"

# Debug and logging
app.configure "development", ->
  loadAudiolet ".js"

  app.use require("express-error").express3
    contextLinesCount: 3
    handleUncaughtException: true

# Define port and start Server
port = process.env.PORT or process.env.VMC_APP_PORT or 3000
app.listen port, -> console.log "Listening on #{port}\nPress CTRL-C to stop server."
