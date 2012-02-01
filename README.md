## TODO
* Make use of clustering to allow for higher connection counts.
* Add support for pause/resume
* Gracefully handle connection drops


## Installation
Make sure you have the latest node installed and using npm run:
```
$ npm install -g getbot
```
## Usage

To download a file to a folder, CD into the destination folder and run the following:
```
$ getbot <address>
```
and Bob's your uncle.

To download a file that requires basic HTTP Auth:
```
$ getbot -u <user> -p <pass> <address>
```
or
```
$ getbot <address> (if the address contains the credentials)
```