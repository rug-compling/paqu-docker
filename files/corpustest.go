package main

//. Imports

import (
	"github.com/BurntSushi/toml"
	_ "github.com/go-sql-driver/mysql"
	"github.com/pebbe/util"

	"database/sql"
	"fmt"
	"os"
	"path/filepath"
)

//. Types

type Config struct {
	Login  string
	Prefix string
}

var (
	Cfg Config
)

//. Main

func main() {
	paqudir := os.Getenv("PAQU")
	_, err := toml.DecodeFile(filepath.Join(paqudir, "setup.toml"), &Cfg)
	util.CheckErr(err)

	db, err := dbopen()
	util.CheckErr(err)
	defer db.Close()

	rows, err := db.Query(
		fmt.Sprintf(
			"SELECT 1 FROM `%s_info` WHERE `id` = %q AND `status` = \"FINISHED\"",
			Cfg.Prefix, os.Args[1]))
	util.CheckErr(err)

	for rows.Next() {
		rows.Close()
		fmt.Println("ok")
		return
	}
}

func dbopen() (*sql.DB, error) {
	if Cfg.Login[0] == '$' {
		Cfg.Login = os.Getenv(Cfg.Login[1:])
	}
	return sql.Open("mysql", Cfg.Login+"?charset=utf8&parseTime=true&loc=Europe%2FAmsterdam&sql_mode=''")
}
