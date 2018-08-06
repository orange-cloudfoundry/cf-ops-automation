# Directory structure 'hello-world-root-depls' for  example

## The config repo

### root level overview

```bash
.
|-- concourse
|-- hello-world-root-depls
|-- private-config.yml
`-- shared
```

### hello-world-root-depls overview

```bash
hello-world-root-depls
|-- bosh-deployment-sample
|   |-- enable-deployment.yml
|   `-- secrets
|       |-- meta.yml
|       `-- secrets.yml
|-- cf-apps-deployments
|   `-- generic-app
|       |-- enable-cf-app.yml
|       `-- secrets
|           `-- secrets.yml
|-- ci-deployment-overview.yml
|-- pipeline-sample
|   |-- Readme.md
|   `-- enable-deployment.yml
|-- secrets
|   |-- meta.yml
|   |-- private-config-operators.yml
|   |-- private-runtime-operators.yml
|   `-- secrets.yml
|-- terraform-config
|   |-- secrets
|   |   `-- secrets.yml
|   `-- spec
|       `-- my-private-terraform-spec.tf
|-- terraform-sample
|   |-- secrets
|   |   |-- meta.yml
|   |   `-- secrets.yml
|   `-- spec
|       `-- my-private-terraform-spec.tf
`-- to-delete-bosh-deployment-sample
    `-- secrets
        `-- secrets.yml
```

## The template repo

### root level overview

```bash
.
|-- another-world-root-depls
|-- hello-world-root-depls
`-- shared-config.yml
```

### hello-world-root-depls overview

```bash
hello-world-root-depls
|-- bosh-deployment-sample
|   |-- deployment-dependencies-openstack.yml
|   |-- deployment-dependencies.yml
|   `-- template
|       |-- adding-ntp-release-operators.yml
|       |-- bosh-deployment-sample-tpl.yml
|       |-- ntp-release-vars.yml
|       |-- openstack
|       |   `-- nginx-operators.yml
|       |-- post-deploy.sh
|       `-- pre-deploy.sh
|-- cf-apps-deployments
|   `-- generic-app
|       |-- deployment-dependencies.yml
|       `-- template
|           |-- Staticfile
|           |-- index.html
|           |-- manifest-tpl.yml
|           |-- post-deploy.sh
|           `-- pre-cf-push.sh
|-- hello-world-root-depls-versions.yml
|-- pipeline-sample
|   |-- concourse-pipeline-config
|   |   `-- pipeline-sample.yml
|   `-- deployment-dependencies.yml
|-- template
|   |-- cloud-config.yml
|   |-- deploy.sh
|   |-- openstack
|   |   `-- disk-types-cloud-operators.yml
|   |-- public-config-operators.yml
|   |-- public-runtime-operators.yml
|   `-- runtime-config.yml
`-- terraform-config
    |-- spec
    |   `-- local-provider-sample.tf
    `-- template
        |-- post-generate.sh
        `-- terraform-tpl.tfvars.yml
```

## The config files

### The root config files

* [concourse](/docs/reference_dataset/config_repository/concourse)
* [hello-world-root-depls](/docs/reference_dataset/config_repository/hello-world-root-depls)
* [private-config.yml](/docs/reference_dataset/config_repository/private-config.yml)
* [shared](/docs/reference_dataset/config_repository/shared)

### The hello-world-root-depls files

