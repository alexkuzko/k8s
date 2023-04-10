ARG ALPINE_VERSION=3.16
FROM python:3.10.5-alpine${ALPINE_VERSION} as builder

# Ignore to update versions here (and after FROM alpine line below), example:
# docker build --no-cache --build-arg KUBECTL_VERSION=1.25.8 -t alexkuzko/k8s:1.25.8 -t alexkuzko/k8s:1.25 .
# to build AWS CDK based on Node LTS image:
# docker build --no-cache --build-arg KUBECTL_VERSION=1.25.8 -t alexkuzko/k8s-cdk:1.25.8 -t alexkuzko/k8s-cdk:1.25 -f Dockerfile.node .

ARG AWS_CLI_VERSION=2.9.1
ARG HELM_VERSION=3.10.2
ARG KUBECTL_VERSION=1.25.8
ARG KUSTOMIZE_VERSION=v4.5.7
ARG KUBESEAL_VERSION=0.19.2
# gcr.io/google.com/cloudsdktool/google-cloud-cli
ARG CLOUD_SDK_VERSION=423.0.0

# ========================
RUN apk add --no-cache git unzip groff build-base libffi-dev cmake
RUN git clone --single-branch --depth 1 -b ${AWS_CLI_VERSION} https://github.com/aws/aws-cli.git

WORKDIR aws-cli
RUN python -m venv venv
RUN . venv/bin/activate
RUN scripts/installers/make-exe
RUN unzip -q dist/awscli-exe.zip
RUN aws/install --bin-dir /aws-cli-bin
RUN /aws-cli-bin/aws --version

# reduce image size: remove autocomplete and examples
RUN rm -rf \
    /usr/local/aws-cli/v2/current/dist/aws_completer \
    /usr/local/aws-cli/v2/current/dist/awscli/data/ac.index \
    /usr/local/aws-cli/v2/current/dist/awscli/examples
RUN find /usr/local/aws-cli/v2/current/dist/awscli/data -name completions-1*.json -delete
RUN find /usr/local/aws-cli/v2/current/dist/awscli/botocore/data -name examples-1.json -delete
# ========================

FROM python:3.10.5-alpine${ALPINE_VERSION}

ARG HELM_VERSION=3.10.2
ARG KUBECTL_VERSION=1.25.8
ARG KUSTOMIZE_VERSION=v4.5.7
ARG KUBESEAL_VERSION=0.19.2
# gcr.io/google.com/cloudsdktool/google-cloud-cli
ARG CLOUD_SDK_VERSION=423.0.0

# Install helm (latest release)
# ENV BASE_URL="https://storage.googleapis.com/kubernetes-helm"
ENV BASE_URL="https://get.helm.sh"
ENV TAR_FILE="helm-v${HELM_VERSION}-linux-amd64.tar.gz"
RUN apk add --update --no-cache curl ca-certificates bash git && \
    curl -sL ${BASE_URL}/${TAR_FILE} | tar -xvz && \
    mv linux-amd64/helm /usr/bin/helm && \
    chmod +x /usr/bin/helm && \
    rm -rf linux-amd64

# add helm-diff
RUN helm plugin install https://github.com/databus23/helm-diff && rm -rf /tmp/helm-*

# add helm-unittest
RUN helm plugin install https://github.com/quintush/helm-unittest && rm -rf /tmp/helm-*

# add helm-push
RUN helm plugin install https://github.com/chartmuseum/helm-push && rm -rf /tmp/helm-*

# Install kubectl (same version of aws esk)
RUN curl -sLO https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
    mv kubectl /usr/bin/kubectl && \
    chmod +x /usr/bin/kubectl

# Install kustomize (latest release)
RUN curl -sLO https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz && \
    tar xvzf kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz && \
    mv kustomize /usr/bin/kustomize && \
    chmod +x /usr/bin/kustomize

# Install eksctl (latest version)
RUN curl -sL "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp && \
    mv /tmp/eksctl /usr/bin && \
    chmod +x /usr/bin/eksctl

# copy compiled awscli v2
COPY --from=builder /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=builder /aws-cli-bin/ /usr/local/bin/

# Install jq
RUN apk add --update --no-cache jq yq

# Install for envsubst
RUN apk add --update --no-cache gettext

# Install kubeseal
RUN curl -L https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz -o - | tar xz -C /usr/bin/ && \
    chmod +x /usr/bin/kubeseal

# Install gcloud
RUN curl --silent --fail --show-error -L -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
    mkdir -p /google && \
    tar xzf google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz -C /google && \
    rm -f google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
    /google/google-cloud-sdk/bin/gcloud config set core/disable_usage_reporting true && \
    /google/google-cloud-sdk/bin/gcloud config set component_manager/disable_update_check true && \
    /google/google-cloud-sdk/bin/gcloud components install --quiet gke-gcloud-auth-plugin

# Needed to use new GKE auth mechanism for kubeconfig
ENV USE_GKE_GCLOUD_AUTH_PLUGIN=True

# Final PATH environment variable
ENV PATH="/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/google/google-cloud-sdk/bin"

ENTRYPOINT ["/bin/ash", "-c"]
