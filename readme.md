# https proxy

code needs to be refactored, so please ignore that. Proxy receives http request , 
create new and sends to target. The same with response. Trick is that pair request:response    
 is done within standalone thread. `doneCh` says when https handler finish and it is set when 
 thread finish its job.
 
   
# running locally

find `generate_cert` within go standard libs and run:
```
go run ./generate_cert.go --host localhost  
```

upload output into `/etc/lb/certs/key.pem`, `/etc/lb/certs/cert.pem`  

finally run `go run main.go -port 9443 -url ulozto.cz`

# deployment

 installing namespace and certificates
 ```
./init.sh
 ```

installing app
```
./buils.sh cicd v0.12
 ```


Setup public DNS name to just installed service


open browser and run 

```
https://uuu.onho.cz/
```