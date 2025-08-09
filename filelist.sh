#!/bin/bash 
rtl(){
  eval parsed_path=$1
  echo "reading $parsed_path"
  while IFS= read -r line; do
    if [[ -n $line ]]; then
      echo "+incdir+$line" >> $2
    fi
  done < <(find $parsed_path -path "*/inc")
  while IFS= read -r line; do
    if [[ -n $line ]]; then
      echo "$line" >> $2
    fi
  done < <(find $parsed_path -path "*/rtl/*.v")
  while IFS= read -r line; do
    if [[ -n $line ]]; then
      echo "$line" >> $2
    fi
  done < <(find $parsed_path -path "*/rtl/*.sv")
}
tb(){
  rtl $1 $2
  eval parsed_path=$1
  echo "reading $parsed_path"
  while IFS= read -r line; do
    if [[ -n $line ]]; then
      echo "$line" >> $2
    fi
  done < <(find $parsed_path -path "*/tb/*.v")
  while IFS= read -r line; do
    if [[ -n $line ]]; then
      echo "$line" >> $2
    fi
  done < <(find $parsed_path -path "*/tb/*.sv")
}
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
file2quartus(){
  eval parsed_path=$1
  echo "reading $parsed_path"
  while IFS= read -r line; do
    if [[ "$line" =~ ^-f ]] 
    then
      line=${line#*-f}
      file2quartus $line $2 
    elif [[ "$line" =~ ^\+incdir\+ ]] 
    then
      line=${line#*+incdir+}
      if [[ -n $line ]]; then
        echo "set_global_assignment -name SEARCH_PATH $line" >> $2
      fi
    elif [[ "$line" =~ ^\/\/ ]] 
    then
      line=''
    else
      if [[ -n $line ]]; then
        echo "set_global_assignment -name VERILOG_FILE $line" >> $2
      fi
    fi
  done < <(cat $parsed_path)
}
file2yosys(){
  eval parsed_path=$1
  echo "reading $parsed_path"
  while IFS= read -r line; do
    if [[ "$line" =~ ^-f ]] 
    then
      line=${line#*-f}
      file2yosys $line $2 
    elif [[ "$line" =~ ^\+incdir\+ ]] 
    then
      line=${line#*+incdir+}
      if [[ -n $line ]]; then
        echo "verilog_defaults -add -I$line" >> $2
      fi
    elif [[ "$line" =~ ^\/\/ ]] 
    then
      line=''
    else
      if [[ -n $line ]]; then
        echo "read_verilog $line" >> $2
      fi
    fi
  done < <(cat $parsed_path)
}
merge(){
  eval parsed_path=$1
  echo "reading $parsed_path"
  while IFS= read -r line; do
    if [[ "$line" =~ ^-f ]] 
    then
      line=${line#*-f}
      merge $1 $line $3
    else
      if [[ -n $line ]]; then
        echo "+incdir+$line" >> $3
      fi
    fi
  done < <(cat $parsed_path)
  eval parsed_path=$2
  echo "reading $parsed_path"
  while IFS= read -r line; do
    if [[ "$line" =~ ^-f ]] 
    then
      line=${line#*-f}
      merge $1 $line $3
    else
      if [[ -n $line ]]; then
        echo "$line" >> $3
      fi
    fi
  done < <(cat $parsed_path)
}
synopsys_setup(){
  eval parsed_path=$2
  echo "set target_library [list ]" >> $1
  for pvt in "${@:3}"; do
    echo "reading $parsed_path with $pvt"
    while IFS= read -r line; do
      if [[ -n $line ]]; then
        echo "set target_library [concat $line \$target_library ]" >> $1
      fi
    done < <(find $parsed_path -path $pvt)
  done
  echo "set link_library [concat * \$target_library ]" >> $1
}
if [[ "$#" -eq 3 && "${1,,}" == "rtl" ]]; then
  echo '' > $3
  rtl $2 $3
  sed -i '/^[[:space:]]*$/d' $3
elif [[ "$#" -eq 3 && "${1,,}" == "tb" ]]; then
  echo '' > $3
  tb $2 $3
  sed -i '/^[[:space:]]*$/d' $3
elif [[ "$#" -eq 4 && "${1,,}" == "split" ]]; then
  echo '' > $3
  echo '' > $4
  split $2 $3 $4
  sed -i '/^[[:space:]]*$/d' $3
  sed -i '/^[[:space:]]*$/d' $4
elif [[ "$#" -eq 3 && "${1,,}" == "vivado" ]]; then
  echo 'set include_dirs [list]' > $3
  file2vivado $2 $3
  sed -i '/^[[:space:]]*$/d' $3
elif [[ "$#" -eq 3 && "${1,,}" == "quartus" ]]; then
  echo '' > $3
  file2quartus $2 $3
  sed -i '/^[[:space:]]*$/d' $3
elif [[ "$#" -eq 3 && "${1,,}" == "yosys" ]]; then
  echo '' > $3
  file2yosys $2 $3
  sed -i '/^[[:space:]]*$/d' $3
elif [[ "$#" -eq 4 && "${1,,}" == "merge" ]]; then
  echo '' > $4
  merge $2 $3 $4
  sed -i '/^[[:space:]]*$/d' $4
elif [[ "${1,,}" == "synopsys_setup" ]]; then
  echo "write to $2"
  echo '' > $2
  synopsys_setup "${@:2}"
  sed -i '/^[[:space:]]*$/d' $2
else
  echo "filelist  "
  echo "    rtl              <root directory>       <output file list>                                       "
  echo "    tb               <root directory>       <output file list>                                       "
  echo "    split            <input file list>      <output file list>            <output include list>      "
  echo "    vivado           <input file list>      <output vivado read tcl>                                 "
  echo "    quartus          <input file list>      <output quartus read tcl>                                "
  echo "    yosys            <input file list>      <output yosys read script>                               "
  echo "    merge            <input include list>   <input file list>             <output file list>         "
  echo "    synopsys_setup   <output tcl script>    <lib directory>               <pvts ...>                 "
fi
