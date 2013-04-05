Class Plotter extends AudioletNode
	constructor: (audiolet, canvases) ->
		super audiolet, 1, 0
		@canvas = canvas
		@ctx = canvas.getContext("2D")
		@x = 0
		
	generate: (inputBuffers) ->
		input	= @inputs[0]
		
		@ctx.fillStyle = "#FFF"
		@ctx.fillRect ((x+1) % @canvas.width) 0 3 @canvas.height
		@ctx.moveTo (x % @canvas.width), @canvas.height/2
		@ctx.lineTo (x % @canvas.width), (@canvas.height/2 + input.samples[0])
		if input.samles.length > 1
			@ctx.lineTo (x % @canvas.width), (@canvas.height/2 - input.samples[1])
		@ctx.stroke
		
	toString: -> "Plotter"