// pipelines/Jenkinsfile-webserver-single
// Pipeline para deploy de uma EC2 com WebServer Apache

pipeline {
    // AQUI ESTÁ A MÁGICA: Usamos o label que configuramos no Jenkins (que aponta para o Harbor)
    agent { label 'terraform' } 

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
        // Define o diretório de trabalho do terraform para evitar repetição do dir()
        TF_ROOT               = 'environments/webserver-single'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
        ansiColor('xterm')
        timeout(time: 30, unit: 'MINUTES')
    }

    stages {
        stage('Checkout & Version') {
            steps {
                checkout scm
                sh 'terraform --version'
                // Opcional: Validar se o AWS CLI está na imagem
                sh 'aws --version || echo "AWS CLI não encontrado na imagem, mas Terraform funcionará via env vars"'
            }
        }

        stage('AWS Credentials Check') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', 
                                  credentialsId: 'aws-credentials',
                                  accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                                  secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
                    sh '''
                        echo "Verificando credenciais AWS..."
                        # Este comando só funciona se sua imagem tiver AWS CLI instalado.
                        # Se não tiver, o Terraform ainda funcionará, mas este check falhará.
                        aws sts get-caller-identity || echo "Aviso: AWS CLI falhou, ignorando checagem..."
                        echo "Região alvo: ${TF_VAR_aws_region}"
                    '''
                }
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', 
                                  credentialsId: 'aws-credentials',
                                  accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                                  secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
                    dir("${TF_ROOT}") {
                        sh '''
                            echo "=== Terraform Init ==="
                            terraform init -upgrade
                        '''
                    }
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                dir("${TF_ROOT}") {
                    sh '''
                        echo "=== Terraform Validate ==="
                        terraform validate
                        terraform fmt -check -recursive || true
                    '''
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', 
                                  credentialsId: 'aws-credentials',
                                  accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                                  secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
                    dir("${TF_ROOT}") {
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
                // Input fora do node/agent para não ocupar o executor enquanto espera
                // Porém, como definimos agent global, ele vai pausar o container.
                // Isso é aceitável na maioria dos casos.
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
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', 
                                  credentialsId: 'aws-credentials',
                                  accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                                  secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
                    dir("${TF_ROOT}") {
                        sh '''
                            echo "=== Terraform Apply ==="
                            terraform apply -auto-approve tfplan
                            
                            echo ""
                            echo "=========================================="
                            echo "        INFRAESTRUTURA CRIADA           "
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
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', 
                                  credentialsId: 'aws-credentials',
                                  accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                                  secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
                    dir("${TF_ROOT}") {
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
        success {
            echo "Pipeline executado com sucesso usando imagem customizada!"
        }
        failure {
            echo "Pipeline falhou!"
        }
    }
}