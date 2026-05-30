# Porting notes & operational lessons — go-graphstore

**Status:** This repository is being retired ("going dark"). Its information and
devops are to be ported into the Gene Ontology **main operations repo**. This file
is written for that port — especially an *automated* one reading this repo — to
capture the operational reality and the non-obvious lessons that the code, the
sample files, and even the canonical docs do not fully convey.

Canonical deployment procedure (authoritative, keep following it):
- https://github.com/geneontology/devops-documentation/blob/main/README.graphstore.md
- https://github.com/geneontology/devops-documentation/blob/main/README.setup.md

Everything below supplements those docs. Where a fact was directly verified during
a live production deploy, it is marked **(verified 2026-05-30)**; values quoted from
the canonical docs without independent check this session are marked **(per doc)**.

---

## 1. How a deploy actually runs (the parts not in the sample files)

- `go-deploy` does **not** run on the host. It lives inside the devops container
  image **`geneontology/go-devops-base:tools-jammy-0.4.4`**, which ships
  `go-deploy 0.4.4`, `terraform 1.7.1`, and **`ansible-core 2.16.3`**
  (verified 2026-05-30). The host only needs `docker` (plus `aws`/`terraform` for
  out-of-band checks).
- Two equivalent ways to get this repo + your edited configs into the container:
  1. **Clone fresh inside the container** (what the canonical doc does), then
     `docker cp` your `config-instance.yaml`, `config-stack.yaml`, and
     `aws/backend.tf` in; or
  2. **Bind-mount the host checkout** at run time:
     `docker run -d --name go-graphstore -v <repo>:/tmp/go-graphstore <image> sleep infinity`,
     then drive it with `docker exec`. This deploys exactly the local code and was
     used successfully on 2026-05-30. Terraform writes `.terraform/`, `*.tfvars.json`,
     and `*-inventory.cfg` back into the mounted checkout as **root-owned** files
     (cleanup may need `sudo`).
- Credentials/keys must be staged **inside the container** at exactly:
  `/tmp/go-aws-credentials`, `/tmp/go-ssh`, `/tmp/go-ssh.pub` (referenced by the
  config YAMLs). The AWS file must be in *credentials* format (`[default]` +
  `aws_access_key_id` / `aws_secret_access_key`). Note the GO creds were found
  inline in `~/.aws/config` `[default]` (not a separate `~/.aws/credentials`),
  so staging means extracting those two keys into a credentials-format file.
- Required env in every `docker exec` (shell state does not persist between execs):
  `AWS_SHARED_CREDENTIALS_FILE=/tmp/go-aws-credentials`, `AWS_REGION=us-east-1`,
  and `ANSIBLE_HOST_KEY_CHECKING=False` for the stack step.

## 2. Concrete production values (confirm against samples before reuse)

| Thing | Production value | Source |
|---|---|---|
| TF state bucket (`backend.tf`) | `go-workspace-graphstore` | verified 2026-05-30 |
| Route53 zone — geneontology.org | `Z04640331A23NHVPCC784` | verified 2026-05-30 |
| Route53 zone — berkeleybop.io (internal) | `ZNM42D2G0HNUI` | per doc |
| S3 logs bucket / prefix | `go-service-logs-graphstore-production` / `production-YYYY-MM-DD` | verified 2026-05-30 |
| SSL certs | `s3://go-service-lockbox/geneontology.org.tar.gz` | verified 2026-05-30 |
| Production journal | `http://current.geneontology.org/products/blazegraph/blazegraph-production.jnl.gz` | verified 2026-05-30 |
| Server name / alias | `rdf.geneontology.org` / `graphstore-production-YYYY-MM-DD.geneontology.org` | verified 2026-05-30 |
| Instance | `m5.large`, 150 GB disk, `MEM: 7G` | verified 2026-05-30 |
| Images | `geneontology/go-graphstore:v1`, `geneontology/apache-proxy:v6` | sample defaults |
| Journal size (May 2026) | ~9.25 GB gzip → ~46 GB uncompressed | verified 2026-05-30 |

`S3_BUCKET`/`S3_PREFIX`/`S3_PATH`/`USE_S3` feed the **apache-proxy** container's
`logrotate-to-s3` (Apache log archival), *not* the graphstore container — and only
when `USE_S3=1`.

## 3. Known issues / lessons learned

