# Compiling of assets

blue  := \E[2;36m
gray  := \E[2;37m
green := \E[2;32m
reset := \E[0;00m
arrow := \xe2\x9e\x9e

define done
	@printf "$(gray)Compiled$(reset)$(blue) $1 $(reset)\n"
	@printf "$(gray)      $(arrow)$(reset)$(blue)  $2 $(reset)\n"
endef

jsPath := public/javascript

js    := $(wildcard client/*.coffee)
js    := $(js:client/%.coffee=$(jsPath)/%.js)
# js    := $(js) $(jsPath)/angular.js $(jsPath)/angular-ui.js $(jsPath)/select2.js
css   := $(wildcard style/*.styl)
# css   := $(css) public/style/select2.css
css   := $(css:style/%.styl=public/style/%.css)
html  := $(wildcard views/*.jade)
html  := $(filter-out views/lib.jade,$(html))
html  := $(filter-out views/layout.jade,$(html))
html  := $(html:views/%.jade=public/xhtml/%.html)
mp3   := $(wildcard audio/*.mp3)
mp3   := $(mp3:audio/%.mp3=public/audio/%.wav)
wav   := $(wildcard audio/*.wav)
wav   := $(wav:audio/%.wav=public/audio/%.wav)

.PHONY: clean dist run

all: node_modules $(js) $(css) $(html) $(mp3) $(wav)

run: all
	@coffee server.coffee

clean:
	@rm -fr public

dist: clean
	@rm -fr node_modules

# Directories
#############
$(jsPath):
	@mkdir -p $(jsPath)

public/style:
	@mkdir -p public/style

public/xhtml:
	@mkdir -p public/xhtml

public/audio:
	@mkdir -p public/audio

# Angular and Angular UI
########################
node_modules/AngularJS/build/angular.js:
	@printf "$(green)"
	@cd node_modules/AngularJS/; rake minify
	@printf "$(reset)"

$(jsPath)/angular.js: node_modules/AngularJS/build/angular.js $(jsPath)
	@cp $< $@
	$(call done,$<,$@)

$(jsPath)/angular-ui.js: node_modules/angular-ui/build/angular-ui.js $(jsPath)
	@cp $< $@
	$(call done,$<,$@)

# Select2
#########
$(jsPath)/select2.js: select2/select2.js $(jsPath)
	@cp $< $@
	$(call done,$<,$@)

public/style/select2.css: select2/select2.css public/style/select2.png public/style/select2-spinner.gif public/style
	@cp $< $@
	$(call done,$<,$@)

public/style/select2.png: select2/select2.png public/style
	@cp $< $@
	$(call done,$<,$@)

public/style/select2-spinner.gif: select2/select2-spinner.gif public/style
	@cp $< $@
	$(call done,$<,$@)

# Pattern rules
###############
$(jsPath)/%.js: client/%.coffee $(jsPath)
	@coffee -c -o $(jsPath) $< 1> /dev/null
	$(call done,$<,$@)

public/style/%.css: style/%.styl public/style
	@stylus -u ./node_modules/nib/ -I style/ -o public/style $< 1> /dev/null
	$(call done,$<,$@)

public/xhtml/%.html: views/%.jade public/xhtml
	@jade -P -O public/xhtml -p views/ -o views/$*.json $< 1> /dev/null
	$(call done,$<,$@)

public/audio/%.wav: audio/%.mp3 public/audio
	@lame --quiet --decode $< $@ 1> /dev/null
	$(call done,$<,$@)

public/audio/%.wav: audio/%.wav public/audio
	@cp $< $@ 1> /dev/null
	$(call done,$<,$@)
