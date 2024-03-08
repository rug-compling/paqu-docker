package main

import (
	"fmt"
	"os"

	"github.com/pebbe/dbxml"
	"github.com/pebbe/util"
)

func main() {
	replace := false
	if len(os.Args) > 1 && os.Args[1] == "-r" {
		replace = true
		os.Args = append(os.Args[:1], os.Args[2:]...)
	}

	if len(os.Args) < 3 {
		fmt.Printf(`
Usage: %s [-r] file.dbxml file.xml...

  -r : replace XML files with same name

Stores XML files in 'file.dbxml'.

`, os.Args[0])
		return
	}

	x := util.CheckErr

	db, err := dbxml.OpenReadWrite(os.Args[1])
	x(err)
	defer db.Close()

	for _, filename := range os.Args[2:] {
		fmt.Printf(" %s        \r", filename)
		x(db.PutFile(filename, replace))
	}
	fmt.Println()
}
