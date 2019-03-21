LESS_SRC = src/*.less
TARGETS  = board.min.css main.min.css reports.min.css storage.min.css

all: $(TARGETS)

%.min.css: %.css
	cssmin < $< > $@

%.css: src/%.less $(LESS_SRC)
	lessc $< $@
