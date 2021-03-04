# SPDX-License-Identifier: GPL-2.0

source ${TOPDIR}/scripts/lib_terraform.sh
source ${TOPDIR}/scripts/aws/lib.sh
source ${TOPDIR}/scripts/gce/lib.sh
source ${TOPDIR}/scripts/azure/lib.sh
source ${TOPDIR}/scripts/openstack/lib.sh

ANSIBLE_ENABLE=$CONFIG_KDEVOPS_ANSIBLE_PROVISION_ENABLE
PLAYBOOKDIR=$CONFIG_KDEVOPS_PLAYBOOK_DIR
INVENTORY=$CONFIG_KDEVOPS_ANSIBLE_INVENTORY_FILE
export KDEVOPSHOSTSPREFIX=$CONFIG_KDEVOPS_HOSTS_PREFIX

MANUAL_KILL_NOTICE_FILE="${TOPDIR}/.running_kill_pids.sh"

KERNEL_CI_FAIL_FILE=".kernel-ci.fail"
KERNEL_CI_OK_FILE=".kernel-ci.ok"
KERNEL_CI_FULL_LOG=".kernel-ci.log"
KERNEL_CI_FAIL_LOG=".kernel-ci.fail.log"
KERNEL_CI_DIFF_LOG=".kernel-ci.diff.log"
KERNEL_CI_LOGTIME=".kernel-ci.logtime.loop"
KERNEL_CI_LOGTIME_FULL=".kernel-ci.logtime.full"

KERNEL_CI_WATCHDOG_LOG=".kernel-ci.watchdog.log"
KERNEL_CI_WATCHDOG_RESULTS_NEW=".kernel-ci.status.new"
KERNEL_CI_WATCHDOG_RESULTS=".kernel-ci.status"

KERNEL_CI_WATCHDOG_FAIL_LOG=".kernel-ci.watchdog.fail.log"
KERNEL_CI_WATCHDOG_HUNG=".kernel-ci.watchdog.hung"
KERNEL_CI_WATCHDOG_TIMEOUT=".kernel-ci.watchdog.timeout"

KOTD_LOG=".kotd.log"
KOTD_TMP="${KOTD_LOG}.tmp"
KOTD_BEFORE=".kotd.uname-before.txt"
KOTD_AFTER=".kotd.uname-after.txt"
KOTD_LOGTIME=".kotd.logtime"

FSTESTS_STARTED_FILE="${TOPDIR}/workflows/fstests/.begin"
BLKTESTS_STARTED_FILE="${TOPDIR}/workflows/blktests/.begin"

if [[ "$CONFIG_KDEVOPS_WORKFLOW_FSTESTS" == "y" ]]; then
	FSTYP="$CONFIG_FSTESTS_FSTYP"
	TEST_DEV="$CONFIG_FSTESTS_TEST_DEV"
fi

SKIPANSIBLE="false"
ENABLEANSIBLE="true"
if [[ "$ANSIBLE_ENABLE" != "y" ]]; then
	SKIPANSIBLE="true"
	ENABLEANSIBLE="false"
fi

cat_template_hosts_sed()
{
	cat $1 | sed -e \
		'
		s|@KDEVOPSPYTHONINTERPRETER@|'"$KDEVOPSPYTHONINTERPRETER"'|g;
		s|@KDEVOPSPYTHONOLDINTERPRETER@|'"$KDEVOPSPYTHONOLDINTERPRETER"'|g;
		s|@KDEVOPSHOSTSPREFIX@|'"$KDEVOPSHOSTSPREFIX"'|g;
		' | cat -s
}

cat_template_nodes_sed()
{
	cat $1 | sed -e \
		'
		s|@VAGRANTBOX@|'"$VAGRANTBOX"'|g;
		s|@VBOXVERSION@|'$VBOXVERSION'|g;
		s|@SKIPANSIBLE@|'$SKIPANSIBLE'|g;
		s|@PROVISIONPLAYBOOK@|'$PROVISIONPLAYBOOK'|g;
		s|@PLAYBOOKDIR@|'$PLAYBOOKDIR'|g;
		s|@KDEVOPSHOSTSPREFIX@|'"$KDEVOPSHOSTSPREFIX"'|g;
		' | cat -s
}

