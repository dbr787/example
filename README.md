# Go example project

[![Go Reference](https://pkg.go.dev/badge/golang.org/x/example.svg)](https://pkg.go.dev/golang.org/x/example)

This repository is a fork of the basic Golang example repo, trimmed down to contain a single example.

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

## Build using the golang docker container and execute the built app locally
```sh
name="John Doe"
sudo docker run --rm -v "$PWD":/usr/src/app -w /usr/src/app/hello golang:1.18 go build -v
sudo chmod +x hello/hello
./hello/hello $name
```

# Helpful Links

## Buildkite Tutorial: Containerized Builds with Docker
https://buildkite.com/docs/tutorials/docker-containerized-builds

## Docker Buildkite Plugin
https://github.com/buildkite-plugins/docker-buildkite-plugin
