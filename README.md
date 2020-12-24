# Sapristi

[![Maintainability](https://api.codeclimate.com/v1/badges/e168b7940a847148f617/maintainability)](https://codeclimate.com/github/sapristi-tool/sapristi/maintainability)
![Ruby](https://github.com/sapristi-tool/sapristi/workflows/Ruby/badge.svg)

An efficient tool to control your multi-monitor, multi-workspace enviroment. Just define your favorite working arragement in ~/sapristi.csv  and execute `sapristi` to load your applications and align them in your favorite fashion.

## Requirements

Linux

ruby-wmctrl gem:
  `libx11-dev libglib2.0-dev libxmu-dev`

Ruby/GTK gem


## Installation

    `$ gem install sapristi`

## Usage

`sapristi` loads your definitions.

`sapristi  -v | --verbose` verbose mode.

`sapristi --dry-run` dry mode, show your definitions but it doesn't execute them.

`sapristi -f FILE` load your definitions from another file.

`sapristi -g group` load definitions tagged with group.


### Configuration example: ~/.sapristi.csv

| Title | Command                                                                         | Monitor | X-position | Y-position | H-size | V-size | Workspace | Group    |
|-------|---------------------------------------------------------------------------------|---------|------------|------------|--------|--------|-----------|----------|
|       | subl ~/projects/ruby/sapristi                                                   |         | 0          | 0          | 60%    | 100%   | 0         | sapristi |
|       | terminator --working-directory=~/projects/ruby/sapristi                         |         | 60%        | 0          | 40%    | 50%    | 0         | sapristi |
|       | zeal                                                                            |         | 60%        | 50%        | 40%    | 50%    | 0         | sapristi |
|       | subl ~/projects/python/stuff                                                    |         | 0          | 0          | 60%    | 100%   | 1         | python   |
|       | terminator --working-directory=~/projects/python/stuff                          |         | 60%        | 0          | 40%    | 50%    | 1         | python   |
|       | firefox --new-window https://docs.python.org/3/index.html                       |         | 60%        | 50%        | 40%    | 50%    | 1         | python   |
|       | firefox --new-window https://www.gmail.com                                      |         | 0          | 0          | 50%    | 100%   | 2         | social   |
|       | firefox --new-window https://www.slack.com                                      |         | 50%        | 0          | 50%    | 50%    | 2         | social   |
|       | firefox --new-window https://www.twitter.com                                    |         | 50%        |            | 50%    | 50%    | 2         | social   |
|       | sol                                                                             | DP-2    | 0          | 0          | 100%   | 100%   | 3         | games    |

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sapristi-tool/sapristi.

## License

Please see [LICENSE](https://github.com/sapristi-tool/sapristi/blob/master/LICENSE.txt) for personal usage and [COMM-LICENSE](https://github.com/sapristi-tool/sapristi/blob/master/COMM-LICENSE.txt) for commercial usage.
