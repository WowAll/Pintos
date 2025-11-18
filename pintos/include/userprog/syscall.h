#ifndef USERPROG_SYSCALL_H
#define USERPROG_SYSCALL_H

void syscall_init (void);

void validate_user_ptr(const void *user_addr);

#endif /* userprog/syscall.h */
