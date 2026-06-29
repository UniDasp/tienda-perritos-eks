name: CI/CD Tienda Perritos EKS

on:
  push:
    branches: [ main ]
  workflow_dispatch: {}

env:
  ECR_REPO_FRONTEND: tienda-frontend
  ECR_REPO_BACKEND: tienda-backend
  ECR_REPO_DB: tienda-db

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout código
        uses: actions/checkout@v4

      - name: Configurar credenciales AWS
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ secrets.AWS_REGION }}
          aws-session-token: ${{ secrets.AWS_SESSION_TOKEN }}

      - name: Login a Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2

      - name: Definir tag de imagen
        run: echo "IMAGE_TAG=${GITHUB_SHA::7}" >> $GITHUB_ENV

      # --- Builds ---
      - name: Build & push imágenes
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
        run: |
          docker build -t $ECR_REGISTRY/${ECR_REPO_FRONTEND}:${IMAGE_TAG} ./frontend
          docker push $ECR_REGISTRY/${ECR_REPO_FRONTEND}:${IMAGE_TAG}
          docker build -t $ECR_REGISTRY/${ECR_REPO_BACKEND}:${IMAGE_TAG} ./backend
          docker push $ECR_REGISTRY/${ECR_REPO_BACKEND}:${IMAGE_TAG}
          docker build -t $ECR_REGISTRY/${ECR_REPO_DB}:${IMAGE_TAG} ./db
          docker push $ECR_REGISTRY/${ECR_REPO_DB}:${IMAGE_TAG}

      # --- Despliegue ---
      - name: Configurar kubeconfig
        run: |
          aws eks update-kubeconfig --region ${{ secrets.AWS_REGION }} --name ${{ secrets.EKS_CLUSTER_NAME }}

      - name: Desplegar aplicaciones
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          NS: ${{ secrets.EKS_NAMESPACE }}
        run: |
          kubectl apply -f k8s/namespace.yaml
          kubectl apply -f k8s/mysql-secret.yaml -n $NS
          
          # DB
          kubectl delete deployment tienda-db -n $NS --ignore-not-found
          sed -i "s|image: .*|image: $ECR_REGISTRY/${ECR_REPO_DB}:${IMAGE_TAG}|g" k8s/mysql-deployment.yaml
          kubectl apply -f k8s/mysql-deployment.yaml -f k8s/mysql-service.yaml -n $NS
          
          # BACKEND
          kubectl delete deployment tienda-backend -n $NS --ignore-not-found
          sed -i "s|image: .*|image: $ECR_REGISTRY/${ECR_REPO_BACKEND}:${IMAGE_TAG}|g" k8s/backend-deployment.yaml
          kubectl apply -f k8s/backend-deployment.yaml -f k8s/backend-service.yaml -n $NS
          
          # FRONTEND
          kubectl delete deployment tienda-frontend -n $NS --ignore-not-found
          sed -i "s|image: .*|image: $ECR_REGISTRY/${ECR_REPO_FRONTEND}:${IMAGE_TAG}|g" k8s/frontend-deployment.yaml
          kubectl apply -f k8s/frontend-deployment.yaml -f k8s/frontend-service.yaml -n $NS

      - name: Verificar rollouts
        run: |
          kubectl rollout status deployment/tienda-db -n ${{ secrets.EKS_NAMESPACE }}
          kubectl rollout status deployment/tienda-backend -n ${{ secrets.EKS_NAMESPACE }}
          kubectl rollout status deployment/tienda-frontend -n ${{ secrets.EKS_NAMESPACE }}
