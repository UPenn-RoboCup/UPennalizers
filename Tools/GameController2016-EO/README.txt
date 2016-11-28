# RoboCup SPL and Humanoid League GameController

This is the GameController developed by team B-Human for the RoboCup SPL and Humanoid League.

If there are any questions, please contact fthielke@informatik.uni-bremen.de .

Follow @BHumanOpenSrc on Twitter to get notifications about recent activity.

The sources mentioned in some sections of this document are available at
https://github.com/bhuman/GameController .


### Acknowledgement

The development was partially supported by the RoboCup Federation within the calls for
Support for Projects for League Developments for 2013 and 2015.


## 1. Building from Source

To build it from the source code you may use Apache Ant.
Just call "ant" in the main directory.

Building the source code requires the JDK 1.7 or newer.


## 2. GameController

### Executing the Jar

Double-click GameController.jar or run 

Usage: `java -jar GameController.jar {options}`

    (-h | --help)                   display help
    (-i | --interface) <interface>  set network interface (default is a connected IPv4 interface)
    (-l | --league) (spl | spl_dropin | hl_kid | hl_teen | hl_adult)
                                    select league (default is spl)
    (-w | --window)                 select window mode (default is fullscreen)


### Start Dialog

Select your league. The default can be specified as a command line parameter (see above).

Pick the two teams that are playing. They have to be different teams. If you are 
practicing alone, use the "Invisibles" as second team.

SPL: The GameController automatically selects the jersey colors: If only one team has 
custom jerseys (defined in the file "teams.cfg"), its jersey color is picked first,
otherwise the jersey color of the left is picked first. For both teams, the first jersey
color that they have and, if picking second, that does not conflict with the jersey color
of the opponent is selected in the following sequence:

* Left team: custom 1, custom 2, blue, red
* Right team: custom 1, custom 2, red, blue

You also have to select whether you play a game in the preliminaries or a 
play-off game. In the preliminaries the clock will continue to run during game stoppages
and there will be no penalty shootout in case of a draw. In play-off games, the clock
will be stopped and there may be penalty shootout.

HL: You also have to select whether you play a normal game or a knock-out game. A
knock-out game will continue after a draw with two halves of extra time (if goals were
scored before) and then a penalty shoot-out if necessary. You can also select whether
teams exchange their colors in the halftime.

You can select whether the GameController should run in fullscreen mode or in windowed
mode. Note that the fullscreen mode does not work correctly on some Linux desktops,
because although they report to Java that they would support this feature, they do not.


### Main Screen

The use of the main screen should be rather obvious in most cases. Therefore, we only
focus on the specialties.

When ever you made a mistake, use the undo history at the bottom of the screen to correct
it. You cannot correct individual decisions (except for the last one). Instead, you can
only roll back to a certain state of the game. Click the oldest decision in the history
you want to undo. After that all decisions that would be undone will be marked. Click the
decision again to actually undo it together with all decisions that followed.

To penalize a robot, first press the penalty button, then the robot button. The only 
exception is the state "Set" in playoff games, in which the "Motion in Set" penalty is
preselected and robots can be penalized by simply clicking on them (selecting other 
penalties is still possible). For unpenalizing a robot, just press the robot button.
A robot can only be unpenalized, when its penalty time is over or when the game state
changes (SPL only). Ten seconds before the penalty time is over, the robot's button
starts flashing yellow. For regular penalties, it continues to flash until the button is
pressed. Only buttons of robots that were requested for pickup stop flashing after ten
seconds and simply stay yellow until they are pressed, as a reminder that the robot can
return as soon as it is ready. Robots with a "Motion in Set" penalty stay on the field
and will be automatically unpenalized 15 seconds after pressing the button "Play". 

Before unpenalizing a robot that was taken off the field, please make sure that it was
put back on the field by the assistant referees. For that reason, robots are never
unpenalized automatically.

To substitute a robot, press "Substitute" and then the robot that should leave the field.
Afterwards, any of the substitutes can be activated. If the robot that is replaced is
already penalized, its substitute inherits the penalty. If it is not, the substitute can
immediately enter the field in the HL, but gets a "request for pickup" penalty before it
can enter the field in the SPL.

When pressing the big "+" (goal), "Timeout", or "Global Game Stuck", the
other team gets the next kick-off.

SPL: When the referee decides that too much game time has been lost, use the thin "+" next
to the clock to increase the game time in one-minute steps. This is only available during
stoppages of play.


### Penalty Shootout

In the penalty shootout, press "Set" and place the robots in their correct locations. Press
"Play" to start a single shot. The penalty shot is ended by either pressing "+" for the 
penalty taker or by pressing "Finish" if the shot failed. In both cases, a penalty shot ends
in the state "Finished". Press "Set" again to start the next shot.


### Shortcuts

While the GameController is running, you may use the following keys on the keyboard instead
of pushing buttons:

    Esc       - press it twice to close the GameController
    Delete    - toggle test-mode (everything is legal, every button is visible and enabled)
    Backspace - undo last action

only SPL

    B    - out by blue
    R    - out by red
    Y    - out by yellow
    K    - out by black

    P    - pushing
    L    - leaving the field
    I    - fallen / inactive / local game stuck
    D    - illegal defender
    G    - kickoff goal 
    O    - illegal ball contact
    U    - request for pickup
    C    - coach motion
    T    - teammate pushing
    S    - substitute

