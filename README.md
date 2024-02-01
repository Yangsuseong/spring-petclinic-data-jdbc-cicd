
File Tree
```
.
├── app # 어플리케이션 CI/CD Yaml
│   ├── base
│   │   ├── springboot.yaml
│   │   ├── mysql.yaml
│   │   ├── configmap.yaml
│   │   ├── service.yaml
│   │   ├── secret.yaml
│   │   ├── ingress.yaml
│   │   └── kustomization.yaml
│   └── overlays
│       └── dev
│           └── kustomization.yaml
├── spring-petclinic-data-jdbc    # 어플리케이션 원본
├── k8s-deploy    # K8s 배포 yaml 
│   ├── cicd    # CI/CD 배포 yaml
│   │   ├── ArgoCD
│   │   └── Jenkinsfile
│   └── kubernetes    # 어플리케이션 yaml
│       ├── springboot.yaml
│       ├── mysql.yaml
│       ├── configmap.yaml
│       ├── service.yaml
│       ├── secret.yaml
│       ├── ingress.yaml
│       └── cert
├── config       # 어플리케이션 설정파일
│   └── application.properties
├── Dockerfile
└── README.md
```


# 목차

- [Docker에 어플리케이션과 mysql 배포 후 동작 테스트](#Docker에-어플리케이션과-mysql-배포-후-동작-테스트)
  * [사전 설정](#사전-설정)
  * [어플리케이션 구조 파악](#어플리케이션-구조-파악)
  * [Docker에서 정상 동작하는지 테스트 진행](#Docker에서-정상-동작하는지-테스트-진행)
    + [Docker compose 파일을 이용하여 mysql 배포](#Docker-compose-파일을-이용하여-mysql-배포)
    + [gradle로 이미지 빌드 테스트](#gradle로-이미지-빌드-테스트)
    + [Docker 이미지 빌드 gradle 어플리케이션 빌드](#Docker-이미지-빌드-gradle-어플리케이션-빌드)
    + [Docker에서 동작 확인](#Docker에서-동작-확인)
  * [Docker 테스트 결과 확인](#Docker-테스트-결과-확인)
- [테스트용 Kubernetes 환경 구축](#테스트용-Kubernetes-환경-구축)
  * [테스트 환경](#테스트-환경)
  * [사전 설정](#사전-설정)
  * [kubernetes 배포](#kubernetes-배포)
  * [Compute node 연결](#Compute-node-연결)
  * [배포 완료 후 상태 확인](#배포-완료-후-상태-확인)
- [kubernetes에 서비스 배포](#kubernetes에-서비스-배포)
  * [서비스 설계](#서비스-설계)
  * [ingress-nginx-controller 배포](#ingress-nginx-controller-배포)
  * [Spring Application.properties 수정](#Spring-Application.properties-수정)
  * [kuberntets yaml파일 생성 및 배포](#kuberntets-yaml파일-생성-및-배포)
  * [Ingress Nginx 로 서비스 접근 확인](#Ingress-Nginx-로-서비스-접근-확인)
  * [K8s 환경에서 Nginx ingress로 서비스 접속 확인](#K8s-환경에서-Nginx-ingress로-서비스-접속-확인)
- [Jenkins를 이용한 CI 적용](#Jenkins를-이용한-CI-적용)
  * [Jenkins 배포](#Jenkins-배포)
  * [Jenkins와 Kubernetes 연동](#Jenkins와-Kubernetes-연동)
  * [Github와 Jenkins에 Jenkins sshkey 등록](#Github와-Jenkins에-Jenkins-sshkey-등록)
  * [Jenkins에 Github Credential 등록](#Jenkins에-Github-Credential-등록)
  * [Jenkins에 Dockerhub Credential 등록](#Jenkins에-Dockerhub-Credential-등록)
  * [Jenkinsfile 생성](#Jenkinsfile-생성)
  * [Jenkins pipeline 추가](#Jenkins-pipeline-추가)
  * [Git Repository의 Web hook 설정](#Git-Repository의-Web-hook-설정)
  * [Jenkins Pipeline 동작 확인](#Jenkins-Pipeline-동작-확인)
  * [Github Webhook 동작 확인](#Github-Webhook-동작-확인)
- [ArgoCD를 이용한 CD 적용](#ArgoCD를-이용한-CD-적용)
  * [ArgoCD 배포](#ArgoCD-배포)
  * [ArgoCD admin계정 PW변경](#ArgoCD-admin계정-PW변경)
  * [Kustomization.yaml 생성 후 적용 Jenkins Pipeline 추가](#Kustomization.yaml-생성-후-적용-Jenkins-Pipeline-추가)
  * [Jenkins Pipeline에 Deploy 추가](#Jenkins-Pipeline에-Deploy-추가)
  * [ArgoCD 어플리케이션 등록](#ArgoCD-어플리케이션-등록)
  * [Git Push -> Jenkin Build -> ArgoCD 배포 자동화 확인](#Git-Push-->-Jenkin-Build-->-ArgoCD-배포-자동화-확인)
    + [Git Push](#Git-Push)
    + [Jenkins 빌드&배포 확인](#Jenkins-빌드&배포-확인)
    + [Dockerhub 이미지 업로드 확인](#Dockerhub-이미지-업로드-확인)
    + [Gitub Yaml 업데이트 여부 확인](#Gitub-Yaml-업데이트-여부-확인)
    + [ArgoCD 배포 확인](#ArgoCD-배포-확인)
- [Reference](#reference)







# Docker에 어플리케이션과 mysql 배포 후 동작 테스트
* [spring-petclinic-data-jdbc](https://github.com/spring-petclinic/spring-petclinic-data-jdbc)

## 사전 설정

* Docker 설치
    * 모든 노드에서 진행
    ```
    sudo apt-get update
    sudo apt-get install ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update

    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    ```

gradle을 사용하여 어플리케이션과 도커이미지를 빌드하기 위해 gradle을 설치하였습니다.
```
$ sudo apt update
$ VERSION=7.5.1
$ wget https://services.gradle.org/distributions/gradle-${VERSION}-bin.zip -P /tmp
$ sudo unzip -d /opt/gradle /tmp/gradle-${VERSION}-bin.zip
$ sudo ln -s /opt/gradle/gradle-${VERSION} /opt/gradle/latest
```

gradle 환경변수 지정
```
$ sudo vim /etc/profile.d/gradle.sh
    ########아래 내용 추가########
    # /etc/profile.d/gradle.sh

    export GRADLE_HOME=/opt/gradle/latest
    export PATH=${GRADLE_HOME}/bin:${PATH}
    #############################

$ sudo chmod +x /etc/profile.d/gradle.sh
$ source /etc/profile.d/gradle.sh
```

JAVA_HOME 환경변수 등록을 위해 openjdk를 설치하였습니다.
petclinic 프로젝트에서 17버전 이상을 사용해야 한다고 명시되어 있기때문에 openjdk-17-jdk를 설치합니다.
```
$ sudo apt install openjdk-17-jdk
$ sudo vim /etc/profile
########## 하단에 내용 추가 ##########
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
####################################

$ source /etc/profile
```


## 어플리케이션 구조 파악
[README.md](https://github.com/spring-projects/spring-petclinic/blob/main/readme.md) 파일에 해당 어플리케이션을 Gradle로 빌드하려면 `./gradlew build` 명령어를 사용하라고 명시되어 있습니다. 
Docker-compose 파일을 확인하여 SQL이 사용하는 포트와 DB에 대한 정보 그리고 연결된 Configfile이 무엇인지 체크합니다.
그리고 Linux 환경에서 docker host를 사용하기 위해 extra_hosts 옵션을 추가해줍니다.
이 옵션을 추가하지 않으면 docker에서 spring과 mysql서비스를 올려 테스트할때 'hikari link failure' 에러가 발생합니다.
```
version: "2.2"

services:
  mysql:
    image: mysql:8.0    # 기본 이미지는 mysql:8.0를 사용 
    ports:
      - "3306:3306"     # 3306포트를 사용
    environment:
      - MYSQL_ROOT_PASSWORD=petclinic    # mysql 계정 확인
      - MYSQL_DATABASE=petclinic         # mysql DB 이름 확인
    volumes:
      - "./conf.d:/etc/mysql/conf.d:ro"  # mysql config파일 확인
    extra_hosts:
      - "host.docker.internal:host-gateway"  # 추가
```


## Docker에서 정상 동작하는지 테스트 진행

### Docker compose 파일을 이용하여 mysql 배포
어플리케이션을 먼저 배포시 DB연결에 실패하는 오류가 발생하여 DB를 먼저 배포 진행합니다.
```
$ docker-compose up -d
>>>
Starting spring-petclinic-data-jdbc_mysql_1 ... done
```


### gradle로 이미지 빌드 테스트

gradle로 Docker 이미지를 빌드하기 위해 build.gradle파일을 수정합니다.
```
plugins {
    id 'com.palantir.docker' version '0.35.0'
}

docker {
    name "gradlebuild:test"
}
```

Dockerfile을 생성합니다.
```
FROM openjdk:18-jdk-alpine
WORKDIR /app
COPY application.properties /app/src/main/resources/application.properties
COPY ./ ./
RUN ["./gradlew","build","-x","processTestAot"]
CMD java -jar build/libs/*.jar
```

다음 명령어를 사용하여 gradle로 docker image 빌드를 진행합니다.
```
./gradlew build
```

이때 Docker host통신 관련 문제가 발생하여 진행을 멈추고 Dockerfile로 이미지 빌드를 진행하였습니다.
Linux 환경에서는 Docker 실행 시 '--add-host' 옵션을 주지 않으면 host 통신이 불가능하기 때문에 빌드 테스트중 mysql DB와 통신이 되지 않아 빌드에 실패하는 현상이 발생하였습니다.
gradle을 많이 사용해보지 않아 우선 로컬 테스트에서는 익숙한 Docker를 이용하여 진행해보려고 합니다.


### Docker 이미지 빌드 gradle 어플리케이션 빌드

gradle 버전 확인
* 7.5.1 버전을 사용
```
$ gradle -v
------------------------------------------------------------
Gradle 7.5.1
------------------------------------------------------------

Build time:   2022-08-05 21:17:56 UTC
Revision:     d1daa0cbf1a0103000b71484e1dbfe096e095918

Kotlin:       1.6.21
Groovy:       3.0.10
Ant:          Apache Ant(TM) version 1.10.11 compiled on July 10 2021
JVM:          11.0.21 (Ubuntu 11.0.21+9-post-Ubuntu-0ubuntu120.04)
OS:           Linux 5.4.0-169-generic amd64

```


gradle 초기화
* 초기화를 진행하면 build.gradle, gradlew.bat, settings.gradle, gradlew 파일이 생성됩니다.
```
$ gradle init
```


Gradle로 Docker와 어플리케이션 이미지 빌드를 하기위해 자동 생성되는 build.gradle 파일을 [spring-petclinic](https://github.com/spring-projects/spring-petclinic)에 있는 build.gradle 파일과 비교하여 수정하였습니다.
spring boot 2.5.0버전 이상부터는 gradle로 빌드를 할때 jar파일이 2개 생성됩니다.
첫번째 jar는 해당 프로젝트에 필요한 모든 의존성이 같이 추가된것으로 MANIFEST.MF까지 모두 정상적인 형태로 나옵니다.
하지만 plain.jar는 의존성을 제외하고 딱 프로젝트에 있는 자원들만 jar로 만든것으로 spring 관련 의존성이 빠져 MANIFEST.MF에 Main메소드의 위치가 나오지 않습니다.
앱이름-plain.jar를 생성하지 않기 위해서는 아래 명령어를 build.gradle에 추가하였습니다.
```
$ cat build.gradle
>>>
/*
 * This file was generated by the Gradle 'init' task.
 */

plugins {
    id 'java'
    id 'maven-publish'
    id 'org.springframework.boot' version '3.2.0'
    id 'io.spring.dependency-management' version '1.1.4'
    id 'org.graalvm.buildtools.native' version '0.9.28'
}

apply plugin: 'java'

group = 'org.springframework.samples'
version = '3.2.0'
sourceCompatibility = '17'
description = 'petclinic'

repositories {
    mavenLocal()
    maven {
        url = uri('https://repo.spring.io/snapshot')
    }

    maven {
        url = uri('https://repo.spring.io/milestone')
    }

    maven {
        url = uri('https://repo.maven.apache.org/maven2/')
    }
}

dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-actuator'
    implementation 'org.springframework.boot:spring-boot-starter-validation'
    implementation 'org.springframework.boot:spring-boot-starter-cache'
    implementation 'org.springframework.boot:spring-boot-starter-data-jdbc'
    implementation 'org.springframework.boot:spring-boot-starter-web'
    implementation 'org.springframework.boot:spring-boot-starter-thymeleaf'
    implementation 'org.flywaydb:flyway-core'
    implementation 'org.flywaydb:flyway-mysql'
    implementation 'com.github.ben-manes.caffeine:caffeine'
    implementation 'org.webjars:jquery:3.7.1'
    implementation 'org.webjars:jquery-ui:1.13.2'
    implementation 'org.webjars:bootstrap:5.3.2'
    implementation 'org.springframework.boot:spring-boot-devtools'
    runtimeOnly 'com.mysql:mysql-connector-j:8.0.33'
    testImplementation 'org.springframework.boot:spring-boot-starter-test'
    testImplementation 'org.testcontainers:mysql'
}


publishing {
    publications {
        maven(MavenPublication) {
            from(components.java)
        }
    }
}

tasks.withType(JavaCompile) {
    options.encoding = 'UTF-8'
}


jar {
    enabled = false
}

```


다음으로 이미지 빌드를 위한 Dockerfile을 생성합니다.
빌드시 지속적으로 'IllegalArgumentException: Code generation does not support ?' 에러가 발생하여 해당 프로세스를 건너뛰도록 옵션을 추가하였습니다.
Java 17버전 이상부터 사용이 가능하다고 나와있지만 17버전에서는 `Error creating bean with name 'processorMetrics'` 에러가 발생하여 18버전 이상을 사용해야합니다.
```
FROM openjdk:18-jdk-alpine
WORKDIR /app
COPY ./ ./
RUN ["./gradlew","build","-x","processTestAot"]
#CMD java -jar build/libs/*.jar
```

docker build 명령어로 이미지를 빌드합니다.
```
$ docker build -t test:test .
$ docker images
>>>
REPOSITORY   TAG       IMAGE ID       CREATED              SIZE
test         test      da3ea005f42b   About a minute ago   783MB
mysql        8.0       77f16659c129   4 weeks ago          591MB
```


### Docker에서 동작 확인

이 이미지로 jar 파일을 실행하여 테스트하기 위해 컨테이너를 생성합니다.
이때, Linux 환경에서 docker host통신을 하기 위해 --add-host 옵션을 추가해줍니다.
그러면 다음과같이 DB 연결에 실패하였다는 로그가 발생하게 됩니다.
```
$ docker run -ti -p 8080:8080 --add-host=host.docker.internal:host-gateway test:test sh
>>>
/app # java -jar build/libs/*.jar
>>>
The last packet sent successfully to the server was 0 milliseconds ago. The driver has not received any packets from the server.
        at com.mysql.cj.jdbc.exceptions.SQLError.createCommunicationsException(SQLError.java:175) ~[mysql-connector-j-8.1.0.jar!/:8.1.0]
        at com.mysql.cj.jdbc.exceptions.SQLExceptionsMapping.translateException(SQLExceptionsMapping.java:64) ~[mysql-connector-j-8.1.0.jar!/:8.1.0]
        at com.mysql.cj.jdbc.ConnectionImpl.createNewIO(ConnectionImpl.java:819) ~[mysql-connector-j-8.1.0.jar!/:8.1.0]
        at com.mysql.cj.jdbc.ConnectionImpl.<init>(ConnectionImpl.java:440) ~[mysql-connector-j-8.1.0.jar!/:8.1.0]
        at com.mysql.cj.jdbc.ConnectionImpl.getInstance(ConnectionImpl.java:239) ~[mysql-connector-j-8.1.0.jar!/:8.1.0]
        at com.mysql.cj.jdbc.NonRegisteringDriver.connect(NonRegisteringDriver.java:188) ~[mysql-connector-j-8.1.0.jar!/:8.1.0]
        at com.zaxxer.hikari.util.DriverDataSource.getConnection(DriverDataSource.java:138) ~[HikariCP-5.0.1.jar!/:na]
        at com.zaxxer.hikari.pool.PoolBase.newConnection(PoolBase.java:359) ~[HikariCP-5.0.1.jar!/:na]
        at com.zaxxer.hikari.pool.PoolBase.newPoolEntry(PoolBase.java:201) ~[HikariCP-5.0.1.jar!/:na]
        at com.zaxxer.hikari.pool.HikariPool.createPoolEntry(HikariPool.java:470) ~[HikariCP-5.0.1.jar!/:na]
        at com.zaxxer.hikari.pool.HikariPool.checkFailFast(HikariPool.java:561) ~[HikariCP-5.0.1.jar!/:na]
        at com.zaxxer.hikari.pool.HikariPool.<init>(HikariPool.java:100) ~[HikariCP-5.0.1.jar!/:na]
        at com.zaxxer.hikari.HikariDataSource.getConnection(HikariDataSource.java:112) ~[HikariCP-5.0.1.jar!/:na]
        at org.flywaydb.core.internal.jdbc.JdbcUtils.openConnection(JdbcUtils.java:48) ~[flyway-core-9.22.3.jar!/:na]
        ... 109 common frames omitted
Caused by: com.mysql.cj.exceptions.CJCommunicationsException: Communications link failure
```

컨테이너에서 DB와 통신을 할 수 있도록 springboot의 /app/src/main/resources/application.properties 파일을 수정하고 이미지 빌드시 해당 파일을 내부로 복사하도록 Dockerfile을 수정합니다.
 Kubernetes에 연동 시에는 요구사항대로 Cluster domain으로 통신하도록 수정할 예정입니다.


* 현재 디렉토리에 application.properties 파일을 복사하여 가져옵니다.
```
$ vim application.properties
>>>
# database init
spring.datasource.url=jdbc:mysql://host.docker.internal:3306/petclinic
spring.datasource.username=root
spring.datasource.password=petclinic

# do not attempt to replace database with in-memory database
spring.test.database.replace=none

# Internationalization
spring.messages.basename=messages/messages

# Actuator / Management
management.endpoints.web.base-path=/manage
management.endpoints.web.exposure.include=*

# Logging
logging.level.org.springframework=info
logging.level.sql=debug
# logging.level.org.springframework.web=debug
# logging.level.org.springframework.context.annotation=trace

# Maximum time static resources should be cached
spring.web.resources.cache.cachecontrol.max-age=12h

```

Dockerfile을 수정하여 빌드를 할때 해당 파일을 컨테이너 내부로 복사하도록 하여 빌드합니다.
```
$ vim dockerfile
>>>
FROM openjdk:18-jdk-alpine
WORKDIR /app
COPY ./ ./
COPY ./application.properties /app/src/main/resources/application.properties
RUN ["./gradlew","build","-x","processTestAot"]
CMD java -jar build/libs/*.jar

$ docker build -t test:test2 .
```

## Docker 테스트 결과 확인
새로 빌드한 이미지로 컨테이너를 생성하여 접속 테스트를 진행합니다.
정상적으로 접속 되는것을 확인할 수 있습니다.
![캡처](https://github.com/Yangsuseong/md-check/assets/34338964/8585ae38-9a65-4445-8c54-6f97e1601cff)


이 이미지를 k8s 환경에서 사용하기 위해 [Dockerhub](https://hub.docker.com/repository/docker/tntjd5596/spring-petclinic-data-jdbc/general)에 업로드합니다.
```
$ docker tag test:test tntjd5596/spring-petclinic-data-jdbc:test
$ docker login
$ docker push tntjd5596/spring-petclinic-data-jdbc:test
>>>
The push refers to repository [docker.io/tntjd5596/spring-petclinic-data-jdbc]
8a9b5d25f1f8: Pushed
075badf21f0a: Pushed
e21be2340fb7: Pushed
161ddf5c9722: Pushed
34f7184834b2: Mounted from library/openjdk
5836ece05bfd: Mounted from library/openjdk
72e830a4dff5: Mounted from library/openjdk
test: digest: sha256:47018447fcb43dbf4aa8eb9bbe652aede3e8c08b2cc884902dcac79b54d7d5e5 size: 1789
```


--- 

# 테스트용 Kubernetes 환경 구축

개인 윈도우 PC에 VMware를 이용하여 테스트 환경을 구축하였습니다.
* [VMware 설치 페이지](https://www.vmware.com/kr/products/workstation-player/workstation-player-evaluation.html)

![캡처3](https://github.com/Yangsuseong/md-check/assets/34338964/836e33ee-6665-4aec-ad3d-43dcceebcae4)

### 테스트 환경
* OS
    * Ubuntu 20.04

* 리소스 할당
    * Control node (hostname=compute)
    ```
    CPU : 2 core
    Ram : 4GB
    Disk : 30GB
    Network
    ens33 – NAT
    ens37 – 100.100.0.100(internal)
    ```

    * Compute node(hostname=node1)
    ```
    CPU : 2 core
    Ram : 4GB
    Disk : 30GB
    Network
    ens33 – NAT
    ens37 – 100.100.0.101(internal)
    ```


## 사전 설정
* SWAP OFF
    * 모든 노드에서 진행
    ```
    $ sudo swapoff -a

    $ sudo vim /etc/fstab
    >>>
    # /etc/fstab: static file system information.
    #
    # Use 'blkid' to print the universally unique identifier for a
    # device; this may be used with UUID= as a more robust way to name devices
    # that works even if disks are added and removed. See fstab(5).
    #
    # <file system> <mount point>   <type>  <options>       <dump>  <pass>
    # / was on /dev/sda2 during curtin installation
    /dev/disk/by-uuid/1677f744-e305-4781-9d38-3f37b6db66ab / ext4 defaults 0 1
    #/swap.img      none    swap    sw      0       0   # 주석처리
    ```



* NAT 네트워크 설정
    * 모든 노드에서 진행
    ```
    $ sudo modprobe iptable_nat
    $ sudo vim /etc/sysctl.conf
    ####하단에 내용 추가####
    net.ipv4.ip_forward=1
    #######################
    $ sudo sysctl -p
    ```


* Kubernetes를 docker로 배포하기 위해 cri-docker 설정
  * 모든 노드에서 진행
  * v1.24부터 k8s에서 docker 지원을 중단하여 containerd를 사용해야하지만 테스트 편의성을 위해 cri-docker를 사용하여 docker로 k8s를 배포할 수 있도록 세팅합니다.
```
  curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo systemctl enable --now docker && sudo systemctl status docker --no-pager
sudo usermod -aG docker worker
sudo docker container ls

# cri-docker Install
VER=$(curl -s https://api.github.com/repos/Mirantis/cri-dockerd/releases/latest|grep tag_name | cut -d '"' -f 4|sed 's/v//g')
echo $VER
wget https://github.com/Mirantis/cri-dockerd/releases/download/v${VER}/cri-dockerd-${VER}.amd64.tgz
tar xvf cri-dockerd-${VER}.amd64.tgz
sudo mv cri-dockerd/cri-dockerd /usr/local/bin/

# cri-docker Version Check
cri-dockerd --version

wget https://raw.githubusercontent.com/Mirantis/cri-dockerd/master/packaging/systemd/cri-docker.service
wget https://raw.githubusercontent.com/Mirantis/cri-dockerd/master/packaging/systemd/cri-docker.socket
sudo mv cri-docker.socket cri-docker.service /etc/systemd/system/
sudo sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service

sudo systemctl daemon-reload
sudo systemctl enable cri-docker.service
sudo systemctl enable --now cri-docker.socket

# cri-docker Active Check
sudo systemctl restart docker && sudo systemctl restart cri-docker
sudo systemctl status cri-docker.socket --no-pager 

# Docker cgroup Change Require to Systemd
sudo mkdir /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

sudo systemctl restart docker && sudo systemctl restart cri-docker
sudo docker info | grep Cgroup

# Kernel Forwarding 
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sudo sysctl --system
```


* Kubeadm, kubelet, kubectl 설치
    * 모든 노드에서 진행
    * docker를 사용하기 위해 cri-socket을 cir-docker로 사용하였습니다.
    ```
    $ sudo apt-get update
    $ sudo apt-get install -y apt-transport-https ca-certificates curl
    $ sudo mkdir /etc/apt/keyrings/
    $ sudo curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg  https://dl.k8s.io/apt/doc/apt-key.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
    $ sudo apt-get update
    $ sudo apt-get install -y kubelet kubeadm kubectl
    $ sudo apt-mark hold kubelet kubeadm kubectl    # 버전 holding
    ```


## kubernetes 배포

마스터노드에서 쿠버네티스를 배포한다. 완료 후 출력되는 join값을 잘 기록해 놓아야 합니다.
weave CNI를 사용하기 위해 네트워크 대역 설정하였고 네트워크 브릿지 설정 에러가 발생하여 에러 ignore 옵션을 추가하였습니다. 또한 cri-o가 아닌 docker를 사용하기 위해 소켓 경로를 직접 지정해줬습니다.
* control 에서 진행
```
$ sudo kubeadm init --pod-network-cidr=10.32.0.0/12 --apiserver-advertise-address=100.100.0.100 --cri-socket /var/run/cri-dockerd.sock --ignore-preflight-errors=FileContent--proc-sys-net-bridge-bridge-nf-call-iptables  
```


* 배포 후 Join key 임시 저장
```
$ vim ~/join.txt
>>>
kubeadm join 100.100.0.100:6443 --token x2iuga.gaxkdf6sxlc3kdgs \
        --discovery-token-ca-cert-hash sha256:34393b65ea89af0c41f61c992ae5e02dfeac5dc1bb5e92a704609be4db6a4da3
```


kubernetes config파일 admin계정에 복사
* control 에서 진행
```
$ mkdir -p $HOME/.kube
$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
$ sudo chown $(id -u):$(id -g) $HOME/.kube/config
```


## Compute node 연결
* node1 에서 진행
* 네트워크 브릿지 설정 에러가 발생하여 에러ignore 옵션 추가
* containerd가 아닌 cri-docker를 사용하기 위해 cri-socket 옵션 추가
```
$ sudo kubeadm join 100.100.0.100:6443 --token x2iuga.gaxkdf6sxlc3kdgs \
        --discovery-token-ca-cert-hash sha256:34393b65ea89af0c41f61c992ae5e02dfeac5dc1bb5e92a704609be4db6a4da3 --cri-socket /var/run/cri-dockerd.sock --ignore-preflight-errors=FileContent--proc-sys-net-bridge-bridge-nf-call-iptables
```


* K8s CNI 설치 (Weave net)
```
$ kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
```


## 배포 완료 후 상태 확인
* 노드 연결 상태 확인
```
$ kubectl get node
>>>
NAME      STATUS   ROLES           AGE     VERSION
control   Ready    control-plane   13m     v1.28.2
node1     Ready    <none>          4m41s   v1.28.2
```


* 모든 pod가 정상 동작중인지 확인
```
$ kubectl get pod -A
>>>
NAMESPACE     NAME                              READY   STATUS    RESTARTS      AGE
kube-system   coredns-5dd5756b68-sb84c          1/1     Running   0             12m
kube-system   coredns-5dd5756b68-w47n6          1/1     Running   0             12m
kube-system   etcd-control                      1/1     Running   0             13m
kube-system   kube-apiserver-control            1/1     Running   0             13m
kube-system   kube-controller-manager-control   1/1     Running   0             13m
kube-system   kube-proxy-4dd2m                  1/1     Running   0             12m
kube-system   kube-proxy-jhtzh                  1/1     Running   0             4m36s
kube-system   kube-scheduler-control            1/1     Running   0             13m
kube-system   weave-net-ltxj9                   2/2     Running   1 (20s ago)   31s
kube-system   weave-net-mgdlw                   2/2     Running   1 (19s ago)   31s
```


--- 

# kubernetes에 어플리케이션 배포

* gradle을 사용하여 어플리케이션과 도커이미지를 빌드한다.
* 어플리케이션의 log는 host의 /logs 디렉토리에 적재되도록 한다.
* 어플리케이션과 DB는 cluster domain으로 통신한다.
* nginx-ingress-controller 통해 어플리케이션에 접속이 가능하다.
* namespace는 default를 사용한다.
* README.md 파일에 실행 방법을 기술한다.

## 서비스 설계

File Tree
```
.
├── app
│   ├── base
│   │   ├── springboot.yaml
│   │   ├── mysql.yaml
│   │   ├── configmap.yaml
│   │   ├── service.yaml
│   │   ├── secret.yaml
│   │   ├── ingress.yaml
│   │   └── kustomization.yaml
│   └── overlays
│       └── dev
│           └── kustomization.yaml
├── spring-petclinic-data-jdbc
├── k8s-deploy
│   ├── cicd
│   │   ├── ArgoCD
│   │   └── Jenkinsfile
│   └── kubernetes
│       ├── springboot.yaml
│       ├── mysql.yaml
│       ├── configmap.yaml
│       ├── service.yaml
│       ├── secret.yaml
│       ├── ingress.yaml
│       └── cert
├── config
│   └── application.properties
├── Dockerfile
└── README.md
```

## ingress-nginx-controller 배포
[공식 사이트](https://kubernetes.github.io/ingress-nginx/deploy/#quick-start)에서 설치 방법을 찾아 배포합니다.
```
$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml

$ kubectl get pod -n ingress-nginx
>>>
NAME                                        READY   STATUS      RESTARTS   AGE
ingress-nginx-admission-create-xvzq8        0/1     Completed   0          96s
ingress-nginx-admission-patch-k7f4s         0/1     Completed   2          96s
ingress-nginx-controller-8558859656-qn2gc   1/1     Running     0          96s
```


## Spring Application.properties 수정
Spring Application.properties는 configmap으로 수정하려고 하면 rootfs 관련 에러가 발생합니다.
Kubernetes 호스트 도메인으로 통신하기 위해 Spring Application.properties 이미지 빌드 후 Dockerhub에 Push합니다.

'spring.datasource.url:3306'을 클러스터 도메인 'mysql-service.default.svc.cluster.local' 또는 같은 Namespace에 있는 서비스이기 때문에 서비스 이름인 'mysql-service:3306'으로 변경합니다.
```
# database init
spring.datasource.url=jdbc:mysql://mysql-service:3306/petclinic
spring.datasource.username=root
spring.datasource.password=petclinic

# do not attempt to replace database with in-memory database
spring.test.database.replace=none

# Internationalization
spring.messages.basename=messages/messages

# Actuator / Management
management.endpoints.web.base-path=/manage
management.endpoints.web.exposure.include=*

# Logging
logging.level.org.springframework=info
logging.level.sql=debug
# logging.level.org.springframework.web=debug
# logging.level.org.springframework.context.annotation=trace
logging.file.path=/app/build/libs/
logging.file.name=/app/build/libs/petclinic.log

# Maximum time static resources should be cached
spring.web.resources.cache.cachecontrol.max-age=12h

spring.datasource.hikari.connection-timeout=60000
spring.datasource.hikari.maximum-pool-size=5

```


## kuberntets yaml파일 생성 및 배포

Namespace는 Default를 사용해야하므로 matadata:namespace에 별도로 명시하였습니다.

* springboot.yaml
    * spring 어플리케이션 로그는 application.properties로 생성하였으며 컨테이너 내부에서 /app/build/libs/petclinic.log 로 기록되므로 해당 파일을 Host PC의 /logs/myapp.log 로 마운트하였습니다.
    * container 생성 전 initcontainer로 기존 파일들을 host pc로 복사 후 container에 마운트하는 방법으로 진행하였습니다. 
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: springboot-deployment
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: springboot
  template:
    metadata:
      labels:
        app: springboot
    spec:
      initContainers:
      - name: copy-files
        image: tntjd5596/spring-petclinic-data-jdbc:k8s10
        command: ['sh', '-c', 'cp /app/build/libs/spring-petclinic-*.jar /logs/application.jar']
        volumeMounts:
        - name: log-volume
          mountPath: /logs/
      containers:
      - name: springboot-pod
        image: tntjd5596/spring-petclinic-data-jdbc:k8s10
        ports:
        - containerPort: 8080
        volumeMounts:
        - name: log-volume
          mountPath: /app/build/libs/
      volumes:
      - name: log-volume
        hostPath:
          path: /logs/

```

* mysql.yaml
    * docker-compose에 있던 volumes: - "./conf.d:/etc/mysql/conf.d:ro" 를 구현하기 위해 Configmap을 연결하였습니다. mysql 배포시 기본적으로 필요한 MYSQL_ROOT_PASSWORD는 보안을 위해 base64로 인코딩된 비밀번호를 Secret으로 생성하여 배포하였습니다.
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql-deployment
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql-pod
        image: mysql:8.0
        ports:
        - containerPort: 3306
        volumeMounts:
        - name: mysql-config-volume
          mountPath: /etc/mysql/conf.d
        env:
        - name: MYSQL_DATABASE
          valueFrom:
            configMapKeyRef:
              name: mysql-configmap
              key: mysql-database-name
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-root-password
              key: password
      volumes:
      - name: mysql-config-volume
        configMap:
          name: mysql-configmap
          items:
          - key: my.cnf
            path: my.cnf
```

* configmap.yaml
    * mysql에 연결될 configmap을 생성하였습니다. 기존 docker-compose파일에 연결된 내용이 없으므로 configmap에도 빈 파일로 생성하였습니다.
```
apiVersion: v1
kind: ConfigMap
metadata:
  name: mysql-configmap
  namespace: default
data:
  my.cnf: |
    # insert config
  mysql-database-name: petclinic
```

* service.yaml
    * deployment에 사용되는 포트에 맞는 서비스를 생성하였습니다.
```
apiVersion: v1
kind: Service
metadata:
  name: springboot-service
  namespace: default
spec:
  selector:
    app: springboot
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
  type: ClusterIP
---
apiVersion: v1
kind: Service
metadata:
  name: mysql-service
  namespace: default
spec:
  selector:
    app: mysql
  ports:
    - protocol: TCP
      port: 3306
      targetPort: 3306
  type: ClusterIP

```

* secret.yaml
    * mysql 배포시 사용될 MYSQL_ROOT_PASSWORD를 base64로 인코딩하여 Secret으로 생성하였습니다.
```
apiVersion: v1
kind: Secret
metadata:
  name: mysql-root-password
  namespace: default
type: Opaque
data:
  password: cGV0Y2xpbmlj

```

* ingress.yaml
  * nginx를 사용하기 위해 어노테이션을 추가하였고, ssl 인증 키를 발급받아 시크릿으로 등록하였습니다.
  * 테스트 환경이 On-premise이고 공인IP와 도메인이 없어 nodeport를 이용한 접근 테스트만 진행하였습니다.
```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: petclinic-ingress
  namespace: default
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/rewrite-target: /
    ingressclass.kubernetes.io/is-default-class: "true"
spec:
  rules:
  - host: test.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: springboot-service
            port:
              number: 8080
  tls:
  - hosts:
    - petclinic.com
    secretName: petclinic-tls
```

시크릿 생성을 위한 스크립트는 다음과 같습니다.
```
#/bin/bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout ./tls.key -out ./tls.crt -subj "/CN=test.example.com"

kubectl create secret tls --save-config petclinic-tls --key ./tls.key --cert ./tls.crt
```



생성한 yaml파일을 배포합니다.
```
$ kubectl apply -f springboot.yaml
$ kubectl apply -f secret.yaml
$ kubectl apply -f configmap.yaml
$ kubectl apply -f mysql.yaml
$ kubectl apply -f service.yaml
$ kubectl apply -f ingress.yaml
```
![캡처4](https://github.com/Yangsuseong/md-check/assets/34338964/1a934e4d-6bf8-4a55-9b29-81be435e778c)


배포가 완료된 이후 springboot pod 로그를 확인하면 쿠버네티스에서도 정상적으로 동작하는것을 확인할 수 있습니다.
```
kubectl logs springboot-deployment-56cc9c9fbd-6htw6


              |\      _,,,--,,_
             /,`.-'`'   ._  \-;;,_
  _______ __|,4-  ) )_   .;.(__`'-'__     ___ __    _ ___ _______
 |       | '---''(_/._)-'(_\_)   |   |   |   |  |  | |   |       |
 |    _  |    ___|_     _|       |   |   |   |   |_| |   |       | __ _ _
 |   |_| |   |___  |   | |       |   |   |   |       |   |       | \ \ \ \
 |    ___|    ___| |   | |      _|   |___|   |  _    |   |      _|  \ \ \ \
 |   |   |   |___  |   | |     |_|       |   | | |   |   |     |_    ) ) ) )
 |___|   |_______| |___| |_______|_______|___|_|  |__|___|_______|  / / / /
 ==================================================================/_/_/_/

:: Built with Spring Boot :: 3.2.0


2024-01-20T05:22:39.905Z  INFO 1 --- [           main] o.s.s.petclinic.PetClinicApplication     : Starting PetClinicApplication v3.2.0 using Java 18-ea with PID 1 (/app/build/libs/spring-petclinic-data-jdbc-3.2.0.jar started by root in /app)
2024-01-20T05:22:39.908Z  INFO 1 --- [           main] o.s.s.petclinic.PetClinicApplication     : No active profile set, falling back to 1 default profile: "default"
2024-01-20T05:22:39.966Z  INFO 1 --- [           main] .e.DevToolsPropertyDefaultsPostProcessor : For additional web related logging consider setting the 'logging.level.web' property to 'DEBUG'
2024-01-20T05:22:40.932Z  INFO 1 --- [           main] .s.d.r.c.RepositoryConfigurationDelegate : Bootstrapping Spring Data JDBC repositories in DEFAULT mode.
2024-01-20T05:22:40.981Z  INFO 1 --- [           main] .s.d.r.c.RepositoryConfigurationDelegate : Finished Spring Data repository scanning in 45 ms. Found 5 JDBC repository interfaces.
2024-01-20T05:22:41.494Z  INFO 1 --- [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat initialized with port 8080 (http)
2024-01-20T05:22:41.503Z  INFO 1 --- [           main] o.apache.catalina.core.StandardService   : Starting service [Tomcat]
2024-01-20T05:22:41.503Z  INFO 1 --- [           main] o.apache.catalina.core.StandardEngine    : Starting Servlet engine: [Apache Tomcat/10.1.16]
2024-01-20T05:22:41.610Z  INFO 1 --- [           main] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring embedded WebApplicationContext
2024-01-20T05:22:41.611Z  INFO 1 --- [           main] w.s.c.ServletWebServerApplicationContext : Root WebApplicationContext: initialization completed in 1645 ms
2024-01-20T05:22:41.949Z  INFO 1 --- [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Starting...
2024-01-20T05:22:42.301Z  INFO 1 --- [           main] com.zaxxer.hikari.pool.HikariPool        : HikariPool-1 - Added connection com.mysql.cj.jdbc.ConnectionImpl@60652518
2024-01-20T05:22:42.303Z  INFO 1 --- [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Start completed.
2024-01-20T05:22:42.384Z  INFO 1 --- [           main] o.f.c.internal.license.VersionPrinter    : Flyway Community Edition 9.22.3 by Redgate
2024-01-20T05:22:42.384Z  INFO 1 --- [           main] o.f.c.internal.license.VersionPrinter    : See release notes here: https://rd.gt/416ObMi
2024-01-20T05:22:42.385Z  INFO 1 --- [           main] o.f.c.internal.license.VersionPrinter    :
2024-01-20T05:22:42.400Z  INFO 1 --- [           main] org.flywaydb.core.FlywayExecutor         : Database: jdbc:mysql://mysql-service.default.svc.cluster.local:3306/petclinic (MySQL 8.0)
2024-01-20T05:22:42.476Z  INFO 1 --- [           main] o.f.core.internal.command.DbValidate     : Successfully validated 2 migrations (execution time 00:00.041s)
2024-01-20T05:22:42.490Z  INFO 1 --- [           main] o.f.core.internal.command.DbMigrate      : Current version of schema `petclinic`: 002
2024-01-20T05:22:42.493Z  INFO 1 --- [           main] o.f.core.internal.command.DbMigrate      : Schema `petclinic` is up to date. No migration necessary.
2024-01-20T05:22:43.572Z  INFO 1 --- [           main] o.s.b.a.e.web.EndpointLinksResolver      : Exposing 14 endpoint(s) beneath base path '/manage'
2024-01-20T05:22:43.669Z  INFO 1 --- [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port 8080 (http) with context path ''
2024-01-20T05:22:43.682Z  INFO 1 --- [           main] o.s.s.petclinic.PetClinicApplication     : Started PetClinicApplication in 4.3 seconds (process running for 4.811)
```

## Ingress Nginx 로 서비스 접근 확인
다음으로 Ingress Nginx에서 Petclinic 서비스로 접근할 수 있도록 테스트를 진행합니다.
현재 테스트 환경이 On-premise 환경이므로 로드밸런서를 이용한 테스트가 불가능하여 NodePort로 접근이 되는지 확인하였습니다.

```
mercury@control:~/service/kubernetes$ kubectl get svc -A
NAMESPACE       NAME                                 TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
default         kubernetes                           ClusterIP      10.96.0.1       <none>        443/TCP                      18h
default         mysql-service                        ClusterIP      10.110.48.14    <none>        3306/TCP                     17h
default         springboot-service                   ClusterIP      10.106.242.21   <none>        80/TCP                       17h
ingress-nginx   ingress-nginx-controller             LoadBalancer   10.97.154.193   <pending>     80:32094/TCP,443:30958/TCP   17h
ingress-nginx   ingress-nginx-controller-admission   ClusterIP      10.96.153.83    <none>        443/TCP                      17h
kube-system     kube-dns                             ClusterIP      10.96.0.10      <none>        53/UDP,53/TCP,9153/TCP       18h

mercury@control:~/service/kubernetes$ kubectl get ing
NAME                CLASS    HOSTS   ADDRESS   PORTS   AGE
petclinic-ingress   <none>   *                 80      8m

```

## K8s 환경에서 Nginx ingress로 서비스 접속 확인
Cluster IP와 Ingress Nginx의 NodePort를 이용하여 웹 접속을 확인합니다.
정상적으로 Nginx Ingress를 통해 서비스로 접근되는것을 확인할 수 있습니다.

![캡처2](https://github.com/Yangsuseong/md-check/assets/34338964/5da0b8f5-1e2f-4c40-bcac-c1e495bda8c0)


--- 

# Jenkins를 이용한 CI 적용

Jenkins와 ArgoCD를 배포하여 CI/CD Tool을 적용하려고 합니다.


## Jenkins 배포

ci namespace를 생성하고 jenkins를 배포합니다.

`namespace.yaml`
```
apiVersion: v1
kind: Namespace
metadata:
  name: ci
```

`jenkins-master.yaml`
```
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: jenkins
  namespace: ci
spec:
  serviceName: jenkins
  replicas: 1
  selector:
    matchLabels:
      app: jenkins
  template:
    metadata:
      labels:
        app: jenkins
    spec:
      serviceAccountName: jenkins
      containers:
      - name: jenkins
        image: jenkins/jenkins:lts
        ports:
        - name: http-port
          containerPort: 8080
        - name: jnlp-port
          containerPort: 50000
        volumeMounts:
        - name: jenkins-vol
          mountPath: /var/jenkins_home
      volumes:
      - name: jenkins-vol
        hostPath:
          path: /jenkins-data
          type: Directory
---
apiVersion: v1
kind: Service
metadata:
  name: jenkins
  namespace: ci
spec:
  type: NodePort
  ports:
  - port: 8080
    targetPort: 8080
  selector:
    app: jenkins
---
apiVersion: v1
kind: Service
metadata:
  name: jenkins-jnlp
  namespace: ci
spec:
  type: ClusterIP
  ports:
  - port: 50000
    targetPort: 50000
  selector:
    app: jenkins
```

`jenkins-rbac.yaml`
```
apiVersion: v1
kind: ServiceAccount
metadata:
  name: jenkins
  namespace: ci
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: jenkins
  namespace: ci
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["create","delete","get","list","patch","update","watch"]
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create","delete","get","list","patch","update","watch"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get","list","watch"]
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get"]
- apiGroups: [""]
  resources: ["events"]
  verbs: ["get", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: jenkins
  namespace: ci
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: jenkins
subjects:
- kind: ServiceAccount
  name: jenkins
```

배포 완료 후 service 포트를 확인하여 웹으로 접속합니다.

```
$ kubectl apply -f namespace.yaml
$ kubectl apply -f jenkins-master.yaml
$ kubectl apply -f jenkins-rbac.yaml

$ kubectl get svc -n ci
>>>
NAME           TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
jenkins        NodePort    10.96.86.140   <none>        8080:31910/TCP   7m20s
jenkins-jnlp   ClusterIP   10.110.27.16   <none>        50000/TCP        7m20s
```

![캡처5](https://github.com/Yangsuseong/md-check/assets/34338964/0c0542ab-8544-47b5-b707-67098498724c)



## Jenkins와 Kubernetes 연동

초기 설정을 마친 후 jenkins에서 Kubernetes와 Docker Pipeline 플러그인을 설치합니다.

![캡처6](https://github.com/Yangsuseong/md-check/assets/34338964/a2d14f88-47af-45db-baca-ccf2edf516ee)


설치가 완료되면 kubernetes 정보를 등록해 연동합니다.
* Name: 해당 클러스터를 구분할 수 있는 이름
  * kubernetes
* Kubernetes URL: Jenkins가 k8s 내부에서 실행중이므로, API서버의 In-cluster URL을 입력
  * https://kubernetes.default.svc
* Kubernetes Namespace: Remote Agent 관련 리소스가 생성될 Namespace를 의미한다.
* RBAC 설정시 ‘ci’ Namespace에만 유효하도록 정의하였으므로 ci를 입력
  * ci
* Jenkins URL: In-cluster의 Jenkins URL로 HTTP 관련 Service 이름과 Port를 명시
  * http://jenkins:8080
* Jenkins tunnel: Remote Agent가 접근할 주소, jnlp 관련 Service 이름과 Port를 입력
  * jenkins-jnlp:50000
* Pod Labels 추가
  * Key: jenkins
  * Value: slave

![캡7](https://github.com/Yangsuseong/md-check/assets/34338964/0c3cf554-e16b-4e49-a895-28d0d54eae28)



## Github와 Jenkins에 Jenkins sshkey 등록

Jenkins-master Pod 내부로 접속해 SSH-Key 를 생성합니다.
그리고 생성한 키 내용을 Github에 등록하기 위해 복사합니다.
```
$ kubectl exec -ti -n ci jenkins-0 -- bash

(jenkins-0)$ ssh-keygen -t rsa
(jenkins-0)$ cat /var/jenkins_home/.ssh/id_rsa.pub
>>>
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDWATHuPxiiQi4C1m7rSJOgRQrlWDL
(중략)
+K1eneCK80yanuQM6jIJLVvw6SgMl1nTlW8= jenkins@jenkins-0
```

Git Hub 홈페이지에서 Setting -> SSH and GPG keys 탭에서 SSH key 등록합니다.

![캡처8](https://github.com/Yangsuseong/md-check/assets/34338964/2751fcf6-4079-40aa-a07c-02b679fa072c)



다음으로 Jenkins Dashboard에서 관리 -> Manage Credentials 로 이동 후 Credentials 등록합니다.
credential 종류는 'SSH Username with private key'로 선택합니다.
```
$ cat /var/jenkins_home/.ssh/id_rsa
-----BEGIN OPENSSH PRIVATE KEY-----
#$%#$%#$%#$%#$%!@#
#$!@#^#$%^@#$%!@#$
...
!@#$#$#$%!@%#$%!@#
!@#$==
-----END OPENSSH PRIVATE KEY-----
```

![캡처9](https://github.com/Yangsuseong/md-check/assets/34338964/a18d9048-4885-49cd-9866-e552b9e10b9a)


## Jenkins에 Github Credential 등록

Github홈페이지에 로그인 이후 계정설정 -> Developer Setting -> Personal access token에 들어갑니다.
이후 Generate Token을 클릭하고 권한을 할당한 이후 토큰을 생성하여 복사합니다.

![캡처12](https://github.com/Yangsuseong/md-check/assets/34338964/429a957b-e4fc-4b85-b678-6a8c02cc368b)

다음으로 Jenkins Dashboard로 돌아와서 Jenkins Dashboard 관리 -> Manage Credentials 로 이동 후 새로운 Credential을 생성해줍니다.
* Username : Git ID를 입력합니다.
* Password : 방금 생성한 Git Credential을 붙여넣습니다.
다른 값들은 원하는대로 설정 후 credential을 생성합니다.

![캡처13](https://github.com/Yangsuseong/md-check/assets/34338964/c1538fda-1f66-492d-855d-b78f0dbc9279)





## Jenkins에 Dockerhub Credential 등록

Jenkins Dashboard 관리 -> Manage Credentials 로 이동 후 방금 생성한 jenkins Credential에 추가로 정보를 등록하기 위해 Global-Credentials 버튼을 클릭합니다.
Kind : Username with password, Scope : Global을 선택하고 Username에 Dockerhub 계정을 입력합니다.
Password에는 Dockerhub 계정 설정에서 New Token을 발급받아 복사하여 붙여넣습니다.


![캡처10](https://github.com/Yangsuseong/md-check/assets/34338964/8851765d-2a27-421b-9954-4922c388b5f2)

![캡처11](https://github.com/Yangsuseong/md-check/assets/34338964/c5c6e37b-f96c-428f-8210-06423f0613bd)



## Jenkinsfile 생성

[과제 repository](https://github.com/kakaopayseccoding-devops/202401-tntjd5596-naver.com/blob/main/README.md_backup)와 Jenkins를 연결하기 위해 Jenkinsfile을 생성합니다.

`Jenkinsfile`
```
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
        def dockerHubCred = 'dckr_pat_QCKdNy2MK1U42P52KIFgoaKoFCg'
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
                    '${Jenkins에 생성한 Dockercred 이름}'){
                        appImage.push("${env.BUILD_NUMBER}")
                        appImage.push("latest")
                    }
                }
            }
        }
    }   
}
```


## Jenkins pipeline 추가

Jenkins Dashboard -> 새로운 Item 에서 Pipeline을 추가합니다.
* GitHub project: 빌드할 소스코드와 Jenkinsfile이 위치한 GitHub 프로젝트 URL(.git 생략)
* Github hook trigger for GITScm polling 체크
  * git push 가 이루어질때마다 자동으로 빌드 진행하도록 하는 trigger

![캡처14](https://github.com/Yangsuseong/md-check/assets/34338964/ac66a2f9-1062-4258-91b7-f0ed4ae2f582)


아래로 드래그하여 설정을 마저 진행합니다.
* Repository URL : Github Repository git 주소 (.git 포함)
* Credentials : Git Credential로 생성한 Credential 선택
* Branch Specifier : 레포지토리의 main 또는 master 브랜치 이름 확인 후 입력
* Script Path : Jenkinsfile의 경로 입력

![캡처15](https://github.com/Yangsuseong/md-check/assets/34338964/5277157b-db2a-451a-bdc7-7b12a423ec12)


## Git Repository의 Web hook 설정
Github -> Repository -> Setting -> Webhooks 로 이동 후 Add Webhook 클릭하여 web hook을 생성합니다.
여기서부터는 공유된 '202401-tntjd5596-naver.com' 레포지토리에서 진행이 안되기때문에 [개인 Repository](https://github.com/Yangsuseong/spring-petclinic-data-jdbc-cicd)를 생성하여 테스트를 진행하였습니다.

* Payload URL
  * http:{Jenkins 를 외부에서 접속할 수 있는 Domain}github-webhook
* Content type
  * application/json

![캡처18](https://github.com/Yangsuseong/md-check/assets/34338964/ae118f7a-c434-4feb-b291-86002b7b1d6b)



## Jenkins Pipeline 동작 확인

생성한 프로젝트에서 Build Now 버튼을 눌러 파이프라인이 정상적으로 동작하는지 확인합니다.
이때 에러가 발생할경우 로그를 확인하여 해결합니다.
2가지 문제로 인해 에러가 발생하여 해결하였습니다.
* 1번째 - gradlew 파일의 실행 권한 문제
* 2번째 - Dockergub Creditional 이름 대소문자 오타

![캡처19](https://github.com/Yangsuseong/md-check/assets/34338964/5a122fb5-43cd-463e-857e-7a4a52519ffe)

![캡처20](https://github.com/Yangsuseong/md-check/assets/34338964/d51810d8-3339-4d2a-898a-5784c2d1db53)

## Github Webhook 동작 확인
외부에서 Jenkins로 접속할 수 있는 환경이 아니어서 Webhook이 동작하지 않습니다.
지금까지 세팅을 모두 완료하였으면 정상적으로 Webhook이 동작하여 Git Push를 할 경우 자동으로 이미지 빌드가 진행될것입니다.

---

# ArgoCD를 이용한 CD 적용

ArgoCD를 이용하여 CD 환경을 구축하려고 합니다.

## ArgoCD 배포

ArgoCD Namespace를 생성합니다.

`namespace.yaml`
```
apiVersion: v1
kind: Namespace
metadata:
  name: argocd

```

ArgoCD 배포 yaml을 내려받고 argocd-server 서비스 부분을 찾아 type: NodePort 를 추가 후 argocd namespace에 배포합니다.
```
$ curl https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml -o argo-cd.yaml

$ vim argo-cd.yaml
```

`argo-cd.yaml`
```
(생략)
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app.kubernetes.io/component: server
    app.kubernetes.io/name: argocd-server
    app.kubernetes.io/part-of: argocd
  name: argocd-server
spec:
  type: NodePort
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: 8080
  - name: https
    port: 443
    protocol: TCP
    targetPort: 8080
  selector:
    app.kubernetes.io/name: argocd-server
---
(생략)
```

```
$ kubectl apply -f argo-cd.yaml -n argocd
```

ArgoCD server 서비스 포트를 확인합니다.
```
$ kubectl get svc -n argocd argocd-server
NAME            TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
argocd-server   NodePort   10.102.101.223   <none>        80:31907/TCP,443:32450/TCP   110s
```

해당 포트로 웹 접속 확인

![캡처21](https://github.com/Yangsuseong/md-check/assets/34338964/8ab56323-431e-4012-9dc6-56600c224d0e)


## ArgoCD admin계정 PW변경

초기 비밀번호 확인
```
$ kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
>>> 
qC9z-59RKpHSrM0F
```

로컬에 Argo CD CLI Tool 설치
```
$ VERSION=$(curl --silent "https://api.github.com/repos/argoproj/argo-cd/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')

$ sudo curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/$VERSION/argocd-linux-amd64

$ sudo chmod +x /usr/local/bin/argocd
```

ArgoCD admin계정으로로그인
```
$ argocd login 100.100.0.100:31907
>>>
WARNING: server certificate had error: tls: failed to verify certificate: x509: cannot validate certificate for 100.100.0.100 because it doesn't contain any IP SANs. Proceed insecurely (y/n)? y
Username: admin
Password: 
'admin:login' logged in successfully
Context '100.100.0.100:31907' updated
```

admin 계정 패스워드 변경
```
$ argocd account update-password
*** Enter password of currently logged in user (admin): 기존 패스워드
*** Enter new password for user admin: testtest123
*** Confirm new password for user admin: testtest123
Password updated
Context '100.100.0.100:31907' updated
```


## Kustomization.yaml 생성 후 적용 Jenkins Pipeline 추가

로컬에서 kustomize 명령어를 사용하기 위해 kustomize 설치
```
$ sudo snap install kustomize
```

kustomize file tree로 디렉토리 구성
```
├── base
│   ├── springboot.yaml
│   ├── mysql.yaml
│   ├── configmap.yaml
│   ├── service.yaml
│   ├── secret.yaml
│   ├── ingress.yaml
│   └── kustomization.yaml
└── overlays
    └── dev
        └── kustomization.yaml
```

kustomization.yaml 파일 생성

`base/kustomization.yaml`
```
resources:
- configmap.yaml
- secret.yaml
- mysql.yaml
- service.yaml
- springboot.yaml
- ingress.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
```

`/overlays/dev/kustomization.yaml`
```
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
images:
- name: tntjd5596/spring-petclinic-data-jdbc
  newTag: dev
resources:
- ../../base
```

kustomize 적용
```
$ kubectl apply -k overlays/dev/
```

이미지 태그 변경
```
$ cd overlays/dev/ && kustomize edit set image ghcr.io/wlgns5376/example-app:latest
```

Git에 변경사항 업데이트
```
$ git add ./*
$ git commit -a -m "kustomize setting"
$ git push
```

## Jenkins Pipeline에 Deploy 추가

Jenkinsfile에 Deploy Pipeline을 추가합니다.
* podTemplate에 argo 컨테이너 정보 추가
* Deploy Step 추가

`Jenkinsfile`
```
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
(생략)
        stage('Deploy'){
            container('argo'){
                checkout([$class: 'GitSCM',
                    branches: [[name: '*/main' ]],
                    extensions: scm.extensions,
                    userRemoteConfigs: [[
                        url: '<Git Hub 주소>',
                        credentialsId: '<Jenkins Git Hub 인증서 이름>',
                    ]]
                ])
                 withCredentials([usernamePassword(credentialsId: '<github인증서 이름>', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    sshagent(credentials: ['<Jenkins ssh 인증서 이름>']){
                        sh("""
                            #!/bin/bash
                            set +x
                            export GIT_SSH_COMMAND="ssh -oStrictHostKeyChecking=no"
                            git config --global user.name "<Github ID>"
                            git remote add origin https://${USERNAME}:${PASSWORD}@github.com/${USERNAME}/spring-petclinic-data-jdbc-cicd.git
                            git checkout main
                            cd app/overlays/dev && kustomize edit set image tntjd5596/spring-petclinic-data-jdbc:${BUILD_NUMBER}
                            git commit -a -m "CI/CD Build"
                            git push
                        """)
                    }
                 }
            }
        }
(생략)
```

Jenkins Plugin 추가 설치
* ssh Agent 플러그인 검색 후 설치

![캡처28](https://github.com/Yangsuseong/md-check/assets/34338964/d0667f9e-795e-4655-a826-e1b9db148a45)



## ArgoCD 어플리케이션 등록

NEW APP 버튼을 클릭해서 애플리케이션을 등록합니다.

![캡처22](https://github.com/Yangsuseong/md-check/assets/34338964/6b591bd8-f228-45f7-9932-f27e0ee06992)

기본 정보를 입력합니다.
Application Name은 spring-petclinic-data-jdbc로 설정하였습니다.
자동 Sync를 활성화하기 위해 Sync Policy는 Automatic으로 선택합니다.
다른 설정값은 Default 상태로 둡니다.

![캡처23](https://github.com/Yangsuseong/md-check/assets/34338964/a57ef392-bdf8-4f94-9a58-42fd8f3f8dd4)


현재 작업코드는 main branch에 저장되어있어서 Revision을 main로 설정했습니다.
그리고 Path는 app/base로 설정합니다.
DESTINATION에 namespace는 서비스가 배포된 default를 입력합니다.

![캡처25](https://github.com/Yangsuseong/md-check/assets/34338964/0aefd5ef-7f2b-4312-aee1-ad2090adbb49)


Create 버튼을 누르면 다음과 같이 서비스가 등록됩니다.
Sync 버튼을 누르면 Git 저장소의 내용을 가져와서 Kubernetes에 적용합니다.

![캡처26](https://github.com/Yangsuseong/md-check/assets/34338964/8f165f87-2b88-4c38-b7c3-fe88361d6d69)

Sync 버튼을 누른 후 어플리케이션이 연동된것을 확인할 수 있습니다.
하지만, 현재 springboot Pod의 상태가 Error 로 떠있는것을 볼 수 있습니다.
지금부터 문제 해결 후 Git push를 하면 자동으로 배포가 되는지 확인해보겠습니다.
* (이번 테스트에서는 VM내부망에서 진행되어 Git Webhook Trigger가 동작하지 않습니다. 따라서 build 시작은 Jenkins에서 수동으로 버튼을 눌러 진행됩니다.)

![캡처27](https://github.com/Yangsuseong/md-check/assets/34338964/9d7361f2-2dce-4f38-b981-5c196edd6d1d)


## Git Push -> Jenkin Build -> ArgoCD 배포 자동화 확인


### Git Push
소스코드 수정 후 Git 레포지토리에 Push합니다.

```
$ git add ./*
$ git commit -a -m "ArgoCD 동작확인"
$ git push
```

### Jenkins 빌드&배포 확인
Jenkins 대시보드에서 빌드가 진행, 완료되는지 확인합니다.
* 테스트 환경에서는 내부망으로 구성되어 Git Webhook 트리거가 동작하지 않아 수동으로 빌드 버튼을 눌러 진행하였습니다.

![캡처40](https://github.com/Yangsuseong/md-check/assets/34338964/68b5c494-29fd-4bfe-9a46-ea68f8fb4e1f)


### Dockerhub 이미지 업로드 확인

빌드 완료된 이미지가 정상적으로 Dockerhub에 업로드 되었는지 확인합니다.

![캡처41](https://github.com/Yangsuseong/md-check/assets/34338964/fd8631e0-4c40-4edd-bdef-3c81dac40be8)


### Gitub Yaml 업데이트 여부 확인

Github에서 Kustomization.yaml파일 내에 서비스 버전 태그가 자동으로 변경이 되었는지 확인합니다.

![캡처42](https://github.com/Yangsuseong/md-check/assets/34338964/81d6bf8f-0c6c-4bb3-8550-df743c21d16e)


### ArgoCD 배포 확인

ArgoCD에서 Github Push를 감지하고 자동으로 Sync가 진행되었는지 확인합니다.

![캡처43](https://github.com/Yangsuseong/md-check/assets/34338964/a8101bdf-04f0-479b-aa4b-4a241e957d6d)







---
## Reference
Gradle 설치
* https://jjeongil.tistory.com/2013
* https://velog.io/@k0000k/%EB%A6%AC%EB%88%85%EC%8A%A4%EC%97%90%EC%84%9C-Gradle-%EC%84%A4%EC%B9%98%ED%95%98%EA%B8%B0

Gradle로 Docker build하는방법
* https://www.youtube.com/watch?v=SzFYHB0l0jk 

Gradle Java 버전 호환성
* https://docs.gradle.org/6.5.1/userguide/compatibility.html 

Java Repository 버전 확인
* https://mvnrepository.com/artifact/com.mysql/mysql-connector-j 

Docker install
* https://docs.docker.com/engine/install/ubuntu/ 

Docker host 통신
* https://lasel.kr/archives/773 

Kubernetes 공식문서
* https://kubernetes.io/ko/docs/setup/production-environment/tools/kubeadm/install-kubeadm/ 

kubernetes + cri-docker 배포
* https://tech.hostway.co.kr/2022/08/30/1374/ 

Kubernetes GPG key 에러 해결방법
* https://github.com/kubernetes/release/issues/2862 
* https://velog.io/@yekim/Ubuntu-20.4-apt-get-update-%EC%97%90%EB%9F%AC 

ingress-nginx Controller 공식문서
* https://kubernetes.github.io/ingress-nginx/deploy/

On-premis 환경에서 ingress-nginx 접근 확인
* https://www.whatwant.com/entry/Install-NGINX-Ingress-Controller 

Jenkins와 Gradle을 통한 빌드 환경 구축
* https://velog.io/@qudalsrnt3x/Jenkins-%EC%A0%A0%ED%82%A8%EC%8A%A4%EC%99%80-Github%EC%9D%84-%ED%86%B5%ED%95%9C-%EB%B9%8C%EB%93%9C-%ED%99%98%EA%B2%BD-%EA%B5%AC%EC%B6%95

ArgoCD Kustomize 적용
* https://velog.io/@wlgns5376/GitOps-ArgoCD%EC%99%80-Kustomize%EB%A5%BC-%EC%9D%B4%EC%9A%A9%ED%95%B4-kubernetes%EC%97%90-%EB%B0%B0%ED%8F%AC%ED%95%98%EA%B8%B0 

Docker Hub 링크
* https://hub.docker.com/repository/docker/tntjd5596/spring-petclinic-data-jdbc-cicd/general