cat_template_terraform_sed()
{
	cat $1 | sed -e \
		'
		s|@LIMITBOXES@|'"$LIMITBOXES"'|g;
		s|@LIMITNUMBOXES@|'"$LIMITNUMBOXES"'|g;
		s|@AWSREGION@|'$AWSREGION'|g;
		s|@AWSAVREGION@|'$AWSAVREGION'|g;
		s|@AWSNAMESEARCH@|'$AWSNAMESEARCH'|g;
		s|@AWSVIRTTYPE@|'$AWSVIRTTYPE'|g;
		s|@AWSAMIOWNER@|'$AWSAMIOWNER'|g;
		s|@AWSINSTANCETYPE@|'$AWSINSTANCETYPE'|g;
		s|@AZURERESOURCELOCATION@|'$AZURERESOURCELOCATION'|g;
		s|@AZUREVMSIZE@|'$AZUREVMSIZE'|g;
		s|@AZUREMANAGEDDISKTYPE@|'$AZUREMANAGEDDISKTYPE'|g;
		s|@AZUREIMAGEPUBLISHER@|'$AZUREIMAGEPUBLISHER'|g;
		s|@AZUREIMAGEOFFER@|'$AZUREIMAGEOFFER'|g;
		s|@AZUREIMAGESKU@|'$AZUREIMAGESKU'|g;
		s|@AZUREIMAGEVERSION@|'$AZUREIMAGEVERSION'|g;
		s|@AZURECLIENTCERTPATH@|'$AZURECLIENTCERTPATH'|g;
		s|@AZURECLIENTCERTPASSWD@|'$AZURECLIENTCERTPASSWD'|g;
		s|@AZUREAPPLICATIONID@|'$AZUREAPPLICATIONID'|g;
		s|@AZURESUBSCRIPTIONID@|'$AZURESUBSCRIPTIONID'|g;
		s|@AZURETENANTID@|'$AZURETENANTID'|g;
		s|@GCEPROJECT@|'$GCEPROJECT'|g;
		s|@GCEREGION@|'$GCEREGION'|g;
		s|@GCEMACHINETYPE@|'$GCEMACHINETYPE'|g;
		s|@GCESCRATCHDISKTYPE@|'$GCESCRATCHDISKTYPE'|g;
		s|@GCEIMAGENAME@|'$GCEIMAGENAME'|g;
		s|@GCECREDENTIALS@|'$GCECREDENTIALS'|g;
		s|@OPENSTACKCLOUD@|'$OPENSTACKCLOUD'|g;
		s|@OPENSTACKPREFIX@|'$OPENSTACKPREFIX'|g;
		s|@OPENSTACKFLAVOR@|'$OPENSTACKFLAVOR'|g;
		s|@OPENSTACKIMAGE@|'"$OPENSTACKIMAGE"'|g;
		s|@OPENSTACKKEYNAME@|'$OPENSTACKKEYNAME'|g;
		s|@SSHCONFIGPUBKEYFILE@|'$SSHCONFIGPUBKEYFILE'|g;
		s|@SSHCONFIGUSER@|'$SSHCONFIGUSER'|g;
		s|@SSHCONFIGUPDATE@|'$SSHCONFIGUPDATE'|g;
		s|@SSHCONFIGFILE@|'$SSHCONFIGFILE'|g;
		s|@SSHCONFIGSTRICT@|'$SSHCONFIGSTRICT'|g;
		s|@SSHCONFIGBACKUP@|'$SSHCONFIGBACKUP'|g;
		s|@ENABLEANSIBLE@|'$ENABLEANSIBLE'|g;
		s|@PROVISIONPLAYBOOK@|'$PROVISIONPLAYBOOK'|g;
		s|@PLAYBOOKDIR@|'$PLAYBOOKDIR'|g;
		s|@INVENTORY@|'$INVENTORY'|g;
		' | cat -s
}

