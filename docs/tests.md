# Tests

The bundles in the repo are tested using multiple tooling at different layers
to ensure they are valid and are usable.

## Bundle validation

Bundle validation is performed by using
[opm](https://github.com/operator-framework/operator-registry), which provides
an option to validate a given bundle image. The bundle must be in a container
image format that can be pulled from a container registry. Local container
images can't be tested directly, opm requires the images to be pullable, it
pulls the bundle image, unpacks and validates the bundle content. In github
actions CI, a local container registry is setup to push the bundle and pull for
testing with opm.

Output from the CI:

```console
bin/opm alpha bundle validate -t localhost:5000/storageos/operator-bundle:v2.2.0
time="2020-10-20T20:28:20Z" level=info msg="Create a temp directory at /tmp/bundle-410085128" container-tool=docker
time="2020-10-20T20:28:20Z" level=debug msg="Pulling and unpacking container image" container-tool=docker
time="2020-10-20T20:28:20Z" level=info msg="running /usr/bin/docker pull localhost:5000/storageos/operator-bundle:v2.2.0" container-tool=docker
time="2020-10-20T20:28:20Z" level=info msg="running docker create" container-tool=docker
time="2020-10-20T20:28:20Z" level=debug msg="[docker create localhost:5000/storageos/operator-bundle:v2.2.0 ]" container-tool=docker
time="2020-10-20T20:28:21Z" level=info msg="running docker cp" container-tool=docker
time="2020-10-20T20:28:21Z" level=debug msg="[docker cp 115806dfdc6d38d3b69b0cafa6d53367283ac5d34c0f0e8a04fa0b457c2daf51:/. /tmp/bundle-410085128]" container-tool=docker
time="2020-10-20T20:28:21Z" level=info msg="running docker rm" container-tool=docker
time="2020-10-20T20:28:21Z" level=debug msg="[docker rm 115806dfdc6d38d3b69b0cafa6d53367283ac5d34c0f0e8a04fa0b457c2daf51]" container-tool=docker
time="2020-10-20T20:28:21Z" level=info msg="Unpacked image layers, validating bundle image format & contents" container-tool=docker
time="2020-10-20T20:28:21Z" level=debug msg="Found manifests directory" container-tool=docker
time="2020-10-20T20:28:21Z" level=debug msg="Found metadata directory" container-tool=docker
time="2020-10-20T20:28:21Z" level=debug msg="Getting mediaType info from manifests directory" container-tool=docker
time="2020-10-20T20:28:21Z" level=info msg="Found annotations file" container-tool=docker
time="2020-10-20T20:28:21Z" level=info msg="Could not find optional dependencies file" container-tool=docker
time="2020-10-20T20:28:21Z" level=debug msg="Validating bundle contents" container-tool=docker
time="2020-10-20T20:28:21Z" level=debug msg="Validating \"apiextensions.k8s.io/v1beta1, Kind=CustomResourceDefinition\" from file \"jobs.storageos.com.crd.yaml\"" container-tool=docker
time="2020-10-20T20:28:21Z" level=debug msg="Validating \"apiextensions.k8s.io/v1beta1, Kind=CustomResourceDefinition\" from file \"nfsservers.storageos.com.crd.yaml\"" container-tool=docker
time="2020-10-20T20:28:21Z" level=debug msg="Validating \"apiextensions.k8s.io/v1beta1, Kind=CustomResourceDefinition\" from file \"storageosclusters.storageos.com.crd.yaml\"" container-tool=docker
time="2020-10-20T20:28:21Z" level=debug msg="Validating \"operators.coreos.com/v1alpha1, Kind=ClusterServiceVersion\" from file \"storageosoperator.clusterserviceversion.yaml\"" container-tool=docker
time="2020-10-20T20:28:21Z" level=debug msg="Validating \"apiextensions.k8s.io/v1beta1, Kind=CustomResourceDefinition\" from file \"storageosupgrades.storageos.com.crd.yaml\"" container-tool=docker
time="2020-10-20T20:28:21Z" level=info msg="All validation tests have been completed successfully" container-tool=docker
```

## Policy based validation

For enforcing general best practices on the bundle configurations, [Open Policy
Agent (OPA)](https://www.openpolicyagent.org/) based policies are defined and
are tested against the bundle configuration. The policies are defined in
`policy/` directory. The bundles are validated based on these policies using
[conftest](https://www.conftest.dev).

Over time, learned new best practices can be added as new policies. This can
help automate the review process. The knowledge applied in manual review can be
written and enforced in code.

Output from the CI:

```console
bin/conftest test storageos2/2.2.0/manifests/storageosoperator.clusterserviceversion.yaml -o table
+---------+-------------------------------------------------------------------------+---------+
| RESULT  |                                  FILE                                   | MESSAGE |
+---------+-------------------------------------------------------------------------+---------+
| success | storageos2/2.2.0/manifests/storageosoperator.clusterserviceversion.yaml |         |
| success | storageos2/2.2.0/manifests/storageosoperator.clusterserviceversion.yaml |         |
| success | storageos2/2.2.0/manifests/storageosoperator.clusterserviceversion.yaml |         |
+---------+-------------------------------------------------------------------------+---------+
```

## OLM e2e test

e2e tests are performed by setting up a [Kind](https://kind.sigs.k8s.io)
cluster and installing OLM using [operator-sdk CLI](sdk.operatorframework.io/).
For the target bundle version, a bundle image is built. The bundle image is
used to create an OLM catalog index image using opm. This catalog index image
is used as source to install a CatalogSource in the OLM cluster. Using the
[operator kubectl plugin](github.com/operator-framework/kubectl-operator), the
operator in the installed catalog is installed and checked for a successful
installation.

Output from the CI:

```console
...
Run kubectl apply -f examples/catalogsource.yaml
catalogsource.operators.coreos.com/storageos-catalog created
NAME                   NAMESPACE  DISPLAY              TYPE  PUBLISHER       AGE
storageos-catalog      default                         grpc                  5s
operatorhubio-catalog  olm        Community Operators  grpc  OperatorHub.io  37s
...
Run kubectl operator install storageos2 --create-operator-group
operatorgroup "default" created
subscription "storageos2" created
operator "storageos2" installed; installed csv is "storageosoperator.v2.2.0"
...
Run until kubectl operator list | grep storageos2
PACKAGE     NAMESPACE  SUBSCRIPTION  INSTALLED CSV             CURRENT CSV               STATUS         AGE
storageos2  default    storageos2    storageosoperator.v2.2.0  storageosoperator.v2.2.0  AtLatestKnown  16s
...
```

**NOTE**: All these are tests for operator only. StorageOS is not installed in
any of these tests. They only validate the OLM bundle that are present in this
repository and help ensure the operator can be installed using the bundles.
