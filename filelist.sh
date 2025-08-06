#!/bin/bash 
split(){
  eval parsed_path=$1
  echo "reading $parsed_path"
  while IFS= read -r line; do
    if [[ "$line" =~ ^-f ]] 
    then
      line=${line#*-f}
      split $line $2 $3
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
file2vivado(){
  eval parsed_path=$1
  echo "reading $parsed_path"
  while IFS= read -r line; do
    if [[ "$line" =~ ^-f ]] 
    then
      line=${line#*-f}
      file2vivado $line $2 
    elif [[ "$line" =~ ^\+incdir\+ ]] 
    then
      line=${line#*+incdir+}
      if [[ -n $line ]]; then
	      echo "set include_dirs [concat $line \$include_dirs]" >> $2
      fi
    elif [[ "$line" =~ ^\/\/ ]] 
    then
      line=''
    else
      if [[ -n $line ]]; then
        echo "add_files $line" >> $2
      fi
    fi
  done < <(cat $parsed_path)
}
if [[ "$#" -eq 4 && "${1,,}" == "split" ]]; then
  echo '' > $3
  echo '' > $4
  split $2 $3 $4
  sed -i '/^[[:space:]]*$/d' $3
  sed -i '/^[[:space:]]*$/d' $4
elif [[ "$#" -eq 3 && "${1,,}" == "vivado" ]]; then
  echo 'set include_dirs [list]' > $3
  file2vivado $2 $3
  sed -i '/^[[:space:]]*$/d' $3
else
  echo "filelist  "
  echo "    split   <input file list>   <output file list>          <output include list>  "
  echo "    vivado  <input file list>   <output vivado read tcl>                           "
fi
