# Punch

Punch simplifies bootstrapping, quering and controlling AWS EC2 instances. Punch is written in Bash.

Punch enables you to use scripts to bootstrap instances, rather than expressing your requirements in a DSL. This is well suited if you have an immutable server architecture—that is, you tend to create and destroy instances, rather than looking after them for a long time.

## Dependencies

Punch requires the [AWS CLI](https://aws.amazon.com/cli/), so you must install this before using punch.

## Configuration

Punch uses environment variables for its configuration, and can load environment variables from a shell script. For example:

```
PUNCH_PROFILE=my-profile punch instances
```

or

```
punch -f web-server-config.sh instances
```

### Automatic configuration

Punch looks for a file named `.punch.cfg` starting in the current working directory and continuing 
up through parent directories.

## Running an instance

Here is an example configuration file `web-server-config.sh`. This contains all of the settings necessary to run an instance:
```
PUNCH_PROFILE=my-profile
PUNCH_REGION=us-west-1

PUNCH_AMI=ami-d8bdebb8
# or
PUNCH_IMAGE="ubuntu release=focal"

PUNCH_SECURITY_GROUP=sg-55512345
PUNCH_SUBNET=subnet-55512345
PUNCH_ASSOCIATE_PUBLIC_IP_ADDRESS=1
PUNCH_KEY_NAME=my-key-pair
PUNCH_INSTANCE_TYPE=t2.micro
#PUNCH_COUNT=1
```

All of this configuration is optional, depending upon your setup. `PUNCH_PROFILE` refers to a profile configured using `aws configure`.

Now we run punch to run three new instances:
```
punch -f web-server-config.sh run -c 3
```

### Bootstrapping an instance

Bootstrapping an instance involves running scripts on startup that setup the instance for use. Punch supports downloading bootstrap scripts from a Git repository.

We add the following to the example configuration file `web-server-config.sh` above:
```
PUNCH_BOOTSTRAP_PRIVATE_KEY_FILE=~/.ssh/id_automation
PUNCH_BOOTSTRAP_GIT_URL=git@github.com:karlvr/bootstrap-scripts.git
PUNCH_BOOTSTRAP_GIT_DIR=/opt/bootstrap
PUNCH_BOOTSTRAP_SCRIPT='
/opt/bootstrap/stage1.sh
/opt/bootstrap/stage2.sh
'
```

All of these configuration options are optional. A private key file is only required if you bootstrap scripts git repository required authentication. You can also use `https` git URLs.

**WARNING**: The private key will be visible to anyone with access to the instance, so it should not be considered secure. This could be improved in future. For now, use a private key that only has access to your bootstrap scripts.

Now we run punch again to run one new instance, this time running bootstrapping scripts: (Note that these bootstrapping scripts don’t currently exist so this isn’t a working demo!)
```
punch -f web-server-config.sh run
```

You can also replace the bootstrap template that punch uses by setting the `PUNCH_BOOTSTRAP_TEMPLATE` variable. See the default `bootstrap.sh` template for more information. Punch uses [mo](https://github.com/tests-always-included/mo) (a Moustache template engine written in Bash) to perform variable substitution in the bootstrap template.

### Setting tags on new instances

Punch can set tags on your new instances using a `PUNCH_TAGS` environment variable, or using one or more tags specified as a command-line argument.

To use the environment variable / configuration approach, add the following to the configuration file:
```
PUNCH_TAGS="name1=value1 name2=value2"
```

To use the command-line arguments approach:
```
punch -f web-server-config.sh run -t name1=value1 -t name2=value2
```

### Client tokens

Use [client tokens](http://docs.aws.amazon.com/AWSEC2/latest/APIReference/Run_Instance_Idempotency.html#client-tokens) to ensure idempotency of your requests. Pass a client token as a command-line argument:

```
punch -f web-server-config.sh run -o MyIdempotencyToken
```

## Querying instances

For convenience, punch can query your instances with some common filtering options.

For a list of all of your instances (and their state) in the region:
```
PUNCH_PROFILE=my-profile PUNCH_REGION=us-west-1 punch instances
```

Punch uses environment variables, and configuration, to automatically build filters so it only queries (or controls) instances that match the configuration. Punch will filter match on the AMI image-id, the security group id, the subnet, the key-pair name, the instance type and any tags in the configuration. This helps to ensure that when you use a configuration file, you are only talking to the instances represented by it (as long as your configuration file options are unique; for that purpose use unique tagging).

For a list of all of your instances matching a configuration file:
```
punch -f web-server-config.sh instances
```

You can also apply filters using the same syntax as [`aws ec2 describe-instances`](http://docs.aws.amazon.com/cli/latest/reference/ec2/describe-instances.html):
```
punch instances -f Name=instance-type,Values=t2.micro
```

Punch makes it easy to filter by security group id, tag, running state, client token and instance id.
```
punch instances -g sg-55512345
punch instances -t MyTag=MyValue
punch instances -t MyTag
punch instances -t =MyValue
punch instances -r
punch instances -o MyIdempotencyToken
punch instances -i i-5551234567890
```

You can combine these and repeat options to build up the required filter.

You can also get the public IP addresses of your instances:
```
punch ips
```

## Controlling instances

You can run commands or scripts on your instances using ssh:
```
punch -f web-server-config.sh ssh -c 'sudo apt-get update && sudo apt-get upgrade'
```

You can also just interactively connect to your instances using ssh, one at a time:
```
punch -f web-server-config.sh ssh
```

Or, if you have [csshX](https://github.com/brockgr/csshx) installed, all at once:
```
punch -f web-server-config.sh csshX
```

**WARNING**: Punch disables host key checking and remembering for its ssh connections, as each instance is likely to have a new key that you haven’t seen before.

### Starting, stopping, terminating

You can start, stop and terminate EC2 instances using punch. These commands support the same filtering options as the querying commands.

```
punch -f web-server-config.sh start -t Role=Webserver
punch -f web-server-config.sh stop -t Role=Webserver
punch -f web-server-config.sh terminate -t Role=Webserver
```

## Finally

The `punch` script contains more detailed usage information.
