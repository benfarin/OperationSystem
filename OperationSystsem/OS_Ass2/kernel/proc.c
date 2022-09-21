#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"

struct cpu cpus[NCPU];

struct proc proc[NPROC];

struct proc *initproc;

int nextpid = 1;
struct spinlock pid_lock;

extern void forkret(void);
static void freeproc(struct proc *p);

extern char trampoline[]; // trampoline.S

// helps ensure that wakeups of wait()ing
// parents are not lost. helps obey the
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;

extern uint64 cas(volatile void *addr, int expected, int newval);

int flag; // 1 when flag is ON,Otherwise 0

int unusedLS;
int sleepingLS;
int zombieLS;
int runnableLS[NCPU];
uint64 counters[NCPU];

//Modify lists - start

int
set_next_to_last(struct proc *proc_to_add)
{
  int curr_index;
    do{ 
    curr_index = (proc_to_add)->nextIndex;
  } while(cas(&((proc_to_add)->nextIndex), curr_index, -1));
  return 1;
}

int
add_to_ls(int cpuID, int *proc_ls, int new_proc_index){

  int next_index, curr_index;
  struct proc *proc_to_add = proc + new_proc_index;

    do{
      curr_index = proc_to_add->cpu_num;
    } while(cpuID > -1 && cas(&((proc_to_add)->cpu_num), curr_index, cpuID));
  

  if(*proc_ls == -1){ // ls empty
    do{
      curr_index = *proc_ls;
    } while(*proc_ls == -1 && cas(proc_ls, curr_index, new_proc_index));
    if(*proc_ls == new_proc_index) 
    { set_next_to_last(proc_to_add);
      return 1;
    }
  }

  next_index = *proc_ls;
  do{ 
    curr_index = next_index;
    if(curr_index != -1 && (proc + curr_index)->canDelete == 1) return add_to_ls(cpuID,proc_ls,new_proc_index);
    next_index = (proc + curr_index)->nextIndex;
  } while(cas(&((proc + curr_index)->nextIndex), -1, new_proc_index));

  set_next_to_last(proc_to_add);
  return 1;
}

int
set_can_be_deleted(struct proc *proc_to_remove)
{
  int delFlag;
  do{
    delFlag = (proc_to_remove)->canDelete;
  } while(cas(&((proc_to_remove)->canDelete), delFlag, 0)) ;
  return 0;

}

int
remove_from_ls(int *proc_ls, int remove_index){
  int res,delFlag, curr_link, prev_link, next_link;
  struct proc *proc_to_remove = proc + remove_index;

  res = 0;
  if (*proc_ls == -1) { // ls empty
    return 0;
  }

  if((proc_to_remove)->canDelete == 1) return 0;

  do{
    delFlag = (proc_to_remove)->canDelete;
  } while(cas(&((proc_to_remove)->canDelete), delFlag, 1)) ;

  if(*proc_ls == remove_index){ 
    do{
      next_link = (proc_to_remove)->nextIndex;
    } while(!cas(proc_ls, remove_index, next_link)) ;
    if(*proc_ls == (proc_to_remove)->nextIndex){
      res = remove_index + 1;
      set_can_be_deleted(proc_to_remove);
      return res;
    } 
  }

  curr_link = *proc_ls;
  do {
    prev_link = curr_link;
    if(prev_link != remove_index && (proc + prev_link)->canDelete == 1) return remove_from_ls(proc_ls,remove_index);
    curr_link = (proc + prev_link)->nextIndex;
  } while(cas(&((proc + prev_link)->nextIndex), remove_index, (proc_to_remove)->nextIndex) 
          && prev_link != -1) ;

  if (prev_link == -1){ // <proc_to_remove> isn't in the list
    res = 0;
    set_can_be_deleted(proc_to_remove);
    return res;
  }

  res = remove_index+1;
  if(proc_to_remove->canDelete == 0)
    return res;
  set_can_be_deleted(proc_to_remove);
  return res;
}

//Modify lists - end



// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
  }
}

