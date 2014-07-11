# == Class: nslcd
#
# Puppet module for a daemon for NSS and PAM lookups using LDAP.
#
# === Parameters
#
# === Variables
#
# === Examples
#
#  include nslcd
#
# === Authors
#
# Callum Dickinson <callum@huttradio.co.nz>
#
# === Copyright
#
# Copyright 2014 Callum Dickinson.
#
class nslcd
(
	# Boolean variable to control whether or not we automatically
	# configure /etc/nsswitch.conf for LDAP directory search.
	$configure_nsswitch	=> true,
	$nsswitch_conf		=> "/etc/nsswitch.conf",

	# Packages to install.
	$nslcd_packages			= $::osfamily ?
	{
		'Debian'	=> [ "libnss-ldapd" ],
		default		=> undef,
	},

	$kstart_packages		= $::osfamily ?
	{
		'Debian'	=> [ "k5start", "libpam-krb5" ],
		default		=> undef,
	},

	# Services to start and enable.
	$nslcd_service			= $::osfamily ?
	{
		'Debian'	=> 'nslcd',
		default		=> undef,
	},

	# Location of nslcd.conf.
	$nslcd_conf			= $::osfamily ?
	{
		default		=> "/etc/nslcd.conf",
	},

	# nslcd.conf options
	$threads			= undef,
	$uid				= "nslcd",
	$gid				= $::osfamily ?
	{
		'RedHat'	=> "ldap",
		default		=> "nslcd",
	},

	$uri				= "ldapi:///",
	$ldap_version			= undef,
	$binddn				= undef,
	$bindpw				= undef,
	$rootpwmoddn			= undef,
	$rootpwmodpw			= undef,
	
	$sasl_mech			= undef,
	$sasl_realm			= undef,
	$sasl_authcid			= undef,
	$sasl_authzid			= undef,
	
	$sasl_secprops			= undef,
	$sasl_canonicalize		= undef,
	
	$krb5_ccname			= undef,
	
	$base				= undef,
	$scope				= undef,
	$deref				= undef,
	$referrals			= undef,
	$filter				= undef,
	$map				= undef,
	
	$bind_timelimit			= undef,
	$timelimit			= undef,
	$idle_timelimit			= undef,
	$reconnect_sleeptime		= undef,
	$reconnect_retrytime		= undef,
	
	$ssl				= undef,
	$tls_reqcert			= undef,
	$tls_cacertdir			= undef,
	$tls_cacertfile			= undef,
	$tls_randfile			= undef,
	$tls_ciphe			= undef,
	$tls_cert			= undef,
	$tls_key			= undef,
	
	$pagesize			= undef,
	$nss_initgroups_ignoreusers	= undef,
	$nss_min_uid			= undef,
	$validnames			= undef,
	$ignorecase			= undef,
	$pam_authz_search		= undef,
	$pam_password_prohibit_message	= undef
)
{
	case $::osfamily
	{
		/^[^(Debian)]$/:
		{
			fail("Sorry, but nslcd does not support the $::osfamily OS family at this time")
		}
	}

	# Configure packages to install.
	if (is_string($krb5_ccname))
	{
		$packages = flatten($nslcd_packages, $kstart_packages)
	}
	else
	{
		$packages = $nslcd_packages
	}

	# Install packages.
	package
	{ $packages:
		ensure	=> installed,
	}

	# Install the nslcd.conf template.
	file
	{ $nslcd_conf:
		owner	=> "root",
		group	=> "root",
		mode	=> "444",
		content	=> template("nslcd/nslcd.conf"),
	}

	# Configure /etc/nsswitch.conf for LDAP directory search.
	if ($configure_nsswitch)
	{
		augeas
		{ "nslcd::nsswitch_conf":
			context	=> "/files$nsswitch_conf/",
			changes	=>
			[
				"set database[. = 'passwd']/service[. = 'ldap'] ldap",
				"set database[. = 'group']/service[. = 'ldap'] ldap",
				"set database[. = 'shadow']/service[. = 'ldap'] ldap",
			],
		}
	}

	# Make sure the service is running.
	service
	{ $nslcd_service:
		ensure	=> running,
		enable	=> true,
		require	=> [ Package[$packages], File[$nslcd_conf], Augeas["nslcd::nsswitch_conf"] ],
	}
	
}
