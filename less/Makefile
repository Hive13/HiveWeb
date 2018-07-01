LESS_SRC  = src/*.less
LESS_IN   = src/base.less
LESS_DEST = style.css

%.min.css: %.css
	cssmin < $< > $@

%.css: src/%.less $(LESS_SRC)
	lessc $< $@
