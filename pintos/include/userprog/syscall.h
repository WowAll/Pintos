#ifndef USERPROG_SYSCALL_H
#define USERPROG_SYSCALL_H

extern struct lock filesys_lock;

void syscall_init (void);

static void syscall_exit (int);

#endif /* userprog/syscall.h */
