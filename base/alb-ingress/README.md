# ALB Ingress setup

This is from https://kubernetes-sigs.github.io/aws-alb-ingress-controller/guide/controller/setup/#helm
and https://hub.helm.sh/charts/incubator/aws-alb-ingress-controller

Unfortunately, there is some sort of requirement for us to configure the cluster name
so that things get properly tagged.  So there's no generic way to do it that I'm aware
of.

I'm wondering if kustomize could come to the rescue here and edit a generic config
yaml instead of us rendering out per-cluster config files.  Better brains can figure
this out!

