#!/bin/bash

##########################################################
##                                                      ##
## Shell script for generating a boards manager release ##
## Created by MCUdude                                   ##
## Requires wget, jq and a bash environment             ##
##                                                      ##
##########################################################

# Change these to match your repo
AUTHOR=SpenceKonde      # Github username
REPOSITORY=megaTinyCore # Github repo name

# Get the download URL for the latest release from Github
DOWNLOAD_URL=$(curl -s https://api.github.com/repos/$AUTHOR/$REPOSITORY/releases/latest | grep "tarball_url" | awk -F\" '{print $4}')

# Download file
wget --no-verbose $DOWNLOAD_URL

# Get filename
DOWNLOADED_FILE=$(echo $DOWNLOAD_URL | awk -F/ '{print $8}')

# Add .tar.bz2 extension to downloaded file
mv $DOWNLOADED_FILE ${DOWNLOADED_FILE}.tar.bz2

# Extract downloaded file and place it in a folder (the #"v"} part removes the v in the version number if it is present)
printf "\nExtracting folder ${DOWNLOADED_FILE}.tar.bz2 to $REPOSITORY-${DOWNLOADED_FILE#"v"}\n"
mkdir -p "$REPOSITORY-${DOWNLOADED_FILE#"v"}" && tar -xzf ${DOWNLOADED_FILE}.tar.bz2 -C "$REPOSITORY-${DOWNLOADED_FILE#"v"}" --strip-components=1
printf "Done!\n"

# Move files out of the megaavr folder
mv $REPOSITORY-${DOWNLOADED_FILE#"v"}/megaavr/* $REPOSITORY-${DOWNLOADED_FILE#"v"}

# Delete the extras folder
rm -rf $REPOSITORY-${DOWNLOADED_FILE#"v"}/extras

# Delete downloaded file and empty megaavr folder
rm -rf ${DOWNLOADED_FILE}.tar.bz2 $REPOSITORY-${DOWNLOADED_FILE#"v"}/megaavr

# Comment out the github/manual installation's tools.pymcuprog.cmd...
sed -i 's/^tools.pymcuprog.cmd/#tools.pymcuprog.cmd/' $REPOSITORY-${DOWNLOADED_FILE#"v"}/platform.txt

sed -i 's/^tools.serialupdi.cmd/#tools.serialupdi.cmd/' $REPOSITORY-${DOWNLOADED_FILE#"v"}/platform.txt
#
sed -i 's/^#REMOVE#//' $REPOSITORY-${DOWNLOADED_FILE#"v"}/platform.txt

cp $REPOSITORY-${DOWNLOADED_FILE#"v"}/platform.txt platform.extract

# Compress folder to tar.bz2
printf "\nCompressing folder $REPOSITORY-${DOWNLOADED_FILE#"v"} to $REPOSITORY-${DOWNLOADED_FILE#"v"}.tar.bz2\n"
tar -cjSf $REPOSITORY-${DOWNLOADED_FILE#"v"}.tar.bz2 $REPOSITORY-${DOWNLOADED_FILE#"v"}
printf "Done!\n"

# Get file size on bytes
FILE_SIZE=$(wc -c "$REPOSITORY-${DOWNLOADED_FILE#"v"}.tar.bz2" | awk '{print $1}')

# Get SHA256 hash
SHA256="SHA-256:$(shasum -a 256 "$REPOSITORY-${DOWNLOADED_FILE#"v"}.tar.bz2" | awk '{print $1}')"

# Create Github download URL
URL="https://${AUTHOR}.github.io/${REPOSITORY}/$REPOSITORY-${DOWNLOADED_FILE#"v"}.tar.bz2"

cp "package_drazzy.com_index.json" "package_drazzy.com_index.json.tmp"

# Add new boards release entry
jq -r                                   \
--arg repository $REPOSITORY            \
--arg version    ${DOWNLOADED_FILE#"v"} \
--arg url        $URL                   \
--arg checksum   $SHA256                \
--arg file_size  $FILE_SIZE             \
--arg file_name  $REPOSITORY-${DOWNLOADED_FILE#"v"}.tar.bz2  \
'(.packages[] | select(.name==$repository)).platforms[(.packages[] | select(.name==$repository)).platforms | length] |= . +
{
  "name": $repository,
  "architecture": "megaavr",
  "version": $version,
  "category": "Contributed",
  "url": $url,
  "archiveFileName": $file_name,
  "checksum": $checksum,
  "size": $file_size,
  "boards": [
    {
      "name": "Full Arduino support for the tinyAVR 0-series, 1-series, and the new 2-series!<br/> 24-pin parts: ATtiny3227/3217/1627/1617/1607/827/817/807/427<br/> 20-pin parts: ATtiny3226/3216/1626/1616/1606/826/816/806/426/416/406<br/> 14-pin parts: ATtiny3224/1624/1614/1604/824/814/804/424/414/404/214/204<br/> 8-pin parts: ATtiny412/402/212/202<br/> Microchip Boards: Curiosity Nano 3217/1627/1607 and Xplained Pro (3217/817), Mini (817) Nano (416). Direct USB uploads may not work on linux, but you can export hex and <br/> upload through the mass storage projection."
    },
    {
      "name": "2.6.3 was a bad release, 2.6.4 should resolve the issues with compiling most sketches under that version. It also adds the option to use the WDT fuse, and of course has the fixes from 2.6.0-2.6.3, waking from sleep as a Wire slave, half-duplex serial, and more, and corrects an issue with installation of 2.6.2"
    },
    {
      "name": "Supported UPDI programmers: SerialUPDI (serial adapter w/diode or resistor), jtag2updi, nEDBG, mEDBG, EDBG, SNAP, Atmel-ICE and PICkit4 - or use one of those to load<br/> the Optiboot serial bootloader (included) for serial programming. Which programing method makes more sense depends on your application and requirements. <br/><br/> The full documentation is not included with board manager installations (it is hard to find and the images bloat the download); we recommend viewing it through github at the link above<br/> or if it must be read withouht an internet connection by downaloding the manual installation package"
    }
  ],
  "toolsDependencies": [
    {
      "packager": "DxCore",
      "name": "avr-gcc",
      "version": "7.3.0-atmel3.6.1-azduino6"
    },
    {
      "packager": "DxCore",
      "name": "avrdude",
      "version": "6.3.0-arduino17or18"
    },
    {
      "packager": "arduino",
      "name": "arduinoOTA",
      "version": "1.3.0"
    },
    {
      "packager": "megaTinyCore",
      "version": "3.7.2-post1",
      "name": "python3"
    }
  ]
}' "package_drazzy.com_index.json.tmp" > "package_drazzy.com_index.json"

# Remove files that's no longer needed
rm -rf "$REPOSITORY-${DOWNLOADED_FILE#"v"}" "package_drazzy.com_index.json.tmp"
