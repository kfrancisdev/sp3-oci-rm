resource "oci_dns_rrset" "lb_a_record" {
    domain = "${local.Sp3_env_name}.oci.sp3dev.ml"
    rtype = "A"
    zone_name_or_id = local.Sp3dev_ml_dns_zone_id
    #compartment_id = local.Sp3dev_ml_dns_comp_id
    items {
        rdata = "${local.Sp3_lb_public_ip}"
        ttl = 30
    }
}