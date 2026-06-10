from langchain.tools import tool

from text2sql_agent.database.postgres_adapter import PostgresAdapter
from text2sql_agent.config import PG_HOST, PG_PORT, PG_USER, PG_PASSWORD, PG_DB


adapter = PostgresAdapter(connection_string=f"postgresql://{PG_USER}:{PG_PASSWORD}@{PG_HOST}:{PG_PORT}/{PG_DB}")

@tool
def list_tables() -> str:
    """Retourne la liste des tables présentes dans la base de données."""
    sql_query = "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';"
    result = adapter.execute_read_only_query(sql_query)
    if isinstance(result, str) :
        return result
    else : 
        rows = result[1]
        formatted_result = "## Liste des tables:\n" + "\n".join([f"- {row[0]}" for row in rows])
        return formatted_result

@tool
def get_table_schema(table_name: str) -> str:
    """Retourne le schéma de la table spécifiée, incluant les colonnes et leurs types."""
    sql_query = "SELECT column_name, data_type FROM information_schema.columns WHERE table_name = %s;"
    result = adapter.execute_read_only_query(sql_query, params=(table_name,))
    if isinstance(result, str) :
        return result
    else :
        rows = result[1]
        formatted_result = "## Liste des colonnes:\n" + "\n".join([f"- {row[0]}: {row[1]}" for row in rows])
        return formatted_result

@tool
def execute_sql_query(sql_query: str) -> str:
    """Exécute une requête SQL et retourne les résultats."""
    result = adapter.execute_read_only_query(sql_query)
    if isinstance(result, str):
        return result
    else :
        columns, rows = result
        header = "- " + " | ".join([str(col) for col in columns]) + " \n"
        body = " \n".join(["- " + " | ".join([str(v) for v in row]) for row in rows])
        formatted_result = f"## Résultats de la requête: \n{header}{body}"
        return formatted_result


tools = [list_tables, get_table_schema, execute_sql_query]
tools_by_name = {tool.name: tool for tool in tools}