only Humanoid-League

    B    - out by blue
    R    - out by red

    M    - ball manipulation
    P    - physical contact
    A    - illegal attack
    D    - illegal defense
    I    - service / incapable
    S    - substitute


## 3. GameStateVisualizer

### Executing the Jar

Double-click GameStateVisualizer.jar or run 

Usage: `java -jar GameStateVisualizer.jar {options}`

    (-h | --help)                   display help
    (-l | --league) (spl | spl_dropin | hl_kid | hl_teen | hl_adult)
                                    select league (default is spl)

### Shortcuts

In addition to the usual keyboard combinations to terminate the application
(Alt+F4 / Cmd+Q), pressing F11 toggles between the normal mode and the test
mode. In the latter, the messages sent by the GameController are dumped on
the screen.


## 4. TeamCommunicationMonitor

The TeamCommunicationMonitor (TCM) is a tool for visualizing the data
communicated by robots during SPL games.

It serves two main purposes:

1. offering diagnostic data such as which robots are communicating on which
   team ports and whether the data that is sent by these conforms to the
   SPLStandardMessage, which is the standard communication protocol in the SPL
2. visualizing the data that was sent via SPLStandardMessages in both textual
   and graphical form.

For more info see [TCM](TCM.md).


## 5. libgamectrl (SPL)

libgamectrl automatically provides the GameController packets in ALMemory. 
It also implements the return channel of the GameController. It handles the 
buttons and LEDs according to the rules (with a few additions).


### Installation

Put the file libgamectrl.so somewhere on your NAO and add the library to your 
file "autoload.ini" so that NAOqi can find it. The binary provided was built
for NAOqi 2.1.

It is also possible to build the library from source using Aldebaran's qibuild
framework. The qiproject.xml and CMakeList.txt have been placed in 
libgamectrl's source folder. Just follow the instructions of the README file there.


### Usage

In your NAOqi module, execute the following code at the beginning (only once):

    AL::ALMemoryProxy *memory = new AL::ALMemoryProxy(pBroker);
    memory->insertData("GameCtrl/teamNumber", <your team number>);
    memory->insertData("GameCtrl/teamColour", <your default team color>);
    memory->insertData("GameCtrl/playerNumber", <your robot's player number>);

The team number must be non-zero. Setting the team number will reset 
libgamectrl (i.e. go back to the initial state). libgamectrl will also set 
"GameCtrl/teamNumber" back to zero, so it will recognize the next time your 
application is started.

Setting the default team color can actually be omitted now. In that case, it
is black, i.e. the corresponding foot LED is switched off.

You can receive the current GameController packet with:

    RoboCupGameControlData gameCtrlData; // should probably zero it the first time it is used
    AL::ALValue value = memory->getData("GameCtrl/RoboCupGameControlData");
    if (value.isBinary() && value.getSize() == sizeof(RoboCupGameControlData))
        memcpy(&gameCtrlData, value, sizeof(RoboCupGameControlData));


### Deviations from the Rules

The first time the chest button is pressed it is ignored, because many teams 
will use it to let the robot get up.

In the Initial state, it is also possible to switch between "normal", 
"penalty taker" (green LED), and "penalty goalkeeper" (yellow LED) by pressing 
the right foot bumper. The state is shown by the right foot LED, and only in 
the Initial state. An active GameController will overwrite these settings.



## 6. Coach Messages

The coach broadcasts messages as defined in SPLCoachMessage.h to the UDP port
SPL_COACH_MESSAGE_PORT through the wireless network. Players are not permitted
to listen to this port. The GameController will integrate the coach messages
into the RoboCupGameControlData packet and forward them to the players according
to the SPL rules. Since coach messages must be human readable, it is assumed
that they are a zero-terminated string and all data after the first zero
character is zeroed, too.

The GameStateVisualizer also displays the coach messages.

Please note that the field "team" now contains the team number, not the color.


## 7. Misc

The format of the packets the GameController broadcasts at port
GAMECONTROLLER\_DATA\_PORT and receives at port GAMECONTROLLER\_RETURN\_PORT
is defined in the file RoboCupGameControlData.h. It differs from the version used
in 2014 in several ways:

- Inside the messages, teams are now identified by their number rather than their 
  color (e.g. kickOffTeam, dropInTeam).

- SPLCoachMessage as well as TeamInfo now have a sequence number of 1 byte which
  is set by the coach.

- Coach messages now have a data packet size of 81 bytes instead of 40. 

- RoboCupGameControlData now has the gameType flag, which indicates whether the
  current game is a round-robin game (time does not stop), a drop-in player game
  (the same, but only one half), or a play-off game, i.e. a (quarter / semi)
  final (time is stopped).


## 8. Known Issues

There are still a number of issues left:

- When running on the same PC, the GameStateVisualizer sometimes does not
  receive the GameController packets anymore. This error is hard to reproduce,
  but it happened quite often in Eindhoven. It did not in João Pessoa, but there 
  the GameStateVisualizer was never running for a long time in a row.
  
- The qibuild file for libgamectrl is untested.

- The alignment of button labels is bad if the buttons are small.
