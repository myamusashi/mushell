#!/usr/bin/env bash

find "$1" -name "*.desktop" -print0 | xargs -0 awk '
BEGIN { 
  FS="=";
}
FNR==1 { 
  name=""; 
  exec="";
}
/^Name=/ { name=$2 }
/^Exec=/ { exec=$2 }
ENDFILE {
  if (name != "" && exec != "") {
    split(FILENAME, parts, "/");
    filename = parts[length(parts)];
    sub(/\.desktop$/, "", filename);
    print filename "," name "," exec;
  }
}
'
