/*
 * Routines specific to the Unity codebase
*/

int unity_is_metafile(struct repository *r, const char *path);
int unity_read_metafile_guid(struct repository *r, struct object_id* oid, char result[32]);
