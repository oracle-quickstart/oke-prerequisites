resource "null_resource" "local-machine-setup" {
  depends_on = ["oci_containerengine_node_pool.cf_node_pool", "local_file.cf_cluster_kube_config_file"]

  provisioner "local-exec" {
    command = "sh ../scripts/local_machine_setup.sh ${local_file.cf_cluster_kube_config_file.filename}"
  }
}
