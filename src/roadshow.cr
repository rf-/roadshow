require "./roadshow/cli"

status = Roadshow::CLI.run(STDIN, STDOUT, ARGV)
exit status
