Phusion Passenger Security Vulnerability – WHM Server Package Assessment


Reviewed the cPanel security advisory regarding the Phusion Passenger Watchdog API privilege escalation vulnerability across the production WHM servers.

Checked Passenger package installation and versions on the WHM servers.
[sysadmin@whm ~]$ rpm -qa | grep -i passenger
ea-ruby27-mod_passenger-6.1.8-1.el8.cloudlinux.x86_64
ea-ruby27-rubygem-passenger-6.1.8-1.el8.cloudlinux.x86_64

Verified the CloudLinux OS and EA4 package repositories & Confirmed the available package versions.
[root@blazewebtechwhm ~]# yum --disablerepo=EA4-c8 list --showduplicates ea-ruby27-mod_passenger ea-ruby27-rubygem-passenger
Last metadata expiration check: 1:54:22 ago on Fri 14 Aug 2026 07:47:27 AM EDT.
Installed Packages
ea-ruby27-mod_passenger.x86_64                                                                                                1:6.1.8-1.el8.cloudlinux                                                                                                @cl-ea4
ea-ruby27-rubygem-passenger.x86_64                                                                                            1:6.1.8-1.el8.cloudlinux                                                                                                @cl-ea4
Available Packages
ea-ruby27-mod_passenger.x86_64                                                                                                1:6.0.23-1.el8.cloudlinux.1                                                                                             cl-ea4 
ea-ruby27-mod_passenger.x86_64                                                                                                1:6.0.27-1.el8.cloudlinux                                                                                               cl-ea4 
ea-ruby27-mod_passenger.x86_64                                                                                                1:6.1.0-2.el8.cloudlinux                                                                                                cl-ea4 
ea-ruby27-mod_passenger.x86_64                                                                                                1:6.1.1-1.el8.cloudlinux                                                                                                cl-ea4 
ea-ruby27-mod_passenger.x86_64                                                                                                1:6.1.2-1.el8.cloudlinux                                                                                                cl-ea4 
ea-ruby27-mod_passenger.x86_64                                                                                                1:6.1.4-1.el8.cloudlinux                                                                                                cl-ea4 
ea-ruby27-mod_passenger.x86_64                                                                                                1:6.1.5-1.el8.cloudlinux                                                                                                cl-ea4 
ea-ruby27-mod_passenger.x86_64                                                                                                1:6.1.7-1.el8.cloudlinux                                                                                                cl-ea4 
ea-ruby27-mod_passenger.x86_64                                                                                                1:6.1.8-1.el8.cloudlinux                                                                                                cl-ea4 
ea-ruby27-rubygem-passenger.x86_64                                                                                            1:6.0.23-1.el8.cloudlinux.1                                                                                             cl-ea4 
ea-ruby27-rubygem-passenger.x86_64                                                                                            1:6.0.27-1.el8.cloudlinux                                                                                               cl-ea4 
ea-ruby27-rubygem-passenger.x86_64                                                                                            1:6.1.0-2.el8.cloudlinux                                                                                                cl-ea4 
ea-ruby27-rubygem-passenger.x86_64                                                                                            1:6.1.1-1.el8.cloudlinux                                                                                                cl-ea4 
ea-ruby27-rubygem-passenger.x86_64                                                                                            1:6.1.2-1.el8.cloudlinux                                                                                                cl-ea4 
ea-ruby27-rubygem-passenger.x86_64                                                                                            1:6.1.4-1.el8.cloudlinux                                                                                                cl-ea4 
ea-ruby27-rubygem-passenger.x86_64                                                                                            1:6.1.5-1.el8.cloudlinux                                                                                                cl-ea4 
ea-ruby27-rubygem-passenger.x86_64                                                                                            1:6.1.7-1.el8.cloudlinux                                                                                                cl-ea4 
ea-ruby27-rubygem-passenger.x86_64                                                                                            1:6.1.8-1.el8.cloudlinux                                                                                                cl-ea4 

Checked for available security updates and cPanel package integrity.
[root@server ~]# yum updateinfo list security all | grep -i passenger
[root@server ~]# /usr/local/cpanel/scripts/check_cpanel_pkgs --list-only

For affected CloudLinux servers where the patched package is not yet available through the active CloudLinux repository, patching will be monitored and performed once the supported update is released.