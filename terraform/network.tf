variable "VPC-CIDR" {
  default = "10.0.0.0/16"
}

data "oci_identity_availability_domains" "ADs" {
  compartment_id = "${var.tenancy_ocid}"
}

resource "oci_core_virtual_network" "oke_confluent_vcn" {
  cidr_block     = "${var.VPC-CIDR}"
  compartment_id = "${var.tenancy_ocid}"
  display_name   = "oke_confluent_vcn"
  dns_label      = "okecfvcn"
}

resource "oci_core_internet_gateway" "confluent_internet_gateway" {
  compartment_id = "${var.tenancy_ocid}"
  display_name   = "confluent_internet_gateway"
  vcn_id         = "${oci_core_virtual_network.oke_confluent_vcn.id}"
}

resource "oci_core_route_table" "RouteForComplete" {
  compartment_id = "${var.tenancy_ocid}"
  vcn_id         = "${oci_core_virtual_network.oke_confluent_vcn.id}"
  display_name   = "RouteTableForComplete"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = "${oci_core_internet_gateway.confluent_internet_gateway.id}"
  }
}

resource "oci_core_security_list" "default_security_list" {
  compartment_id = "${var.tenancy_ocid}"
  display_name   = "Default_Security_List"
  vcn_id         = "${oci_core_virtual_network.oke_confluent_vcn.id}"

  egress_security_rules = [{
    destination = "0.0.0.0/0"
    protocol    = "all"
    stateless   = false
  }]

  egress_security_rules = [{
    destination = "${cidrsubnet(var.VPC-CIDR, 8, 0)}"
    protocol    = "all"
    stateless   = true
  }]

  egress_security_rules = [{
    destination = "${cidrsubnet(var.VPC-CIDR, 8, 1)}"
    protocol    = "all"
    stateless   = true
  }]

  egress_security_rules = [{
    destination = "${cidrsubnet(var.VPC-CIDR, 8, 2)}"
    protocol    = "all"
    stateless   = true
  }]

  egress_security_rules = [{
    destination = "${var.VPC-CIDR}"
    protocol    = "all"
    stateless   = true
  }]

  ingress_security_rules = [{
    protocol  = "all"
    source    = "${cidrsubnet(var.VPC-CIDR, 8, 0)}"
    stateless = true
  }]

  ingress_security_rules = [{
    protocol  = "all"
    source    = "${cidrsubnet(var.VPC-CIDR, 8, 1)}"
    stateless = true
  }]

  ingress_security_rules = [{
    protocol  = "all"
    source    = "${cidrsubnet(var.VPC-CIDR, 8, 2)}"
    stateless = true
  }]

  ingress_security_rules = [{
    tcp_options {
      "max" = 22
      "min" = 22
    }

    protocol  = "6"
    source    = "0.0.0.0/0"
    stateless = false
  }]

  ingress_security_rules = [{
    tcp_options {
      "max" = 22
      "min" = 22
    }

    protocol  = "6"
    source    = "130.35.0.0/16"
    stateless = false
  }]

  ingress_security_rules = [{
    tcp_options {
      "max" = 22
      "min" = 22
    }

    protocol  = "6"
    source    = "138.1.0.0/17"
    stateless = false
  }]

  ingress_security_rules = [{
    protocol  = "all"
    source    = "${var.VPC-CIDR}"
    stateless = true
  }]

  ingress_security_rules = [{
    tcp_options {
      "max" = 32767
      "min" = 30000
    }

    protocol  = "6"
    source    = "0.0.0.0/0"
    stateless = false
  }]

  ingress_security_rules = [{
    protocol  = "1"
    source    = "0.0.0.0/0"
    stateless = false

    icmp_options {
      "type" = 3
      "code" = 4
    }
  }]

  ingress_security_rules = [{
    protocol  = "1"
    source    = "${var.VPC-CIDR}"
    stateless = false

    icmp_options {
      "type" = 3
    }
  }]
}

resource "oci_core_security_list" "LoadBalancers" {
  compartment_id = "${var.tenancy_ocid}"
  display_name   = "Load_Balancer_Security_List"
  vcn_id         = "${oci_core_virtual_network.oke_confluent_vcn.id}"

  egress_security_rules = [{
    destination = "0.0.0.0/0"
    protocol    = "6"
    stateless   = true
  }]

  ingress_security_rules = [{
    protocol  = "6"
    source    = "0.0.0.0/0"
    stateless = true
  }]
}

## Publicly Accessable Subnet Setup

resource "oci_core_subnet" "public" {
  count               = "3"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[count.index],"name")}"
  cidr_block          = "${cidrsubnet(var.VPC-CIDR, 8, count.index)}"
  display_name        = "public_${count.index}"
  compartment_id      = "${var.tenancy_ocid}"
  vcn_id              = "${oci_core_virtual_network.oke_confluent_vcn.id}"
  route_table_id      = "${oci_core_route_table.RouteForComplete.id}"
  security_list_ids   = ["${oci_core_security_list.default_security_list.id}"]
  dhcp_options_id     = "${oci_core_virtual_network.oke_confluent_vcn.default_dhcp_options_id}"
  dns_label           = "public${count.index}"
}

## LB for Kubernetes
resource "oci_core_subnet" "lb_subnet_1" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[0],"name")}"
  cidr_block          = "${cidrsubnet(var.VPC-CIDR, 8, 20)}"
  display_name        = "lb_subnet_1"
  compartment_id      = "${var.tenancy_ocid}"
  vcn_id              = "${oci_core_virtual_network.oke_confluent_vcn.id}"
  route_table_id      = "${oci_core_route_table.RouteForComplete.id}"
  security_list_ids   = ["${oci_core_security_list.LoadBalancers.id}"]
  dhcp_options_id     = "${oci_core_virtual_network.oke_confluent_vcn.default_dhcp_options_id}"
  dns_label           = "lbsubnet1"
}

## LB for Kubernetes
resource "oci_core_subnet" "lb_subnet_2" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[1],"name")}"
  cidr_block          = "${cidrsubnet(var.VPC-CIDR, 8, 21)}"
  display_name        = "lb_subnet_2"
  compartment_id      = "${var.tenancy_ocid}"
  vcn_id              = "${oci_core_virtual_network.oke_confluent_vcn.id}"
  route_table_id      = "${oci_core_route_table.RouteForComplete.id}"
  security_list_ids   = ["${oci_core_security_list.LoadBalancers.id}"]
  dhcp_options_id     = "${oci_core_virtual_network.oke_confluent_vcn.default_dhcp_options_id}"
  dns_label           = "lbsubnet2"
}
