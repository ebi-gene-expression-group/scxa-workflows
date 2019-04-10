function file_for_desc_param() {
  manifest_path=$1
  description=$2
  parameter=$3
  awk -F'\t' -v desc=$description -v param=$parameter  '$1 == desc && $3 == param { print $2 }' $manifest_path
}
