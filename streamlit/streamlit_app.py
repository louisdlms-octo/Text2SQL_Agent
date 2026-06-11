import os

import requests
import streamlit as st

API_URL = os.getenv("API_URL", "http://localhost:8000")

st.set_page_config(
    page_title="POC Chatbot E-commerce",
    page_icon="🤖",
    layout="wide",
)

st.title("🤖 POC Chatbot E-commerce")
st.caption("Interface Streamlit simple pour discuter avec l'agent LangGraph")


if "messages" not in st.session_state:
    st.session_state.messages = []

for message in st.session_state.messages:
    with st.chat_message(message["role"]):
        st.markdown(message["content"])


user_prompt = st.chat_input("Posez votre question à l'agent...")

if user_prompt:
    st.session_state.messages.append({"role": "user", "content": user_prompt})

    with st.chat_message("user"):
        st.markdown(user_prompt)

    with st.chat_message("assistant"):
        with st.spinner("Agent Text-to-SQL en cours de réflexion..."):
            r = requests.post(f"{API_URL}/invoke", json={"message": user_prompt}, timeout=120)
            answer = r.json()["response"]
        st.markdown(answer)

    st.session_state.messages.append({"role": "assistant", "content": answer})
