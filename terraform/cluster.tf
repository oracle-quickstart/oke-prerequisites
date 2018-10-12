variable "cluster_kubernetes_version" {
  default = "v1.9.7"
}

variable "cluster_name" {
  default = "confluentOKECluster"
}

variable "availability_domain" {
  default = 3
}

variable "cluster_options_add_ons_is_kubernetes_dashboard_enabled" {
  default = true
}

variable "cluster_options_add_ons_is_tiller_enabled" {
  default = true
}

variable "cluster_options_kubernetes_network_config_pods_cidr" {
  default = "10.244.0.0/16"
}

variable "cluster_options_kubernetes_network_config_services_cidr" {
  default = "10.96.0.0/16"
}

variable "node_pool_initial_node_labels_key" {
  default = "key"
}

variable "node_pool_initial_node_labels_value" {
  default = "value"
}

variable "node_pool_kubernetes_version" {
  default = "v1.9.7"
}

variable "node_pool_name" {
  default = "cfPool"
}

variable "node_pool_node_image_name" {
  default = "Oracle-Linux-7.4"
}

variable "node_pool_node_shape" {
  default = "VM.Standard1.1"
}

variable "node_pool_quantity_per_subnet" {
  default = 3
}

variable "node_pool_ssh_public_key" {}

resource "oci_containerengine_cluster" "cf_cluster" {
  #Required
  compartment_id     = "${var.compartment_ocid}"
  kubernetes_version = "${var.cluster_kubernetes_version}"
  name               = "${var.cluster_name}"
  vcn_id             = "${oci_core_virtual_network.oke_confluent_vcn.id}"

  #Optional
  options {
    service_lb_subnet_ids = ["${oci_core_subnet.lb_subnet_1.id}", "${oci_core_subnet.lb_subnet_2.id}"]

    #Optional
    add_ons {
      #Optional
      is_kubernetes_dashboard_enabled = "${var.cluster_options_add_ons_is_kubernetes_dashboard_enabled}"
      is_tiller_enabled               = "${var.cluster_options_add_ons_is_tiller_enabled}"
    }

    kubernetes_network_config {
      pods_cidr     = "${var.cluster_options_kubernetes_network_config_pods_cidr}"
      services_cidr = "${var.cluster_options_kubernetes_network_config_services_cidr}"
    }
  }
}

resource "oci_containerengine_node_pool" "cf_node_pool" {
  cluster_id         = "${oci_containerengine_cluster.cf_cluster.id}"
  compartment_id     = "${var.compartment_ocid}"
  kubernetes_version = "${var.node_pool_kubernetes_version}"
  name               = "${var.node_pool_name}"
  node_image_name    = "${var.node_pool_node_image_name}"
  node_shape         = "${var.node_pool_node_shape}"
  subnet_ids         = ["${oci_core_subnet.public.0.id}", "${oci_core_subnet.public.1.id}", "${oci_core_subnet.public.2.id}"]

  initial_node_labels {
    key   = "${var.node_pool_initial_node_labels_key}"
    value = "${var.node_pool_initial_node_labels_value}"
  }

  quantity_per_subnet = "${var.node_pool_quantity_per_subnet}"
  ssh_public_key      = "${var.node_pool_ssh_public_key}"
}

output "cluster" {
  value = {
    id                 = "${oci_containerengine_cluster.cf_cluster.id}"
    kubernetes_version = "${oci_containerengine_cluster.cf_cluster.kubernetes_version}"
    name               = "${oci_containerengine_cluster.cf_cluster.name}"
  }
}

output "node_pool" {
  value = {
    id                 = "${oci_containerengine_node_pool.cf_node_pool.id}"
    kubernetes_version = "${oci_containerengine_node_pool.cf_node_pool.kubernetes_version}"
    name               = "${oci_containerengine_node_pool.cf_node_pool.name}"
    subnet_ids         = "${oci_containerengine_node_pool.cf_node_pool.subnet_ids}"
  }
}

output "Where to access Kubeconfig file" {
  value = {
    filename = "${local_file.cf_cluster_kube_config_file.filename}"
  }
}
