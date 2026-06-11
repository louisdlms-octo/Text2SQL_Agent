# ---- Image de l'API FastAPI (agent Text-to-SQL) ----
# On part d'une image Python 3.12 légère
FROM python:3.12-slim

# On récupère "uv" (ton gestionnaire de paquets) depuis son image officielle
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

# Dossier de travail dans le conteneur
WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy

# 1) On copie SEULEMENT les fichiers de dépendances et on installe les deps.
#    Tant que ces 2 fichiers ne changent pas, Docker réutilise le cache
#    et ne réinstalle pas tout à chaque build.
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-install-project --no-dev --extra postgres

# 2) On copie le reste du code (le .dockerignore filtre le superflu),
#    puis on installe le projet lui-même
COPY . .
RUN uv sync --frozen --no-dev --extra postgres

# On met le venv dans le PATH pour pouvoir lancer "uvicorn" directement
ENV PATH="/app/.venv/bin:$PATH"

# L'API écoute sur le port 8000
EXPOSE 8000

# Commande lancée au démarrage du conteneur : on démarre le serveur uvicorn
CMD ["uvicorn", "text2sql_agent.api.main:app", "--host", "0.0.0.0", "--port", "8000"]
