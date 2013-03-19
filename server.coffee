express = require "express"
fibrous = require "fibrous"
color   = require "bash-color"

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
  app.use fibrous.middleware

  # Set up routes
  app.get "/", (req, res) ->
    # res.set "Content-Type": "application/xhtml+xml; charset=utf-8"
    res.render "index", require "./views/index.json"

  app.get "/gitarr", (req, res) ->
    # res.set "Content-Type": "application/xhtml+xml; charset=utf-8"
    res.render "gitarr", require "./views/gitarr.json"

app.configure "production", ->
  app.get "/javascript/Audiolet.js", (req, res) ->
    res.sendfile "./Audiolet/src/audiolet/Audiolet.min.js"

# Debug and logging
app.configure "development", ->
  app.use require("express-error").express3
    contextLinesCount: 3
    handleUncaughtException: true

  app.get "/javascript/Audiolet.js", (req, res) ->
    res.sendfile "./Audiolet/src/audiolet/Audiolet.js"

# Define port and start Server
port = process.env.PORT or process.env.VMC_APP_PORT or 3000
app.listen port, -> console.log "Listening on #{port}\nPress CTRL-C to stop server."
