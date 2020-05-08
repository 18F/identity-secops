# Falco!

This is where we can render the falco config.
```
cd falco
./render-falco.sh
cd ..
./deploy.sh <clustername>
```

As of this writing, falco needs to use the falcosecurity/falco:0.18.0 image to
work in EKS.  Let us hope this changes someday.  When that happens, you probably
will be able to zero out the `falco-values.yml` file and re-render.

Once deployed, Falco alerts will appear in the log stream for your review.

Nifty!

