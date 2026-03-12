# n8n setup with docker in docker (dind)

### Dind container

```
docker run --privileged --name docker -d -v certs:/certs --restart=always docker:dind

```

### n8n custom image

For docker cli

```
FROM docker.n8n.io/n8nio/n8n

USER root

COPY --from=docker:cli /usr/local/bin/docker /usr/local/bin/docker

RUN chmod +x /usr/local/bin/docker

RUN addgroup -g 989 docker && addgroup node docker

USER node

```

### n8n container

```
docker run -d --restart=always --name n8n -p 5678:5678 --env DOCKER_HOST=tcp://docker:2376 --env DOCKER_TLS_VERIFY=1 --env DOCKER_CERT_PATH=/certs/client -v certs:/certs --link docker -e WEBHOOK_URL=<n8n-public-url> -e GENERIC_TIMEZONE="Europe/Zurich" -e TZ="Europe/Zurich" -e N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true -e NODES_EXCLUDE="[]" -v n8n_data:/home/node/.n8n n8n-with-dockercli:latest

```
