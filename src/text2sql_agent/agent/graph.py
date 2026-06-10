from langchain.messages import SystemMessage, ToolMessage, HumanMessage
from langgraph.graph.message import MessagesState
from langgraph.graph import StateGraph, START, END
from typing import Literal


from .models import sql_model, reflect_model
from .prompts import SQL_SYSTEM_PROMPT, REFLECTION_SYSTEM_PROMPT
from .tools import tools_by_name


class AgentState(MessagesState):
    sql_model_calls: int = 0
    reflect_count: int = 0 
    max_reflects: int = 3
    reflect_approved: bool = False
    

## Nodes and edges of the graph

def sql_node(state: AgentState):
    return {
        "messages": [
            sql_model.invoke(
                [
                    SystemMessage(
                        content=SQL_SYSTEM_PROMPT
                    )
                ]
                + state["messages"]
            )
        ],
        "sql_model_calls": state.get("sql_model_calls", 0) + 1
    }

def tool_node(state: AgentState):
    """Performs the tool call"""

    result = []
    for tool_call in state["messages"][-1].tool_calls:
        tool = tools_by_name[tool_call["name"]]
        observation = tool.invoke(tool_call["args"])
        result.append(ToolMessage(content=observation, tool_call_id=tool_call["id"]))
    return {"messages": result}



def should_continue(state: AgentState) -> Literal["tool_node", "reflect_node"]:
    """Decide if we should continue the loop or stop based upon whether the LLM made a tool call"""

    messages = state["messages"]
    last_message = messages[-1]

    # If the LLM makes a tool call, then perform an action
    if last_message.tool_calls:
        return "tool_node"

    # Otherwise, we send the response to reflect node
    return "reflect_node"



def reflect_node(state: AgentState):
    verdict = reflect_model.invoke([SystemMessage(content=REFLECTION_SYSTEM_PROMPT)] + state["messages"])
    return {
        "messages": [HumanMessage(content=verdict.critique)] if not verdict.approved else [],
        "reflect_count": state.get("reflect_count", 0) + 1,
        "reflect_approved": verdict.approved,
    }
    
def should_end(state: AgentState) -> Literal["sql_node", END]:
    """Decide if we should continue reflecting or stop based upon whether the reflection was approved"""

    if state.get("reflect_approved", False):
        return END
    elif state.get("reflect_count", 0) >= state.get("max_reflects", 3):
        return END
    else:
        return "sql_node"


## Graph construction

# Build workflow
agent_builder = StateGraph(AgentState)

# Add nodes
agent_builder.add_node("sql_node", sql_node)
agent_builder.add_node("tool_node", tool_node)
agent_builder.add_node("reflect_node", reflect_node)

# Add edges to connect nodes
agent_builder.add_edge(START, "sql_node")
agent_builder.add_conditional_edges(
    "sql_node",
    should_continue,
    ["tool_node", "reflect_node"]
)
agent_builder.add_edge("tool_node", "sql_node")
agent_builder.add_conditional_edges(
    "reflect_node",
    should_end,
    ["sql_node", END]
)

# Compile the agent
compiled_agent = agent_builder.compile()

