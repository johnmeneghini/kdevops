# oscheck

oscheck is a framework to let you easily get
[fstests ](git://git.kernel.org/pub/scm/fs/xfs/xfstests-dev.git)
going, and running with the correct set of parameters for a specific
distribution / stable kernels.

oscheck relies on vagrant, terraform and ansible to get you going
with whatever your virtualization / bare metal / cloud provisioning
environment easily. The vagrant / terraform setup is completely
optional, however ansible *is* used to run oscheck across all hosts.

There are five parts to the long terms ideals for oscheck:

1. Provisioning required virtual hosts for fstests purposes (filesystem specific)
2. Provisioning requirements for building fstests and installing oscheck
3. Running oscheck
4. Collecting results
5. Processing results

Vagrant or terraform can optionally be used for the first part. Vagrant and
terraform are also used to kick off ansible later for the second part of the
provisioning, to get all requirements installed, then to build and install
oscheck and fstests.

Since oscheck has its own set of expunge lists, it is then used to let you run
fstests as easily as possible. By default it should in theory never crash *iff*
the distro you are testing has the respective expunge files set for the
filesystem you are testing. This should let you run fstests against a custom
kernel, for example, to ensure you don't introduce regressions for changes.

Collecting results is next. This is not implemented yet. Its still all manual.
Processing results is also manual, and you can see the results of this effort
on the respective expunge lists for each distro on oscheck. Ideally each
failure is properly tracked with a bz# (redhat) bsc# (suse) or a respective
kernel.org bugzilla (kz#) entry. It is expected someone should be working on
these issues.

What works?

  * Full vagrant provisioning
  * Optionally allowing vagrant to also run oscheck to run a full fstests run
  * Initial terraform provisioning on different cloud providers
  * Running ansible to install dependencies on debian
  * Running oscheck to install dependencies on other distros
  * Running ansible for running oscheck or building a custom kernel and booting into it
  * Running oscheck with a set of expunge files

What's missing?

  * Hooking up terraform with ansible. For this I am considering using [the terraform ansible module](https://registry.terraform.io/modules/radekg/ansible/provisioner/2.2.0).
  * Storage setup when terraform is used in a consistent way for both /data and /media/truncated drives we can use for fstests. Right now the oscheck ansible playbook relies on at least two nvme drives to be available.
  * A way to automate getting your vagrant / cloud provider IP address to your ssh config so we can later run with ansible
  * Processing results -- we should use xunit, ted has some scripts for this already
  * Displaying results: well... hopefully someone will volunteer for this :)

By default Debian testing is used where possible. Support for other
distributions has been added, however upkeeping it is up to the folks interested
in those distributions or the community to at least keep the expunge list up to
date.

## Provisioning

If you are using baremetal just skip the sections about using oscheck. If
you need to provision systems read on.

### Vagrant support - localized VMs

Vagrant is used to easily deploy oscheck non-cloud virtual machines. Below are
the list of providers supported:

  * Virtualbox
  * libvirt (KVM)

The following Operating Systems are supported:

  * OS X
  * Linux

#### Provisioning with vagrant for oscheck

If on Linux we'll assume you are using KVM. If OS X we'll assume you are using
Virtualbox. If these assumptions are incorrect you can override on the
filesystem configuration file of your choise. If using xfs, for example,
you'd edit vagrant/xfs.yaml and set the force_provider variable to either
"libvirt" or "kvm"

You are responsible for having a pretty recent system with some fresh
libvirt, or vitualbox installed. For instance, a virtualbox which supports
nvme. By default additional sparse files are used for the target disks
which will be used for testing fstests.

```bash
cd vagrant/
vagrant up
```

Say you want to just test the provisioning mechanism:

```bash
vagrant provision
```
##### Limitting vagrant's number of boxes

By default the using vagrant will try to create *all* the boxes specified on
the filesystem you are trying to test. By default this is xfs.yml and there
are currently 7 boxes there. If you are going to just test this framework
you can limit this initially using environment variables:

```bash
export OSCHECK_VAGRANT_LIMIT_BOXES="yes"
export OSCHECK_VAGRANT_LIMIT_NUM_BOXES=1
```

This will ensure only oscheck-xfs for example would be created and
provisioned. This might be useful if you are developing oscheck on a laptop,
for example, and you want to limit the amount of resources used by oscheck.

### Terraform support

Terraform is used to deploy oscheck on cloud virtual machines. Below are the
list of clouds currently supported:

  * azure
  * openstack (special minicloud support added)
  * aws

#### Provisioning with terraform with oscheck

```bash
cd terraform/you_provider
make deps
terraform init
terraform plan
terraform apply
```

## Running ansible

Before running ansible make sure you can ssh into the hosts listed on ansible/hosts.

You'd use ansible to provision fstests and oscheck's dependencies, and install
all you need to get going with oscheck. You can also use it to *run* oscheck
in parallel on your shiny systems. Later we'll add playbooks to collect
results and then process them.

```bash
cd ansible/
ansible-playbook -i hosts oscheck.yml
```

### Running oscheck with ansible to do a full fstests run

To use ansible to run oscheck to do a full fstests run you would use:

```bash
$ cat ansible/extra_vars.yml
---
oscheck_run_tests: true
```

```bash
cd ansible/
ansible-playbook -i hosts oscheck.yml --tags "run_tests"
```

### Testinga  custom kernel

Let's say you have a custom kernel you want to test:

```bash
ansible-playbook -i hosts bootlinux.yml
```

# oscheck's primary objective: track a baseline for XFS on latest Linux and Linux stable kernels

oscheck's primary objective is to track baselne results of running fstests for
XFS against:

  * linux-next
  * linux
  * linux-stable kernels listed as supported on kernel.org
  * xfs-linux for-next branch

Different filesystems support can be added at a later time, if there is
interest and a willing maintainer for its respective entries.

## Setup for Tracking xfs-linux for-next branch with a localversion file

oscheck determines which expunge files to use for your kernel buy looking at
your running kernel with uname -r. Since we want to track both Linus' latest
tree, and also xfs-linux for-next branch, and since xfs-linux is based on Linus'
latest tree if we booted into a for-next branch for xfs-linux we'd end up with
the same uname -r. To distinguish these kernels you are encouraged to add an
extra file when building the for-next branch.

The kernel build system appends a tag to your build if you have any file
named prefixed with "localversion-", as such we recommend adding a
localversion-xfs file and with a date to reflect the date matching
the date for you checked out the for-next branch. For instance:

	oscheck@linuxnext-xfs ~/xfs-next (git::xfs-next)$ cat localversion-xfs
	-xfs-20180713

This will produce the following uname -r:

	oscheck@linuxnext-xfs ~/xfs-next (git::xfs-next)$ uname -r
	4.18.0-rc4-xfs-20180713+

This enables oscheck in turn to be able to look at the following directory for
its respective expunge files:

	expunges/4.18.0-rc4-xfs-20180713+

This will typically be a symlink to the linux-next-xfs directory if the
kernel you are building is the latest. Otherwise, it will become a directory
reflecting old results.

# oscheck's secondary objective: track a baseline XFS on different distributions

Different Linux distribution can add support to track the latest Linux and stable
kernels and/or to also track their own kernels if they so wish. oscheck is currently
supported to run on, and a respective baseline can be tracked for the following
distributions:

  * Debian testing
  * OpenSUSE Leap 15.0
  * Fedora 28

# fstest bug triage

  * [xfs bug triage](triage/xfs.md)

## Goals

  * Track latest [fstests ](git://git.kernel.org/pub/scm/fs/xfs/xfstests-dev.git)
  * Keep Linux Distribution agnostic
  * Make it easy to ramp up and use
  * Track fstests issues for all kernels listed as supported on kernel.org
  * Enable addition of different filesystems
  * Enable distributions to track their own fstests issues

## Patches

Please send patches to:

	To: mcgrof@kernel.org

## Requirements

You'll need:

  * A supported distribution
  * clone the latest [fstests ](git://git.kernel.org/pub/scm/fs/xfs/xfstests-dev.git),
    you can then use oscheck.sh --install-deps to install fstests's dependencies.
  * A test system
  * Use existing spare disk or create a qcow2 image for testing

## Install

As root run:

	make install

Review the deployed config and become comfortable with the different supported
sections:

	/var/lib/xfstests/configs/$(hostname).config

To check the dependencies required to compile and install xfstests:

	/var/lib/xfstests/oscheck.sh --check-deps

If you want to try to get oscheck to install the dependencies for you, you
can run the following, your distribution must have support for this on
the respective helpers.sh, for instance opensuse-leap has osfiles/opensuse-leap/helpers.sh.

	/var/lib/xfstests/oscheck.sh --install-deps

After this go compile and install xfstests.

# Run

Once fstests has been installed you can run:

	cd /var/lib/xfstests/
	./gendisks.sh -d
	time ./oscheck.sh | tee log

## Setup

You'll need a guest with plenty of disk space, currently gendisks.sh requires
240 GiB of space for a loopback setup, however in practice this turns out to
currently be about 60 GiB of real disk space required.

## Usage

Provided you've updated what you need to as per above, for example say you are
going run a baseline test with XFS, just as ssh into the guest, and you should
be able to do a full baseline test as follows. No failures are expected to
appear:

	cd /var/lib/xfstests/
	./gendisks.sh -d
	mkfs.xfs -f /dev/loop16
	time ./oscheck.sh | tee log

### Setting up scrach dev - using truncated files - using gendisks.sh

The easiest and most convenient way to test fstests against a filesystem is
to use the base qcow2 images and use the truncated / loopback file setup.
The scratch devices are set up using one truncated file per test parition.
With this approach, after the truncated files are created one uses losetup
to setup a loopback device for each truncated file. When using loopback
devices one may end up testing up to three different filesystems though,
if using a qcow2 image:

  * The filesystem on the host/hypervisor where the qcow image resides, say /opt/qemu/guest.img
  * The guest filesystem where you create the truncated files (say /media/truncated/)
  * The actual filesystem you test with fstests

Using truncated files with loopback devices therefore may create more
issues than typically observed than just using a real bare metal system
with only the target filesystem you want to test. So we may see more
issues, not less than using bare metal. However, since its convenient, and
since tests run fast, we recommend using this setup.

If using truncated files with loopback devices you want to reduce the number of
different filesystem used though. Control over the hypervisor/host and where the
guest image resides is up to the administrator of the guest. As for the guest,
we recommend you create a separate large partition which the filesystem
developer can then use to create create target truncated files. Then, at least as
far as the guest is concerned only one filesystem is used. To aid with this you
can set the environment variable $OSCHECK_TRUNCATE_PATH with the path to where
truncated files will reside. By default $OSCHECK_TRUNCATE_PATH is set to
/media/truncated.

The script gendisks.sh on this repository can be used to easily set up
loopback devices with truncated files and uses the $OSCHECK_TRUNCATE_PATH
directory path for them.

Ensure you take note what filesystem OSCHECK_TRUNCATE_PATH is on.

	./gendisks.sh -d

You should end up with something like:

	# losetup -a
	/dev/loop5: [0803]:1676932 (/media/truncated/disk-sdc5)
	/dev/loop6: [0803]:1679306 (/media/truncated/disk-sdc6)
	/dev/loop7: [0803]:1679307 (/media/truncated/disk-sdc7)
	/dev/loop8: [0803]:1679308 (/media/truncated/disk-sdc8)
	/dev/loop9: [0803]:1679309 (/media/truncated/disk-sdc9)
	/dev/loop10: [0803]:1679310 (/media/truncated/disk-sdc10)
	/dev/loop11: [0803]:1679311 (/media/truncated/disk-sdc11)
	/dev/loop12: [0803]:1679312 (/media/truncated/disk-sdc12)
	/dev/loop13: [0803]:1679313 (/media/truncated/disk-sdc13)
	/dev/loop14: [0803]:1679314 (/media/truncated/disk-sdc14)
	/dev/loop15: [0803]:1679315 (/media/truncated/disk-sdc15)
	/dev/loop16: [0803]:1679316 (/media/truncated/disk-sdc16)

Ensure that the directory matches what you set up for $OSCHECK_TRUNCATE_PATH.

## Expunge files

We need a way to express to skip tests to work with a baseline. fstests tends
to refer to this as "expunging" tests. fstests supports the abilty to specify
an expunge list as a file, and multiple expunge lists can be used.
Comments on expunge files are always ignored. The expected format of the
file is one entry per line, comments after the line are ignored.

We support grooming through this tree's possible expunge files by OS release
and section. You may also optionally triage the failures per priority per
directory. There is a special file "all.txt" which we look for on each
filesystem to allow failures to apply to all sections. This way for instance on
XFS you may want to annotate that a test is failing on section "xfs" and also
on "xfs_reflink", and all other sections on example.config.

Example files with failures due to differenes against the expected golden output
and we're unsure if this is a real issue:

	expunges/opensuse-leap/15.0/unassigned/diff/all.txt
	expunges/opensuse-leap/15.0/unassigned/
	expunges/opensuse-leap/15.0/xfs/diff/xfs.txt
	expunges/opensuse-leap/15.0/xfs/diff/xfs_reflink.txt
	... etc

 Untriaged:

	expunges/opensuse-leap/15.0/xfs/unassigned/all.txt
	expunges/opensuse-leap/15.0/xfs/unassigned/xfs.txt
	expunges/opensuse-leap/15.0/xfs/unassigned/xfs_reflink.txt
	... etc

 Triaged:

	expunges/opensuse-leap/15.0/xfs/unassigned/P1/xfs.txt
	expunges/opensuse-leap/15.0/xfs/unassigned/P1/xfs_nocrc_512.txt
	... etc

 Untriaged:

	expunges/opensuse-leap/15.0/xfs/assigned/all.txt"
	expunges/opensuse-leap/15.0/xfs/assigned/xfs.txt"
	expunges/opensuse-leap/15.0/xfs/assigned/xfs_nocrc_512.txt
	... etc

 Triaged:

	expunges/opensuse-leap/15.0/xfs/assigned/P1/all.txt
	expunges/opensuse-leap/15.0/xfs/assigned/P1/xfs.txt
	expunges/opensuse-leap/15.0/xfs/assigned/P1/xfs_nocrc_512.txt
	expunges/opensuse-leap/15.0/xfs/assigned/P2/all.txt
	expunges/opensuse-leap/15.0/xfs/assigned/P3/xfs_nocrc_512.txt
	expunges/opensuse-leap/15.0/xfs/assigned/xfs.txt
	... etc

## Testing expunge lists

You can test the expunge lists by using a dry run:

	./oscheck.sh -n

This in turn will pass -n to fstests's check which does the same thing.
When -n is used, we don't do any requirements check. If you want to emulate
a different OS you can use the environment variables $OSCHECK_OS_FILE with
a path to an os-release file specific to a target system. This can be used
to test what the expunge list looks like when doing a dry run.

To see the actual files being picked for the expunge list for a release
you can use:

	./oscheck.sh --show-cmd -n

Be sure to set OSCHECK_OS_FILE if you want to emulate an OS file from another
distribution from which you are currently running this on. The path to the
file must be absolute. We carry list of os-release files from different
distributions which you can set OSCHECK_OS_FILE to to test and see what an
expunge files would be used if one runs oscheck.sh on that distribution.

To see the list of possible expunge files for a release use:

	./oscheck.sh --expunge-list -n

To check to see what expunge files would actually be used for opensuse Leap 15.0:

	export OSCHECK_OS_FILE=/home/oscheck/osfiles/opensuse-leap/15.0/os-release
	./oscheck.sh --show-cmd -n

## Parallelizing fstests runs - multiple guests and one test per section

fstests runs serially, since one can run a full set of tests with one section, and since
there are different sections one can tests a filesyste against, one could parallelize
tests by running oscheck against only one specific section per guest. For example,
to run oscheck only against the section xfs_reflink_1024:

	./oscheck --test-section xfs_reflink_1024 | tee log

## Running tests quickly - FAST_TEST

Although ./check supports using the group quick (with -g quick), the quick
group is rather abused and the semantics of how long a tests can run is not
clear. Additionally a thorough filesystem test would run a test against all
known custom sections which are supported.

To help with this we've itemized all tests which are known to take long,
specifically 10 seconds or more on a 4-core qemu system, 4 GiB of RAM on
SSDs, and we can skip all these and all custom sections if you set the
environment variable:

	export FAST_TEST=y

## Adding support for a new distribution

Adding support for a new distribution consists of writing a respective helpers.sh
file. For instance osfiles/distro/helpers.sh. Your distribution may either use
/etc/os-release files or it may rely on lsb_release output information. For the
former you can use the debian helpers.sh file as a templete, otherwise you can
use the opensuse-leap helpers.sh file as a template. If your distribution has
a /etc/os-release file, supply it as a copy under:

	osfiles/your-distro/release/os-release

Once you have a helper file in place for your distsribution test this to ensure
that it can detect if you are running a distro kernel or not:

	./oscheck --is-distro

Likewise test to ensure these work as expected as well:

	./oscheck --check-deps
	./oscheck --install-deps

You will then need to create a baseline. For now you will have to create
expunge files for different failures yourself. Once you have the helpers.sh
file and the expunges files ready, submit them upstream into oscheck.

## qemu kernel configs

For now we supply kernel configs used to build the vanilla / stable kernels tested.
These purposely trimmed to be minimal for use on qemu KVM guests to run a full
fstests. They are under:

	qemu-kernel-configs/

License
-------

This work is licensed under the GPLv2, refer to the [LICENSE](./LICENSE) file
for details. Please stick to SPDX annotations for file license annotations.
If a file has no SPDX annotation the GPLv2 applies. We keep SPDX annotations
with permissive licenses to ensure upstream projects we embraced under
permissive licenses can benefit from our changes to their respective files.
