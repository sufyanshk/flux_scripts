#Copyright (C) 2020 Sufyan M. Shaikh
#!/bin/bash
#PBS -q batch
#PBS -N 2monb_001_222 
#PBS -l nodes=node4:ppn=16
#PBS -o evsvol_fine.out
#PBS -e evsvol_fine.err

cd $PBS_O_WORKDIR

#THIS SCRIPT SHOULD BE USED FOR FINAL LATTICE PARAMETER CALCULATION ONLY
#CHECK THE POSCAR FILE SECTION, VERIFY THAT THE EACH ELEMENT AND ITS RESPECTIVE
#ATOMS ARE CORRECTLY DEFINED.

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

#Initial POSCAR, POTCAR and KPOINTS will be taken from the folder.
#Later only the POSCAR will be changed.
#Rest of the files will be used as it is.

#POSCAR will be changed for every new lattice parameter and the values will be used to calculated the energies.
#These energies will be saved in summary_EvsV_fine.csv file, which will be later used to plot E vs V graph...
#from which precise lattice parameter will be found out.

#Enter the probable range of lattice parameter. This is from the earlier VASP run.
#For better accuracy, keep the step size in for loop as 0.01
touch "fineals_started"
for i in $(seq 2 0.01 4) 
do
	sed -i "1s/.*/$sys_name/" POSCAR
	sed -i "2s/.*/$i/" POSCAR
	echo "a= $i"
	/apps/INTEL/INTEL2018_new/compilers_and_libraries_2018.5.274/linux/mpi/intel64/bin/mpirun -np $n_cores -hostfile $PBS_NODEFILE vasp > log
	
	#This will write in to file summary2.csv file.
	E=`awk '/F=/ {print $0}' OSZICAR` ; echo $i kp2 $E >> summary2.csv
done

#This will seperate the columns by commas and only the 
#lattice parameter, Energies will be printed to summary_EvsV_fine.csv file.
awk '{print $1","$2","$5}' summary2.csv > summary_EvsV_fine.csv

#Plots the fine E vs. V using gnuplot
gnuplot plot_fine.plt

echo "$sys_name : E vs. V \"FINE\" CALCULATION FINISHED" && touch "finaels_over"
printf "\n"
