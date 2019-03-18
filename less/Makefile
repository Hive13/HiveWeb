LESS_SRC = src/*.less
TARGETS  = admin.min.css main.min.css reports.min.css

all: $(TARGETS)

%.min.css: %.css
	cssmin < $< > $@

%.css: src/%.less $(LESS_SRC)
	lessc $< $@
