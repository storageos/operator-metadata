package olm

# Variables

name = input.metadata.name

kind = input.kind

certified = input.metadata.annotations.certified

annotationImage = input.metadata.annotations.containerImage

deploymentImage = input.spec.install.spec.deployments[0].spec.template.spec.containers[0].image

is_csv {
	input.kind = "ClusterServiceVersion"
}
