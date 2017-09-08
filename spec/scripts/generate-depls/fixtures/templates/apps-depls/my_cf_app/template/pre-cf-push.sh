#!/bin/sh
echo "creating php info application"
cat << EOF > ${GENERATE_DIR}/index.php
<?php
  phpinfo();
?>
EOF

cf create-org "$CF_ORG"
cf create-space "$CF_SPACE" -o "$CF_ORG"
cf target -s "$CF_SPACE" -o "$CF_ORG"
