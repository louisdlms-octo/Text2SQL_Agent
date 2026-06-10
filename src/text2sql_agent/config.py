import os
from dotenv import load_dotenv

load_dotenv()

MAMMOUTH_API_KEY = os.getenv("MAMMOUTH_API_KEY", "")
MAMMOUTH_BASE_URL = os.getenv("MAMMOUTH_BASE_URL", "https://api.mammouth.ai/v1")

PG_HOST = os.getenv("PG_HOST", "localhost")
PG_PORT = os.getenv("PG_PORT", "8001")
PG_USER = os.getenv("PG_USER", "postgres")
PG_PASSWORD = os.getenv("PG_PASSWORD", "password")
PG_DB = os.getenv("PG_DB", "ecommerce")
