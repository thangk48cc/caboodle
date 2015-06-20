package main

import (
    "io"
    "fmt"
    "net/http"
    "encoding/json"
)

func hello(w http.ResponseWriter, r *http.Request) {
    io.WriteString(w, "Hello world!")
}

type Credential struct {
    Username string
    Password string
}

type Session struct {
    Session string
}

type Contact struct {
    Displayname string
    Username string
}

type Roster struct {
    Contacts []Contact
}

func login(res http.ResponseWriter, req *http.Request) {
    if req.Method == "POST" {
        cred := Credential{}
        err := json.NewDecoder(req.Body).Decode(&cred)
        if err != nil {
            panic("can't decode")
        }
        fmt.Println("credentials: " + cred.Username + " , " + cred.Password)
        
        if cred.Username == "x" && cred.Password == "y" {

            res.WriteHeader(200)
            res.Header().Set("Content-Type", "application/json")
    
            session := Session{"123456"}    
            js, err := json.Marshal(session)
            if err != nil {
              http.Error(res, err.Error(), http.StatusInternalServerError)
              return
            }
            //fmt.Println("js = " + js)
            res.Write(js)
    
        } else {
            res.WriteHeader(401)
        }
    }
}

func roster(res http.ResponseWriter, req *http.Request) {
    if req.Method == "GET" {

        fmt.Println("roster")

        res.WriteHeader(200)
        res.Header().Set("Content-Type", "application/json")
    
        //names := []Contact{{"Superman", "superguy"}, {"Batman","bruce"}, {"Aquaman","alex"}}
        names := Roster{ []Contact{{"Superman","Clark"},{"Batman","Bruce"},{"Aquaman","Alex"}}}
        js, err := json.Marshal(names)
        if err != nil {
          http.Error(res, err.Error(), http.StatusInternalServerError)
          return
        }
        res.Write(js)
    }
}

func main() {
    http.HandleFunc("/", hello)
    http.HandleFunc("/login", login)
    http.HandleFunc("/roster", roster)
    http.ListenAndServe(":8000", nil)
}
