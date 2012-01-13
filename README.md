## TODO
* Make use of clustering to allow for higher connection counts.
* Add support for pause/resume
* Gracefully handle connection drops
* Think of another name for the project, there is an old out-dated segmented download manager out there for windows which makes this project name confusing.
* Add support for saving the file as another name
* Add support for setting the max connection number

## Installation
For now, clone this repo and run
    $ npm link
inside the cloned folder to try it out.

Note: We aren't totally happy with the script right now so it isn't in the official NPM repo yet.

## Usage

To download a file to a folder, CD into the destination folder and run the following:
    $ getbot <address>
and Bob's your uncle.

To download a file that requires basic HTTP Auth:
    $ getbot -u <user> -p <pass> <address>
or
    $ getbot <address> (if the address contains the credentials)