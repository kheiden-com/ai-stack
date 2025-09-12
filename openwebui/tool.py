import os
import requests
from datetime import datetime
from pydantic import BaseModel, Field


class Tools:
    class Valves(BaseModel):
        tool_server: str = Field(
            default="http://host.docker.internal:8000",
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
                        "name": "Tool Server",
                        "url": f"https://chat.kheiden.com",
                    },
                },
            }
        )
        return data

    async def query_media(self, __event_emitter__=None):
        try:
            return self.notify(
                __event_emitter__,
                data=requests.post(
                    f"http://toolserver:8000/query_media"
                ).json(),
            )
        except Exception as e:
            self.notify(__event_emitter__, e)
            return e
