variable "cluster_kube_config_expiration" {
  default = 2592000
}

variable "cluster_kube_config_token_version" {
  default = "1.0.0"
}

data "oci_containerengine_cluster_kube_config" "cf_cluster_kube_config" {
  cluster_id    = "${oci_containerengine_cluster.cf_cluster.id}"
  expiration    = "${var.cluster_kube_config_expiration}"
  token_version = "${var.cluster_kube_config_token_version}"
}

resource "local_file" "cf_cluster_kube_config_file" {
  content  = "${data.oci_containerengine_cluster_kube_config.cf_cluster_kube_config.content}"
  filename = "${path.module}/cf_cluster_kube_config_file.txt"
}
