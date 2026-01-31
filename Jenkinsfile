pipeline {
    agent any
    
    triggers {
        githubPush()
    }

    environment {
        AWS_ACCOUNT_ID = "966137697484"
        REGION = "ap-south-1"
        ECR_URL = "${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
        BRANCH_NAME = "${env.BRANCH_NAME}"
        BUILD_NUMBER = "${env.BUILD_NUMBER}"
        IMAGE_TAG = "${BRANCH_NAME}-flight-servicce-v.1.${BUILD_NUMBER}"
        DEV_IMAGE_TAG = "dev-flight-servicce-v.1.${BUILD_NUMBER}"
        PREPROD_IMAGE_TAG = "preprod-flight-servicce-v.1.${BUILD_NUMBER}"
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '5', artifactNumToKeepStr: '5'))
    }

    tools {
        maven 'maven_3.8.4'
    }

    stages {
        stage('Initialize') {
            steps {
                echo "Starting Pipeline for branch: ${env.BRANCH_NAME}"
                echo "Build Number: ${env.BUILD_NUMBER}"
            }
        }

        stage('Build and Test for Dev') {
            when { branch 'dev' }
            stages {
                stage('Code Compilation') {
                    steps {
                        echo 'Code Compilation in Progress!'
                        sh 'mvn clean compile'
                    }
                }
                stage('Code QA Execution') {
                    steps {
                        echo 'JUnit Test Execution in Progress!'
                        sh 'mvn clean test'
                    }
                }
                stage('Code Package') {
                    steps {
                        echo 'Packaging Code into WAR Artifact'
                        sh 'mvn clean package'
                    }
                }
                stage('Build & Tag Docker Image') {
                    steps {
                        echo "Building Docker Image: ${ECR_URL}/flight-servicce:${DEV_IMAGE_TAG}"
                        sh "docker build -t ${ECR_URL}/flight-servicce:${DEV_IMAGE_TAG} ."
                    }
                }
                stage('Push Docker Image to Amazon ECR') {
                    steps {
                        withDockerRegistry([credentialsId: 'ecr:ap-south-1:ecr-credentials', url: "https://${ECR_URL}"]) {
                            sh "docker push ${ECR_URL}/flight-servicce:${DEV_IMAGE_TAG}"
                        }
                    }
                }
            }
        }

        stage('Tag Docker Image for Preprod and Prod') {
            when {
                anyOf {
                    branch 'preprod'
                    branch 'prod'
                }
            }
            steps {
                script {
                    def targetTag = (BRANCH_NAME == 'preprod') ? PREPROD_IMAGE_TAG : "prod-flight-servicce-v.1.${BUILD_NUMBER}"
                    def sourceTag = (BRANCH_NAME == 'preprod') ? DEV_IMAGE_TAG : PREPROD_IMAGE_TAG
                    def sourceImage = "${ECR_URL}/flight-servicce:${sourceTag}"
                    def targetImage = "${ECR_URL}/flight-servicce:${targetTag}"

                    withDockerRegistry([credentialsId: 'ecr:ap-south-1:ecr-credentials', url: "https://${ECR_URL}"]) {
                        sh "docker pull ${sourceImage}"
                        sh "docker tag ${sourceImage} ${targetImage}"
                        sh "docker push ${targetImage}"
                    }
                    sh "docker rmi ${sourceImage} ${targetImage} || true"
                }
            }
        }

        stage('Deploy to Dev') {
            when { branch 'dev' }
            steps {
                script {
                    sh "sed -i 's|<latest>|${DEV_IMAGE_TAG}|g' kubernetes/dev/05-deployment.yaml"
                    sh "kubectl --kubeconfig=/var/lib/jenkins/.kube/config apply -f kubernetes/dev/"
                }
            }
        }

        stage('Deploy to Preprod') {
            when { branch 'preprod' }
            steps {
                script {
                    sh "sed -i 's|<latest>|${PREPROD_IMAGE_TAG}|g' kubernetes/preprod/05-deployment.yaml"
                    sh "kubectl --kubeconfig=/var/lib/jenkins/.kube/config apply -f kubernetes/preprod/"
                }
            }
        }

        stage('Deploy to Prod') {
            when { branch 'prod' }
            steps {
                script {
                    def prodTag = "prod-flight-servicce-v.1.${BUILD_NUMBER}"
                    sh "sed -i 's|<latest>|${prodTag}|g' kubernetes/prod/05-deployment.yaml"
                    sh "kubectl --kubeconfig=/var/lib/jenkins/.kube/config apply -f kubernetes/prod/"
                }
            }
        }
    }

    post {
        success {
            echo "Deployment to ${env.BRANCH_NAME} completed successfully"
        }
        failure {
            echo "Deployment failed. Check logs."
        }
    }
}
