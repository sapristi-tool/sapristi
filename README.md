# Sapristi

[![Maintainability](https://api.codeclimate.com/v1/badges/e168b7940a847148f617/maintainability)](https://codeclimate.com/github/sapristi-tool/sapristi/maintainability)
![Ruby](https://github.com/sapristi-tool/sapristi/workflows/Ruby/badge.svg)

![Sapristi image](/assets/images/sapristi.png)

An efficient tool to control your multi-monitor, multi-workspace enviroment. Just define your favorite working arragement in ~/sapristi.csv  and execute `sapristi` to load your applications and align them in your favorite fashion.

## Requirements

Linux

See ruby-wmctrl (`libx11-dev libglib2.0-dev libxmu-dev`) and Ruby/GTK gem requirements.


## Installation

    `$ gem install sapristi`

## Usage

`sapristi` load definitions from default configuration file (~/.sapristi.csv)

`sapristi -f FILE` load your definitions from another file, ie: sapristi -f ~/machine_learning_definitions.csv

`sapristi  -v | --verbose` verbose mode.

`sapristi --dry-run` dry mode, show your definitions but it doesn't execute them.

`sapristi -g group` load definitions tagged with group, ie: sapristi -g social


### Configuration example: ~/.sapristi.csv

| __Title__ | __Command__                                                                         | __Monitor__ | __X__          | __Y__          | __Width__  | __Height__ | __Workspace__ | __Group__    |
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

Fields:

__Title__: (Optional, regex). If defined, sapristi will try to find a window with a title that matches the provided regular expression.

__Command__: (Optional, a command) If __Title__ is non provided or there isn't a window that matches __Title__, sapristi will execute __Command__.
Every line has to define a __Title__, a __Command__ or both

__Monitor__ (Optional, monitor name):
  - Use monitor when specified.
  - Use main monitor if monitor name is not found.
  - Use main monitor if __Monitor__ is not provided.
  
__X__: (Mandatory, absolute or relative) X position to position the window, it can be absolute (200) or relative (20%) Monitor work area, not monitor resolution.

__Y__: (Mandatory, absolute or relative) Y position to position the window, it can be absolute (300) or relative (30%) Monitor work area, not monitor resolution.

__Width__: (Mandatory, absolute or relative) Window width, it can be absolute (400) or relative (40%) Monitor work area, not monitor resolution.

__Height__: (Mandatory, absolute or relative) Window height, it can be absolute (400) or relative (40%) Monitor work area, not monitor resolution.

__Workspace__: (Optional, workspace number: 0, n - 1) Move window to __Workspace__ if defined, otherwise leave it in current workspace.


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sapristi-tool/sapristi.

## License

Please see [LICENSE](https://github.com/sapristi-tool/sapristi/blob/master/LICENSE.txt) for personal usage and [COMM-LICENSE](https://github.com/sapristi-tool/sapristi/blob/master/COMM-LICENSE.txt) for commercial usage.

## Credits
<span>Photo by <a href="https://unsplash.com/@danfreemanphoto?utm_source=unsplash&amp;utm_medium=referral&amp;utm_content=creditCopyText">Dan Freeman</a> on <a href="https://unsplash.com/?utm_source=unsplash&amp;utm_medium=referral&amp;utm_content=creditCopyText">Unsplash</a></span>
