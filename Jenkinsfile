pipeline {
  agent any

  options {
    timestamps()
    timeout(time: 30, unit: 'MINUTES')
  }

  environment {
    AWS_REGION = "ap-south-1"

    // Must be exact ECR repo URI (no tag)
    // Example: 167345113114.dkr.ecr.ap-south-1.amazonaws.com/project-1/webapp
    ECR_URI = "167345113114.dkr.ecr.ap-south-1.amazonaws.com/project-1"

    // Repo-1 (App code repo)
    APP_REPO_URL = "https://github.com/Bunny06022001/code-repo-project-1.git"
    APP_BRANCH   = "main"

    // Repo-2 (Helm/GitOps repo watched by ArgoCD)
    GITOPS_REPO_URL = "https://github.com/Bunny06022001/helm-repo-project-1.git"
    GITOPS_BRANCH   = "main"

    // Path inside Repo-2
    VALUES_FILE = "project-1/charts/webapp/values.yaml"
  }

  stages {

    stage('1) Checkout Repo-1 (App)') {
      steps {
        checkout([
          $class: 'GitSCM',
          branches: [[name: "*/${APP_BRANCH}"]],
          userRemoteConfigs: [[
            url: "${APP_REPO_URL}",
            credentialsId: 'git'
          ]]
        ])

        sh '''
          set -e
          echo "Repo-1 latest commit:"
          git log -1 --oneline
        '''
      }
    }

    stage('2) Build JAR') {
      steps {
        sh '''
          set -e
          mvn clean package -DskipTests
        '''
      }
    }

    stage('3) Build Docker Image') {
      steps {
        sh '''
          set -e
          GIT_SHA=$(git rev-parse --short HEAD)
          echo "${GIT_SHA}" > image.txt
          echo "IMAGE_TAG=${GIT_SHA}"

          docker build -t ${ECR_URI}:${GIT_SHA} .
        '''
      }
    }

    stage('4) Push Image to ECR') {
      steps {
        sh '''
          set -e
          IMAGE_TAG=$(cat image.txt)

          aws ecr get-login-password --region ${AWS_REGION} \
            | docker login --username AWS --password-stdin $(echo ${ECR_URI} | cut -d/ -f1)

          docker push ${ECR_URI}:${IMAGE_TAG}
        '''
      }
    }

    stage('5) Checkout Repo-2 (GitOps/Helm)') {
      steps {
        dir('gitops') {
          checkout([
            $class: 'GitSCM',
            branches: [[name: "*/${GITOPS_BRANCH}"]],
            userRemoteConfigs: [[
              url: "${GITOPS_REPO_URL}",
              credentialsId: 'git'
            ]]
          ])

          sh '''
            set -e
            echo "Repo-2 latest commit:"
            git log -1 --oneline
          '''
        }
      }
    }

    stage('6) Update values.yaml tag') {
      steps {
        sh '''
          set -e
          IMAGE_TAG=$(cat image.txt)

          cd gitops

          echo "Before:"
          grep -nE "^[[:space:]]*tag:" ${VALUES_FILE} || true

          # Simple + reliable replacement for YAML like: "  tag: v1"
          sed -i "s/^  tag: .*/  tag: ${IMAGE_TAG}/" ${VALUES_FILE}

          echo "After:"
          grep -nE "^[[:space:]]*tag:" ${VALUES_FILE} || true
        '''
      }
    }

    stage('7) Commit Repo-2 change') {
      steps {
        sh '''
          set -e
          cd gitops

          git config user.email "jenkins@local"
          git config user.name "jenkins"

          git add ${VALUES_FILE}

          # If nothing changed, don't fail
          git diff --cached --quiet && echo "No changes to commit" && exit 0

          git commit -m "deploy: $(cat ../image.txt)"
        '''
      }
    }

    stage('8) Push Repo-2') {
      steps {
        dir('gitops') {
          withCredentials([usernamePassword(credentialsId: 'git', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_TOKEN')]) {
            sh '''
              set -e
              git push https://${GIT_USER}:${GIT_TOKEN}@github.com/Bunny06022001/helm-repo-project-1.git HEAD:${GITOPS_BRANCH}
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
  }
}
