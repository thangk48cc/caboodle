package main

import (
    "io"
//    "io/ioutil"
    "fmt"
//    "log"
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

func main() {
    http.HandleFunc("/", hello)
    http.HandleFunc("/login", login)
    http.ListenAndServe(":8000", nil)
}
