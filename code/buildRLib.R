
### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
command.arguments <- commandArgs(trailingOnly = TRUE);
   code.directory <- normalizePath(command.arguments[1]);
 output.directory <- normalizePath(command.arguments[2]);
pkgs.desired.FILE <- normalizePath(command.arguments[3]);

setwd(output.directory);

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
fh.output  <- file("log.output",  open = "wt");
fh.message <- file("log.message", open = "wt");

sink(file = fh.message, type = "message");
sink(file = fh.output,  type = "output" );

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
print("\n##### Sys.time()");
Sys.time();

start.proc.time <- proc.time();

###################################################
# default.libPaths <- setdiff(gsub(x=.libPaths(),pattern="^/(Users|home)/.+",replacement=""),c(""));
  default.libPaths <- setdiff(gsub(x=.libPaths(),pattern="^/(Users|home)/.+/buildRLib/.+",replacement=""),c(""));

cat("\n# default.libPaths\n");
print(   default.libPaths   );

.libPaths(default.libPaths);

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
# copy the file of desired packages to output directory
file.copy(
    from = pkgs.desired.FILE,
    to   = "."
    );

# read list of desired R packages
pkgs.desired <- read.table(
    file = pkgs.desired.FILE,
    header = FALSE,
    stringsAsFactors = FALSE
    )[,1];

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
# assemble full path for R library to be built
current.version <- paste0(R.Version()["major"],".",R.Version()["minor"]);
myLibrary <- file.path(".","library",current.version,"library");
if(!dir.exists(myLibrary)) { dir.create(path = myLibrary, recursive = TRUE); }

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
# exclude packages already installed
preinstalled.packages <- as.character(
    installed.packages(lib.loc = c(.libPaths(),myLibrary))[,"Package"]
    );

cat("\n# pre-installed packages:\n");
print(   preinstalled.packages     );

pkgs.desired <- setdiff(
    pkgs.desired,
    preinstalled.packages
    );

cat("\n# packages to be installed:\n");
print(   pkgs.desired   );

write.table(
    file      = "Rpackages-desired-minus-preinstalled.txt",
    x         = data.frame(package = sort(pkgs.desired)),
    quote     = FALSE,
    row.names = FALSE,
    col.names = FALSE
    );

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
# get URL of an active CRAN mirror
CRANmirrors   <- getCRANmirrors();
CRANmirrors   <- CRANmirrors[CRANmirrors[,"OK"]==1,];
caCRANmirrors <- CRANmirrors[CRANmirrors[,"CountryCode"]=="ca",c("Name","CountryCode","OK","URL")];
if (nrow(caCRANmirrors) > 0) {
	myRepoURL <- caCRANmirrors[nrow(caCRANmirrors),"URL"];
	} else if (nrow(CRANmirrors) > 0) {
	myRepoURL <- CRANmirrors[1,"URL"];
	} else {
	q();
	}

print(paste("\n##### myRepoURL",myRepoURL,sep=" = "));

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
is.macOS <- grepl(x = sessionInfo()[['platform']], pattern = 'apple', ignore.case = TRUE);
myType   <- ifelse(test = is.macOS, yes = "binary", no = getOption("pkgType"));

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
# install package 'tiff' to user-specified library
cat("\n##### installation begins: 'tiff' ...\n");
install.packages(
    pkgs         = "tiff",
    lib          = myLibrary,
    repos        = myRepoURL,
    type         = myType,
    dependencies = TRUE # c("Depends", "Imports", "LinkingTo", "Suggests")
    );
cat("\n##### installation complete: 'tiff' ...\n");

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
# install package 'tiff' to user-specified library
cat("\n##### installation begins: 'Cairo' ...\n");
install.packages(
    pkgs         = "Cairo",
    lib          = myLibrary,
    repos        = myRepoURL,
    type         = myType,
    dependencies = TRUE # c("Depends", "Imports", "LinkingTo", "Suggests")
    );
cat("\n##### installation complete: 'Cairo' ...\n");

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
cat("\n##### installation begins: 'BiocManager' ...\n");
if ( !("BiocManager" %in% preinstalled.packages) ) {
    install.packages(
        pkgs         = c("BiocManager"),
        lib          = myLibrary,
        repos        = myRepoURL,
        dependencies = TRUE # c("Depends", "Imports", "LinkingTo", "Suggests")
        );
    }
cat("\n##### installation complete: 'BiocManager' ...\n");

library(
    package        = "BiocManager",
    character.only = TRUE,
    lib.loc        = myLibrary
    );

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
cat("\n##### installation begins: 'Bioconductor' packages ...\n");
BiocPkgs <- c("BiocVersion","BiocStyle","graph","Rgraphviz","ComplexHeatmap");
BiocPkgs <- setdiff(BiocPkgs,preinstalled.packages);
if ( length(BiocPkgs) > 0 ) {
    BiocManager::install(
        pkgs         = BiocPkgs,
        lib          = myLibrary,
        dependencies = TRUE
        );
    }
cat("\n##### installation complete: 'Bioconductor' packages ...\n");

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
# install desired R packages to user-specified library
cat("\n##### installation begins: not-yet-installed packages in Rpackages-desired.txt ...\n");
install.packages(
    pkgs         = pkgs.desired,
    lib          = myLibrary,
    repos        = myRepoURL,
    dependencies = TRUE # c("Depends", "Imports", "LinkingTo", "Suggests")
    );
cat("\n##### installation complete: not-yet-installed packages in Rpackages-desired.txt ...\n");

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
# On macOS, install also: spDataLarge, getSpatialData
is.macOS <- grepl(x = sessionInfo()[['platform']], pattern = 'apple', ignore.case = TRUE);
if ( is.macOS ) {

    cat("\n##### installing begins: 'spDataLarge' ...\n");
    install.packages(
        pkgs  = 'spDataLarge',
        repos = 'https://nowosad.github.io/drat/',
        type  = 'source'
        );
    cat("\n##### installation complete: 'spDataLarge' ...\n");

    cat("\n##### installing begins: 'getSpatialData' ...\n");
    devtools::install_github("16EAGLE/getSpatialData");
    cat("\n##### installation complete: 'getSpatialData' ...\n");

    }

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
my.colnames <- c("Package","Version","License","License_restricts_use","NeedsCompilation","Built");
DF.installed.packages <- as.data.frame(installed.packages(lib = myLibrary)[,my.colnames]);

write.table(
    file      = "Rpackages-newlyInstalled.txt",
    x         = DF.installed.packages,
    sep       = "\t",
    quote     = FALSE,
    row.names = FALSE,
    col.names = TRUE
    );

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
pkgs.notInstalled <- setdiff(
    pkgs.desired,
    as.character(installed.packages(lib = myLibrary)[,"Package"])
    );

write.table(
    file      = "Rpackages-notInstalled.txt",
    x         = data.frame(package.notInstalled = sort(pkgs.notInstalled)),
    quote     = FALSE,
    row.names = FALSE,
    col.names = TRUE
    );

###################################################
### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
cat("\n##### warnings()\n");
print( warnings() );

cat("\n##### sessionInfo()\n");
print( sessionInfo() );

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
cat("\n##### Sys.time()\n");
print( Sys.time() );

stop.proc.time <- proc.time();
cat("\n##### start.proc.time() - stop.proc.time()\n");
stop.proc.time - start.proc.time;

sink(type = "output" );
sink(type = "message");
closeAllConnections();
