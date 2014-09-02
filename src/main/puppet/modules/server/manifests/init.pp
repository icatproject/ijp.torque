#
# Server
#
class server {

  include torque::server
  include nagios::monitor
  include ganglia::web
  include ganglia::reporter
  include apache2
  include glassfish::server
 
  exec {"tar zxf /root/downloads/ijp-utils-1.0.0.tar.gz main/python/ijp --to-command cat > /usr/local/bin/ijp && chmod 775 /usr/local/bin/ijp":
  	creates => "/usr/local/bin/ijp",
  	path => ["/bin"],
  }
  
  file {"/etc/puppet/modules/server/files/python":
  	ensure => directory,
  }
  
  file {"/etc/puppet/modules/server/files/python/python-ijp-1.0.0.tar.gz":
  	source => "/root/downloads/python-ijp-1.0.0.tar.gz",
  }
   
  file {"/etc/puppet/modules/usergen/manifests/":
  	ensure => "directory",
  	owner => "dmf",
  	group => "dmf",
  	require => Common_account["dmf"],
  }
  
  file {"/etc/puppet/modules/usergen/manifests/init.pp":
  	ensure => "file",
  	owner => "dmf",
  	group => "dmf",
  	require => User["dmf"],
  }
  
   file {"/home/dmf/bin/wakeup":
    ensure => "file",
    source => "puppet:///modules/server/wakeup", 
    owner => "dmf",
    group => "dmf",
    mode => "0500",
    require => User[ "dmf" ],
  }

  firewall { "100 open port 8140 for puppet":
    proto => tcp,
    port => 8140,
    action => accept,
  }

  firewall { "100 open port 5432 for postgresql":
    proto => tcp,
    port => 5432,
    action => accept,
  }
 
  firewall { "100 open port 8081 for puppetdb":
    proto => tcp,
    port => 8081,
    action => accept,
  }
  
  firewall { "100 open port 4848 for glassfish admin":
    proto => tcp,
    port => 4848,
    action => accept,
  }
  
  firewall { "100 open port 8080 for glassfish":
    proto => tcp,
    port => 8080,
    action => accept,
  }
  
  firewall { "100 open port 1099 for puppetdb - this one is not understood":
    proto => tcp,
    port => 1099,
    action => accept,
  }
       
  file {"dmf.profile":
    ensure => present,
    path => "/home/dmf/.profile",
    source => "puppet:///modules/server/dmf.profile",
    owner => "dmf",
    group => "dmf",
    require => User["dmf"],
  }
  
  file {"dmf.portal_submissions":
    ensure => directory,
    path => "/home/dmf/portal_submissions",
    owner => "dmf",
    group => "dmf",
    require => User["dmf"],
  }

  sudoers_entry{"dmf_on_server":}

  file {"/etc/security/limits.conf":
    ensure => "file",
    source => "puppet:///modules/server/etc/security/limits.conf",
    owner => "root",
    group => "root",
    mode => "0644",
  }

  file {"/etc/pam.d/su":
    ensure => "file",
    source => "puppet:///modules/server/etc/pam.d/su",
    owner => "root",
    group => "root",
    mode => "0644",
  }
  
   if $fqdn == "rclsfserv010.rc-harwell.ac.uk" {
    $ids_main_dir = "/mnt/data/ids"
    $ids_archive_dir = "/mnt/rhubarb/ids"

    file { "/mnt/rhubarb": ensure => "directory", }

    mount { "/mnt/rhubarb":
      device  => "rhubarb.ads.rl.ac.uk:/vol2/rallsf",
      fstype  => "nfs",
      ensure  => "mounted",
      options => "user,rsize=32768,wsize=32768,hard,intr",
      atboot  => true,
      require => [File["/mnt/rhubarb"], Package["nfs-common"]],
      notify  => Exec["${ids_archive_dir}"],
    }

    # Root can't see it - only dmf
    exec { "${ids_archive_dir}":
      user        => "dmf",
      path        => "/bin",
      command     => "mkdir -p ${ids_archive_dir}",
      refreshonly => true,
    }

    file { ["${ids_main_dir}"]:
      ensure  => directory,
      owner   => dmf,
      group   => dmf,
      require => User["dmf"],
    }

  } else {
    $ids_main_dir = "/home/dmf/ids/main"
    $ids_archive_dir = "/home/dmf/ids/archive"

    file { ["/home/dmf/ids", "${ids_main_dir}", "$ids_archive_dir"]:
      ensure  => directory,
      owner   => dmf,
      group   => dmf,
      require => User["dmf"],
    }

  }

  file { "ids.storage_file.main.properties":
    path    => "/home/dmf/install/config/ids.storage_file.main.properties",
    content => "dir = ${ids_main_dir}",
    owner   => dmf,
    group   => dmf,
    require => User["dmf"],
  }

  file { "ids.storage_file.archive.properties":
    path    => "/home/dmf/install/config/ids.storage_file.archive.properties",
    content => "dir = ${ids_archive_dir}",
    owner   => dmf,
    group   => dmf,
    require => User["dmf"],
  }

  file { "/home/dmf/ingestion":
    ensure => "directory",
    owner  => "dmf",
    group  => "dmf",
  }

  file { "/home/dmf/ingestion/ingest.py":
    ensure => "file",
    source => "puppet:///modules/server_lsf/ingest.py",
    owner  => "dmf",
    group  => "dmf",
    mode   => "0770",
  }

  file { "/home/dmf/ingestion/launcher":
    ensure => "file",
    source => "puppet:///modules/server_lsf/launcher",
    owner  => "dmf",
    group  => "dmf",
    mode   => "0770",
  }

  exec { "run_ingest":
    path     => "/bin",
    cwd      => "/home/dmf/ingestion",
    command  => "su dmf -c ./launcher",
    unless   => "[ -f pidfile ] && ps $(cat pidfile) >> /dev/null",
    provider => "shell",
  }

  file { "ijp.properties":
    path    => "/home/dmf/install/config/ijp",
    source  => "puppet:///modules/server_lsf/config/ijp",
    recurse => true,
    purge   => false,
    owner   => "dmf",
    group   => "dmf",
  }

  file { "/etc/puppet/modules/server/files/python/python-ijp_lsf-1.0.0.tar.gz": source => "/root/downloads/python-ijp_lsf-1.0.0.tar.gz", 
  }

  file { "/usr/local/etc/icat.dump": source => "puppet:///modules/server_lsf/db/icat.dump", }

  file { "/usr/local/sbin/post-db.sh":
    source => "puppet:///modules/server_lsf/db/post-db.sh",
    mode   => "0700",
  }

  exec { "post-db.sh":
    cwd     => "/usr/local/etc/",
    path    => ["/usr/local/sbin", "/usr/bin"],
    require => File["/usr/local/etc/icat.dump", "/usr/local/sbin/post-db.sh"],
    onlyif  => "[ -n $(echo 'select * from FACILITY;' | mysql -u icat -picat icat) ]"
  }
   
}