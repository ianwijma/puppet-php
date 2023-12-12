# This class installs additiona PHP versions,
# !!! CURRENT ONLY RedHat & remi are supported !!
#
# === Parameters
#
# [*version*]
#   The version of the additional PHP version we're trying to install
#   Required
#
# [*extensions*]
#   Install PHP extensions, this is overwritten by hiera hash `php::extensions`
#
# [*fpm*]
#   Install and configure php-fpm
#
class php::additional (
  Optional[String] $version = undef,
  Hash $extensions          = $php::extensions,
  Boolean $fpm              = $php::fpm,
) {
  if $version == undef or $version == '' {
    fail("php::additiona::${title} is missing the required field \"version\"")
  }

  $base_path = "/etc/opt/remi/php${version}"

  anchor { 'additional_php::begin': }
  -> class { 'php::packages':
    names           => ["php${version}"],
    names_to_prefix => [],
  }
  -> anchor { 'additional_php::end': }

  create_resources('php::extension', $extensions, {
    additional_php_version => $version,
    config_root_ini        => "${base_path}/php.d/",
    require                => Class['php::packages'],
    before                 => Anchor['additional_php::end'],
    package_prefix         => "php${version}-",
  })

  if $fpm {
    Anchor['php::begin']
    -> class { 'php::fpm':
      inifile      => "${base_path}/php.ini",
      package      => "php${version}-php-fpm",
      service_name => "php${version}-php-fpm",
      config_file  => "${base_path}/php-fpm.ini",
    }
    -> Anchor['php::end']
  }
}
