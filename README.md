# Pulp Clowder Deployments

## Usage example
```
# This creates a ClowdEnvironment object for the namespace. Several services are started.
bonfire namespace reserve --duration 8h
oc config set-context ephemeral-mwyp3o
bonfire deploy-env -n $(oc project | grep -oE 'ephemeral-......') --template-file pulp-template.yaml
```

pulp-clowdenv.yaml is not used and not tested at this time.
