podTemplate(label: 'docker-build',
    containers: [
        containerTemplate(
            name: 'git',
            image: 'alpine/git',
            command: 'cat',
            ttyEnabled: true
        ),
        containerTemplate(
            name: 'docker',
            image: 'docker',
            command: 'cat',
            ttyEnabled: true
        ),
        containerTemplate(
            name: 'argo',
            image: 'argoproj/argo-cd-ci-builder:latest',
            command: 'cat',
            ttyEnabled: true
        ),
    ],

    volumes: [
        hostPathVolume(mountPath: '/var/run/docker.sock', hostPath: '/var/run/docker.sock'),
    ]
) {
    node('docker-build') {
        def appImage

        stage('Checkout'){
            container('git'){
                checkout scm
            }
        }

        stage('Build'){
            container('docker'){
                script {
                    appImage = docker.build("tntjd5596/spring-petclinic-data-jdbc-cicd")
                }
            }
        }


        stage('Test'){
            container('docker'){
                script {
                    appImage.inside {
                        echo 'Skip Test'
                    }
                }
            }
        }

        stage('Push'){
            container('docker'){
                script {
                    docker.withRegistry('https://registry.hub.docker.com','dockercred'){
                        appImage.push("${env.BUILD_NUMBER}")
                        appImage.push("latest")
                    }
                }
            }
        }

        stage('Deploy'){
            script {
                env.GIT_SSH_COMMAND = 'ssh -o StrictHostKeyChecking=no'
                container('argo'){
                    checkout([$class: 'GitSCM',
                        branches: [[name: '*/main' ]],
                        extensions: scm.extensions,
                        userRemoteConfigs: [[
                            url: 'git@github.com:Yangsuseong/spring-petclinic-data-jdbc-cicd.git',
                            credentialsId: 'githubcred',
                        ]]
                    ])
                    sshagent(credentials: ['jenkins-ssh-private']){
                        sh("""
                            #!/bin/bash
                            set +x
                            export GIT_SSH_COMMAND="ssh -oStrictHostKeyChecking=no"
                            git config --global user.email "tntjd5596@gmail.com""
                            git checkout main
                            cd app/overlays/dev && kustomize edit set image tntjd5596/spring-petclinic-data-jdbc:${BUILD_NUMBER}
                            git commit -a -m "CI/CD Build"
                            git push
                        """)
                    }
                }
            }
        }
    }
} 
