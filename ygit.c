/*
 * ygit.c -
 *
 * Implement Yorick interface to Git library.
 *
 * See https://libgit2.org/docs/guides/101-samples/ for examples of use of the
 * library.
 *
 *-----------------------------------------------------------------------------
 *
 * This file is part of YGit software (https://github.com/emmt/YGit) licensed
 * under the MIT license.
 *
 * Copyright (c) 2024, Éric Thiébaut.
 */

#include <errno.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <yapi.h>
#include <pstdlib.h>
#include <git2.h>

// Debug or not debug, that's the question...
#ifdef YGIT_DEBUG
#  define DEBUG(...) do { fprintf(stderr, "DEBUG: " __VA_ARGS__); fflush(stderr); } while(0)
#else
#  define  DEBUG(...)
#endif

static char mesg[256]; // large enough for messages and SHA-1 (40 characters)

static char* format_message(const char* format, ...)
{
    va_list args;
    va_start(args, format);
    vsnprintf(mesg, sizeof(mesg), format, args);
    va_end(args);
    mesg[sizeof(mesg) - 1] = 0;
    return mesg;
}

static void report_git_error(int error)
{
    if (error < 0) {
        const git_error* e = git_error_last();
        //fprintf(stderr, "Error %d/%d: %s\n", error, e->klass, e->message);
        y_error(e->message);
    }
}

static void push_string(const char* str)
{
    char** arr = ypush_q(NULL);
    arr[0] = str == NULL ? NULL : p_strcpy(str);
}

/*---------------------------------------------------------------------------*/
/* GIT REPOSITORY */

typedef struct ygit_repository_ {
    git_repository* repo;
    const char* dir;
} ygit_repository;

static void ygit_repository_free(void* addr)
{
    ygit_repository* obj = addr;
    if (obj->repo != NULL) {
        git_repository_free(obj->repo);
    }
    if (obj->dir != NULL) {
        p_free((void*)obj->dir);
    }
}

static void ygit_repository_print(void* addr)
{
    ygit_repository* obj = addr;
    y_print("Git repository (dir = \"", 0);
    y_print(obj->dir, 0);
    y_print("\")", 1);
}


static void ygit_repository_eval(void* addr, int argc)
{
    y_error("Git blob is not callable");
}

static void ygit_repository_extract(void* addr, char* name)
{
    ygit_repository* obj = addr;
    int c = name[0];
    switch (c) {
    case 'd':
        if (strcmp("dir", name) == 0) {
            push_string(obj->dir);
            return;
        }
        break;
    }
    y_error("invalid member of Git repository");
}

static y_userobj_t ygit_repository_type = {
    "git_repository",
    ygit_repository_free,
    ygit_repository_print,
    ygit_repository_eval,
    ygit_repository_extract,
    NULL
};

/*---------------------------------------------------------------------------*/
/* GIT BLOB */

typedef struct ygit_blob_ {
    git_blob* blob;
    git_oid oid;
} ygit_blob;

static void ygit_blob_free(void* addr)
{
    ygit_blob* obj = addr;
    if (obj->blob != NULL) {
        git_blob_free(obj->blob);
    }
}

static void ygit_blob_print(void* addr)
{
    ygit_blob* obj = addr;
    y_print("Git blob (size = ", 0);
    snprintf(mesg, sizeof(mesg), "%ld", (long)git_blob_rawsize(obj->blob));
    mesg[sizeof(mesg) - 1] = 0;
    y_print(mesg, 0);
    y_print(" byte(s), hash = ", 0);
    git_oid_tostr(mesg, sizeof(mesg) - 1, &obj->oid);
    mesg[sizeof(mesg) - 1] = 0;
    y_print(mesg, 0);
    y_print(")", 1);
}

static void ygit_blob_eval(void* addr, int argc)
{
    y_error("Git blob is not callable");
}

