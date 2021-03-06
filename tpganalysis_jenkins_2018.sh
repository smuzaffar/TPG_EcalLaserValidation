#!/bin/bash -ex
#Jenkins script for TPGAnalysis and ECAL conditions' validation

echo "Running automated fast track validation script. Will compare ECAL trigger primitives rate difference for two different sets of conditions "
echo "reference and test sqlite files"
echo " "

###############################
dataset=Run2017D/SinglePhoton/RAW/v1
GT=94X_dataRun2_v2
reference=302635
sqlite1=303573
sqlite2=303835
week=39
nevents=500
INSTALL=true
RUN=true
###############################

datasetpath=`echo ${dataset} | tr '/' '_'`

export CMSREL=CMSSW_9_4_0_pre3
export RELNAME=TPLasVal_940pre3
export SCRAM_ARCH=slc6_amd64_gcc630

if ${INSTALL}; then
scram p -n $RELNAME CMSSW $CMSREL
cd $RELNAME/src
eval `scram runtime -sh`

git cms-init
git remote add cms-l1t-offline git@github.com:cms-l1t-offline/cmssw.git
#git fetch cms-l1t-offline
git fetch https://github.com/cms-l1t-offline/cmssw.git
git cms-merge-topic -u cms-l1t-offline:l1t-integration-v97.1
git cms-addpkg L1Trigger/L1TCommon
git cms-addpkg L1Trigger/L1TMuon
git clone --depth 1 https://github.com/cms-l1t-offline/L1Trigger-L1TMuon.git L1Trigger/L1TMuon/data

scram b -j $(getconf _NPROCESSORS_ONLN)
#cp -r /eos/cms/store/caf/user/ecaltrg/EcalTPGAnalysis .
git clone --depth 1 -b tpganalysis_jenkins https://gitlab.cern.ch/ECALPFG/EcalTPGAnalysis.git
export USER_CXXFLAGS="-Wno-delete-non-virtual-dtor -Wno-error=unused-but-set-variable -Wno-error=unused-variable -Wno-error=sign-compare -Wno-error=reorder"
scram b -j $(getconf _NPROCESSORS_ONLN)
else
cd $RELNAME/src
fi
eval `scram runtime -sh`
cd EcalTPGAnalysis/Scripts/TriggerAnalysis
   if ${RUN}; then
./runTPGbatchLC_jenkins_2018.sh jenkins $reference $dataset $GT $nevents $sqlite1 &
./runTPGbatchLC_jenkins_2018.sh jenkins $reference $dataset $GT $nevents $sqlite2 &
wait
fi
cp addhist_jenkins_2018.sh log_and_results/${reference}-${datasetpath}-LC-IOV_${sqlite1}-batch/.
pushd log_and_results/${reference}-${datasetpath}-LC-IOV_${sqlite1}-batch/
./addhist_jenkins_2018.sh ${sqlite1} &
popd
cp addhist_jenkins_2018.sh log_and_results/${reference}-${datasetpath}-LC-IOV_${sqlite2}-batch/.
pushd log_and_results/${reference}-${datasetpath}-LC-IOV_${sqlite2}-batch/
./addhist_jenkins_2018.sh ${sqlite2} &
popd
wait

mv log_and_results/${reference}-${datasetpath}-LC-IOV_${sqlite1}-batch/newhistoTPG_${sqlite1}_eg12.root ../../TPGPlotting/plots/.

mv log_and_results/${reference}-${datasetpath}-LC-IOV_${sqlite2}-batch/newhistoTPG_${sqlite2}_eg12.root ../../TPGPlotting/plots/.

cd ../../TPGPlotting/plots/

./validationplots_jenkins_2018.sh $sqlite1 $sqlite2 $reference $week

