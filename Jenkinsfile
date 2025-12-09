// pipelines/Jenkinsfile-webserver-single
// Pipeline para deploy de uma EC2 com WebServer Apache

pipeline {
    agent none

    parameters {
        choice(
            name: 'ACTION',
            choices: ['plan', 'apply', 'destroy'],
            description: 'Ação do Terraform a executar'
        )
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'staging', 'production'],
            description: 'Ambiente de deploy'
        )
        string(
            name: 'AWS_REGION',
            defaultValue: 'us-east-1',
            description: 'Região AWS'
        )
        choice(
            name: 'SERVER_COLOR',
            choices: ['blue', 'green', 'red', 'yellow'],
            description: 'Cor do servidor'
        )
        string(
            name: 'INSTANCE_TYPE',
            defaultValue: 't2.micro',
            description: 'Tipo da instância EC2'
        )
        string(
            name: 'KEY_NAME',
            defaultValue: '',
            description: 'Nome do Key Pair para SSH (opcional)'
        )
    }

    environment {
        TF_VAR_aws_region     = "${params.AWS_REGION}"
        TF_VAR_environment    = "${params.ENVIRONMENT}"
        TF_VAR_server_color   = "${params.SERVER_COLOR}"
        TF_VAR_instance_type  = "${params.INSTANCE_TYPE}"
        TF_VAR_key_name       = "${params.KEY_NAME}"
        TF_IN_AUTOMATION      = 'true'
        TF_INPUT              = 'false'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
        ansiColor('xterm')
        timeout(time: 30, unit: 'MINUTES')
    }

    stages {
        stage('Checkout') {
            agent {
                docker {
                    image 'hashicorp/terraform:1.6'
                    args '-u root --entrypoint=""'
                }
            }
            steps {
                checkout scm
                sh 'terraform --version'
            }
        }

        stage('AWS Credentials Check') {
            agent {
                docker {
                    image 'amazon/aws-cli:latest'
                    args '-u root --entrypoint=""'
                }
            }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', 
                                  credentialsId: 'aws-credentials',
                                  accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                                  secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
                    sh '''
                        echo "Verificando credenciais AWS..."
                        aws sts get-caller-identity
                        echo "Região: ${TF_VAR_aws_region}"
                    '''
                }
            }
        }

        stage('Terraform Init') {
            agent {
                docker {
                    image 'hashicorp/terraform:1.6'
                    args '-u root --entrypoint=""'
                }
            }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', 
                                  credentialsId: 'aws-credentials',
                                  accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                                  secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
                    dir('environments/webserver-single') {
                        sh '''
                            echo "=== Terraform Init ==="
                            terraform init -upgrade
                        '''
                    }
                }
            }
        }

        stage('Terraform Validate') {
            agent {
                docker {
                    image 'hashicorp/terraform:1.6'
                    args '-u root --entrypoint=""'
                }
            }
            steps {
                dir('environments/webserver-single') {
                    sh '''
                        echo "=== Terraform Validate ==="
                        terraform validate
                        terraform fmt -check -recursive || true
                    '''
                }
            }
        }

        stage('Terraform Plan') {
            agent {
                docker {
                    image 'hashicorp/terraform:1.6'
                    args '-u root --entrypoint=""'
                }
            }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', 
                                  credentialsId: 'aws-credentials',
                                  accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                                  secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
                    dir('environments/webserver-single') {
                        sh '''
                            echo "=== Terraform Plan ==="
                            terraform plan -out=tfplan
                        '''
                    }
                }
            }
        }

        stage('Approval') {
            when {
                expression { params.ACTION == 'apply' || params.ACTION == 'destroy' }
            }
            steps {
                script {
                    def action = params.ACTION == 'destroy' ? 'DESTRUIR' : 'APLICAR'
                    input message: "Deseja ${action} a infraestrutura no ambiente ${params.ENVIRONMENT}?",
                          ok: "Sim, ${action}!"
                }
            }
        }

        stage('Terraform Apply') {
            when {
                expression { params.ACTION == 'apply' }
            }
            agent {
                docker {
                    image 'hashicorp/terraform:1.6'
                    args '-u root --entrypoint=""'
                }
            }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', 
                                  credentialsId: 'aws-credentials',
                                  accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                                  secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
                    dir('environments/webserver-single') {
                        sh '''
                            echo "=== Terraform Apply ==="
                            terraform apply -auto-approve tfplan
                            
                            echo ""
                            echo "=========================================="
                            echo "         INFRAESTRUTURA CRIADA           "
                            echo "=========================================="
                            terraform output
                        '''
                    }
                }
            }
        }

        stage('Terraform Destroy') {
            when {
                expression { params.ACTION == 'destroy' }
            }
            agent {
                docker {
                    image 'hashicorp/terraform:1.6'
                    args '-u root --entrypoint=""'
                }
            }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', 
                                  credentialsId: 'aws-credentials',
                                  accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                                  secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
                    dir('environments/webserver-single') {
                        sh '''
                            echo "=== Terraform Destroy ==="
                            terraform destroy -auto-approve
                            
                            echo ""
                            echo "=========================================="
                            echo "       INFRAESTRUTURA DESTRUÍDA          "
                            echo "=========================================="
                        '''
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        success {
            echo "Pipeline executado com sucesso!"
        }
        failure {
            echo "Pipeline falhou!"
        }
    }
}
