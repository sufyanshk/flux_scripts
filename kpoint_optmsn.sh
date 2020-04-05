#Copyright (C) 2020 Sufyan M. Shaikh
#!/bin/bash
#PBS -q batch
#PBS -N 2monb_001_222 
#PBS -l nodes=node4:ppn=16
#PBS -o evsvol_coarse.out
#PBS -e evsvol_coarse.err

cd $PBS_O_WORKDIR

#THIS FILE SHOULD ONLY BE USED FOR OPTIMISING KPOINTS...
#AFTER THE E vs V HAS BEEN OPTIMISED AND...
#THE PRECISE LATTICE PARAMETER HAS BEEN FOUND OUT.

if [ -f summary1.csv ];then
        rm summary1.csv
        if [ -f summary_EvsV_coarse.csv ]; then
                rm summary_EvsV_coarse.csv
        fi
fi

#Name of the system
sys_name="NbMo"

#Define no. of cores
n_cores=300

#Precise lattice parameter, found out from earlier runs of VASP.
i=2.9

#POSCAR with precise lattice parameter will be written here.
sed -i "1s/.*/$sys_name/" POSCAR
sed -i "2s/.*/$i/" POSCAR

#KPOINTS will be changed and the respective energies will be calculated.
#Put the range of K-point in which you want to get the energy values.
for kp in $(seq 4 1 20)
do
	sed -i "4s/.*/$kp $kp $kp/" KPOINTS

	echo "a= $i K-points=$kp $kp $kp"
	
	#Energy will be calculated for every KPOINT
	/apps/INTEL/INTEL2018_new/compilers_and_libraries_2018.5.274/linux/mpi/intel64/bin/mpirun -np $n_cores -hostfile $PBS_NODEFILE vasp > log
	
	#Lattice parameter, K-points and energy will be written in the "summary3.csv" file
	E=`awk '/F=/ {print $0}' OSZICAR` 
	echo $i $kp $E >> summary3.csv
done

#This will seperate the columns with commas and the final file will "summary_with_kp.csv".
awk '{print $1","$2","$5}' summary3.csv >> summary_with_kp.csv

#Plots E vs. K-points for given precise lattice parameter
gnuplot plot_kp.plt

echo "$sys_name : K-point optimisation finished"
printf "\n"
