# RoboCup SPL TeamCommunicationMonitor

The TeamCommunicationMonitor (TCM) is a tool for visualizing the data
communicated between robots during SPL games.

It serves two main purposes:

1. offering diagnostic data such as which robots are communicating on which
   team ports and whether the data that is sent by these conforms to the
   SPLStandardMessage that is the standard communication protocol in the SPL
2. visualizing the data that was sent via SPLStandardMessages in both textual
   and graphical form.


## Usage

Building the TeamCommunicationMonitor is done together with the GameController
using Apache Ant.

The jar file may be executed by simply double-clicking it or calling:

`java -jar TeamCommunicationMonitor.jar`

It depends on the JOGAMP JOGL library (see http://jogamp.org/jogl/www/) for
drawing the 3D view of the field.
The JOGL jars reside in the deps directory and are automatically copied to the
build directory during the build process.

By passing the command line parameter `-s` or `--silent`, the TCM is started in
"silent" mode, in which it does not display anything but still stores all
received messages in log files.


## User Interface

The main window of the TCM consists of a 3D view in the middle and two grey
columns at the sides which each display the team logo and information about
currently sending robots of the team that plays on the corresponding side.

For each robot, its IP-address and player number as well as statistics about
the messages it sends are displayed. Double clicking one of these robot entries
opens a new window that displays more detailed information that was contained
in the most recently received SPLStandardMessage from the robot.
Values that do not conform to the definition of the SPLStandardMessage are
marked in red.

By default, the 3D view shows the field and visualizes some information about
the robots of the currently playing teams, i.e. is their position, their
penalized/fallen state, their player number, where they see the ball, and to
which positions they intend to walk (black cross) and shoot (red cross).
Each of these drawings may be toggled in the submenu `Drawings` that is located
in the `View` menu in the menu bar of the main window. Additionally, the
drawing `GameControllerInfo` that displays the current state of a running
GameController can be activated there.

The `View` menu also contains the `Mirror` option that allows to switch the
sides of the playing teams. This option may be useful if the user is watching
from the opposite side of the field.


## Logging

The TCM automatically writes all received network packets to a log file in
order to give users the possibility of reviewing network traffic again at a
later point in time.
Log files are stored in the directory `logs_teamcomm` and are named after the
time of their creation, the playing teams and the current half of the game.

In order to replay a log file, the `File` menu in the menu bar of the TCM's main
window has the option `Replay log file`. This option open an always-on-top
window containing controls to play, pause, fast forward or rewind the replaying
of the log. Replays can be speeded up to play back up to factor 128 times faster
than the original. However, please note that the messages per second counters in
the UI are based on real time, not the replay speed.


## Plugins

Teams may write plugins for the TCM that add:

* values to display in the detail windows of the robots of the team
* drawings that are drawn in the 3D view for each robot of the team
* drawings that are drawn in the 3D view when the team plays

A plugin consists of one or multiple jar files that lie somewhere in a folder
named `plugins/<team number>` relative to the TeamCommunicationMonitor.jar.
The TCM dynamically loads these jars when it notices the team's robots are
playing in the current game.

In order to use the classes of the TCM in plugins, which are needed in order to
extend the classes for messages and drawings, plugins must be compiled with the
TeamCommunicationMonitor.jar in their classpath.

### Message plugins
The first class found that extends `teamcomm.data.AdvancedMessage` is supposed
to be the message class of the team. Whenever the TCM receives a packet from a
robot of the team, it is first read as a SPLStandardMessage, then cast to the
message class of the team and its `init()` method is called.
This method may be used to parse the contents of the custom data array of the
SPLStandardMessage into separate fields so they are easily usable later on.

The `display()` method of the message class is supposed to return an array of
strings that should be displayed in the detail window of the robot that sent
the message. Each string is written in a separate line.

### Drawing Plugins
The TCM uses all classes in the plugin jars that extend
`teamcomm.gui.drawings.PerPlayer` as drawings that are drawn once for
each robot of the team per frame.

These classes override the methods `init()` (optional), `hasAlpha()`,
`getPriority()` and `draw()`. The TCM instantiates each class exactly once and
calls its methods as follows:

* `init()` is called once when the object is instantiated (i.e. when the plugin
  was just loaded).
    * This method may be used to load models or other resources needed for the
      drawing.
* `hasAlpha()` is supposed to return true iff the drawing contains transparency.
    * This information is needed so that the TCM can set up the rendering order
      to draw transparent objects after opaque objects.
* `getPriority()` is supposed to return a priority for the drawing if it
  contains transparency. This is needed in order to achieve the correct
  rendering order of objects containing transparency. The priority value should
  be higher the farther away the object is from the viewer.
    * Make sure to align your priorities to those of the default drawings:
      The field drawing has a priority of 1000, the ball drawing has 500, and
      the player number drawing has 10.
* `draw()` does the actual drawing. Its parameters are the OpenGL 2.0 context it
  should draw on, the current state of the robot for which the drawing is drawn,
  and a camera object.
    * When `draw()` is called, the OpenGL modelview matrix is initially set up
      so that the x axis points towards the opponent goal and (0,0,0) is the
      center of the field. When implementing your own drawings, make sure that
      you reset the modelview matrix to this (e.g. using `glPushMatrix()` /
      `glPopMatrix()`) when your `draw()` method returns.

Apart from per player drawings, teams may also write static drawings that are
drawn only once per frame like the field drawing. For this, the drawings extend
`teamcomm.gui.drawings.Static` instead of PerPlayer.
For static drawings, the x axis initially always points towards the goal of the
right team.

The camera object that the `draw()` method of drawings receives is useful only
because of its method `turnTowardsCamera()` that rotates the modelview matrix
so that the x axis points to the right and the y axis to the top of the screen
of the viewer. This is useful for displaying text or images.

The package `teamcomm.gui.drawings` also contains some utility classes that can
be used by drawings:
* `TextureLoader` manages the loading of textures from image files
* `Text` allows to draw ASCII text
* `Image` allows to draw a textured 2D surface with the correct aspect ratio of
  the given texture
* `RoSi2Loader` manages the loading of models from ros2 files as used by
  B-Human's simulator SimRobot

Refer to the common drawings in `teamcomm.gui.drawings.common` for example
implementations of drawings. By the way, these are not compiled into the
TeamCommunicationMonitor.jar, but to the special plugin jar file
`plugins/common.jar` and dynamically loaded by the TCM as well.

### Example plugin
Team B-Human provides the source code for a sample plugin that visualizes data
sent by their robots in the directory `resources/plugins/05` of the
GameController repository.
This plugin may be used as a reference when developing plugins for other teams.
