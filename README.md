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


<br><br>
# Task 5.2 - prometheus bash web server on GCP GKE + Uptimerobot

- steps:

	- `gcloud beta interactive`
	- `gcloud config get-value project`
		- `gcloud config set project prometheus-407701`

	- create GCP repo if needed	
		- `gcloud services enable artifactregistry.googleapis.com`
		- `gcloud artifacts repositories create "prometheus-eu" --repository-format=docker --location="europe" --description="prometheus location=europe"`
		- `gcloud artifacts repositories list`
		- `gcloud artifacts packages list --repository prometheus-eu --location europe`
		- ? if needed: `gcloud auth configure-docker europe-docker.pkg.dev`
		- 

	- create and push image - use bash webserver `while|ncd`
		- multiplatform!
			- `docker buildx create --use --platform linux/386,linux/amd64,linux/arm64 --name multiplatform-builder2`
			- `docker buildx inspect --bootstrap`
			- `docker buildx build --platform linux/386,linux/amd64,linux/arm64 --tag europe-docker.pkg.dev/prometheus-407701/prometheus-eu/prometheus-bash-webserver-test:v1.0.0 --push .`
			- check: 
				- `gcloud artifacts tags list --package prometheus-bash-webserver-test --repository prometheus-eu --location europe`
			- test on gcp: 
				- `docker run -ti -p 8080:8080 europe-docker.pkg.dev/prometheus-407701/prometheus-eu/prometheus-bash-webserver-test:v0.0.11`
		
	- create cluster and run deployment:						
		- create cluster
			- `gcloud container clusters create prometheus-uptimerobot1 --machine-type=e2-small --num-nodes=2 --total-max-nodes=2 --max-nodes=2 --zone=europe-central2-a --disk-size=40GB`
			- `gcloud container clusters list`
		- prepare env 
			- `gcloud container clusters get-credentials prometheus-uptimerobot --zone=europe-central2-a` // set kubeconfig
			- `k get all -A` // check all is good
			- `k create ns prometheus-uptimerobot`
			- `k config set-context --current --namespace prometheus-uptimerobot` // switch context
		- test image 
			- `k run testuptimerobot1 --image=europe-docker.pkg.dev/prometheus-407701/prometheus-eu/prometheus-bash-webserver-test:v1.0.0`
		- create deployment:
			- `k create deploy app-v1 --image europe-docker.pkg.dev/prometheus-407701/prometheus-eu/prometheus-bash-webserver-test:v1.0.0` 
		- create service
			- `k expose deploy app-v1 --port 80 --type LoadBalancer --target-port 8080`
			- wait for external IP assigning
				- `k get svc -w` // wait for external IP
			- `LB=$(k get svc app-v1 -o jsonpath="{..ingress[0].ip}") && echo $LB && curl $LB`

	- in docker image change version and push new image
		- check new image is used by cluster
			- `while true; do curl $LB; sleep 0.3; done`			

		- update image
			- change version in Dockerfile
			- `docker buildx build --platform linux/386,linux/amd64,linux/arm64 --tag europe-docker.pkg.dev/prometheus-407701/prometheus-eu/prometheus-bash-webserver-test:v0.0.12 --push .`
			- `gcloud artifacts tags list --package prometheus-bash-webserver-test --repository prometheus-eu --location europe`
			- get pod name: 
				- `k get pod`
			- get container name: 
				- `echo $(kubectl get pods demo1-59567ff59f-mtttg -o jsonpath='{.spec.containers[*].name}')`
			- set new image for pod container
				- `k set image deployment/demo1 prometheus-bash-webserver-test=europe-docker.pkg.dev/prometheus-407701/prometheus-eu/prometheus-bash-webserver-test:v0.0.12`
				- `k annotate deployment/demo1 kubernetes.io/change-cause="update to v0.0.12" --overwrite=true`
			- check history
				- `k rollout history deployment/demo1`
			- rollback	
				- `k rollout undo deploy/demo1 --to-revision 1`
		
	- test labels
		- `k create deploy app-v2 --image europe-docker.pkg.dev/prometheus-407701/prometheus-eu/prometheus-bash-webserver-test:v2.0.0`
		- `k get po --show-labels`
		- `k get svc -o wide`
		- `k get po -l app=app-v1`
		- set label for all pods
			- `k label po --all run=demo1`
			- delete label if needed `k label po --all run-`
		- update service
			- `k edit svc`
				- change `app: demo1` to `run: demo`
				- see changes in `while true; do curl $LB; sleep 0.3; done`

	- emulate canary 
		- 1 = demo1=50%, demo2=50%
		
		- 2 = demo1=90%, demo2=10%
			- `k scale deploy app-v1 --replicas 9 && k get po -w --show-labels`
			- `k get po -Lapp,run`
			- `k label po --all run=demo`
			- `k get po -Lapp,run`
		- 3 = demo1=0%, demo2=100%
			- `k scale deploy demo1 --replicas 0 && k get po -w --show-labels`
			- `k get po -Lapp,run`

	- clean
		- `obs`
		- `gcloud container clusters list`
		






