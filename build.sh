#!/bin/bash

moonc src/
mv src/*.lua .

rm NodekaMudlet.mpackage
7z -tzip a NodekaMudlet.mpackage *