* [hello-world-root-depls](/docs/reference_dataset/config_repository/hello-world-root-depls)
  * [bosh-deployment-sample](/docs/reference_dataset/config_repository/hello-world-root-depls/bosh-deployment-sample)
    * [enable-deployment.yml](/docs/reference_dataset/config_repository/hello-world-root-depls/bosh-deployment-sample/enable-deployment.yml)
    * [secrets](/docs/reference_dataset/config_repository/hello-world-root-depls/bosh-deployment-sample/secrets)
      * [meta.yml](/docs/reference_dataset/config_repository/hello-world-root-depls/bosh-deployment-sample/secrets/meta.yml)
      * [secrets.yml](/docs/reference_dataset/config_repository/hello-world-root-depls/bosh-deployment-sample/secrets/secrets.yml)
  * [cf-apps-deployments](/docs/reference_dataset/config_repository/hello-world-root-depls/cf-apps-deployments)
    * [generic-app](/docs/reference_dataset/config_repository/hello-world-root-depls/cf-apps-deployments/generic-app)
      * [enable-cf-app.yml](/docs/reference_dataset/config_repository/hello-world-root-depls/cf-apps-deployments/generic-app/enable-cf-app.yml)
      * [secrets](/docs/reference_dataset/config_repository/hello-world-root-depls/cf-apps-deployments/generic-app/secrets)
        * [secrets.yml](/docs/reference_dataset/config_repository/hello-world-root-depls/cf-apps-deployments/generic-app/secrets/secrets.yml)
  * [ci-deployment-overview.yml](/docs/reference_dataset/config_repository/hello-world-root-depls/ci-deployment-overview.yml)
  * [pipeline-sample](/docs/reference_dataset/config_repository/hello-world-root-depls/pipeline-sample)
    * [Readme.md](/docs/reference_dataset/config_repository/hello-world-root-depls/pipeline-sample/Readme.md)
    * [enable-deployment.yml](/docs/reference_dataset/config_repository/hello-world-root-depls/pipeline-sample/enable-deployment.yml)
  * [secrets](/docs/reference_dataset/config_repository/hello-world-root-depls/secrets)
    * [meta.yml](/docs/reference_dataset/config_repository/hello-world-root-depls/secrets/meta.yml)
    * [private-config-operators.yml](/docs/reference_dataset/config_repository/hello-world-root-depls/secrets/private-config-operators.yml)
    * [private-runtime-operators.yml](/docs/reference_dataset/config_repository/hello-world-root-depls/secrets/private-runtime-operators.yml)
    * [secrets.yml](/docs/reference_dataset/config_repository/hello-world-root-depls/secrets/secrets.yml)
  * [terraform-config](/docs/reference_dataset/config_repository/hello-world-root-depls/terraform-config)
    * [secrets](/docs/reference_dataset/config_repository/hello-world-root-depls/terraform-config/secrets)
      * [secrets.yml](/docs/reference_dataset/config_repository/hello-world-root-depls/terraform-config/secrets/secrets.yml)
    * [spec](/docs/reference_dataset/config_repository/hello-world-root-depls/terraform-config/spec)
      * [my-private-terraform-spec.tf](/docs/reference_dataset/config_repository/hello-world-root-depls/terraform-config/spec/my-private-terraform-spec.tf)
  * [terraform-sample](/docs/reference_dataset/config_repository/hello-world-root-depls/terraform-sample)
    * [secrets](/docs/reference_dataset/config_repository/hello-world-root-depls/terraform-sample/secrets)
      * [meta.yml](/docs/reference_dataset/config_repository/hello-world-root-depls/terraform-sample/secrets/meta.yml)
      * [secrets.yml](/docs/reference_dataset/config_repository/hello-world-root-depls/terraform-sample/secrets/secrets.yml)
    * [spec](/docs/reference_dataset/config_repository/hello-world-root-depls/terraform-sample/spec)
      * [my-private-terraform-spec.tf](/docs/reference_dataset/config_repository/hello-world-root-depls/terraform-sample/spec/my-private-terraform-spec.tf)
  * [to-delete-bosh-deployment-sample](/docs/reference_dataset/config_repository/hello-world-root-depls/to-delete-bosh-deployment-sample)
    * [secrets](/docs/reference_dataset/config_repository/hello-world-root-depls/to-delete-bosh-deployment-sample/secrets)
      * [secrets.yml](/docs/reference_dataset/config_repository/hello-world-root-depls/to-delete-bosh-deployment-sample/secrets/secrets.yml)

### The shared files

* [shared](/docs/reference_dataset/shared/shared)
  * [certs](/docs/reference_dataset/shared/shared/certs)
    * [internal_paas-ca](/docs/reference_dataset/shared/shared/certs/internal_paas-ca)
      * [server-ca.crt](/docs/reference_dataset/shared/shared/certs/internal_paas-ca/server-ca.crt)
  * [concourse-credentials.yml](/docs/reference_dataset/shared/shared/concourse-credentials.yml)
  * [pipeline-credentials.yml](/docs/reference_dataset/shared/shared/pipeline-credentials.yml)
  * [secrets.yml](/docs/reference_dataset/shared/shared/secrets.yml)

## The template files

### The root template files

* [another-world-root-depls](/docs/reference_dataset/template_repository/another-world-root-depls)
* [hello-world-root-depls](/docs/reference_dataset/template_repository/hello-world-root-depls)
* [shared-config.yml](/docs/reference_dataset/template_repository/shared-config.yml)

