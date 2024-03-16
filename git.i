/*
 * git.i -
 *
 * Yorick interface to Git library.
 *
 *-----------------------------------------------------------------------------
 *
 * This file is part of YGit software (https://github.com/emmt/YGit) licensed
 * under the MIT license.
 *
 * Copyright (c) 2024, Éric Thiébaut.
 */

if (is_func(plug_in)) plug_in, "ygit";

/* Private function to initialize the Git library. */
extern _git_init;
_git_init;

extern git_repository_open;
/* DOCUMENT repo = git_repository_open(path);

     Open Git repository at `path`. The repository is automatically closed when
     the returned object is no longer in use.

   SEE ALSO: `git_blob_lookup`.
 */

extern git_blob_lookup;
/* DOCUMENT blob = git_blob_lookup(repos, id);
         or blob = git_blob_lookup(repos, id, def);

     Lookup the blob object identified by `id` in repository `repo`. The
     argument `id` is the SHA-1 identifier of the object (as a string or as an
     array of bytes) which can be computed by:

         sha1("blob " + size + "\0" + contents)

     Optional argument `def` is returned if the blob is not found. If `def` is
     not specified, an error is raised if the blob is not found.

     In case of success, the returned object has the following fields:

         blob.content // the blob raw content as an array of bytes
         blob.hash    // the SHA-1 hash of the blob data
         blob.oid     // the Object Identifier Data of the blob data
         blob.size    // the number of bytes of the blob raw content

     The blob resources are automatically released when the returned object is
     no longer in use.

   SEE ALSO: `git_repository_open`.
 */

func git_blob_hash(data, T)
/* DOCUMENT bin_oid = git_blob_hash(data);
        or  bin_oid = git_blob_hash(data, char);
        or  str_oid = git_blob_hash(data, string);

     Compute the SHA-1 identifier of the Git blob whose content is `data`, a
     numerical array or a scalar string. Above, `bin_oid` is the binary
     representation of the identifier (a vector of bytes) while `str_oid` is
     the textual representation of the identifier.

   SEE ALSO: `git_blob_lookup`.
 */
{
    // Check argument.
    type = structof(data);
    if (is_void(type) && !is_void(data)) {
        error, "expecting array content";
    } else if (type == string) {
        if (!is_scalar(data)) {
            error, "non-scalar string content not supported";
        }
    } else if (type == pointer) {
        error, "array of pointers content not supported";
    }

    // Compute SHA-1 digest of "blob " + sizeof(data) + "\0" + data. Note that
    // the null separator is simply the final byte of the result of `strchar`.
    state = [];
    sha1, state, strchar(swrite(format="blob %d", sizeof(data)));
    bin_oid = sha1(state, data);
    if (is_void(T) || T == char) {
        return bin_oid;
    } else if (T == string) {
        return git_oid_tostr(bin_oid);
    } else {
        error, "optional argument T must be `char` or `string`";
    }
}

extern git_oid_tostr;
extern git_oid_fromstr;
/* DOCUMENT oid_str = git_oid_tostr(oid_bin);
         or oid_bin = git_oid_fromstr(oid_str);

     These functions convert between the binary, `oid_bin`, and textual,
     `oid_str`, forms of the SHA-1 identifier of a Git object.

   SEE ALSO: `git_blob_hash`, `git_blob_lookup`.
 */

local git_file_load, git_file_save;
/* DOCUMENT arr = git_file_load(filename);
         or arr = git_file_load(filename, char);
         or str = git_file_load(filename, string);
         or git_file_save, filename, data, overwrite=0n;

     The function `git_file_load` reads the content of file `filename` as an
     array of bytes `arr` or as a single string `str`.

     Conversely, the subroutine `git_file_save` writes the `data` content (a
     numerical array or a scalar string) into file `filename`. Keyword
     `overwrite` (false by default) specifies whether an existing file may be
     overwritten.

   SEE ALSO: `git_blob_hash`, `git_blob_lookup`.
 */

func git_file_load(filename, T)
{
    file = open(filename, "rb");
    size = sizeof(file);
    data = array(char, size);
    byte = char();
    if (_read(file, 0, data) != size || _read(file, size, byte) != 0) {
        error, "size of file changed while reading";
    }
    if (is_void(T) || T == char) {
        return data;
    } else if (T == string) {
        return strchar(data);
    } else {
        error, "optional argument T must be `char` or `string`";
    }
}

func git_file_save(filename, data, overwrite=)
{
    // Check data content and convert it to bytes if it is a string.
    type = structof(data);
    if (is_void(type) && !is_void(data)) {
        error, "expecting array content";
    } else if (type == string) {
        if (!is_scalar(data)) {
            error, "non-scalar string content not supported";
        }
        data = strlen(data) > 0 ? strchar(data)(1:-1) : [];
    } else if (type == pointer) {
        error, "array of pointers content not supported";
    }

    // Write content.
    if (!overwrite && open(filename, "r", 1)) {
        error, "file already exists";
    }
    file = open(filename, "wb");
    if (!is_void(data)) {
        _write, file, 0, data;
    }
}
