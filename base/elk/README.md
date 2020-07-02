# Logging!

This is where the ELK stack is configured for the cluster!

If you want to try out the latest/greatest, you can probably just do this:
```
cd logging
./render-logging.sh
cd ..
./deploy.sh <clustername>
```

This will write out manifests into `clusterconfig/base/` for the various
services.

There are some `*-values.yml` files that you can edit to change the config of the
resulting base ELK stack.  However, if you want to change the config on a per-cluster
basis, you will need to do that in the `clusterconfig/clustername/kustomization.yaml`
file.


## Disk space

Adding more disk space seems to be tricky.  The easiest way is to just add more nodes,
but that burns up memory, and if the nodes are not loaded, that might be a waste of
$$.

The proper way to do this seems to be documented in a few ways here:
https://serverfault.com/questions/955293/how-to-increase-disk-size-in-a-stateful-set

