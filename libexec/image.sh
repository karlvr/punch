find_image() {
	local owner=
	local architecture=x86_64
	local root_device_type=ebs
	local image_type=machine
	local hypervisor=xen
	local virtualization_type=hvm
	local volume_type=
	local release=

	local option
	for option in $* ; do
		local option_key
		local option_value
		option_key=$(echo "$option" | cut -d= -f1)
		option_value=$(echo "$option" | cut -d= -f2)

		if [ "$option_key" == "owner" ]; then
			owner="$option_value"
		elif [ "$option_key" == "architecture" ]; then
			architecture="$option_value"
		elif [ "$option_key" == "root_device_type" ]; then
			root_device_type="$option_value"
		elif [ "$option_key" == "image_type" ]; then
			image_type="$option_value"
		elif [ "$option_key" == "hypervisor" ]; then
			hypervisor="$option_value"
		elif [ "$option_key" == "virtualization_type" ]; then
			virtualization_type="$option_value"
		elif [ "$option_key" == "volume_type" ]; then
			volume_type="$option_value"
		elif [ "$option_key" == "release" ]; then
			release="$option_value"
		else
			echo "Unsupported image filter option: $option" >&2
			return 0
		fi
	done

	local filters=

	if [ ! -z "$architecture" ]; then
		filters="$filters Name=architecture,Values=$architecture"
	fi
	if [ ! -z "$root_device_type" ]; then
		filters="$filters Name=root-device-type,Values=$root_device_type"
	fi
	if [ ! -z "$image_type" ]; then
		filters="$filters Name=image-type,Values=$image_type"
	fi
	if [ ! -z "$hypervisor" ]; then
		filters="$filters Name=hypervisor,Values=$hypervisor"
	fi
	if [ ! -z "$virtualization_type" ]; then
		filters="$filters Name=virtualization-type,Values=$virtualization_type"
	fi
	if [ ! -z "$volume_type" ]; then
		filters="$filters Name=block-device-mapping.volume-type,Values=$volume_type"
	fi
	if [ ! -z "$release" ]; then
		filters="$filters Name=name,Values=ubuntu/images/*$release*"
	fi

	# Find AMI
	aws ec2 describe-images $global_aws_options \
		--filters $filters \
		--owners "$owner" \
		--output text --query 'Images[].[ImageId,CreationDate,Name,Description]' \
		| sort -k2 -r | head -n 1 | cut -f 1
}

find_image_with_distro() {
	local distro="$1"
	shift

	if [ "$distro" == "ubuntu" ]; then
		# Use official Canonical owner id
		find_image owner=099720109477 $*
	else
		echo "Unsupported distro: $distro" >&2
		exit 1
	fi
}
