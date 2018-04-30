# Configure the PowerDNS provider
provider "powerdns" {
    api_key = "${var.powerdns_api_key}"
    server_url = "${format("http://%s:8088",var.powerdns_server_ip)}"
}


# Add a record to the zone
resource "powerdns_record" "test" {
    zone = "internal.paas."
    name = "test.internal.paas."
    type = "A"
    ttl = 3000
    records = ["${var.powerdns_record["test"]}"]
}

# Add a split dns for cf api wildcard =>  to cloudfoundry/haproxy job
resource "powerdns_record" "cf-api" {
    zone = "${format("%s.",var.system_domain)}"
    name = "${format("*.%s.",var.system_domain)}"
    type = "A"
    ttl = 3000
    records = ["${var.powerdns_record["cf-api"]}"]
}

# Add a dns wildcard for cf apps directly to cloudfoundry/haproxy job
resource "powerdns_record" "cf-apps-internal" {
    zone = "internal.paas"
    name = "*.apps.internal.paas."
    type = "A"
    ttl = 3000
    records = ["${var.powerdns_record["cf-api"]}"]
}

# Add a split dns for cf apps wildcard => to cf-haproxy/cf-haproxy jobs
resource "powerdns_record" "cf-apps" {
    zone = "${format("%s.",var.apps_domain)}"
    name = "${format("*.%s.",var.apps_domain)}"
    type = "A"
    ttl = 3000
    records = ["${var.powerdns_record["cf-apps"]}"]
}

# Add a split dns for cf apps http wildcard => to cf-haproxy/cf-haproxy jobs
resource "powerdns_record" "cf-apps-http" {
    zone = "${format("%s.",var.apps_http_domain)}"
    name = "${format("*.%s.",var.apps_http_domain)}"
    type = "A"
    ttl = 3000
    records = ["${var.powerdns_record["cf-apps-http"]}"]
}




# Add a split dns for ops wildcard => to cf-haproxy/cf-haproxy jobs

resource "powerdns_record" "cf-ops" {
    zone = "${format("%s.",var.ops_domain)}"
    name = "${format("*.%s.",var.ops_domain)}"
    type = "A"
    ttl = 3000
    records = ["${var.powerdns_record["cf-ops"]}"]
}


resource "powerdns_record" "cf-apps-internet" {
    zone = "${format("%s.",var.apps_internet_domain)}"
    name = "${format("*.%s.",var.apps_internet_domain)}"
    type = "A"
    ttl = 3000
    records = ["${var.powerdns_record["cf-apps-internet"]}"]
}


#add an alias for each bosh director
resource "powerdns_record" "bosh-micro" {
    zone = "internal.paas."
    name = "bosh-micro.internal.paas."
    type = "A"
    ttl = 30000
    records = ["${var.powerdns_record["bosh-micro"]}"]
}

resource "powerdns_record" "bosh-master" {
    zone = "internal.paas."
    name = "bosh-master.internal.paas."
    type = "A"
    ttl = 3000
    records = ["${var.powerdns_record["bosh-master"]}"]
}


resource "powerdns_record" "bosh-ops" {
    zone = "internal.paas."
    name = "bosh-ops.internal.paas."
    type = "A"
    ttl = 3000
    records = ["${var.powerdns_record["bosh-ops"]}"]
}

resource "powerdns_record" "bosh-expe" {
    zone = "internal.paas."
    name = "bosh-expe.internal.paas."
    type = "A"
    ttl = 3000
    records = ["${var.powerdns_record["bosh-expe"]}"]
}



resource "powerdns_record" "bosh-ondemand" {
    zone = "internal.paas."
    name = "bosh-ondemand.internal.paas."
    type = "A"
    ttl = 3000
    records = ["${var.powerdns_record["bosh-ondemand"]}"]
}


resource "powerdns_record" "elpaaso-ldap" {
    zone = "internal.paas."
    name = "elpaaso-ldap.internal.paas."
    type = "A"
    ttl = 3000
    records = ["${var.powerdns_record["elpaaso-ldap"]}"]
}


resource "powerdns_record" "prometheus" {
    zone = "internal.paas."
    name = "prometheus.internal.paas."
    type = "A"
    ttl = 3000
    records = ["${var.powerdns_record["prometheus"]}"]
}

resource "powerdns_record" "prometheus-ops" {
    zone = "internal.paas."
    name = "prometheus-ops.internal.paas."
    type = "A"
    ttl = 3000
    records = ["${var.powerdns_record["prometheus-ops"]}"]
}

