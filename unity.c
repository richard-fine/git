/*
 * Routines specific to the Unity codebase
*/

#define USE_THE_REPOSITORY_VARIABLE

#include "git-compat-util.h"
#include "repository.h"
#include "attr.h"
#include "object-store-ll.h"

static struct attr_check *unitymetafile_attr;
int unity_is_metafile(struct repository *r, const char *path)
{
	if (!unitymetafile_attr) {
		unitymetafile_attr = attr_check_initl("unitymetafile", NULL);
	}

	git_check_attr(r->index, path, unitymetafile_attr);

	return ATTR_TRUE(unitymetafile_attr->items[0].value);
}

static const char guid_prefix[] = "guid: ";
static const int prefix_length = sizeof(guid_prefix) - 1;

int unity_read_metafile_guid(struct repository *r, 
                             struct object_id* oid, 
                             char result[32])
{
    unsigned long sz;
	enum object_type type;
	void *buf;

    buf = repo_read_object_file(r, oid, &type, &sz);
	if (!buf || type != OBJ_BLOB) {
		free(buf);
		return 0;
	}

    const char *guid = memmem(buf, sz, guid_prefix, prefix_length);
    if (!guid) {
        return 0;
    }

    guid += prefix_length;
    if (guid + 32 > (char *)buf + sz) {
        return 0;
    }

    memcpy(result, guid, 32);
    return 1;
}
