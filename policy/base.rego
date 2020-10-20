package main

import data.olm

deny_no_v_in_name[msg] {
    olm.is_csv
    not contains(olm.name, ".v")
    msg = sprintf("Operator name must have '.v'; found `%v`", [olm.name])
}

deny_annotation_deployment_image[msg] {
    olm.is_csv
    not olm.annotationImage = olm.deploymentImage
    msg = sprintf("Annotation image and deployment image must be same; found `%v`, `%v`", [olm.annotationImage, olm.deploymentImage])
}

deny_not_certified[msg] {
    olm.is_csv
    not olm.certified = "true"
    msg = sprintf("Operator must be certified - metadata.annotations.certified: 'true'; found `%v`", [olm.certified])
}
