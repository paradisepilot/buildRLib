#!/bin/bash

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
currentDIR=`pwd`
  codeDIR=${currentDIR}/code
outputDIR=${currentDIR//github/gittmp}/output

if [ ! -d ${outputDIR} ]; then
	mkdir -p ${outputDIR}
fi

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
rpackagesFILE=Rpackages-desired.txt

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
cp -r ${codeDIR}    ${outputDIR}
cp ${rpackagesFILE} ${outputDIR}

##################################################
myRscript=${codeDIR}/buildRLib.R
stdoutFile=${outputDIR}/stdout.R.`basename ${myRscript} .R`
stderrFile=${outputDIR}/stderr.R.`basename ${myRscript} .R`
R --no-save --args ${codeDIR} ${outputDIR} ${rpackagesFILE} < ${myRscript} > ${stdoutFile} 2> ${stderrFile}

##################################################
exit

