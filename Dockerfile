FROM amazonlinux:latest as builder

WORKDIR /root

ENV HELM_VERSION=v2.16.3
ENV KUBECTL_VERSION=1.15.10

# updating and installing awscli, kubectl, helm and jq.
RUN yum update -y && yum install -y unzip make wget tar gzip \
    && curl -L -o awscli-bundle.zip https://s3.amazonaws.com/aws-cli/awscli-bundle.zip \
    && unzip awscli-bundle.zip && ./awscli-bundle/install -i /opt/awscli -b /opt/awscli/aws && rm awscli-bundle.zip \
    && curl -L -o /opt/kubectl/kubectl --create-dirs https://amazon-eks.s3.us-west-2.amazonaws.com/${KUBECTL_VERSION}/2020-02-22/bin/linux/amd64/kubectl \
    && chmod +x /opt/kubectl/kubectl \
    && curl -L -o helm-v2.16.3-linux-amd64.tar.gz https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz \
    && tar -xvzf helm-v2.16.3-linux-amd64.tar.gz && mkdir -p /opt/helm && mv ./linux-amd64/* /opt/helm/ && rm helm-v2.16.3-linux-amd64.tar.gz \
    && wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 \
    && mv jq-linux64 /opt/awscli/jq && chmod +x /opt/awscli/jq \
    && rm -rf awscli-bundle linux-amd64

# Mouting runtime for lambda.
FROM lambci/lambda:provided as runtime

USER root

RUN yum install -y zip

# Copy awscli, kubectl and helm.
COPY --from=builder /opt/awscli/lib/python2.7/site-packages/ /opt/awscli/ 
COPY --from=builder /opt/awscli/bin/ /opt/awscli/bin/ 
COPY --from=builder /opt/awscli/bin/aws /opt/awscli/aws
COPY --from=builder /opt/awscli/jq /opt/awscli/jq
COPY --from=builder /opt/kubectl/kubectl /opt/kubectl/kubectl
COPY --from=builder /opt/helm/helm /opt/helm/helm

# Remove unnecessary files to reduce the size and zipping /opt for lambda layer environment.
RUN rm -rf /opt/awscli/pip* /opt/awscli/setuptools* /opt/awscli/awscli/examples \
    && cd /opt &&  zip -r /root/lambda-layer.zip ./*