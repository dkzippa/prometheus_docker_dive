# Implement DIVE in pipleine                                                                                               

https://asciinema.org/a/CtoOcDP9dnddwXkeEb9SuMHKV

### Info:
- it is the simple local example:)                                                                                         
- example uses local git repo intentionally                                                                                
- example uses local docker img intentionally                                                                              
- pipline emulated with post-commit hook                                                                                   
                                                                                                                           
                                                                                                                           
### Steps:                                                                                                                   
- install dive     


- create git repo                                                                                                          
- add post-commit hook                                                                                                     
    - get commit message, get img tag from substring `docker-img:...`                                                  
    - use dive for ci with settings `dive --ci --lowestEfficiency=0.9`                                                 
	- touch .git/hooks/post-commit
	- vi .git/hooks/post-commit
		-`dive --ci --lowestEfficiency=0.9 $(git log --oneline -n 1 | awk -F "docker-img:" '{print $2}')`
	- chmod +x .git/hooks/post-commit


- create Dockerfile                                            
	- add bash webserver `CMD while true; do { echo -e 'HTTP/1.1 200 OK\n\n Version: 1.0';} | nc -vlp 8080; done`                                                            
- build docker img                                                                                                         
- test docker img by running container + using curl                                                                        
- tag docker img with test tag, for this example - `dkzippa/prometheus-img-vX.X.X`                                         
- commit files with message "..., docker-img:<docker img tag>"                                                             
- check git 'pipeline' results                                                                                             
- here we go;) 

