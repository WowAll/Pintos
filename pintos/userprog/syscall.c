#include "userprog/syscall.h"
#include <stdio.h>
#include <syscall-nr.h>
#include "threads/interrupt.h"
#include "threads/thread.h"
#include "threads/loader.h"
#include "threads/synch.h"
#include "userprog/gdt.h"
#include "threads/flags.h"
#include "intrinsic.h"

void syscall_entry (void);
void syscall_handler (struct intr_frame *);

struct lock filesys_lock;

/* 시스템 호출.
 *
 * 이전에는 시스템 호출 서비스가 인터럽트 핸들러에 의해 처리되었습니다
 * (예: 리눅스의 int 0x80). 그러나 x86-64에서는 제조업체가
 * 시스템 호출을 요청하는 효율적인 경로인 `syscall` 명령을 제공합니다.
 *
 * syscall 명령은 모델 특정 레지스터(MSR)에서 값을 읽어 작동합니다.
 * 자세한 내용은 매뉴얼을 참조하세요. */

#define MSR_STAR 0xc0000081         /* 세그먼트 선택자 msr */
#define MSR_LSTAR 0xc0000082        /* 롱 모드 SYSCALL 대상 */
#define MSR_SYSCALL_MASK 0xc0000084 /* eflags용 마스크 */

static int syscall_write(int fd, const void *buffer, unsigned length) {
	//validate_user_ptr(buffer);

	if (fd == STDOUT_FILENO) {
		putbuf(buffer, length);
		return length;
	}

	return -1;
}

static void
syscall_exit (int status) {
	struct thread *curr = thread_current();
    curr->exit_status = status;
	printf ("%s: exit(%d)\n", curr->name, status);

    thread_exit();
}

static void
validate_user_string (const void *uaddr) {
	if (uaddr == NULL)
	syscall_exit(-1);

	// 최소 버전: 첫 바이트만 검증
	if (!is_user_vaddr(uaddr) || pml4_get_page(thread_current()->pml4, uaddr) == NULL)
		syscall_exit(-1);
}

static bool syscall_create (const char *file, unsigned initial_size) {
	validate_user_string(file);

	if (file[0] == '\0')
		syscall_exit(-1);

	bool success;
	lock_acquire(&filesys_lock);
	success = filesys_create(file, initial_size);
	lock_release(&filesys_lock);

	return success;
}

void
syscall_init (void) {
	lock_init(&filesys_lock);
	write_msr(MSR_STAR, ((uint64_t)SEL_UCSEG - 0x10) << 48  |
			((uint64_t)SEL_KCSEG) << 32);
	write_msr(MSR_LSTAR, (uint64_t) syscall_entry);

	/* 인터럽트 서비스 루틴은 syscall_entry가 사용자 스택을 커널
	 * 모드 스택으로 교환할 때까지 어떤 인터럽트도 처리하지 않아야 합니다.
	 * 따라서 FLAG_FL을 마스크했습니다. */
	write_msr(MSR_SYSCALL_MASK,
			FLAG_IF | FLAG_TF | FLAG_DF | FLAG_IOPL | FLAG_AC | FLAG_NT);
}

/* 주요 시스템 호출 인터페이스 */
void
syscall_handler (struct intr_frame *f) {
	// TODO: 여기에 구현을 작성하세요.
	switch (f->R.rax) {
		case SYS_HALT:
			power_off();
			break;
		case SYS_EXIT:
			syscall_exit((int)f->R.rdi);
			break;
		case SYS_CREATE:
			f->R.rax = syscall_create((const char *)f->R.rdi, (unsigned)f->R.rsi);
			break;
		case SYS_FORK:
			f->R.rax = process_fork(f->R.rdi, f->R.rsi);
			break;
		case SYS_EXEC:
			f->R.rax = process_exec(f->R.rdi);
			break;
		case SYS_WAIT:
			f->R.rax = process_wait(f->R.rdi);
			break;
		case SYS_READ:
			//syscall_read(f->R.rdi, (void *)f->R.rsi, f->R.rdx);
			break;
		case SYS_WRITE:
			f->R.rax = syscall_write(f->R.rdi, (void *)f->R.rsi, f->R.rdx);
			break;
		default:
			break;
	}
}

/*
void
validate_user_ptr(const void *user_addr) {
	struct thread *curr = thread_current();

	if (user_addr == NULL)
		exit(-1);

	if (!is_user_vaddr(user_addr))
		exit(-1);

	if (pml4_get_page(curr->pml4, user_addr) == NULL)
		exit(-1);

}
		*/

/*
int syscall_read(int fd, void *buffer, unsigned length) {
	validate_user_ptr(buffer);

	if (fd == STDIN_FILENO) {
	}
	return -1;
}
	*/