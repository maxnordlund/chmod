class Synth extends AudioletGroup
  constructor: (audiolet, frequency) ->
    super audiolet, 0, 1
    @sine = new Sine @audiolet, frequency
    @modulator = new Saw @audiolet, 2 * frequency
    @modulatorMulAdd = new MulAdd @audiolet, frequency / 2, frequency
    @gain = new Gain @audiolet
    @envelope = new PercussiveEnvelope @audiolet, 1, 0.2, 0.5,
      ( -> @audiolet.scheduler.addRelative 0, @remove.bind @ ).bind @

    @modulator.connect @modulatorMulAdd
    @modulatorMulAdd.connect @sine
    @envelope.connect @gain, 0, 1
    @sine.connect @gain
    @gain.connect @outputs[0]

class KarplusStrong extends AudioletNode
  constructor: (audiolet, frequency) ->
    super audiolet, 1, 1
    @linkNumberOfOutputChannels 0, 0
    @period = Math.floor @audiolet.device.sampleRate / frequency
    @buffers = []
    @firstRun = true
    @index  = 0

  generate: (inputBuffers, outputBuffers) ->
    input  = @inputs[0]
    output = @outputs[0]

    numberOfChannels = input.samples.length
    numberOfBuffers  = @buffers.length
    for i in [0..numberOfChannels - 1]
      if i >= numberOfBuffers
        @buffers.push new Float32Array @period

      buffer = @buffers[i]
      if @firstRun
        output.samples[i] = input.samples[i]
      else
        if @index is 0
          prev = @period - 1
        else
          prev = @index - 1
        output.samples[i] = (buffer[@index] + buffer[prev]) / 2
      buffer[@index] = output.samples[i]

    @index++
    if @index >= @period
      @index = 0
      console.log @audiolet.device.sampleRate / @period if @firstRun
      @firstRun = false

  toString: -> "Karplus-Strong"

class GitarrString extends AudioletGroup
  constructor: (audiolet, frequency) ->
    super audiolet, 0, 1

    @noise = new WhiteNoise @audiolet
    @gain = new Gain @audiolet
    @envelope = new PercussiveEnvelope @audiolet, 0, 0.2, 0.5,
      ( -> @audiolet.scheduler.addRelative 0, @remove.bind @ ).bind @

    @main  = new KarplusStrong @audiolet, frequency
    @noise.connect @main

    @main.connect @gain
    @envelope.connect @gain, 0, 1
    @gain.connect @outputs[0]

class Gitarr extends AudioletGroup
  constructor: (audiolet, arr) ->
    super audiolet, 0, 1
    add = new Add @audiolet
    add.connect @outputs[0]
    window.strings = []
    for frequency in arr
      tmp = new Add @audiolet
      time = do Math.random
      delay = new Delay @audiolet, time, time
      string = new GitarrString @audiolet, frequency
      string.connect delay
      strings.push string
      delay.connect add, 0, 1
      add.connect tmp
      add = tmp

    console.log "Done with prep"

    for string in strings
      string.envelope.gate.setValue 1

class Link extends AudioletGroup
  constructor: (audiolet, frequency, wait) ->
    super audiolet, 0, 1
    sound = new GitarrString audiolet, frequency
    delay = new Delay audiolet, wait, wait
    adder = new Add audiolet

    sound.connect adder, 0, 1
    delay.connect adder
    adder.connect @outputs[0]

class Range
  constructor: (id) ->
    @input  = $("##{id} input")
    @output = $("##{id} output")
    @input.on "change", @change
    @change null

  change: (event) =>
    @value = parseFloat do @input.val
    @output.text @value
    return true

# See http://en.wikipedia.org/wiki/Piano_key_frequencies
note = (n) -> 440 * Math.pow 2, (n - 49) / 12

#+ Jonas Raoni Soares Silva
#@ http://jsfromhell.com/array/shuffle [v1.0]
shuffle = (o) -> #v1.0
  j = undefined
  x = undefined
  i = o.length

  while i
    j = parseInt(Math.random() * i)
    x = o[--i]
    o[i] = o[j]
    o[j] = x
  o

class Simple
  constructor: (arr) ->
    @index = 0
    @notes = []
    for tune in arr
      @notes.push note tune
    shuffle @notes

  next: ->
    tune = @notes[@index]
    unless tune?
      shuffle @notes
      @index = 0
      return do @next
    @index++
    console.log tune
    return tune

$ ->
  frequency = new Range "frequency"
  mix       = new Range "mix"
  roomSize  = new Range "roomSize"
  damping   = new Range "damping"

  audiolet  = new Audiolet

  $play = $("#play")
  $play.on "click", (event) ->
    console.log frequency.value, mix.value, roomSize.value, damping.value
    # sound = new GitarrString audiolet, frequency.value
    # sound = new Gitarr audiolet, [200, 440, 200, 440, 560]
    # sound.connect audiolet.output
    out = audiolet.output
    arr = [40, 42, 44, 45, 47, 49]
    window.arr = arr
    wait = 0.2
    pattern = new Simple arr
    total = 0
    # for tune in arr
    while total < 10
      freq  = do pattern.next
      continue unless freq?
      # wait  = do Math.random
      sound = new GitarrString audiolet, freq
      delay = new Delay audiolet, wait, wait
      adder = new Add audiolet

      sound.connect adder, 0, 1
      delay.connect adder
      adder.connect out

      out = delay
      total++
    return true
