# Splitting this folder into its own GitHub repository

While this project lives inside the `X4G` repository, GitHub cannot create a new
repository for it. Three ways to give it a repository of its own — all keep the
full commit history.

## Option A · `publish.sh` (one command, easiest)

From a copy of this folder on your own machine, where the GitHub CLI is
authenticated as **you**:

```bash
./publish.sh                 # creates a public  github.com/<you>/herald-agent-railway
./publish.sh my-agent        # custom repository name
./publish.sh my-agent --private
./publish.sh --dry-run       # run every check, print the commands, change nothing
```

The script verifies your tooling, refuses to publish anything that looks like a
credential, initialises a repository if the folder is not one yet, and never
force-pushes over an existing repository — if the repo already exists it just
pushes to it.

## Option B · `git subtree split` (no extra tooling)

```bash
# from a fresh clone of X4G, on the branch that contains this folder
git clone https://github.com/<you>/X4G.git && cd X4G
git checkout arena/01a0a682-x4g

# extract just this folder, with its history, onto a new branch
git subtree split -P herald-agent-railway -b herald-main

# create an empty repo on GitHub named herald-agent-railway, then:
git remote add herald https://github.com/<you>/herald-agent-railway.git
git push herald herald-main:main
```

The new repository then contains only this project, with the commits that
touched it.

## Option C · restore from the bundle (keeps this project's own history)

This is the only option that preserves the project's *own* commits (Option B
keeps the monorepo's commit messages instead). The bundle is a single
self-contained file — every branch, no working tree needed:

```bash
# download it (it sits next to this folder, in the X4G repository root)
curl -LO https://github.com/<you>/X4G/raw/arena/01a0a682-x4g/herald-agent-railway.bundle

git clone herald-agent-railway.bundle herald-agent-railway
cd herald-agent-railway
git remote remove origin 2>/dev/null || true
git remote add origin https://github.com/<you>/herald-agent-railway.git
git push -u origin main
```

The bundle is a **snapshot**, not a source of truth. If the code changes, it is
regenerated from the project repository with:

```bash
git bundle create herald-agent-railway.bundle --all
git bundle verify herald-agent-railway.bundle   # always sanity-check it
```

## Deploying *before* the split (straight from the monorepo folder)

Connect Railway to `X4G` and set **Service → Settings → Source → Root Directory**
to `herald-agent-railway`. Railway then builds this project's Dockerfile and
leaves the rest of the repository alone.

⚠️ Do not point a Railway service at the repository root: the root Dockerfile
belongs to the X4G gateway, which is a proxy-style workload — exactly the kind
of service Railway's acceptable-use policy prohibits, and the reason accounts
get suspended. Keep the two workloads on separate services (or separate
projects) so one cannot take the other down with it.

## After the split

1. Delete the `.git`-less copy here, or keep it as a monorepo folder — your choice.
2. In the new repository, connect Railway to that repo instead of this one
   (Service → Settings → Source), so deploys build the Herald Dockerfile.
3. `railway config plan` then `railway config apply` to let
   `.railway/railway.ts` manage the service and its volume.
4. Optional: generate a Railway template from the project and paste the slug
   into the commented-out Deploy button in `README.md`.

## Note on history

The project's real history lives in its own repository — the bundle in Option C
carries all of it, on a `main` branch with project-scoped (not monorepo)
commits. Everything under `X4G/herald-agent-railway/` is a mirror so the code is
reachable on GitHub in the meantime.
