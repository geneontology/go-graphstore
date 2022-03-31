# Build And Push Image

Clone the repo. 

```sh
# Example: Build and push to dockerhub geneontology repo.
# Choose appropriate tag if planning to push dockerhub geneontology repo.

docker build -f docker/Dockerfile -t geneontology/go-graphstore:some_tage .
docker push geneontology/go-graphstore:some_tag
```
