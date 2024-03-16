require, "git.i";
require, "testing.i";

func same_data(a, b)
{
    return structof(a) == structof(b) && numberof(a) == numberof(b) && allof(a(*) == b(*));
}

test_init, 1n;

dirname = string();
while (! read(prompt="Name of YGit repository: ", dirname)) ;
repo = git_repository_open(dirname);
filename = dirname + "/" + "git.i";

bin_data = git_file_load(filename);
test_assert, "structof(bin_data) == char";
test_assert, "is_vector(bin_data)";
test_assert, "same_data(bin_data, git_file_load(filename, char))";
str_data = git_file_load(filename, string);
test_assert, "structof(str_data) == string";
test_assert, "is_scalar(str_data)";
test_assert, "strlen(str_data) == sizeof(bin_data)";
test_assert, "same_data(bin_data, strchar(str_data)(1:-1))";

bin_oid = git_blob_hash(bin_data);
test_assert, "same_data(bin_oid, git_blob_hash(str_data))";
str_oid = git_oid_tostr(bin_oid)
test_assert, "same_data(bin_oid, git_oid_fromstr(str_oid))";
blob = git_blob_lookup(repo, bin_oid);
test_assert, "blob.size == sizeof(bin_data)";
test_assert, "same_data(blob.oid, bin_oid)";
test_assert, "same_data(blob.content, bin_data)";
test_assert, "blob.hash == str_oid";
blob = git_blob_lookup(repo, str_oid);
test_assert, "blob.size == sizeof(bin_data)";
test_assert, "same_data(blob.oid, bin_oid)";
test_assert, "same_data(blob.content, bin_data)";
test_assert, "blob.hash == str_oid";

// Summary.
test_summary;
