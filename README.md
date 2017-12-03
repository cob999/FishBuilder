# Introduction

FishBuilder is a light hearted and marine-themed PowerShell script to give a basic interface for running MSBuild commands and other random commands of use to a .Net developer. It is inspired by old-school console applications and was a learning tool for implementing such an interface using PowerShell.

The most common use case is for when a Visual Studio solution contains a huge number of projects resulting in a long compile time. To reduce the compile time it is possible to build individual projects with msbuild commands that you prepare in advance. In a similar way you may want to run specific test suites easily without having to run all unit tests.

But remembering these commands and executing them is awkward so why not create a basic text based UI using PowerShell and execute commands with a UI that also includes ascii pictures of marine life!

The script codifies a lot of the details about how to call msbuild (and other) commands from a PowerShell script, passing parameters to them etc. Also useful nuggets like reading envrionment variables, checking for admin priviliges etc. A simple Visual Studio solution containing two console applictions is included to demonstrate the script in action. In reality it would only be useful in a much more complex Visual Studio solution that contained multiple projects, project types, tests etc.

I developed this script for a development environment that ran an instance of Solr within Vagrant. This was quite unreliable so commands to restart Vagrant are included.

## Screenshots

Main Menu

![Main Menu](/mainmenu.png)

Testing Sub-menu

![Testing Menu](/submenu.png)

## Usage

Make sure to set an environment variable FISHBUILDER_ROOT to the root of your msbuild solution or project. Then just execute .\FishBuilder.ps1 using PowerShell

Set the environment variable with PowerShell like the following
    [Environment]::SetEnvironmentVariable("FISHBUILDER_ROOT", "c:\path", "User")


 
## Some of the useful features

1. Makes sure the you have Administrator priviliges at startup
1. Tells you what branch was built
1. Tells you what time you started the build and how long it took to complete
1. Creates a summary of info like whether errors were reported and what actions were done
1. iisresets, vagrant restarts and database commands are also common actions to perform so there are utilities for doing these individually
1. a submenu for for running various suites of tests
1. Uses two processors to keep the build fast but your system responsive, this could be made configurable see note below
1. Run SQL commands including an example to drop databases

## Known issues

1. The display of whether an action completed successfully or not is not 100% reliable, it is supposed to show an error message and show the summary on a red background. But some of the steps in particular failed tests, do not exit with an error code but continue. Will need to come up with a better way of capturing errors especially for failing tests.

2. Discussion on /m parameter and using multiple processors, need to experiment with the ideal value for quick build versus keep a repsonsive system here on my desktop

see http://www.hanselman.com/blog/FasterBuildsWithMSBuildUsingParallelBuildsAndMulticoreCPUs.aspx

## TODO/Future ideas

* I have a version of this script that allow the excuting of NUnit tests based on category, project etc. In a large code base this was the most useful feature of this tool, I plan to add this back in at some point, the sub menu for testing is in place, if you want this feature ASAP open an Issue in github
