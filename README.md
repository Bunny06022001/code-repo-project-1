# Project-1: Commit → Prod (Jenkins CI + ECR + ArgoCD GitOps on EKS)

## What this project demonstrates
A production-style GitOps pipeline on AWS:

- Developer pushes code to **Repo-1**
- **Jenkins** builds the app JAR, builds a Docker image, pushes to **AWS ECR**
- Jenkins updates **Repo-2 (Helm GitOps repo)** with the new image tag (commit SHA)
- **ArgoCD** auto-syncs and deploys to **EKS**
- App is served via **Kubernetes Service (NodePort)**

## Architecture (high-level)
Repo-1 (App) ──push──> Jenkins ──build/push──> ECR
                          │
                          └──commit tag update──> Repo-2 (Helm GitOps)
                                                   │
                                                   └──ArgoCD auto-sync──> EKS

## Tech stack
- AWS: EKS, ECR, EC2 (Jenkins)
- CI: Jenkins (Pipeline as Code - Jenkinsfile)
- CD: ArgoCD (GitOps)
- Packaging: Maven
- Deploy: Helm chart (Repo-2)

## Pipeline flow (what happens on each push)
1. Checkout Repo-1
2. `mvn clean package -DskipTests`
3. `docker build` (tag = Git commit SHA)
4. Push image to ECR
5. Checkout Repo-2 (Helm GitOps)
6. Update `values.yaml` image tag to the new SHA
7. Commit + push Repo-2
8. ArgoCD detects change and deploys automatically

## Repositories
- Repo-1 (this repo): application source + Dockerfile + Jenkinsfile  
- Repo-2 (GitOps/Helm): https://github.com/Bunny06022001/helm-repo-project-1

## Rollback strategy
- Revert the GitOps commit in Repo-2 (values.yaml tag) and ArgoCD auto-rolls back