// initialize the proc table at boot time.
void
procinit(void)
{

  struct proc *p;
  int i;
  unusedLS = -1;
  sleepingLS = -1;
  zombieLS = -1;
  #ifdef ON
    flag = 1;
  #endif
  #ifdef OFF
    flag = 0;
  #endif
  initlock(&pid_lock, "nextpid");
  initlock(&wait_lock, "wait_lock");
  for(i=0; i<NCPU; i++ )
  {
    counters[i] = 0;
    runnableLS[i] = -1;
  }
  for(p = proc; p < &proc[NPROC]; p++) {
    initlock(&p->lock, "proc");
    p->kstack = KSTACK((int) (p - proc));
    p->index = (p - proc);
    p->nextIndex = -1;
    p->cpu_num = -1;
    p->canDelete = 0;
    add_to_ls(-1, &unusedLS, p->index);
  }

}

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
  int id = r_tp();
  return id;
}

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
  int id = cpuid();
  struct cpu *c = &cpus[id];
  return c;
}

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
  push_off();
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
  pop_off();
  return p;
}

int
allocpid() { // Changed as required
  push_off();
  int pid;    
  do {
    pid = nextpid;
  }
  while(cas(&nextpid, pid, pid + 1));
  pop_off();
  return pid;
}

// Look in the process table for an UNUSED proc.
// If found, initialize state required to run in the kernel,
// and return with p->lock held.
// If there are no free procs, or a memory allocation fails, return 0.
static struct proc*
allocproc(void){
  struct proc *p;
  int temp;
  if(unusedLS == -1){ // No free entry
    return 0;
  }
  temp = unusedLS;
  if(remove_from_ls(&unusedLS, unusedLS) > 0){
    p = proc + temp;
    acquire(&p->lock);
    goto found;
  }
  return 0;

found:
  p->pid = allocpid();
  p->state = USED;
  p->cpu_num = -1;
  p->nextIndex = -1;
  p->canDelete = 0;

  // Allocate a trapframe page.
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  // An empty user page table.
  p->pagetable = proc_pagetable(p);
  if(p->pagetable == 0){
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  // Set up new context to start executing at forkret,
  // which returns to user space.
  memset(&p->context, 0, sizeof(p->context));
  p->context.ra = (uint64)forkret;
  p->context.sp = p->kstack + PGSIZE;

  return p;
}


// free a proc structure and the data hanging from it,
// including user pages.
// p->lock must be held.
static void
freeproc(struct proc *p){
  if(p->trapframe)
    kfree((void*)p->trapframe);
  p->trapframe = 0;
  if(p->pagetable)
    proc_freepagetable(p->pagetable, p->sz);
  remove_from_ls(&zombieLS, p->index);
  add_to_ls(-1, &unusedLS, p->index);
  p->pagetable = 0;
  p->sz = 0;
  p->pid = 0;
  p->parent = 0;
  p->name[0] = 0;
  p->chan = 0;
  p->killed = 0;
  p->xstate = 0;
  p->cpu_num = -1;
  p->nextIndex = -1;
  p->state = UNUSED;
  p->canDelete = 0;
}

// Create a user page table for a given process,
// with no user memory, but with trampoline pages.
pagetable_t
proc_pagetable(struct proc *p)
{
  pagetable_t pagetable;

  // An empty page table.
  pagetable = uvmcreate();
  if(pagetable == 0)
    return 0;

  // map the trampoline code (for system call return)
  // at the highest user virtual address.
  // only the supervisor uses it, on the way
  // to/from user space, so not PTE_U.
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
              (uint64)trampoline, PTE_R | PTE_X) < 0){
    uvmfree(pagetable, 0);
    return 0;
  }

  // map the trapframe just below TRAMPOLINE, for trampoline.S.
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
              (uint64)(p->trapframe), PTE_R | PTE_W) < 0){
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    uvmfree(pagetable, 0);
    return 0;
  }

  return pagetable;
}

