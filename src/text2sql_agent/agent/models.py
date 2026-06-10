from langchain_openai import ChatOpenAI
from pydantic import BaseModel, Field

from text2sql_agent.config import MAMMOUTH_API_KEY, MAMMOUTH_BASE_URL
from .tools import tools



sql_model = ChatOpenAI(model="gpt-4.1", temperature=0.0, api_key=MAMMOUTH_API_KEY, base_url=MAMMOUTH_BASE_URL)
reflect_model =  ChatOpenAI(model="gpt-4.1-nano", temperature=0.0, api_key=MAMMOUTH_API_KEY, base_url=MAMMOUTH_BASE_URL)

class ReflectionVerdict(BaseModel):
    approved: bool = Field(description="True si la réponse répond correctement et complètement à la question, False sinon")
    critique: str = Field(default="", description="Ce qui manque ou est incorrect si non approuvé")

sql_model = sql_model.bind_tools(tools)
reflect_model = reflect_model.with_structured_output(ReflectionVerdict)
