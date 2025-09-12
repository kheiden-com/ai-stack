from typing import Union # Add this import at the top with other typing imports

from fastapi import FastAPI, HTTPException, Body, Request
from fastapi.middleware.cors import CORSMiddleware
import requests

from pydantic import BaseModel, Field
import os

app = FastAPI(
    title="kheiden-com Toolserver",
    version="1.0.0",
    description="An OpenAPI server for tools used by kheiden-com",
)

origins = ["*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class MediaResponse(BaseModel):
    result: dict = Field(..., description="The media found from the query")

class MediaRequest(BaseModel):
    query: str = Field(..., description="The query to use in order to find related media")

@app.post("/query_media", response_model=MediaResponse, summary="Query for related media")
def query_media(data: MediaRequest = Body(...)):
    headers = {
        "Cf-Access-Authenticated-User-Email": os.environ.get("USER_ID")
    }
    params = {
        "count": 10,
        "quality": 1,
        "q": data.query
    }
    result = requests.get("http://photoprism:2342/api/v1/photos", params=params, headers=headers)
    return MediaResponse(result=result.json())
