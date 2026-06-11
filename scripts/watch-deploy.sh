#!/usr/bin/env bash
# =============================================================================
# Watcher (CD pull-based) : surveille origin/main et, dès qu'un nouveau commit
# est poussé ET que la CI a fini de publier son image, redéploie sur minikube.
#
# C'est ta machine qui interroge GitHub (comme un "git pull"), jamais
# l'inverse : aucun service n'écoute sur ton poste.
#
# Usage :
#   ./scripts/watch-deploy.sh                (Ctrl+C pour arrêter)
#   INTERVAL=30 ./scripts/watch-deploy.sh    (vérifie toutes les 30s)
# =============================================================================
set -euo pipefail

cd "$(dirname "$0")/.."

INTERVAL="${INTERVAL:-60}"
WORKFLOW="build.yml"

# Tag de l'image actuellement déployée dans le cluster (vide si rien)
deployed_sha() {
  { kubectl get deployment text2sql-api \
      -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || true; } \
    | sed 's/.*://'
}

# La CI du commit $1 s'est-elle terminée avec succès ?
ci_success() {
  [[ "$(gh run list --workflow "$WORKFLOW" --commit "$1" \
        --json status,conclusion \
        --jq '[.[] | select(.status == "completed" and .conclusion == "success")] | length' \
        2>/dev/null || echo 0)" -gt 0 ]]
}

echo "==> Surveillance de origin/main toutes les ${INTERVAL}s (Ctrl+C pour arrêter)"
while true; do
  if git fetch origin main --quiet 2>/dev/null; then
    TARGET="$(git rev-parse origin/main)"
    CURRENT="$(deployed_sha)"
    if [[ "$TARGET" != "$CURRENT" ]]; then
      if ci_success "$TARGET"; then
        echo "==> [$(date '+%H:%M:%S')] nouveau commit ${TARGET:0:7} : déploiement…"
        ./scripts/deploy.sh "$TARGET" \
          || echo "!!  déploiement échoué, nouvel essai dans ${INTERVAL}s"
      else
        echo "…   [$(date '+%H:%M:%S')] commit ${TARGET:0:7} détecté, CI pas encore terminée"
      fi
    fi
  fi
  sleep "$INTERVAL"
done
