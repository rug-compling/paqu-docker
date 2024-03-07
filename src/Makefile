
all: \
	/opt/bin/corpustest \
	/opt/bin/dbtest \
	/opt/bin/dbwait

/opt/bin/% : %.go go.mod
	/go/bin/go build -o $@ $<

go.mod: *.go
	rm -f go.mod go.sum
	go mod init localhost
	go mod tidy

