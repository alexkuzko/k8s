# All-In-One Kubernetes tools (kubectl, helm, iam-authenticator, eksctl, kubeseal, etc)

kubernetes docker images with necessary tools 

### Notes

(1) For AWS EKS users, not all versions are supported yet. [AWS EKS](https://aws.amazon.com/eks) maintains [special kubernetes versions](https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html) to its managed service. Do remember to choice the proper version for EKS only.

(2) There is no `latest` tag for this image

(3) If you need more tools to be added, raise tickets in issues.

### Installed tools

- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) (latest minor versions: https://kubernetes.io/releases/)
- [kustomize](https://github.com/kubernetes-sigs/kustomize) (latest release: https://github.com/kubernetes-sigs/kustomize/releases/latest)
- [helm](https://github.com/helm/helm) (latest release: https://github.com/helm/helm/releases/latest)
- [helm-diff](https://github.com/databus23/helm-diff) (latest commit)
- [helm-unittest](https://github.com/quintush/helm-unittest) (latest commit)
- [helm-push](https://github.com/chartmuseum/helm-push) (latest commit)
- [aws-iam-authenticator](https://github.com/kubernetes-sigs/aws-iam-authenticator) (latest version when run the build)
- [eksctl](https://github.com/weaveworks/eksctl) (latest version when run the build)
- [awscliv1](https://github.com/aws/aws-cli) (latest version when run the build)
- [awscliv2](https://github.com/aws/aws-cli) (v2.1.39)
- [kubeseal](https://github.com/bitnami-labs/sealed-secrets) (latest version when run the build)
- General tools, such as bash, curl, jq, yq, etc

### Github Repo

https://github.com/alpine-docker/k8s

### build logs

https://app.circleci.com/pipelines/github/alpine-docker/k8s

### Docker image tags

https://hub.docker.com/r/alpine/k8s/tags/

# Quick start
Set environmental variable `awscli` to `v2` to use awscliv2 by default, otherwise awscliv1 is used.

To pass an environmental variable to a docker image use the `-e` option:

```
docker -e awscli=v2 ...
```

# Why we need it

Mostly it is used during CI/CD (continuous integration and continuous delivery) or as part of an automated build/deployment

# kubectl versions

You should check in [kubernetes versions](https://kubernetes.io/releases/), it lists the kubectl latest minor versions and used as image tags.

# Involve with developing and testing

If you want to build these images by yourself, please follow below commands.

```
export REBUILD=true
# comment the line in file "build.sh" to stop image push:  docker push ${image}:${tag}
bash ./build.sh
```

### Weekly build

Automation build job runs weekly by Circle CI Pipeline.
