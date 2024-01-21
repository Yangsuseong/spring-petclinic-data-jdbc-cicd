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
    ],

    volumes: [
        hostPathVolume(mountPath: '/var/run/docker.sock', hostPath: '/var/run/docker.sock'),
    ]
) {
    node('docker-build') {
        def dockerHubCred = "dckr_pat_YHktmwuG70ibC-V4Bp1CVRDubzI"
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
                    docker.withRegistry('https://registry.hub.docker.com','Dockerhub'){
                        appImage.push("${env.BUILD_NUMBER}")
                        appImage.push("latest")
                    }
                }
            }
        }

        stage('Deploy'){
            container('argo'){
                checkout([$class: 'GitSCM',
                    branches: [[name: '*/main' ]],
                    extensions: scm.extensions,
                    userRemoteConfigs: [[
                        url: 'https://github.com/Yangsuseong/spring-petclinic-data-jdbc-cicd',
                        credentialsId: 'Github',
                    ]]
                ])
                sshagent(credentials: ['Github']){
                    sh("""
                        #!/usr/bin/env bash
                        set +x
                        export GIT_SSH_COMMAND="ssh -oStrictHostKeyChecking=no"
                        git config --global user.email "tntjd5596@gmail.com"
                        git checkout main
                        cd app/overlays/dev && kustomize edit set image tntjd5596/spring-petclinic-data-jdbc:${env.BUILD_NUMBER}

                        # Debugging: Print current state
                        echo "Current directory: \$(pwd)"
                        echo "Git configurations:"
                        git config --list

                        # Debugging: Print changes
                        git status
                        git diff

                        git add app/overlays/dev/kustomization.yaml
                        git commit -a -m "CI/CD Build"
                        git push
                    """)
                }
            }
        }
    }
}