### The hello-world-root-depls files

* [hello-world-root-depls](/docs/reference_dataset/template_repository/hello-world-root-depls)
  * [bosh-deployment-sample](/docs/reference_dataset/template_repository/hello-world-root-depls/bosh-deployment-sample)
    * [deployment-dependencies-openstack.yml](/docs/reference_dataset/template_repository/hello-world-root-depls/bosh-deployment-sample/deployment-dependencies-openstack.yml)
    * [deployment-dependencies.yml](/docs/reference_dataset/template_repository/hello-world-root-depls/bosh-deployment-sample/deployment-dependencies.yml)
    * [template](/docs/reference_dataset/template_repository/hello-world-root-depls/bosh-deployment-sample/template)
      * [adding-ntp-release-operators.yml](/docs/reference_dataset/template_repository/hello-world-root-depls/bosh-deployment-sample/template/adding-ntp-release-operators.yml)
      * [bosh-deployment-sample-tpl.yml](/docs/reference_dataset/template_repository/hello-world-root-depls/bosh-deployment-sample/template/bosh-deployment-sample-tpl.yml)
      * [ntp-release-vars.yml](/docs/reference_dataset/template_repository/hello-world-root-depls/bosh-deployment-sample/template/ntp-release-vars.yml)
      * [openstack](/docs/reference_dataset/template_repository/hello-world-root-depls/bosh-deployment-sample/template/openstack)
        * [nginx-operators.yml](/docs/reference_dataset/template_repository/hello-world-root-depls/bosh-deployment-sample/template/openstack/nginx-operators.yml)
      * [post-deploy.sh](/docs/reference_dataset/template_repository/hello-world-root-depls/bosh-deployment-sample/template/post-deploy.sh)
      * [pre-deploy.sh](/docs/reference_dataset/template_repository/hello-world-root-depls/bosh-deployment-sample/template/pre-deploy.sh)
  * [cf-apps-deployments](/docs/reference_dataset/template_repository/hello-world-root-depls/cf-apps-deployments)
    * [generic-app](/docs/reference_dataset/template_repository/hello-world-root-depls/cf-apps-deployments/generic-app)
      * [deployment-dependencies.yml](/docs/reference_dataset/template_repository/hello-world-root-depls/cf-apps-deployments/generic-app/deployment-dependencies.yml)
      * [template](/docs/reference_dataset/template_repository/hello-world-root-depls/cf-apps-deployments/generic-app/template)
        * [Staticfile](/docs/reference_dataset/template_repository/hello-world-root-depls/cf-apps-deployments/generic-app/template/Staticfile)
        * [index.html](/docs/reference_dataset/template_repository/hello-world-root-depls/cf-apps-deployments/generic-app/template/index.html)
        * [manifest-tpl.yml](/docs/reference_dataset/template_repository/hello-world-root-depls/cf-apps-deployments/generic-app/template/manifest-tpl.yml)
        * [post-deploy.sh](/docs/reference_dataset/template_repository/hello-world-root-depls/cf-apps-deployments/generic-app/template/post-deploy.sh)
        * [pre-cf-push.sh](/docs/reference_dataset/template_repository/hello-world-root-depls/cf-apps-deployments/generic-app/template/pre-cf-push.sh)
  * [hello-world-root-depls-versions.yml](/docs/reference_dataset/template_repository/hello-world-root-depls/hello-world-root-depls-versions.yml)
  * [pipeline-sample](/docs/reference_dataset/template_repository/hello-world-root-depls/pipeline-sample)
    * [concourse-pipeline-config](/docs/reference_dataset/template_repository/hello-world-root-depls/pipeline-sample/concourse-pipeline-config)
      * [pipeline-sample.yml](/docs/reference_dataset/template_repository/hello-world-root-depls/pipeline-sample/concourse-pipeline-config/pipeline-sample.yml)
    * [deployment-dependencies.yml](/docs/reference_dataset/template_repository/hello-world-root-depls/pipeline-sample/deployment-dependencies.yml)
  * [template](/docs/reference_dataset/template_repository/hello-world-root-depls/template)
    * [cloud-config.yml](/docs/reference_dataset/template_repository/hello-world-root-depls/template/cloud-config.yml)
    * [deploy.sh](/docs/reference_dataset/template_repository/hello-world-root-depls/template/deploy.sh)
    * [openstack](/docs/reference_dataset/template_repository/hello-world-root-depls/template/openstack)
      * [disk-types-cloud-operators.yml](/docs/reference_dataset/template_repository/hello-world-root-depls/template/openstack/disk-types-cloud-operators.yml)
    * [public-config-operators.yml](/docs/reference_dataset/template_repository/hello-world-root-depls/template/public-config-operators.yml)
    * [public-runtime-operators.yml](/docs/reference_dataset/template_repository/hello-world-root-depls/template/public-runtime-operators.yml)
    * [runtime-config.yml](/docs/reference_dataset/template_repository/hello-world-root-depls/template/runtime-config.yml)
    * [virtualbox](/docs/reference_dataset/template_repository/hello-world-root-depls/template/virtualbox)
  * [terraform-config](/docs/reference_dataset/template_repository/hello-world-root-depls/terraform-config)
    * [spec](/docs/reference_dataset/template_repository/hello-world-root-depls/terraform-config/spec)
      * [local-provider-sample.tf](/docs/reference_dataset/template_repository/hello-world-root-depls/terraform-config/spec/local-provider-sample.tf)
    * [template](/docs/reference_dataset/template_repository/hello-world-root-depls/terraform-config/template)
      * [post-generate.sh](/docs/reference_dataset/template_repository/hello-world-root-depls/terraform-config/template/post-generate.sh)
      * [terraform-tpl.tfvars.yml](/docs/reference_dataset/template_repository/hello-world-root-depls/terraform-config/template/terraform-tpl.tfvars.yml)

