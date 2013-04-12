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
    for i in [0...numberOfChannels]
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
      @firstRun = false

  toString: -> "Karplus-Strong"

class GitarrString extends AudioletGroup
  constructor: (audiolet, frequency) ->
    super audiolet, 0, 1

    @noise = new WhiteNoise @audiolet
    @gain = new Gain @audiolet
    @envelope = new PercussiveEnvelope @audiolet, 0, 0.5, 3,
      ( -> @audiolet.scheduler.addRelative 0, @remove.bind @ ).bind @

    @main  = new KarplusStrong @audiolet, frequency
    @noise.connect @main

    @main.connect @gain
    @envelope.connect @gain, 0, 1
    @gain.connect @outputs[0]

class Range
  base: [ "A", "A#", "B", "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#" ]

  constructor: (id, @isNote=true) ->
    @input  = $("##{id} input")
    @output = $("##{id} output")
    @input.on "change", @change
    @change null

  change: (event) =>
    @value = parseFloat do @input.val
    @output.text if @isNote then do @toString else @value
    return true

  get: ->
    # See http://en.wikipedia.org/wiki/Piano_key_frequencies
    return 440 * Math.pow 2, (@value - 49) / 12

  set: (note) ->
    normalize = (n) -> Math.ceil Math.floor(n / 4) / (n / 4)
    digit  = parseInt note.slice note.length - 1
    letter = 1 + @base.indexOf note.slice 0, note.length - 1
    @input.val letter + 12 * (digit - normalize letter)
    @change null
    return note

  toString: -> "#{@base[(@value - 1) % 12]}#{Math.floor (@value + 8) / 12}"

$ ->
  frequency = new Range "frequency", false
  # CM11 (major eleventh)
  window.notes = "C4-E4-G4-B4-D5-F#5".split "-"
  for i in [0..5]
    range = new Range "tune_#{i}"
    range.set notes[i]
    notes[i] = range

  $play = $("#play")
  $play.on "click", (event) ->
    audiolet = new Audiolet
    frequencyPattern = new PSequence (do note.get for note in notes), 1
    durationPattern  = new PChoose [0.1, 0.15, 0.2, 0.25], 1
    audiolet.scheduler.play [frequencyPattern], 0.01, (tune) ->
      string = new GitarrString audiolet, tune
      string.connect audiolet.output
    return true