### 3a. `stat` task fails: `get_md5` removed in ansible-core 2.16
`provision/stage.yaml`'s "Check if journal exists" task passed `get_md5: False`,
removed from the `stat` module in ansible-core 2.16 (shipped by the current devops
image). It aborts the stack play before the journal is staged. Fix: drop that one
line — `get_checksum: False` already disables checksumming, so it is
behavior-preserving. (Fixed in go-graphstore PR #37.) **Port lesson:** audit all
playbooks for parameters removed in modern Ansible, not just this one.

### 3b. `get_url` checksum stalls large-journal downloads (still unfixed)
The journal download **succeeds**, but Ansible `get_url`'s post-download checksum
pass on a ~9 GB file runs far longer than the playbook's `async_status` poll window
(`retries: 45 × delay: 20s` = **15 min**), so the play fails even though the file
is fully on disk. This is the single biggest deploy hazard.

- **Do not** be misled into thinking the EBS volume is slow: raw `dd` direct I/O
  measured **~100 MB/s read & write** (verified 2026-05-30). The ~4 MB/s seen
  during the hang was `get_url`'s read pattern, not the disk.
- **Manual rescue that worked (2026-05-30):** hard-link/preserve the completed
  download out of Ansible's temp dir, `unpigz`/`gunzip` it to
  `<stage_dir>/blazegraph.jnl`, then re-run the stack. `stage.yaml` guards the
  download **and** unpack tasks with `when: not journal_result.stat.exists`, keyed
  on the **unzipped** `blazegraph.jnl` — so once that file exists, both steps are
  skipped and the deploy proceeds straight to config + service start.
- **Proper fix for the port:** widen the `async_status` window, skip the redundant
  checksum, or download via a streaming method that doesn't re-read the whole file.

### 3c. Production cutover happens at **Cloudflare**, not Route53
`rdf.geneontology.org` is a **CNAME to `rdf.geneontology.org.cdn.cloudflare.net`**
(verified 2026-05-30) — it sits behind Cloudflare. Consequences:
- Terraform/Route53 only manages the **per-instance dated** record
  (`graphstore-production-YYYY-MM-DD.geneontology.org`, an A record in zone
  `Z04640331A23NHVPCC784`). It does **not** manage `rdf`.
- Going live ("cutover") is changing the **Cloudflare origin** to the new instance.
  That step is outside this repo's terraform and outside `go-deploy`.
- `config-stack.yaml` ships `USE_CLOUDFLARE: 0` even though the endpoint is fronted
  by Cloudflare; revisit this during the port if Cloudflare-aware handling
  (real client IP, etc.) is wanted.

### 3d. Verifying a cutover when the origin is hidden behind Cloudflare
Public DNS only shows Cloudflare IPs, so you cannot read the origin directly.
Technique that worked: send a uniquely-marked request through `rdf.geneontology.org`
(e.g. `https://rdf.geneontology.org/<unique-token>`), then `grep` that token in each
candidate instance's Apache access log
(`/home/ubuntu/stage_dir/apache_logs/graphstore-access.log`). The instance that logs
it is the live origin. Cross-check with log recency (the live origin keeps receiving
Cloudflare traffic; retired ones go quiet).

## 4. Teardown safety (retiring an old instance)

- Terraform **workspaces are independent**; each production instance lives in its own
  workspace (`production-YYYY-MM-DD`) with its own state.
- Before destroying, prove isolation with a read-only plan:
  `terraform -chdir=aws workspace select <ws> && terraform -chdir=aws plan -destroy`.
  A healthy retire target shows **`Plan: 0 to add, 0 to change, 6 to destroy`** — and
  the only DNS record removed is that instance's **own dated hostname**, never `rdf`.
  All `main.tf` variables have defaults, so the plan needs no tfvars file.
- `go-deploy --workspace <ws> --working-directory aws -destroy -verbose` removes the
  6 resources **and deletes the workspace** (verified 2026-05-30).
- **Hot-backup policy:** always keep the immediately-previous production instance
  running as a fallback; only retire instances older than that.

## 5. Service shape on the instance (for health checks / debugging)

- `docker-compose` stack at `/home/ubuntu/stage_dir/docker-compose.yaml`: containers
  `graphstore` (Blazegraph) and `apache_graphstore` (proxy, ports 80/443).
- Blazegraph listens on `8899` **only on the internal docker network** — it is not
  published to the instance host, so `curl localhost:8899` from the host returns
  nothing; reach it through the proxy (`-H 'Host: rdf.geneontology.org'`).
- SPARQL endpoint: `/blazegraph/namespace/kb/sparql` (the proxy also serves
  `/sparql`). A trivial `SELECT ?s ?p ?o WHERE { ?s ?p ?o } LIMIT 1` confirms data
  loaded; broad unbounded queries (e.g. `COUNT(DISTINCT ?g)`) intentionally hit the
  query-deadline timeout configured in `conf/readonly_cors.xml` — that is QoS working,
  not a failure.
