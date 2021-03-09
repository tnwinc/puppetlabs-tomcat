# Definition tomcat::config::server::alias
#
# Configure an Alias element in $CATALINA_BASE/conf/server.xml
#
# Parameters:
# - $catalina_base is the root of the Tomcat installation
# - $alias_ensure specifies whether you are trying to add or remove the Context
#   element. Valid values are 'true', 'false', 'present', or 'absent'. Defaults
#   to 'present'.
# - $alias_name is the alias to use.
#   If not specified, defaults to $name.
# - $parent_service is the Service element this Context should be nested beneath.
#   Defaults to 'Catalina'.
# - $parent_engine is the `name` attribute to the Engine element the Host of this Context
#   should be nested beneath. Only valid if $parent_host is specified.
# - $parent_host is the `name` attribute to the Host element this Context
#   should be nested beneath.
#
define tomcat::config::server::alias (
  $catalina_base         = $::tomcat::catalina_home,
  $alias_ensure        = 'present',
  $alias_name            = undef,
  $parent_service        = undef,
  $parent_engine         = undef,
  $parent_host           = undef,
) {
  if versioncmp($::augeasversion, '1.0.0') < 0 {
    fail('Server configurations require Augeas >= 1.0.0')
  }

  validate_re($alias_ensure, '^(present|absent|true|false)$')

  if $alias_name {
    $_alias_name = $alias_name
  } else {
    $_alias_name = $name
  }

  if $parent_service {
    $_parent_service = $parent_service
  } else {
    $_parent_service = 'Catalina'
  }

  if $parent_engine and ! $parent_host {
    warning('alias elements cannot be nested directly under engine elements, ignoring $parent_engine')
  }

  if $parent_engine and $parent_host {
    $_parent_engine = $parent_engine
  } else {
    $_parent_engine = undef
  }

  if $parent_host and ! $_parent_engine {
    $path = "Server/Service[#attribute/name='${_parent_service}']/Engine/Host[#attribute/name='${parent_host}']/Alias[#text='${_alias_name}']"
  } elsif $parent_host and $_parent_engine {
    $path = "Server/Service[#attribute/name='${_parent_service}']/Engine[#attribute/name='${_parent_engine}']/Host[#attribute/name='${parent_host}']/Alias[#text='${_alias_name}']"
  } else {
    $path = "Server/Service[#attribute/name='${_parent_service}']/Engine/Host/Alias[#text='${_alias_name}']"
  }

  if $alias_ensure =~ /^(absent|false)$/ {
    $augeaschanges = "rm ${path}"
  } else {
    $alias = "set ${path}/#text ${_alias_name}"

    $augeaschanges = delete_undef_values(flatten([$alias]))
  }

  augeas { "${catalina_base}-${_parent_service}-${_parent_engine}-${parent_host}-alias-${name}":
    lens    => 'Xml.lns',
    incl    => "${catalina_base}/conf/server.xml",
    changes => $augeaschanges,
  }
}
