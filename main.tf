# ------ Provider
provider "oci" {
  region = var.region
  # version = "4.20.0"
}

locals {
  Sp3_ssh_key                = var.ssh_pub_key
  Sp3_bastion_shape          = var.bastion_shape
  Sp3_bastion_image          = var.bastion_image
  Sp3_headnode_shape         = var.headnode_shape
  Sp3_headnode_image         = var.headnode_image
  Sp3_env_name               = var.name_prefix == "" ? "${var.env_name}-${local.Sp3_deploy_id}" : "${var.name_prefix}-${var.env_name}-${local.Sp3_deploy_id}"
  is_flexible_bastion_shape  = contains(local.compute_flexible_shapes, local.Sp3_bastion_shape)
  is_flexible_headnode_shape = contains(local.compute_flexible_shapes, local.Sp3_headnode_shape)
}

# ------ Create Instance
resource "oci_core_instance" "Sp3Bastion" {
  # Required
  compartment_id = local.Sp3_cid
  shape          = local.Sp3_bastion_shape
  # Optional
  display_name        = "${local.Sp3_env_name}-bastion"
  availability_domain = local.Sp3_ad
  agent_config {
    # Optional
  }
  create_vnic_details {
    # Required
    subnet_id = local.Pubsn001_id
    # Optional
    assign_public_ip       = true
    display_name           = "${local.Sp3_env_name}-bastion vnic 00"
    hostname_label         = "${local.Sp3_env_name}-bastion"
    skip_source_dest_check = "false"
    nsg_ids                = [local.bastion_nsg_id]
  }
  metadata = {
    ssh_authorized_keys = local.Sp3_ssh_key
    # user_data           = data.template_cloudinit_config.bastion.rendered
  }

  defined_tags = { "workload.server-type" = "Bastion" }
  extended_metadata = {
    tenancy_id    = var.tenancy_ocid
    deployment_id = local.Sp3_deploy_id
  }

  dynamic "shape_config" {
    for_each = local.is_flexible_bastion_shape ? [1] : []
    content {
      ocpus         = var.bastion_ocpus
      memory_in_gbs = var.bastion_ram
    }
  }

  source_details {
    source_id   = local.Sp3_bastion_image
    source_type = "image"
    # Optional
    boot_volume_size_in_gbs = var.bastion_boot_size
    #        kms_key_id              = 
  }
  preserve_boot_volume = false
}

locals {
  Sp3Bastion_id         = oci_core_instance.Sp3Bastion.id
  Sp3Bastion_public_ip  = oci_core_instance.Sp3Bastion.public_ip
  Sp3Bastion_private_ip = oci_core_instance.Sp3Bastion.private_ip
  sp3_bastion_connect   = var.create_dns ? "bastion.${local.Sp3_env_name}.${local.Sp3_dns_suffix}" : local.Sp3Bastion_public_ip
}

output "sp3_bastion" {
  value = local.sp3_bastion_connect
}

# ------ Create Head Node Instance
resource "oci_core_instance" "Sp3Headnode" {
  # Required
  compartment_id = local.Sp3_cid
  shape          = local.Sp3_headnode_shape
  # Optional
  display_name        = "${local.Sp3_env_name}-headnode"
  availability_domain = local.Sp3_ad
  create_vnic_details {
    # Required
    subnet_id = local.Privsn001_id
    # Optional
    assign_public_ip       = false
    display_name           = "${local.Sp3_env_name}-headnode vnic 00"
    hostname_label         = "${local.Sp3_env_name}-headnode"
    skip_source_dest_check = "false"
    nsg_ids                = [local.hn_nsg_id]
    private_ip             = "10.0.1.2"
  }
  metadata = {
    ssh_authorized_keys = local.Sp3_ssh_key
    user_data           = data.template_cloudinit_config.headnode.rendered
  }

  defined_tags = { "workload.server-type" = "Headnode" }
  extended_metadata = {
    tenancy_id    = var.tenancy_ocid
    deployment_id = local.Sp3_deploy_id
    subnet_id     = local.Privsn001_id
  }

  dynamic "shape_config" {
    for_each = local.is_flexible_headnode_shape ? [1] : []
    content {
      ocpus         = var.headnode_ocpus
      memory_in_gbs = var.headnode_ram
    }
  }
  source_details {
    # Required
    source_id   = local.Sp3_headnode_image
    source_type = "image"
    # Optional
    boot_volume_size_in_gbs = var.hn_boot_size
    #        kms_key_id              = 
  }

  depends_on = [
    oci_core_vcn.oke_cluster_vcn,
    oci_containerengine_cluster.oke_containerengine_cluster,
    oci_containerengine_node_pool.oke_containerengine_node_pool,
  ]

  preserve_boot_volume = false
}

locals {
  Sp3Headnode_id         = oci_core_instance.Sp3Headnode.id
  Sp3Headnode_public_ip  = oci_core_instance.Sp3Headnode.public_ip
  Sp3Headnode_private_ip = oci_core_instance.Sp3Headnode.private_ip
}

output "sp3headnodePrivateIP" {
  value = local.Sp3Headnode_private_ip
}

output "sp3_deploy_id" {
  value = local.Sp3_deploy_id
}
