# Variables
$home = "/home/vagrant"
$execute_as_vagrant = "sudo -u vagrant -H bash -l -c"
# use "postgresql" or "mongodb"
$database = "postgresql"

# use "Django or Flask"
$framework = "Django"

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

package { "build-essential":
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
# This installation follows instructions from https://github.com/yyuu/pyenv
$pyenv_path = "${home}/.pyenv"
$pyenv = "${pyenv_path}/bin/pyenv"
$shims = "${pyenv_path}/shims"
$dev_env = "${home}/development"

exec { "clone_pyenv":
	command => "${execute_as_vagrant} 'cd && git clone git://github.com/yyuu/pyenv.git .pyenv'"
}

file_line { "PYENV_ROOT":
	path => "${home}/.bashrc",
	line => 'export PYENV_ROOT="$HOME/.pyenv"',
}

file_line { "PATH":
	path => "${home}/.bashrc",
	line => 'export PATH="$PYENV_ROOT/bin:$PATH"',
}

file_line { "EVAL":
	path => "${home}/.bashrc",
	line => 'eval "$(pyenv init -)"',
}

exec { "install_python":
	command => "${execute_as_vagrant} '${pyenv} install 3.4.1'",
	timeout => 0,
}

exec { "rehash":
	command => "${execute_as_vagrant} '${pyenv} rehash && ${pyenv} global 3.4.1'",
}

exec { "install_virtualenv":
	command => "${execute_as_vagrant} '${shims}/pip install virtualenv'",
}

exec{ "create_app_virtualenv":
	command => "${execute_as_vagrant} '${shims}/virtualenv ${dev_env}'",
}

exec{ "install_framework":
	command => "${execute_as_vagrant} '${dev_env}/bin/pip install ${framework}'",
	timeout => 0,
}

Package[ "build-essential" ] ->
	Package[ "git" ] ->
	Exec[ "clone_pyenv" ] ->
	File_line[ "PYENV_ROOT" ] ->
	File_line[ "PATH" ] ->
	File_line[ "EVAL" ] ->
	Exec[ "install_python" ] ->
	Exec[ "rehash" ] ->
	Exec[ "install_virtualenv" ] ->
	Exec[ "create_app_virtualenv" ] ->
	Exec[ "install_framework" ]
