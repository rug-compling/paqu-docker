package main

import (
	"github.com/pebbe/dbxml"

	"encoding/xml"
	"fmt"
	"os"
)

type Alpino struct {
	Conllu ConlluT `xml:"conllu"`
}

type ConlluT struct {
	Status string `xml:"status,attr"`
	Auto   string `xml:"auto,attr"`
}

func main() {
	version := os.Args[1]
	filename := os.Args[2]

	db, err := dbxml.OpenRead(filename)
	if err != nil {
		fmt.Println("DACT_ERROR", err)
		return
	}

	size, err := db.Size()
	if err != nil {
		fmt.Println("DACT_ERROR", err)
		return
	}

	message1 := "DACT_HAS_NO_UD"
	message2 := "NO_DACTX"

	defer func() {
		fmt.Println(message1, message2)
	}()

	has_ud := false

	docs, err := db.All()
	if err != nil {
		fmt.Println("DACT_ERROR", err)
		return
	}
	for docs.Next() {
		data := docs.Content()
		var alpino Alpino
		err := xml.Unmarshal([]byte(data), &alpino)
		if err != nil {
			fmt.Println("DACT_ERROR", err)
			return
		}
		if alpino.Conllu.Status != "" {
			has_ud = true
			if alpino.Conllu.Auto != version {
				message1 = "DACT_HAS_OLD_UD"
			} else {
				message1 = "DACT_HAS_UD"
			}
		}
		docs.Close()
	}
	if err := docs.Error(); err != nil {
		fmt.Println("DACT_ERROR", err)
		return
	}
	db.Close()

	////////////////////////////////////////////////////////////////

	db, err = dbxml.OpenRead(filename + "x")
	if err != nil {
		return
	}

	message2 = "HAS_DACTX"

	size2, err := db.Size()
	if err != nil || size2 != size {
		message2 = "OLD_DACTX"
		return
	}

	if !has_ud {
		return
	}

	docs, err = db.All()
	if err != nil {
		message2 = "OLD_DACTX"
		return
	}
	for docs.Next() {
		data := docs.Content()
		var alpino Alpino
		err := xml.Unmarshal([]byte(data), &alpino)
		if err != nil {
			message2 = "OLD_DACTX"
			return
		}
		if alpino.Conllu.Status != "" {
			has_ud = true
			if alpino.Conllu.Auto != version {
				message2 = "OLD_DACTX"
			}
		}
		docs.Close()
	}
	if docs.Error() != nil {
		message2 = "OLD_DACTX"
	}
	db.Close()

}
