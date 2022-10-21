
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
default.libPaths <- .libPaths();
default.libPaths <- gsub(x = default.libPaths, pattern = "^/(Users|home)/.+/Library/R/.+/library", replacement = "");
default.libPaths <- gsub(x = default.libPaths, pattern = "^/(Users|home)/.+/buildRLib/.+",         replacement = "");
default.libPaths <- setdiff(default.libPaths,c(""));

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

pkgs.desired <- sort(setdiff(pkgs.desired,preinstalled.packages));
pkgs.desired <- sort(unique(c("rstan",pkgs.desired)));
cat("\n# packages to be installed:\n");
print( pkgs.desired );

write.table(
    file      = "Rpackages-desired-minus-preinstalled.txt",
    x         = data.frame(package = sort(pkgs.desired)),
    quote     = FALSE,
    row.names = FALSE,
    col.names = FALSE
    );

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
# get URL of the cloud CRAN mirror
DF.CRAN.mirrors <- getCRANmirrors();
myRepoURL <- DF.CRAN.mirrors[grepl(x = DF.CRAN.mirrors[,"Name"], pattern = "0-Cloud"),"URL"];
# myRepoURL <- "https://cloud.r-project.org";
print(paste("\n# myRepoURL",myRepoURL,sep=" = "));

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
# set timeout to 600 seconds;
# needed for downloading large package source when using download.file(),
# which in turn is used by install.packages.
options( timeout = 600 );
cat("\n# getOption('timeout')\n");
print(   getOption('timeout')   );

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
is.macOS     <- grepl(x = sessionInfo()[['platform']], pattern = 'apple', ignore.case = TRUE);
install.type <- ifelse(test = is.macOS, yes = "binary", no = getOption("pkgType"));

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
cat("\n##### installation begins: 'codetools' ...\n");
install.packages(
    pkgs         = c("codetools"),
    lib          = myLibrary,
    repos        = myRepoURL,
    dependencies = TRUE # c("Depends", "Imports", "LinkingTo", "Suggests")
    );
cat("\n##### installation complete: 'codetools' ...\n");

library(
    package        = "codetools",
    character.only = TRUE,
    lib.loc        = myLibrary
    );

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
cat("\n##### installation begins: 'boot' ...\n");
install.packages(
    pkgs         = c("boot"),
    lib          = myLibrary,
    repos        = myRepoURL,
    dependencies = TRUE # c("Depends", "Imports", "LinkingTo", "Suggests")
    );
cat("\n##### installation complete: 'boot' ...\n");

library(
    package        = "boot",
    character.only = TRUE,
    lib.loc        = myLibrary
    );

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
cat("\n##### installation begins: 'BiocManager' ...\n");
install.packages(
    pkgs         = c("BiocManager"),
    lib          = myLibrary,
    repos        = myRepoURL,
    dependencies = TRUE # c("Depends", "Imports", "LinkingTo", "Suggests")
    );
cat("\n##### installation complete: 'BiocManager' ...\n");

library(
    package        = "BiocManager",
    character.only = TRUE,
    lib.loc        = myLibrary
    );

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
cat("\n##### installation begins: 'Bioconductor' packages ...\n");
BiocPkgs <- c("BiocVersion","BiocStyle","graph","Rgraphviz","ComplexHeatmap");
already.installed.packages <- as.character(
    installed.packages(lib.loc = c(.libPaths(),myLibrary))[,"Package"]
    );
BiocPkgs <- setdiff(BiocPkgs,already.installed.packages);
if ( length(BiocPkgs) > 0 ) {
    BiocManager::install(
        pkgs         = BiocPkgs,
        lib          = myLibrary,
        dependencies = TRUE
        );
    }
cat("\n##### installation complete: 'Bioconductor' packages ...\n");

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
is.linux <- grepl(x = sessionInfo()[['platform']], pattern = 'linux', ignore.case = TRUE);
if ( is.linux ) {

    ### See instructions for installing arrow on Linux here:
    ### https://cran.r-project.org/web/packages/arrow/vignettes/install.html
    options(
        HTTPUserAgent = sprintf(
            "R/%s R (%s)",
            getRversion(),
            paste(getRversion(), R.version["platform"], R.version["arch"], R.version["os"])
            )
        );

    myRepoURL <- "https://packagemanager.rstudio.com/all/__linux__/focal/latest";
    print(paste("\n# myRepoURL (Linux)",myRepoURL,sep=" = "));

    }

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
cat("\n##### first-round installation begins: not-yet-installed packages in Rpackages-desired.txt ...\n");

# exclude packages already installed
already.installed.packages <- as.character(
    installed.packages(lib.loc = c(.libPaths(),myLibrary))[,"Package"]
    );
cat("\n# already-installed packages:\n");
print(   already.installed.packages    );

pkgs.still.to.install <- setdiff(pkgs.desired,already.installed.packages);
pkgs.still.to.install <- sort(unique(c("rstan",pkgs.still.to.install)));
cat("\n# packages to be installed:\n");
print(   pkgs.still.to.install       );

install.packages(
    pkgs         = c("KernSmooth","lattice"),
    lib          = myLibrary,
    repos        = myRepoURL,
    dependencies = TRUE # c("Depends", "Imports", "LinkingTo", "Suggests")
    );

library(
    package        = "KernSmooth",
    character.only = TRUE,
    lib.loc        = myLibrary
    );

library(
    package        = "lattice",
    character.only = TRUE,
    lib.loc        = myLibrary
    );

install.packages(
    pkgs         = pkgs.still.to.install,
    lib          = myLibrary,
    repos        = myRepoURL,
    type         = install.type,
    dependencies = TRUE # c("Depends", "Imports", "LinkingTo", "Suggests")
    );

