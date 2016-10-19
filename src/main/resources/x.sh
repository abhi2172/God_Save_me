PATH=/bin:/usr/bin:/usr/ucb:/etc:/usr/local/bin:/usr/ccs/bin
export PATH

ulimit -s unlimited
ulimit -n 65536
umask 022
export ORACLE_SID=DEV1
export ORACLE_HOME=/env346/Norashr/DEV1/dev1ora/8.0.6
export TNS_ADMIN=/env346/Norashr/DEV1/dev1ora/8.0.6/network/admin/DEV1_nj09mhe5019
#export PATH = $PATH:/env346/Nrdbmssw/rdbms_base/product/11.1.0/bin/sqlldr
export PATH=$PATH:/env346/Norashr/DEV1/dev1ora/8.0.6/bin
. /env346/Norashr/DEV1/dev1appl/APPSDEV1_nj09mhe5019.env
FORMS60_PATH=$FORMS60_PATH:$AU_TOP/forms/US:$MHEAU_TOP/forms/US
export FORMS60_PATH

cd /env346/Norashr/DEV1/dev1appl/mheau/11.5.0/forms/US/
echo `pwd`
for f in `ls *.fmb|head -3`
do
   f1=`echo "$f" | cut -d'.' -f1`
   /env346/Norashr/DEV1/dev1ora/8.0.6/bin/f60gen Module=$f Userid=apps/dev1apps Output_file=$f1.fmx
done
echo "compilation done"
rm -rf /tmp/release/*.fmb
echo "fmb files got removed"