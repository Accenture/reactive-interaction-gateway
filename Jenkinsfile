#!/usr/bin/env groovy

node {
    def dockerhubDomain = 'dockerhub.accenture.com'
    def dockerhubAccount = 'lwa'
    def imageName = 'fsa-reactive-gateway'
    def languageTag = 'elixir'
    def imageTestSuffix = 'test'
    def imageBuildSuffix = 'build'
    def imageDeploySuffix = 'deploy'
    def gitHash
    
    ansiColor('xterm') {
        stage('Preparation') {            
            // wipe out workspace
            deleteDir()
            
            // clone repository
            git url: 'ssh://git@innersource.accenture.com/a2495/reactive-gateway-elixir.git', branch: 'feature/deploy', credentialsId: '4c9b7d51-e0d4-4184-ab62-04b48b0dc227'
            
            // get last commit hash
            gitHash = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
            
            // ensure that docker is running
            sh '''(
                if [ `ps -ef | grep -v grep | grep docker | wc -l` -gt 0 ]
                then
                    echo 'Docker is running ...'
                else
                    echo 'Starting docker ...'
                    service docker start
                fi
            )'''
        }
        
        stage('Test') {
            // build environment for Elixir app release
            sh "docker build -t ${imageName}-${languageTag}-${imageTestSuffix} -f test.dockerfile ."
            // run release for app and mount artifacts to volume
            sh "docker run --name ${imageName}-${languageTag}-${imageTestSuffix} ${imageName}-${languageTag}-${imageTestSuffix}"
        }
        
        stage('Build') {
            // build environment for Elixir app release
            sh "docker build -t ${imageName}-${languageTag}-${imageBuildSuffix} -f build.dockerfile ."
            // run release for app and mount artifacts to volume
            sh "docker run --name ${imageName}-${languageTag}-${imageBuildSuffix} -v /var/jenkins_home/jobs/banking-ref-app/jobs/reactive-gateway-elixir/workspace/fsa-reactive-gateway:/opt/sites/fsa-reactive-gateway/_build/prod/rel/gateway ${imageName}-${languageTag}-${imageBuildSuffix}"
        }
        
        stage('Deploy') {
            withCredentials([usernamePassword(credentialsId: 'martin-dockerhub', passwordVariable: 'DOCKERHUB_PASSWORD', usernameVariable: 'DOCKERHUB_USERNAME')]) {
                sh "docker login -u $DOCKERHUB_USERNAME -p $DOCKERHUB_PASSWORD $dockerhubDomain"
                
                // build image of application from artifacts in volume
                def appImage = docker.build("${imageName}-${languageTag}-${imageDeploySuffix}")
                
                // tag and push images without basepath
                sh "docker tag ${appImage.imageName()} ${dockerhubDomain}/${dockerhubAccount}/${imageName}:${languageTag}-${gitHash}"
                sh "docker push ${dockerhubDomain}/${dockerhubAccount}/${imageName}:${languageTag}-${gitHash}"
                sh "docker tag ${appImage.imageName()} ${dockerhubDomain}/${dockerhubAccount}/${imageName}:${languageTag}"
                sh "docker push ${dockerhubDomain}/${dockerhubAccount}/${imageName}:${languageTag}"
            }
        }
        
        stage('Clean') {
            sh '''(
                if [ `docker images -q -f dangling=true | wc -l` -gt 0 ]
                then
                    echo 'Removing dangling images ...'
                    docker rmi -f $(docker images -q -f dangling=true)
                else
                    echo 'No dangling images found'
                fi
            )'''
            
            // remove dead container with build environment
            sh "docker rm ${imageName}-${languageTag}-${imageBuildSuffix}"
            // delete images
            // sh "docker rmi ${imageName}-${languageTag}-${imageBuildSuffix}"
            // sh "docker rmi ${imageName}-${languageTag}-${imageDeploySuffix}"
            sh "docker rmi \$(docker images --format '{{.Repository}}:{{.Tag}}' | grep ${imageName})"
            // sh "docker rmi \$(docker images --format '{{.Repository}}:{{.Tag}}' | grep ${gitHash})"
        }
    }
}
