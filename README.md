# A Yorick interface to the Git library

This repository provides a [Yorick](http://github.com/LLNL/yorick) plug-in to
operate on Git repositories via the [Git library](https://libgit2.org).

Currently the plug-in provides very limited capabilities. You can:

- Open a Git repository with `git_repository_open`.

- Retrieve a Git blob object given its SHA-1 hash with `git_blob_lookup` and,
  then extract its raw content.


## Usage

If the plug-in has been properly installed, it is sufficient to use any
function of the plug-in to automatically load it. You may force the loading of
the plug-in by something like:

``` c
#include "git.i"
```

or

``` c
require, "git.i";
```

in your code.

To open a Git repository, do:

``` c
repo = git_repository_open(dir);
```

with `dir` the repository directory. The syntax `repo.dir` yields the name of
the repository directory. The resources associated with the repository object
are automatically released when the object is no longer in use.

A repository object can be used to lookup a blob:

``` c
blob = git_blob_lookup(repos, id);
```

with `id` the SHA-1 identifier of the object as a string or as an array of
bytes. The returned object has the following fields:

``` c
blob.content // the blob raw content as an array of bytes
blob.hash    // the SHA-1 hash of the blob data
blob.oid     // the Object Identifier Data of the blob data
blob.size    // the number of bytes of the blob raw content
```

A third optional argument can be provided to `git_blob_lookup`, this argument
is returned if the blob is not found instead or throwing an error:

``` c
blob = git_blob_lookup(repos, id, def);
```


## Installation

In short, building and installing the plug-in can be as quick as:

``` sh
cd $BUILD_DIR
$SRC_DIR/configure
make
make install
```

where `$BUILD_DIR` is the build directory (at your convenience) and `$SRC_DIR`
is the source directory of the plug-in code. The build and source directories
can be the same in which case, call `./configure` to configure for building.

More detailed installation explanations are given below.

1. You must have Yorick and GIT installed on your machine. You may consider
   using [EasyYorick](https://github.com/emmt/EasyYorick) for installing
   Yorick.

2. Unpack the software code somewhere or clone the Git repository.

3. Configure for compilation.  There are two possibilities:

   For an **in-place build**, go to the source directory, say `$SRC_DIR`, of
   the plug-in code and run the configuration script:

   ``` sh
   cd $SRC_DIR
   ./configure
   ```

   To see the configuration options, call:

   ``` sh
   ./configure --help
   ```

   To compile in a **different build directory**, say `$BUILD_DIR`, create the
   build directory, go to the build directory and run the configuration script:

   ``` sh
   mkdir -p $BUILD_DIR
   cd $BUILD_DIR
   $SRC_DIR/configure
   ```

   where `$SRC_DIR` is the path to the source directory of the plug-in code.
   To see the configuration options, call:

   ``` sh
   $SRC_DIR/configure --help
   ```

4. Compile the code:

   ``` sh
   make
   ```

4. Install the plug-in in Yorick directories:

   ``` sh
   make install
   ```