// Free a process's page table, and free the
// physical memory it refers to.
void
proc_freepagetable(pagetable_t pagetable, uint64 sz)
{
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
  uvmfree(pagetable, sz);
}

// a user program that calls exec("/init")
// od -t xC initcode
uchar initcode[] = {
  0x17, 0x05, 0x00, 0x00, 0x13, 0x05, 0x45, 0x02,
  0x97, 0x05, 0x00, 0x00, 0x93, 0x85, 0x35, 0x02,
  0x93, 0x08, 0x70, 0x00, 0x73, 0x00, 0x00, 0x00,
  0x93, 0x08, 0x20, 0x00, 0x73, 0x00, 0x00, 0x00,
  0xef, 0xf0, 0x9f, 0xff, 0x2f, 0x69, 0x6e, 0x69,
  0x74, 0x00, 0x00, 0x24, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00
};

// Set up first user process.
void
userinit(void){
  struct proc *p;
  int curr_cpu_count;
  p = allocproc();
  initproc = p;
  
  // allocate one user page and copy init's instructions
  // and data into it.
  uvminit(p->pagetable, initcode, sizeof(initcode));
  p->sz = PGSIZE;
  
  // prepare for the very first "return" from kernel to user.
  p->trapframe->epc = 0;      // user program counter
  p->trapframe->sp = PGSIZE;  // user stack pointer
  
  safestrcpy(p->name, "initcode", sizeof(p->name));
  p->cwd = namei("/");
  p->state = RUNNABLE;
  add_to_ls(0, runnableLS, p->index);
  if(flag > 0){
    do{
      curr_cpu_count = counters[0]; 
    } while(cas(&(counters[0]), curr_cpu_count, curr_cpu_count + 1)) ;
  }
  release(&p->lock);
}

// Grow or shrink user memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
  uint sz;
  struct proc *p = myproc();

  sz = p->sz;
  if(n > 0){
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
      return -1;
    }
  } else if(n < 0){
    sz = uvmdealloc(p->pagetable, sz, sz + n);
  }
  p->sz = sz;
  return 0;
}

int get_min_cpu()
{
  
  int i,res;
  uint64 min = __UINT64_MAX__;
  res = -1;
  for(i = 0; i < CPUS; i++){
    if(counters[i] < min){
        min = counters[i];
        res = i;
      }
    }
    return res;
}

int
get_my_cpu(int my_cpu)
{

  int i, res;
  res = 0;
  if(flag > 0){
    res = get_min_cpu();
    do{ 
      i = counters[res];
    } while(cas(counters + res, i, i + 1)) ;  
  }
  else
    res = my_cpu;
  return res;
}
// Create a new process, copying the parent.
// Sets up child kernel stack to return as if from fork() system call.
int
fork(void){
  int cpu_to_add, i, pid;
  struct proc *np;
  struct proc *p = myproc();

  // Allocate process.
  if((np = allocproc()) == 0){
    return -1;
  }
  // Copy user memory from parent to child.
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    freeproc(np);
    release(&np->lock);
    return -1;
  }
  np->sz = p->sz;

  // copy saved user registers.
  *(np->trapframe) = *(p->trapframe);

  // Cause fork to return 0 in the child.
  np->trapframe->a0 = 0;

  // increment reference counts on open file descriptors.
  for(i = 0; i < NOFILE; i++)
    if(p->ofile[i])
      np->ofile[i] = filedup(p->ofile[i]);
  np->cwd = idup(p->cwd);

  safestrcpy(np->name, p->name, sizeof(p->name));

  pid = np->pid;

  release(&np->lock);

  acquire(&wait_lock);
  np->parent = p;
  release(&wait_lock);

  acquire(&np->lock);
  np->state = RUNNABLE;
  release(&np->lock);

  cpu_to_add = get_my_cpu(p->cpu_num);
  add_to_ls(cpu_to_add,(runnableLS + cpu_to_add), np->index); 


  return pid;
}

