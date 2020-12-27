# Sapristi

[![Maintainability](https://api.codeclimate.com/v1/badges/e168b7940a847148f617/maintainability)](https://codeclimate.com/github/sapristi-tool/sapristi/maintainability) ![Gem](https://img.shields.io/gem/v/sapristi?style=plastic)

![Sapristi image](/assets/images/sapristi.jpg)

An efficient tool to control your multi-monitor, multi-workspace enviroment. Just define your favorite working arragement in ~/sapristi.csv  and execute `sapristi` to load your applications and align them in your favorite fashion.

## Installation

Install build dependencies

    `$ sudo apt install build-essential ruby-dev libx11-dev libglib2.0-dev libxmu-dev libgtk-3-dev`

Install gem

    `$ gem install sapristi`

## Usage

`sapristi` load definitions from default configuration file (~/.sapristi.csv) If default configuration file is not found, it will create an empty one.

  > `-f FILE` load your definitions from another file, ie: sapristi -f ~/machine_learning_definitions.csv

  > `-v | --verbose` verbose mode

  > `--dry-run` dry mode, show your definitions but it doesn't execute them

  > `-g|--group name` load definitions tagged with group, ie: sapristi -g social
  
  > `-h|--help` show help
  
  > `-m|--monitors` show available monitors info (including work area size) and exits


### Configuration example: ~/.sapristi.csv

| __Title__ | __Command__                                                                         | __Monitor__ | __X__          | __Y__          | __Width__  | __Height__ | __Workspace__ | __Group__    |
|-------|---------------------------------------------------------------------------------|---------|------------|------------|--------|--------|-----------|----------|
|       | subl ~/projects/ruby/sapristi                                                   |         | 0%         | 0%         | 60%    | 100%   | 0         | sapristi |
|       | terminator --working-directory=~/projects/ruby/sapristi                         |         | 60%        | 0%         | 40%    | 50%    | 0         | sapristi |
|       | zeal                                                                            |         | 60%        | 50%        | 40%    | 50%    | 0         | sapristi |
|       | subl ~/projects/python/stuff                                                    |         | 0%         | 0%         | 60%    | 100%   | 1         | python   |
|       | terminator --working-directory=~/projects/python/stuff                          |         | 60%        | 0%         | 40%    | 50%    | 1         | python   |
|       | firefox --new-window https://docs.python.org/3/index.html                       |         | 60%        | 50%        | 40%    | 50%    | 1         | python   |
|       | firefox --new-window https://www.gmail.com                                      |         | 0%         | 0%         | 50%    | 100%   | 2         | social   |
|       | firefox --new-window https://www.slack.com                                      |         | 50%        | 0%         | 50%    | 50%    | 2         | social   |
|       | firefox --new-window https://www.twitter.com                                    |         | 50%        | 0%         | 50%    | 50%    | 2         | social   |
|       | sol                                                                             | DP-2    | 0%         | 0%         | 100%   | 100%   | 3         | games    |

The configuration file is a CSV file (comma delimited, no separator). First line is the header line, next lines are definitions. Each definition prescribes:
 - How choose a window from the current ones, or how to launch a program to produce the window: __Title__, __Command__
 - Which monitor to place it: __Monitor__
 - Which workspace: __Workspace__
 - Desired window geometry: __X__, __Y__, __Width__, __Height__

The table above represents a CSV file like the one below:
```
Title,Command,Monitor,X,Y,Width,Height,Workspace,Group
,subl ~/projects/ruby/sapristi,,0%,0%,60%,100%,0,sapristi
,terminator --working-directory=~/projects/ruby/sapristi,,60%,0%,40%,50%,0,sapristi
,zeal,,60%,50%,40%,50%,0,sapristi
,subl ~/projects/python/stuff,,0%,0%,60%,100%,1,python
,terminator --working-directory=~/projects/python/stuff,,60%,0%,40%,50%,1,python
,firefox --new-window https://docs.python.org/3/index.html,,60%,50%,40%,50%,1,python
,firefox --new-window https://www.gmail.com,,0%,0%,50%,100%,2,social
,firefox --new-window https://www.slack.com,,50%,0%,50%,50%,2,social
,firefox --new-window https://www.twitter.com,,50%,50%,50%,50%,2,social
,sol,DP-2,0%,0%,100%,100%,3,games
```


#### Fields:

- __Title__(optional): Regex If defined, sapristi will try to find a window whose title matches the regular expression. Examples:
  - \(sapristi\) - Sublime
  - Twitter.+Firefox
  - System Monitor

- __Command__(optional): A command. If __Title__ is not provided or there isn't a window that matches it, sapristi will execute __Command__. Examples:
  - firefox --new-window https://www.twitter.com
  - terminator --working-directory=~/projects/python/stuff
  
  (Every line has to define a __Title__, **OR** a __Command__ or both)
  
- __Monitor__(optional): Monitor name (check your monitor names with xrandr) If a definition specifies a monitor not present or if is empty, window will be placed in the main monitor of the actual environment.
  - Use monitor when specified.
  - Use main monitor if monitor name is not found.
  - Use main monitor if __Monitor__ is not provided.
  
- __X__(mandatory): Absolute or relative. Horizontal top left coordinate to place the window:
  - Absolute (monitor width): ie 100, 200, 250.
  - Relative (monitor workarea): 10%, 20%, 50%. Percentage has to be an integer between 0 and 100. 

- __Y__(mandatory): Absolute or relative. Vertical top left coordinate to place the window:
  - Absolute (monitor monitor height): ie 100, 200, 250.
  - Relative (monitor workarea): 10%, 20%, 50%. Percentage has to be an integer between 0 and 100. 
  
  The work area should be considered when positioning menus and similar popups, to avoid placing them below panels, docks or other desktop components.
  ![workarea image](/assets/images/workarea.jpg)

- __Width__(mandatory): Absolute (pixels) or relative (workarea) Window width. Examples: 100, 50%. 

- __Height__(mandatory): Absolute (pixels) or relative (workarea) Window height. Examples: 100, 50%. 

- __Workspace__(optional): Workspace/desktop to place the window, current workspace if it is not defined. Examples: 0, 1, 5.

## Requirements

Linux

See ruby-wmctrl (`libx11-dev libglib2.0-dev libxmu-dev`) and Ruby/GTK (`libgtk-3-dev`) gem requirements.

## Caveats

Some programs use a main/server process to optimize their use of system resources. When you launch them, it is not possible to correlate the pid of the seed process with the pid of the window, Sapristi uses an heuristic approach to detect window instantiated under this type of strategy.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sapristi-tool/sapristi.

## License

Please see [LICENSE](https://github.com/sapristi-tool/sapristi/blob/master/LICENSE.txt) for personal usage and [COMM-LICENSE](https://github.com/sapristi-tool/sapristi/blob/master/COMM-LICENSE.txt) for commercial usage.

## Credits
<span>Photo by <a href="https://unsplash.com/@danfreemanphoto?utm_source=unsplash&amp;utm_medium=referral&amp;utm_content=creditCopyText">Dan Freeman</a> on <a href="https://unsplash.com/?utm_source=unsplash&amp;utm_medium=referral&amp;utm_content=creditCopyText">Unsplash</a></span>
