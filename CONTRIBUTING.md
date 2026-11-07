# Contributing to ramen-projects

This repository holds the project content of the RAMEN apps (`projects/<project>/<tool>/…`) and the import scripts
(`imports/<project>/`). Projects: `abbw`, `sbwi`, `ri`. Tools: `shoyu`, `miso` and the gcore files read by tori and miso.

## From dev to production

| Branch | Deploys to                                                                         |
| ------ | ---------------------------------------------------------------------------------- |
| `dev`  | development and staging, each for its **locked project**                           |
| `main` | each project to its production host: abbw → antjebrons, sbwi → sbwi, ri → riserver |

Every change goes to `dev` first. `main` only accepts pull requests with an approval from a code owner of the changed
files (`.github/CODEOWNERS`).

**Before a pull request into `main` is merged, every changed project file must have been tested on the staging
server.** Staging shows one project at a time: lock the project you changed on staging, check the result there, and
only then merge.

## Locking a project on staging or development

Actions → **Deploy** → Run workflow, on branch `dev`:

- environment `staging` (or `development`), project `sbwi`: locks sbwi and copies its whole content there. From then on
  every `dev` change to sbwi goes there automatically.
- project `locked`: copies the locked project again in full.

Lock the environment back to the project its database holds (abbw on staging and development today) when you're done:
locking only switches the files, not the data. Production can be redeployed by hand the same way, run on `main`: it syncs all three production hosts.

## Checks

Every deploy and every pull request checks that all JSON files under `projects/` parse; a broken file never reaches a
host. Only files whose content changed are copied; tori and miso restart when their gcore files changed.

Contributions are licensed under the repository's [Apache License 2.0](LICENSE).
