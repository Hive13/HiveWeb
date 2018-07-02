LESS_SRC = src/*.less
TARGETS  = admin.min.css main.min.css

all: $(TARGETS)

%.min.css: %.css
	cssmin < $< > $@

%.css: src/%.less $(LESS_SRC)
	lessc $< $@
