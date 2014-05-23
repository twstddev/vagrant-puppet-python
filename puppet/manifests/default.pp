# Variables
$home = "/home/vagrant"
$execute_as_vagrant = "sudo -u vagrant -H bash -l -c"
# use "postgresql" or "mongodb"
$database = "postgresql"

# Set default binary paths 
Exec {
	path => [ "/usr/bin", "/usr/local/bin" ]
}

# Prepare system before main stage
stage { "init": }

class update_apt {
	exec { "apt-get -y update": }
}

class{ "update_apt" :
	stage => init,
}

Stage[ "init" ] -> Stage[ "main" ]

# Main packages
package { "vim":
	ensure => "present",
}

package { "git":
	ensure => "present",
}

package { "curl":
	ensure => "present",
}

package { [ "sqlite3", "libsqlite3-dev" ]:
	ensure => "present",
}

# Install database
case $database {
	"postgresql" : {
		class { "postgresql::server":
			postgres_password => "postgres"
		}
		postgresql::server::db { "app":
			user => "root",
			password => postgresql_password( "root", "root" ),
			require => Class[ "postgresql::server" ],
		}
	}

	"mongodb" : {
		class { "::mongodb::server":
			auth => true,
		}
		mongodb::db { "app":
			user => "root",
			password => "root",
			require => Class[ "::mongodb::server" ],
		}
	}
}

# Install python

