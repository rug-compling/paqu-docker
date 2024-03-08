
all: \
	/opt/bin/corpustest \
	/opt/bin/dbtest \
	/opt/bin/dbwait \
	/opt/bin/dbxml_create

/opt/bin/% : %.go go.mod
	CGO_CFLAGS=-I/opt/dbxml2/include \
	CGO_CXXFLAGS=-I/opt/dbxml2/include \
	CGO_LDFLAGS='-L/opt/dbxml2/lib -Wl,-rpath=/opt/dbxml2/lib' \
	/go/bin/go build -o $@ $<

go.mod: *.go
	rm -f go.mod go.sum
	go mod init localhost
	go mod tidy

