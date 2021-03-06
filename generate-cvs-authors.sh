#!/bin/sh

# Generates a list of authors which will be compatible with 
# cvs2git/cvs2svn config. Run on a network that understands
# how to convert a username to a name. We assume
# 
#
# Recommend running like
#
#    # Assumes you are in a CVS controlled directory
#    ./generate-cvs-authors.sh
#
#    # Assumes you need public CVS access
#    ./generate-cvs-authors.sh ensembl-rest
#
#    # Allows you to change the CVS root area if need be
#    ./generate-cvs-authors.sh biomart-perl biomart

PROJ=${1:-ensembl-foo}
ROOT=${2:-ensembl}
if [ -d CVS ]; then
  authors=$(cvs -Q log | grep author | perl -lne 'print $1 if (/author: (\w+);/)' | sort -u)
else
  public_cvsroot=":pserver:cvsuser@cvs.sanger.ac.uk:/cvsroot/$ROOT"
  authors=$(cvs -Q -d $public_cvsroot rlog $PROJ | grep author | perl -lne 'print $1 if (/author: (\w+);/)' | sort -u)  
fi

echo 'author_transforms={'
echo "'ensembl' : 'Ensembl <ensembl>',"
echo "'cvs2git' : 'cvs2git <cvs2git>',"
for author in $authors; do
  #Combine stdout and stderr. Then look for the bad string
  finger_output=$(finger -m $author 2>&1)
  if [[ "$finger_output" == *"no such user"* ]]; then
    echo "    '$author' : ('$author','$author@sanger.ac.uk')," 
  else
    full_name=$(finger -m $author | sed -e '/Name/!d' -e 's/.*Name: //' | perl -lne '$v=$1 if /^([-a-z ]+)/i; $v =~ s/\s+$//; print $v')
    echo "    '$author' : ('$full_name','$author@sanger.ac.uk'),"
  fi
done
echo "}"
