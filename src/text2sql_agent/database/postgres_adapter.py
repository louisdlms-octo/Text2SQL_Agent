import psycopg

class PostgresAdapter:
    def __init__(self, connection_string: str):
        self.connection_string = connection_string

    def execute_read_only_query(self, sql: str, params: tuple | None = None):
        try:
            with psycopg.connect(self.connection_string) as conn:
                conn.read_only = True
                with conn.cursor() as cur:
                    cur.execute(sql, params)
                    columns = [col.name for col in cur.description]
                    rows = cur.fetchall()
                    return columns, rows
        except Exception as e:
            return f"Error executing query: {e}"

        

