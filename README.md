# Punch

Punch simplifies bootstrapping, quering and controlling AWS EC2 instances. Punch is written in Bash.

Punch enables you to use scripts to bootstrap instances, rather than expressing your requirements in a DSL. This is well suited if you have an immutable server architecture—that is, you tend to create and destroy instances, rather than looking after them for a long time.

## Dependencies

Punch requires the [AWS CLI](https://aws.amazon.com/cli/), so you must install this before using punch.

## Configuration

Punch uses environment variables for its configuration, and can load environment variables from a shell script. For example:

```
PROFILE=my-profile punch instances
```

or

```
punch -f web-server-config.sh instances
```

## Running an instance

Here is an example configuration file `web-server-config.sh`. This contains all of the settings necessary to run an instance:
```
PROFILE=my-profile
REGION=us-west-1

AMI=ami-d8bdebb8
SECURITY_GROUP=sg-55512345
SUBNET=subnet-55512345
ASSOCIATE_PUBLIC_IP_ADDRESS=1
KEY_NAME=my-key-pair
INSTANCE_TYPE=t2.micro
#COUNT=1
```

All of this configuration is optional, depending upon your setup. `PROFILE` refers to a profile configured using `aws configure`.

Now we run punch to run three new instances:
```
punch -f web-server-config.sh run -c 3
```

### Bootstrapping an instance

Bootstrapping an instance involves running scripts on startup that setup the instance for use. Punch supports downloading bootstrap scripts from a Git repository.

We add the following to the example configuration file `web-server-config.sh` above:
```
BOOTSTRAP_PRIVATE_KEY_FILE=~/.ssh/id_automation
BOOTSTRAP_GIT_URL=git@github.com:karlvr/bootstrap-scripts.git
BOOTSTRAP_GIT_DIR=/opt/bootstrap
BOOTSTRAP_SCRIPT="
/opt/bootstrap/stage1.sh
/opt/bootstrap/stage2.sh
"
```

All of these configuration options are optional. A private key file is only required if you bootstrap scripts git repository required authentication. You can also use `https` git URLs.

**WARNING**: The private key will be visible to anyone with access to the instance, so it should not be considered secure. This could be improved in future. For now, use a private key that only has access to your bootstrap scripts.

Now we run punch again to run one new instance, this time running bootstrapping scripts: (Note that these bootstrapping scripts don’t currently exist so this isn’t a working demo!)
```
punch -f web-server-config.sh run
```

You can also replace the bootstrap template that punch uses by setting the `BOOTSTRAP_TEMPLATE` variable. See the default `bootstrap.sh` template for more information. Punch uses [mo](https://github.com/tests-always-included/mo) (a Moustache template engine written in Bash) to perform variable substitution in the bootstrap template.

### Setting tags on new instances

Punch can set tags on your new instances using a `TAGS` environment variable, or using one or more tags specified as a command-line argument.

To use the environment variable / configuration approach, add the following to the configuration file:
```
TAGS="name1=value1 name2=value2"
```

To use the command-line arguments approach:
```
punch -f web-server-config.sh run -t name1=value1 -t name2=value2
```

## Querying instances

For convenience, punch can query your instances with some common filtering options.

For a list of all of your instances (and their state) in the region:
```
punch -f web-server-config.sh instances
```

You can apply filters using the same syntax as [`aws ec2 describe-instances`](http://docs.aws.amazon.com/cli/latest/reference/ec2/describe-instances.html):
```
punch -f web-server-config.sh instances -f Name=instance-type,Values=t2.micro
```

Punch makes it easy to filter by security group id, tag, running state and instance id.
```
punch -f web-server-config.sh instances -g sg-55512345
punch -f web-server-config.sh instances -t MyTag=MyValue
punch -f web-server-config.sh instances -t MyTag
punch -f web-server-config.sh instances -t =MyValue
punch -f web-server-config.sh instances -r
punch -f web-server-config.sh instances -i i-5551234567890
```

You can combine these and repeat options to build up the required filter.

You can also get the public IP addresses of your instances:
```
punch -f web-server-config.sh ips
```

## Controlling instances

You can run commands or scripts on your instances using ssh:
```
punch -f web-server-config.sh ssh 'sudo apt-get update && sudo apt-get upgrade'
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
