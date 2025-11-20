#ifndef USERPROG_PROCESS_H
#define USERPROG_PROCESS_H

#include "threads/thread.h"

struct fork_args {
	struct thread      *parent;    // 부모 쓰레드
	struct intr_frame   parent_if; // 부모의 intr_frame "복사본" (by value)

    struct semaphore    fork_done; // 자식 프로세스 생성이 완료됬는지 기다리기용 세마포어
    bool                success;   // fork 성공여부    
};

struct child_info * find_child_info(struct thread *parent, tid_t child_tid);

tid_t process_create_initd (const char *file_name);
tid_t process_fork (const char *name, struct intr_frame *if_);
int process_exec (void *f_name);
int process_wait (tid_t);
void process_exit (void);
void process_activate (struct thread *next);
bool load_argument (const char *file_name, struct intr_frame *if_);

#endif /* userprog/process.h */
