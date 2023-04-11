# Pulp Clowder Deployments

## Usage example
```
# This creates a ClowdEnvironment object for the namespace. Several services are started.
bonfire namespace reserve --duration 8h
oc config set-context ephemeral-mwyp3o
bonfire deploy-env -n $(oc project | grep -oE 'ephemeral-......') --template-file pulp-template.yaml
oc exec $(oc get pod | grep cr-generator | cut -f 1 -d " ") cat /cdapp/cdappconfig.json | jq
./config.sh
```

pulp-clowdenv.yaml is not used and not tested at this time.
