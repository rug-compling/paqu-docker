package main

//. Imports

import (
	"github.com/BurntSushi/toml"
	_ "github.com/go-sql-driver/mysql"
	"github.com/pebbe/util"

	"database/sql"
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
	_, err := toml.DecodeFile(filepath.Join(paqudir, "setup.toml"), &Cfg)
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
