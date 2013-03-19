class Synth extends AudioletGroup
  constructor: (audiolet, frequency) ->
    super [audiolet, 0, 1]...
    @sine = new Sine @audiolet, frequency.value
    @modulator = new Saw @audiolet, 2 * frequency.value
    @modulatorMulAdd = new MulAdd @audiolet, frequency.value / 2, frequency.value
    @gain = new Gain @audiolet
    @envelope = new PercussiveEnvelope @audiolet, 1, 0.2, 0.5,
      ( -> @audiolet.scheduler.addRelative 0, @remove.bind @ ).bind @

    @modulator.connect @modulatorMulAdd
    @modulatorMulAdd.connect @sine
    @envelope.connect @gain, 0, 1
    @sine.connect @gain
    @gain.connect @outputs[0]

class Feedback extends AudioletGroup
  constructor: (audiolet, frequency, feedback, mix) ->
    super [audiolet, 0, 1]...
    period = Math.floor @audiolet.device.sampleRate / frequency.value

    @noise = new WhiteNoise @audiolet
    @gain = new Gain @audiolet
    @envelope = new PercussiveEnvelope @audiolet, 1, 0.2, 0.5,
      ( -> @audiolet.scheduler.addRelative 0, @remove.bind @ ).bind @
    @feedbackDelay = new FeedbackDelay @audiolet, period, period, feedback.value, mix.value

    @noise.connect @feedbackDelay
    @feedbackDelay.connect @gain
    @envelope.connect @gain, 0, 1
    @gain.connect @outputs[0]

class Fail extends AudioletGroup
  constructor: (audiolet, frequency, feedback, mix) ->
    super [audiolet, 0, 1]...
    period = 1
    console.log period, @audiolet.device.sampleRate, frequency.value

    # Burst of white noise
    @noise = new WhiteNoise @audiolet
    @burst = new Gain @audiolet
    @burstEnvelope = new PercussiveEnvelope @audiolet, 1, period, period,
      ( -> @audiolet.scheduler.addRelative 0, @remove.bind @ ).bind @

    # Feedback delay
    @delay = new Delay @audiolet, period, period
    @lowPass = new LowPassFilter @audiolet, frequency
    @mulAdd = new MulAdd @audiolet, 0.5, 0
    # @mixer = new UpMixer @audiolet, 2

    # Single tune
    @gain = new Gain @audiolet
    @gainEnvelope = new PercussiveEnvelope @audiolet, 1, 2, 5,
      ( -> @audiolet.scheduler.addRelative 0, @remove.bind @ ).bind @

    # Connect nodes
    @burstEnvelope.connect @burst, 0, 1
    @gainEnvelope.connect @gain, 0, 1
    @noise.connect @burst

    @burst.connect @mulAdd, 0, 0
    @lowPass.connect @mulAdd, 0, 2

    @mulAdd.connect @delay
    @mulAdd.connect @gain

    @delay.connect @lowPass
    @burst.connect @gain
    @gain.connect @outputs[0]

class KarplusStrong extends AudioletNode
  constructor: (audiolet, frequency, feedback, mix) ->
    super audiolet, 1, 1
    @linkNumberOfOutputChannels 0, 0
    @period = Math.floor @audiolet.device.sampleRate / frequency.value
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

class Gitarr extends AudioletGroup
  constructor: (audiolet, frequency, feedback, mix) ->
    super [audiolet, 0, 1]...

    @noise = new WhiteNoise @audiolet
    @gain = new Gain @audiolet
    @envelope = new PercussiveEnvelope @audiolet, 1, 0.2, 0.5,
      ( -> @audiolet.scheduler.addRelative 0, @remove.bind @ ).bind @
    @karplus = new KarplusStrong @audiolet, frequency, feedback, mix
    @mixer = new UpMixer @audiolet, 2

    @noise.connect @karplus
    @karplus.connect @gain
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

$ ->
  frequency = new Range "frequency"

  audiolet  = new Audiolet

  $play = $("#play")
  $play.on "click", (event) ->
    console.log frequency.value, feedback.value, mix.value
    sound = new Gitarr audiolet, frequency, feedback, mix
    sound.connect audiolet.output
    window.sound = sound
    return true
