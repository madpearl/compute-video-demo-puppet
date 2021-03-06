gce_instance { 'puppet-enterprise-master':
    ensure       => present,
    description  => 'A PE Master, Console and PuppetDB',
    machine_type => 'n1-standard-1',
    zone         => 'us-central1-a',
    network      => 'default',
    require      => Gce_disk['puppet-enterprise-master'],
    disk         => 'puppet-enterprise-master,boot',
    tags         => ['puppet', 'master'],
    startupscript        => 'puppet-enterprise.sh',
    metadata             => {
      'pe_role'          => 'master',
      'pe_version'       => '3.3.0',
      'pe_consoleadmin'  => 'admin@example.com',
      'pe_consolepwd'    => 'puppetenterprise',
      'setup'            => '
        package { "git":
          ensure => present,
        }

        vcsrepo { "/opt/compute-video-demo-puppet":
          ensure   => present,
          provider => git,
          source   => "https://github.com/GoogleCloudPlatform/compute-video-demo-puppet.git",
          require  => Package["git"],
        }

        file { "/etc/puppetlabs/puppet/autosign.conf":
          ensure  => file,
          content => "*.${domain}",
        }

        file { "/etc/puppetlabs/puppet/manifests/site.pp":
          ensure => file,
          content => "node /^puppet-agent-\\d+/ {
          class { \"apache\": }

          include apache::mod::headers

          file {\"/var/www/index.html\":
            ensure  => present,
            content => template(\"/opt/compute-video-demo-puppet/index.html.erb\"),
            require => Class[\"apache\"],
          }
        }"
      }

      firewall { "100 allow 443 and 8140":
        port   => [8140, 443],
        proto  => tcp,
        action => accept,
      }' 
    },
    modules      => ['puppetlabs-apache', 'puppetlabs-firewall', 'puppetlabs-stdlib', 'puppetlabs-vcsrepo', 'puppetlabs-gce_compute'],
}

gce_disk { "puppet-enterprise-master":
  ensure        => present,
  source_image  => 'centos-6',
  zone          => 'us-central1-a',
  size_gb       => 10,
}

gce_firewall { 'allow-puppet-master':
    ensure      => present,
    network     => 'default',
    description => 'allows incoming 8140 connections',
    allowed     => 'tcp:8140',
}
