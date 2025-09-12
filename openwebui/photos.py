import os
import requests
from datetime import datetime
from pydantic import BaseModel, Field


class Tools:
    class Valves(BaseModel):
        tool_server: str = Field(
            default="http://photoprism:2342/api/v1/photos",
            description="Toolserver fully qualified URL.",
            json_schema_extra={"secret": True},
        )

    def __init__(self, v=None):
        self.valves = v or self.Valves()
        pass

    def notify(self, __event_emitter__, data):
        __event_emitter__(
            {
                "type": "citation",
                "data": {
                    "document": [data],
                    "metadata": [
                        {
                            "date_accessed": datetime.now().isoformat(),
                            "source": "Tool Server",
                        }
                    ],
                    "source": {
                        "name": "Photoprism",
                        "url": f"http://localhost:2342.com/",
                    },
                },
            }
        )
        return data

    async def get_related_documents(self, query, __event_emitter__=None):
        headers = {
            "Authorization ": "Bearer mwLut0-MolB3Y-PEgVH4-ObN6DE"
        }
        params = {
            "q": query,
            "count": 10,
            "quality": 1
        }
        try:
            return self.notify(
                __event_emitter__,
                data=requests.get(
                    f"http://photoprism:2342/api/v1/photos",
                    headers=headers,
                    params=params
                ).json(),
            )
        except Exception as e:
            self.notify(__event_emitter__, e)
            return e
