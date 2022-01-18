# submariner-workflow
Set of scripts used to work with multiple Submariner Repositories

## Overview

[Submariner](https://github.com/submariner-io) is implemented as a set of repositories.
I have been having trouble coordinating and building between the different intertwined
repositories.
So to that end, I wrote a handful of scripts to help me manage.
Also, my work-flow is probably a little different (development on a headless server and
testing in a VM on that server), so additional script are used to keep changes in sync.

## Multiple Repository Management (local)

The following scripts are used to manage the multiple repositories on the server
(Development Server) I am coding on.

Workflow:
* Clone this repository on the Development Server:
  ```bash
  mkdir -p /home/${USER}/src/; cd /home/${USER}/src/
  git clone https://github.com/Billy99/submariner-workflow.git
  ```

* Run script to clone the Submariner repositories on the Development Server and copy scripts:
  ```bash
  cd  /home/${USER}/src/submariner-workflow/
  ./setup_sub.sh local
  ```

* Code away ...

* Every so often, update all the repositories with latest upstream:
  ```bash
  cd  /home/${USER}/src/submariner-io/
  ./update_sub.sh
  ```

See below for details about each script.

### setup_sub.sh

The `setup_sub.sh` script performs three actions:

* Creates the base directory to clone the repositories in. The default location can
  be overwritten by updating the variable in the `variables.sh` file or overwritten
  as an export variables (defaults shown below):
  ```bash
  export SUBMARINER_BASE_DIRECTORY="/home/${USER}/src/submariner-io"
  ```

* Copy the scripts from this repo to the base directory.
  Only the needed scripts are copied based on mode to reduce confusion.
  * `.\setup_sub.sh` or `.\setup_sub.sh local`: Assumes this is where the coding is occurring
    (Development Server). Copies the scripts: `gen_diff_sub.sh`, `update_sub.sh` and `variables.sh`
  * `.\setup_sub.sh remote`: Assumes this is where the testing is occurring (Remote Server) and
    different from server coding on.
    Copies the scripts: `copy_sub.sh` and `variables.sh`

* `git clones` the set of repositories defined in the top of the script.
  If a subdirectory for the repository already exists (even if empty), it is ignored.
  The local repositories are not updated by this script if the directory already exists. 
  Edit the script to change the list of repositories that are being managed.
  Below is the default set of repositories cloned:
  ```bash
  SUBMARINER_REPOS=(
    admiral
    coastguard
    lighthouse
    shipyard
    submariner
    submariner-operator
    submariner-website
  )
  ```

### update_sub.sh

The `update_sub.sh` script loops through the set of existing cloned repositories and
pulls the latest from upstream using `git fetch` and `git rebase`.
The script will detect whether to pull from `origin\devel`, `upstream\devel`, or other.
If the cloned repositories has any changes, then that cloned repository is skipped
and manual update required.
Handling merge conflicts was not worth the effort.

### variables.sh

The `variables.sh` script is just a set of variables used by multiple of the scripts,
so placed in one file so there are not conflicting definitions.


## Remote Testing (remote)

My setup maybe a little different.
I code on my development server in the lab which is still CentOS.
To test Submariner, needed Fedora 34 or higher, so I created a Fedora VM.
But I already had my editor of choice and git setup the way I like it on the
Development Server.
So I code on the Development Server, then copy the changes to the VM (Remote Server).
Where this may be applicable to others, I have a headless development server.
Changes to the Submariner-Website repository can be tested locally, but need to
connect to [http://localhost:1313](http://localhost:1313).
I found it easy to rerun `./setup_sub.sh remote` on my laptop and test change from there,
while still coding from my Development Server.

Workflow (assumes `./setup_sub.sh local` already run on Development Server and coding performed there):
* Remote Server: Clone this repository on the Remote Server (VM, laptop, etc):
  ```bash
  mkdir -p /home/${USER}/src/; cd /home/${USER}/src/
  git clone https://github.com/Billy99/submariner-workflow.git
  ```

* Remote Server: Run script to clone the Submariner repositories on the Remote Server and copy scripts:
  ```bash
  cd  /home/${USER}/src/submariner-workflow/
  ./setup_sub.sh remote
  ```

* Development Server: Code away on the Development Server ...

* Development Server: When ready to test, generate diff files:
  ```bash
  cd  /home/${USER}/src/submariner-io/
  ./gen_diff_sub.sh   
  ```

* Remote Server: Copy diff files from Development Server (assumes RSA Key has been copied so `scp` can be run without password prompt):
  ```bash
  cd  /home/${USER}/src/submariner-io/
  ./copy_sub.sh
  ```

* Remote Server: Whenever all the repositories on the Development Server are updated with latest upstream, do the same on the Remote Server (adding `update` when calling `copy_sub.sh`):
  ```bash
  cd  /home/${USER}/src/submariner-io/
  ./copy_sub.sh update
  ```

See below for details about each script.

### gen_diff_sub.sh

The `gen_diff_sub.sh` script is intended to be run on the Development Server.
It loops through all the cloned repositories and generates a diff file for each cloned repository.
The diff is against HEAD, so if code is already committed, it will still be added to the diff file.

### copy_sub.sh

The `copy_sub.sh` script is intended to be run on the Remote Server.
It loops through all the cloned repositories and runs the following actions:

* Cleans up the cloned repository on the Remote Server by deleting any lingering
  diff files from previous runs and removes and existing changes by running `git checkout .`.

* If `update` is passed in as a parameter, then updates the cloned repositories on
  Remote Server by pulling the latest from upstream using `git fetch` and `git rebase`.
  Unlike `update_sub.sh`, because `copy_sub.sh` is cleaning up previous changes in the
  previous step, every cloned repository is updated.
  No manual updating is needed on Remote Server.
  ```bash
  cd  /home/${USER}/src/submariner-io/
  ./copy_sub.sh update
  ```

* Runs `scp` to copy the generated diff file from the Development Server.
  Caveats:
  * Assumes the same directory structure on both the Development Server and Remote Server.
  * Assumes RSA Key has been copied from the Remote Server to the Development Server so
    `scp` can run without being prompted for password.
  * `scp` is controlled by the following environment variables that can be updated in the
    `variables.sh` file or overwritten as export variables (defaults shown below):
    ```bash
    export SUBMARINER_USER=$USER
    export SUBMARINER_SERVER_IP="10.8.125.32"
    export SUBMARINER_BASE_DIRECTORY="/home/${SUBMARINER_USER}/src/submariner-io"
    ```

* If a diff file is copied, applies the diff file to the cloned repository on the Remote Server.

## Docker Login Patch - Rate Limit Workaround

Submariner pulls a couple of images from Docker.
If on a corporate network where there are multiple "anonymous" Docker pull requests,
the Docker Rate Limit can be hit:
```
docker: Error response from daemon: toomanyrequests: You have reached your pull rate limit.
  You may increase the limit by authenticating and upgrading: https://www.docker.com/increase-rate-limit.
```

Several fixes have been added, like copying Weave images to local registry so they aren't
pulled every `make deploy` (`make deploy` can be replaced with `make cluster` in this description).
But there are still instance where it may get hit.
Logging into Docker on host machine doesn't work because `make deploy` runs in a Dapper shell
and loses the login.

The following patch exposes Docker login credential through environment variables to the Dapper shell.
It is not recommended to have your Docker login credential exposed via environment variables,
which is why this patch is not pushed upstream.
But when you are blocked, this is a ugly hack that unblocks you.
Once the variables are used in the Dapper shell, they are `unset`.
However, they are still exposed on the host `make deploy` was run on.

**NOTE:** This logs into Docker in the Dapper shell so Docker pulls from within Dapper shell
will not be from "anonymous".
If Docker pull is from within the KIND cluster, this will not help.
To work around the pull rate errors within KIND cluster, you need to pre-download the image
from within the Dapper shell and copy to local registry.
See `deploy_weave_cni()` or `deploy_kind_ovn()` in
[`cluster.sh`](https://github.com/submariner-io/shipyard/blob/devel/scripts/shared/clusters.sh).

Steps to apply patch:

* Expose Docker login credential via environment variables (export or setup in \~/.bashrc):
  ```bash
  DOCKER_USER=Username
  DOCKER_PASSWD=password
  ```

* Apply patch to `shipyard` repository and build image:
  ```bash
  cp /home/${SUBMARINER_USER}/src/submariner-workflow/docker_login.diff /home/${SUBMARINER_USER}/src/submariner-io/shipyard/.

  cd /home/${SUBMARINER_USER}/src/submariner-io/shipyard/
  git apply docker_login.diff
  make images
  ```

* The patch updates `Dockerfile.dapper`. If running `make deploy` out of another repository
  like `submariner-operator`, update `Dockerfile.dapper` in that repository.
  ```bash
  cd /home/${SUBMARINER_USER}/src/submariner-io/submariner-operator/
  cp ../shipyard/Dockerfile.dapper .
  make deploy using=lighthouse
  ```
