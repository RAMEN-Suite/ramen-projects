# Security policy

## Supported versions

`main` is what the production hosts serve. Content on `dev` reaches the development and staging servers only and may
change without notice.

## Reporting a vulnerability

Please use GitHub's private vulnerability reporting for this repository. Do not open a public issue for an undisclosed
vulnerability.

Include the affected project and file, reproduction steps, impact, and any known mitigation. You can expect an
acknowledgement within seven days. A fix timeline depends on severity and reproducibility; coordinated disclosure will be
agreed with the reporter before details are published.

## Deployment

This repository holds configuration and content, no code that runs on the hosts. A deploy copies files over SSH with a
key that the host restricts to writing below its content directory, and restarts servers through the deploy gateway
with a second, separate key. Every deploy and every pull request checks that the JSON files parse.
