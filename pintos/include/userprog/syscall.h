#ifndef USERPROG_SYSCALL_H
#define USERPROG_SYSCALL_H

void syscall_init (void);

static void syscall_exit (int);

static void validate_user_addr(const void *);

#endif /* userprog/syscall.h */
