#!/usr/bin/env bash
# =============================================================================
# Déploiement local (CD) : récupère une image construite par la CI sur ghcr.io
# et la déploie sur minikube.
#
# Usage :
#   ./scripts/deploy.sh          -> déploie le dernier commit de origin/main
#   ./scripts/deploy.sh <sha>    -> déploie un commit précis
# =============================================================================
set -euo pipefail

cd "$(dirname "$0")/.."

IMAGE="ghcr.io/louisdlms-octo/text2sql-api"
MINIKUBE_PROFILE="${MINIKUBE_PROFILE:-minikube}"

SHA="${1:-}"
if [[ -z "$SHA" ]]; then
  git fetch origin main --quiet
  SHA="$(git rev-parse origin/main)"
fi

echo "==> Déploiement de $IMAGE:$SHA"

# Lit une variable dans le .env local (gère "KEY=val" et "KEY = val")
read_env() {
  sed -n -E "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*//p" .env | head -1 \
    | sed -E 's/[[:space:]]+$//' | tr -d '"' | tr -d "'"
}

# On parle au docker DE minikube : l'image téléchargée atterrit directement
# dans le cluster (du coup, pas besoin d'imagePullSecret côté Kubernetes).
eval "$(minikube -p "$MINIKUBE_PROFILE" docker-env)"

# Le package ghcr.io est privé par défaut : on s'authentifie avec le token gh
gh auth token | docker login ghcr.io -u louisdlms-octo --password-stdin >/dev/null

docker pull "$IMAGE:$SHA"

# Le Secret Kubernetes est créé depuis le .env local (jamais commité) :
# les secrets ne transitent plus par GitHub.
kubectl create secret generic text2sql-api-secrets \
  --from-literal=MAMMOUTH_API_KEY="$(read_env MAMMOUTH_API_KEY)" \
  --from-literal=PG_PASSWORD="$(read_env PG_PASSWORD)" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/service.yaml
# On remplace le tag "dev" du manifest par l'image exacte du commit déployé
sed "s|text2sql-api:dev|$IMAGE:$SHA|" k8s/deployment.yaml | kubectl apply -f -

kubectl rollout status deployment/text2sql-api --timeout=180s

echo "==> OK : $IMAGE:$SHA déployé."
echo "    Pour ouvrir l'API : minikube -p $MINIKUBE_PROFILE service text2sql-api --url"
