class Range
  constructor: (id) ->
    @input  = $("##{id} input")
    @output = $("##{id} output")
    @input.on "change", @change
    @change null

  change: (event) =>
    @value = parseFloat do @input.val
    @output.text "#{Math.floor(@value / 60)}:#{(@value % 60).toFixed 2}"
    return true

  max: (value) -> @input.attr "max", value

class Switch extends AudioletNode
  constructor: (audiolet, time) ->
    super audiolet, 0, 1
    @linkNumberOfOutputChannels 0, 0
    @length = Math.floor audiolet.device.sampleRate * time
    @index  = 0

  generate: (inputBuffers, outputBuffers) ->
    output = @outputs[0]

    numberOfChannels = output.samples.length
    for i in [0..numberOfChannels - 1]
      output.samples[i] = @index / @length

    if @index < @length
      @index++

  toString: -> "Switch"

class Fade extends AudioletGroup
  FADE_TIME = 1.0

  constructor: (audiolet, first, second, time) ->
    super audiolet, 0, 1

    @first  = new BufferPlayer audiolet, first
    @second = new BufferPlayer audiolet, second
    @switch = new Switch audiolet, FADE_TIME
    @delay  = new Delay audiolet, time, time
    @cross  = new CrossFade audiolet, 0

    @switch.connect @delay
    @first.connect  @cross, 0, 0
    @second.connect @cross, 0, 1
    @delay.connect  @cross, 0, 2
    @cross.connect  @outputs[0]

class Splice extends AudioletGroup
  constructor: (audiolet, first, second, stop, start) ->
    super audiolet, 0, 1

    to   = Math.floor first.sampleRate * stop
    from = Math.floor second.sampleRate * start

    @buffer = new AudioletBuffer first.numberOfChannels, to + second.length - from
    @buffer.setSection first, to, 0, 0
    @buffer.setSection second, second.length - from, from, to
    @player = new BufferPlayer audiolet, @buffer, first.sampleRate / audiolet.device.sampleRate

    @player.connect @outputs[0]

$ ->
  stop  = new Range "stop"
  start = new Range "start"
  $play = $("#play")

  load = (path) ->
    deferred = new $.Deferred
    buffer   = new AudioletBuffer 1, 0
    request  = new AudioFileRequest "/audio/#{path}.wav", true
    request.onSuccess = (decoded) ->
      buffer.length = decoded.length
      buffer.numberOfChannels = decoded.channels.length
      buffer.unslicedChannels = decoded.channels
      buffer.channels = decoded.channels
      buffer.channelOffset = 0
      buffer.sampleRate = decoded.sampleRate
      deferred.resolve buffer

    request.onFailure = ->
      deferred.reject "Could not load", path

    do request.send
    return deferred

  $play.attr "disabled", "disabled"
  # $.when(load("Song_of_Storms"), load("Song_of_Time")).done (first, second) ->
  $.when(load("karta"), load("kaka")).done (first, second) ->
    audiolet = new Audiolet
    stop.max first.length / first.sampleRate
    start.max second.length / second.sampleRate
    $play.removeAttr "disabled"
    $play.on "click", (event) ->
      splice = new Splice audiolet, first, second, stop.value, start.value
      splice.connect audiolet.output
      return true
