# Roadshow

[![](https://secure.travis-ci.org/rf-/roadshow.svg?branch=master)](http://travis-ci.org/rf-/roadshow)

## Summary

Roadshow is a tool that uses [Docker] and [Docker Compose] to make it easy to
test your library or application against different sets of dependencies without
relying on an external CI service.

## Setup

(Note: you have to have working `docker` and `docker-compose` executables on
your `PATH` to use Roadshow. On a Mac, you can install them using
[Homebrew-Cask].)

Roadshow's configuration is specified in a YAML file which lives at the top
level of your project and is named `scenarios.yml`.

To generate a skeleton for this file, use the `init` command:

    roadshow init

Here's an example of a basic `scenarios.yml` file:

    # Based on the name of your working directory by default. This will be
    # prepended to the generated Docker image names created by Docker Compose.
    project: someprojectname

    # This configuration is shared by all of your scenarios, except where they
    # override it. The format is identical to an individual scenario.
    #
    # Anywhere in this block, you can use the placeholder "{{scenario_name}}"
    # to stand in for the name of each individual scenario.
    shared:
      # Specify the value to pass into FROM in the Dockerfile (i.e.,
      # what image to use as a starting point for this scenario).
      from: bash

      # Specify the value to pass into CMD in the Dockerfile.
      cmd: "echo 'default command' && echo $ENV_VAR"

    # The individual scenarios.
    scenarios:
      one:
        # Configuration for the main service in Docker Compose. Extra services
        # aren't supported yet.
        service:
          environment:
            ENV_VAR: scenario one
      two:
        from: bash
        cmd: "echo 'overridden command' && echo $ENV_VAR"
        service:
          environment:
            ENV_VAR: scenario two

## Usage

Once you've set up your `scenarios.yml` file, you can generate Dockerfiles and
Docker Compose files into a subdirectory called `scenarios`:

    roadshow generate

Once you've done that, you can easily run all of the scenarios' default
commands at once:

    roadshow run

To run an individual scenario's default command, use the `-s` or `--scenario`
option:

    roadshow run -s rails32

To run a non-default command across all scenarios or an individual scenario,
pass extra arguments, optionally preceded by `--` to avoid any ambiguity:

    roadshow run rails console
    roadshow run -s rails32 -- rails console

In all of these cases, if any of the individual commands exit with a non-zero
status then Roadshow will too.

If you want to clean up after yourself, you can remove all containers, images,
and volumes created by Roadshow for the current project:

    roadshow cleanup

## Example: Testing a Ruby library

If you have a Ruby library that integrates with other gems, it can be hard to
test it across various versions of Ruby and your dependencies. A
`scenarios.yml` file for this situation might look like this:

    project: my_cool_gem

    shared:
      from: ruby:2.4
      cmd: "bundle install && bundle exec rake"
      service:
        volumes:
          - bundle:/usr/local/bundle
        environment:
          BUNDLE_GEMFILE: scenarios/{{scenario_name}}.gemfile
      volumes:
        bundle:

    scenarios:
      rails32:
        from: ruby:2.2
      rails51:

The `bundle` volume will hold the installed dependencies for each scenario, so
that you don't have to reinstall them from scratch every time you run anything.

Once you run `roadshow generate` to create the `scenarios` directory, you can
add files called `scenarios/rails32.gemfile` and `scenarios/rails51.gemfile`
containing the gem dependencies for each scenario. For example,
`scenarios/rails51.gemfile` could look like this:

    source "http://rubygems.org"

    gem "rails", "5.1.0"
    gem "sqlite3"

    gemspec :path => "../"

Now you can just use `roadshow run` to run your tests across both versions.

## License and Acknowledgements

Roadshow is available under the terms of the MIT license (see the LICENSE file
for details). It was inspired by [thoughtbot]'s excellent [Appraisal] tool for
Ruby.

[Appraisal]: https://github.com/thoughtbot/appraisal
[Docker Compose]: https://docs.docker.com/compose/
[Docker]: https://docker.com
[Homebrew-Cask]: https://github.com/caskroom/homebrew-cask
[thoughtbot]: https://github.com/thoughtbot
