class Synth extends AudioletGroup
  constructor: (audiolet, frequency) ->
    super [audiolet, 0, 1]...
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
  constructor: (audiolet, frequency, mix, roomSize, damping) ->
    super [audiolet, 0, 1]...

    @noise = [
      new WhiteNoise @audiolet
      new WhiteNoise @audiolet
      new WhiteNoise @audiolet
    ]
    @gain = new Gain @audiolet
    @envelope = new PercussiveEnvelope @audiolet, 1, 0.2, 0.5,
      ( -> @audiolet.scheduler.addRelative 0, @remove.bind @ ).bind @
    @effect = new Reverb @audiolet, mix, roomSize, damping

    @main  = new KarplusStrong @audiolet, frequency
    @above = new KarplusStrong @audiolet, frequency * 1.005
    @below = new KarplusStrong @audiolet, frequency * 0.995

    @addOther = new Add @audiolet
    @addFinal = new Add @audiolet

    @noise[0].connect @main
    @noise[1].connect @above
    @noise[2].connect @below

    @above.connect @addOther, 0, 0
    @below.connect @addOther, 0, 1

    @main.connect @addFinal, 0, 0
    @addOther.connect @addFinal, 0, 1

    @addFinal.connect @gain
    @envelope.connect @gain, 0, 1
    @gain.connect @effect
    @effect.connect @outputs[0]

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

$ ->
  frequency = new Range "frequency"
  mix       = new Range "mix"
  roomSize  = new Range "roomSize"
  damping   = new Range "damping"

  audiolet  = new Audiolet

  $play = $("#play")
  $play.on "click", (event) ->
    console.log frequency.value, mix.value, roomSize.value, damping.value
    sound = new GitarrString audiolet, frequency.value, mix.value, roomSize.value, damping.value
    sound.connect audiolet.output
    window.sound = sound
    return true
