# Local AI Stack

This includes:
- Inference runtime (ollama)
- Vector Database (qdrant)
- Application Frontend (OpenWebUi)
- Workflow Automation (n8n)
- Multimedia Management (photoprism)


## Getting Started
```
git clone ...
cd ai-stack
git clone https://github.com/open-webui/open-webui
docker build . -t home:webui
docker-compose up -d
```

Requires availability of the following ports:
```
3000
```

```
docker-compose -f docker-compose-nas.yaml up
```


## Future Updates

TODO: Acquire X free ports on host machine, create port variables for each, configure each container with environment variables which reference these available ports.

