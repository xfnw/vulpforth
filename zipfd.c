#define _GNU_SOURCE

#include "zip/src/zip.h"
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <sys/syscall.h>
#include <unistd.h>

static struct zip_t *z;

extern void zipfd_init(void) {
	z = zip_open("/proc/self/exe", 0, 'r');
	if (z == NULL) {
		fprintf(stderr, "cannot open zip (you do have /proc, yes?)\n");
		exit(1);
	}
}

extern int zipfd_open(int len, char *name, int flags) {
	name[len] = '\0';

	if (flags != 0)
		return syscall(SYS_open, name, flags, 420);
	if (zip_entry_open(z, name) != 0)
		return -1;

	void *buf;
	size_t size;
	int myfd = memfd_create(name, 0);
	zip_entry_read(z, &buf, &size);
	write(myfd, buf, size);

	lseek(myfd, 0, SEEK_SET);
	zip_entry_close(z);

	return myfd;
}
