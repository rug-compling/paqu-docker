package main

//. Imports

import (
	"github.com/BurntSushi/toml"
	_ "github.com/go-sql-driver/mysql"
	"github.com/pebbe/util"

	"bytes"
	"database/sql"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"time"
)

//. Types

type Config struct {
	Login string
}

var (
	Cfg Config
)

//. Main

func main() {
	paqudir := os.Getenv("PAQU")
	_, err := TomlDecodeFile(filepath.Join(paqudir, "setup.toml"), &Cfg)
	util.CheckErr(err)

	if Cfg.Login[0] == '$' {
		Cfg.Login = os.Getenv(Cfg.Login[1:])
	}

	var db *sql.DB
	for i := 0; i < 60; i++ {
		db, err = dbopen()
		if err == nil {
			err = db.Ping()
			db.Close()
			if err == nil {
				return
			}
		}
		time.Sleep(time.Second)
	}
	log.Fatalln(err)
}

func dbopen() (*sql.DB, error) {
	return sql.Open("mysql", Cfg.Login+"?charset=utf8&parseTime=true&loc=Europe%2FAmsterdam&sql_mode=''")
}

func TomlDecodeFile(fpath string, v interface{}) (toml.MetaData, error) {
	bs, err := ioutil.ReadFile(fpath)
	if err != nil {
		return toml.MetaData{}, err
	}
	// skip BOM (berucht op Windows)
	if bytes.HasPrefix(bs, []byte{239, 187, 191}) {
		bs = bs[3:]
	}
	return toml.Decode(string(bs), v)
}
