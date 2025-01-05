#define _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <unistd.h>
#include <zip.h>

static zip_t *z;

extern void zipfd_init(void) {
	int e = 0;
	z = zip_open("/proc/self/exe", ZIP_RDONLY, &e);
	if (z == NULL) {
		zip_error_t err;
		zip_error_init_with_code(&err, e);
		fprintf(stderr,
			"cannot open zip (you do have /proc, yes?): %s\n",
			zip_error_strerror(&err));
		zip_error_fini(&err);
		exit(1);
	}
}

/* flags get ignored, it is only there to keep the same
 * signature as the non-zip open forth word */
extern int zipfd_open(int len, char *name, int flags) {
	name[len] = '\0';

	zip_file_t *file = zip_fopen(z, name, 0);
	if (file == NULL)
		return -1;

	char buf[4096];
	int l, myfd = memfd_create(name, 0);
	while ((l = zip_fread(file, buf, sizeof buf)) != 0)
		write(myfd, buf, l);

	lseek(myfd, 0, SEEK_SET);
	zip_fclose(file);

	return myfd;
}
