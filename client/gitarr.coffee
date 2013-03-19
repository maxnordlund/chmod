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

$ ->
  frequency = new Range "frequency"
  mix       = new Range "mix"
  roomSize  = new Range "roomSize"
  damping   = new Range "damping"

  $play = $("#play")
  $play.on "click", (event) ->
    window.notes = [40, 42, 44, 45, 47, 49].map note
    window.note  = note
    # frequencyPattern = new PSequence notes, Infinity
    frequencyPattern = new PChoose notes, Infinity
    window.pattern = frequencyPattern
    audiolet = new Audiolet
    total = 0
    audiolet.scheduler.play [frequencyPattern], 1, (tune) ->
      console.log ++total
      string = new GitarrString audiolet, tune
      string.connect audiolet.output
    return true
