# GitLab Geo

GitLab Geo provides the ability to have read-only, geographically distributed
application deployments.

While external database services can be used, these documents currently focus on
the use of the [Omnibus GitLab][omnibus] to provide the most platform agnostic
guide.

[omnibus]: https://docs.gitlab.com/omnibus

## Requirements

While this chart has the ability to make use of GitLab Geo functionality. Doing
so has several requirements:

- The use of [external PostgreSQL](../external-db/index.md) services, as the
  included PostgreSQL does is not exposed to outside networks, or currently
  have WAL support required for replication.
- The supplied database must
    - Support replication.
    - The primary database must reachable by the primary application deployment,
      and all secondary database nodes (for replication).
    - Secondary databases only need to be reachable by the secondary application
      deployments.
    - Support SSL between primary and secondary.
- The the primary must be reachable via HTTPS by all secondaries. Secondaries
  must be accessible to the primary via HTTPS.

## Overview

This guide will use 2 Omnibus GitLab instances, configuring only the PostgreSQL
services needed. It is intended to be the _minimal_ required configuration. This
documentation can be expanded in the future to include SSL between all services,
support for other database providers, and promoting a secondary node to primary.

The outline below should be followed in order:

1. Setup of primary database instance.
1. Deploy chart as Geo Primary
1. Setup for secondary database, and replication
1. Set the Geo the primary node
1. Copying secrets from primary application deployment to secondary deployment
1. Deploy chart as Geo Secondary
1. Adding secondary via the primary

## Setup Primary Database Instance

Install an [operating system supported by Omnibus GitLab][og-os], and then
[install the Omnibus GitLab][og-install] onto it. Do not provide the
`EXTERNAL_URL` environment variable when installing, as we'll provide a minimal
configuration file ([sample](db/primary.rb)) before running reconfiguring.



[og-os]: https://docs.gitlab.com/ee/install/requirements.html#operating-systems
[og-install]: https://about.gitlab.com/install/


# RAW OUTLINE

1. Install / configure primary as db (above configuration)
    - sudo su
    - apt-get install ...
    - rm /etc/gitlab/gitlab.rb
    - vim /etc/gitlab/gitlab.rb
    - gitlab-ctl reconfigure
    - gitlab-ctl set-replication-password
    - cat ~gitlab-psql/data/server.crt
        - (alternative) jq -r '.postgresql.internal_certificate' /etc/gitlab/gitlab-secrets.json
1. deploy `geo-primary` helm
    - helm upgrade --install geo-primary path/to/branch -f base.yaml -f geo-primary.yaml
    - Login & upload EE license
1. Install secondary as DBs (above configuration)
    - sudo su
    - apt-get install ...
    - rm /etc/gitlab/gitlab.rb
    - vim /etc/gitlab/gitlab.rb
    - gitlab-ctl reconfigure
1. "setup" secondary
    - verify connectivity to primary => openssl s_client -connect jplum-geo-1.do.gitlap.com:5432 </dev/null
        - want to see 'CONNECTED(00000005), write:errno=0'
    - root@jplum-geo-2:~# vim primary.crt (from above)
    - root@jplum-geo-2:~# install -D -o gitlab-psql -g gitlab-psql -m 0400 -T primary.crt ~gitlab-psql/.postgresql/root.crt
    - sudo    -u gitlab-psql /opt/gitlab/embedded/bin/psql --list -U gitlab_replicator -d "dbname=gitlabhq_production sslmode=verify-ca" -W -h geo-1.db.example.com
    - gitlab-ctl reconfigure ; gitlab-ctl restart postgresql ; gitlab-ctl reconfigure
    - gitlab-ctl replicate-geo-database --slot-name=geo_2 --host=geo-1.db.gitlab.com
1. copy k8s secrets from primary to secondary
    - kubectl get secret geo-primary-rails-secret -o yaml  > geo-secondary-rails-secret.yaml
    - kubectl get secret geo-primary-gitlab-shell-host-keys -o yaml  > geo-secondary-gitlab-shell-host-keys
    - strip annotations, change metadata.labels.release, change metadata.name
    - remove metadata.creationTimestamp, resourceVersion, selfLink, uid
    - (handy dandy jq filter)
1. Set the primary node (via geo-primary-task-runner)
    - gitlab-rake geo:set_primary_node
    - gitlab-rake gitlab:geo:check
1. deploy `geo-secondary` helm
    -  helm upgrade --install geo-secondary path/to/branch -f base.yaml -f geo-secondary.yaml
1. configure geo db (via geo-secondary-task-runner)
    - gitlab-rake geo:db:setup
    - gitlab-rake geo:db:refresh_foreign_tables
    - gitlab-rake gitlab:geo:check
1. [Add secondary node to the Primary](https://docs.gitlab.com/ee/administration/geo/replication/configuration.html#step-3-add-the-secondary-node)
    - https://gitlab-secondary.example.com/
