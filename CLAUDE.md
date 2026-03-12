# CLAUDE.md

## Project overview

go-graphstore is the Gene Ontology's Blazegraph SPARQL endpoint service. It packages Blazegraph into a Docker container behind an Apache reverse proxy and deploys it to AWS EC2 instances using Terraform and Ansible.

The service runs at `rdf.geneontology.org` (production) and `rdf-internal.berkeleybop.io` (internal).

## Repository structure

- `docker/Dockerfile` — Multi-stage build: Maven/OpenJDK 8 builder, openjdk:8-jre runtime. Exposes port 8899.
- `conf/` — Blazegraph configuration (readonly_cors.xml for CORS and query timeouts).
- `provision/` — All deployment infrastructure:
  - `aws/main.tf` — Terraform config, uses module from `geneontology/devops-aws-go-instance` (ref V3.1).
  - `build_images.yaml`, `stage.yaml`, `start_services.yaml`, `down_services.yaml` — Ansible playbooks.
  - `vars.yaml`, `ssl-vars.yaml`, `qos-vars.yaml` — Ansible variables.
  - `templates/` — Jinja2 templates for docker-compose, Apache vhosts, QoS, Blazegraph config.
  - `production/` — Production config samples. See [canonical deployment docs](https://github.com/geneontology/devops-documentation/blob/main/README.graphstore.md) for production procedures; general devops setup (credentials, environment) is at [README.setup.md](https://github.com/geneontology/devops-documentation/blob/main/README.setup.md).
- `pom.xml` — Maven project: blazegraph-jar 2.1.4, jetty-servlets 9.2.3.
- `Makefile` — Local build and Blazegraph loading targets.
- `.github/workflows/aws_test.yaml` — CI/CD: provisions a test instance on push to master.

## Deployment

Canonical deployment documentation lives at:
https://github.com/geneontology/devops-documentation/blob/main/README.graphstore.md

Key points:
- `go-deploy` is the high-level deployment tool for day-to-day operations. Use it for provisioning, deploying stacks, inspecting state, and destroying instances.
- Raw `terraform` commands are for lower-level debugging only.
- Two deployment tracks: **production** (geneontology.org) and **internal** (berkeleybop.io).
- Workspace naming convention: `production-YYYY-MM-DD` or `internal-YYYY-MM-DD`.
- Config sample files use unique `REPLACE_ME_*` placeholders (e.g. `REPLACE_ME_S3_STATE_BUCKET`, `REPLACE_ME_DNS_ZONE_ID`). Each placeholder is self-documenting. Always scan for remaining placeholders before deploying: `grep -rn 'REPLACE_ME_' config-stack.yaml config-instance.yaml ssl-vars.yaml vars.yaml aws/backend.tf`

## Related repositories

- [devops-documentation](https://github.com/geneontology/devops-documentation) — Canonical deployment docs (README.graphstore.md). Checked out at `../devops-documentation`.
- [devops-aws-go-instance](https://github.com/geneontology/devops-aws-go-instance) — Terraform module for AWS EC2 provisioning (consumed via `main.tf`).
- [devops-apache-proxy](https://github.com/geneontology/devops-apache-proxy) — Apache reverse proxy Docker image (consumed at deploy time).
- [devops-deployment-scripts](https://github.com/geneontology/devops-deployment-scripts) — Builds the `geneontology/go-devops-base` Docker image used as the devops environment.

## Build and test

Local build (requires Maven, Java 8):
```
make all
make load-blazegraph
```

CI runs on push to master via `.github/workflows/aws_test.yaml` — provisions a test instance, verifies the service responds, then destroys it.

## Important conventions

- The default instance user is `ubuntu`.
- Docker container name for devops work: `go-graphstore`.
- Credentials and SSH keys go in `/tmp/` inside the devops container (see README.setup.md).
- Never commit credentials, SSH keys, or `backend.tf` files (covered by `.gitignore`).
- **When generating deployment commands, always read the actual sample files** (e.g. `production/backend.tf.sample`, `production/config-instance.yaml.sample`, `production/config-stack.yaml.sample`) to determine exact placeholder names and file structure. Do not rely on documentation alone — the docs may use different placeholder names than the files. The sample files are the source of truth.
- The `config-stack.yaml` (from `config-stack.yaml.sample`) bundles overrides for SSL, S3, and other vars — when it is used, editing `vars.yaml` and `ssl-vars.yaml` separately is not needed for values already present in the stack config.
- **When generating command lists for the user**, clearly distinguish between commands that can be copy-pasted verbatim and those that require user-specific values. Specifically:
  - The path to the AWS credentials file on the host machine is user-specific — always ask or confirm.
  - The path to SSH keys on the host machine is user-specific — always ask or confirm.
  - The `docker cp` commands for copying credentials into the container require the user's host paths.
  - The environment exports (`AWS_SHARED_CREDENTIALS_FILE`, `AWS_REGION`, `ANSIBLE_HOST_KEY_CHECKING`) must appear before any commands that depend on them — do not assume they carry over from a previous step description.
  - All other commands (sed substitutions, go-deploy, grep checks) can be copy-pasted verbatim once the date and track are known.
