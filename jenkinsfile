pipeline {
    agent any
    stages {
        stage ('build') {
            steps {
                sh '''
                whoami
                aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 590183962065.dkr.ecr.us-east-1.amazonaws.com
                docker build -t kubernetes_project .
                docker tag kubernetes_project:latest 590183962065.dkr.ecr.us-east-1.amazonaws.com/kubernetes_project:${BUILD_NUMBER}
                docker push 590183962065.dkr.ecr.us-east-1.amazonaws.com/kubernetes_project:${BUILD_NUMBER}
                '''
            }

        }
        stage ('deploy'){
            steps {
                sh '''
                sed "s/xyz/${BUILD_NUMBER}/g" K8/deployment.yaml > deployment-new.yaml
                /var/lib/jenkins/kubectl apply -f deployment-new.yaml
                /var/lib/jenkins/kubectl apply -f K8/service.yaml
                '''
            }

        }
    }
}
