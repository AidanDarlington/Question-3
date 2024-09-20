#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "date.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
  int n;
  if(argint(0, &n) < 0)
    return -1;
  exit(n);
  return 0;  // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return fork();
}

uint64
sys_wait(void)
{
  uint64 p;
  if(argaddr(0, &p) < 0)
    return -1;
  return wait(p);
}

uint64
sys_sbrk(void)
{
  int addr;
  int n;

  if(argint(0, &n) < 0)
    return -1;
  addr = myproc()->sz;
  if(growproc(n) < 0)
    return -1;
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  if(argint(0, &pid) < 0)
    return -1;
  return kill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}

// Aidan Darlington
// StudentID: 21134427
// Creating pageAccess function
int
sys_pageAccess(void)
{
    // Get the three function arguments from the pageAccess() system call
    uint64 usrpage_ptr;  // First argument - pointer to user space address
    int npages;          // Second argument - the number of pages to examine
    uint64 usraddr;      // Third argument - pointer to the bitmap

    // Retrieve the arguments passed from the user program
    if (argaddr(0, &usrpage_ptr) < 0 || argint(1, &npages) < 0 || argaddr(2, &usraddr) < 0)
	return -1;

    // Validate the number of pages (npages cannot exceed 64)
    if (npages > 64)
	return -1;

    struct proc *p = myproc(); // Get current process
    uint64 bitmap = 0; // Initialize the bitmap to 0
    uint64 va_start = usrpage_ptr; // Start virtual address

    // Iterate through the pages and check if they have been accessed
    for (int i = 0; i < npages; i++) {
	uint64 page_addr = va_start + i * PGSIZE; // Virtual address of current page
	uint64 pa = walkaddr(p->pagetable, page_addr); // Get the physical address

	if (pa == 0) {
	    return -1; // Invalid page address
	}

	pte_t* pte = (pte_t*)(pa & ~0xFFF); // Get page table entry (PTE)

	// Check if the page has been accessed
	if (*pte & (PTE_R | PTE_W)) {
	    bitmap |= (1 << i); // Set the corresponding bit in the bitmap
	}
    }

    // Copy the bitmap to user space before returning
    if (copyout(p->pagetable, usraddr, (char*)&bitmap, sizeof(bitmap)) < 0)
	return -1;

    return 0; // Return success
}
