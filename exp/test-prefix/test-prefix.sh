
set -e

SELF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

NODES=$1
if [ -z "${NODES}" ]
then
	NODES=1
fi

run() {
	echo "$@"
	"$@"
}

MPI_ARGS=(-n $nproc)
if [[ "${NODES}" -gt 1 ]]
then
	MPI_ARGS+=(--bynode)
fi

for solver in mumps superlu_dist pastix
do
	for nproc in 1 2
	do
		run mpirun ${MPI_ARGS[@]} python "${SELF_DIR}"/../apps/firedrake/matrix_free/stokes-casper.py 64 $solver 0 1
		run mpirun ${MPI_ARGS[@]} python "${SELF_DIR}"/../apps/fenics/cavity/demo_cavity.py 64 $solver 0 1

		if [[ "$solver" = "superlu_dist" ]]
		then
			eselect superlu_dist set superlu_dist_cuda
		fi

		run mpirun ${MPI_ARGS[@]} python "${SELF_DIR}"/../apps/firedrake/matrix_free/stokes-casper.py 64 $solver 1 1
		run mpirun ${MPI_ARGS[@]} python "${SELF_DIR}"/../apps/fenics/cavity/demo_cavity.py 64 $solver 1 1

		if [[ "$solver" = "superlu_dist" ]]
		then
			eselect superlu_dist set superlu_dist
		fi
	done
done
