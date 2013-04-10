class Range
  constructor: (id) ->
    @input  = $("##{id} input")
    @output = $("##{id} output")
    @input.on "change", @change
    @change null

  change: (event) =>
    @value = parseFloat do @input.val
    @output.text "#{Math.floor(@value / 60)}:#{(@value % 60).toFixed 1}"
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

class Splice extends AudioletGroup
  constructor: (audiolet, first, second, time) ->
    super audiolet, 0, 1

    @first  = new BufferPlayer audiolet, first
    @second = new BufferPlayer audiolet, second
    @switch = new Switch audiolet, 1.0
    @delay  = new Delay audiolet, time, time
    @cross  = new CrossFade audiolet, 0

    @switch.connect @delay
    @first.connect  @cross, 0, 0
    @second.connect @cross, 0, 1
    @delay.connect  @cross, 0, 2
    @cross.connect  @outputs[0]

$ ->
  time  = new Range "time"
  $play = $("#play")

  load = (path) ->
    deferred = new $.Deferred
    buffer   = new AudioletBuffer 1, 0
    buffer.load "/audio/#{path}.wav", true, ->
      deferred.resolve buffer
    return deferred

  $play.attr "disabled", "disabled"
  $.when(load("Song_of_Storms"), load("Song_of_Time")).done (first, second) ->
    audiolet = new Audiolet
    time.max Math.min(first.length, second.length) / audiolet.device.sampleRate
    $play.removeAttr "disabled"
    $play.on "click", (event) ->
      splice   = new Splice audiolet, first, second, time.value
      splice.connect audiolet.output
      return true
