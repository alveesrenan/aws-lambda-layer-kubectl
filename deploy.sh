#!/bin/bash
check_status() {
    if [ $1 != 0 ]; then
        echo
        echo $2
        exit $1
    fi
}
DOCKER_REPOSITORY=renaalve
IMAGE_NAME=aws-lambda-layer-kubectl
IMAGE_TAG=latest
AWS_REGION=us-east-1

case $1 in
    'build-layer')
        docker build -f Dockerfile -t ${DOCKER_REPOSITORY}/${IMAGE_NAME}:${IMAGE_TAG} .
        check_status $? 'An error occurred when generating docker image.'

        docker cp $(docker run -d ${DOCKER_REPOSITORY}/${IMAGE_NAME}:${IMAGE_TAG}):/root/lambda-layer.zip .
        check_status $? 'An error occurred when getting lambda-layer.zip file.'

        ;;
    'deploy-layer')
        S3_BUCKET=etp-k8s-eks-kubectl-layer
        STACK_NAME=etp-k8s-eks-kubectl-layer

        sam package --template-file ./template-layer.yaml --output-template-file ./output-layer.yaml --s3-bucket ${S3_BUCKET}
        check_status $? 'An error occurred when packing sam layer template.'

        sam deploy --template-file ./output-layer.yaml --stack-name ${STACK_NAME} --region ${AWS_REGION} --capabilities CAPABILITY_IAM
        check_status $? 'An error occurred when deploying sam layer stack.'
        
        ;;
    'deploy-lambda')
        S3_BUCKET=etp-k8s-eks-kubectl
        STACK_NAME=etp-k8s-eks-kubectl
        
        sam package --template-file ./template.yaml --output-template-file ./output-lambda.yaml --s3-bucket ${S3_BUCKET}
        check_status $? 'An error occurred when packing layer template.'

        # YOU MUST REPLACE LAMBDA_LAYER_ARN TO YOUR LAMBDA LAYER ARN
        sam deploy --template-file ./output-lambda.yaml --stack-name ${STACK_NAME} --region ${AWS_REGION} \
            --parameter-overrides LambdaLayerARN=#LAMBDA_LAYER_ARN \
            --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM
        check_status $? 'An error occurred when deploying lambda layer stack.'

        ;;
    *)
        echo "Invalid!" 
        ;;
esac