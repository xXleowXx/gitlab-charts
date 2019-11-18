### Geo Secondary
external_url 'http://gitlab-secondary.example.com'
roles ['geo_secondary_role']
gitlab_rails['auto_migrate'] = false
geo_secondary['auto_migrate'] = false
## turn off everything but the DB
sidekiq['enable']=false
unicorn['enable']=false
gitlab_workhorse['enable']=false
nginx['enable']=false
geo_logcursor['enable']=false
grafana['enable']=false
gitaly['enable']=false
redis['enable']=false
prometheus_monitoring['enable'] = false
## Configure the DBs for network
postgresql['enable'] = true
postgresql['listen_address'] = '0.0.0.0'
postgresql['sql_user_password'] = 'gitlab_user_password_hash'
# !! CAUTION !!
# This list of CIDR addresses should be customized
# - primary application deployment
# - secondary database instance(s)
postgresql['md5_auth_cidr_addresses'] = ['0.0.0.0/0']
geo_postgresql['listen_address'] = '0.0.0.0'
geo_postgresql['sql_user_password'] = 'gitlab_geo_user_password_hash'
# !! CAUTION !!
# This list of CIDR addresses should be customized
# - primary application deployment
# - secondary database instance(s)
geo_postgresql['md5_auth_cidr_addresses'] = ['0.0.0.0/0']
## Settings so we can automatically configure the FDW
geo_secondary['db_fdw'] = true
gitlab_rails['db_password']='gitlab_user_password'
