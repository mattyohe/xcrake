rakelibs := $(wildcard rakelib/*.rake)

build/Rakefile: Rakefile $(rakelibs)
	mkdir -p build
	cat Rakefile rakelib/*.rake > build/Rakefile

clean:
	rm -rf build
