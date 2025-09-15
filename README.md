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
```
To create the external volumes, use the below commands.

```
docker volume create n8n_data
docker volume create qdrant_storage
docker volume create open-webui
docker volume create ollama
docker volume create photoprism
```

Start the stack
```
docker-compose up -d
```

Requires availability of the following ports:
```
3000
```

```
docker-compose -f docker-compose-nas.yaml up
```


## Images

This stack uses a combination of pre-built images from Docker Hub and custom-built images.

-   **n8n**: A custom-built image for workflow automation. The Dockerfile is located in the `n8n/` directory.
-   **qdrant**: The official `qdrant/qdrant` image for the vector database.
-   **OpenWebUi**: The `kheidencom/openwebui:latest` image is used as the application frontend. The `Getting Started` section mentions building an image from source, which is an alternative if you want to customize the OpenWebUi.
-   **ollama**: A custom-built image for the inference runtime. The Dockerfile is in the `ollama/` directory. This image is configured to download some default models on startup.
-   **photoprism**: The official `photoprism/photoprism:latest` image for multimedia management.
-   **mariadb**: The official `mariadb:11.4` image, used as the database for PhotoPrism.

## Using Existing Data

If you have existing data from another setup, you can copy it to the volumes used by this stack. This data can be in another Docker volume or inside a Docker image.

### From a Docker Volume

If your data is in another Docker volume (e.g., from a previous installation), you can copy it.

First, identify the name of the source volume. You can list your existing volumes with `docker volume ls`.

Let's say your old ollama volume is named `ollama_data_old` and you want to copy it to the `ollama_storage` volume used in this stack. You can use the following command:

```bash
docker run --rm \
  -v ollama_data_old:/from \
  -v ollama_storage:/to \
  alpine sh -c "cd /from ; cp -av . /to"
```

This command starts a temporary `alpine` container, mounts the old volume to `/from` and the new volume to `/to`, and then copies all the data.

### From a Docker Image

If you have an existing Docker image that contains data you want to use (e.g., an `ollama` image with pre-downloaded models), you can copy the data from the image into a volume used by this stack.

For example, to copy models from an image named `my-ollama:latest` to the `ollama_storage` volume:

```bash
docker run --rm \
  --entrypoint /bin/sh \
  -v ollama_storage:/to \
  my-ollama:latest -c "cp -av /root/.ollama/. /to/"
```

This command starts a temporary container from your existing image (`my-ollama:latest`), mounts the stack's `ollama_storage` volume to the `/to` directory, and then copies the data from `/root/.ollama` (the default location in ollama images) to the volume. You may need to adjust the source path (`/root/.ollama/`) depending on where the data is stored in your image.

### Copying Data Between Images

If you need to create a new Docker image by copying files from a source image to a destination image, you can use the `copy_image_data.sh` script included in this repository. This might be useful if you want to create a custom `ollama` image that includes models from another image.

The script uses a `docker run`-based workflow to:
1.  Start a temporary container from a source image.
2.  Copy the specified directory from it to the local filesystem.
3.  Start a temporary container from a destination image.
4.  Copy the data from the local filesystem into it.
5.  Commit the result as a new image with a new tag.

**Usage:**

```bash
./copy_image_data.sh <source_image> <path_in_source> <dest_image> <path_in_dest> <new_image_tag>
```

**Example:**

To copy models from an image named `my-ollama:latest` into the `ollama` image built by this stack (`ai-stack-ollama:latest`), creating a new image tagged `ollama:with-my-models`:

```bash
./copy_image_data.sh my-ollama:latest /root/.ollama/models ai-stack-ollama:latest /root/.ollama/models ollama:with-my-models
```

You would then need to update the `docker-compose.yaml` file to use your new `ollama:with-my-models` image in the `ollama` service.

## Future Updates

TODO: Acquire X free ports on host machine, create port variables for each, configure each container with environment variables which reference these available ports.

