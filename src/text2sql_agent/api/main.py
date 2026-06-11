from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import mlflow

from text2sql_agent.agent.graph import compiled_agent

# Specify the tracking URI for the MLflow server.
mlflow.set_tracking_uri("http://localhost:5000")
# Specify the experiment you just created for your LLM application or AI agent.
mlflow.set_experiment("Text-to-SQL Agent")
# Enable automatic tracing for all langchain API calls.
mlflow.langchain.autolog()


app = FastAPI(title="Text2SQL Agent API")

class QueryRequest(BaseModel):
    message: str

class QueryResponse(BaseModel):
    response: str

@app.get("/health")
def health_check():
    return {"status": "ok"}

@app.post("/invoke", response_model=QueryResponse)
async def invoke_agent(req: QueryRequest):
    try:
        result = await compiled_agent.ainvoke(
            {"messages": [{"role": "user", "content": req.message}]}
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Agent error: {e}")
    return QueryResponse(response=result["messages"][-1].content)