## Required pipeline credentials for hello-world-root-depls

### hello-world-root-depls-cf-apps-generated.yml

* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* cf-ops-automation-uri
* concourse-hello-world-root-depls-password
* concourse-hello-world-root-depls-target
* concourse-hello-world-root-depls-username
* paas-templates-branch
* paas-templates-uri
* secrets-branch
* secrets-uri
* slack-channel
* slack-webhook

### hello-world-root-depls-concourse-generated.yml

* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* cf-ops-automation-uri
* concourse-hello-world-root-depls-insecure
* concourse-hello-world-root-depls-password
* concourse-hello-world-root-depls-target
* concourse-hello-world-root-depls-username
* iaas-type
* paas-templates-branch
* paas-templates-uri
* secrets-branch
* secrets-uri
* slack-channel
* slack-webhook

### hello-world-root-depls-generated.yml

* bosh-openstack-cpi-release-version
* bosh-password
* bosh-target
* bosh-username
* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* cf-ops-automation-uri
* concourse-hello-world-root-depls-insecure
* concourse-hello-world-root-depls-password
* concourse-hello-world-root-depls-target
* concourse-hello-world-root-depls-username
* iaas-type
* paas-templates-branch
* paas-templates-uri
* secrets-branch
* secrets-uri
* slack-channel
* slack-webhook
* stemcell-main-name
* stemcell-name-prefix
* stemcell-version

### hello-world-root-depls-init-generated.yml

* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* cf-ops-automation-uri
* concourse-hello-world-root-depls-insecure
* concourse-hello-world-root-depls-password
* concourse-hello-world-root-depls-target
* concourse-hello-world-root-depls-username
* iaas-type
* paas-templates-branch
* paas-templates-uri
* secrets-branch
* secrets-uri
* slack-channel
* slack-webhook

### hello-world-root-depls-news-generated.yml

* bosh-openstack-cpi-release-version
* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* cf-ops-automation-uri
* nginx-version
* ntp-version
* paas-templates-branch
* paas-templates-uri
* secrets-uri
* slack-channel
* slack-webhook
* stemcell-name
* stemcell-version
* vault-version

### hello-world-root-depls-s3-br-upload-generated.yml

* bosh-openstack-cpi-release-version
* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* cf-ops-automation-uri
* concourse-hello-world-root-depls-password
* concourse-hello-world-root-depls-target
* concourse-hello-world-root-depls-username
* github-access-token
* s3-br-access-key-id
* s3-br-bucket
* s3-br-endpoint
* s3-br-region-name
* s3-br-secret-key
* s3-br-skip-ssl-verification
* slack-channel
* slack-webhook

### hello-world-root-depls-s3-stemcell-upload-generated.yml

* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* cf-ops-automation-uri
* concourse-hello-world-root-depls-password
* concourse-hello-world-root-depls-target
* concourse-hello-world-root-depls-username
* s3-stemcell-access-key-id
* s3-stemcell-bucket
* s3-stemcell-endpoint
* s3-stemcell-region-name
* s3-stemcell-secret-key
* s3-stemcell-skip-ssl-verification
* slack-channel
* slack-webhook
* stemcell-version

### hello-world-root-depls-sync-helper-generated.yml

* anonymized-secrets-compare-repo-uri
* anonymized-secrets-repo-uri
* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* cf-ops-automation-uri
* secrets-branch
* secrets-uri
* slack-channel
* slack-webhook

### hello-world-root-depls-tf-generated.yml

* cf-ops-automation-branch
* cf-ops-automation-tag-filter
* cf-ops-automation-uri
* iaas-type
* paas-templates-branch
* paas-templates-uri
* secrets-branch
* secrets-uri
* slack-channel
* slack-webhook

## List of pipelines in which credentials appear for hello-world-root-depls

### anonymized-secrets-compare-repo-uri

* hello-world-root-depls-sync-helper-generated.yml

### anonymized-secrets-repo-uri

* hello-world-root-depls-sync-helper-generated.yml

### bosh-openstack-cpi-release-version

* hello-world-root-depls-generated.yml
* hello-world-root-depls-news-generated.yml
* hello-world-root-depls-s3-br-upload-generated.yml

### bosh-password

* hello-world-root-depls-generated.yml

### bosh-target

* hello-world-root-depls-generated.yml

### bosh-username

* hello-world-root-depls-generated.yml

### cf-ops-automation-branch

* hello-world-root-depls-cf-apps-generated.yml
* hello-world-root-depls-concourse-generated.yml
* hello-world-root-depls-generated.yml
* hello-world-root-depls-init-generated.yml
* hello-world-root-depls-news-generated.yml
* hello-world-root-depls-s3-br-upload-generated.yml
* hello-world-root-depls-s3-stemcell-upload-generated.yml
* hello-world-root-depls-sync-helper-generated.yml
* hello-world-root-depls-tf-generated.yml

### cf-ops-automation-tag-filter

* hello-world-root-depls-cf-apps-generated.yml
* hello-world-root-depls-concourse-generated.yml
* hello-world-root-depls-generated.yml
* hello-world-root-depls-init-generated.yml
* hello-world-root-depls-news-generated.yml
* hello-world-root-depls-s3-br-upload-generated.yml
* hello-world-root-depls-s3-stemcell-upload-generated.yml
* hello-world-root-depls-sync-helper-generated.yml
* hello-world-root-depls-tf-generated.yml

### cf-ops-automation-uri

* hello-world-root-depls-cf-apps-generated.yml
* hello-world-root-depls-concourse-generated.yml
* hello-world-root-depls-generated.yml
* hello-world-root-depls-init-generated.yml
* hello-world-root-depls-news-generated.yml
* hello-world-root-depls-s3-br-upload-generated.yml
* hello-world-root-depls-s3-stemcell-upload-generated.yml
* hello-world-root-depls-sync-helper-generated.yml
* hello-world-root-depls-tf-generated.yml

### concourse-hello-world-root-depls-insecure

* hello-world-root-depls-concourse-generated.yml
* hello-world-root-depls-generated.yml
* hello-world-root-depls-init-generated.yml

### concourse-hello-world-root-depls-password

* hello-world-root-depls-cf-apps-generated.yml
* hello-world-root-depls-concourse-generated.yml
* hello-world-root-depls-generated.yml
* hello-world-root-depls-init-generated.yml
* hello-world-root-depls-s3-br-upload-generated.yml
* hello-world-root-depls-s3-stemcell-upload-generated.yml

### concourse-hello-world-root-depls-target

* hello-world-root-depls-cf-apps-generated.yml
* hello-world-root-depls-concourse-generated.yml
* hello-world-root-depls-generated.yml
* hello-world-root-depls-init-generated.yml
* hello-world-root-depls-s3-br-upload-generated.yml
* hello-world-root-depls-s3-stemcell-upload-generated.yml

### concourse-hello-world-root-depls-username

* hello-world-root-depls-cf-apps-generated.yml
* hello-world-root-depls-concourse-generated.yml
* hello-world-root-depls-generated.yml
* hello-world-root-depls-init-generated.yml
* hello-world-root-depls-s3-br-upload-generated.yml
* hello-world-root-depls-s3-stemcell-upload-generated.yml

### github-access-token

* hello-world-root-depls-s3-br-upload-generated.yml

