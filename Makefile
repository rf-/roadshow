default: clean roadshow-osx-amd64 roadshow-linux64

roadshow-osx-amd64: src/**/*
	crystal build src/roadshow.cr --release -o roadshow-osx-amd64

roadshow-linux64: src/**/*
	docker run --rm -v `pwd`:/rs crystallang/crystal bash -c 'cd /rs && crystal build src/roadshow.cr --release -o roadshow-linux64'

clean:
	rm -f roadshow-*
