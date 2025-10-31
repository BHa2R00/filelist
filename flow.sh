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
file2dc_shell(){
  eval parsed_path=$1
  echo "reading $parsed_path"
  while IFS= read -r line; do
    if [[ "$line" =~ ^-f ]] 
    then
      line=${line#*-f}
      file2dc_shell $line $2 
    elif [[ "$line" =~ ^\+incdir\+ ]] 
    then
      line=${line#*+incdir+}
      if [[ -n $line ]]; then
        echo "lappend search_path $line" >> $2
      fi
    elif [[ "$line" =~ ^\/\/ ]] 
    then
      line=''
    else
      if [[ -n $line ]]; then
        echo "analyze -format verilog -define {$3 SCAN} $line" >> $2
      fi
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
db_lib(){
  eval parsed_path=$2
  #echo "sh rm -rfv dc_work" >> $1
  #echo "define_design_lib WORK -path dc_work" >> $1
  #echo "set command_log_file \"dc_work.log\"" >> $1
  echo "set target_library [list ]" >> $1
  for pvt in "${@:3}"; do
    echo "reading $parsed_path with $pvt"
    while IFS= read -r line; do
      if [[ -n $line ]]; then
	      if ! grep "${line##*/}" $1; then
          echo "target_library $line"
          echo "set target_library [concat $line \$target_library ]" >> $1
          lib_path="${line%.db}.lib"
          echo "read_liberty $lib_path" >> read_liberty.tcl
          echo "read_cell_library $lib_path" >> read_cell_library.tcl
		    fi
      fi
    done < <(find $parsed_path -path $pvt)
  done
  echo "set link_library [concat * \$target_library ]" >> $1
}
mw_lib(){
  eval parsed_path=$2
  #echo "sh rm -rfv icc_work.mw" >> $1
  echo "set mw_reference_library [list ]" >> $1
  echo "reading $parsed_path"
  while IFS= read -r line; do
    if [[ -n $line ]]; then
      line1=${line//FRAM/}
      echo "mw_reference_library $line1"
      echo "set mw_reference_library [concat $line1 \$mw_reference_library ]" >> $1
    fi
  done < <(find $parsed_path -path '*/FRAM')
  for pm in "${@:3}"; do
    while IFS= read -r line; do
      if [[ -n $line ]]; then
	      if ! grep "${line##*/}" $1; then
          echo "technology $line"
          echo "set technology $line" >> $1
		    fi
      fi
    done < <(find $parsed_path -path "$pm.tf")
  done
  #echo "create_mw_lib -technology \$technology -mw_reference_library \$mw_reference_library icc_work.mw" >> $1
  #echo "open_mw_lib icc_work.mw" >> $1
  while IFS= read -r line; do
    if [[ -n $line ]]; then
	    if ! grep "${line##*/}" $1; then
        echo "antenna $line"
        echo "source $line" >> $1
	    fi
    fi
  done < <(find $parsed_path -name '*ant*.tcl')
  echo "set stdcell_filler [list ]" >> $1
  while IFS= read -r line; do
    if [[ -n $line ]]; then
      line1="${line##*/}"
	    if ! grep $line1 $1; then
        echo "stdcell_filler $line1 " 
        echo "set stdcell_filler [concat $line1 \$stdcell_filler ]" >> $1
      fi
    fi
  done < <(find $parsed_path -path '*CEL/*FIL*' | sed 's/^.*CEL\/\(.*\):.*$/\1/')
}
lib2db(){
  eval path1=$1
  eval path2=$2
  #
lc_shell << EOF > /dev/null 
read_lib $path1 -no_warnings 
set lib_objects [get_lib *]
set lib_names [get_attr \$lib_objects name]
set lib_name [lindex \$lib_names 0]
write_lib -format db -output $path2 \$lib_name
exit
EOF
  #
}
libs2dbs(){
  eval parsed_path=$1
  while IFS= read -r line; do
    if [[ -n $line ]]; then
      line1="${line%.lib}.db"
      lib2db $line $line1
    fi
  done < <(find $parsed_path -name $2)
}
verilog_lib(){
  eval parsed_path=$2
  for pvt in "${@:3}"; do
    echo "reading $parsed_path with $pvt"
    while IFS= read -r line; do
      if [[ -n $line ]]; then
	      if ! grep "${line##*/}" $1; then
          echo "read_verilog $line -blackbox "
          echo "read_verilog $line -blackbox " >> $1
          #echo "read_verilog $line "
          #echo "read_verilog $line " >> $1
		    fi
      fi
    done < <(find $parsed_path -path $pvt)
  done
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
elif [[ "$#" -eq 4 && "${1,,}" == "dc_shell" ]]; then
  echo '' > $3
  file2dc_shell $2 $3 $4
  sed -i '/^[[:space:]]*$/d' $3
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
elif [[ "${1,,}" == "db_lib" ]]; then
  echo "write to $2"
  echo "# eda.sh ${@:1}" > $2
  echo "# eda.sh ${@:1}" > read_liberty.tcl
  echo "# eda.sh ${@:1}" > read_cell_library.tcl
  db_lib "${@:2}"
  sed -i '/^[[:space:]]*$/d' $2
elif [[ "${1,,}" == "mw_lib" ]]; then
  echo "write to $2"
  echo "# eda.sh ${@:1}" > $2
  mw_lib "${@:2}"
  sed -i '/^[[:space:]]*$/d' $2
elif [[ "${1,,}" == "lib2db" ]]; then
  echo "convert $2 to $3"
  lib2db "${@:2}"
elif [[ "${1,,}" == "libs2dbs" ]]; then
  libs2dbs "${@:2}"
elif [[ "${1,,}" == "verilog_lib" ]]; then
  echo "write to $2"
  echo "# eda.sh ${@:1}" > $2
  verilog_lib "${@:2}"
  sed -i '/^[[:space:]]*$/d' $2
else
  echo "$0                                                                                            "
  echo "    rtl         <root directory>       <output file list>                                     "
  echo "    tb          <root directory>       <output file list>                                     "
  echo "    split       <input file list>      <output file list>            <output include list>    "
  echo "    dc_shell    <input file list>      <output dc_shell read tcl>    <asic lib define>        "
  echo "    vivado      <input file list>      <output vivado read tcl>                               "
  echo "    quartus     <input file list>      <output quartus read tcl>                              "
  echo "    yosys       <input file list>      <output yosys read script>                             "
  echo "    merge       <input include list>   <input file list>             <output file list>       "
  echo "    db_lib      <output tcl script>    <lib directory>               <pvts ...>               "
  echo "    mw_lib      <output tcl script>    <lib directory>               <tech pattern ...>       "
  echo "    lib2db      <input liberty>        <output synopsys db>                                   "
  echo "    libs2dbs    <root directory>       <pattern>                                              "
  echo "    verilog_lib <output tcl script>    <lib directory>               <path pattern ...>       "
fi
