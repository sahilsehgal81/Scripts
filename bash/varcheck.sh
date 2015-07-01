#!/bin/bash
# varcheck.sh: Variable sanity check with :? 
#path=${1:?Error command line argument not passed}
path=${1:?Error command line argument not passed}
echo "Backup path is $path."
echo "I'm done if \$path is set."
