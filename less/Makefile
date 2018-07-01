LESS_SRC  = src/*.less
LESS_IN   = src/base.less
LESS_DEST = style.css

%.min.css: %.css
	cssmin < $< > $@

$(LESS_DEST): $(LESS_SRC)
	lessc $(LESS_IN) $@	