// Pass p's abandoned children to init.
// Caller must hold wait_lock.
void
reparent(struct proc *p)
{
  struct proc *pp;

  for(pp = proc; pp < &proc[NPROC]; pp++){
    if(pp->parent == p){
      pp->parent = initproc;
      wakeup(initproc);
    }
  }
}

// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait().
void
exit(int status){
  struct proc *p = myproc();

  if(p == initproc)
    panic("init exiting");

  // Close all open files.
  for(int fd = 0; fd < NOFILE; fd++){
    if(p->ofile[fd]){
      struct file *f = p->ofile[fd];
      fileclose(f);
      p->ofile[fd] = 0;
    }
  }

  begin_op();
  iput(p->cwd);
  end_op();
  p->cwd = 0;

  acquire(&wait_lock);

  // Give any children to init.
  reparent(p);

  // Parent might be sleeping in wait().
  wakeup(p->parent);
  
  acquire(&p->lock);

  p->xstate = status;
  remove_from_ls((runnableLS + p->cpu_num), p->index);
  p->state = ZOMBIE;
  add_to_ls(-1,&zombieLS, p->index); 

  release(&wait_lock);

  // Jump into the scheduler, never to return.
  sched();
  panic("zombie exit");
}

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(uint64 addr){
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
  acquire(&wait_lock);

  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
    for(np = proc; np < &proc[NPROC]; np++){
      if(np->parent == p){
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if(np->state == ZOMBIE){
          // Found one.
          pid = np->pid;
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
                                  sizeof(np->xstate)) < 0) {
            release(&np->lock);
            release(&wait_lock);
            return -1;
          }
          freeproc(np);
          release(&np->lock);
          release(&wait_lock);
          return pid;
        }
        release(&np->lock);
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || p->killed){
      release(&wait_lock);
      return -1;
    }
    // Wait for a child to exit.
    sleep(p, &wait_lock);  //DOC: wait-sleep
  }
}


//for part 4
void
schedulerNew(int cpu_id, int *first_proc, struct cpu *c)
{
  int index;
  struct proc *p = myproc();
  for(int i = 0; i < CPUS; i++){
    if(runnableLS[i] != -1){ 
    p = proc + runnableLS[i];
    acquire(&p->lock);
    if(remove_from_ls((runnableLS + i), p->index) > 0 && !cas(&p->state, RUNNABLE, RUNNING)){
      do{ 
        index = counters[cpu_id];
        } while(cas(&counters[cpu_id], index, index + 1)) ;
      cas(&(p->cpu_num), i, cpu_id);
      c->proc = p;
      swtch(&c->context, &p->context);
      c->proc = 0;
    }
    release(&p->lock);
    break;
        }
      }
}


// Per-CPU process scheduler.
// Each CPU calls scheduler() after setting itself up.
// Scheduler never returns.  It loops, doing:
//  - choose a process to run.
//  - swtch to start running that process.
//  - eventually that process transfers control
//    via swtch back to the scheduler.
void
scheduler(void){
  struct proc *p = 0;
  struct cpu *c = mycpu();
  int curr_index;
  int cpu_id = cpuid();
  int *first_proc;

  c->proc = 0;
  for(;;){
    // Avoid deadlock by ensuring that devices can interrupt.
    intr_on();

    first_proc = &runnableLS[cpu_id];
    curr_index = runnableLS[cpu_id];
    if(!curr_index){ 
      p = proc + curr_index;
      acquire(&p->lock);
      if(remove_from_ls(first_proc, curr_index) > 0 && !cas(&p->state, RUNNABLE, RUNNING)){
        
          c->proc = p;
          swtch(&c->context, &p->context);
          c->proc = 0;
        }
      release(&p->lock);
    }
    else if(flag > 0){
      schedulerNew(cpu_id,first_proc,c);
    }
  }
}


