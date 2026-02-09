# skill-scanner-docker

Dockerfile for [cisco-ai-defense/skill-scanner](https://github.com/cisco-ai-defense/skill-scanner) — a security scanner for AI Agent Skills that detects prompt injection, data exfiltration, and malicious code patterns.

## Build

Clone the skill-scanner source and copy the Dockerfile into it:

```bash
git clone https://github.com/cisco-ai-defense/skill-scanner.git
cp Dockerfile .dockerignore skill-scanner/
cd skill-scanner
```

Build the image:

```bash
docker build -t skill-scanner .
```

To set a specific version (the default is `0.0.0+docker`):

```bash
docker build --build-arg VERSION=1.2.3 -t skill-scanner .
```

## Usage

### Scan a skill

```bash
docker run --rm -v /path/to/skill:/scan/skill skill-scanner scan /scan/skill
```

### Scan with behavioral analysis

```bash
docker run --rm -v /path/to/skill:/scan/skill \
  skill-scanner scan /scan/skill --use-behavioral
```

### Scan with LLM analysis

```bash
docker run --rm \
  -e SKILL_SCANNER_LLM_API_KEY=your_api_key \
  -e SKILL_SCANNER_LLM_MODEL=claude-3-5-sonnet-20241022 \
  -v /path/to/skill:/scan/skill \
  skill-scanner scan /scan/skill --use-llm
```

### Scan multiple skills

```bash
docker run --rm -v /path/to/skills:/scan/skills \
  skill-scanner scan-all /scan/skills --recursive
```

### JSON output

```bash
docker run --rm -v /path/to/skill:/scan/skill \
  skill-scanner scan /scan/skill --format json
```

### Run the API server

```bash
docker run --rm -p 8000:8000 \
  --entrypoint skill-scanner-api \
  skill-scanner --host 0.0.0.0
```

The API docs are available at `http://localhost:8000/docs` and the health endpoint at `http://localhost:8000/health`.

### Pass environment variables via file

```bash
docker run --rm --env-file .env \
  -v /path/to/skill:/scan/skill \
  skill-scanner scan /scan/skill --use-llm
```

See [`.env.example`](https://github.com/cisco-ai-defense/skill-scanner/blob/main/.env.example) in the upstream repo for all available variables.

## Image details

| Property | Value |
|----------|-------|
| Base | `python:3.12-slim` |
| Size | ~600 MB |
| User | `scanner` (non-root) |
| Workdir | `/scan` |
| Exposed port | 8000 (API server) |
