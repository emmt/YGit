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

func git_blob_hash(data)
/* DOCUMENT id = git_blob_hash(data);

     Compute the SHA-1 identifier of the Git blob whose content is `data`, a
     numerical array or a scalar string.

   SEE ALSO: `git_blob_lookup`.
 */
{
    // Check argument.
    T = structof(data);
    if (is_void(T)) {
        error, "expecting array content";
    } else if (T == string) {
        if (!is_scalar(data)) {
            error, "non-scalar string content not supported";
        }
    } else if (T == pointer) {
        error, "array of pointers content not supported";
    }

    // Compute SHA-1 digest of "blob " + sizeof(data) + "\0" + data.
    state = [];
    sha1, state, strchar(swrite(format="blob %d", sizeof(data)));
    return sha1(state, data);
}

func git_file_load(filename, T)
/* DOCUMENT arr = git_file_load(filename);
         or arr = git_file_load(filename, char);
         or str = git_file_load(filename, string);

     Read the content of file `filename` as an array of bytes `arr` or, in the
     latter example, as a single string `str`.

   SEE ALSO: `git_blob_hash`.
 */
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
