/*
 * Routines specific to the Unity codebase
*/

#define USE_THE_REPOSITORY_VARIABLE

#include "git-compat-util.h"
#include "attr.h"

static struct attr_check *unitymetafile_attr;
int unity_is_metafile(struct repository *r, const char *path)
{
	if (!unitymetafile_attr) {
		unitymetafile_attr = attr_check_initl("unitymetafile", NULL);
	}

	git_check_attr(r->index, path, unitymetafile_attr);

	return ATTR_TRUE(unitymetafile_attr->items[0].value);
}