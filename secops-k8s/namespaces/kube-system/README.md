# Cluster Kubernetes Config

This is where we create and configure core infrastructure services
required to bootstrap the cluster like CI/CD, maybe clamav, etc.

CI/CD then will be used to deploy everything else.


## ELK

To create the ELK config files, run `./render-elk.sh` in this directory.
It will get the elasticsearch helm charts and render them into yml files
in this directory which you can check in.

