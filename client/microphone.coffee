class Microphone extends AudioletNode
	constructor: (audiolet) ->
		super audiolet, 1, 1
		@linkNumberOfOutputChannels 0, 0
		this.trigger = new AudioletParameter this 1 (value || 0)
		
		
	generate: (inputBuffers, outputBuffers) ->
		input  = @inputs[0]
		output = @outputs[0]