resource "powerdns_record" "prometheus-master" {
    zone = "internal.paas."
    name = "prometheus-master.internal.paas."
    type = "A"
    ttl = 3000
    records = ["${var.powerdns_record["prometheus-master"]}"]
}


resource "powerdns_record" "prometheus-blackbox-probe" {
    zone = "internal.paas."
    name = "prometheus-blackbox-probe.internal.paas."
    type = "A"
    ttl = 3000
    records = ["${var.powerdns_record["prometheus-blackbox-probe"]}"]
}

resource "powerdns_record" "webhook-mcxa" {
    zone = "internal.paas."
    name = "webhook-mcxa.internal.paas."
    type = "A"
    ttl = 3000
    records = ["${var.powerdns_record["webhook-mcxa"]}"]
}

resource "powerdns_record" "elpaaso-fpv-intranet" {
    zone = "internal.paas."
    name = "elpaaso-fpv-intranet.internal.paas."
    type = "A"
    ttl = 3000
    records = ["${var.powerdns_record["elpaaso-fpv-intranet"]}"]
}

resource "powerdns_record" "elpaaso-fpv-internet" {
    zone = "internal.paas."
    name = "elpaaso-fpv-internet.internal.paas."
    type = "A"
    ttl = 3000
    records = ["${var.powerdns_record["elpaaso-fpv-internet"]}"]
}



resource "powerdns_record" "elpaaso-mail" {
    zone = "internal.paas."
    name = "elpaaso-mail.internal.paas."
    type = "A"
    ttl = 3000
    records = ["${var.powerdns_record["elpaaso-mail"]}"]
}

resource "powerdns_record" "elpaaso-mail-1" {
    zone = "internal.paas."
    name = "elpaaso-mail-1.internal.paas."
    type = "A"
    ttl = 3000
    records = ["${var.powerdns_record["elpaaso-mail-1"]}"]
}

resource "powerdns_record" "weave-scope" {
    zone = "internal.paas."
    name = "weave-scope.internal.paas."
    type = "A"
    ttl = 3000
    records = ["192.168.31.149"]
}

resource "powerdns_record" "docker-bosh-cli" {
    zone = "internal.paas."
    name = "docker-bosh-cli.internal.paas."
    type = "A"
    ttl = 3000
    records = ["${var.powerdns_record["docker-bosh-cli"]}"]
}

resource "powerdns_record" "docker-bosh-cli-service" {
    zone = "internal.paas."
    name = "docker-bosh-cli-service.internal.paas."
    type = "A"
    ttl = 3000
    records = ["${var.powerdns_record["docker-bosh-cli-service"]}"]
}

resource "powerdns_record" "elpaaso-ntp1" {
    zone = "internal.paas."
    name = "elpaaso-ntp1.internal.paas."
    type = "A"
    ttl = 3000
    records = ["${var.powerdns_record["elpaaso-ntp1"]}"]
}

resource "powerdns_record" "elpaaso-ntp2" {
    zone = "internal.paas."
    name = "elpaaso-ntp2.internal.paas."
    type = "A"
    ttl = 3000
    records = ["${var.powerdns_record["elpaaso-ntp2"]}"]
}


resource "powerdns_record" "credhub" {
    zone = "internal.paas."
    name = "credhub.internal.paas."
    type = "A"
    ttl = 3000
    records = ["${var.powerdns_record["credhub"]}"]
}

resource "powerdns_record" "uaa-credhub" {
    zone = "internal.paas."
    name = "uaa-credhub.internal.paas."
    type = "A"
    ttl = 3000
    records = ["${var.powerdns_record["uaa-credhub"]}"]
}



resource "powerdns_record" "ls-router-ops" {
    zone = "internal.paas."
    name = "ls-router-ops.internal.paas."
    type = "A"
    ttl = 3000
    records = ["192.168.99.245"]
}

resource "powerdns_record" "es-master-ops" {
    zone = "internal.paas."
    name = "es-master-ops.internal.paas."
    type = "A"
    ttl = 3000
    records = ["192.168.99.26"]
}

resource "powerdns_record" "private-s3" {
    zone = "internal.paas."
    name = "private-s3.internal.paas."
    type = "A"
    ttl = 3000
    records = ["192.168.116.50"]
}


output "powerdns_server_url" {
    value = "${format("http://%s:8088",var.powerdns_server_ip)}"
}

resource "powerdns_record" "cf-datastores" {
    zone = "internal.paas."
    name = "cf-datastores.internal.paas."
    type = "A"
    ttl = 300
    records = ["192.168.99.217"]
}