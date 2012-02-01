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

Getbot can also read a file and use each line as addresses to queue:

_downloads.txt (note each path on it's own line)_
```
http://file1.dmg
http://file2.zip
```

```
$ getbot -l downloads.txt
```
and off it goes