package main

import (
    "io"
    "fmt"
    "reflect"
    "net/http"
    "encoding/json"
    "appengine"
    "appengine/datastore"
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

type Entity struct {
    Value string
}

func db(w http.ResponseWriter, r *http.Request) {

    w.Header().Set("Content-Type", "text/plain; charset=utf-8")
    c := appengine.NewContext(r)

    k := datastore.NewKey(c, "Entity", "stringID", 0, nil)
    //e := new(Entity)
    e := Entity{"ytitne"}    

    if _, err := datastore.Put(c, k, &e); err != nil {
        fmt.Fprint(w, "A")
        http.Error(w, err.Error(), 500)
        return
    }

    if err := datastore.Get(c, k, &e); err != nil {
        fmt.Fprint(w, "B")
        http.Error(w, err.Error(), 500)
        return
    }

    old := e.Value
    e.Value = r.URL.Path

    if _, err := datastore.Put(c, k, &e); err != nil {
        fmt.Fprint(w, "C")
        http.Error(w, err.Error(), 500)
        return
    }

    fmt.Fprintf(w, "old=%q\nnew=%q\n", old, e.Value)
}

func registerSave(cred Credential, req *http.Request) (Credential, error) {

    c := appengine.NewContext(req)
    k := datastore.NewKey(c, "Credential", cred.Username, 0, nil)

    _, err := datastore.Put(c, k, &cred)
    return cred, err
}

func loginCheck(cred Credential, req *http.Request) (Credential, error) {

    c := appengine.NewContext(req)
    k := datastore.NewKey(c, "Credential", cred.Username, 0, nil)
    storedCred := Credential{}

    err := datastore.Get(c, k, &storedCred)
    return storedCred, err
}

func register(res http.ResponseWriter, req *http.Request) {
    if req.Method == "POST" {
        cred := Credential{}
        err := json.NewDecoder(req.Body).Decode(&cred)
        if err != nil {
            panic("can't decode")
        }

        if _, err := registerSave(cred, req); err != nil {
            fmt.Fprint(res, "C")
            http.Error(res, err.Error(), 500)
            return
        }

        //fmt.Println("credentials: " + cred2.Username + " , " + cred2.Password)
        createSession(res, cred.Username)
    }
}

func createSession(res http.ResponseWriter, username string) {
    res.WriteHeader(200)
    res.Header().Set("Content-Type", "application/json")

    session := Session{"123456"}    
    js, err := json.Marshal(session)
    if err != nil {
      http.Error(res, err.Error(), http.StatusInternalServerError)
      return
    }
    res.Write(js)
}

func login(res http.ResponseWriter, req *http.Request) {
    if req.Method == "POST" {
        cred := Credential{}
        err := json.NewDecoder(req.Body).Decode(&cred)
        if err != nil {
            panic("can't decode")
        }
        fmt.Println("credentials: " + cred.Username + " , " + cred.Password)
        
        //if cred.Username == "x" && cred.Password == "y" {
        if storedCred, err := loginCheck(cred, req); err != nil {
            http.Error(res, err.Error(), 500)
        } else if (reflect.DeepEqual(cred, storedCred)) {

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

func init() {
    http.HandleFunc("/", hello)
    http.HandleFunc("/register", register)
    http.HandleFunc("/login", login)
    http.HandleFunc("/roster", roster)
    http.HandleFunc("/db", db)
}

