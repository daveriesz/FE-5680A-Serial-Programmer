# FE-5680A Serial Programmer

This is a simple Bash script to manage the frequency of a FE-5680A rubidium
frequency standard.  It can print the current frequency, set a new frequency,
and persist the current freqency to NVRAM so that it is remembered if the
unit's power is diconnected.

It may also work with other FE-56xx devices.  I haven't investigated this.

## Running

Command-line usage can be obtained at any time with the ```-h```, ```--help```, or ```help``` arguments.  You will see the output:

```
Usage:

  fe5680.sh help
  fe5680.sh --help
  fe5680.sh -help
    Print this help message

  fe5680.sh device <dev> [opt] <cmd ...>
    Execute command(s) on a given FE56xx serial device, where:
      "device <dev>" specifies the serial device
      [opt] is an optional argument:
         "raw"  print serial I/O from the device to stderr
      <cmd> is one or more of the following:
        "get"   print the current frequency
        "set N" set the frequency to N Hz
        "write" write the current frequency to NVRAM
```

Example 1:

```
  $ ./fe5680.sh device /dev/ttyUSB0 get
```

This prints the frequency of the FE-5680A device connected to serial port
```/dev/ttyUSB0```.  It will output something like:

```
Frequency: 10,000,000.00 Hz
```

Example 2:

```
  $ ./fe5680.sh device /dev/ttyUSB0 get set 10123000.1 get
```

This prints the frequency of the FE-5680A device connected to serial port
```/dev/ttyUSB0```, sets the frequency to 10,123,000.1 Hz, then prints the
frequency again.  It will output something like:

```
Frequency: 9,999,999.80 Hz
Set frequency command succeeded.
Frequency: 10,123,000.10 Hz
```

## Issues

Issue?  Bug?  Feature request?  Please submit an [issue](issues).

## Contributing

Feel free to submit a pull request if you want to contribute.
I'm not very good at reading other people's code, so please
include a verbose description and/or explanation.

## Licensing

The script and attendant documentation are Copyright (C) 2023 David Riesz.

This project and its code are all licensed under the MIT License.
Please read the [license file](LICENSE).

