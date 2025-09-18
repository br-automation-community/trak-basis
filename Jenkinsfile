@Library('BuR_External@feature/AS_6') _

def PROJECT_NAME = "TrakBasisProject"
def CONFIG_NAME = "Config1"
def UNIT_TEST_CONFIG_NAME = "Config1"

pipeline {
    agent { 
         node { 
             label 'bras_6'
         }
    } 
    environment {
    	PROJECT_DIR = "$WORKSPACE"
    	RELEASE_VERSION = ReleaseVersion(workspace:  "${WORKSPACE}");
    }
    stages {
        stage('Update Tags') {
            steps {
                bat(script: 'git fetch --tags --force');
            }
        }
        stage('Build AS Project') {
			steps {
				BuildASProject(project: "${PROJECT_DIR}", configuration: "${CONFIG_NAME}", max_warnings: -1, buildpip: false);
			}
        }
        stage('Unit Tests') {
            options {
                timeout(time: 15, unit: 'MINUTES') 
            } 
			steps {
				RunArUnitTests(project: "${PROJECT_DIR}", configuration: "${UNIT_TEST_CONFIG_NAME}");
			}
        }
    }
    post {
        always {
            script {
                ProcessArTestResults()
            }
        }
    }
}