cat("\n##### first-round installation complete: not-yet-installed packages in Rpackages-desired.txt ...\n");

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
already.installed.packages <- as.character(
    installed.packages(lib.loc = c(.libPaths(),myLibrary))[,"Package"]
    );
pkgs.still.to.install <- sort(setdiff(pkgs.desired,already.installed.packages));

if ( length(pkgs.still.to.install) > 0 ) {

    cat("\n##### second-round installation begins: not-yet-installed packages in Rpackages-desired.txt ...\n");

    cat("\n# already-installed packages:\n");
    print(   already.installed.packages    );

    cat("\n# packages to be installed:\n");
    print(   pkgs.still.to.install       );

    myRepoURL <- "https://cran.microsoft.com";
    print(paste("\n# myRepoURL",myRepoURL,sep=" = "));

    install.packages(
        pkgs         = pkgs.still.to.install,
        lib          = myLibrary,
        repos        = myRepoURL,
        type         = install.type,
        dependencies = TRUE # c("Depends", "Imports", "LinkingTo", "Suggests")
        );

    cat("\n##### second-round installation complete: not-yet-installed packages in Rpackages-desired.txt ...\n");

    }

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
already.installed.packages <- as.character(
    installed.packages(lib.loc = c(.libPaths(),myLibrary))[,"Package"]
    );
pkgs.still.to.install <- sort(setdiff(pkgs.desired,already.installed.packages));

if ( length(pkgs.still.to.install) > 0 ) {

    cat("\n##### third-round installation begins: not-yet-installed packages in Rpackages-desired.txt ...\n");

    cat("\n# already-installed packages:\n");
    print(   already.installed.packages    );

    cat("\n# packages to be installed:\n");
    print(   pkgs.still.to.install       );

    is.cloud.or.microsoft <- grep(x = DF.CRAN.mirrors[,'URL'], pattern = "(cloud|microsoft)")
    DF.CRAN.mirrors <- DF.CRAN.mirrors[setdiff(1:nrow(DF.CRAN.mirrors),is.cloud.or.microsoft),];
    DF.CRAN.mirrors <- DF.CRAN.mirrors[DF.CRAN.mirrors[,'OK'] == 1,];

    if ( nrow(DF.CRAN.mirrors) == 1 ) {
        cat("\n# Found no additional CRAN mirrors; do nothing.'\n");
        } else {

        random.row.index <- sample(x = seq(1,nrow(DF.CRAN.mirrors)), size = 1);
        myRepoURL <- DF.CRAN.mirrors[random.row.index,"URL"];
        print(paste("\n# myRepoURL",myRepoURL,sep=" = "));

        install.packages(
            pkgs         = pkgs.still.to.install,
            lib          = myLibrary,
            repos        = myRepoURL,
            type         = install.type,
            dependencies = TRUE # c("Depends", "Imports", "LinkingTo", "Suggests")
            );

        }

    cat("\n##### third-round installation complete: not-yet-installed packages in Rpackages-desired.txt ...\n");

    }

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
# On macOS, install also: spDataLarge, getSpatialData
is.macOS <- grepl(x = sessionInfo()[['platform']], pattern = 'apple', ignore.case = TRUE);
if ( is.macOS ) {

    cat("\n##### installation begins: 'spDataLarge' ...\n");
    install.packages(
        pkgs  = 'spDataLarge',
        lib   = myLibrary,
        repos = 'https://nowosad.github.io/drat/',
        type  = 'source'
        );
    cat("\n##### installation complete: 'spDataLarge' ...\n");

    .libPaths(c(myLibrary,.libPaths()));
    github.repos <- c("r-spatial/RQGIS3","16EAGLE/getSpatialData");
    for ( github.repo in github.repos ) {
        cat(paste0("\n##### installation begins: '",github.repo,"' ...\n"));
        devtools::install_github(repo = github.repo, upgrade = "always");
        cat(paste0("\n##### installation complete: '",github.repo,"' ...\n"));
        }

    }

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
# is.linux <- grepl(x = sessionInfo()[['platform']], pattern = 'linux', ignore.case = TRUE);
# if ( is.linux ) {
#
#     cat("\n##### special installation on Linux begins ...\n");
#
#     pkgs.special.install   <- c("arrow","fdacluster","fdANOVA","RGISTools","sta","terrainr","tsutils");
#     DF.installed.pkgs      <- installed.packages();
#     pkgs.already.installed <- as.character(DF.installed.pkgs[,"Package"]);
#     pkgs.to.install        <- setdiff(pkgs.special.install,pkgs.already.installed);
#
#     if ( length(pkgs.to.install) == 0 ) {
#
#         cat("\n##### all special-install packages have already been installed ...\n");
#
#     } else {
#
#         cat("\n### installation (on Linux) begins: 'arrow', 'terrainr' ...\n");
#         ### See instructions for installing arrow on Linux here:
#         ### https://cran.r-project.org/web/packages/arrow/vignettes/install.html
#         options(
#             HTTPUserAgent = sprintf(
#                 "R/%s R (%s)",
#                 getRversion(),
#                 paste(getRversion(), R.version["platform"], R.version["arch"], R.version["os"])
#                 )
#             );
#         install.packages(
#             pkgs  = pkgs.to.install,
#             lib   = myLibrary,
#             repos = "https://packagemanager.rstudio.com/all/__linux__/focal/latest"
#             );
#         cat("\n### installation (on Linux) begins: 'arrow', 'terrainr' ...\n");
#
#         }
#
#     cat("\n##### special installation on Linux complete ...\n");
#
#     }

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
