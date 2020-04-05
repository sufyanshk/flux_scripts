#Copyright (C) 2020 S#Copyright (C) 2020 Sufyan M. Shaikh
#!/bin/bash
#PBS -q batch
#PBS -N 2monb_001_222 
#PBS -l nodes=node4:ppn=16
#PBS -o evsvol_coarse.out
#PBS -e evsvol_coarse.err

cd $PBS_O_WORKDIR

#THIS SCRIPT SHOULD BE USED FOR INITIAL STRUCUTRAL AND SHAPE RELAXATION
#CHECK THE POSCAR FILE SECTION, CONFIRM THE ELEMENTS AND THEIR RESPECTIVE
#ATOMS ARE CORRECTLY DEFINED

if [ -f summary1.csv ];then
        rm summary1.csv
        if [ -f summary_EvsV_coarse.csv ]; then
                rm summary_EvsV_coarse.csv
        fi
fi

#Define no. of cores
n_cores=16

#Name of the system
sys_name="NbMo"

#Energy cut-off value (for structure relaxation take 1.3x the ENMAX of POTCAR)
e_cutoff=300

#INCAR file will be written here
cat >INCAR <<!
	SYSTEM	= $sys_name
	ISTART	= 0
	NPAR	= 4
	ALGO 	= FAST
	ISPIN 	= 2 
	NSIM 	= 4
	ENCUT 	= $e_cutoff
	IBRION 	= 2
	NELM 	= 100
	NELMIN 	= 3 
	ISIF 	= 3
	ISMEAR 	= 1
	MAGMOM 	= 5 5 
	SIGMA 	= 0.2
	PREC 	= Accurate
	LWAVE 	= .FALSE.
	LREAL 	= AUTO
	LCHARG 	= .FALSE.
	LVTOT 	= .FALSE.
!

#Initial POSCAR, POTCAR and KPOINTS will be taken from the folder.
#Later only the POSCAR and INCAR files will be changed.
#Rest of the files will be used as it is.

#First relaxation will take place.
#This is the first run of the VASP for structure relaxation.
echo "FIRST RELAXATION STARTED"
/apps/INTEL/INTEL2018_new/compilers_and_libraries_2018.5.274/linux/mpi/intel64/bin/mpirun -np $n_cores -hostfile $PBS_NODEFILE vasp > log
echo "FIRST RELAXATION OVER"

#After the first run, the CONTCAR file will be copied to POSCAR.
cat CONTCAR > POSCAR
echo "CONTCAR COPIED TO POSCAR"

#Again the relaxation will be done with new POSCAR.
echo "VASP SECOND RUN STARTED"
/apps/INTEL/INTEL2018_new/compilers_and_libraries_2018.5.274/linux/mpi/intel64/bin/mpirun -np $n_cores -hostfile $PBS_NODEFILE vasp > log
echo "SECOND RUN OF VASP IS OVER"

#For getting correct energy values, one more calculation will be done with TETRAHEDRON method (ISMEAR=-5).
#There won't be any relaxation for this run (IBRION=-1).
#INCAR file will be written here
echo "INCAR FILE WILL BE EDITED"
sed -i "s/ISMEAR.*/ISMEAR = -5/" INCAR
sed -i "s/IBRION.*/IBRION = -1/" INCAR

echo "STARTING FINAL ENERGY CALCULATION FOR CORRECT ENERGY VALUES"
/apps/INTEL/INTEL2018_new/compilers_and_libraries_2018.5.274/linux/mpi/intel64/bin/mpirun -np $n_cores -hostfile $PBS_NODEFILE vasp > log
echo "FINAL ENERGY CALCULATION IS OVER"

echo "STARTING E vs V CALCULATIONS"

#POSCAR will be changed for every new lattice parameter and the values will be used to calculated the energies.
#These energies will saved in SUMMARY file, which will be later used to plot E vs V graph.

for i in $(seq 1 1 10) 
do
	sed -i "1s/.*/$sys_name/" POSCAR
	sed -i "2s/.*/$i/" POSCAR
	echo "a= $i"
	/apps/INTEL/INTEL2018_new/compilers_and_libraries_2018.5.274/linux/mpi/intel64/bin/mpirun -np $n_cores -hostfile $PBS_NODEFILE vasp > log
	
	#This will write in to file summary.csv file.
	#The columns will be sepereated with spaces.
	E=`awk '/F=/ {print $0}' OSZICAR` ; echo $i kp $E >> summary1.csv
done

#This will seperate the columns by commas and only the 
#lattice parameter, K-points and Energies will be printed to summary_EvsV_coarse.csv file.
awk '{print $1","$2","$5}' summary1.csv > summary_EvsV_coarse.csv

#Plots the E vs. V using gnuplot
gnuplot plot_coarse.plt

echo "$sys_name : E vs. V \"COARSE\" CALCULATIONS ARE FINISHED"
printf "\n"