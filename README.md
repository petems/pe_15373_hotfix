# Overview

This puppet module will pluginsync Ruby 1.8.7 compatible versions of PE specific facts.

# Module Description

Old Puppet (eg. pre Puppet 4) uses the system Ruby. CentOS/RHEL 6's system ruby is 1.8.7 by default:

```
[root@centos-6-puppet-38 ~]# rpm -qa puppet
puppet-3.8.7-1.el6.noarch
[root@centos-6-puppet-38 ~]# rpm -qa puppet
puppet-3.8.7-1.el6.noarch
[root@centos-6-puppet-38 ~]# ruby -v
ruby 1.8.7 (2013-06-27 patchlevel 374) [x86_64-linux]
```


This is a super EOL version of Ruby with a lot of missing features, for example, no "relative_require"

When migrating a 3.8 machine to newer Puppet, you might see this message because of this:

```bash
[root@centos-6-puppet-38 ~]# puppet agent -t
Info: Loading facts
Error: Could not retrieve local facts: undefined method `require_relative' for main:Object
Error: Failed to apply catalog: Could not retrieve local facts: undefined method `require_relative' for main:Object
```

When run with `--trace`, the issue becomes clear:

```
[root@centos-6-puppet-38 ~]# puppet agent -t --trace
puppet agent -t --server=pe-201731-master.puppetdebug.vlan --trace
Info: Retrieving pluginfacts
Info: Retrieving plugin
Info: Loading facts
Error: Could not retrieve local facts: undefined method `require_relative' for main:Object
/var/lib/puppet/lib/facter/pe_server_version.rb:1
```

Because Ruby 1.8.7 doesn't have `require_relative`

From Puppet 4 onward, we bundle Ruby in with Puppet, avoiding these imcompatibility issues.

However, during the transition this can block the migration before the upgrade of the package.

```
[root@foss-38 vagrant]# puppet agent -t --server=pe-201731-master.puppetdebug.vlan --trace
Info: Retrieving pluginfacts
Info: Retrieving plugin
Notice: /File[/var/lib/puppet/lib/facter/pe_server_version.rb]/content:
--- /var/lib/puppet/lib/facter/pe_server_version.rb 2017-11-03 19:31:21.958738288 +0000
+++ /tmp/puppet-file20171103-9714-19681cs-0 2017-11-03 19:34:56.041726285 +0000
@@ -1,3 +1,11 @@
+unless Kernel.respond_to?(:require_relative)
+  module Kernel
+    def require_relative(path)
+      require File.join(File.dirname(caller[0]), path.to_str)
+    end
+  end
+end
+
 require_relative '../shared/pe_server_version'

 # This only works on server nodes.  It relies on the presence of the file

Notice: /File[/var/lib/puppet/lib/facter/pe_server_version.rb]/content: content changed '{md5}17c2795fe8a56b731ae0fc81ba147e6a' to '{md5}72e0b511f3c1ea0d017cbe4d4c16de49'
Info: Loading facts
Info: Caching catalog for centos-6-puppet-38.puppet.vm
Info: Applying configuration version '1509737699'
Info: Creating state file /var/lib/puppet/state/state.yaml
Notice: Finished catalog run in 0.03 seconds
```

After the transition to Puppet 4, which will have the newer Ruby, this module is no longer needed and should be removed to avoid overwriting changes to those facts in newer versions of Puppet Enterprise:

```
[root@centos-6-puppet-38 ~]# puppet agent -t
Info: Using configured environment 'production'
Info: Retrieving pluginfacts
Info: Retrieving plugin
Notice: /File[/opt/puppetlabs/puppet/cache/lib/facter/pe_server_version.rb]/content:
--- /opt/puppetlabs/puppet/cache/lib/facter/pe_server_version.rb  2017-11-03 20:00:36.266453780 +0000
+++ /tmp/puppet-file20171103-10848-u7e0ss 2017-11-03 20:00:55.583107275 +0000
@@ -1,11 +1,3 @@
-unless Kernel.respond_to?(:require_relative)
-  module Kernel
-    def require_relative(path)
-      require File.join(File.dirname(caller[0]), path.to_str)
-    end
-  end
-end
-
 require_relative '../shared/pe_server_version'

 # This only works on server nodes.  It relies on the presence of the file

Notice: /File[/opt/puppetlabs/puppet/cache/lib/facter/pe_server_version.rb]/content: content changed '{md5}72e0b511f3c1ea0d017cbe4d4c16de49' to '{md5}17c2795fe8a56b731ae0fc81ba147e6a'
Info: Loading facts
Info: Caching catalog for centos-6-puppet-38.puppet.vm
Info: Applying configuration version '1509739257'
Notice: Applied catalog in 0.48 seconds
```

