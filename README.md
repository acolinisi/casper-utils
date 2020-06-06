Utilities for building CASPER and running experiments.

Build Gentoo Prefix with CASPER and dependencies
================================================

Step 1. Prepare source tarballs
------------------------------

To build Gentoo Prefix need to pre-populate `distfiles/` directory
with some special source tarballs (even if the build host is online).

All source tarballs are on USC HPCC filesystem in
`/scratch/acolin/casper-utils/distfiles/`, so you can just copy
all of it:

	$ rsync -aq /scratch/acolin/casper-utils/distfiles/ casper-utils/distfiles/

For offline build hosts (e.g. worker nodes on USC HPCC), the above copy
of the whole distfiles directory is a requirement. For online hosts, it
is sufficient to copy only the special tarballs listed below (however, if you
have access to all, then might as well copy all to not waste Internet
bandwidth).

The special source taballs that must be prepopulated, even for online build hosts:

* `portage-DATE.tar.bz2`
* `gentoo-DATE.tar.bz2`

  The snapshot date is indicated in the job script.  Cannot always be fetched
  from online, because upstream hosts only about 1 month.

* `gentoo-headers{,-base}-KERNEL_VERSION.tar.gz`

  Archives for the kernel version running on the host. The archives for 3.10
  are available in `distfiles/` (see below). To make an archive for other kernel
  versions, see the comments in the ebuild.

* `tetgen` (manually fill out form to get download link)
* `ampi` (manually fill out form to get download link)
* `pyop2` (due to checksum changes in tarball autogenerated by GitHub)

Step 2. Run build job
---------------------
To build Gentoo Prefix on USC HPPC: `jobs/gpref.job.sh`

    $ casper-utils/jobs/gpref.job.sh PREFIX_PATH casper-usc-hpcc-ARCH ARCH

To build Gentoo Prefix on other hosts:

    $ casper-utils/jobs/gpref.sh PREFIX_PATH casper-usc-hpcc-ARCH

where
* the first argument (`PREFIX_PATH`) is a relative or absolute folder where
  the prefix will be built (ensure several GB of space, and note that after
  prefix is built it cannot be relocated to another path), on USC HPCC you
  most likely want this to be under /scratch or /scratch2 filesystem;
* the second argument is a Gentoo profile name where ARCH identifies the CPU
  family for which to optimize via the `-march,-mtune` compiler flags (for the
  generic unoptimized use `amd64`; for supported families see
 `ebuilds/profiles/casper-usc-hpcc-*`),
* the third argument (for USC HPCC only) ARCH again, but cannot be `amd64`;
  even if you want a generic (unoptimized) build, you still have to choose a
  CPU family for the build host (`sandybridge` is a reasonable choice for
  building a generic prefix, see notes below).

Some notes:

* Due to imperfections in the build recipes for some libraries, the
  cpu family of the build host must be the same as that of the target host,
  i.e. if you want a prefix optimized for Sandy Bridge, you have to
  build it on a Sandy Bridge node. (This could be fixed by tracking down
  the offending packages and fixing each to not use target compiler flags
  for tools that need to be run on the build host.)
* Some packages optimize for the build host even if you did not request
  any optimization, so you can't build a generic unoptimized prefix on
  a new CPU family; use Sandy Bridge nodes to build generic prefixes that
  should mostly work on newer CPU families too.
* Builds of numerical libraries on AMD Opteron node appear to be broken
  when optimized for opteron CPU family (even with `-march=native`).

Step 3. Test the prefix
------------------------

The `test-prefix.sh` runs a CFD benchmark in FEniCS and Firedrake
with MPI and GPU.

On a host compatible with the ARCH for which the prefix was built:

    $ PREFIX_PATH/startprefix 
    $ mkdir -p casper-utils/exp/dat cd casper-utils/exp/dat
    $ bash ../jobs/test-prefix.sh

To enqueue this job onto a worker node on USC HPCC, make use of the helper
script `psbatch` (like `sbatch`, but run in a prefix) shipped in `bin/`:

    $ export PATH=/PATH/TO/casper-utils/bin:$PATH
    $ mkdir -p casper-utils/exp/dat cd casper-utils/exp/dat
    $ psbatch PREFIX_PATH ARCH "v100:1" 2G 1 2 00:30:00 bash ../jobs/test-prefix.sh

where the arguments are:

1. the path to the prefix built earlier
2. the CPU family for which the prefix was built (see above)
3. a SLURM GRES specification for requesting GPU resource
4. amount of memory per task
5. number of nodes
6. number of tasks (total, not per-node)
7. time limit for the job
