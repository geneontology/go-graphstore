# Build And Push Images

Clone the repo. 

```sh
# Example: Build and  push to dockerhub geneontology repo.
# Choose appropriate tag if planning to push dockerhub geneontology repo.

cd docker 
docker build -f ./Dockerfile -t geneontology/go-graphstore:some_tage ..
docker push geneontology/go-graphstore:some_tag

docker build -f ./Dockerfile.proxy -t geneontology/apache-proxy:some_tag . 
docker push geneontology/apache-proxy:some_tag
```