// Switch to scheduler.  Must hold only p->lock
// and have changed proc->state. Saves and restores
// intena because intena is a property of this
// kernel thread, not this CPU. It should
// be proc->intena and proc->noff, but that would
// break in the few places where a lock is held but
// there's no process.
void
sched(void)
{
  int intena;
  struct proc *p = myproc();

  if(!holding(&p->lock))
    panic("sched p->lock");
  if(mycpu()->noff != 1)
    panic("sched locks");
  if(p->state == RUNNING)
    panic("sched running");
  if(intr_get())
    panic("sched interruptible");

  intena = mycpu()->intena;
  swtch(&p->context, &mycpu()->context);
  mycpu()->intena = intena;
}

// Give up the CPU for one scheduling round.
void
yield(void){
  int cpu_to_add;
  struct proc *p = myproc();
  acquire(&p->lock);
  p->state = RUNNABLE;
  cpu_to_add = get_my_cpu(p->cpu_num);
  add_to_ls(cpu_to_add,(runnableLS + p->cpu_num), p->index);
  sched();
  release(&p->lock);
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);

  if (first) {
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
}

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk){
  int res;
  struct proc *p = myproc();
  res = 0;
  
  p->chan = chan;
  if (remove_from_ls((runnableLS + p->cpu_num), p->index) > 0){
    do{
      res = p->state;
    } while(cas(&p->state, res, SLEEPING));
    res = 2;
    add_to_ls(-1, &sleepingLS, p->index);
    acquire(&p->lock);
    release(lk);
    sched();

  }

  if(res>0){
    // Go to sleep.
    p->chan = 0;
    release(&p->lock);
    acquire(lk);
  }
  else
  {   
    acquire(&p->lock);
    release(lk);
    p->chan = 0;
    release(&p->lock);
    acquire(lk);

  }
  

}

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan){
  struct proc *p;
  int curr_index, old_index, cpu_to_add;
  curr_index = sleepingLS;

  do{
    if(curr_index == -1){ 
      return;
    }
    p = (proc + curr_index);
    if(p != myproc()){
      acquire(&(p->lock));
      if (p->chan == chan){ // p is sleeping on <chan>
        if (remove_from_ls(&sleepingLS, curr_index) > 0){
          p->chan = 0;
          if(!cas(&p->state, SLEEPING, RUNNABLE)){
            cpu_to_add = get_my_cpu(p->cpu_num);
            add_to_ls(cpu_to_add,(runnableLS + cpu_to_add), p->index);  

          }
        }
      }
      release(&p->lock);
    }
    old_index = curr_index;
  } while(!cas(&curr_index, old_index, (proc + curr_index)->nextIndex));
}

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid){
  struct proc *p;
  //int cpu_to_add;
  for(p = proc; p < &proc[NPROC]; p++){
    acquire(&p->lock);
    if(p->pid == pid){
      p->killed = 1;
      if(p->state == SLEEPING){
        // Wake process from sleep().
        remove_from_ls(&sleepingLS, p->index);
        p->state = RUNNABLE;
        // cpu_to_add = get_my_cpu(p->cpu_num);
        // add_to_ls(cpu_to_add, (runnableLS + p->cpu_num), p->index);
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
  }
  return -1;
}

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
  struct proc *p = myproc();
  if(user_dst){
    return copyout(p->pagetable, dst, src, len);
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
  struct proc *p = myproc();
  if(user_src){
    return copyin(p->pagetable, dst, src, len);
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
  static char *states[] = {
  [UNUSED]    "unused",
  [SLEEPING]  "sleep ",
  [RUNNABLE]  "runble",
  [RUNNING]   "run   ",
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
  for(p = proc; p < &proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
    printf("%d %s %s", p->pid, state, p->name);
    printf("\n");
  }
}

int
set_cpu(int cpuID){
  int curr_cpu;
  struct  proc *p = myproc();
  do{
    curr_cpu = p->cpu_num;
  } while(cas(&((proc + p->index)->cpu_num), curr_cpu, cpuID)) ;
  yield();
  return p->cpu_num;
}

int
get_cpu(void){
  intr_off();
  return cpuid();
}

int
cpu_process_count(int cpuID){
  if(cpuID < NCPU)
    return counters[cpuID];
  return -1;
}