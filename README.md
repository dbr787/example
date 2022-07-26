# Go example project

[![Go Reference](https://pkg.go.dev/badge/golang.org/x/example.svg)](https://pkg.go.dev/golang.org/x/example)

This repository is a fork of the basic Golang example repo, trimmed down to contain a single example.

## My Notes/Comments
I was able to complete the task relatively easily, I did run into a common issue which was the docker permissions.  
Running the `sudo usermod -aG docker buildkite-agent` command still required a reboot in order to add permissions, so I ended up using `sudo setfacl --modify user:buildkite-agent:rw /var/run/docker.sock` in the bootstrap script to avoid an unecessary reboot of the agent servers after being provisioned.  
I chose to include commands within the `commands` step, inline in the [pipeline.yml](./buildkite/pipeline.yml) script rather than execute a separate script stored in the repository, while acknowledging both options are possible.  
Rather than deploying Buildkite agent servers manually, I chose to include terraform modules in the repository to assist with deploying and registering agents so I wouldn't have to manually create and destroy servers, or ssh to them in order to run installation\registration\docker commands.  
These terraform modules can be much improved, but serve as a good starting point allowing Linux servers of different sizes and types to be provisioned and registered as agents automatically.

## Build the project locally

```sh
$ cd hello
$ go build
```

A simple application that takes a command line argument, and then returns it to you in a string:

```sh
$ chmod +x hello/hello
$ ./hello/hello John Doe
```

The above will return 'Hello, John Doe!'

## Build the project locally using the golang docker container
```sh
sudo docker run --rm -v "$PWD":/usr/src/app -w /usr/src/app/hello golang:1.18 go build -v
sudo chmod +x hello/hello
./hello/hello John Doe
```

## Deploy and register Buildkite agents with terraform

***Ensure that both the AWS CLI and Terraform are installed and configured.***

- Update [terraform.tfvars.template](terraform/terraform.tfvars.template) with the details specific to your environment/deployment
- Retrieve the Buildkite agent token from the GUI
- Update the `buildkite_agent_token` in [secret.auto.tfvars.template](terraform/secret.auto.tfvars.template)
- Rename [terraform.tfvars.template](terraform/terraform.tfvars.template) to `terraform.tfvars`
- Rename [secret.auto.tfvars.template](terraform/secret.auto.tfvars.template) to `secret.auto.tfvars`
- Run the following commands to deploy the environment and agents...
  ```sh
  terraform -chdir="./terraform" init
  terraform -chdir="./terraform" plan
  terraform -chdir="./terraform" apply
  ```
  Or use the provided [deploy_agents.sh](deploy_agents.sh) script...
  ```sh
  chmod +x ./deploy_agents.sh
  ./deploy_agents.sh
  ```
- Run the following commands to ***destroy*** the environment and agents...
  ```sh
  terraform -chdir="./terraform" destroy
  ```
  Or use the provided [deploy_agents.sh](deploy_agents.sh) script...
  ```sh
  chmod +x ./deploy_agents.sh
  ./deploy_agents.sh --destroy
  ```

## Backlog (TODO)
- Allow user to set `queue` for each agent deployed
- Update code to allow `windows` platorm agents to be deployed with different bootstrap script
- Update code to allow other linux operating systems to be selected with different bootstrap scripts
- Include deregistration of agents in a destroy provisioner

## Helpful Links

### Buildkite Tutorial: Containerized Builds with Docker
https://buildkite.com/docs/tutorials/docker-containerized-builds

### Docker Buildkite Plugin
https://github.com/buildkite-plugins/docker-buildkite-plugin

### Buildkite Example Pipelines
https://buildkite.com/docs/pipelines/example-pipelines