cat_fstests_config_sed()
{
	cat $1 | sed -e \
		'
		s|@FSTESTSTESTDEV@|'$FSTESTSTESTDEV'|g;
		s|@FSTESTSDIR@|'$FSTESTSDIR'|g;
		s|@FSTESTSSCRATCHDEVPOOL@|'"$FSTESTSSCRATCHDEVPOOL"'|g;
		s|@FSTESTSSCRATCHMNT@|'$FSTESTSSCRATCHMNT'|g;
		s|@FSTESTSLOGWRITESDEV@|'$FSTESTSLOGWRITESDEV'|g;
		s|@FSTESTSSCRATCHLOGDEV@|'$FSTESTSSCRATCHLOGDEV'|g;
		s|@FSTESTSSCRATCHRTDEV@|'$FSTESTSSCRATCHRTDEV'|g;
		' | cat -s
}

add_host_entry()
{
	TARGET_HOST=$1
	SECOND_IP=$2
	TARGET_FILE=$3

	echo "  - name: $TARGET_HOST" >> $TARGET_FILE
	echo "    ip: $SECOND_IP" >> $TARGET_FILE

	if [[ "$CONFIG_HAVE_DISTRO_LACKS_SUPPORT_FOR_NVME" == "y" ]]; then
		echo "    lacks_nvme_support: true" >> $TARGET_FILE
	fi

	if [[ "$CONFIG_HAVE_DISTRO_LACKS_SUPPORT_FOR_VIRTIO_DRIVE" == "y" ]]; then
		echo "    lacks_drive_virtio: true" >> $TARGET_FILE
	fi
}

generic_generate_nodes_file()
{
	TMP_INIT_NODE=$(mktemp)
	if [ ! -f $TMP_INIT_NODE ]; then
		echo "Cannot create temporary file: $TMP_INIT_NODE do you have mktemp installed?"
		exit 1
	fi
	TMP_FINAL_NODE=$(mktemp)
	if [ ! -f $TMP_FINAL_NODE ]; then
		echo "Cannot create temporary file: $TMP_FINAL_NODE"
		exit 1
	fi

	cp $GENERIC_SPLIT_START $TMP_INIT_NODE

	SECOND_IP_START="172.17.8."
	IP_LAST_OCTET_START="100"
	CURRENT_IP="1"
	let IP_LAST_OCTET="$IP_LAST_OCTET_START+$CURRENT_IP"
	SECOND_IP="${SECOND_IP_START}${IP_LAST_OCTET}"
	TARGET_HOSTNAME="${KDEVOPSHOSTSPREFIX}"
	if [[ "$TARGET_HOSTNAME" == "" ]]; then
		echo "Empty hostname, you probably forgot to define the"
		echo "CUSTOM_DISTRO_HOST_PREFIX for your distribution, fix"
		echo "that and try again".

		exit 1
	fi
	add_host_entry $TARGET_HOSTNAME $SECOND_IP $TMP_INIT_NODE

	let CURRENT_IP="$CURRENT_IP+1"
	if [[ "$CONFIG_KDEVOPS_BASELINE_AND_DEV" == "y" ]]; then
		let IP_LAST_OCTET="$IP_LAST_OCTET_START+$CURRENT_IP"
		SECOND_IP="${SECOND_IP_START}${IP_LAST_OCTET}"
		TARGET_HOSTNAME="${KDEVOPSHOSTSPREFIX}-dev"
		add_host_entry $TARGET_HOSTNAME $SECOND_IP $TMP_INIT_NODE
		let CURRENT_IP="$CURRENT_IP+1"
	fi

	cat $TMP_INIT_NODE > $TMP_FINAL_NODE
	cat_template_nodes_sed $TMP_FINAL_NODE > $KDEVOPS_NODES

	rm -f $TMP_INIT_NODE $TMP_FINAL_NODE
}
