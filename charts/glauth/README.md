
## Merge `conf` with your `values-override.yaml`

>> mikefarah/yq utility needed

```bash

tmp_conf=$(mktemp)
sed -e 's/^/  /' conf > ${tmp_conf}
sed -i '1 i\cnf: |-' ${tmp_conf}
yq eval-all 'select(fileIndex==0).config.cnf = select(fileIndex==1).cnf | select(fileIndex==0)' -i values-override.yaml ${tmp_conf}


## Only works in bash
# function overrrideConf()
# {
#   RED="\x1B[31m"
#   RESET="\x1B[0m"
#   if [[ -z ${1} || -z ${2}]] && echo >&2 "${RED}Provide proper files${RESET}" &&& exit 1
#   tmp_conf=$(mktemp)
#   sed -e 's/^/  /' ${2} > ${tmp_conf}
#   sed -i '1 i\cnf: |-' ${tmp_conf}
#   yq eval-all 'select(fileIndex==0).config.cnf = select(fileIndex==1).cnf | select(fileIndex==0)' -i ${1} ${tmp_conf}
# }
```
