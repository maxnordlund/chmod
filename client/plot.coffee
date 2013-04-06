class Plotter extends AudioletNode
	constructor: (audiolet, canvas) ->
		super audiolet, 1, 0
		@canvas = canvas
		@ctx = canvas.getContext "2D"
		@x = 0

	generate: (inputBuffers) ->
		input 			= @inputs[0]
		clear_width 	= 3
		clear_x 		= (x + 1) % @canvas.width
		
		@ctx.fillStyle = "#FFF"
		
		@ctx.fillRect clear_x, 0, clear_width, @canvas.height
		
		@ctx.moveTo pos_x, @canvas.height / 2
		@ctx.lineTo pos_x, (@canvas.height / 2 + input.samples[0])
		if input.samles.length > 1
			@ctx.lineTo (x % @canvas.width), (@canvas.height/2 - input.samples[1])
		@ctx.stroke
		x = clear_x
		
	toString: -> "Plotter"
	
$ ->
	audiolet  = new Audiolet
	
	$play = $("#play")
	$play.on "click", (event) ->
		console.log frequency.value, mix.value, roomSize.value, damping.value
		sound = new GitarrString audiolet, frequency.value, mix.value, roomSize.value, damping.value
		sound.connect audiolet.output
		window.sound = sound
		return true