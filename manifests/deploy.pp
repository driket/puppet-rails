# = define: rails_deploy
#
# Sets up basic requirements for a deploy:
#   * user to run the application as
#   * create directory to deploy app to
#
# Does not handle creating current, releases or shared directories. Capistrano
# already handles that.
#
# == Parameters:
#
# $app_name:: name of the application. Used in the default $deploy_path,
#   "/data/${app_name}". Defaults to the name of the resource.
# $deploy_path:: where the application will be deployed. Defaults to '/data'
# $app_user:: name of the system user to create to run the application as.
#   Defaults to 'deploy'
#
# == Requires:
#
# Nothing.
#
# == Sample Usage:
#
#   rails_deploy { 'todo-list':
#     app_user => 'passenger',
#     deploy_path => '/var/lib/passenger,
#   }
#
define rails::deploy(
  $app_name          = $name,
  $deploy_path       = '/data',
  $app_user          = 'deploy',
  $app_group         = 'deploy',
  $rails_env         = 'production',
  $database_name     = 'UNSET',
  $database_host     = 'localhost',
  $database_adapter  = 'UNSET',
  $database_user     = 'UNSET',
  $database_password = 'UNSET',
  $database_charset  = 'utf8',
  $database_pool     = 5
) {
  $app_path = "${deploy_path}/${app_name}"

  ensure_resource('user', $app_user, {
    ensure     => present,
    system     => true,
    managehome => true,
    home       => "/home/${app_user}",
  })

  ensure_resource('group', $app_group, {
    ensure  => present,
    require => User[$app_user],
  })

  mkdir_p($deploy_path, {
    ensure  => directory,
    mode    => '0755',
  })

  file { $app_path:
    ensure  => directory,
    owner   => $app_user,
    group   => $app_group,
    mode    => '0775',
    require => File[$deploy_path],
  }

  if $database_adapter != 'UNSET' {
    if $database_password == 'UNSET' {
      fail('database_password is required for database.yml')
    }

    if $database_user == 'UNSET' {
      $database_user_real = $app_user
    } else {
      $database_user_real = $database_user
    }

    if $database_name == 'UNSET' {
      $database_name_real = regsubst($app_name, '-', '_', 'G')
    } else {
      $database_name_real = $database_name
    }

    file { ["${app_path}/shared", "${app_path}/shared/config"]:
      ensure => directory,
      owner  => $app_user,
      group  => $app_group,
      mode   => '0775',
    }

    file { "${app_name}-database.yml":
      ensure  => file,
      path    => "${app_path}/shared/config/database.yml",
      owner   => $app_user,
      group   => $app_group,
      content => template('rails/database.yml.erb'),
      mode    => '0644',
      require => File[$app_path],
    }
  }
}
