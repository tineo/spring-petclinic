#!/usr/bin/env groovy
pipeline {
    environment {
        registry = "tineodevops/petclinic"
        registryCredential = 'dockerhub'
        dockerImage = ''
    }
    agent {
        label 'maven'
    }
    stages {
        stage('Build') {
            steps {
                sh 'mvn -B -DskipTests clean package'
            }
        }
        stage('Test') {
            steps {
                sh 'mvn test'
            }
        }
        stage('Building image') {
            steps {
                script {
                    dockerImage = docker.build registry + ":$BUILD_NUMBER"
                }
            }
        }
        stage('Deploy Image') {
            steps {
                script {
                    docker.withRegistry('', registryCredential) {
                        dockerImage.push()
                    }
                }
            }
        }
        stage('Install from Registry') {
            steps {

                sshagent(credentials: ['devops_pem']) {
                    sh "ssh -vvv -o StrictHostKeyChecking=no -T \
                         ubuntu@${AWS_INSTANCE} \
                         'docker ps -f name=petclinic -q | xargs --no-run-if-empty docker container stop; \
                         docker container ls -a -fname=petclinic -q | xargs -r docker container rm'"
                }

                sshagent(credentials: ['devops_pem']) {
                    sh "ssh -vvv -o StrictHostKeyChecking=no -T \
                         ubuntu@${AWS_INSTANCE} \
                         'docker pull tineodevops/petclinic:$BUILD_NUMBER'"

                }
            }
        }


        stage('Starting Docker image on AWS') {
            steps {
                script {
                    sshagent(credentials: ['devops_pem']) {
                        sh "ssh -vvv -o StrictHostKeyChecking=no -T \
                              ubuntu@${AWS_INSTANCE} \
                              'docker run -d --rm -ti -p 8080:8080 --name petclinic tineodevops/petclinic:$BUILD_NUMBER'"
                    }

                }
            }
        }
        stage('Functional Test with JMeter') {
            steps {
                sh "while ! httping -qc1 \
                http://${AWS_INSTANCE}:8080 ; do sleep 1 ; done"

                sh "jmeter -Jjmeter.save.saveservice.output_format=xml \
                -n -t src/test/jmeter/petclinic_test_plan.jmx \
                -l src/test/jmeter/petclinic_test_plan.jtl"

                perfReport 'src/test/jmeter/petclinic_test_plan.jtl'
                step([$class: 'ArtifactArchiver', artifacts: '**/*.jtl'])
            }
        }
    }
}
