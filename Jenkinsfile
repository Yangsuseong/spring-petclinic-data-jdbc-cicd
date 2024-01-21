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
        def dockerHubCred = "dckr_pat_QCKdNy2MK1U42P52KIFgoaKoFCg"
        def appImage

        stage('Checkout'){
            container('git'){
                checkout scm
            }
        }

        stage('Build'){
            container('docker'){
                script {
                    appImage = docker.build("tntjd5596/spring-petclinic-data-jdbc")
                }
            }
        }


        stage('Test'){
            container('docker'){
                script {
                    appImage.inside {
                        sh 'npm install'
                        sh 'npm test'
                    }
                }
            }
        }

        stage('Push'){
            container('docker'){
                script {
                    docker.withRegistry('https://registry.hub.docker.com',
                    'dckr_pat_QCKdNy2MK1U42P52KIFgoaKoFCg'){
                        appImage.push("${env.BUILD_NUMBER}")
                        appImage.push("latest")
                    }
                }
            }
        }
    }   

}
