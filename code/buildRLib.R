
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
print( default.libPaths   );

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
print("\n##### installation of package 'tiff' ...");
install.packages(
    pkgs         = "tiff",
    lib          = myLibrary,
    repos        = myRepoURL,
    type         = myType,
    dependencies = TRUE # c("Depends", "Imports", "LinkingTo", "Suggests")
    );
print("\n##### installation of package 'tiff' complete ...");

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
# install package 'tiff' to user-specified library
print("\n##### installation of package 'Cairo' ...");
install.packages(
    pkgs         = "Cairo",
    lib          = myLibrary,
    repos        = myRepoURL,
    type         = myType,
    dependencies = TRUE # c("Depends", "Imports", "LinkingTo", "Suggests")
    );
print("\n##### installation of package 'Cairo' complete ...");

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
print("\n##### installation of BiocManager starts ...");
if ( !("BiocManager" %in% preinstalled.packages) ) {
    install.packages(
        pkgs         = c("BiocManager"),
        lib          = myLibrary,
        repos        = myRepoURL,
        dependencies = TRUE # c("Depends", "Imports", "LinkingTo", "Suggests")
        );
    }
print("\n##### installation of BiocManager complete ...");

library(
    package        = "BiocManager",
    character.only = TRUE,
    lib.loc        = myLibrary
    );

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
print("\n##### installation of Bioconductor packages starts ...");
BiocPkgs <- c("BiocVersion","BiocStyle","graph","Rgraphviz","ComplexHeatmap");
BiocPkgs <- setdiff(BiocPkgs,preinstalled.packages);
if ( length(BiocPkgs) > 0 ) {
    BiocManager::install(
        pkgs         = BiocPkgs,
        lib          = myLibrary,
        dependencies = TRUE
        );
    }
print("\n##### installation of Bioconductor packages complete ...");

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
# install desired R packages to user-specified library
print("\n##### installation of packages starts ...");
install.packages(
    pkgs         = pkgs.desired,
    lib          = myLibrary,
    repos        = myRepoURL,
    dependencies = TRUE # c("Depends", "Imports", "LinkingTo", "Suggests")
    );
print("\n##### installation of packages complete ...");

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
# install spDataLarge on macOS
is.macOS <- grepl(x = sessionInfo()[['platform']], pattern = 'apple', ignore.case = TRUE);
if ( is.macOS ) {
    print("\n##### installing spDataLarge ...");
    install.packages(
        pkgs  = 'spDataLarge',
        repos = 'https://nowosad.github.io/drat/',
        type  = 'source'
        );
    print("\n##### installation of spDataLarge complete ...");
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
print("\n##### warnings()")
warnings();

print("\n##### sessionInfo()")
sessionInfo();

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
print("\n##### Sys.time()");
Sys.time();

stop.proc.time <- proc.time();
print("\n##### start.proc.time() - stop.proc.time()");
stop.proc.time - start.proc.time;

sink(type = "output" );
sink(type = "message");
closeAllConnections();