### iaas-type

* hello-world-root-depls-concourse-generated.yml
* hello-world-root-depls-generated.yml
* hello-world-root-depls-init-generated.yml
* hello-world-root-depls-tf-generated.yml

### nginx-version

* hello-world-root-depls-news-generated.yml

### ntp-version

* hello-world-root-depls-news-generated.yml

### paas-templates-branch

* hello-world-root-depls-cf-apps-generated.yml
* hello-world-root-depls-concourse-generated.yml
* hello-world-root-depls-generated.yml
* hello-world-root-depls-init-generated.yml
* hello-world-root-depls-news-generated.yml
* hello-world-root-depls-tf-generated.yml

### paas-templates-uri

* hello-world-root-depls-cf-apps-generated.yml
* hello-world-root-depls-concourse-generated.yml
* hello-world-root-depls-generated.yml
* hello-world-root-depls-init-generated.yml
* hello-world-root-depls-news-generated.yml
* hello-world-root-depls-tf-generated.yml

### s3-br-access-key-id

* hello-world-root-depls-s3-br-upload-generated.yml

### s3-br-bucket

* hello-world-root-depls-s3-br-upload-generated.yml

### s3-br-endpoint

* hello-world-root-depls-s3-br-upload-generated.yml

### s3-br-region-name

* hello-world-root-depls-s3-br-upload-generated.yml

### s3-br-secret-key

* hello-world-root-depls-s3-br-upload-generated.yml

### s3-br-skip-ssl-verification

* hello-world-root-depls-s3-br-upload-generated.yml

### s3-stemcell-access-key-id

* hello-world-root-depls-s3-stemcell-upload-generated.yml

### s3-stemcell-bucket

* hello-world-root-depls-s3-stemcell-upload-generated.yml

### s3-stemcell-endpoint

* hello-world-root-depls-s3-stemcell-upload-generated.yml

### s3-stemcell-region-name

* hello-world-root-depls-s3-stemcell-upload-generated.yml

### s3-stemcell-secret-key

* hello-world-root-depls-s3-stemcell-upload-generated.yml

### s3-stemcell-skip-ssl-verification

* hello-world-root-depls-s3-stemcell-upload-generated.yml

### secrets-branch

* hello-world-root-depls-cf-apps-generated.yml
* hello-world-root-depls-concourse-generated.yml
* hello-world-root-depls-generated.yml
* hello-world-root-depls-init-generated.yml
* hello-world-root-depls-sync-helper-generated.yml
* hello-world-root-depls-tf-generated.yml

### secrets-uri

* hello-world-root-depls-cf-apps-generated.yml
* hello-world-root-depls-concourse-generated.yml
* hello-world-root-depls-generated.yml
* hello-world-root-depls-init-generated.yml
* hello-world-root-depls-news-generated.yml
* hello-world-root-depls-sync-helper-generated.yml
* hello-world-root-depls-tf-generated.yml

### slack-channel

* hello-world-root-depls-cf-apps-generated.yml
* hello-world-root-depls-concourse-generated.yml
* hello-world-root-depls-generated.yml
* hello-world-root-depls-init-generated.yml
* hello-world-root-depls-news-generated.yml
* hello-world-root-depls-s3-br-upload-generated.yml
* hello-world-root-depls-s3-stemcell-upload-generated.yml
* hello-world-root-depls-sync-helper-generated.yml
* hello-world-root-depls-tf-generated.yml

### slack-webhook

* hello-world-root-depls-cf-apps-generated.yml
* hello-world-root-depls-concourse-generated.yml
* hello-world-root-depls-generated.yml
* hello-world-root-depls-init-generated.yml
* hello-world-root-depls-news-generated.yml
* hello-world-root-depls-s3-br-upload-generated.yml
* hello-world-root-depls-s3-stemcell-upload-generated.yml
* hello-world-root-depls-sync-helper-generated.yml
* hello-world-root-depls-tf-generated.yml

### stemcell-main-name

* hello-world-root-depls-generated.yml

### stemcell-name

* hello-world-root-depls-news-generated.yml

### stemcell-name-prefix

* hello-world-root-depls-generated.yml

### stemcell-version

* hello-world-root-depls-generated.yml
* hello-world-root-depls-news-generated.yml
* hello-world-root-depls-s3-stemcell-upload-generated.yml

### vault-version

* hello-world-root-depls-news-generated.yml

