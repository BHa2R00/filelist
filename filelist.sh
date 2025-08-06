#!/bin/bash 
filelist(){
  eval parsed_path=$1
  echo "reading $parsed_path"
  while IFS= read -r line; do
    if [[ "$line" =~ ^-f ]] 
    then
      line=${line#*-f}
      filelist $line $2 $3
    elif [[ "$line" =~ ^\+incdir\+ ]] 
    then
      line=${line#*+incdir+}
	    echo $line >> $3
    elif [[ "$line" =~ ^\/\/ ]] 
    then
      line=''
    else
        echo $line >> $2
    fi
  done < <(cat $parsed_path)
}
if [[ "$#" -eq 3 ]]; then
  echo '' > $2
  echo '' > $3
  filelist $1 $2 $3
  sed -i '/^[[:space:]]*$/d' $2
  sed -i '/^[[:space:]]*$/d' $3
else
  echo "filelist <input file list> <output file list> <output include list>"
fi
