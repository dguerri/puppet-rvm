#
# Puppet Ruby Version Manager Installation Module. 
#
# Copyright (C) 2010 Davide Guerri (davide.guerri@gmail.com)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#	Usage:
#
#		rvm::system_wide { "rvm": }
#
#	Supported parameters:
#
#		none
#			
#	Defines:	
#		
#		Exec[ "rvm_install" ]
#

define rvm::system_wide ( ) {

	# Setting global parameters and environment
	$working_directory = "/tmp"
	$timeout = 600 # 10 minutes

	Exec { 
		path => [
			'/usr/local/bin',
			'/usr/local/sbin',
			'/usr/bin',
			'/usr/sbin',
			'/bin/',
			'/sbin',
		],
		cwd => $working_directory,
	}

	# Setting up requisites

	case $operatingsystem {
		Ubuntu, Debian: { 
			$required_packages = [ 
				'git-core',
				'libreadline5-dev', 
				'zlib1g-dev', 
				'libssl-dev', 
				'autoconf', 
				'curl', 
				'gettext', 
				'libxml2-dev', 
				'libxslt-dev',
				'libyaml-dev',
				'libncurses5-dev', 
			]
			$profile_path = "/etc/profile.d/rvm.sh"
		}
		RedHat, Fedora, Centos: { # Untested!
			$required_packages = [
				'git', 
				'readline-devel', 
				'zlib-devel', 
				'openssl-devel',
				'autoconf', 
				'curl', 
				'gettext',
				'libxml2-devel', 
				'libxslt-devel',
				'libyaml-devel',
				'ncurses-devel',
			] 
			$profile_path = "/etc/profile.d/rvm.sh" # Untested!
		}
		default: { 
			fail("Unsupported distribution!") 
		}
	}

	package { "rvm_required_packages":
		name => $required_packages,
		ensure => installed,
	}

	file { "rvm_install-system-wide_script":
		path => "${working_directory}/install-system-wide",
		source => "puppet:///rvm/install-system-wide",
		owner => root,
		group => root,
		mode => 644,
		ensure => present,
	}

	# Proceding with install

	exec { "rvm_install":
		command => "bash < ./install-system-wide",
		timeout => $timeout,
		require => [ 
			Package[ "rvm_required_packages" ], 
			File[ "rvm_install-system-wide_script" ] 
		],
		unless => "test -f /usr/local/rvm/scripts/rvm"
	}

	file { "rvm_profile":
		path => $profile_path,
		content => "[[ -s '/usr/local/lib/rvm' ]] && . '/usr/local/lib/rvm'  # This loads RVM into a shell session.",
		owner => root,
		group => root,
		mode => 644,
		ensure => present,
		require => Exec[ "rvm_install" ]
	}

	# Cleanup

	tidy { "rvm_install-system-wide_script_remove":
		path => "${working_directory}",
		require => Exec[ "rvm_install" ],
		recurse => 1,
		matches => [ "install-system-wide" ],
	}

}