static void ygit_blob_extract(void* addr, char* name)
{
    ygit_blob* obj = addr;
    int c = name[0];
    switch (c) {
    case 'c':
        if (strcmp("content", name) == 0) {
            size_t size = git_blob_rawsize(obj->blob);
            void* dest = ypush_c((long[]){1, size});
            const void* src = git_blob_rawcontent(obj->blob);
            memcpy(dest, src, size);
            return;
        }
        break;
    case 'h':
        if (strcmp("hash", name) == 0) {
            char** arr = ypush_q(NULL);
            const size_t size = 41;
            arr[0] = p_malloc(size);
            git_oid_tostr(arr[0], size - 1, &obj->oid);
            return;
        }
        break;
    case 'o':
        if (strcmp("oid", name) == 0) {
            size_t size = sizeof(git_oid);
            void* oid = ypush_c((long[]){1, size});
            memcpy(oid, &obj->oid, size);
            return;
        }
        break;
    case 's':
        if (strcmp("size", name) == 0) {
            ypush_long(git_blob_rawsize(obj->blob));
            return;
        }
        break;
    }
    y_error("invalid member of Git blob");
}

static y_userobj_t ygit_blob_type = {
    "git_blob",
    ygit_blob_free,
    ygit_blob_print,
    ygit_blob_eval,
    ygit_blob_extract,
    NULL
};

/*---------------------------------------------------------------------------*/
/* BUILTIN FUNCTIONS */

void Y__git_init(int argc)
{
    static int initlevel = 0;
    if (initlevel == 0) {
        git_libgit2_init();
        initlevel += 1;
    }
}

void Y_git_repository_open(int argc)
{
    if (argc != 1) y_error("expecting exactly one argument");
    const char* dir = ygets_q(0);
    if (dir == NULL || dir[0] == 0) {
        y_error("invalid Git repository name");
    }
    ygit_repository* obj = ypush_obj(&ygit_repository_type, sizeof(ygit_repository));
    obj->repo = NULL;
    obj->dir = p_native(dir);
    int error = git_repository_open(&obj->repo, obj->dir);
    if (error < 0) {
        report_git_error(error);
    }
}

void Y_git_blob_lookup(int argc)
{
    if (argc < 2 || argc > 3) y_error("expecting exactly 2 or 3 arguments");
    int iarg, error = 0;
    bool throw_errors = argc != 3; // throw errors if no default provided

    // Extract 1st argument: the Git repository object.
    iarg = argc - 1;
    ygit_repository* r = yget_obj(iarg, &ygit_repository_type);

    // Extract 2nd argument: the SHA-1 hash string or the Object Identifier Data (OID).
    iarg = argc - 2;
    git_oid oid;
    int type = yarg_typeid(iarg);
    int rank = yarg_rank(iarg);
    if (type == Y_STRING && rank == 0) {
        const char* hash = ygets_q(iarg);
        if (hash == NULL || strlen(hash) != 40) {
            if (throw_errors) {
                y_error("Git SHA-1 string must have 40 characters");
            }
            return;
        }
        error = git_oid_fromstr(&oid, hash);
        if (error < 0) {
            if (throw_errors) {
                report_git_error(error);
            }
            return;
        }
    } else if (type == Y_CHAR && rank == 1) {
        long nbytes;
        const void* bytes = ygeta_c(iarg, &nbytes, NULL);
        if (nbytes != sizeof(oid)) {
            if (throw_errors) {
                y_error(format_message("Git SHA-1 binary identifier must have %ld bytes",
                                       (long)sizeof(oid)));
            }
            return;
        }
        memcpy(&oid, bytes, sizeof(oid));
    } else {
        if (throw_errors) {
            y_error("Git blob identifier must be a SHA-1 hash string or OID data");
        }
        return;
    }

    // Lookup blob object.
    ygit_blob* b = ypush_obj(&ygit_blob_type, sizeof(ygit_blob));
    b->blob = NULL;
    memcpy(&b->oid, &oid, sizeof(b->oid));
    error = git_blob_lookup(&b->blob, r->repo, &oid);
    if (error < 0) {
        yarg_drop(1); // drop newly created object
        if (throw_errors) {
            report_git_error(error);
        }
        return;
    }
}
