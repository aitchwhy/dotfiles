---
description: Local GitHub Actions Testing
---

# Local GitHub Actions Testing

We use [act](https://github.com/nektos/act) to simulate GitHub Actions locally. This allows for rapid feedback cycles without waiting for remote CI/CD pipelines.

## Setup

1.  Ensure `act` is installed (it's part of the standard environment).
2.  The configuration is managed in `config/act/actrc`.

## Usage

We have added `just` commands to simplify usage.

### List Available Jobs

```bash
just gha-list
```

### Run a Specific Job

```bash
just gha -j job_name
```

Example:

```bash
just gha -j brain-tests
```

### Run All Jobs

```bash
just gha
```

### Watch Mode (Iterative Testing)

Run a job automatically whenever files change:

```bash
just gha-watch job_name
```

## Troubleshooting

- **Image Architectures**: We force `linux/amd64` to avoid issues with Apple Silicon.
- **Secrets**: If your job needs secrets, creating a `.secrets` file in the root is the standard `act` way, or passing `-s SECRET=value` flags via `gha`.
