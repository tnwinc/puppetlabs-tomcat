# Definition tomcat::config::server::resource
#
# Configure a Resource element in $CATALINA_BASE/conf/server.xml
#
# Parameters:
# - $catalina_base is the root of the Tomcat installation
# - $resource specifies whether you are trying to add or remove the Resource
#   element. Valid values are 'true', 'false', 'present', or 'absent'. Defaults
#   to 'present'.
# - $resource_name is the alias to use.
#   If not specified, defaults to $name.
# - $parent_service is the Service element this Resource should be nested beneath.
#   Defaults to 'Catalina'.
# - $parent_engine is the `name` attribute to the Engine element the Host of this Resource
#   should be nested beneath. Only valid if $parent_host is specified.
# - $parent_host is the `name` attribute to the Host element this Resource
#   should be nested beneath.
# - $parent_context is the `name` attribute to the Context element this Resource
#   should be nested beneath.
# - An optional hash of $additional_attributes to add to the Context. Should be of
#   the format 'attribute' => 'value'.
# - An optional array of $attributes_to_remove from the Context.
#
define tomcat::config::server::resource (
  $catalina_base         = $::tomcat::catalina_home,
  $resource_ensure       = 'present',
  $resource_name         = undef,
  $parent_service        = undef,
  $parent_engine         = undef,
  $parent_host           = undef,
  $parent_context        = undef,
  $additional_attributes = {},
  $attributes_to_remove  = [],
) {
  if versioncmp($::augeasversion, '1.0.0') < 0 {
    fail('Server configurations require Augeas >= 1.0.0')
  }

  validate_re($resource_ensure, '^(present|absent|true|false)$')

  if $resource_name {
    $_resource_name = $resource_name
  } else {
    $_resource_name = $name
  }

  if $parent_service {
    $_parent_service = "Service[#attribute/name='${parent_service}']"
  } else {
    $_parent_service = "Service[#attribute/name='Catalina']"
  }

  if $parent_engine and ! $parent_host {
    warning('alias elements cannot be nested directly under engine elements, ignoring $parent_engine')
  }

  if $parent_engine and $parent_host {
    $_parent_engine = "Engine[#attribute/name='${parent_engine}']"
  } else {
    $_parent_engine = 'Engine'
  }

  if $parent_host {
    $_parent_host = "Host[#attribute/name='${parent_host}']"
  } else {
    $_parent_host = 'Host'
  }

  if $parent_context {
    $_parent_context = "Context[#attribute/docBase='${parent_context}']"
  } else {
    $_parent_context = 'Context'
  }

  $path = "Server/${_parent_service}/${_parent_engine}/${_parent_host}/${_parent_context}/Resource[#attribute/name='${_resource_name}']"


  if $resource_ensure =~ /^(absent|false)$/ {
    $augeaschanges = "rm ${path}"
  } else {
    $resource = "set ${path}/#attribute/name ${_resource_name}"

    if ! empty($additional_attributes) {
      $_additional_attributes = suffix(prefix(join_keys_to_values($additional_attributes, " '"), "set ${path}/#attribute/"), "'")
    } else {
      $_additional_attributes = undef
    }

    if ! empty(any2array($attributes_to_remove)) {
      $_attributes_to_remove = prefix(any2array($attributes_to_remove), "rm ${path}/#attribute/")
    } else {
      $_attributes_to_remove = undef
    }

    $augeaschanges = delete_undef_values(flatten([$resource, $_additional_attributes, $_attributes_to_remove]))
  }

  augeas { "${catalina_base}-${_parent_service}-${_parent_engine}-${parent_host}-${parent_context}-resource-${name}":
    lens    => 'Xml.lns',
    incl    => "${catalina_base}/conf/server.xml",
    changes => $augeaschanges,
  }
}
