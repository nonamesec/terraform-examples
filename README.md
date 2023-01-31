# Noname Security terraform examples

This repository contains terraform examples for setting up componets of [Noname Security](https://nonamesecurity.com).

## Conventions

* We use `data` sources for components that you likely already have set-up. Things like `alb`, `security-groups`, `subnets` and more.
* Setting up the least amount of resources possible, building on top of existing cloud resources when possible.
* Least access by default
* Secure by default
* Each directory will contain its own README. Browse to a directory to read more about it


## Existing components

1. [Network](network)
2. [Remote Engine on EC2 VM](remote-engine-aws-ec2)
3. [EKS](eks)


## Contributing

Submitting a PR or an issue is encouraged
