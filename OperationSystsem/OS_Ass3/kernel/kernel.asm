
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	87013103          	ld	sp,-1936(sp) # 80008870 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	c9c78793          	addi	a5,a5,-868 # 80005d00 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffb87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	eea78793          	addi	a5,a5,-278 # 80000f98 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	44e080e7          	jalr	1102(ra) # 8000257a <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	b5a080e7          	jalr	-1190(ra) # 80000cee <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	900080e7          	jalr	-1792(ra) # 80001ac4 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	fac080e7          	jalr	-84(ra) # 80002180 <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	314080e7          	jalr	788(ra) # 80002524 <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	b76080e7          	jalr	-1162(ra) # 80000da2 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	b60080e7          	jalr	-1184(ra) # 80000da2 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	a1a080e7          	jalr	-1510(ra) # 80000cee <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	2de080e7          	jalr	734(ra) # 800025d0 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	aa0080e7          	jalr	-1376(ra) # 80000da2 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	ec6080e7          	jalr	-314(ra) # 8000230c <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	7f6080e7          	jalr	2038(ra) # 80000c5e <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00041797          	auipc	a5,0x41
    8000047c:	eb878793          	addi	a5,a5,-328 # 80041330 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b6c50513          	addi	a0,a0,-1172 # 800080d8 <digits+0x98>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	6ee080e7          	jalr	1774(ra) # 80000cee <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	63e080e7          	jalr	1598(ra) # 80000da2 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	4d4080e7          	jalr	1236(ra) # 80000c5e <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	47e080e7          	jalr	1150(ra) # 80000c5e <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	4a6080e7          	jalr	1190(ra) # 80000ca2 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	514080e7          	jalr	1300(ra) # 80000d42 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	a6c080e7          	jalr	-1428(ra) # 8000230c <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	40a080e7          	jalr	1034(ra) # 80000cee <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	854080e7          	jalr	-1964(ra) # 80002180 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	43a080e7          	jalr	1082(ra) # 80000da2 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	31a080e7          	jalr	794(ra) # 80000cee <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	3bc080e7          	jalr	956(ra) # 80000da2 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kalloc>:
  release(&kmem.lock);
}

void *
kalloc(void)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000a02:	00011497          	auipc	s1,0x11
    80000a06:	87e48493          	addi	s1,s1,-1922 # 80011280 <kmem>
    80000a0a:	8526                	mv	a0,s1
    80000a0c:	00000097          	auipc	ra,0x0
    80000a10:	2e2080e7          	jalr	738(ra) # 80000cee <acquire>
  r = kmem.freelist;
    80000a14:	6c84                	ld	s1,24(s1)

  if(r) {
    80000a16:	c4a1                	beqz	s1,80000a5e <kalloc+0x66>
    references[PA2IDX((uint64)r)] = 1;
    80000a18:	800007b7          	lui	a5,0x80000
    80000a1c:	97a6                	add	a5,a5,s1
    80000a1e:	83b1                	srli	a5,a5,0xc
    80000a20:	078a                	slli	a5,a5,0x2
    80000a22:	00011717          	auipc	a4,0x11
    80000a26:	89670713          	addi	a4,a4,-1898 # 800112b8 <references>
    80000a2a:	97ba                	add	a5,a5,a4
    80000a2c:	4705                	li	a4,1
    80000a2e:	c398                	sw	a4,0(a5)
    kmem.freelist = r->next;
    80000a30:	609c                	ld	a5,0(s1)
    80000a32:	00011517          	auipc	a0,0x11
    80000a36:	84e50513          	addi	a0,a0,-1970 # 80011280 <kmem>
    80000a3a:	ed1c                	sd	a5,24(a0)
  }
  release(&kmem.lock);
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	366080e7          	jalr	870(ra) # 80000da2 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000a44:	6605                	lui	a2,0x1
    80000a46:	4595                	li	a1,5
    80000a48:	8526                	mv	a0,s1
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	3a0080e7          	jalr	928(ra) # 80000dea <memset>
  return (void*)r;
}
    80000a52:	8526                	mv	a0,s1
    80000a54:	60e2                	ld	ra,24(sp)
    80000a56:	6442                	ld	s0,16(sp)
    80000a58:	64a2                	ld	s1,8(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
  release(&kmem.lock);
    80000a5e:	00011517          	auipc	a0,0x11
    80000a62:	82250513          	addi	a0,a0,-2014 # 80011280 <kmem>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	33c080e7          	jalr	828(ra) # 80000da2 <release>
  if(r)
    80000a6e:	b7d5                	j	80000a52 <kalloc+0x5a>

0000000080000a70 <reference_add>:
//   return references[PA2IDX(pa)];
// }

int
reference_add(uint64 page)
{
    80000a70:	7179                	addi	sp,sp,-48
    80000a72:	f406                	sd	ra,40(sp)
    80000a74:	f022                	sd	s0,32(sp)
    80000a76:	ec26                	sd	s1,24(sp)
    80000a78:	e84a                	sd	s2,16(sp)
    80000a7a:	e44e                	sd	s3,8(sp)
    80000a7c:	1800                	addi	s0,sp,48
  int ref;
  do
  {
    ref = references[PA2IDX(page)];
    80000a7e:	80000937          	lui	s2,0x80000
    80000a82:	992a                	add	s2,s2,a0
    80000a84:	00c95913          	srli	s2,s2,0xc
  } while(cas(&references[PA2IDX(page)],ref,ref+1));
    80000a88:	00291993          	slli	s3,s2,0x2
    80000a8c:	00011797          	auipc	a5,0x11
    80000a90:	82c78793          	addi	a5,a5,-2004 # 800112b8 <references>
    80000a94:	99be                	add	s3,s3,a5
    ref = references[PA2IDX(page)];
    80000a96:	894e                	mv	s2,s3
    80000a98:	00092583          	lw	a1,0(s2) # ffffffff80000000 <end+0xfffffffefffba000>
  } while(cas(&references[PA2IDX(page)],ref,ref+1));
    80000a9c:	0015849b          	addiw	s1,a1,1
    80000aa0:	8626                	mv	a2,s1
    80000aa2:	854e                	mv	a0,s3
    80000aa4:	00006097          	auipc	ra,0x6
    80000aa8:	8a2080e7          	jalr	-1886(ra) # 80006346 <cas>
    80000aac:	f575                	bnez	a0,80000a98 <reference_add+0x28>
  // acquire(&r_lock);
  // ref = ++references[PA2IDX(pa)];
  // release(&r_lock); 
  return ref+1;
}
    80000aae:	8526                	mv	a0,s1
    80000ab0:	70a2                	ld	ra,40(sp)
    80000ab2:	7402                	ld	s0,32(sp)
    80000ab4:	64e2                	ld	s1,24(sp)
    80000ab6:	6942                	ld	s2,16(sp)
    80000ab8:	69a2                	ld	s3,8(sp)
    80000aba:	6145                	addi	sp,sp,48
    80000abc:	8082                	ret

0000000080000abe <reference_remove>:

int
reference_remove(uint64 page)
{
    80000abe:	7179                	addi	sp,sp,-48
    80000ac0:	f406                	sd	ra,40(sp)
    80000ac2:	f022                	sd	s0,32(sp)
    80000ac4:	ec26                	sd	s1,24(sp)
    80000ac6:	e84a                	sd	s2,16(sp)
    80000ac8:	e44e                	sd	s3,8(sp)
    80000aca:	1800                	addi	s0,sp,48
  int ref;
    do
  {
    ref = references[PA2IDX(page)];
    80000acc:	80000937          	lui	s2,0x80000
    80000ad0:	992a                	add	s2,s2,a0
    80000ad2:	00c95913          	srli	s2,s2,0xc
  } while(cas(&references[PA2IDX(page)],ref,ref-1));
    80000ad6:	00291993          	slli	s3,s2,0x2
    80000ada:	00010797          	auipc	a5,0x10
    80000ade:	7de78793          	addi	a5,a5,2014 # 800112b8 <references>
    80000ae2:	99be                	add	s3,s3,a5
    ref = references[PA2IDX(page)];
    80000ae4:	894e                	mv	s2,s3
    80000ae6:	00092583          	lw	a1,0(s2) # ffffffff80000000 <end+0xfffffffefffba000>
  } while(cas(&references[PA2IDX(page)],ref,ref-1));
    80000aea:	fff5849b          	addiw	s1,a1,-1
    80000aee:	8626                	mv	a2,s1
    80000af0:	854e                	mv	a0,s3
    80000af2:	00006097          	auipc	ra,0x6
    80000af6:	854080e7          	jalr	-1964(ra) # 80006346 <cas>
    80000afa:	f575                	bnez	a0,80000ae6 <reference_remove+0x28>
  // acquire(&r_lock);
  // ref = --references[PA2IDX(pa)];
  // release(&r_lock);
  return ref-1;
}
    80000afc:	8526                	mv	a0,s1
    80000afe:	70a2                	ld	ra,40(sp)
    80000b00:	7402                	ld	s0,32(sp)
    80000b02:	64e2                	ld	s1,24(sp)
    80000b04:	6942                	ld	s2,16(sp)
    80000b06:	69a2                	ld	s3,8(sp)
    80000b08:	6145                	addi	sp,sp,48
    80000b0a:	8082                	ret

0000000080000b0c <kfree>:
{
    80000b0c:	1101                	addi	sp,sp,-32
    80000b0e:	ec06                	sd	ra,24(sp)
    80000b10:	e822                	sd	s0,16(sp)
    80000b12:	e426                	sd	s1,8(sp)
    80000b14:	e04a                	sd	s2,0(sp)
    80000b16:	1000                	addi	s0,sp,32
  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000b18:	03451793          	slli	a5,a0,0x34
    80000b1c:	eb85                	bnez	a5,80000b4c <kfree+0x40>
    80000b1e:	84aa                	mv	s1,a0
    80000b20:	00045797          	auipc	a5,0x45
    80000b24:	4e078793          	addi	a5,a5,1248 # 80046000 <end>
    80000b28:	02f56263          	bltu	a0,a5,80000b4c <kfree+0x40>
    80000b2c:	47c5                	li	a5,17
    80000b2e:	07ee                	slli	a5,a5,0x1b
    80000b30:	00f57e63          	bgeu	a0,a5,80000b4c <kfree+0x40>
  if (reference_remove((uint64)pa) > 0)
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	f8a080e7          	jalr	-118(ra) # 80000abe <reference_remove>
    80000b3c:	02a05063          	blez	a0,80000b5c <kfree+0x50>
}
    80000b40:	60e2                	ld	ra,24(sp)
    80000b42:	6442                	ld	s0,16(sp)
    80000b44:	64a2                	ld	s1,8(sp)
    80000b46:	6902                	ld	s2,0(sp)
    80000b48:	6105                	addi	sp,sp,32
    80000b4a:	8082                	ret
    panic("kfree");
    80000b4c:	00007517          	auipc	a0,0x7
    80000b50:	51450513          	addi	a0,a0,1300 # 80008060 <digits+0x20>
    80000b54:	00000097          	auipc	ra,0x0
    80000b58:	9ea080e7          	jalr	-1558(ra) # 8000053e <panic>
  references[PA2IDX((uint64)pa)] = 0;
    80000b5c:	800007b7          	lui	a5,0x80000
    80000b60:	97a6                	add	a5,a5,s1
    80000b62:	83b1                	srli	a5,a5,0xc
    80000b64:	078a                	slli	a5,a5,0x2
    80000b66:	00010717          	auipc	a4,0x10
    80000b6a:	75270713          	addi	a4,a4,1874 # 800112b8 <references>
    80000b6e:	97ba                	add	a5,a5,a4
    80000b70:	0007a023          	sw	zero,0(a5) # ffffffff80000000 <end+0xfffffffefffba000>
  memset(pa, 1, PGSIZE);
    80000b74:	6605                	lui	a2,0x1
    80000b76:	4585                	li	a1,1
    80000b78:	8526                	mv	a0,s1
    80000b7a:	00000097          	auipc	ra,0x0
    80000b7e:	270080e7          	jalr	624(ra) # 80000dea <memset>
  acquire(&kmem.lock);
    80000b82:	00010917          	auipc	s2,0x10
    80000b86:	6fe90913          	addi	s2,s2,1790 # 80011280 <kmem>
    80000b8a:	854a                	mv	a0,s2
    80000b8c:	00000097          	auipc	ra,0x0
    80000b90:	162080e7          	jalr	354(ra) # 80000cee <acquire>
  r->next = kmem.freelist;
    80000b94:	01893783          	ld	a5,24(s2)
    80000b98:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000b9a:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000b9e:	854a                	mv	a0,s2
    80000ba0:	00000097          	auipc	ra,0x0
    80000ba4:	202080e7          	jalr	514(ra) # 80000da2 <release>
    80000ba8:	bf61                	j	80000b40 <kfree+0x34>

0000000080000baa <freerange>:
//   freerange(end, (void*)PHYSTOP);
// }

void
freerange(void *pa_start, void *pa_end)
{
    80000baa:	7179                	addi	sp,sp,-48
    80000bac:	f406                	sd	ra,40(sp)
    80000bae:	f022                	sd	s0,32(sp)
    80000bb0:	ec26                	sd	s1,24(sp)
    80000bb2:	e84a                	sd	s2,16(sp)
    80000bb4:	e44e                	sd	s3,8(sp)
    80000bb6:	e052                	sd	s4,0(sp)
    80000bb8:	1800                	addi	s0,sp,48
  char *p;
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000bba:	6785                	lui	a5,0x1
    80000bbc:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000bc0:	94aa                	add	s1,s1,a0
    80000bc2:	757d                	lui	a0,0xfffff
    80000bc4:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000bc6:	94be                	add	s1,s1,a5
    80000bc8:	0095ee63          	bltu	a1,s1,80000be4 <freerange+0x3a>
    80000bcc:	892e                	mv	s2,a1
    kfree(p);
    80000bce:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000bd0:	6985                	lui	s3,0x1
    kfree(p);
    80000bd2:	01448533          	add	a0,s1,s4
    80000bd6:	00000097          	auipc	ra,0x0
    80000bda:	f36080e7          	jalr	-202(ra) # 80000b0c <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000bde:	94ce                	add	s1,s1,s3
    80000be0:	fe9979e3          	bgeu	s2,s1,80000bd2 <freerange+0x28>
}
    80000be4:	70a2                	ld	ra,40(sp)
    80000be6:	7402                	ld	s0,32(sp)
    80000be8:	64e2                	ld	s1,24(sp)
    80000bea:	6942                	ld	s2,16(sp)
    80000bec:	69a2                	ld	s3,8(sp)
    80000bee:	6a02                	ld	s4,0(sp)
    80000bf0:	6145                	addi	sp,sp,48
    80000bf2:	8082                	ret

0000000080000bf4 <kinit>:
{
    80000bf4:	1141                	addi	sp,sp,-16
    80000bf6:	e406                	sd	ra,8(sp)
    80000bf8:	e022                	sd	s0,0(sp)
    80000bfa:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000bfc:	00007597          	auipc	a1,0x7
    80000c00:	46c58593          	addi	a1,a1,1132 # 80008068 <digits+0x28>
    80000c04:	00010517          	auipc	a0,0x10
    80000c08:	67c50513          	addi	a0,a0,1660 # 80011280 <kmem>
    80000c0c:	00000097          	auipc	ra,0x0
    80000c10:	052080e7          	jalr	82(ra) # 80000c5e <initlock>
  initlock(&r_lock, "refereces");
    80000c14:	00007597          	auipc	a1,0x7
    80000c18:	45c58593          	addi	a1,a1,1116 # 80008070 <digits+0x30>
    80000c1c:	00010517          	auipc	a0,0x10
    80000c20:	68450513          	addi	a0,a0,1668 # 800112a0 <r_lock>
    80000c24:	00000097          	auipc	ra,0x0
    80000c28:	03a080e7          	jalr	58(ra) # 80000c5e <initlock>
  memset(references, 0, sizeof(int)*PA2IDX(PHYSTOP));
    80000c2c:	00020637          	lui	a2,0x20
    80000c30:	4581                	li	a1,0
    80000c32:	00010517          	auipc	a0,0x10
    80000c36:	68650513          	addi	a0,a0,1670 # 800112b8 <references>
    80000c3a:	00000097          	auipc	ra,0x0
    80000c3e:	1b0080e7          	jalr	432(ra) # 80000dea <memset>
  freerange(end, (void*)PHYSTOP);
    80000c42:	45c5                	li	a1,17
    80000c44:	05ee                	slli	a1,a1,0x1b
    80000c46:	00045517          	auipc	a0,0x45
    80000c4a:	3ba50513          	addi	a0,a0,954 # 80046000 <end>
    80000c4e:	00000097          	auipc	ra,0x0
    80000c52:	f5c080e7          	jalr	-164(ra) # 80000baa <freerange>
}
    80000c56:	60a2                	ld	ra,8(sp)
    80000c58:	6402                	ld	s0,0(sp)
    80000c5a:	0141                	addi	sp,sp,16
    80000c5c:	8082                	ret

0000000080000c5e <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000c5e:	1141                	addi	sp,sp,-16
    80000c60:	e422                	sd	s0,8(sp)
    80000c62:	0800                	addi	s0,sp,16
  lk->name = name;
    80000c64:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000c66:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000c6a:	00053823          	sd	zero,16(a0)
}
    80000c6e:	6422                	ld	s0,8(sp)
    80000c70:	0141                	addi	sp,sp,16
    80000c72:	8082                	ret

0000000080000c74 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c74:	411c                	lw	a5,0(a0)
    80000c76:	e399                	bnez	a5,80000c7c <holding+0x8>
    80000c78:	4501                	li	a0,0
  return r;
}
    80000c7a:	8082                	ret
{
    80000c7c:	1101                	addi	sp,sp,-32
    80000c7e:	ec06                	sd	ra,24(sp)
    80000c80:	e822                	sd	s0,16(sp)
    80000c82:	e426                	sd	s1,8(sp)
    80000c84:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c86:	6904                	ld	s1,16(a0)
    80000c88:	00001097          	auipc	ra,0x1
    80000c8c:	e20080e7          	jalr	-480(ra) # 80001aa8 <mycpu>
    80000c90:	40a48533          	sub	a0,s1,a0
    80000c94:	00153513          	seqz	a0,a0
}
    80000c98:	60e2                	ld	ra,24(sp)
    80000c9a:	6442                	ld	s0,16(sp)
    80000c9c:	64a2                	ld	s1,8(sp)
    80000c9e:	6105                	addi	sp,sp,32
    80000ca0:	8082                	ret

0000000080000ca2 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000ca2:	1101                	addi	sp,sp,-32
    80000ca4:	ec06                	sd	ra,24(sp)
    80000ca6:	e822                	sd	s0,16(sp)
    80000ca8:	e426                	sd	s1,8(sp)
    80000caa:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cac:	100024f3          	csrr	s1,sstatus
    80000cb0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000cb4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cb6:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000cba:	00001097          	auipc	ra,0x1
    80000cbe:	dee080e7          	jalr	-530(ra) # 80001aa8 <mycpu>
    80000cc2:	5d3c                	lw	a5,120(a0)
    80000cc4:	cf89                	beqz	a5,80000cde <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000cc6:	00001097          	auipc	ra,0x1
    80000cca:	de2080e7          	jalr	-542(ra) # 80001aa8 <mycpu>
    80000cce:	5d3c                	lw	a5,120(a0)
    80000cd0:	2785                	addiw	a5,a5,1
    80000cd2:	dd3c                	sw	a5,120(a0)
}
    80000cd4:	60e2                	ld	ra,24(sp)
    80000cd6:	6442                	ld	s0,16(sp)
    80000cd8:	64a2                	ld	s1,8(sp)
    80000cda:	6105                	addi	sp,sp,32
    80000cdc:	8082                	ret
    mycpu()->intena = old;
    80000cde:	00001097          	auipc	ra,0x1
    80000ce2:	dca080e7          	jalr	-566(ra) # 80001aa8 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000ce6:	8085                	srli	s1,s1,0x1
    80000ce8:	8885                	andi	s1,s1,1
    80000cea:	dd64                	sw	s1,124(a0)
    80000cec:	bfe9                	j	80000cc6 <push_off+0x24>

0000000080000cee <acquire>:
{
    80000cee:	1101                	addi	sp,sp,-32
    80000cf0:	ec06                	sd	ra,24(sp)
    80000cf2:	e822                	sd	s0,16(sp)
    80000cf4:	e426                	sd	s1,8(sp)
    80000cf6:	1000                	addi	s0,sp,32
    80000cf8:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000cfa:	00000097          	auipc	ra,0x0
    80000cfe:	fa8080e7          	jalr	-88(ra) # 80000ca2 <push_off>
  if(holding(lk))
    80000d02:	8526                	mv	a0,s1
    80000d04:	00000097          	auipc	ra,0x0
    80000d08:	f70080e7          	jalr	-144(ra) # 80000c74 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d0c:	4705                	li	a4,1
  if(holding(lk))
    80000d0e:	e115                	bnez	a0,80000d32 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d10:	87ba                	mv	a5,a4
    80000d12:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000d16:	2781                	sext.w	a5,a5
    80000d18:	ffe5                	bnez	a5,80000d10 <acquire+0x22>
  __sync_synchronize();
    80000d1a:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000d1e:	00001097          	auipc	ra,0x1
    80000d22:	d8a080e7          	jalr	-630(ra) # 80001aa8 <mycpu>
    80000d26:	e888                	sd	a0,16(s1)
}
    80000d28:	60e2                	ld	ra,24(sp)
    80000d2a:	6442                	ld	s0,16(sp)
    80000d2c:	64a2                	ld	s1,8(sp)
    80000d2e:	6105                	addi	sp,sp,32
    80000d30:	8082                	ret
    panic("acquire");
    80000d32:	00007517          	auipc	a0,0x7
    80000d36:	34e50513          	addi	a0,a0,846 # 80008080 <digits+0x40>
    80000d3a:	00000097          	auipc	ra,0x0
    80000d3e:	804080e7          	jalr	-2044(ra) # 8000053e <panic>

0000000080000d42 <pop_off>:

void
pop_off(void)
{
    80000d42:	1141                	addi	sp,sp,-16
    80000d44:	e406                	sd	ra,8(sp)
    80000d46:	e022                	sd	s0,0(sp)
    80000d48:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000d4a:	00001097          	auipc	ra,0x1
    80000d4e:	d5e080e7          	jalr	-674(ra) # 80001aa8 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d52:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000d56:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000d58:	e78d                	bnez	a5,80000d82 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d5a:	5d3c                	lw	a5,120(a0)
    80000d5c:	02f05b63          	blez	a5,80000d92 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000d60:	37fd                	addiw	a5,a5,-1
    80000d62:	0007871b          	sext.w	a4,a5
    80000d66:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000d68:	eb09                	bnez	a4,80000d7a <pop_off+0x38>
    80000d6a:	5d7c                	lw	a5,124(a0)
    80000d6c:	c799                	beqz	a5,80000d7a <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d6e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d72:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d76:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d7a:	60a2                	ld	ra,8(sp)
    80000d7c:	6402                	ld	s0,0(sp)
    80000d7e:	0141                	addi	sp,sp,16
    80000d80:	8082                	ret
    panic("pop_off - interruptible");
    80000d82:	00007517          	auipc	a0,0x7
    80000d86:	30650513          	addi	a0,a0,774 # 80008088 <digits+0x48>
    80000d8a:	fffff097          	auipc	ra,0xfffff
    80000d8e:	7b4080e7          	jalr	1972(ra) # 8000053e <panic>
    panic("pop_off");
    80000d92:	00007517          	auipc	a0,0x7
    80000d96:	30e50513          	addi	a0,a0,782 # 800080a0 <digits+0x60>
    80000d9a:	fffff097          	auipc	ra,0xfffff
    80000d9e:	7a4080e7          	jalr	1956(ra) # 8000053e <panic>

0000000080000da2 <release>:
{
    80000da2:	1101                	addi	sp,sp,-32
    80000da4:	ec06                	sd	ra,24(sp)
    80000da6:	e822                	sd	s0,16(sp)
    80000da8:	e426                	sd	s1,8(sp)
    80000daa:	1000                	addi	s0,sp,32
    80000dac:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000dae:	00000097          	auipc	ra,0x0
    80000db2:	ec6080e7          	jalr	-314(ra) # 80000c74 <holding>
    80000db6:	c115                	beqz	a0,80000dda <release+0x38>
  lk->cpu = 0;
    80000db8:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000dbc:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000dc0:	0f50000f          	fence	iorw,ow
    80000dc4:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000dc8:	00000097          	auipc	ra,0x0
    80000dcc:	f7a080e7          	jalr	-134(ra) # 80000d42 <pop_off>
}
    80000dd0:	60e2                	ld	ra,24(sp)
    80000dd2:	6442                	ld	s0,16(sp)
    80000dd4:	64a2                	ld	s1,8(sp)
    80000dd6:	6105                	addi	sp,sp,32
    80000dd8:	8082                	ret
    panic("release");
    80000dda:	00007517          	auipc	a0,0x7
    80000dde:	2ce50513          	addi	a0,a0,718 # 800080a8 <digits+0x68>
    80000de2:	fffff097          	auipc	ra,0xfffff
    80000de6:	75c080e7          	jalr	1884(ra) # 8000053e <panic>

0000000080000dea <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000dea:	1141                	addi	sp,sp,-16
    80000dec:	e422                	sd	s0,8(sp)
    80000dee:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000df0:	ce09                	beqz	a2,80000e0a <memset+0x20>
    80000df2:	87aa                	mv	a5,a0
    80000df4:	fff6071b          	addiw	a4,a2,-1
    80000df8:	1702                	slli	a4,a4,0x20
    80000dfa:	9301                	srli	a4,a4,0x20
    80000dfc:	0705                	addi	a4,a4,1
    80000dfe:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000e00:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000e04:	0785                	addi	a5,a5,1
    80000e06:	fee79de3          	bne	a5,a4,80000e00 <memset+0x16>
  }
  return dst;
}
    80000e0a:	6422                	ld	s0,8(sp)
    80000e0c:	0141                	addi	sp,sp,16
    80000e0e:	8082                	ret

0000000080000e10 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000e10:	1141                	addi	sp,sp,-16
    80000e12:	e422                	sd	s0,8(sp)
    80000e14:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000e16:	ca05                	beqz	a2,80000e46 <memcmp+0x36>
    80000e18:	fff6069b          	addiw	a3,a2,-1
    80000e1c:	1682                	slli	a3,a3,0x20
    80000e1e:	9281                	srli	a3,a3,0x20
    80000e20:	0685                	addi	a3,a3,1
    80000e22:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000e24:	00054783          	lbu	a5,0(a0)
    80000e28:	0005c703          	lbu	a4,0(a1)
    80000e2c:	00e79863          	bne	a5,a4,80000e3c <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000e30:	0505                	addi	a0,a0,1
    80000e32:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000e34:	fed518e3          	bne	a0,a3,80000e24 <memcmp+0x14>
  }

  return 0;
    80000e38:	4501                	li	a0,0
    80000e3a:	a019                	j	80000e40 <memcmp+0x30>
      return *s1 - *s2;
    80000e3c:	40e7853b          	subw	a0,a5,a4
}
    80000e40:	6422                	ld	s0,8(sp)
    80000e42:	0141                	addi	sp,sp,16
    80000e44:	8082                	ret
  return 0;
    80000e46:	4501                	li	a0,0
    80000e48:	bfe5                	j	80000e40 <memcmp+0x30>

0000000080000e4a <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000e4a:	1141                	addi	sp,sp,-16
    80000e4c:	e422                	sd	s0,8(sp)
    80000e4e:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000e50:	ca0d                	beqz	a2,80000e82 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000e52:	00a5f963          	bgeu	a1,a0,80000e64 <memmove+0x1a>
    80000e56:	02061693          	slli	a3,a2,0x20
    80000e5a:	9281                	srli	a3,a3,0x20
    80000e5c:	00d58733          	add	a4,a1,a3
    80000e60:	02e56463          	bltu	a0,a4,80000e88 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000e64:	fff6079b          	addiw	a5,a2,-1
    80000e68:	1782                	slli	a5,a5,0x20
    80000e6a:	9381                	srli	a5,a5,0x20
    80000e6c:	0785                	addi	a5,a5,1
    80000e6e:	97ae                	add	a5,a5,a1
    80000e70:	872a                	mv	a4,a0
      *d++ = *s++;
    80000e72:	0585                	addi	a1,a1,1
    80000e74:	0705                	addi	a4,a4,1
    80000e76:	fff5c683          	lbu	a3,-1(a1)
    80000e7a:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000e7e:	fef59ae3          	bne	a1,a5,80000e72 <memmove+0x28>

  return dst;
}
    80000e82:	6422                	ld	s0,8(sp)
    80000e84:	0141                	addi	sp,sp,16
    80000e86:	8082                	ret
    d += n;
    80000e88:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000e8a:	fff6079b          	addiw	a5,a2,-1
    80000e8e:	1782                	slli	a5,a5,0x20
    80000e90:	9381                	srli	a5,a5,0x20
    80000e92:	fff7c793          	not	a5,a5
    80000e96:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000e98:	177d                	addi	a4,a4,-1
    80000e9a:	16fd                	addi	a3,a3,-1
    80000e9c:	00074603          	lbu	a2,0(a4)
    80000ea0:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000ea4:	fef71ae3          	bne	a4,a5,80000e98 <memmove+0x4e>
    80000ea8:	bfe9                	j	80000e82 <memmove+0x38>

0000000080000eaa <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000eaa:	1141                	addi	sp,sp,-16
    80000eac:	e406                	sd	ra,8(sp)
    80000eae:	e022                	sd	s0,0(sp)
    80000eb0:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000eb2:	00000097          	auipc	ra,0x0
    80000eb6:	f98080e7          	jalr	-104(ra) # 80000e4a <memmove>
}
    80000eba:	60a2                	ld	ra,8(sp)
    80000ebc:	6402                	ld	s0,0(sp)
    80000ebe:	0141                	addi	sp,sp,16
    80000ec0:	8082                	ret

0000000080000ec2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000ec2:	1141                	addi	sp,sp,-16
    80000ec4:	e422                	sd	s0,8(sp)
    80000ec6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000ec8:	ce11                	beqz	a2,80000ee4 <strncmp+0x22>
    80000eca:	00054783          	lbu	a5,0(a0)
    80000ece:	cf89                	beqz	a5,80000ee8 <strncmp+0x26>
    80000ed0:	0005c703          	lbu	a4,0(a1)
    80000ed4:	00f71a63          	bne	a4,a5,80000ee8 <strncmp+0x26>
    n--, p++, q++;
    80000ed8:	367d                	addiw	a2,a2,-1
    80000eda:	0505                	addi	a0,a0,1
    80000edc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000ede:	f675                	bnez	a2,80000eca <strncmp+0x8>
  if(n == 0)
    return 0;
    80000ee0:	4501                	li	a0,0
    80000ee2:	a809                	j	80000ef4 <strncmp+0x32>
    80000ee4:	4501                	li	a0,0
    80000ee6:	a039                	j	80000ef4 <strncmp+0x32>
  if(n == 0)
    80000ee8:	ca09                	beqz	a2,80000efa <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000eea:	00054503          	lbu	a0,0(a0)
    80000eee:	0005c783          	lbu	a5,0(a1)
    80000ef2:	9d1d                	subw	a0,a0,a5
}
    80000ef4:	6422                	ld	s0,8(sp)
    80000ef6:	0141                	addi	sp,sp,16
    80000ef8:	8082                	ret
    return 0;
    80000efa:	4501                	li	a0,0
    80000efc:	bfe5                	j	80000ef4 <strncmp+0x32>

0000000080000efe <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000efe:	1141                	addi	sp,sp,-16
    80000f00:	e422                	sd	s0,8(sp)
    80000f02:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000f04:	872a                	mv	a4,a0
    80000f06:	8832                	mv	a6,a2
    80000f08:	367d                	addiw	a2,a2,-1
    80000f0a:	01005963          	blez	a6,80000f1c <strncpy+0x1e>
    80000f0e:	0705                	addi	a4,a4,1
    80000f10:	0005c783          	lbu	a5,0(a1)
    80000f14:	fef70fa3          	sb	a5,-1(a4)
    80000f18:	0585                	addi	a1,a1,1
    80000f1a:	f7f5                	bnez	a5,80000f06 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000f1c:	00c05d63          	blez	a2,80000f36 <strncpy+0x38>
    80000f20:	86ba                	mv	a3,a4
    *s++ = 0;
    80000f22:	0685                	addi	a3,a3,1
    80000f24:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000f28:	fff6c793          	not	a5,a3
    80000f2c:	9fb9                	addw	a5,a5,a4
    80000f2e:	010787bb          	addw	a5,a5,a6
    80000f32:	fef048e3          	bgtz	a5,80000f22 <strncpy+0x24>
  return os;
}
    80000f36:	6422                	ld	s0,8(sp)
    80000f38:	0141                	addi	sp,sp,16
    80000f3a:	8082                	ret

0000000080000f3c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000f3c:	1141                	addi	sp,sp,-16
    80000f3e:	e422                	sd	s0,8(sp)
    80000f40:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000f42:	02c05363          	blez	a2,80000f68 <safestrcpy+0x2c>
    80000f46:	fff6069b          	addiw	a3,a2,-1
    80000f4a:	1682                	slli	a3,a3,0x20
    80000f4c:	9281                	srli	a3,a3,0x20
    80000f4e:	96ae                	add	a3,a3,a1
    80000f50:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000f52:	00d58963          	beq	a1,a3,80000f64 <safestrcpy+0x28>
    80000f56:	0585                	addi	a1,a1,1
    80000f58:	0785                	addi	a5,a5,1
    80000f5a:	fff5c703          	lbu	a4,-1(a1)
    80000f5e:	fee78fa3          	sb	a4,-1(a5)
    80000f62:	fb65                	bnez	a4,80000f52 <safestrcpy+0x16>
    ;
  *s = 0;
    80000f64:	00078023          	sb	zero,0(a5)
  return os;
}
    80000f68:	6422                	ld	s0,8(sp)
    80000f6a:	0141                	addi	sp,sp,16
    80000f6c:	8082                	ret

0000000080000f6e <strlen>:

int
strlen(const char *s)
{
    80000f6e:	1141                	addi	sp,sp,-16
    80000f70:	e422                	sd	s0,8(sp)
    80000f72:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000f74:	00054783          	lbu	a5,0(a0)
    80000f78:	cf91                	beqz	a5,80000f94 <strlen+0x26>
    80000f7a:	0505                	addi	a0,a0,1
    80000f7c:	87aa                	mv	a5,a0
    80000f7e:	4685                	li	a3,1
    80000f80:	9e89                	subw	a3,a3,a0
    80000f82:	00f6853b          	addw	a0,a3,a5
    80000f86:	0785                	addi	a5,a5,1
    80000f88:	fff7c703          	lbu	a4,-1(a5)
    80000f8c:	fb7d                	bnez	a4,80000f82 <strlen+0x14>
    ;
  return n;
}
    80000f8e:	6422                	ld	s0,8(sp)
    80000f90:	0141                	addi	sp,sp,16
    80000f92:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f94:	4501                	li	a0,0
    80000f96:	bfe5                	j	80000f8e <strlen+0x20>

0000000080000f98 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f98:	1141                	addi	sp,sp,-16
    80000f9a:	e406                	sd	ra,8(sp)
    80000f9c:	e022                	sd	s0,0(sp)
    80000f9e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000fa0:	00001097          	auipc	ra,0x1
    80000fa4:	af8080e7          	jalr	-1288(ra) # 80001a98 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000fa8:	00008717          	auipc	a4,0x8
    80000fac:	07070713          	addi	a4,a4,112 # 80009018 <started>
  if(cpuid() == 0){
    80000fb0:	c139                	beqz	a0,80000ff6 <main+0x5e>
    while(started == 0)
    80000fb2:	431c                	lw	a5,0(a4)
    80000fb4:	2781                	sext.w	a5,a5
    80000fb6:	dff5                	beqz	a5,80000fb2 <main+0x1a>
      ;
    __sync_synchronize();
    80000fb8:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000fbc:	00001097          	auipc	ra,0x1
    80000fc0:	adc080e7          	jalr	-1316(ra) # 80001a98 <cpuid>
    80000fc4:	85aa                	mv	a1,a0
    80000fc6:	00007517          	auipc	a0,0x7
    80000fca:	10250513          	addi	a0,a0,258 # 800080c8 <digits+0x88>
    80000fce:	fffff097          	auipc	ra,0xfffff
    80000fd2:	5ba080e7          	jalr	1466(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000fd6:	00000097          	auipc	ra,0x0
    80000fda:	0d8080e7          	jalr	216(ra) # 800010ae <kvminithart>
    trapinithart();   // install kernel trap vector
    80000fde:	00001097          	auipc	ra,0x1
    80000fe2:	7d0080e7          	jalr	2000(ra) # 800027ae <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000fe6:	00005097          	auipc	ra,0x5
    80000fea:	d5a080e7          	jalr	-678(ra) # 80005d40 <plicinithart>
  }

  scheduler();        
    80000fee:	00001097          	auipc	ra,0x1
    80000ff2:	fe0080e7          	jalr	-32(ra) # 80001fce <scheduler>
    consoleinit();
    80000ff6:	fffff097          	auipc	ra,0xfffff
    80000ffa:	45a080e7          	jalr	1114(ra) # 80000450 <consoleinit>
    printfinit();
    80000ffe:	fffff097          	auipc	ra,0xfffff
    80001002:	770080e7          	jalr	1904(ra) # 8000076e <printfinit>
    printf("\n");
    80001006:	00007517          	auipc	a0,0x7
    8000100a:	0d250513          	addi	a0,a0,210 # 800080d8 <digits+0x98>
    8000100e:	fffff097          	auipc	ra,0xfffff
    80001012:	57a080e7          	jalr	1402(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80001016:	00007517          	auipc	a0,0x7
    8000101a:	09a50513          	addi	a0,a0,154 # 800080b0 <digits+0x70>
    8000101e:	fffff097          	auipc	ra,0xfffff
    80001022:	56a080e7          	jalr	1386(ra) # 80000588 <printf>
    printf("\n");
    80001026:	00007517          	auipc	a0,0x7
    8000102a:	0b250513          	addi	a0,a0,178 # 800080d8 <digits+0x98>
    8000102e:	fffff097          	auipc	ra,0xfffff
    80001032:	55a080e7          	jalr	1370(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80001036:	00000097          	auipc	ra,0x0
    8000103a:	bbe080e7          	jalr	-1090(ra) # 80000bf4 <kinit>
    kvminit();       // create kernel page table
    8000103e:	00000097          	auipc	ra,0x0
    80001042:	322080e7          	jalr	802(ra) # 80001360 <kvminit>
    kvminithart();   // turn on paging
    80001046:	00000097          	auipc	ra,0x0
    8000104a:	068080e7          	jalr	104(ra) # 800010ae <kvminithart>
    procinit();      // process table
    8000104e:	00001097          	auipc	ra,0x1
    80001052:	99a080e7          	jalr	-1638(ra) # 800019e8 <procinit>
    trapinit();      // trap vectors
    80001056:	00001097          	auipc	ra,0x1
    8000105a:	730080e7          	jalr	1840(ra) # 80002786 <trapinit>
    trapinithart();  // install kernel trap vector
    8000105e:	00001097          	auipc	ra,0x1
    80001062:	750080e7          	jalr	1872(ra) # 800027ae <trapinithart>
    plicinit();      // set up interrupt controller
    80001066:	00005097          	auipc	ra,0x5
    8000106a:	cc4080e7          	jalr	-828(ra) # 80005d2a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    8000106e:	00005097          	auipc	ra,0x5
    80001072:	cd2080e7          	jalr	-814(ra) # 80005d40 <plicinithart>
    binit();         // buffer cache
    80001076:	00002097          	auipc	ra,0x2
    8000107a:	eae080e7          	jalr	-338(ra) # 80002f24 <binit>
    iinit();         // inode table
    8000107e:	00002097          	auipc	ra,0x2
    80001082:	53e080e7          	jalr	1342(ra) # 800035bc <iinit>
    fileinit();      // file table
    80001086:	00003097          	auipc	ra,0x3
    8000108a:	4e8080e7          	jalr	1256(ra) # 8000456e <fileinit>
    virtio_disk_init(); // emulated hard disk
    8000108e:	00005097          	auipc	ra,0x5
    80001092:	dd4080e7          	jalr	-556(ra) # 80005e62 <virtio_disk_init>
    userinit();      // first user process
    80001096:	00001097          	auipc	ra,0x1
    8000109a:	d06080e7          	jalr	-762(ra) # 80001d9c <userinit>
    __sync_synchronize();
    8000109e:	0ff0000f          	fence
    started = 1;
    800010a2:	4785                	li	a5,1
    800010a4:	00008717          	auipc	a4,0x8
    800010a8:	f6f72a23          	sw	a5,-140(a4) # 80009018 <started>
    800010ac:	b789                	j	80000fee <main+0x56>

00000000800010ae <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    800010ae:	1141                	addi	sp,sp,-16
    800010b0:	e422                	sd	s0,8(sp)
    800010b2:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    800010b4:	00008797          	auipc	a5,0x8
    800010b8:	f6c7b783          	ld	a5,-148(a5) # 80009020 <kernel_pagetable>
    800010bc:	83b1                	srli	a5,a5,0xc
    800010be:	577d                	li	a4,-1
    800010c0:	177e                	slli	a4,a4,0x3f
    800010c2:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    800010c4:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    800010c8:	12000073          	sfence.vma
  sfence_vma();
}
    800010cc:	6422                	ld	s0,8(sp)
    800010ce:	0141                	addi	sp,sp,16
    800010d0:	8082                	ret

00000000800010d2 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    800010d2:	7139                	addi	sp,sp,-64
    800010d4:	fc06                	sd	ra,56(sp)
    800010d6:	f822                	sd	s0,48(sp)
    800010d8:	f426                	sd	s1,40(sp)
    800010da:	f04a                	sd	s2,32(sp)
    800010dc:	ec4e                	sd	s3,24(sp)
    800010de:	e852                	sd	s4,16(sp)
    800010e0:	e456                	sd	s5,8(sp)
    800010e2:	e05a                	sd	s6,0(sp)
    800010e4:	0080                	addi	s0,sp,64
    800010e6:	84aa                	mv	s1,a0
    800010e8:	89ae                	mv	s3,a1
    800010ea:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    800010ec:	57fd                	li	a5,-1
    800010ee:	83e9                	srli	a5,a5,0x1a
    800010f0:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    800010f2:	4b31                	li	s6,12
  if(va >= MAXVA)
    800010f4:	04b7f263          	bgeu	a5,a1,80001138 <walk+0x66>
    panic("walk");
    800010f8:	00007517          	auipc	a0,0x7
    800010fc:	fe850513          	addi	a0,a0,-24 # 800080e0 <digits+0xa0>
    80001100:	fffff097          	auipc	ra,0xfffff
    80001104:	43e080e7          	jalr	1086(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001108:	060a8663          	beqz	s5,80001174 <walk+0xa2>
    8000110c:	00000097          	auipc	ra,0x0
    80001110:	8ec080e7          	jalr	-1812(ra) # 800009f8 <kalloc>
    80001114:	84aa                	mv	s1,a0
    80001116:	c529                	beqz	a0,80001160 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001118:	6605                	lui	a2,0x1
    8000111a:	4581                	li	a1,0
    8000111c:	00000097          	auipc	ra,0x0
    80001120:	cce080e7          	jalr	-818(ra) # 80000dea <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001124:	00c4d793          	srli	a5,s1,0xc
    80001128:	07aa                	slli	a5,a5,0xa
    8000112a:	0017e793          	ori	a5,a5,1
    8000112e:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001132:	3a5d                	addiw	s4,s4,-9
    80001134:	036a0063          	beq	s4,s6,80001154 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001138:	0149d933          	srl	s2,s3,s4
    8000113c:	1ff97913          	andi	s2,s2,511
    80001140:	090e                	slli	s2,s2,0x3
    80001142:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001144:	00093483          	ld	s1,0(s2)
    80001148:	0014f793          	andi	a5,s1,1
    8000114c:	dfd5                	beqz	a5,80001108 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000114e:	80a9                	srli	s1,s1,0xa
    80001150:	04b2                	slli	s1,s1,0xc
    80001152:	b7c5                	j	80001132 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001154:	00c9d513          	srli	a0,s3,0xc
    80001158:	1ff57513          	andi	a0,a0,511
    8000115c:	050e                	slli	a0,a0,0x3
    8000115e:	9526                	add	a0,a0,s1
}
    80001160:	70e2                	ld	ra,56(sp)
    80001162:	7442                	ld	s0,48(sp)
    80001164:	74a2                	ld	s1,40(sp)
    80001166:	7902                	ld	s2,32(sp)
    80001168:	69e2                	ld	s3,24(sp)
    8000116a:	6a42                	ld	s4,16(sp)
    8000116c:	6aa2                	ld	s5,8(sp)
    8000116e:	6b02                	ld	s6,0(sp)
    80001170:	6121                	addi	sp,sp,64
    80001172:	8082                	ret
        return 0;
    80001174:	4501                	li	a0,0
    80001176:	b7ed                	j	80001160 <walk+0x8e>

0000000080001178 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001178:	57fd                	li	a5,-1
    8000117a:	83e9                	srli	a5,a5,0x1a
    8000117c:	00b7f463          	bgeu	a5,a1,80001184 <walkaddr+0xc>
    return 0;
    80001180:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001182:	8082                	ret
{
    80001184:	1141                	addi	sp,sp,-16
    80001186:	e406                	sd	ra,8(sp)
    80001188:	e022                	sd	s0,0(sp)
    8000118a:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000118c:	4601                	li	a2,0
    8000118e:	00000097          	auipc	ra,0x0
    80001192:	f44080e7          	jalr	-188(ra) # 800010d2 <walk>
  if(pte == 0)
    80001196:	c105                	beqz	a0,800011b6 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001198:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000119a:	0117f693          	andi	a3,a5,17
    8000119e:	4745                	li	a4,17
    return 0;
    800011a0:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800011a2:	00e68663          	beq	a3,a4,800011ae <walkaddr+0x36>
}
    800011a6:	60a2                	ld	ra,8(sp)
    800011a8:	6402                	ld	s0,0(sp)
    800011aa:	0141                	addi	sp,sp,16
    800011ac:	8082                	ret
  pa = PTE2PA(*pte);
    800011ae:	00a7d513          	srli	a0,a5,0xa
    800011b2:	0532                	slli	a0,a0,0xc
  return pa;
    800011b4:	bfcd                	j	800011a6 <walkaddr+0x2e>
    return 0;
    800011b6:	4501                	li	a0,0
    800011b8:	b7fd                	j	800011a6 <walkaddr+0x2e>

00000000800011ba <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800011ba:	715d                	addi	sp,sp,-80
    800011bc:	e486                	sd	ra,72(sp)
    800011be:	e0a2                	sd	s0,64(sp)
    800011c0:	fc26                	sd	s1,56(sp)
    800011c2:	f84a                	sd	s2,48(sp)
    800011c4:	f44e                	sd	s3,40(sp)
    800011c6:	f052                	sd	s4,32(sp)
    800011c8:	ec56                	sd	s5,24(sp)
    800011ca:	e85a                	sd	s6,16(sp)
    800011cc:	e45e                	sd	s7,8(sp)
    800011ce:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800011d0:	c205                	beqz	a2,800011f0 <mappages+0x36>
    800011d2:	8aaa                	mv	s5,a0
    800011d4:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800011d6:	77fd                	lui	a5,0xfffff
    800011d8:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800011dc:	15fd                	addi	a1,a1,-1
    800011de:	00c589b3          	add	s3,a1,a2
    800011e2:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800011e6:	8952                	mv	s2,s4
    800011e8:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800011ec:	6b85                	lui	s7,0x1
    800011ee:	a015                	j	80001212 <mappages+0x58>
    panic("mappages: size");
    800011f0:	00007517          	auipc	a0,0x7
    800011f4:	ef850513          	addi	a0,a0,-264 # 800080e8 <digits+0xa8>
    800011f8:	fffff097          	auipc	ra,0xfffff
    800011fc:	346080e7          	jalr	838(ra) # 8000053e <panic>
      panic("mappages: remap");
    80001200:	00007517          	auipc	a0,0x7
    80001204:	ef850513          	addi	a0,a0,-264 # 800080f8 <digits+0xb8>
    80001208:	fffff097          	auipc	ra,0xfffff
    8000120c:	336080e7          	jalr	822(ra) # 8000053e <panic>
    a += PGSIZE;
    80001210:	995e                	add	s2,s2,s7
  for(;;){
    80001212:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001216:	4605                	li	a2,1
    80001218:	85ca                	mv	a1,s2
    8000121a:	8556                	mv	a0,s5
    8000121c:	00000097          	auipc	ra,0x0
    80001220:	eb6080e7          	jalr	-330(ra) # 800010d2 <walk>
    80001224:	cd19                	beqz	a0,80001242 <mappages+0x88>
    if(*pte & PTE_V)
    80001226:	611c                	ld	a5,0(a0)
    80001228:	8b85                	andi	a5,a5,1
    8000122a:	fbf9                	bnez	a5,80001200 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000122c:	80b1                	srli	s1,s1,0xc
    8000122e:	04aa                	slli	s1,s1,0xa
    80001230:	0164e4b3          	or	s1,s1,s6
    80001234:	0014e493          	ori	s1,s1,1
    80001238:	e104                	sd	s1,0(a0)
    if(a == last)
    8000123a:	fd391be3          	bne	s2,s3,80001210 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    8000123e:	4501                	li	a0,0
    80001240:	a011                	j	80001244 <mappages+0x8a>
      return -1;
    80001242:	557d                	li	a0,-1
}
    80001244:	60a6                	ld	ra,72(sp)
    80001246:	6406                	ld	s0,64(sp)
    80001248:	74e2                	ld	s1,56(sp)
    8000124a:	7942                	ld	s2,48(sp)
    8000124c:	79a2                	ld	s3,40(sp)
    8000124e:	7a02                	ld	s4,32(sp)
    80001250:	6ae2                	ld	s5,24(sp)
    80001252:	6b42                	ld	s6,16(sp)
    80001254:	6ba2                	ld	s7,8(sp)
    80001256:	6161                	addi	sp,sp,80
    80001258:	8082                	ret

000000008000125a <kvmmap>:
{
    8000125a:	1141                	addi	sp,sp,-16
    8000125c:	e406                	sd	ra,8(sp)
    8000125e:	e022                	sd	s0,0(sp)
    80001260:	0800                	addi	s0,sp,16
    80001262:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001264:	86b2                	mv	a3,a2
    80001266:	863e                	mv	a2,a5
    80001268:	00000097          	auipc	ra,0x0
    8000126c:	f52080e7          	jalr	-174(ra) # 800011ba <mappages>
    80001270:	e509                	bnez	a0,8000127a <kvmmap+0x20>
}
    80001272:	60a2                	ld	ra,8(sp)
    80001274:	6402                	ld	s0,0(sp)
    80001276:	0141                	addi	sp,sp,16
    80001278:	8082                	ret
    panic("kvmmap");
    8000127a:	00007517          	auipc	a0,0x7
    8000127e:	e8e50513          	addi	a0,a0,-370 # 80008108 <digits+0xc8>
    80001282:	fffff097          	auipc	ra,0xfffff
    80001286:	2bc080e7          	jalr	700(ra) # 8000053e <panic>

000000008000128a <kvmmake>:
{
    8000128a:	1101                	addi	sp,sp,-32
    8000128c:	ec06                	sd	ra,24(sp)
    8000128e:	e822                	sd	s0,16(sp)
    80001290:	e426                	sd	s1,8(sp)
    80001292:	e04a                	sd	s2,0(sp)
    80001294:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001296:	fffff097          	auipc	ra,0xfffff
    8000129a:	762080e7          	jalr	1890(ra) # 800009f8 <kalloc>
    8000129e:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800012a0:	6605                	lui	a2,0x1
    800012a2:	4581                	li	a1,0
    800012a4:	00000097          	auipc	ra,0x0
    800012a8:	b46080e7          	jalr	-1210(ra) # 80000dea <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800012ac:	4719                	li	a4,6
    800012ae:	6685                	lui	a3,0x1
    800012b0:	10000637          	lui	a2,0x10000
    800012b4:	100005b7          	lui	a1,0x10000
    800012b8:	8526                	mv	a0,s1
    800012ba:	00000097          	auipc	ra,0x0
    800012be:	fa0080e7          	jalr	-96(ra) # 8000125a <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800012c2:	4719                	li	a4,6
    800012c4:	6685                	lui	a3,0x1
    800012c6:	10001637          	lui	a2,0x10001
    800012ca:	100015b7          	lui	a1,0x10001
    800012ce:	8526                	mv	a0,s1
    800012d0:	00000097          	auipc	ra,0x0
    800012d4:	f8a080e7          	jalr	-118(ra) # 8000125a <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012d8:	4719                	li	a4,6
    800012da:	004006b7          	lui	a3,0x400
    800012de:	0c000637          	lui	a2,0xc000
    800012e2:	0c0005b7          	lui	a1,0xc000
    800012e6:	8526                	mv	a0,s1
    800012e8:	00000097          	auipc	ra,0x0
    800012ec:	f72080e7          	jalr	-142(ra) # 8000125a <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800012f0:	00007917          	auipc	s2,0x7
    800012f4:	d1090913          	addi	s2,s2,-752 # 80008000 <etext>
    800012f8:	4729                	li	a4,10
    800012fa:	80007697          	auipc	a3,0x80007
    800012fe:	d0668693          	addi	a3,a3,-762 # 8000 <_entry-0x7fff8000>
    80001302:	4605                	li	a2,1
    80001304:	067e                	slli	a2,a2,0x1f
    80001306:	85b2                	mv	a1,a2
    80001308:	8526                	mv	a0,s1
    8000130a:	00000097          	auipc	ra,0x0
    8000130e:	f50080e7          	jalr	-176(ra) # 8000125a <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001312:	4719                	li	a4,6
    80001314:	46c5                	li	a3,17
    80001316:	06ee                	slli	a3,a3,0x1b
    80001318:	412686b3          	sub	a3,a3,s2
    8000131c:	864a                	mv	a2,s2
    8000131e:	85ca                	mv	a1,s2
    80001320:	8526                	mv	a0,s1
    80001322:	00000097          	auipc	ra,0x0
    80001326:	f38080e7          	jalr	-200(ra) # 8000125a <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000132a:	4729                	li	a4,10
    8000132c:	6685                	lui	a3,0x1
    8000132e:	00006617          	auipc	a2,0x6
    80001332:	cd260613          	addi	a2,a2,-814 # 80007000 <_trampoline>
    80001336:	040005b7          	lui	a1,0x4000
    8000133a:	15fd                	addi	a1,a1,-1
    8000133c:	05b2                	slli	a1,a1,0xc
    8000133e:	8526                	mv	a0,s1
    80001340:	00000097          	auipc	ra,0x0
    80001344:	f1a080e7          	jalr	-230(ra) # 8000125a <kvmmap>
  proc_mapstacks(kpgtbl);
    80001348:	8526                	mv	a0,s1
    8000134a:	00000097          	auipc	ra,0x0
    8000134e:	608080e7          	jalr	1544(ra) # 80001952 <proc_mapstacks>
}
    80001352:	8526                	mv	a0,s1
    80001354:	60e2                	ld	ra,24(sp)
    80001356:	6442                	ld	s0,16(sp)
    80001358:	64a2                	ld	s1,8(sp)
    8000135a:	6902                	ld	s2,0(sp)
    8000135c:	6105                	addi	sp,sp,32
    8000135e:	8082                	ret

0000000080001360 <kvminit>:
{
    80001360:	1141                	addi	sp,sp,-16
    80001362:	e406                	sd	ra,8(sp)
    80001364:	e022                	sd	s0,0(sp)
    80001366:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001368:	00000097          	auipc	ra,0x0
    8000136c:	f22080e7          	jalr	-222(ra) # 8000128a <kvmmake>
    80001370:	00008797          	auipc	a5,0x8
    80001374:	caa7b823          	sd	a0,-848(a5) # 80009020 <kernel_pagetable>
}
    80001378:	60a2                	ld	ra,8(sp)
    8000137a:	6402                	ld	s0,0(sp)
    8000137c:	0141                	addi	sp,sp,16
    8000137e:	8082                	ret

0000000080001380 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001380:	715d                	addi	sp,sp,-80
    80001382:	e486                	sd	ra,72(sp)
    80001384:	e0a2                	sd	s0,64(sp)
    80001386:	fc26                	sd	s1,56(sp)
    80001388:	f84a                	sd	s2,48(sp)
    8000138a:	f44e                	sd	s3,40(sp)
    8000138c:	f052                	sd	s4,32(sp)
    8000138e:	ec56                	sd	s5,24(sp)
    80001390:	e85a                	sd	s6,16(sp)
    80001392:	e45e                	sd	s7,8(sp)
    80001394:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001396:	03459793          	slli	a5,a1,0x34
    8000139a:	e795                	bnez	a5,800013c6 <uvmunmap+0x46>
    8000139c:	8a2a                	mv	s4,a0
    8000139e:	892e                	mv	s2,a1
    800013a0:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013a2:	0632                	slli	a2,a2,0xc
    800013a4:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800013a8:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013aa:	6b05                	lui	s6,0x1
    800013ac:	0735e863          	bltu	a1,s3,8000141c <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800013b0:	60a6                	ld	ra,72(sp)
    800013b2:	6406                	ld	s0,64(sp)
    800013b4:	74e2                	ld	s1,56(sp)
    800013b6:	7942                	ld	s2,48(sp)
    800013b8:	79a2                	ld	s3,40(sp)
    800013ba:	7a02                	ld	s4,32(sp)
    800013bc:	6ae2                	ld	s5,24(sp)
    800013be:	6b42                	ld	s6,16(sp)
    800013c0:	6ba2                	ld	s7,8(sp)
    800013c2:	6161                	addi	sp,sp,80
    800013c4:	8082                	ret
    panic("uvmunmap: not aligned");
    800013c6:	00007517          	auipc	a0,0x7
    800013ca:	d4a50513          	addi	a0,a0,-694 # 80008110 <digits+0xd0>
    800013ce:	fffff097          	auipc	ra,0xfffff
    800013d2:	170080e7          	jalr	368(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800013d6:	00007517          	auipc	a0,0x7
    800013da:	d5250513          	addi	a0,a0,-686 # 80008128 <digits+0xe8>
    800013de:	fffff097          	auipc	ra,0xfffff
    800013e2:	160080e7          	jalr	352(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800013e6:	00007517          	auipc	a0,0x7
    800013ea:	d5250513          	addi	a0,a0,-686 # 80008138 <digits+0xf8>
    800013ee:	fffff097          	auipc	ra,0xfffff
    800013f2:	150080e7          	jalr	336(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800013f6:	00007517          	auipc	a0,0x7
    800013fa:	d5a50513          	addi	a0,a0,-678 # 80008150 <digits+0x110>
    800013fe:	fffff097          	auipc	ra,0xfffff
    80001402:	140080e7          	jalr	320(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    80001406:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001408:	0532                	slli	a0,a0,0xc
    8000140a:	fffff097          	auipc	ra,0xfffff
    8000140e:	702080e7          	jalr	1794(ra) # 80000b0c <kfree>
    *pte = 0;
    80001412:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001416:	995a                	add	s2,s2,s6
    80001418:	f9397ce3          	bgeu	s2,s3,800013b0 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000141c:	4601                	li	a2,0
    8000141e:	85ca                	mv	a1,s2
    80001420:	8552                	mv	a0,s4
    80001422:	00000097          	auipc	ra,0x0
    80001426:	cb0080e7          	jalr	-848(ra) # 800010d2 <walk>
    8000142a:	84aa                	mv	s1,a0
    8000142c:	d54d                	beqz	a0,800013d6 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000142e:	6108                	ld	a0,0(a0)
    80001430:	00157793          	andi	a5,a0,1
    80001434:	dbcd                	beqz	a5,800013e6 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001436:	3ff57793          	andi	a5,a0,1023
    8000143a:	fb778ee3          	beq	a5,s7,800013f6 <uvmunmap+0x76>
    if(do_free){
    8000143e:	fc0a8ae3          	beqz	s5,80001412 <uvmunmap+0x92>
    80001442:	b7d1                	j	80001406 <uvmunmap+0x86>

0000000080001444 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001444:	1101                	addi	sp,sp,-32
    80001446:	ec06                	sd	ra,24(sp)
    80001448:	e822                	sd	s0,16(sp)
    8000144a:	e426                	sd	s1,8(sp)
    8000144c:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	5aa080e7          	jalr	1450(ra) # 800009f8 <kalloc>
    80001456:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001458:	c519                	beqz	a0,80001466 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	98c080e7          	jalr	-1652(ra) # 80000dea <memset>
  return pagetable;
}
    80001466:	8526                	mv	a0,s1
    80001468:	60e2                	ld	ra,24(sp)
    8000146a:	6442                	ld	s0,16(sp)
    8000146c:	64a2                	ld	s1,8(sp)
    8000146e:	6105                	addi	sp,sp,32
    80001470:	8082                	ret

0000000080001472 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001472:	7179                	addi	sp,sp,-48
    80001474:	f406                	sd	ra,40(sp)
    80001476:	f022                	sd	s0,32(sp)
    80001478:	ec26                	sd	s1,24(sp)
    8000147a:	e84a                	sd	s2,16(sp)
    8000147c:	e44e                	sd	s3,8(sp)
    8000147e:	e052                	sd	s4,0(sp)
    80001480:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001482:	6785                	lui	a5,0x1
    80001484:	04f67863          	bgeu	a2,a5,800014d4 <uvminit+0x62>
    80001488:	8a2a                	mv	s4,a0
    8000148a:	89ae                	mv	s3,a1
    8000148c:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000148e:	fffff097          	auipc	ra,0xfffff
    80001492:	56a080e7          	jalr	1386(ra) # 800009f8 <kalloc>
    80001496:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001498:	6605                	lui	a2,0x1
    8000149a:	4581                	li	a1,0
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	94e080e7          	jalr	-1714(ra) # 80000dea <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800014a4:	4779                	li	a4,30
    800014a6:	86ca                	mv	a3,s2
    800014a8:	6605                	lui	a2,0x1
    800014aa:	4581                	li	a1,0
    800014ac:	8552                	mv	a0,s4
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	d0c080e7          	jalr	-756(ra) # 800011ba <mappages>
  memmove(mem, src, sz);
    800014b6:	8626                	mv	a2,s1
    800014b8:	85ce                	mv	a1,s3
    800014ba:	854a                	mv	a0,s2
    800014bc:	00000097          	auipc	ra,0x0
    800014c0:	98e080e7          	jalr	-1650(ra) # 80000e4a <memmove>
}
    800014c4:	70a2                	ld	ra,40(sp)
    800014c6:	7402                	ld	s0,32(sp)
    800014c8:	64e2                	ld	s1,24(sp)
    800014ca:	6942                	ld	s2,16(sp)
    800014cc:	69a2                	ld	s3,8(sp)
    800014ce:	6a02                	ld	s4,0(sp)
    800014d0:	6145                	addi	sp,sp,48
    800014d2:	8082                	ret
    panic("inituvm: more than a page");
    800014d4:	00007517          	auipc	a0,0x7
    800014d8:	c9450513          	addi	a0,a0,-876 # 80008168 <digits+0x128>
    800014dc:	fffff097          	auipc	ra,0xfffff
    800014e0:	062080e7          	jalr	98(ra) # 8000053e <panic>

00000000800014e4 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800014e4:	1101                	addi	sp,sp,-32
    800014e6:	ec06                	sd	ra,24(sp)
    800014e8:	e822                	sd	s0,16(sp)
    800014ea:	e426                	sd	s1,8(sp)
    800014ec:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800014ee:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800014f0:	00b67d63          	bgeu	a2,a1,8000150a <uvmdealloc+0x26>
    800014f4:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800014f6:	6785                	lui	a5,0x1
    800014f8:	17fd                	addi	a5,a5,-1
    800014fa:	00f60733          	add	a4,a2,a5
    800014fe:	767d                	lui	a2,0xfffff
    80001500:	8f71                	and	a4,a4,a2
    80001502:	97ae                	add	a5,a5,a1
    80001504:	8ff1                	and	a5,a5,a2
    80001506:	00f76863          	bltu	a4,a5,80001516 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000150a:	8526                	mv	a0,s1
    8000150c:	60e2                	ld	ra,24(sp)
    8000150e:	6442                	ld	s0,16(sp)
    80001510:	64a2                	ld	s1,8(sp)
    80001512:	6105                	addi	sp,sp,32
    80001514:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001516:	8f99                	sub	a5,a5,a4
    80001518:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000151a:	4685                	li	a3,1
    8000151c:	0007861b          	sext.w	a2,a5
    80001520:	85ba                	mv	a1,a4
    80001522:	00000097          	auipc	ra,0x0
    80001526:	e5e080e7          	jalr	-418(ra) # 80001380 <uvmunmap>
    8000152a:	b7c5                	j	8000150a <uvmdealloc+0x26>

000000008000152c <uvmalloc>:
  if(newsz < oldsz)
    8000152c:	0ab66163          	bltu	a2,a1,800015ce <uvmalloc+0xa2>
{
    80001530:	7139                	addi	sp,sp,-64
    80001532:	fc06                	sd	ra,56(sp)
    80001534:	f822                	sd	s0,48(sp)
    80001536:	f426                	sd	s1,40(sp)
    80001538:	f04a                	sd	s2,32(sp)
    8000153a:	ec4e                	sd	s3,24(sp)
    8000153c:	e852                	sd	s4,16(sp)
    8000153e:	e456                	sd	s5,8(sp)
    80001540:	0080                	addi	s0,sp,64
    80001542:	8aaa                	mv	s5,a0
    80001544:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001546:	6985                	lui	s3,0x1
    80001548:	19fd                	addi	s3,s3,-1
    8000154a:	95ce                	add	a1,a1,s3
    8000154c:	79fd                	lui	s3,0xfffff
    8000154e:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001552:	08c9f063          	bgeu	s3,a2,800015d2 <uvmalloc+0xa6>
    80001556:	894e                	mv	s2,s3
    mem = kalloc();
    80001558:	fffff097          	auipc	ra,0xfffff
    8000155c:	4a0080e7          	jalr	1184(ra) # 800009f8 <kalloc>
    80001560:	84aa                	mv	s1,a0
    if(mem == 0){
    80001562:	c51d                	beqz	a0,80001590 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001564:	6605                	lui	a2,0x1
    80001566:	4581                	li	a1,0
    80001568:	00000097          	auipc	ra,0x0
    8000156c:	882080e7          	jalr	-1918(ra) # 80000dea <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001570:	4779                	li	a4,30
    80001572:	86a6                	mv	a3,s1
    80001574:	6605                	lui	a2,0x1
    80001576:	85ca                	mv	a1,s2
    80001578:	8556                	mv	a0,s5
    8000157a:	00000097          	auipc	ra,0x0
    8000157e:	c40080e7          	jalr	-960(ra) # 800011ba <mappages>
    80001582:	e905                	bnez	a0,800015b2 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001584:	6785                	lui	a5,0x1
    80001586:	993e                	add	s2,s2,a5
    80001588:	fd4968e3          	bltu	s2,s4,80001558 <uvmalloc+0x2c>
  return newsz;
    8000158c:	8552                	mv	a0,s4
    8000158e:	a809                	j	800015a0 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001590:	864e                	mv	a2,s3
    80001592:	85ca                	mv	a1,s2
    80001594:	8556                	mv	a0,s5
    80001596:	00000097          	auipc	ra,0x0
    8000159a:	f4e080e7          	jalr	-178(ra) # 800014e4 <uvmdealloc>
      return 0;
    8000159e:	4501                	li	a0,0
}
    800015a0:	70e2                	ld	ra,56(sp)
    800015a2:	7442                	ld	s0,48(sp)
    800015a4:	74a2                	ld	s1,40(sp)
    800015a6:	7902                	ld	s2,32(sp)
    800015a8:	69e2                	ld	s3,24(sp)
    800015aa:	6a42                	ld	s4,16(sp)
    800015ac:	6aa2                	ld	s5,8(sp)
    800015ae:	6121                	addi	sp,sp,64
    800015b0:	8082                	ret
      kfree(mem);
    800015b2:	8526                	mv	a0,s1
    800015b4:	fffff097          	auipc	ra,0xfffff
    800015b8:	558080e7          	jalr	1368(ra) # 80000b0c <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800015bc:	864e                	mv	a2,s3
    800015be:	85ca                	mv	a1,s2
    800015c0:	8556                	mv	a0,s5
    800015c2:	00000097          	auipc	ra,0x0
    800015c6:	f22080e7          	jalr	-222(ra) # 800014e4 <uvmdealloc>
      return 0;
    800015ca:	4501                	li	a0,0
    800015cc:	bfd1                	j	800015a0 <uvmalloc+0x74>
    return oldsz;
    800015ce:	852e                	mv	a0,a1
}
    800015d0:	8082                	ret
  return newsz;
    800015d2:	8532                	mv	a0,a2
    800015d4:	b7f1                	j	800015a0 <uvmalloc+0x74>

00000000800015d6 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800015d6:	7179                	addi	sp,sp,-48
    800015d8:	f406                	sd	ra,40(sp)
    800015da:	f022                	sd	s0,32(sp)
    800015dc:	ec26                	sd	s1,24(sp)
    800015de:	e84a                	sd	s2,16(sp)
    800015e0:	e44e                	sd	s3,8(sp)
    800015e2:	e052                	sd	s4,0(sp)
    800015e4:	1800                	addi	s0,sp,48
    800015e6:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800015e8:	84aa                	mv	s1,a0
    800015ea:	6905                	lui	s2,0x1
    800015ec:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015ee:	4985                	li	s3,1
    800015f0:	a821                	j	80001608 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800015f2:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800015f4:	0532                	slli	a0,a0,0xc
    800015f6:	00000097          	auipc	ra,0x0
    800015fa:	fe0080e7          	jalr	-32(ra) # 800015d6 <freewalk>
      pagetable[i] = 0;
    800015fe:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001602:	04a1                	addi	s1,s1,8
    80001604:	03248163          	beq	s1,s2,80001626 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001608:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000160a:	00f57793          	andi	a5,a0,15
    8000160e:	ff3782e3          	beq	a5,s3,800015f2 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001612:	8905                	andi	a0,a0,1
    80001614:	d57d                	beqz	a0,80001602 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001616:	00007517          	auipc	a0,0x7
    8000161a:	b7250513          	addi	a0,a0,-1166 # 80008188 <digits+0x148>
    8000161e:	fffff097          	auipc	ra,0xfffff
    80001622:	f20080e7          	jalr	-224(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    80001626:	8552                	mv	a0,s4
    80001628:	fffff097          	auipc	ra,0xfffff
    8000162c:	4e4080e7          	jalr	1252(ra) # 80000b0c <kfree>
}
    80001630:	70a2                	ld	ra,40(sp)
    80001632:	7402                	ld	s0,32(sp)
    80001634:	64e2                	ld	s1,24(sp)
    80001636:	6942                	ld	s2,16(sp)
    80001638:	69a2                	ld	s3,8(sp)
    8000163a:	6a02                	ld	s4,0(sp)
    8000163c:	6145                	addi	sp,sp,48
    8000163e:	8082                	ret

0000000080001640 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001640:	1101                	addi	sp,sp,-32
    80001642:	ec06                	sd	ra,24(sp)
    80001644:	e822                	sd	s0,16(sp)
    80001646:	e426                	sd	s1,8(sp)
    80001648:	1000                	addi	s0,sp,32
    8000164a:	84aa                	mv	s1,a0
  if(sz > 0)
    8000164c:	e999                	bnez	a1,80001662 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000164e:	8526                	mv	a0,s1
    80001650:	00000097          	auipc	ra,0x0
    80001654:	f86080e7          	jalr	-122(ra) # 800015d6 <freewalk>
}
    80001658:	60e2                	ld	ra,24(sp)
    8000165a:	6442                	ld	s0,16(sp)
    8000165c:	64a2                	ld	s1,8(sp)
    8000165e:	6105                	addi	sp,sp,32
    80001660:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001662:	6605                	lui	a2,0x1
    80001664:	167d                	addi	a2,a2,-1
    80001666:	962e                	add	a2,a2,a1
    80001668:	4685                	li	a3,1
    8000166a:	8231                	srli	a2,a2,0xc
    8000166c:	4581                	li	a1,0
    8000166e:	00000097          	auipc	ra,0x0
    80001672:	d12080e7          	jalr	-750(ra) # 80001380 <uvmunmap>
    80001676:	bfe1                	j	8000164e <uvmfree+0xe>

0000000080001678 <uvmcopy>:
uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{
  pte_t *pte;
  uint64 va, pa;

  for (va = 0; va < sz; va += PGSIZE) {
    80001678:	c271                	beqz	a2,8000173c <uvmcopy+0xc4>
{
    8000167a:	7139                	addi	sp,sp,-64
    8000167c:	fc06                	sd	ra,56(sp)
    8000167e:	f822                	sd	s0,48(sp)
    80001680:	f426                	sd	s1,40(sp)
    80001682:	f04a                	sd	s2,32(sp)
    80001684:	ec4e                	sd	s3,24(sp)
    80001686:	e852                	sd	s4,16(sp)
    80001688:	e456                	sd	s5,8(sp)
    8000168a:	0080                	addi	s0,sp,64
    8000168c:	8aaa                	mv	s5,a0
    8000168e:	8a2e                	mv	s4,a1
    80001690:	89b2                	mv	s3,a2
  for (va = 0; va < sz; va += PGSIZE) {
    80001692:	4481                	li	s1,0
    80001694:	a0b9                	j	800016e2 <uvmcopy+0x6a>
    
    if ((pte = walk(old, va, 0)) == 0) 
      panic("uvmcopy: pte should exist");
    80001696:	00007517          	auipc	a0,0x7
    8000169a:	b0250513          	addi	a0,a0,-1278 # 80008198 <digits+0x158>
    8000169e:	fffff097          	auipc	ra,0xfffff
    800016a2:	ea0080e7          	jalr	-352(ra) # 8000053e <panic>
    if((*pte & PTE_V) == 0)
      panic("uvmcopy: page not present");
    800016a6:	00007517          	auipc	a0,0x7
    800016aa:	b1250513          	addi	a0,a0,-1262 # 800081b8 <digits+0x178>
    800016ae:	fffff097          	auipc	ra,0xfffff
    800016b2:	e90080e7          	jalr	-368(ra) # 8000053e <panic>
    pa = PTE2PA(*pte);

    if (*pte & PTE_W)
      *pte = (*pte | PTE_COW) & ~PTE_W;

    if(mappages(new, va, PGSIZE, pa, (uint)PTE_FLAGS(*pte)) < 0)
    800016b6:	6118                	ld	a4,0(a0)
    800016b8:	3ff77713          	andi	a4,a4,1023
    800016bc:	86ca                	mv	a3,s2
    800016be:	6605                	lui	a2,0x1
    800016c0:	85a6                	mv	a1,s1
    800016c2:	8552                	mv	a0,s4
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	af6080e7          	jalr	-1290(ra) # 800011ba <mappages>
    800016cc:	04054363          	bltz	a0,80001712 <uvmcopy+0x9a>
      goto err;

    reference_add(pa);
    800016d0:	854a                	mv	a0,s2
    800016d2:	fffff097          	auipc	ra,0xfffff
    800016d6:	39e080e7          	jalr	926(ra) # 80000a70 <reference_add>
  for (va = 0; va < sz; va += PGSIZE) {
    800016da:	6785                	lui	a5,0x1
    800016dc:	94be                	add	s1,s1,a5
    800016de:	0534fd63          	bgeu	s1,s3,80001738 <uvmcopy+0xc0>
    if ((pte = walk(old, va, 0)) == 0) 
    800016e2:	4601                	li	a2,0
    800016e4:	85a6                	mv	a1,s1
    800016e6:	8556                	mv	a0,s5
    800016e8:	00000097          	auipc	ra,0x0
    800016ec:	9ea080e7          	jalr	-1558(ra) # 800010d2 <walk>
    800016f0:	d15d                	beqz	a0,80001696 <uvmcopy+0x1e>
    if((*pte & PTE_V) == 0)
    800016f2:	611c                	ld	a5,0(a0)
    800016f4:	0017f713          	andi	a4,a5,1
    800016f8:	d75d                	beqz	a4,800016a6 <uvmcopy+0x2e>
    pa = PTE2PA(*pte);
    800016fa:	00a7d913          	srli	s2,a5,0xa
    800016fe:	0932                	slli	s2,s2,0xc
    if (*pte & PTE_W)
    80001700:	0047f713          	andi	a4,a5,4
    80001704:	db4d                	beqz	a4,800016b6 <uvmcopy+0x3e>
      *pte = (*pte | PTE_COW) & ~PTE_W;
    80001706:	dfb7f793          	andi	a5,a5,-517
    8000170a:	2007e793          	ori	a5,a5,512
    8000170e:	e11c                	sd	a5,0(a0)
    80001710:	b75d                	j	800016b6 <uvmcopy+0x3e>
  }
  return 0;

  err:
  uvmunmap(new, 0, va / PGSIZE, 1);
    80001712:	4685                	li	a3,1
    80001714:	00c4d613          	srli	a2,s1,0xc
    80001718:	4581                	li	a1,0
    8000171a:	8552                	mv	a0,s4
    8000171c:	00000097          	auipc	ra,0x0
    80001720:	c64080e7          	jalr	-924(ra) # 80001380 <uvmunmap>
  return -1;
    80001724:	557d                	li	a0,-1
}
    80001726:	70e2                	ld	ra,56(sp)
    80001728:	7442                	ld	s0,48(sp)
    8000172a:	74a2                	ld	s1,40(sp)
    8000172c:	7902                	ld	s2,32(sp)
    8000172e:	69e2                	ld	s3,24(sp)
    80001730:	6a42                	ld	s4,16(sp)
    80001732:	6aa2                	ld	s5,8(sp)
    80001734:	6121                	addi	sp,sp,64
    80001736:	8082                	ret
  return 0;
    80001738:	4501                	li	a0,0
    8000173a:	b7f5                	j	80001726 <uvmcopy+0xae>
    8000173c:	4501                	li	a0,0
}
    8000173e:	8082                	ret

0000000080001740 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001740:	1141                	addi	sp,sp,-16
    80001742:	e406                	sd	ra,8(sp)
    80001744:	e022                	sd	s0,0(sp)
    80001746:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001748:	4601                	li	a2,0
    8000174a:	00000097          	auipc	ra,0x0
    8000174e:	988080e7          	jalr	-1656(ra) # 800010d2 <walk>
  if(pte == 0)
    80001752:	c901                	beqz	a0,80001762 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001754:	611c                	ld	a5,0(a0)
    80001756:	9bbd                	andi	a5,a5,-17
    80001758:	e11c                	sd	a5,0(a0)
}
    8000175a:	60a2                	ld	ra,8(sp)
    8000175c:	6402                	ld	s0,0(sp)
    8000175e:	0141                	addi	sp,sp,16
    80001760:	8082                	ret
    panic("uvmclear");
    80001762:	00007517          	auipc	a0,0x7
    80001766:	a7650513          	addi	a0,a0,-1418 # 800081d8 <digits+0x198>
    8000176a:	fffff097          	auipc	ra,0xfffff
    8000176e:	dd4080e7          	jalr	-556(ra) # 8000053e <panic>

0000000080001772 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001772:	cebd                	beqz	a3,800017f0 <copyout+0x7e>
{
    80001774:	715d                	addi	sp,sp,-80
    80001776:	e486                	sd	ra,72(sp)
    80001778:	e0a2                	sd	s0,64(sp)
    8000177a:	fc26                	sd	s1,56(sp)
    8000177c:	f84a                	sd	s2,48(sp)
    8000177e:	f44e                	sd	s3,40(sp)
    80001780:	f052                	sd	s4,32(sp)
    80001782:	ec56                	sd	s5,24(sp)
    80001784:	e85a                	sd	s6,16(sp)
    80001786:	e45e                	sd	s7,8(sp)
    80001788:	e062                	sd	s8,0(sp)
    8000178a:	0880                	addi	s0,sp,80
    8000178c:	8b2a                	mv	s6,a0
    8000178e:	892e                	mv	s2,a1
    80001790:	8ab2                	mv	s5,a2
    80001792:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(dstva);
    80001794:	7c7d                	lui	s8,0xfffff
    if (cow_handle(pagetable, va0) < 0)
      return -1;
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001796:	6b85                	lui	s7,0x1
    80001798:	a015                	j	800017bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000179a:	41390933          	sub	s2,s2,s3
    8000179e:	0004861b          	sext.w	a2,s1
    800017a2:	85d6                	mv	a1,s5
    800017a4:	954a                	add	a0,a0,s2
    800017a6:	fffff097          	auipc	ra,0xfffff
    800017aa:	6a4080e7          	jalr	1700(ra) # 80000e4a <memmove>

    len -= n;
    800017ae:	409a0a33          	sub	s4,s4,s1
    src += n;
    800017b2:	9aa6                	add	s5,s5,s1
    dstva = va0 + PGSIZE;
    800017b4:	01798933          	add	s2,s3,s7
  while(len > 0){
    800017b8:	020a0a63          	beqz	s4,800017ec <copyout+0x7a>
    va0 = PGROUNDDOWN(dstva);
    800017bc:	018979b3          	and	s3,s2,s8
    if (cow_handle(pagetable, va0) < 0)
    800017c0:	85ce                	mv	a1,s3
    800017c2:	855a                	mv	a0,s6
    800017c4:	00001097          	auipc	ra,0x1
    800017c8:	f24080e7          	jalr	-220(ra) # 800026e8 <cow_handle>
    800017cc:	02054463          	bltz	a0,800017f4 <copyout+0x82>
    pa0 = walkaddr(pagetable, va0);
    800017d0:	85ce                	mv	a1,s3
    800017d2:	855a                	mv	a0,s6
    800017d4:	00000097          	auipc	ra,0x0
    800017d8:	9a4080e7          	jalr	-1628(ra) # 80001178 <walkaddr>
    if(pa0 == 0)
    800017dc:	c90d                	beqz	a0,8000180e <copyout+0x9c>
    n = PGSIZE - (dstva - va0);
    800017de:	412984b3          	sub	s1,s3,s2
    800017e2:	94de                	add	s1,s1,s7
    if(n > len)
    800017e4:	fa9a7be3          	bgeu	s4,s1,8000179a <copyout+0x28>
    800017e8:	84d2                	mv	s1,s4
    800017ea:	bf45                	j	8000179a <copyout+0x28>
  }
  return 0;
    800017ec:	4501                	li	a0,0
    800017ee:	a021                	j	800017f6 <copyout+0x84>
    800017f0:	4501                	li	a0,0
}
    800017f2:	8082                	ret
      return -1;
    800017f4:	557d                	li	a0,-1
}
    800017f6:	60a6                	ld	ra,72(sp)
    800017f8:	6406                	ld	s0,64(sp)
    800017fa:	74e2                	ld	s1,56(sp)
    800017fc:	7942                	ld	s2,48(sp)
    800017fe:	79a2                	ld	s3,40(sp)
    80001800:	7a02                	ld	s4,32(sp)
    80001802:	6ae2                	ld	s5,24(sp)
    80001804:	6b42                	ld	s6,16(sp)
    80001806:	6ba2                	ld	s7,8(sp)
    80001808:	6c02                	ld	s8,0(sp)
    8000180a:	6161                	addi	sp,sp,80
    8000180c:	8082                	ret
      return -1;
    8000180e:	557d                	li	a0,-1
    80001810:	b7dd                	j	800017f6 <copyout+0x84>

0000000080001812 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001812:	c6bd                	beqz	a3,80001880 <copyin+0x6e>
{
    80001814:	715d                	addi	sp,sp,-80
    80001816:	e486                	sd	ra,72(sp)
    80001818:	e0a2                	sd	s0,64(sp)
    8000181a:	fc26                	sd	s1,56(sp)
    8000181c:	f84a                	sd	s2,48(sp)
    8000181e:	f44e                	sd	s3,40(sp)
    80001820:	f052                	sd	s4,32(sp)
    80001822:	ec56                	sd	s5,24(sp)
    80001824:	e85a                	sd	s6,16(sp)
    80001826:	e45e                	sd	s7,8(sp)
    80001828:	e062                	sd	s8,0(sp)
    8000182a:	0880                	addi	s0,sp,80
    8000182c:	8b2a                	mv	s6,a0
    8000182e:	8a2e                	mv	s4,a1
    80001830:	8c32                	mv	s8,a2
    80001832:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001834:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001836:	6a85                	lui	s5,0x1
    80001838:	a015                	j	8000185c <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000183a:	9562                	add	a0,a0,s8
    8000183c:	0004861b          	sext.w	a2,s1
    80001840:	412505b3          	sub	a1,a0,s2
    80001844:	8552                	mv	a0,s4
    80001846:	fffff097          	auipc	ra,0xfffff
    8000184a:	604080e7          	jalr	1540(ra) # 80000e4a <memmove>

    len -= n;
    8000184e:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001852:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001854:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001858:	02098263          	beqz	s3,8000187c <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    8000185c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001860:	85ca                	mv	a1,s2
    80001862:	855a                	mv	a0,s6
    80001864:	00000097          	auipc	ra,0x0
    80001868:	914080e7          	jalr	-1772(ra) # 80001178 <walkaddr>
    if(pa0 == 0)
    8000186c:	cd01                	beqz	a0,80001884 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000186e:	418904b3          	sub	s1,s2,s8
    80001872:	94d6                	add	s1,s1,s5
    if(n > len)
    80001874:	fc99f3e3          	bgeu	s3,s1,8000183a <copyin+0x28>
    80001878:	84ce                	mv	s1,s3
    8000187a:	b7c1                	j	8000183a <copyin+0x28>
  }
  return 0;
    8000187c:	4501                	li	a0,0
    8000187e:	a021                	j	80001886 <copyin+0x74>
    80001880:	4501                	li	a0,0
}
    80001882:	8082                	ret
      return -1;
    80001884:	557d                	li	a0,-1
}
    80001886:	60a6                	ld	ra,72(sp)
    80001888:	6406                	ld	s0,64(sp)
    8000188a:	74e2                	ld	s1,56(sp)
    8000188c:	7942                	ld	s2,48(sp)
    8000188e:	79a2                	ld	s3,40(sp)
    80001890:	7a02                	ld	s4,32(sp)
    80001892:	6ae2                	ld	s5,24(sp)
    80001894:	6b42                	ld	s6,16(sp)
    80001896:	6ba2                	ld	s7,8(sp)
    80001898:	6c02                	ld	s8,0(sp)
    8000189a:	6161                	addi	sp,sp,80
    8000189c:	8082                	ret

000000008000189e <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000189e:	c6c5                	beqz	a3,80001946 <copyinstr+0xa8>
{
    800018a0:	715d                	addi	sp,sp,-80
    800018a2:	e486                	sd	ra,72(sp)
    800018a4:	e0a2                	sd	s0,64(sp)
    800018a6:	fc26                	sd	s1,56(sp)
    800018a8:	f84a                	sd	s2,48(sp)
    800018aa:	f44e                	sd	s3,40(sp)
    800018ac:	f052                	sd	s4,32(sp)
    800018ae:	ec56                	sd	s5,24(sp)
    800018b0:	e85a                	sd	s6,16(sp)
    800018b2:	e45e                	sd	s7,8(sp)
    800018b4:	0880                	addi	s0,sp,80
    800018b6:	8a2a                	mv	s4,a0
    800018b8:	8b2e                	mv	s6,a1
    800018ba:	8bb2                	mv	s7,a2
    800018bc:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800018be:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018c0:	6985                	lui	s3,0x1
    800018c2:	a035                	j	800018ee <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800018c4:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800018c8:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800018ca:	0017b793          	seqz	a5,a5
    800018ce:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800018d2:	60a6                	ld	ra,72(sp)
    800018d4:	6406                	ld	s0,64(sp)
    800018d6:	74e2                	ld	s1,56(sp)
    800018d8:	7942                	ld	s2,48(sp)
    800018da:	79a2                	ld	s3,40(sp)
    800018dc:	7a02                	ld	s4,32(sp)
    800018de:	6ae2                	ld	s5,24(sp)
    800018e0:	6b42                	ld	s6,16(sp)
    800018e2:	6ba2                	ld	s7,8(sp)
    800018e4:	6161                	addi	sp,sp,80
    800018e6:	8082                	ret
    srcva = va0 + PGSIZE;
    800018e8:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800018ec:	c8a9                	beqz	s1,8000193e <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800018ee:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800018f2:	85ca                	mv	a1,s2
    800018f4:	8552                	mv	a0,s4
    800018f6:	00000097          	auipc	ra,0x0
    800018fa:	882080e7          	jalr	-1918(ra) # 80001178 <walkaddr>
    if(pa0 == 0)
    800018fe:	c131                	beqz	a0,80001942 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001900:	41790833          	sub	a6,s2,s7
    80001904:	984e                	add	a6,a6,s3
    if(n > max)
    80001906:	0104f363          	bgeu	s1,a6,8000190c <copyinstr+0x6e>
    8000190a:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000190c:	955e                	add	a0,a0,s7
    8000190e:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001912:	fc080be3          	beqz	a6,800018e8 <copyinstr+0x4a>
    80001916:	985a                	add	a6,a6,s6
    80001918:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000191a:	41650633          	sub	a2,a0,s6
    8000191e:	14fd                	addi	s1,s1,-1
    80001920:	9b26                	add	s6,s6,s1
    80001922:	00f60733          	add	a4,a2,a5
    80001926:	00074703          	lbu	a4,0(a4)
    8000192a:	df49                	beqz	a4,800018c4 <copyinstr+0x26>
        *dst = *p;
    8000192c:	00e78023          	sb	a4,0(a5)
      --max;
    80001930:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001934:	0785                	addi	a5,a5,1
    while(n > 0){
    80001936:	ff0796e3          	bne	a5,a6,80001922 <copyinstr+0x84>
      dst++;
    8000193a:	8b42                	mv	s6,a6
    8000193c:	b775                	j	800018e8 <copyinstr+0x4a>
    8000193e:	4781                	li	a5,0
    80001940:	b769                	j	800018ca <copyinstr+0x2c>
      return -1;
    80001942:	557d                	li	a0,-1
    80001944:	b779                	j	800018d2 <copyinstr+0x34>
  int got_null = 0;
    80001946:	4781                	li	a5,0
  if(got_null){
    80001948:	0017b793          	seqz	a5,a5
    8000194c:	40f00533          	neg	a0,a5
}
    80001950:	8082                	ret

0000000080001952 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001952:	7139                	addi	sp,sp,-64
    80001954:	fc06                	sd	ra,56(sp)
    80001956:	f822                	sd	s0,48(sp)
    80001958:	f426                	sd	s1,40(sp)
    8000195a:	f04a                	sd	s2,32(sp)
    8000195c:	ec4e                	sd	s3,24(sp)
    8000195e:	e852                	sd	s4,16(sp)
    80001960:	e456                	sd	s5,8(sp)
    80001962:	e05a                	sd	s6,0(sp)
    80001964:	0080                	addi	s0,sp,64
    80001966:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001968:	00030497          	auipc	s1,0x30
    8000196c:	d8048493          	addi	s1,s1,-640 # 800316e8 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001970:	8b26                	mv	s6,s1
    80001972:	00006a97          	auipc	s5,0x6
    80001976:	68ea8a93          	addi	s5,s5,1678 # 80008000 <etext>
    8000197a:	04000937          	lui	s2,0x4000
    8000197e:	197d                	addi	s2,s2,-1
    80001980:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001982:	00035a17          	auipc	s4,0x35
    80001986:	766a0a13          	addi	s4,s4,1894 # 800370e8 <tickslock>
    char *pa = kalloc();
    8000198a:	fffff097          	auipc	ra,0xfffff
    8000198e:	06e080e7          	jalr	110(ra) # 800009f8 <kalloc>
    80001992:	862a                	mv	a2,a0
    if(pa == 0)
    80001994:	c131                	beqz	a0,800019d8 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001996:	416485b3          	sub	a1,s1,s6
    8000199a:	858d                	srai	a1,a1,0x3
    8000199c:	000ab783          	ld	a5,0(s5)
    800019a0:	02f585b3          	mul	a1,a1,a5
    800019a4:	2585                	addiw	a1,a1,1
    800019a6:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019aa:	4719                	li	a4,6
    800019ac:	6685                	lui	a3,0x1
    800019ae:	40b905b3          	sub	a1,s2,a1
    800019b2:	854e                	mv	a0,s3
    800019b4:	00000097          	auipc	ra,0x0
    800019b8:	8a6080e7          	jalr	-1882(ra) # 8000125a <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019bc:	16848493          	addi	s1,s1,360
    800019c0:	fd4495e3          	bne	s1,s4,8000198a <proc_mapstacks+0x38>
  }
}
    800019c4:	70e2                	ld	ra,56(sp)
    800019c6:	7442                	ld	s0,48(sp)
    800019c8:	74a2                	ld	s1,40(sp)
    800019ca:	7902                	ld	s2,32(sp)
    800019cc:	69e2                	ld	s3,24(sp)
    800019ce:	6a42                	ld	s4,16(sp)
    800019d0:	6aa2                	ld	s5,8(sp)
    800019d2:	6b02                	ld	s6,0(sp)
    800019d4:	6121                	addi	sp,sp,64
    800019d6:	8082                	ret
      panic("kalloc");
    800019d8:	00007517          	auipc	a0,0x7
    800019dc:	81050513          	addi	a0,a0,-2032 # 800081e8 <digits+0x1a8>
    800019e0:	fffff097          	auipc	ra,0xfffff
    800019e4:	b5e080e7          	jalr	-1186(ra) # 8000053e <panic>

00000000800019e8 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800019e8:	7139                	addi	sp,sp,-64
    800019ea:	fc06                	sd	ra,56(sp)
    800019ec:	f822                	sd	s0,48(sp)
    800019ee:	f426                	sd	s1,40(sp)
    800019f0:	f04a                	sd	s2,32(sp)
    800019f2:	ec4e                	sd	s3,24(sp)
    800019f4:	e852                	sd	s4,16(sp)
    800019f6:	e456                	sd	s5,8(sp)
    800019f8:	e05a                	sd	s6,0(sp)
    800019fa:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800019fc:	00006597          	auipc	a1,0x6
    80001a00:	7f458593          	addi	a1,a1,2036 # 800081f0 <digits+0x1b0>
    80001a04:	00030517          	auipc	a0,0x30
    80001a08:	8b450513          	addi	a0,a0,-1868 # 800312b8 <pid_lock>
    80001a0c:	fffff097          	auipc	ra,0xfffff
    80001a10:	252080e7          	jalr	594(ra) # 80000c5e <initlock>
  initlock(&wait_lock, "wait_lock");
    80001a14:	00006597          	auipc	a1,0x6
    80001a18:	7e458593          	addi	a1,a1,2020 # 800081f8 <digits+0x1b8>
    80001a1c:	00030517          	auipc	a0,0x30
    80001a20:	8b450513          	addi	a0,a0,-1868 # 800312d0 <wait_lock>
    80001a24:	fffff097          	auipc	ra,0xfffff
    80001a28:	23a080e7          	jalr	570(ra) # 80000c5e <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a2c:	00030497          	auipc	s1,0x30
    80001a30:	cbc48493          	addi	s1,s1,-836 # 800316e8 <proc>
      initlock(&p->lock, "proc");
    80001a34:	00006b17          	auipc	s6,0x6
    80001a38:	7d4b0b13          	addi	s6,s6,2004 # 80008208 <digits+0x1c8>
      p->kstack = KSTACK((int) (p - proc));
    80001a3c:	8aa6                	mv	s5,s1
    80001a3e:	00006a17          	auipc	s4,0x6
    80001a42:	5c2a0a13          	addi	s4,s4,1474 # 80008000 <etext>
    80001a46:	04000937          	lui	s2,0x4000
    80001a4a:	197d                	addi	s2,s2,-1
    80001a4c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a4e:	00035997          	auipc	s3,0x35
    80001a52:	69a98993          	addi	s3,s3,1690 # 800370e8 <tickslock>
      initlock(&p->lock, "proc");
    80001a56:	85da                	mv	a1,s6
    80001a58:	8526                	mv	a0,s1
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	204080e7          	jalr	516(ra) # 80000c5e <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001a62:	415487b3          	sub	a5,s1,s5
    80001a66:	878d                	srai	a5,a5,0x3
    80001a68:	000a3703          	ld	a4,0(s4)
    80001a6c:	02e787b3          	mul	a5,a5,a4
    80001a70:	2785                	addiw	a5,a5,1
    80001a72:	00d7979b          	slliw	a5,a5,0xd
    80001a76:	40f907b3          	sub	a5,s2,a5
    80001a7a:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a7c:	16848493          	addi	s1,s1,360
    80001a80:	fd349be3          	bne	s1,s3,80001a56 <procinit+0x6e>
  }
}
    80001a84:	70e2                	ld	ra,56(sp)
    80001a86:	7442                	ld	s0,48(sp)
    80001a88:	74a2                	ld	s1,40(sp)
    80001a8a:	7902                	ld	s2,32(sp)
    80001a8c:	69e2                	ld	s3,24(sp)
    80001a8e:	6a42                	ld	s4,16(sp)
    80001a90:	6aa2                	ld	s5,8(sp)
    80001a92:	6b02                	ld	s6,0(sp)
    80001a94:	6121                	addi	sp,sp,64
    80001a96:	8082                	ret

0000000080001a98 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001a98:	1141                	addi	sp,sp,-16
    80001a9a:	e422                	sd	s0,8(sp)
    80001a9c:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a9e:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001aa0:	2501                	sext.w	a0,a0
    80001aa2:	6422                	ld	s0,8(sp)
    80001aa4:	0141                	addi	sp,sp,16
    80001aa6:	8082                	ret

0000000080001aa8 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001aa8:	1141                	addi	sp,sp,-16
    80001aaa:	e422                	sd	s0,8(sp)
    80001aac:	0800                	addi	s0,sp,16
    80001aae:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001ab0:	2781                	sext.w	a5,a5
    80001ab2:	079e                	slli	a5,a5,0x7
  return c;
}
    80001ab4:	00030517          	auipc	a0,0x30
    80001ab8:	83450513          	addi	a0,a0,-1996 # 800312e8 <cpus>
    80001abc:	953e                	add	a0,a0,a5
    80001abe:	6422                	ld	s0,8(sp)
    80001ac0:	0141                	addi	sp,sp,16
    80001ac2:	8082                	ret

0000000080001ac4 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001ac4:	1101                	addi	sp,sp,-32
    80001ac6:	ec06                	sd	ra,24(sp)
    80001ac8:	e822                	sd	s0,16(sp)
    80001aca:	e426                	sd	s1,8(sp)
    80001acc:	1000                	addi	s0,sp,32
  push_off();
    80001ace:	fffff097          	auipc	ra,0xfffff
    80001ad2:	1d4080e7          	jalr	468(ra) # 80000ca2 <push_off>
    80001ad6:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001ad8:	2781                	sext.w	a5,a5
    80001ada:	079e                	slli	a5,a5,0x7
    80001adc:	0002f717          	auipc	a4,0x2f
    80001ae0:	7dc70713          	addi	a4,a4,2012 # 800312b8 <pid_lock>
    80001ae4:	97ba                	add	a5,a5,a4
    80001ae6:	7b84                	ld	s1,48(a5)
  pop_off();
    80001ae8:	fffff097          	auipc	ra,0xfffff
    80001aec:	25a080e7          	jalr	602(ra) # 80000d42 <pop_off>
  return p;
}
    80001af0:	8526                	mv	a0,s1
    80001af2:	60e2                	ld	ra,24(sp)
    80001af4:	6442                	ld	s0,16(sp)
    80001af6:	64a2                	ld	s1,8(sp)
    80001af8:	6105                	addi	sp,sp,32
    80001afa:	8082                	ret

0000000080001afc <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001afc:	1141                	addi	sp,sp,-16
    80001afe:	e406                	sd	ra,8(sp)
    80001b00:	e022                	sd	s0,0(sp)
    80001b02:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001b04:	00000097          	auipc	ra,0x0
    80001b08:	fc0080e7          	jalr	-64(ra) # 80001ac4 <myproc>
    80001b0c:	fffff097          	auipc	ra,0xfffff
    80001b10:	296080e7          	jalr	662(ra) # 80000da2 <release>

  if (first) {
    80001b14:	00007797          	auipc	a5,0x7
    80001b18:	d0c7a783          	lw	a5,-756(a5) # 80008820 <first.1683>
    80001b1c:	eb89                	bnez	a5,80001b2e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001b1e:	00001097          	auipc	ra,0x1
    80001b22:	ca8080e7          	jalr	-856(ra) # 800027c6 <usertrapret>
}
    80001b26:	60a2                	ld	ra,8(sp)
    80001b28:	6402                	ld	s0,0(sp)
    80001b2a:	0141                	addi	sp,sp,16
    80001b2c:	8082                	ret
    first = 0;
    80001b2e:	00007797          	auipc	a5,0x7
    80001b32:	ce07a923          	sw	zero,-782(a5) # 80008820 <first.1683>
    fsinit(ROOTDEV);
    80001b36:	4505                	li	a0,1
    80001b38:	00002097          	auipc	ra,0x2
    80001b3c:	a04080e7          	jalr	-1532(ra) # 8000353c <fsinit>
    80001b40:	bff9                	j	80001b1e <forkret+0x22>

0000000080001b42 <allocpid>:
allocpid() {
    80001b42:	1101                	addi	sp,sp,-32
    80001b44:	ec06                	sd	ra,24(sp)
    80001b46:	e822                	sd	s0,16(sp)
    80001b48:	e426                	sd	s1,8(sp)
    80001b4a:	e04a                	sd	s2,0(sp)
    80001b4c:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b4e:	0002f917          	auipc	s2,0x2f
    80001b52:	76a90913          	addi	s2,s2,1898 # 800312b8 <pid_lock>
    80001b56:	854a                	mv	a0,s2
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	196080e7          	jalr	406(ra) # 80000cee <acquire>
  pid = nextpid;
    80001b60:	00007797          	auipc	a5,0x7
    80001b64:	cc478793          	addi	a5,a5,-828 # 80008824 <nextpid>
    80001b68:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b6a:	0014871b          	addiw	a4,s1,1
    80001b6e:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b70:	854a                	mv	a0,s2
    80001b72:	fffff097          	auipc	ra,0xfffff
    80001b76:	230080e7          	jalr	560(ra) # 80000da2 <release>
}
    80001b7a:	8526                	mv	a0,s1
    80001b7c:	60e2                	ld	ra,24(sp)
    80001b7e:	6442                	ld	s0,16(sp)
    80001b80:	64a2                	ld	s1,8(sp)
    80001b82:	6902                	ld	s2,0(sp)
    80001b84:	6105                	addi	sp,sp,32
    80001b86:	8082                	ret

0000000080001b88 <proc_pagetable>:
{
    80001b88:	1101                	addi	sp,sp,-32
    80001b8a:	ec06                	sd	ra,24(sp)
    80001b8c:	e822                	sd	s0,16(sp)
    80001b8e:	e426                	sd	s1,8(sp)
    80001b90:	e04a                	sd	s2,0(sp)
    80001b92:	1000                	addi	s0,sp,32
    80001b94:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b96:	00000097          	auipc	ra,0x0
    80001b9a:	8ae080e7          	jalr	-1874(ra) # 80001444 <uvmcreate>
    80001b9e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001ba0:	c121                	beqz	a0,80001be0 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ba2:	4729                	li	a4,10
    80001ba4:	00005697          	auipc	a3,0x5
    80001ba8:	45c68693          	addi	a3,a3,1116 # 80007000 <_trampoline>
    80001bac:	6605                	lui	a2,0x1
    80001bae:	040005b7          	lui	a1,0x4000
    80001bb2:	15fd                	addi	a1,a1,-1
    80001bb4:	05b2                	slli	a1,a1,0xc
    80001bb6:	fffff097          	auipc	ra,0xfffff
    80001bba:	604080e7          	jalr	1540(ra) # 800011ba <mappages>
    80001bbe:	02054863          	bltz	a0,80001bee <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001bc2:	4719                	li	a4,6
    80001bc4:	05893683          	ld	a3,88(s2)
    80001bc8:	6605                	lui	a2,0x1
    80001bca:	020005b7          	lui	a1,0x2000
    80001bce:	15fd                	addi	a1,a1,-1
    80001bd0:	05b6                	slli	a1,a1,0xd
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	5e6080e7          	jalr	1510(ra) # 800011ba <mappages>
    80001bdc:	02054163          	bltz	a0,80001bfe <proc_pagetable+0x76>
}
    80001be0:	8526                	mv	a0,s1
    80001be2:	60e2                	ld	ra,24(sp)
    80001be4:	6442                	ld	s0,16(sp)
    80001be6:	64a2                	ld	s1,8(sp)
    80001be8:	6902                	ld	s2,0(sp)
    80001bea:	6105                	addi	sp,sp,32
    80001bec:	8082                	ret
    uvmfree(pagetable, 0);
    80001bee:	4581                	li	a1,0
    80001bf0:	8526                	mv	a0,s1
    80001bf2:	00000097          	auipc	ra,0x0
    80001bf6:	a4e080e7          	jalr	-1458(ra) # 80001640 <uvmfree>
    return 0;
    80001bfa:	4481                	li	s1,0
    80001bfc:	b7d5                	j	80001be0 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bfe:	4681                	li	a3,0
    80001c00:	4605                	li	a2,1
    80001c02:	040005b7          	lui	a1,0x4000
    80001c06:	15fd                	addi	a1,a1,-1
    80001c08:	05b2                	slli	a1,a1,0xc
    80001c0a:	8526                	mv	a0,s1
    80001c0c:	fffff097          	auipc	ra,0xfffff
    80001c10:	774080e7          	jalr	1908(ra) # 80001380 <uvmunmap>
    uvmfree(pagetable, 0);
    80001c14:	4581                	li	a1,0
    80001c16:	8526                	mv	a0,s1
    80001c18:	00000097          	auipc	ra,0x0
    80001c1c:	a28080e7          	jalr	-1496(ra) # 80001640 <uvmfree>
    return 0;
    80001c20:	4481                	li	s1,0
    80001c22:	bf7d                	j	80001be0 <proc_pagetable+0x58>

0000000080001c24 <proc_freepagetable>:
{
    80001c24:	1101                	addi	sp,sp,-32
    80001c26:	ec06                	sd	ra,24(sp)
    80001c28:	e822                	sd	s0,16(sp)
    80001c2a:	e426                	sd	s1,8(sp)
    80001c2c:	e04a                	sd	s2,0(sp)
    80001c2e:	1000                	addi	s0,sp,32
    80001c30:	84aa                	mv	s1,a0
    80001c32:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c34:	4681                	li	a3,0
    80001c36:	4605                	li	a2,1
    80001c38:	040005b7          	lui	a1,0x4000
    80001c3c:	15fd                	addi	a1,a1,-1
    80001c3e:	05b2                	slli	a1,a1,0xc
    80001c40:	fffff097          	auipc	ra,0xfffff
    80001c44:	740080e7          	jalr	1856(ra) # 80001380 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c48:	4681                	li	a3,0
    80001c4a:	4605                	li	a2,1
    80001c4c:	020005b7          	lui	a1,0x2000
    80001c50:	15fd                	addi	a1,a1,-1
    80001c52:	05b6                	slli	a1,a1,0xd
    80001c54:	8526                	mv	a0,s1
    80001c56:	fffff097          	auipc	ra,0xfffff
    80001c5a:	72a080e7          	jalr	1834(ra) # 80001380 <uvmunmap>
  uvmfree(pagetable, sz);
    80001c5e:	85ca                	mv	a1,s2
    80001c60:	8526                	mv	a0,s1
    80001c62:	00000097          	auipc	ra,0x0
    80001c66:	9de080e7          	jalr	-1570(ra) # 80001640 <uvmfree>
}
    80001c6a:	60e2                	ld	ra,24(sp)
    80001c6c:	6442                	ld	s0,16(sp)
    80001c6e:	64a2                	ld	s1,8(sp)
    80001c70:	6902                	ld	s2,0(sp)
    80001c72:	6105                	addi	sp,sp,32
    80001c74:	8082                	ret

0000000080001c76 <freeproc>:
{
    80001c76:	1101                	addi	sp,sp,-32
    80001c78:	ec06                	sd	ra,24(sp)
    80001c7a:	e822                	sd	s0,16(sp)
    80001c7c:	e426                	sd	s1,8(sp)
    80001c7e:	1000                	addi	s0,sp,32
    80001c80:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001c82:	6d28                	ld	a0,88(a0)
    80001c84:	c509                	beqz	a0,80001c8e <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001c86:	fffff097          	auipc	ra,0xfffff
    80001c8a:	e86080e7          	jalr	-378(ra) # 80000b0c <kfree>
  p->trapframe = 0;
    80001c8e:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001c92:	68a8                	ld	a0,80(s1)
    80001c94:	c511                	beqz	a0,80001ca0 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c96:	64ac                	ld	a1,72(s1)
    80001c98:	00000097          	auipc	ra,0x0
    80001c9c:	f8c080e7          	jalr	-116(ra) # 80001c24 <proc_freepagetable>
  p->pagetable = 0;
    80001ca0:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001ca4:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001ca8:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001cac:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001cb0:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001cb4:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001cb8:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001cbc:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001cc0:	0004ac23          	sw	zero,24(s1)
}
    80001cc4:	60e2                	ld	ra,24(sp)
    80001cc6:	6442                	ld	s0,16(sp)
    80001cc8:	64a2                	ld	s1,8(sp)
    80001cca:	6105                	addi	sp,sp,32
    80001ccc:	8082                	ret

0000000080001cce <allocproc>:
{
    80001cce:	1101                	addi	sp,sp,-32
    80001cd0:	ec06                	sd	ra,24(sp)
    80001cd2:	e822                	sd	s0,16(sp)
    80001cd4:	e426                	sd	s1,8(sp)
    80001cd6:	e04a                	sd	s2,0(sp)
    80001cd8:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cda:	00030497          	auipc	s1,0x30
    80001cde:	a0e48493          	addi	s1,s1,-1522 # 800316e8 <proc>
    80001ce2:	00035917          	auipc	s2,0x35
    80001ce6:	40690913          	addi	s2,s2,1030 # 800370e8 <tickslock>
    acquire(&p->lock);
    80001cea:	8526                	mv	a0,s1
    80001cec:	fffff097          	auipc	ra,0xfffff
    80001cf0:	002080e7          	jalr	2(ra) # 80000cee <acquire>
    if(p->state == UNUSED) {
    80001cf4:	4c9c                	lw	a5,24(s1)
    80001cf6:	cf81                	beqz	a5,80001d0e <allocproc+0x40>
      release(&p->lock);
    80001cf8:	8526                	mv	a0,s1
    80001cfa:	fffff097          	auipc	ra,0xfffff
    80001cfe:	0a8080e7          	jalr	168(ra) # 80000da2 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d02:	16848493          	addi	s1,s1,360
    80001d06:	ff2492e3          	bne	s1,s2,80001cea <allocproc+0x1c>
  return 0;
    80001d0a:	4481                	li	s1,0
    80001d0c:	a889                	j	80001d5e <allocproc+0x90>
  p->pid = allocpid();
    80001d0e:	00000097          	auipc	ra,0x0
    80001d12:	e34080e7          	jalr	-460(ra) # 80001b42 <allocpid>
    80001d16:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001d18:	4785                	li	a5,1
    80001d1a:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001d1c:	fffff097          	auipc	ra,0xfffff
    80001d20:	cdc080e7          	jalr	-804(ra) # 800009f8 <kalloc>
    80001d24:	892a                	mv	s2,a0
    80001d26:	eca8                	sd	a0,88(s1)
    80001d28:	c131                	beqz	a0,80001d6c <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001d2a:	8526                	mv	a0,s1
    80001d2c:	00000097          	auipc	ra,0x0
    80001d30:	e5c080e7          	jalr	-420(ra) # 80001b88 <proc_pagetable>
    80001d34:	892a                	mv	s2,a0
    80001d36:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001d38:	c531                	beqz	a0,80001d84 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001d3a:	07000613          	li	a2,112
    80001d3e:	4581                	li	a1,0
    80001d40:	06048513          	addi	a0,s1,96
    80001d44:	fffff097          	auipc	ra,0xfffff
    80001d48:	0a6080e7          	jalr	166(ra) # 80000dea <memset>
  p->context.ra = (uint64)forkret;
    80001d4c:	00000797          	auipc	a5,0x0
    80001d50:	db078793          	addi	a5,a5,-592 # 80001afc <forkret>
    80001d54:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d56:	60bc                	ld	a5,64(s1)
    80001d58:	6705                	lui	a4,0x1
    80001d5a:	97ba                	add	a5,a5,a4
    80001d5c:	f4bc                	sd	a5,104(s1)
}
    80001d5e:	8526                	mv	a0,s1
    80001d60:	60e2                	ld	ra,24(sp)
    80001d62:	6442                	ld	s0,16(sp)
    80001d64:	64a2                	ld	s1,8(sp)
    80001d66:	6902                	ld	s2,0(sp)
    80001d68:	6105                	addi	sp,sp,32
    80001d6a:	8082                	ret
    freeproc(p);
    80001d6c:	8526                	mv	a0,s1
    80001d6e:	00000097          	auipc	ra,0x0
    80001d72:	f08080e7          	jalr	-248(ra) # 80001c76 <freeproc>
    release(&p->lock);
    80001d76:	8526                	mv	a0,s1
    80001d78:	fffff097          	auipc	ra,0xfffff
    80001d7c:	02a080e7          	jalr	42(ra) # 80000da2 <release>
    return 0;
    80001d80:	84ca                	mv	s1,s2
    80001d82:	bff1                	j	80001d5e <allocproc+0x90>
    freeproc(p);
    80001d84:	8526                	mv	a0,s1
    80001d86:	00000097          	auipc	ra,0x0
    80001d8a:	ef0080e7          	jalr	-272(ra) # 80001c76 <freeproc>
    release(&p->lock);
    80001d8e:	8526                	mv	a0,s1
    80001d90:	fffff097          	auipc	ra,0xfffff
    80001d94:	012080e7          	jalr	18(ra) # 80000da2 <release>
    return 0;
    80001d98:	84ca                	mv	s1,s2
    80001d9a:	b7d1                	j	80001d5e <allocproc+0x90>

0000000080001d9c <userinit>:
{
    80001d9c:	1101                	addi	sp,sp,-32
    80001d9e:	ec06                	sd	ra,24(sp)
    80001da0:	e822                	sd	s0,16(sp)
    80001da2:	e426                	sd	s1,8(sp)
    80001da4:	1000                	addi	s0,sp,32
  p = allocproc();
    80001da6:	00000097          	auipc	ra,0x0
    80001daa:	f28080e7          	jalr	-216(ra) # 80001cce <allocproc>
    80001dae:	84aa                	mv	s1,a0
  initproc = p;
    80001db0:	00007797          	auipc	a5,0x7
    80001db4:	26a7bc23          	sd	a0,632(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001db8:	03400613          	li	a2,52
    80001dbc:	00007597          	auipc	a1,0x7
    80001dc0:	a7458593          	addi	a1,a1,-1420 # 80008830 <initcode>
    80001dc4:	6928                	ld	a0,80(a0)
    80001dc6:	fffff097          	auipc	ra,0xfffff
    80001dca:	6ac080e7          	jalr	1708(ra) # 80001472 <uvminit>
  p->sz = PGSIZE;
    80001dce:	6785                	lui	a5,0x1
    80001dd0:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001dd2:	6cb8                	ld	a4,88(s1)
    80001dd4:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001dd8:	6cb8                	ld	a4,88(s1)
    80001dda:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001ddc:	4641                	li	a2,16
    80001dde:	00006597          	auipc	a1,0x6
    80001de2:	43258593          	addi	a1,a1,1074 # 80008210 <digits+0x1d0>
    80001de6:	15848513          	addi	a0,s1,344
    80001dea:	fffff097          	auipc	ra,0xfffff
    80001dee:	152080e7          	jalr	338(ra) # 80000f3c <safestrcpy>
  p->cwd = namei("/");
    80001df2:	00006517          	auipc	a0,0x6
    80001df6:	42e50513          	addi	a0,a0,1070 # 80008220 <digits+0x1e0>
    80001dfa:	00002097          	auipc	ra,0x2
    80001dfe:	170080e7          	jalr	368(ra) # 80003f6a <namei>
    80001e02:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e06:	478d                	li	a5,3
    80001e08:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001e0a:	8526                	mv	a0,s1
    80001e0c:	fffff097          	auipc	ra,0xfffff
    80001e10:	f96080e7          	jalr	-106(ra) # 80000da2 <release>
}
    80001e14:	60e2                	ld	ra,24(sp)
    80001e16:	6442                	ld	s0,16(sp)
    80001e18:	64a2                	ld	s1,8(sp)
    80001e1a:	6105                	addi	sp,sp,32
    80001e1c:	8082                	ret

0000000080001e1e <growproc>:
{
    80001e1e:	1101                	addi	sp,sp,-32
    80001e20:	ec06                	sd	ra,24(sp)
    80001e22:	e822                	sd	s0,16(sp)
    80001e24:	e426                	sd	s1,8(sp)
    80001e26:	e04a                	sd	s2,0(sp)
    80001e28:	1000                	addi	s0,sp,32
    80001e2a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001e2c:	00000097          	auipc	ra,0x0
    80001e30:	c98080e7          	jalr	-872(ra) # 80001ac4 <myproc>
    80001e34:	892a                	mv	s2,a0
  sz = p->sz;
    80001e36:	652c                	ld	a1,72(a0)
    80001e38:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001e3c:	00904f63          	bgtz	s1,80001e5a <growproc+0x3c>
  } else if(n < 0){
    80001e40:	0204cc63          	bltz	s1,80001e78 <growproc+0x5a>
  p->sz = sz;
    80001e44:	1602                	slli	a2,a2,0x20
    80001e46:	9201                	srli	a2,a2,0x20
    80001e48:	04c93423          	sd	a2,72(s2)
  return 0;
    80001e4c:	4501                	li	a0,0
}
    80001e4e:	60e2                	ld	ra,24(sp)
    80001e50:	6442                	ld	s0,16(sp)
    80001e52:	64a2                	ld	s1,8(sp)
    80001e54:	6902                	ld	s2,0(sp)
    80001e56:	6105                	addi	sp,sp,32
    80001e58:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001e5a:	9e25                	addw	a2,a2,s1
    80001e5c:	1602                	slli	a2,a2,0x20
    80001e5e:	9201                	srli	a2,a2,0x20
    80001e60:	1582                	slli	a1,a1,0x20
    80001e62:	9181                	srli	a1,a1,0x20
    80001e64:	6928                	ld	a0,80(a0)
    80001e66:	fffff097          	auipc	ra,0xfffff
    80001e6a:	6c6080e7          	jalr	1734(ra) # 8000152c <uvmalloc>
    80001e6e:	0005061b          	sext.w	a2,a0
    80001e72:	fa69                	bnez	a2,80001e44 <growproc+0x26>
      return -1;
    80001e74:	557d                	li	a0,-1
    80001e76:	bfe1                	j	80001e4e <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e78:	9e25                	addw	a2,a2,s1
    80001e7a:	1602                	slli	a2,a2,0x20
    80001e7c:	9201                	srli	a2,a2,0x20
    80001e7e:	1582                	slli	a1,a1,0x20
    80001e80:	9181                	srli	a1,a1,0x20
    80001e82:	6928                	ld	a0,80(a0)
    80001e84:	fffff097          	auipc	ra,0xfffff
    80001e88:	660080e7          	jalr	1632(ra) # 800014e4 <uvmdealloc>
    80001e8c:	0005061b          	sext.w	a2,a0
    80001e90:	bf55                	j	80001e44 <growproc+0x26>

0000000080001e92 <fork>:
{
    80001e92:	7179                	addi	sp,sp,-48
    80001e94:	f406                	sd	ra,40(sp)
    80001e96:	f022                	sd	s0,32(sp)
    80001e98:	ec26                	sd	s1,24(sp)
    80001e9a:	e84a                	sd	s2,16(sp)
    80001e9c:	e44e                	sd	s3,8(sp)
    80001e9e:	e052                	sd	s4,0(sp)
    80001ea0:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001ea2:	00000097          	auipc	ra,0x0
    80001ea6:	c22080e7          	jalr	-990(ra) # 80001ac4 <myproc>
    80001eaa:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001eac:	00000097          	auipc	ra,0x0
    80001eb0:	e22080e7          	jalr	-478(ra) # 80001cce <allocproc>
    80001eb4:	10050b63          	beqz	a0,80001fca <fork+0x138>
    80001eb8:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001eba:	04893603          	ld	a2,72(s2)
    80001ebe:	692c                	ld	a1,80(a0)
    80001ec0:	05093503          	ld	a0,80(s2)
    80001ec4:	fffff097          	auipc	ra,0xfffff
    80001ec8:	7b4080e7          	jalr	1972(ra) # 80001678 <uvmcopy>
    80001ecc:	04054663          	bltz	a0,80001f18 <fork+0x86>
  np->sz = p->sz;
    80001ed0:	04893783          	ld	a5,72(s2)
    80001ed4:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001ed8:	05893683          	ld	a3,88(s2)
    80001edc:	87b6                	mv	a5,a3
    80001ede:	0589b703          	ld	a4,88(s3)
    80001ee2:	12068693          	addi	a3,a3,288
    80001ee6:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001eea:	6788                	ld	a0,8(a5)
    80001eec:	6b8c                	ld	a1,16(a5)
    80001eee:	6f90                	ld	a2,24(a5)
    80001ef0:	01073023          	sd	a6,0(a4)
    80001ef4:	e708                	sd	a0,8(a4)
    80001ef6:	eb0c                	sd	a1,16(a4)
    80001ef8:	ef10                	sd	a2,24(a4)
    80001efa:	02078793          	addi	a5,a5,32
    80001efe:	02070713          	addi	a4,a4,32
    80001f02:	fed792e3          	bne	a5,a3,80001ee6 <fork+0x54>
  np->trapframe->a0 = 0;
    80001f06:	0589b783          	ld	a5,88(s3)
    80001f0a:	0607b823          	sd	zero,112(a5)
    80001f0e:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001f12:	15000a13          	li	s4,336
    80001f16:	a03d                	j	80001f44 <fork+0xb2>
    freeproc(np);
    80001f18:	854e                	mv	a0,s3
    80001f1a:	00000097          	auipc	ra,0x0
    80001f1e:	d5c080e7          	jalr	-676(ra) # 80001c76 <freeproc>
    release(&np->lock);
    80001f22:	854e                	mv	a0,s3
    80001f24:	fffff097          	auipc	ra,0xfffff
    80001f28:	e7e080e7          	jalr	-386(ra) # 80000da2 <release>
    return -1;
    80001f2c:	5a7d                	li	s4,-1
    80001f2e:	a069                	j	80001fb8 <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f30:	00002097          	auipc	ra,0x2
    80001f34:	6d0080e7          	jalr	1744(ra) # 80004600 <filedup>
    80001f38:	009987b3          	add	a5,s3,s1
    80001f3c:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001f3e:	04a1                	addi	s1,s1,8
    80001f40:	01448763          	beq	s1,s4,80001f4e <fork+0xbc>
    if(p->ofile[i])
    80001f44:	009907b3          	add	a5,s2,s1
    80001f48:	6388                	ld	a0,0(a5)
    80001f4a:	f17d                	bnez	a0,80001f30 <fork+0x9e>
    80001f4c:	bfcd                	j	80001f3e <fork+0xac>
  np->cwd = idup(p->cwd);
    80001f4e:	15093503          	ld	a0,336(s2)
    80001f52:	00002097          	auipc	ra,0x2
    80001f56:	824080e7          	jalr	-2012(ra) # 80003776 <idup>
    80001f5a:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f5e:	4641                	li	a2,16
    80001f60:	15890593          	addi	a1,s2,344
    80001f64:	15898513          	addi	a0,s3,344
    80001f68:	fffff097          	auipc	ra,0xfffff
    80001f6c:	fd4080e7          	jalr	-44(ra) # 80000f3c <safestrcpy>
  pid = np->pid;
    80001f70:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001f74:	854e                	mv	a0,s3
    80001f76:	fffff097          	auipc	ra,0xfffff
    80001f7a:	e2c080e7          	jalr	-468(ra) # 80000da2 <release>
  acquire(&wait_lock);
    80001f7e:	0002f497          	auipc	s1,0x2f
    80001f82:	35248493          	addi	s1,s1,850 # 800312d0 <wait_lock>
    80001f86:	8526                	mv	a0,s1
    80001f88:	fffff097          	auipc	ra,0xfffff
    80001f8c:	d66080e7          	jalr	-666(ra) # 80000cee <acquire>
  np->parent = p;
    80001f90:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001f94:	8526                	mv	a0,s1
    80001f96:	fffff097          	auipc	ra,0xfffff
    80001f9a:	e0c080e7          	jalr	-500(ra) # 80000da2 <release>
  acquire(&np->lock);
    80001f9e:	854e                	mv	a0,s3
    80001fa0:	fffff097          	auipc	ra,0xfffff
    80001fa4:	d4e080e7          	jalr	-690(ra) # 80000cee <acquire>
  np->state = RUNNABLE;
    80001fa8:	478d                	li	a5,3
    80001faa:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001fae:	854e                	mv	a0,s3
    80001fb0:	fffff097          	auipc	ra,0xfffff
    80001fb4:	df2080e7          	jalr	-526(ra) # 80000da2 <release>
}
    80001fb8:	8552                	mv	a0,s4
    80001fba:	70a2                	ld	ra,40(sp)
    80001fbc:	7402                	ld	s0,32(sp)
    80001fbe:	64e2                	ld	s1,24(sp)
    80001fc0:	6942                	ld	s2,16(sp)
    80001fc2:	69a2                	ld	s3,8(sp)
    80001fc4:	6a02                	ld	s4,0(sp)
    80001fc6:	6145                	addi	sp,sp,48
    80001fc8:	8082                	ret
    return -1;
    80001fca:	5a7d                	li	s4,-1
    80001fcc:	b7f5                	j	80001fb8 <fork+0x126>

0000000080001fce <scheduler>:
{
    80001fce:	7139                	addi	sp,sp,-64
    80001fd0:	fc06                	sd	ra,56(sp)
    80001fd2:	f822                	sd	s0,48(sp)
    80001fd4:	f426                	sd	s1,40(sp)
    80001fd6:	f04a                	sd	s2,32(sp)
    80001fd8:	ec4e                	sd	s3,24(sp)
    80001fda:	e852                	sd	s4,16(sp)
    80001fdc:	e456                	sd	s5,8(sp)
    80001fde:	e05a                	sd	s6,0(sp)
    80001fe0:	0080                	addi	s0,sp,64
    80001fe2:	8792                	mv	a5,tp
  int id = r_tp();
    80001fe4:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001fe6:	00779a93          	slli	s5,a5,0x7
    80001fea:	0002f717          	auipc	a4,0x2f
    80001fee:	2ce70713          	addi	a4,a4,718 # 800312b8 <pid_lock>
    80001ff2:	9756                	add	a4,a4,s5
    80001ff4:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ff8:	0002f717          	auipc	a4,0x2f
    80001ffc:	2f870713          	addi	a4,a4,760 # 800312f0 <cpus+0x8>
    80002000:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80002002:	498d                	li	s3,3
        p->state = RUNNING;
    80002004:	4b11                	li	s6,4
        c->proc = p;
    80002006:	079e                	slli	a5,a5,0x7
    80002008:	0002fa17          	auipc	s4,0x2f
    8000200c:	2b0a0a13          	addi	s4,s4,688 # 800312b8 <pid_lock>
    80002010:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002012:	00035917          	auipc	s2,0x35
    80002016:	0d690913          	addi	s2,s2,214 # 800370e8 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000201a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000201e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002022:	10079073          	csrw	sstatus,a5
    80002026:	0002f497          	auipc	s1,0x2f
    8000202a:	6c248493          	addi	s1,s1,1730 # 800316e8 <proc>
    8000202e:	a03d                	j	8000205c <scheduler+0x8e>
        p->state = RUNNING;
    80002030:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80002034:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80002038:	06048593          	addi	a1,s1,96
    8000203c:	8556                	mv	a0,s5
    8000203e:	00000097          	auipc	ra,0x0
    80002042:	640080e7          	jalr	1600(ra) # 8000267e <swtch>
        c->proc = 0;
    80002046:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    8000204a:	8526                	mv	a0,s1
    8000204c:	fffff097          	auipc	ra,0xfffff
    80002050:	d56080e7          	jalr	-682(ra) # 80000da2 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002054:	16848493          	addi	s1,s1,360
    80002058:	fd2481e3          	beq	s1,s2,8000201a <scheduler+0x4c>
      acquire(&p->lock);
    8000205c:	8526                	mv	a0,s1
    8000205e:	fffff097          	auipc	ra,0xfffff
    80002062:	c90080e7          	jalr	-880(ra) # 80000cee <acquire>
      if(p->state == RUNNABLE) {
    80002066:	4c9c                	lw	a5,24(s1)
    80002068:	ff3791e3          	bne	a5,s3,8000204a <scheduler+0x7c>
    8000206c:	b7d1                	j	80002030 <scheduler+0x62>

000000008000206e <sched>:
{
    8000206e:	7179                	addi	sp,sp,-48
    80002070:	f406                	sd	ra,40(sp)
    80002072:	f022                	sd	s0,32(sp)
    80002074:	ec26                	sd	s1,24(sp)
    80002076:	e84a                	sd	s2,16(sp)
    80002078:	e44e                	sd	s3,8(sp)
    8000207a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000207c:	00000097          	auipc	ra,0x0
    80002080:	a48080e7          	jalr	-1464(ra) # 80001ac4 <myproc>
    80002084:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002086:	fffff097          	auipc	ra,0xfffff
    8000208a:	bee080e7          	jalr	-1042(ra) # 80000c74 <holding>
    8000208e:	c93d                	beqz	a0,80002104 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002090:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002092:	2781                	sext.w	a5,a5
    80002094:	079e                	slli	a5,a5,0x7
    80002096:	0002f717          	auipc	a4,0x2f
    8000209a:	22270713          	addi	a4,a4,546 # 800312b8 <pid_lock>
    8000209e:	97ba                	add	a5,a5,a4
    800020a0:	0a87a703          	lw	a4,168(a5)
    800020a4:	4785                	li	a5,1
    800020a6:	06f71763          	bne	a4,a5,80002114 <sched+0xa6>
  if(p->state == RUNNING)
    800020aa:	4c98                	lw	a4,24(s1)
    800020ac:	4791                	li	a5,4
    800020ae:	06f70b63          	beq	a4,a5,80002124 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020b2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800020b6:	8b89                	andi	a5,a5,2
  if(intr_get())
    800020b8:	efb5                	bnez	a5,80002134 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020ba:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800020bc:	0002f917          	auipc	s2,0x2f
    800020c0:	1fc90913          	addi	s2,s2,508 # 800312b8 <pid_lock>
    800020c4:	2781                	sext.w	a5,a5
    800020c6:	079e                	slli	a5,a5,0x7
    800020c8:	97ca                	add	a5,a5,s2
    800020ca:	0ac7a983          	lw	s3,172(a5)
    800020ce:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020d0:	2781                	sext.w	a5,a5
    800020d2:	079e                	slli	a5,a5,0x7
    800020d4:	0002f597          	auipc	a1,0x2f
    800020d8:	21c58593          	addi	a1,a1,540 # 800312f0 <cpus+0x8>
    800020dc:	95be                	add	a1,a1,a5
    800020de:	06048513          	addi	a0,s1,96
    800020e2:	00000097          	auipc	ra,0x0
    800020e6:	59c080e7          	jalr	1436(ra) # 8000267e <swtch>
    800020ea:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020ec:	2781                	sext.w	a5,a5
    800020ee:	079e                	slli	a5,a5,0x7
    800020f0:	97ca                	add	a5,a5,s2
    800020f2:	0b37a623          	sw	s3,172(a5)
}
    800020f6:	70a2                	ld	ra,40(sp)
    800020f8:	7402                	ld	s0,32(sp)
    800020fa:	64e2                	ld	s1,24(sp)
    800020fc:	6942                	ld	s2,16(sp)
    800020fe:	69a2                	ld	s3,8(sp)
    80002100:	6145                	addi	sp,sp,48
    80002102:	8082                	ret
    panic("sched p->lock");
    80002104:	00006517          	auipc	a0,0x6
    80002108:	12450513          	addi	a0,a0,292 # 80008228 <digits+0x1e8>
    8000210c:	ffffe097          	auipc	ra,0xffffe
    80002110:	432080e7          	jalr	1074(ra) # 8000053e <panic>
    panic("sched locks");
    80002114:	00006517          	auipc	a0,0x6
    80002118:	12450513          	addi	a0,a0,292 # 80008238 <digits+0x1f8>
    8000211c:	ffffe097          	auipc	ra,0xffffe
    80002120:	422080e7          	jalr	1058(ra) # 8000053e <panic>
    panic("sched running");
    80002124:	00006517          	auipc	a0,0x6
    80002128:	12450513          	addi	a0,a0,292 # 80008248 <digits+0x208>
    8000212c:	ffffe097          	auipc	ra,0xffffe
    80002130:	412080e7          	jalr	1042(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002134:	00006517          	auipc	a0,0x6
    80002138:	12450513          	addi	a0,a0,292 # 80008258 <digits+0x218>
    8000213c:	ffffe097          	auipc	ra,0xffffe
    80002140:	402080e7          	jalr	1026(ra) # 8000053e <panic>

0000000080002144 <yield>:
{
    80002144:	1101                	addi	sp,sp,-32
    80002146:	ec06                	sd	ra,24(sp)
    80002148:	e822                	sd	s0,16(sp)
    8000214a:	e426                	sd	s1,8(sp)
    8000214c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000214e:	00000097          	auipc	ra,0x0
    80002152:	976080e7          	jalr	-1674(ra) # 80001ac4 <myproc>
    80002156:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002158:	fffff097          	auipc	ra,0xfffff
    8000215c:	b96080e7          	jalr	-1130(ra) # 80000cee <acquire>
  p->state = RUNNABLE;
    80002160:	478d                	li	a5,3
    80002162:	cc9c                	sw	a5,24(s1)
  sched();
    80002164:	00000097          	auipc	ra,0x0
    80002168:	f0a080e7          	jalr	-246(ra) # 8000206e <sched>
  release(&p->lock);
    8000216c:	8526                	mv	a0,s1
    8000216e:	fffff097          	auipc	ra,0xfffff
    80002172:	c34080e7          	jalr	-972(ra) # 80000da2 <release>
}
    80002176:	60e2                	ld	ra,24(sp)
    80002178:	6442                	ld	s0,16(sp)
    8000217a:	64a2                	ld	s1,8(sp)
    8000217c:	6105                	addi	sp,sp,32
    8000217e:	8082                	ret

0000000080002180 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002180:	7179                	addi	sp,sp,-48
    80002182:	f406                	sd	ra,40(sp)
    80002184:	f022                	sd	s0,32(sp)
    80002186:	ec26                	sd	s1,24(sp)
    80002188:	e84a                	sd	s2,16(sp)
    8000218a:	e44e                	sd	s3,8(sp)
    8000218c:	1800                	addi	s0,sp,48
    8000218e:	89aa                	mv	s3,a0
    80002190:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002192:	00000097          	auipc	ra,0x0
    80002196:	932080e7          	jalr	-1742(ra) # 80001ac4 <myproc>
    8000219a:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000219c:	fffff097          	auipc	ra,0xfffff
    800021a0:	b52080e7          	jalr	-1198(ra) # 80000cee <acquire>
  release(lk);
    800021a4:	854a                	mv	a0,s2
    800021a6:	fffff097          	auipc	ra,0xfffff
    800021aa:	bfc080e7          	jalr	-1028(ra) # 80000da2 <release>

  // Go to sleep.
  p->chan = chan;
    800021ae:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800021b2:	4789                	li	a5,2
    800021b4:	cc9c                	sw	a5,24(s1)

  sched();
    800021b6:	00000097          	auipc	ra,0x0
    800021ba:	eb8080e7          	jalr	-328(ra) # 8000206e <sched>

  // Tidy up.
  p->chan = 0;
    800021be:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800021c2:	8526                	mv	a0,s1
    800021c4:	fffff097          	auipc	ra,0xfffff
    800021c8:	bde080e7          	jalr	-1058(ra) # 80000da2 <release>
  acquire(lk);
    800021cc:	854a                	mv	a0,s2
    800021ce:	fffff097          	auipc	ra,0xfffff
    800021d2:	b20080e7          	jalr	-1248(ra) # 80000cee <acquire>
}
    800021d6:	70a2                	ld	ra,40(sp)
    800021d8:	7402                	ld	s0,32(sp)
    800021da:	64e2                	ld	s1,24(sp)
    800021dc:	6942                	ld	s2,16(sp)
    800021de:	69a2                	ld	s3,8(sp)
    800021e0:	6145                	addi	sp,sp,48
    800021e2:	8082                	ret

00000000800021e4 <wait>:
{
    800021e4:	715d                	addi	sp,sp,-80
    800021e6:	e486                	sd	ra,72(sp)
    800021e8:	e0a2                	sd	s0,64(sp)
    800021ea:	fc26                	sd	s1,56(sp)
    800021ec:	f84a                	sd	s2,48(sp)
    800021ee:	f44e                	sd	s3,40(sp)
    800021f0:	f052                	sd	s4,32(sp)
    800021f2:	ec56                	sd	s5,24(sp)
    800021f4:	e85a                	sd	s6,16(sp)
    800021f6:	e45e                	sd	s7,8(sp)
    800021f8:	e062                	sd	s8,0(sp)
    800021fa:	0880                	addi	s0,sp,80
    800021fc:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800021fe:	00000097          	auipc	ra,0x0
    80002202:	8c6080e7          	jalr	-1850(ra) # 80001ac4 <myproc>
    80002206:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002208:	0002f517          	auipc	a0,0x2f
    8000220c:	0c850513          	addi	a0,a0,200 # 800312d0 <wait_lock>
    80002210:	fffff097          	auipc	ra,0xfffff
    80002214:	ade080e7          	jalr	-1314(ra) # 80000cee <acquire>
    havekids = 0;
    80002218:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000221a:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    8000221c:	00035997          	auipc	s3,0x35
    80002220:	ecc98993          	addi	s3,s3,-308 # 800370e8 <tickslock>
        havekids = 1;
    80002224:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002226:	0002fc17          	auipc	s8,0x2f
    8000222a:	0aac0c13          	addi	s8,s8,170 # 800312d0 <wait_lock>
    havekids = 0;
    8000222e:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002230:	0002f497          	auipc	s1,0x2f
    80002234:	4b848493          	addi	s1,s1,1208 # 800316e8 <proc>
    80002238:	a0bd                	j	800022a6 <wait+0xc2>
          pid = np->pid;
    8000223a:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000223e:	000b0e63          	beqz	s6,8000225a <wait+0x76>
    80002242:	4691                	li	a3,4
    80002244:	02c48613          	addi	a2,s1,44
    80002248:	85da                	mv	a1,s6
    8000224a:	05093503          	ld	a0,80(s2)
    8000224e:	fffff097          	auipc	ra,0xfffff
    80002252:	524080e7          	jalr	1316(ra) # 80001772 <copyout>
    80002256:	02054563          	bltz	a0,80002280 <wait+0x9c>
          freeproc(np);
    8000225a:	8526                	mv	a0,s1
    8000225c:	00000097          	auipc	ra,0x0
    80002260:	a1a080e7          	jalr	-1510(ra) # 80001c76 <freeproc>
          release(&np->lock);
    80002264:	8526                	mv	a0,s1
    80002266:	fffff097          	auipc	ra,0xfffff
    8000226a:	b3c080e7          	jalr	-1220(ra) # 80000da2 <release>
          release(&wait_lock);
    8000226e:	0002f517          	auipc	a0,0x2f
    80002272:	06250513          	addi	a0,a0,98 # 800312d0 <wait_lock>
    80002276:	fffff097          	auipc	ra,0xfffff
    8000227a:	b2c080e7          	jalr	-1236(ra) # 80000da2 <release>
          return pid;
    8000227e:	a09d                	j	800022e4 <wait+0x100>
            release(&np->lock);
    80002280:	8526                	mv	a0,s1
    80002282:	fffff097          	auipc	ra,0xfffff
    80002286:	b20080e7          	jalr	-1248(ra) # 80000da2 <release>
            release(&wait_lock);
    8000228a:	0002f517          	auipc	a0,0x2f
    8000228e:	04650513          	addi	a0,a0,70 # 800312d0 <wait_lock>
    80002292:	fffff097          	auipc	ra,0xfffff
    80002296:	b10080e7          	jalr	-1264(ra) # 80000da2 <release>
            return -1;
    8000229a:	59fd                	li	s3,-1
    8000229c:	a0a1                	j	800022e4 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000229e:	16848493          	addi	s1,s1,360
    800022a2:	03348463          	beq	s1,s3,800022ca <wait+0xe6>
      if(np->parent == p){
    800022a6:	7c9c                	ld	a5,56(s1)
    800022a8:	ff279be3          	bne	a5,s2,8000229e <wait+0xba>
        acquire(&np->lock);
    800022ac:	8526                	mv	a0,s1
    800022ae:	fffff097          	auipc	ra,0xfffff
    800022b2:	a40080e7          	jalr	-1472(ra) # 80000cee <acquire>
        if(np->state == ZOMBIE){
    800022b6:	4c9c                	lw	a5,24(s1)
    800022b8:	f94781e3          	beq	a5,s4,8000223a <wait+0x56>
        release(&np->lock);
    800022bc:	8526                	mv	a0,s1
    800022be:	fffff097          	auipc	ra,0xfffff
    800022c2:	ae4080e7          	jalr	-1308(ra) # 80000da2 <release>
        havekids = 1;
    800022c6:	8756                	mv	a4,s5
    800022c8:	bfd9                	j	8000229e <wait+0xba>
    if(!havekids || p->killed){
    800022ca:	c701                	beqz	a4,800022d2 <wait+0xee>
    800022cc:	02892783          	lw	a5,40(s2)
    800022d0:	c79d                	beqz	a5,800022fe <wait+0x11a>
      release(&wait_lock);
    800022d2:	0002f517          	auipc	a0,0x2f
    800022d6:	ffe50513          	addi	a0,a0,-2 # 800312d0 <wait_lock>
    800022da:	fffff097          	auipc	ra,0xfffff
    800022de:	ac8080e7          	jalr	-1336(ra) # 80000da2 <release>
      return -1;
    800022e2:	59fd                	li	s3,-1
}
    800022e4:	854e                	mv	a0,s3
    800022e6:	60a6                	ld	ra,72(sp)
    800022e8:	6406                	ld	s0,64(sp)
    800022ea:	74e2                	ld	s1,56(sp)
    800022ec:	7942                	ld	s2,48(sp)
    800022ee:	79a2                	ld	s3,40(sp)
    800022f0:	7a02                	ld	s4,32(sp)
    800022f2:	6ae2                	ld	s5,24(sp)
    800022f4:	6b42                	ld	s6,16(sp)
    800022f6:	6ba2                	ld	s7,8(sp)
    800022f8:	6c02                	ld	s8,0(sp)
    800022fa:	6161                	addi	sp,sp,80
    800022fc:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800022fe:	85e2                	mv	a1,s8
    80002300:	854a                	mv	a0,s2
    80002302:	00000097          	auipc	ra,0x0
    80002306:	e7e080e7          	jalr	-386(ra) # 80002180 <sleep>
    havekids = 0;
    8000230a:	b715                	j	8000222e <wait+0x4a>

000000008000230c <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000230c:	7139                	addi	sp,sp,-64
    8000230e:	fc06                	sd	ra,56(sp)
    80002310:	f822                	sd	s0,48(sp)
    80002312:	f426                	sd	s1,40(sp)
    80002314:	f04a                	sd	s2,32(sp)
    80002316:	ec4e                	sd	s3,24(sp)
    80002318:	e852                	sd	s4,16(sp)
    8000231a:	e456                	sd	s5,8(sp)
    8000231c:	0080                	addi	s0,sp,64
    8000231e:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002320:	0002f497          	auipc	s1,0x2f
    80002324:	3c848493          	addi	s1,s1,968 # 800316e8 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002328:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000232a:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000232c:	00035917          	auipc	s2,0x35
    80002330:	dbc90913          	addi	s2,s2,-580 # 800370e8 <tickslock>
    80002334:	a821                	j	8000234c <wakeup+0x40>
        p->state = RUNNABLE;
    80002336:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    8000233a:	8526                	mv	a0,s1
    8000233c:	fffff097          	auipc	ra,0xfffff
    80002340:	a66080e7          	jalr	-1434(ra) # 80000da2 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002344:	16848493          	addi	s1,s1,360
    80002348:	03248463          	beq	s1,s2,80002370 <wakeup+0x64>
    if(p != myproc()){
    8000234c:	fffff097          	auipc	ra,0xfffff
    80002350:	778080e7          	jalr	1912(ra) # 80001ac4 <myproc>
    80002354:	fea488e3          	beq	s1,a0,80002344 <wakeup+0x38>
      acquire(&p->lock);
    80002358:	8526                	mv	a0,s1
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	994080e7          	jalr	-1644(ra) # 80000cee <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002362:	4c9c                	lw	a5,24(s1)
    80002364:	fd379be3          	bne	a5,s3,8000233a <wakeup+0x2e>
    80002368:	709c                	ld	a5,32(s1)
    8000236a:	fd4798e3          	bne	a5,s4,8000233a <wakeup+0x2e>
    8000236e:	b7e1                	j	80002336 <wakeup+0x2a>
    }
  }
}
    80002370:	70e2                	ld	ra,56(sp)
    80002372:	7442                	ld	s0,48(sp)
    80002374:	74a2                	ld	s1,40(sp)
    80002376:	7902                	ld	s2,32(sp)
    80002378:	69e2                	ld	s3,24(sp)
    8000237a:	6a42                	ld	s4,16(sp)
    8000237c:	6aa2                	ld	s5,8(sp)
    8000237e:	6121                	addi	sp,sp,64
    80002380:	8082                	ret

0000000080002382 <reparent>:
{
    80002382:	7179                	addi	sp,sp,-48
    80002384:	f406                	sd	ra,40(sp)
    80002386:	f022                	sd	s0,32(sp)
    80002388:	ec26                	sd	s1,24(sp)
    8000238a:	e84a                	sd	s2,16(sp)
    8000238c:	e44e                	sd	s3,8(sp)
    8000238e:	e052                	sd	s4,0(sp)
    80002390:	1800                	addi	s0,sp,48
    80002392:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002394:	0002f497          	auipc	s1,0x2f
    80002398:	35448493          	addi	s1,s1,852 # 800316e8 <proc>
      pp->parent = initproc;
    8000239c:	00007a17          	auipc	s4,0x7
    800023a0:	c8ca0a13          	addi	s4,s4,-884 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800023a4:	00035997          	auipc	s3,0x35
    800023a8:	d4498993          	addi	s3,s3,-700 # 800370e8 <tickslock>
    800023ac:	a029                	j	800023b6 <reparent+0x34>
    800023ae:	16848493          	addi	s1,s1,360
    800023b2:	01348d63          	beq	s1,s3,800023cc <reparent+0x4a>
    if(pp->parent == p){
    800023b6:	7c9c                	ld	a5,56(s1)
    800023b8:	ff279be3          	bne	a5,s2,800023ae <reparent+0x2c>
      pp->parent = initproc;
    800023bc:	000a3503          	ld	a0,0(s4)
    800023c0:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800023c2:	00000097          	auipc	ra,0x0
    800023c6:	f4a080e7          	jalr	-182(ra) # 8000230c <wakeup>
    800023ca:	b7d5                	j	800023ae <reparent+0x2c>
}
    800023cc:	70a2                	ld	ra,40(sp)
    800023ce:	7402                	ld	s0,32(sp)
    800023d0:	64e2                	ld	s1,24(sp)
    800023d2:	6942                	ld	s2,16(sp)
    800023d4:	69a2                	ld	s3,8(sp)
    800023d6:	6a02                	ld	s4,0(sp)
    800023d8:	6145                	addi	sp,sp,48
    800023da:	8082                	ret

00000000800023dc <exit>:
{
    800023dc:	7179                	addi	sp,sp,-48
    800023de:	f406                	sd	ra,40(sp)
    800023e0:	f022                	sd	s0,32(sp)
    800023e2:	ec26                	sd	s1,24(sp)
    800023e4:	e84a                	sd	s2,16(sp)
    800023e6:	e44e                	sd	s3,8(sp)
    800023e8:	e052                	sd	s4,0(sp)
    800023ea:	1800                	addi	s0,sp,48
    800023ec:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800023ee:	fffff097          	auipc	ra,0xfffff
    800023f2:	6d6080e7          	jalr	1750(ra) # 80001ac4 <myproc>
    800023f6:	89aa                	mv	s3,a0
  if(p == initproc)
    800023f8:	00007797          	auipc	a5,0x7
    800023fc:	c307b783          	ld	a5,-976(a5) # 80009028 <initproc>
    80002400:	0d050493          	addi	s1,a0,208
    80002404:	15050913          	addi	s2,a0,336
    80002408:	02a79363          	bne	a5,a0,8000242e <exit+0x52>
    panic("init exiting");
    8000240c:	00006517          	auipc	a0,0x6
    80002410:	e6450513          	addi	a0,a0,-412 # 80008270 <digits+0x230>
    80002414:	ffffe097          	auipc	ra,0xffffe
    80002418:	12a080e7          	jalr	298(ra) # 8000053e <panic>
      fileclose(f);
    8000241c:	00002097          	auipc	ra,0x2
    80002420:	236080e7          	jalr	566(ra) # 80004652 <fileclose>
      p->ofile[fd] = 0;
    80002424:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002428:	04a1                	addi	s1,s1,8
    8000242a:	01248563          	beq	s1,s2,80002434 <exit+0x58>
    if(p->ofile[fd]){
    8000242e:	6088                	ld	a0,0(s1)
    80002430:	f575                	bnez	a0,8000241c <exit+0x40>
    80002432:	bfdd                	j	80002428 <exit+0x4c>
  begin_op();
    80002434:	00002097          	auipc	ra,0x2
    80002438:	d52080e7          	jalr	-686(ra) # 80004186 <begin_op>
  iput(p->cwd);
    8000243c:	1509b503          	ld	a0,336(s3)
    80002440:	00001097          	auipc	ra,0x1
    80002444:	52e080e7          	jalr	1326(ra) # 8000396e <iput>
  end_op();
    80002448:	00002097          	auipc	ra,0x2
    8000244c:	dbe080e7          	jalr	-578(ra) # 80004206 <end_op>
  p->cwd = 0;
    80002450:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002454:	0002f497          	auipc	s1,0x2f
    80002458:	e7c48493          	addi	s1,s1,-388 # 800312d0 <wait_lock>
    8000245c:	8526                	mv	a0,s1
    8000245e:	fffff097          	auipc	ra,0xfffff
    80002462:	890080e7          	jalr	-1904(ra) # 80000cee <acquire>
  reparent(p);
    80002466:	854e                	mv	a0,s3
    80002468:	00000097          	auipc	ra,0x0
    8000246c:	f1a080e7          	jalr	-230(ra) # 80002382 <reparent>
  wakeup(p->parent);
    80002470:	0389b503          	ld	a0,56(s3)
    80002474:	00000097          	auipc	ra,0x0
    80002478:	e98080e7          	jalr	-360(ra) # 8000230c <wakeup>
  acquire(&p->lock);
    8000247c:	854e                	mv	a0,s3
    8000247e:	fffff097          	auipc	ra,0xfffff
    80002482:	870080e7          	jalr	-1936(ra) # 80000cee <acquire>
  p->xstate = status;
    80002486:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000248a:	4795                	li	a5,5
    8000248c:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002490:	8526                	mv	a0,s1
    80002492:	fffff097          	auipc	ra,0xfffff
    80002496:	910080e7          	jalr	-1776(ra) # 80000da2 <release>
  sched();
    8000249a:	00000097          	auipc	ra,0x0
    8000249e:	bd4080e7          	jalr	-1068(ra) # 8000206e <sched>
  panic("zombie exit");
    800024a2:	00006517          	auipc	a0,0x6
    800024a6:	dde50513          	addi	a0,a0,-546 # 80008280 <digits+0x240>
    800024aa:	ffffe097          	auipc	ra,0xffffe
    800024ae:	094080e7          	jalr	148(ra) # 8000053e <panic>

00000000800024b2 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800024b2:	7179                	addi	sp,sp,-48
    800024b4:	f406                	sd	ra,40(sp)
    800024b6:	f022                	sd	s0,32(sp)
    800024b8:	ec26                	sd	s1,24(sp)
    800024ba:	e84a                	sd	s2,16(sp)
    800024bc:	e44e                	sd	s3,8(sp)
    800024be:	1800                	addi	s0,sp,48
    800024c0:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800024c2:	0002f497          	auipc	s1,0x2f
    800024c6:	22648493          	addi	s1,s1,550 # 800316e8 <proc>
    800024ca:	00035997          	auipc	s3,0x35
    800024ce:	c1e98993          	addi	s3,s3,-994 # 800370e8 <tickslock>
    acquire(&p->lock);
    800024d2:	8526                	mv	a0,s1
    800024d4:	fffff097          	auipc	ra,0xfffff
    800024d8:	81a080e7          	jalr	-2022(ra) # 80000cee <acquire>
    if(p->pid == pid){
    800024dc:	589c                	lw	a5,48(s1)
    800024de:	01278d63          	beq	a5,s2,800024f8 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800024e2:	8526                	mv	a0,s1
    800024e4:	fffff097          	auipc	ra,0xfffff
    800024e8:	8be080e7          	jalr	-1858(ra) # 80000da2 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800024ec:	16848493          	addi	s1,s1,360
    800024f0:	ff3491e3          	bne	s1,s3,800024d2 <kill+0x20>
  }
  return -1;
    800024f4:	557d                	li	a0,-1
    800024f6:	a829                	j	80002510 <kill+0x5e>
      p->killed = 1;
    800024f8:	4785                	li	a5,1
    800024fa:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800024fc:	4c98                	lw	a4,24(s1)
    800024fe:	4789                	li	a5,2
    80002500:	00f70f63          	beq	a4,a5,8000251e <kill+0x6c>
      release(&p->lock);
    80002504:	8526                	mv	a0,s1
    80002506:	fffff097          	auipc	ra,0xfffff
    8000250a:	89c080e7          	jalr	-1892(ra) # 80000da2 <release>
      return 0;
    8000250e:	4501                	li	a0,0
}
    80002510:	70a2                	ld	ra,40(sp)
    80002512:	7402                	ld	s0,32(sp)
    80002514:	64e2                	ld	s1,24(sp)
    80002516:	6942                	ld	s2,16(sp)
    80002518:	69a2                	ld	s3,8(sp)
    8000251a:	6145                	addi	sp,sp,48
    8000251c:	8082                	ret
        p->state = RUNNABLE;
    8000251e:	478d                	li	a5,3
    80002520:	cc9c                	sw	a5,24(s1)
    80002522:	b7cd                	j	80002504 <kill+0x52>

0000000080002524 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002524:	7179                	addi	sp,sp,-48
    80002526:	f406                	sd	ra,40(sp)
    80002528:	f022                	sd	s0,32(sp)
    8000252a:	ec26                	sd	s1,24(sp)
    8000252c:	e84a                	sd	s2,16(sp)
    8000252e:	e44e                	sd	s3,8(sp)
    80002530:	e052                	sd	s4,0(sp)
    80002532:	1800                	addi	s0,sp,48
    80002534:	84aa                	mv	s1,a0
    80002536:	892e                	mv	s2,a1
    80002538:	89b2                	mv	s3,a2
    8000253a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000253c:	fffff097          	auipc	ra,0xfffff
    80002540:	588080e7          	jalr	1416(ra) # 80001ac4 <myproc>
  if(user_dst){
    80002544:	c08d                	beqz	s1,80002566 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002546:	86d2                	mv	a3,s4
    80002548:	864e                	mv	a2,s3
    8000254a:	85ca                	mv	a1,s2
    8000254c:	6928                	ld	a0,80(a0)
    8000254e:	fffff097          	auipc	ra,0xfffff
    80002552:	224080e7          	jalr	548(ra) # 80001772 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002556:	70a2                	ld	ra,40(sp)
    80002558:	7402                	ld	s0,32(sp)
    8000255a:	64e2                	ld	s1,24(sp)
    8000255c:	6942                	ld	s2,16(sp)
    8000255e:	69a2                	ld	s3,8(sp)
    80002560:	6a02                	ld	s4,0(sp)
    80002562:	6145                	addi	sp,sp,48
    80002564:	8082                	ret
    memmove((char *)dst, src, len);
    80002566:	000a061b          	sext.w	a2,s4
    8000256a:	85ce                	mv	a1,s3
    8000256c:	854a                	mv	a0,s2
    8000256e:	fffff097          	auipc	ra,0xfffff
    80002572:	8dc080e7          	jalr	-1828(ra) # 80000e4a <memmove>
    return 0;
    80002576:	8526                	mv	a0,s1
    80002578:	bff9                	j	80002556 <either_copyout+0x32>

000000008000257a <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000257a:	7179                	addi	sp,sp,-48
    8000257c:	f406                	sd	ra,40(sp)
    8000257e:	f022                	sd	s0,32(sp)
    80002580:	ec26                	sd	s1,24(sp)
    80002582:	e84a                	sd	s2,16(sp)
    80002584:	e44e                	sd	s3,8(sp)
    80002586:	e052                	sd	s4,0(sp)
    80002588:	1800                	addi	s0,sp,48
    8000258a:	892a                	mv	s2,a0
    8000258c:	84ae                	mv	s1,a1
    8000258e:	89b2                	mv	s3,a2
    80002590:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002592:	fffff097          	auipc	ra,0xfffff
    80002596:	532080e7          	jalr	1330(ra) # 80001ac4 <myproc>
  if(user_src){
    8000259a:	c08d                	beqz	s1,800025bc <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000259c:	86d2                	mv	a3,s4
    8000259e:	864e                	mv	a2,s3
    800025a0:	85ca                	mv	a1,s2
    800025a2:	6928                	ld	a0,80(a0)
    800025a4:	fffff097          	auipc	ra,0xfffff
    800025a8:	26e080e7          	jalr	622(ra) # 80001812 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800025ac:	70a2                	ld	ra,40(sp)
    800025ae:	7402                	ld	s0,32(sp)
    800025b0:	64e2                	ld	s1,24(sp)
    800025b2:	6942                	ld	s2,16(sp)
    800025b4:	69a2                	ld	s3,8(sp)
    800025b6:	6a02                	ld	s4,0(sp)
    800025b8:	6145                	addi	sp,sp,48
    800025ba:	8082                	ret
    memmove(dst, (char*)src, len);
    800025bc:	000a061b          	sext.w	a2,s4
    800025c0:	85ce                	mv	a1,s3
    800025c2:	854a                	mv	a0,s2
    800025c4:	fffff097          	auipc	ra,0xfffff
    800025c8:	886080e7          	jalr	-1914(ra) # 80000e4a <memmove>
    return 0;
    800025cc:	8526                	mv	a0,s1
    800025ce:	bff9                	j	800025ac <either_copyin+0x32>

00000000800025d0 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025d0:	715d                	addi	sp,sp,-80
    800025d2:	e486                	sd	ra,72(sp)
    800025d4:	e0a2                	sd	s0,64(sp)
    800025d6:	fc26                	sd	s1,56(sp)
    800025d8:	f84a                	sd	s2,48(sp)
    800025da:	f44e                	sd	s3,40(sp)
    800025dc:	f052                	sd	s4,32(sp)
    800025de:	ec56                	sd	s5,24(sp)
    800025e0:	e85a                	sd	s6,16(sp)
    800025e2:	e45e                	sd	s7,8(sp)
    800025e4:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025e6:	00006517          	auipc	a0,0x6
    800025ea:	af250513          	addi	a0,a0,-1294 # 800080d8 <digits+0x98>
    800025ee:	ffffe097          	auipc	ra,0xffffe
    800025f2:	f9a080e7          	jalr	-102(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025f6:	0002f497          	auipc	s1,0x2f
    800025fa:	24a48493          	addi	s1,s1,586 # 80031840 <proc+0x158>
    800025fe:	00035917          	auipc	s2,0x35
    80002602:	c4290913          	addi	s2,s2,-958 # 80037240 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002606:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002608:	00006997          	auipc	s3,0x6
    8000260c:	c8898993          	addi	s3,s3,-888 # 80008290 <digits+0x250>
    printf("%d %s %s", p->pid, state, p->name);
    80002610:	00006a97          	auipc	s5,0x6
    80002614:	c88a8a93          	addi	s5,s5,-888 # 80008298 <digits+0x258>
    printf("\n");
    80002618:	00006a17          	auipc	s4,0x6
    8000261c:	ac0a0a13          	addi	s4,s4,-1344 # 800080d8 <digits+0x98>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002620:	00006b97          	auipc	s7,0x6
    80002624:	cb0b8b93          	addi	s7,s7,-848 # 800082d0 <states.1720>
    80002628:	a00d                	j	8000264a <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000262a:	ed86a583          	lw	a1,-296(a3)
    8000262e:	8556                	mv	a0,s5
    80002630:	ffffe097          	auipc	ra,0xffffe
    80002634:	f58080e7          	jalr	-168(ra) # 80000588 <printf>
    printf("\n");
    80002638:	8552                	mv	a0,s4
    8000263a:	ffffe097          	auipc	ra,0xffffe
    8000263e:	f4e080e7          	jalr	-178(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002642:	16848493          	addi	s1,s1,360
    80002646:	03248163          	beq	s1,s2,80002668 <procdump+0x98>
    if(p->state == UNUSED)
    8000264a:	86a6                	mv	a3,s1
    8000264c:	ec04a783          	lw	a5,-320(s1)
    80002650:	dbed                	beqz	a5,80002642 <procdump+0x72>
      state = "???";
    80002652:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002654:	fcfb6be3          	bltu	s6,a5,8000262a <procdump+0x5a>
    80002658:	1782                	slli	a5,a5,0x20
    8000265a:	9381                	srli	a5,a5,0x20
    8000265c:	078e                	slli	a5,a5,0x3
    8000265e:	97de                	add	a5,a5,s7
    80002660:	6390                	ld	a2,0(a5)
    80002662:	f661                	bnez	a2,8000262a <procdump+0x5a>
      state = "???";
    80002664:	864e                	mv	a2,s3
    80002666:	b7d1                	j	8000262a <procdump+0x5a>
  }
}
    80002668:	60a6                	ld	ra,72(sp)
    8000266a:	6406                	ld	s0,64(sp)
    8000266c:	74e2                	ld	s1,56(sp)
    8000266e:	7942                	ld	s2,48(sp)
    80002670:	79a2                	ld	s3,40(sp)
    80002672:	7a02                	ld	s4,32(sp)
    80002674:	6ae2                	ld	s5,24(sp)
    80002676:	6b42                	ld	s6,16(sp)
    80002678:	6ba2                	ld	s7,8(sp)
    8000267a:	6161                	addi	sp,sp,80
    8000267c:	8082                	ret

000000008000267e <swtch>:
    8000267e:	00153023          	sd	ra,0(a0)
    80002682:	00253423          	sd	sp,8(a0)
    80002686:	e900                	sd	s0,16(a0)
    80002688:	ed04                	sd	s1,24(a0)
    8000268a:	03253023          	sd	s2,32(a0)
    8000268e:	03353423          	sd	s3,40(a0)
    80002692:	03453823          	sd	s4,48(a0)
    80002696:	03553c23          	sd	s5,56(a0)
    8000269a:	05653023          	sd	s6,64(a0)
    8000269e:	05753423          	sd	s7,72(a0)
    800026a2:	05853823          	sd	s8,80(a0)
    800026a6:	05953c23          	sd	s9,88(a0)
    800026aa:	07a53023          	sd	s10,96(a0)
    800026ae:	07b53423          	sd	s11,104(a0)
    800026b2:	0005b083          	ld	ra,0(a1)
    800026b6:	0085b103          	ld	sp,8(a1)
    800026ba:	6980                	ld	s0,16(a1)
    800026bc:	6d84                	ld	s1,24(a1)
    800026be:	0205b903          	ld	s2,32(a1)
    800026c2:	0285b983          	ld	s3,40(a1)
    800026c6:	0305ba03          	ld	s4,48(a1)
    800026ca:	0385ba83          	ld	s5,56(a1)
    800026ce:	0405bb03          	ld	s6,64(a1)
    800026d2:	0485bb83          	ld	s7,72(a1)
    800026d6:	0505bc03          	ld	s8,80(a1)
    800026da:	0585bc83          	ld	s9,88(a1)
    800026de:	0605bd03          	ld	s10,96(a1)
    800026e2:	0685bd83          	ld	s11,104(a1)
    800026e6:	8082                	ret

00000000800026e8 <cow_handle>:
extern int devintr();

int
cow_handle(pagetable_t pagetable, uint64 va)
{
  va = PGROUNDDOWN(va);
    800026e8:	77fd                	lui	a5,0xfffff
    800026ea:	8dfd                	and	a1,a1,a5

  if(va >= MAXVA)
    800026ec:	57fd                	li	a5,-1
    800026ee:	83e9                	srli	a5,a5,0x1a
    800026f0:	00b7f463          	bgeu	a5,a1,800026f8 <cow_handle+0x10>
    return -1;
    800026f4:	557d                	li	a0,-1

    return 0;
  } else {
    return -1;
  }
}
    800026f6:	8082                	ret
{
    800026f8:	7179                	addi	sp,sp,-48
    800026fa:	f406                	sd	ra,40(sp)
    800026fc:	f022                	sd	s0,32(sp)
    800026fe:	ec26                	sd	s1,24(sp)
    80002700:	e84a                	sd	s2,16(sp)
    80002702:	e44e                	sd	s3,8(sp)
    80002704:	1800                	addi	s0,sp,48
  if ((pte = walk(pagetable, va, 0)) == 0)
    80002706:	4601                	li	a2,0
    80002708:	fffff097          	auipc	ra,0xfffff
    8000270c:	9ca080e7          	jalr	-1590(ra) # 800010d2 <walk>
    80002710:	84aa                	mv	s1,a0
    80002712:	c925                	beqz	a0,80002782 <cow_handle+0x9a>
  if ((*pte & PTE_V) == 0)
    80002714:	611c                	ld	a5,0(a0)
    80002716:	0017f713          	andi	a4,a5,1
    return -1;
    8000271a:	557d                	li	a0,-1
  if ((*pte & PTE_V) == 0)
    8000271c:	c709                	beqz	a4,80002726 <cow_handle+0x3e>
  if ((*pte & PTE_COW) == 0)
    8000271e:	2007f793          	andi	a5,a5,512
    return 1;
    80002722:	4505                	li	a0,1
  if ((*pte & PTE_COW) == 0)
    80002724:	eb81                	bnez	a5,80002734 <cow_handle+0x4c>
}
    80002726:	70a2                	ld	ra,40(sp)
    80002728:	7402                	ld	s0,32(sp)
    8000272a:	64e2                	ld	s1,24(sp)
    8000272c:	6942                	ld	s2,16(sp)
    8000272e:	69a2                	ld	s3,8(sp)
    80002730:	6145                	addi	sp,sp,48
    80002732:	8082                	ret
  if ((n_pa = kalloc()) != 0) {
    80002734:	ffffe097          	auipc	ra,0xffffe
    80002738:	2c4080e7          	jalr	708(ra) # 800009f8 <kalloc>
    8000273c:	892a                	mv	s2,a0
    return -1;
    8000273e:	557d                	li	a0,-1
  if ((n_pa = kalloc()) != 0) {
    80002740:	fe0903e3          	beqz	s2,80002726 <cow_handle+0x3e>
    uint64 pa = PTE2PA(*pte);
    80002744:	0004b983          	ld	s3,0(s1)
    80002748:	00a9d993          	srli	s3,s3,0xa
    8000274c:	09b2                	slli	s3,s3,0xc
    memmove(n_pa, (char*)pa, PGSIZE);
    8000274e:	6605                	lui	a2,0x1
    80002750:	85ce                	mv	a1,s3
    80002752:	854a                	mv	a0,s2
    80002754:	ffffe097          	auipc	ra,0xffffe
    80002758:	6f6080e7          	jalr	1782(ra) # 80000e4a <memmove>
    *pte = PA2PTE(n_pa) | ((PTE_FLAGS(*pte) & ~PTE_COW) | PTE_W);
    8000275c:	00c95793          	srli	a5,s2,0xc
    80002760:	07aa                	slli	a5,a5,0xa
    80002762:	0004b903          	ld	s2,0(s1)
    80002766:	1fb97913          	andi	s2,s2,507
    8000276a:	0127e7b3          	or	a5,a5,s2
    8000276e:	0047e793          	ori	a5,a5,4
    80002772:	e09c                	sd	a5,0(s1)
    kfree((void*)pa);
    80002774:	854e                	mv	a0,s3
    80002776:	ffffe097          	auipc	ra,0xffffe
    8000277a:	396080e7          	jalr	918(ra) # 80000b0c <kfree>
    return 0;
    8000277e:	4501                	li	a0,0
    80002780:	b75d                	j	80002726 <cow_handle+0x3e>
    return -1;
    80002782:	557d                	li	a0,-1
    80002784:	b74d                	j	80002726 <cow_handle+0x3e>

0000000080002786 <trapinit>:

////
void
trapinit(void)
{
    80002786:	1141                	addi	sp,sp,-16
    80002788:	e406                	sd	ra,8(sp)
    8000278a:	e022                	sd	s0,0(sp)
    8000278c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000278e:	00006597          	auipc	a1,0x6
    80002792:	b7258593          	addi	a1,a1,-1166 # 80008300 <states.1720+0x30>
    80002796:	00035517          	auipc	a0,0x35
    8000279a:	95250513          	addi	a0,a0,-1710 # 800370e8 <tickslock>
    8000279e:	ffffe097          	auipc	ra,0xffffe
    800027a2:	4c0080e7          	jalr	1216(ra) # 80000c5e <initlock>
}
    800027a6:	60a2                	ld	ra,8(sp)
    800027a8:	6402                	ld	s0,0(sp)
    800027aa:	0141                	addi	sp,sp,16
    800027ac:	8082                	ret

00000000800027ae <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800027ae:	1141                	addi	sp,sp,-16
    800027b0:	e422                	sd	s0,8(sp)
    800027b2:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027b4:	00003797          	auipc	a5,0x3
    800027b8:	4bc78793          	addi	a5,a5,1212 # 80005c70 <kernelvec>
    800027bc:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800027c0:	6422                	ld	s0,8(sp)
    800027c2:	0141                	addi	sp,sp,16
    800027c4:	8082                	ret

00000000800027c6 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800027c6:	1141                	addi	sp,sp,-16
    800027c8:	e406                	sd	ra,8(sp)
    800027ca:	e022                	sd	s0,0(sp)
    800027cc:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800027ce:	fffff097          	auipc	ra,0xfffff
    800027d2:	2f6080e7          	jalr	758(ra) # 80001ac4 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027d6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800027da:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027dc:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800027e0:	00005617          	auipc	a2,0x5
    800027e4:	82060613          	addi	a2,a2,-2016 # 80007000 <_trampoline>
    800027e8:	00005697          	auipc	a3,0x5
    800027ec:	81868693          	addi	a3,a3,-2024 # 80007000 <_trampoline>
    800027f0:	8e91                	sub	a3,a3,a2
    800027f2:	040007b7          	lui	a5,0x4000
    800027f6:	17fd                	addi	a5,a5,-1
    800027f8:	07b2                	slli	a5,a5,0xc
    800027fa:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027fc:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002800:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002802:	180026f3          	csrr	a3,satp
    80002806:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002808:	6d38                	ld	a4,88(a0)
    8000280a:	6134                	ld	a3,64(a0)
    8000280c:	6585                	lui	a1,0x1
    8000280e:	96ae                	add	a3,a3,a1
    80002810:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002812:	6d38                	ld	a4,88(a0)
    80002814:	00000697          	auipc	a3,0x0
    80002818:	13868693          	addi	a3,a3,312 # 8000294c <usertrap>
    8000281c:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000281e:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002820:	8692                	mv	a3,tp
    80002822:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002824:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002828:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000282c:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002830:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002834:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002836:	6f18                	ld	a4,24(a4)
    80002838:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000283c:	692c                	ld	a1,80(a0)
    8000283e:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002840:	00005717          	auipc	a4,0x5
    80002844:	85070713          	addi	a4,a4,-1968 # 80007090 <userret>
    80002848:	8f11                	sub	a4,a4,a2
    8000284a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000284c:	577d                	li	a4,-1
    8000284e:	177e                	slli	a4,a4,0x3f
    80002850:	8dd9                	or	a1,a1,a4
    80002852:	02000537          	lui	a0,0x2000
    80002856:	157d                	addi	a0,a0,-1
    80002858:	0536                	slli	a0,a0,0xd
    8000285a:	9782                	jalr	a5
}
    8000285c:	60a2                	ld	ra,8(sp)
    8000285e:	6402                	ld	s0,0(sp)
    80002860:	0141                	addi	sp,sp,16
    80002862:	8082                	ret

0000000080002864 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002864:	1101                	addi	sp,sp,-32
    80002866:	ec06                	sd	ra,24(sp)
    80002868:	e822                	sd	s0,16(sp)
    8000286a:	e426                	sd	s1,8(sp)
    8000286c:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000286e:	00035497          	auipc	s1,0x35
    80002872:	87a48493          	addi	s1,s1,-1926 # 800370e8 <tickslock>
    80002876:	8526                	mv	a0,s1
    80002878:	ffffe097          	auipc	ra,0xffffe
    8000287c:	476080e7          	jalr	1142(ra) # 80000cee <acquire>
  ticks++;
    80002880:	00006517          	auipc	a0,0x6
    80002884:	7b050513          	addi	a0,a0,1968 # 80009030 <ticks>
    80002888:	411c                	lw	a5,0(a0)
    8000288a:	2785                	addiw	a5,a5,1
    8000288c:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000288e:	00000097          	auipc	ra,0x0
    80002892:	a7e080e7          	jalr	-1410(ra) # 8000230c <wakeup>
  release(&tickslock);
    80002896:	8526                	mv	a0,s1
    80002898:	ffffe097          	auipc	ra,0xffffe
    8000289c:	50a080e7          	jalr	1290(ra) # 80000da2 <release>
}
    800028a0:	60e2                	ld	ra,24(sp)
    800028a2:	6442                	ld	s0,16(sp)
    800028a4:	64a2                	ld	s1,8(sp)
    800028a6:	6105                	addi	sp,sp,32
    800028a8:	8082                	ret

00000000800028aa <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800028aa:	1101                	addi	sp,sp,-32
    800028ac:	ec06                	sd	ra,24(sp)
    800028ae:	e822                	sd	s0,16(sp)
    800028b0:	e426                	sd	s1,8(sp)
    800028b2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028b4:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800028b8:	00074d63          	bltz	a4,800028d2 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800028bc:	57fd                	li	a5,-1
    800028be:	17fe                	slli	a5,a5,0x3f
    800028c0:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800028c2:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800028c4:	06f70363          	beq	a4,a5,8000292a <devintr+0x80>
  }
}
    800028c8:	60e2                	ld	ra,24(sp)
    800028ca:	6442                	ld	s0,16(sp)
    800028cc:	64a2                	ld	s1,8(sp)
    800028ce:	6105                	addi	sp,sp,32
    800028d0:	8082                	ret
     (scause & 0xff) == 9){
    800028d2:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800028d6:	46a5                	li	a3,9
    800028d8:	fed792e3          	bne	a5,a3,800028bc <devintr+0x12>
    int irq = plic_claim();
    800028dc:	00003097          	auipc	ra,0x3
    800028e0:	49c080e7          	jalr	1180(ra) # 80005d78 <plic_claim>
    800028e4:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800028e6:	47a9                	li	a5,10
    800028e8:	02f50763          	beq	a0,a5,80002916 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800028ec:	4785                	li	a5,1
    800028ee:	02f50963          	beq	a0,a5,80002920 <devintr+0x76>
    return 1;
    800028f2:	4505                	li	a0,1
    } else if(irq){
    800028f4:	d8f1                	beqz	s1,800028c8 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800028f6:	85a6                	mv	a1,s1
    800028f8:	00006517          	auipc	a0,0x6
    800028fc:	a1050513          	addi	a0,a0,-1520 # 80008308 <states.1720+0x38>
    80002900:	ffffe097          	auipc	ra,0xffffe
    80002904:	c88080e7          	jalr	-888(ra) # 80000588 <printf>
      plic_complete(irq);
    80002908:	8526                	mv	a0,s1
    8000290a:	00003097          	auipc	ra,0x3
    8000290e:	492080e7          	jalr	1170(ra) # 80005d9c <plic_complete>
    return 1;
    80002912:	4505                	li	a0,1
    80002914:	bf55                	j	800028c8 <devintr+0x1e>
      uartintr();
    80002916:	ffffe097          	auipc	ra,0xffffe
    8000291a:	092080e7          	jalr	146(ra) # 800009a8 <uartintr>
    8000291e:	b7ed                	j	80002908 <devintr+0x5e>
      virtio_disk_intr();
    80002920:	00004097          	auipc	ra,0x4
    80002924:	95c080e7          	jalr	-1700(ra) # 8000627c <virtio_disk_intr>
    80002928:	b7c5                	j	80002908 <devintr+0x5e>
    if(cpuid() == 0){
    8000292a:	fffff097          	auipc	ra,0xfffff
    8000292e:	16e080e7          	jalr	366(ra) # 80001a98 <cpuid>
    80002932:	c901                	beqz	a0,80002942 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002934:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002938:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000293a:	14479073          	csrw	sip,a5
    return 2;
    8000293e:	4509                	li	a0,2
    80002940:	b761                	j	800028c8 <devintr+0x1e>
      clockintr();
    80002942:	00000097          	auipc	ra,0x0
    80002946:	f22080e7          	jalr	-222(ra) # 80002864 <clockintr>
    8000294a:	b7ed                	j	80002934 <devintr+0x8a>

000000008000294c <usertrap>:
{
    8000294c:	1101                	addi	sp,sp,-32
    8000294e:	ec06                	sd	ra,24(sp)
    80002950:	e822                	sd	s0,16(sp)
    80002952:	e426                	sd	s1,8(sp)
    80002954:	e04a                	sd	s2,0(sp)
    80002956:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002958:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000295c:	1007f793          	andi	a5,a5,256
    80002960:	e7a5                	bnez	a5,800029c8 <usertrap+0x7c>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002962:	00003797          	auipc	a5,0x3
    80002966:	30e78793          	addi	a5,a5,782 # 80005c70 <kernelvec>
    8000296a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000296e:	fffff097          	auipc	ra,0xfffff
    80002972:	156080e7          	jalr	342(ra) # 80001ac4 <myproc>
    80002976:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002978:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000297a:	14102773          	csrr	a4,sepc
    8000297e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002980:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002984:	47a1                	li	a5,8
    80002986:	04f70963          	beq	a4,a5,800029d8 <usertrap+0x8c>
    8000298a:	14202773          	csrr	a4,scause
  } else if (r_scause() == 13 || r_scause() == 15) {
    8000298e:	47b5                	li	a5,13
    80002990:	00f70763          	beq	a4,a5,8000299e <usertrap+0x52>
    80002994:	14202773          	csrr	a4,scause
    80002998:	47bd                	li	a5,15
    8000299a:	08f71863          	bne	a4,a5,80002a2a <usertrap+0xde>
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000299e:	143025f3          	csrr	a1,stval
    if (va >= p->sz || cow_handle(p->pagetable, va) != 0)
    800029a2:	64bc                	ld	a5,72(s1)
    800029a4:	06f5ec63          	bltu	a1,a5,80002a1c <usertrap+0xd0>
      p->killed = 1;
    800029a8:	4785                	li	a5,1
    800029aa:	d49c                	sw	a5,40(s1)
{
    800029ac:	4901                	li	s2,0
    exit(-1);
    800029ae:	557d                	li	a0,-1
    800029b0:	00000097          	auipc	ra,0x0
    800029b4:	a2c080e7          	jalr	-1492(ra) # 800023dc <exit>
  if(which_dev == 2)
    800029b8:	4789                	li	a5,2
    800029ba:	04f91163          	bne	s2,a5,800029fc <usertrap+0xb0>
    yield();
    800029be:	fffff097          	auipc	ra,0xfffff
    800029c2:	786080e7          	jalr	1926(ra) # 80002144 <yield>
    800029c6:	a81d                	j	800029fc <usertrap+0xb0>
    panic("usertrap: not from user mode");
    800029c8:	00006517          	auipc	a0,0x6
    800029cc:	96050513          	addi	a0,a0,-1696 # 80008328 <states.1720+0x58>
    800029d0:	ffffe097          	auipc	ra,0xffffe
    800029d4:	b6e080e7          	jalr	-1170(ra) # 8000053e <panic>
    if(p->killed)
    800029d8:	551c                	lw	a5,40(a0)
    800029da:	eb9d                	bnez	a5,80002a10 <usertrap+0xc4>
    p->trapframe->epc += 4;
    800029dc:	6cb8                	ld	a4,88(s1)
    800029de:	6f1c                	ld	a5,24(a4)
    800029e0:	0791                	addi	a5,a5,4
    800029e2:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029e4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800029e8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029ec:	10079073          	csrw	sstatus,a5
    syscall();
    800029f0:	00000097          	auipc	ra,0x0
    800029f4:	2c6080e7          	jalr	710(ra) # 80002cb6 <syscall>
  if(p->killed)
    800029f8:	549c                	lw	a5,40(s1)
    800029fa:	ebbd                	bnez	a5,80002a70 <usertrap+0x124>
  usertrapret();
    800029fc:	00000097          	auipc	ra,0x0
    80002a00:	dca080e7          	jalr	-566(ra) # 800027c6 <usertrapret>
}
    80002a04:	60e2                	ld	ra,24(sp)
    80002a06:	6442                	ld	s0,16(sp)
    80002a08:	64a2                	ld	s1,8(sp)
    80002a0a:	6902                	ld	s2,0(sp)
    80002a0c:	6105                	addi	sp,sp,32
    80002a0e:	8082                	ret
      exit(-1);
    80002a10:	557d                	li	a0,-1
    80002a12:	00000097          	auipc	ra,0x0
    80002a16:	9ca080e7          	jalr	-1590(ra) # 800023dc <exit>
    80002a1a:	b7c9                	j	800029dc <usertrap+0x90>
    if (va >= p->sz || cow_handle(p->pagetable, va) != 0)
    80002a1c:	68a8                	ld	a0,80(s1)
    80002a1e:	00000097          	auipc	ra,0x0
    80002a22:	cca080e7          	jalr	-822(ra) # 800026e8 <cow_handle>
    80002a26:	d969                	beqz	a0,800029f8 <usertrap+0xac>
    80002a28:	b741                	j	800029a8 <usertrap+0x5c>
  } else if((which_dev = devintr()) != 0){
    80002a2a:	00000097          	auipc	ra,0x0
    80002a2e:	e80080e7          	jalr	-384(ra) # 800028aa <devintr>
    80002a32:	892a                	mv	s2,a0
    80002a34:	c501                	beqz	a0,80002a3c <usertrap+0xf0>
  if(p->killed)
    80002a36:	549c                	lw	a5,40(s1)
    80002a38:	d3c1                	beqz	a5,800029b8 <usertrap+0x6c>
    80002a3a:	bf95                	j	800029ae <usertrap+0x62>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a3c:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a40:	5890                	lw	a2,48(s1)
    80002a42:	00006517          	auipc	a0,0x6
    80002a46:	90650513          	addi	a0,a0,-1786 # 80008348 <states.1720+0x78>
    80002a4a:	ffffe097          	auipc	ra,0xffffe
    80002a4e:	b3e080e7          	jalr	-1218(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a52:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a56:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a5a:	00006517          	auipc	a0,0x6
    80002a5e:	91e50513          	addi	a0,a0,-1762 # 80008378 <states.1720+0xa8>
    80002a62:	ffffe097          	auipc	ra,0xffffe
    80002a66:	b26080e7          	jalr	-1242(ra) # 80000588 <printf>
    p->killed = 1;
    80002a6a:	4785                	li	a5,1
    80002a6c:	d49c                	sw	a5,40(s1)
    80002a6e:	bf3d                	j	800029ac <usertrap+0x60>
  if(p->killed)
    80002a70:	4901                	li	s2,0
    80002a72:	bf35                	j	800029ae <usertrap+0x62>

0000000080002a74 <kerneltrap>:
{
    80002a74:	7179                	addi	sp,sp,-48
    80002a76:	f406                	sd	ra,40(sp)
    80002a78:	f022                	sd	s0,32(sp)
    80002a7a:	ec26                	sd	s1,24(sp)
    80002a7c:	e84a                	sd	s2,16(sp)
    80002a7e:	e44e                	sd	s3,8(sp)
    80002a80:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a82:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a86:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a8a:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a8e:	1004f793          	andi	a5,s1,256
    80002a92:	cb85                	beqz	a5,80002ac2 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a94:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a98:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a9a:	ef85                	bnez	a5,80002ad2 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a9c:	00000097          	auipc	ra,0x0
    80002aa0:	e0e080e7          	jalr	-498(ra) # 800028aa <devintr>
    80002aa4:	cd1d                	beqz	a0,80002ae2 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002aa6:	4789                	li	a5,2
    80002aa8:	06f50a63          	beq	a0,a5,80002b1c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002aac:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ab0:	10049073          	csrw	sstatus,s1
}
    80002ab4:	70a2                	ld	ra,40(sp)
    80002ab6:	7402                	ld	s0,32(sp)
    80002ab8:	64e2                	ld	s1,24(sp)
    80002aba:	6942                	ld	s2,16(sp)
    80002abc:	69a2                	ld	s3,8(sp)
    80002abe:	6145                	addi	sp,sp,48
    80002ac0:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002ac2:	00006517          	auipc	a0,0x6
    80002ac6:	8d650513          	addi	a0,a0,-1834 # 80008398 <states.1720+0xc8>
    80002aca:	ffffe097          	auipc	ra,0xffffe
    80002ace:	a74080e7          	jalr	-1420(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002ad2:	00006517          	auipc	a0,0x6
    80002ad6:	8ee50513          	addi	a0,a0,-1810 # 800083c0 <states.1720+0xf0>
    80002ada:	ffffe097          	auipc	ra,0xffffe
    80002ade:	a64080e7          	jalr	-1436(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002ae2:	85ce                	mv	a1,s3
    80002ae4:	00006517          	auipc	a0,0x6
    80002ae8:	8fc50513          	addi	a0,a0,-1796 # 800083e0 <states.1720+0x110>
    80002aec:	ffffe097          	auipc	ra,0xffffe
    80002af0:	a9c080e7          	jalr	-1380(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002af4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002af8:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002afc:	00006517          	auipc	a0,0x6
    80002b00:	8f450513          	addi	a0,a0,-1804 # 800083f0 <states.1720+0x120>
    80002b04:	ffffe097          	auipc	ra,0xffffe
    80002b08:	a84080e7          	jalr	-1404(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002b0c:	00006517          	auipc	a0,0x6
    80002b10:	8fc50513          	addi	a0,a0,-1796 # 80008408 <states.1720+0x138>
    80002b14:	ffffe097          	auipc	ra,0xffffe
    80002b18:	a2a080e7          	jalr	-1494(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b1c:	fffff097          	auipc	ra,0xfffff
    80002b20:	fa8080e7          	jalr	-88(ra) # 80001ac4 <myproc>
    80002b24:	d541                	beqz	a0,80002aac <kerneltrap+0x38>
    80002b26:	fffff097          	auipc	ra,0xfffff
    80002b2a:	f9e080e7          	jalr	-98(ra) # 80001ac4 <myproc>
    80002b2e:	4d18                	lw	a4,24(a0)
    80002b30:	4791                	li	a5,4
    80002b32:	f6f71de3          	bne	a4,a5,80002aac <kerneltrap+0x38>
    yield();
    80002b36:	fffff097          	auipc	ra,0xfffff
    80002b3a:	60e080e7          	jalr	1550(ra) # 80002144 <yield>
    80002b3e:	b7bd                	j	80002aac <kerneltrap+0x38>

0000000080002b40 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b40:	1101                	addi	sp,sp,-32
    80002b42:	ec06                	sd	ra,24(sp)
    80002b44:	e822                	sd	s0,16(sp)
    80002b46:	e426                	sd	s1,8(sp)
    80002b48:	1000                	addi	s0,sp,32
    80002b4a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b4c:	fffff097          	auipc	ra,0xfffff
    80002b50:	f78080e7          	jalr	-136(ra) # 80001ac4 <myproc>
  switch (n) {
    80002b54:	4795                	li	a5,5
    80002b56:	0497e163          	bltu	a5,s1,80002b98 <argraw+0x58>
    80002b5a:	048a                	slli	s1,s1,0x2
    80002b5c:	00006717          	auipc	a4,0x6
    80002b60:	8e470713          	addi	a4,a4,-1820 # 80008440 <states.1720+0x170>
    80002b64:	94ba                	add	s1,s1,a4
    80002b66:	409c                	lw	a5,0(s1)
    80002b68:	97ba                	add	a5,a5,a4
    80002b6a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b6c:	6d3c                	ld	a5,88(a0)
    80002b6e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b70:	60e2                	ld	ra,24(sp)
    80002b72:	6442                	ld	s0,16(sp)
    80002b74:	64a2                	ld	s1,8(sp)
    80002b76:	6105                	addi	sp,sp,32
    80002b78:	8082                	ret
    return p->trapframe->a1;
    80002b7a:	6d3c                	ld	a5,88(a0)
    80002b7c:	7fa8                	ld	a0,120(a5)
    80002b7e:	bfcd                	j	80002b70 <argraw+0x30>
    return p->trapframe->a2;
    80002b80:	6d3c                	ld	a5,88(a0)
    80002b82:	63c8                	ld	a0,128(a5)
    80002b84:	b7f5                	j	80002b70 <argraw+0x30>
    return p->trapframe->a3;
    80002b86:	6d3c                	ld	a5,88(a0)
    80002b88:	67c8                	ld	a0,136(a5)
    80002b8a:	b7dd                	j	80002b70 <argraw+0x30>
    return p->trapframe->a4;
    80002b8c:	6d3c                	ld	a5,88(a0)
    80002b8e:	6bc8                	ld	a0,144(a5)
    80002b90:	b7c5                	j	80002b70 <argraw+0x30>
    return p->trapframe->a5;
    80002b92:	6d3c                	ld	a5,88(a0)
    80002b94:	6fc8                	ld	a0,152(a5)
    80002b96:	bfe9                	j	80002b70 <argraw+0x30>
  panic("argraw");
    80002b98:	00006517          	auipc	a0,0x6
    80002b9c:	88050513          	addi	a0,a0,-1920 # 80008418 <states.1720+0x148>
    80002ba0:	ffffe097          	auipc	ra,0xffffe
    80002ba4:	99e080e7          	jalr	-1634(ra) # 8000053e <panic>

0000000080002ba8 <fetchaddr>:
{
    80002ba8:	1101                	addi	sp,sp,-32
    80002baa:	ec06                	sd	ra,24(sp)
    80002bac:	e822                	sd	s0,16(sp)
    80002bae:	e426                	sd	s1,8(sp)
    80002bb0:	e04a                	sd	s2,0(sp)
    80002bb2:	1000                	addi	s0,sp,32
    80002bb4:	84aa                	mv	s1,a0
    80002bb6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002bb8:	fffff097          	auipc	ra,0xfffff
    80002bbc:	f0c080e7          	jalr	-244(ra) # 80001ac4 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002bc0:	653c                	ld	a5,72(a0)
    80002bc2:	02f4f863          	bgeu	s1,a5,80002bf2 <fetchaddr+0x4a>
    80002bc6:	00848713          	addi	a4,s1,8
    80002bca:	02e7e663          	bltu	a5,a4,80002bf6 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002bce:	46a1                	li	a3,8
    80002bd0:	8626                	mv	a2,s1
    80002bd2:	85ca                	mv	a1,s2
    80002bd4:	6928                	ld	a0,80(a0)
    80002bd6:	fffff097          	auipc	ra,0xfffff
    80002bda:	c3c080e7          	jalr	-964(ra) # 80001812 <copyin>
    80002bde:	00a03533          	snez	a0,a0
    80002be2:	40a00533          	neg	a0,a0
}
    80002be6:	60e2                	ld	ra,24(sp)
    80002be8:	6442                	ld	s0,16(sp)
    80002bea:	64a2                	ld	s1,8(sp)
    80002bec:	6902                	ld	s2,0(sp)
    80002bee:	6105                	addi	sp,sp,32
    80002bf0:	8082                	ret
    return -1;
    80002bf2:	557d                	li	a0,-1
    80002bf4:	bfcd                	j	80002be6 <fetchaddr+0x3e>
    80002bf6:	557d                	li	a0,-1
    80002bf8:	b7fd                	j	80002be6 <fetchaddr+0x3e>

0000000080002bfa <fetchstr>:
{
    80002bfa:	7179                	addi	sp,sp,-48
    80002bfc:	f406                	sd	ra,40(sp)
    80002bfe:	f022                	sd	s0,32(sp)
    80002c00:	ec26                	sd	s1,24(sp)
    80002c02:	e84a                	sd	s2,16(sp)
    80002c04:	e44e                	sd	s3,8(sp)
    80002c06:	1800                	addi	s0,sp,48
    80002c08:	892a                	mv	s2,a0
    80002c0a:	84ae                	mv	s1,a1
    80002c0c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c0e:	fffff097          	auipc	ra,0xfffff
    80002c12:	eb6080e7          	jalr	-330(ra) # 80001ac4 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002c16:	86ce                	mv	a3,s3
    80002c18:	864a                	mv	a2,s2
    80002c1a:	85a6                	mv	a1,s1
    80002c1c:	6928                	ld	a0,80(a0)
    80002c1e:	fffff097          	auipc	ra,0xfffff
    80002c22:	c80080e7          	jalr	-896(ra) # 8000189e <copyinstr>
  if(err < 0)
    80002c26:	00054763          	bltz	a0,80002c34 <fetchstr+0x3a>
  return strlen(buf);
    80002c2a:	8526                	mv	a0,s1
    80002c2c:	ffffe097          	auipc	ra,0xffffe
    80002c30:	342080e7          	jalr	834(ra) # 80000f6e <strlen>
}
    80002c34:	70a2                	ld	ra,40(sp)
    80002c36:	7402                	ld	s0,32(sp)
    80002c38:	64e2                	ld	s1,24(sp)
    80002c3a:	6942                	ld	s2,16(sp)
    80002c3c:	69a2                	ld	s3,8(sp)
    80002c3e:	6145                	addi	sp,sp,48
    80002c40:	8082                	ret

0000000080002c42 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002c42:	1101                	addi	sp,sp,-32
    80002c44:	ec06                	sd	ra,24(sp)
    80002c46:	e822                	sd	s0,16(sp)
    80002c48:	e426                	sd	s1,8(sp)
    80002c4a:	1000                	addi	s0,sp,32
    80002c4c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c4e:	00000097          	auipc	ra,0x0
    80002c52:	ef2080e7          	jalr	-270(ra) # 80002b40 <argraw>
    80002c56:	c088                	sw	a0,0(s1)
  return 0;
}
    80002c58:	4501                	li	a0,0
    80002c5a:	60e2                	ld	ra,24(sp)
    80002c5c:	6442                	ld	s0,16(sp)
    80002c5e:	64a2                	ld	s1,8(sp)
    80002c60:	6105                	addi	sp,sp,32
    80002c62:	8082                	ret

0000000080002c64 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002c64:	1101                	addi	sp,sp,-32
    80002c66:	ec06                	sd	ra,24(sp)
    80002c68:	e822                	sd	s0,16(sp)
    80002c6a:	e426                	sd	s1,8(sp)
    80002c6c:	1000                	addi	s0,sp,32
    80002c6e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c70:	00000097          	auipc	ra,0x0
    80002c74:	ed0080e7          	jalr	-304(ra) # 80002b40 <argraw>
    80002c78:	e088                	sd	a0,0(s1)
  return 0;
}
    80002c7a:	4501                	li	a0,0
    80002c7c:	60e2                	ld	ra,24(sp)
    80002c7e:	6442                	ld	s0,16(sp)
    80002c80:	64a2                	ld	s1,8(sp)
    80002c82:	6105                	addi	sp,sp,32
    80002c84:	8082                	ret

0000000080002c86 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c86:	1101                	addi	sp,sp,-32
    80002c88:	ec06                	sd	ra,24(sp)
    80002c8a:	e822                	sd	s0,16(sp)
    80002c8c:	e426                	sd	s1,8(sp)
    80002c8e:	e04a                	sd	s2,0(sp)
    80002c90:	1000                	addi	s0,sp,32
    80002c92:	84ae                	mv	s1,a1
    80002c94:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002c96:	00000097          	auipc	ra,0x0
    80002c9a:	eaa080e7          	jalr	-342(ra) # 80002b40 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002c9e:	864a                	mv	a2,s2
    80002ca0:	85a6                	mv	a1,s1
    80002ca2:	00000097          	auipc	ra,0x0
    80002ca6:	f58080e7          	jalr	-168(ra) # 80002bfa <fetchstr>
}
    80002caa:	60e2                	ld	ra,24(sp)
    80002cac:	6442                	ld	s0,16(sp)
    80002cae:	64a2                	ld	s1,8(sp)
    80002cb0:	6902                	ld	s2,0(sp)
    80002cb2:	6105                	addi	sp,sp,32
    80002cb4:	8082                	ret

0000000080002cb6 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002cb6:	1101                	addi	sp,sp,-32
    80002cb8:	ec06                	sd	ra,24(sp)
    80002cba:	e822                	sd	s0,16(sp)
    80002cbc:	e426                	sd	s1,8(sp)
    80002cbe:	e04a                	sd	s2,0(sp)
    80002cc0:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002cc2:	fffff097          	auipc	ra,0xfffff
    80002cc6:	e02080e7          	jalr	-510(ra) # 80001ac4 <myproc>
    80002cca:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002ccc:	05853903          	ld	s2,88(a0)
    80002cd0:	0a893783          	ld	a5,168(s2)
    80002cd4:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002cd8:	37fd                	addiw	a5,a5,-1
    80002cda:	4751                	li	a4,20
    80002cdc:	00f76f63          	bltu	a4,a5,80002cfa <syscall+0x44>
    80002ce0:	00369713          	slli	a4,a3,0x3
    80002ce4:	00005797          	auipc	a5,0x5
    80002ce8:	77478793          	addi	a5,a5,1908 # 80008458 <syscalls>
    80002cec:	97ba                	add	a5,a5,a4
    80002cee:	639c                	ld	a5,0(a5)
    80002cf0:	c789                	beqz	a5,80002cfa <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002cf2:	9782                	jalr	a5
    80002cf4:	06a93823          	sd	a0,112(s2)
    80002cf8:	a839                	j	80002d16 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002cfa:	15848613          	addi	a2,s1,344
    80002cfe:	588c                	lw	a1,48(s1)
    80002d00:	00005517          	auipc	a0,0x5
    80002d04:	72050513          	addi	a0,a0,1824 # 80008420 <states.1720+0x150>
    80002d08:	ffffe097          	auipc	ra,0xffffe
    80002d0c:	880080e7          	jalr	-1920(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d10:	6cbc                	ld	a5,88(s1)
    80002d12:	577d                	li	a4,-1
    80002d14:	fbb8                	sd	a4,112(a5)
  }
}
    80002d16:	60e2                	ld	ra,24(sp)
    80002d18:	6442                	ld	s0,16(sp)
    80002d1a:	64a2                	ld	s1,8(sp)
    80002d1c:	6902                	ld	s2,0(sp)
    80002d1e:	6105                	addi	sp,sp,32
    80002d20:	8082                	ret

0000000080002d22 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d22:	1101                	addi	sp,sp,-32
    80002d24:	ec06                	sd	ra,24(sp)
    80002d26:	e822                	sd	s0,16(sp)
    80002d28:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002d2a:	fec40593          	addi	a1,s0,-20
    80002d2e:	4501                	li	a0,0
    80002d30:	00000097          	auipc	ra,0x0
    80002d34:	f12080e7          	jalr	-238(ra) # 80002c42 <argint>
    return -1;
    80002d38:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d3a:	00054963          	bltz	a0,80002d4c <sys_exit+0x2a>
  exit(n);
    80002d3e:	fec42503          	lw	a0,-20(s0)
    80002d42:	fffff097          	auipc	ra,0xfffff
    80002d46:	69a080e7          	jalr	1690(ra) # 800023dc <exit>
  return 0;  // not reached
    80002d4a:	4781                	li	a5,0
}
    80002d4c:	853e                	mv	a0,a5
    80002d4e:	60e2                	ld	ra,24(sp)
    80002d50:	6442                	ld	s0,16(sp)
    80002d52:	6105                	addi	sp,sp,32
    80002d54:	8082                	ret

0000000080002d56 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d56:	1141                	addi	sp,sp,-16
    80002d58:	e406                	sd	ra,8(sp)
    80002d5a:	e022                	sd	s0,0(sp)
    80002d5c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d5e:	fffff097          	auipc	ra,0xfffff
    80002d62:	d66080e7          	jalr	-666(ra) # 80001ac4 <myproc>
}
    80002d66:	5908                	lw	a0,48(a0)
    80002d68:	60a2                	ld	ra,8(sp)
    80002d6a:	6402                	ld	s0,0(sp)
    80002d6c:	0141                	addi	sp,sp,16
    80002d6e:	8082                	ret

0000000080002d70 <sys_fork>:

uint64
sys_fork(void)
{
    80002d70:	1141                	addi	sp,sp,-16
    80002d72:	e406                	sd	ra,8(sp)
    80002d74:	e022                	sd	s0,0(sp)
    80002d76:	0800                	addi	s0,sp,16
  return fork();
    80002d78:	fffff097          	auipc	ra,0xfffff
    80002d7c:	11a080e7          	jalr	282(ra) # 80001e92 <fork>
}
    80002d80:	60a2                	ld	ra,8(sp)
    80002d82:	6402                	ld	s0,0(sp)
    80002d84:	0141                	addi	sp,sp,16
    80002d86:	8082                	ret

0000000080002d88 <sys_wait>:

uint64
sys_wait(void)
{
    80002d88:	1101                	addi	sp,sp,-32
    80002d8a:	ec06                	sd	ra,24(sp)
    80002d8c:	e822                	sd	s0,16(sp)
    80002d8e:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002d90:	fe840593          	addi	a1,s0,-24
    80002d94:	4501                	li	a0,0
    80002d96:	00000097          	auipc	ra,0x0
    80002d9a:	ece080e7          	jalr	-306(ra) # 80002c64 <argaddr>
    80002d9e:	87aa                	mv	a5,a0
    return -1;
    80002da0:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002da2:	0007c863          	bltz	a5,80002db2 <sys_wait+0x2a>
  return wait(p);
    80002da6:	fe843503          	ld	a0,-24(s0)
    80002daa:	fffff097          	auipc	ra,0xfffff
    80002dae:	43a080e7          	jalr	1082(ra) # 800021e4 <wait>
}
    80002db2:	60e2                	ld	ra,24(sp)
    80002db4:	6442                	ld	s0,16(sp)
    80002db6:	6105                	addi	sp,sp,32
    80002db8:	8082                	ret

0000000080002dba <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002dba:	7179                	addi	sp,sp,-48
    80002dbc:	f406                	sd	ra,40(sp)
    80002dbe:	f022                	sd	s0,32(sp)
    80002dc0:	ec26                	sd	s1,24(sp)
    80002dc2:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002dc4:	fdc40593          	addi	a1,s0,-36
    80002dc8:	4501                	li	a0,0
    80002dca:	00000097          	auipc	ra,0x0
    80002dce:	e78080e7          	jalr	-392(ra) # 80002c42 <argint>
    80002dd2:	87aa                	mv	a5,a0
    return -1;
    80002dd4:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002dd6:	0207c063          	bltz	a5,80002df6 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002dda:	fffff097          	auipc	ra,0xfffff
    80002dde:	cea080e7          	jalr	-790(ra) # 80001ac4 <myproc>
    80002de2:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002de4:	fdc42503          	lw	a0,-36(s0)
    80002de8:	fffff097          	auipc	ra,0xfffff
    80002dec:	036080e7          	jalr	54(ra) # 80001e1e <growproc>
    80002df0:	00054863          	bltz	a0,80002e00 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002df4:	8526                	mv	a0,s1
}
    80002df6:	70a2                	ld	ra,40(sp)
    80002df8:	7402                	ld	s0,32(sp)
    80002dfa:	64e2                	ld	s1,24(sp)
    80002dfc:	6145                	addi	sp,sp,48
    80002dfe:	8082                	ret
    return -1;
    80002e00:	557d                	li	a0,-1
    80002e02:	bfd5                	j	80002df6 <sys_sbrk+0x3c>

0000000080002e04 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e04:	7139                	addi	sp,sp,-64
    80002e06:	fc06                	sd	ra,56(sp)
    80002e08:	f822                	sd	s0,48(sp)
    80002e0a:	f426                	sd	s1,40(sp)
    80002e0c:	f04a                	sd	s2,32(sp)
    80002e0e:	ec4e                	sd	s3,24(sp)
    80002e10:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002e12:	fcc40593          	addi	a1,s0,-52
    80002e16:	4501                	li	a0,0
    80002e18:	00000097          	auipc	ra,0x0
    80002e1c:	e2a080e7          	jalr	-470(ra) # 80002c42 <argint>
    return -1;
    80002e20:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e22:	06054563          	bltz	a0,80002e8c <sys_sleep+0x88>
  acquire(&tickslock);
    80002e26:	00034517          	auipc	a0,0x34
    80002e2a:	2c250513          	addi	a0,a0,706 # 800370e8 <tickslock>
    80002e2e:	ffffe097          	auipc	ra,0xffffe
    80002e32:	ec0080e7          	jalr	-320(ra) # 80000cee <acquire>
  ticks0 = ticks;
    80002e36:	00006917          	auipc	s2,0x6
    80002e3a:	1fa92903          	lw	s2,506(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002e3e:	fcc42783          	lw	a5,-52(s0)
    80002e42:	cf85                	beqz	a5,80002e7a <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e44:	00034997          	auipc	s3,0x34
    80002e48:	2a498993          	addi	s3,s3,676 # 800370e8 <tickslock>
    80002e4c:	00006497          	auipc	s1,0x6
    80002e50:	1e448493          	addi	s1,s1,484 # 80009030 <ticks>
    if(myproc()->killed){
    80002e54:	fffff097          	auipc	ra,0xfffff
    80002e58:	c70080e7          	jalr	-912(ra) # 80001ac4 <myproc>
    80002e5c:	551c                	lw	a5,40(a0)
    80002e5e:	ef9d                	bnez	a5,80002e9c <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002e60:	85ce                	mv	a1,s3
    80002e62:	8526                	mv	a0,s1
    80002e64:	fffff097          	auipc	ra,0xfffff
    80002e68:	31c080e7          	jalr	796(ra) # 80002180 <sleep>
  while(ticks - ticks0 < n){
    80002e6c:	409c                	lw	a5,0(s1)
    80002e6e:	412787bb          	subw	a5,a5,s2
    80002e72:	fcc42703          	lw	a4,-52(s0)
    80002e76:	fce7efe3          	bltu	a5,a4,80002e54 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002e7a:	00034517          	auipc	a0,0x34
    80002e7e:	26e50513          	addi	a0,a0,622 # 800370e8 <tickslock>
    80002e82:	ffffe097          	auipc	ra,0xffffe
    80002e86:	f20080e7          	jalr	-224(ra) # 80000da2 <release>
  return 0;
    80002e8a:	4781                	li	a5,0
}
    80002e8c:	853e                	mv	a0,a5
    80002e8e:	70e2                	ld	ra,56(sp)
    80002e90:	7442                	ld	s0,48(sp)
    80002e92:	74a2                	ld	s1,40(sp)
    80002e94:	7902                	ld	s2,32(sp)
    80002e96:	69e2                	ld	s3,24(sp)
    80002e98:	6121                	addi	sp,sp,64
    80002e9a:	8082                	ret
      release(&tickslock);
    80002e9c:	00034517          	auipc	a0,0x34
    80002ea0:	24c50513          	addi	a0,a0,588 # 800370e8 <tickslock>
    80002ea4:	ffffe097          	auipc	ra,0xffffe
    80002ea8:	efe080e7          	jalr	-258(ra) # 80000da2 <release>
      return -1;
    80002eac:	57fd                	li	a5,-1
    80002eae:	bff9                	j	80002e8c <sys_sleep+0x88>

0000000080002eb0 <sys_kill>:

uint64
sys_kill(void)
{
    80002eb0:	1101                	addi	sp,sp,-32
    80002eb2:	ec06                	sd	ra,24(sp)
    80002eb4:	e822                	sd	s0,16(sp)
    80002eb6:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002eb8:	fec40593          	addi	a1,s0,-20
    80002ebc:	4501                	li	a0,0
    80002ebe:	00000097          	auipc	ra,0x0
    80002ec2:	d84080e7          	jalr	-636(ra) # 80002c42 <argint>
    80002ec6:	87aa                	mv	a5,a0
    return -1;
    80002ec8:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002eca:	0007c863          	bltz	a5,80002eda <sys_kill+0x2a>
  return kill(pid);
    80002ece:	fec42503          	lw	a0,-20(s0)
    80002ed2:	fffff097          	auipc	ra,0xfffff
    80002ed6:	5e0080e7          	jalr	1504(ra) # 800024b2 <kill>
}
    80002eda:	60e2                	ld	ra,24(sp)
    80002edc:	6442                	ld	s0,16(sp)
    80002ede:	6105                	addi	sp,sp,32
    80002ee0:	8082                	ret

0000000080002ee2 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002ee2:	1101                	addi	sp,sp,-32
    80002ee4:	ec06                	sd	ra,24(sp)
    80002ee6:	e822                	sd	s0,16(sp)
    80002ee8:	e426                	sd	s1,8(sp)
    80002eea:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002eec:	00034517          	auipc	a0,0x34
    80002ef0:	1fc50513          	addi	a0,a0,508 # 800370e8 <tickslock>
    80002ef4:	ffffe097          	auipc	ra,0xffffe
    80002ef8:	dfa080e7          	jalr	-518(ra) # 80000cee <acquire>
  xticks = ticks;
    80002efc:	00006497          	auipc	s1,0x6
    80002f00:	1344a483          	lw	s1,308(s1) # 80009030 <ticks>
  release(&tickslock);
    80002f04:	00034517          	auipc	a0,0x34
    80002f08:	1e450513          	addi	a0,a0,484 # 800370e8 <tickslock>
    80002f0c:	ffffe097          	auipc	ra,0xffffe
    80002f10:	e96080e7          	jalr	-362(ra) # 80000da2 <release>
  return xticks;
}
    80002f14:	02049513          	slli	a0,s1,0x20
    80002f18:	9101                	srli	a0,a0,0x20
    80002f1a:	60e2                	ld	ra,24(sp)
    80002f1c:	6442                	ld	s0,16(sp)
    80002f1e:	64a2                	ld	s1,8(sp)
    80002f20:	6105                	addi	sp,sp,32
    80002f22:	8082                	ret

0000000080002f24 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f24:	7179                	addi	sp,sp,-48
    80002f26:	f406                	sd	ra,40(sp)
    80002f28:	f022                	sd	s0,32(sp)
    80002f2a:	ec26                	sd	s1,24(sp)
    80002f2c:	e84a                	sd	s2,16(sp)
    80002f2e:	e44e                	sd	s3,8(sp)
    80002f30:	e052                	sd	s4,0(sp)
    80002f32:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f34:	00005597          	auipc	a1,0x5
    80002f38:	5d458593          	addi	a1,a1,1492 # 80008508 <syscalls+0xb0>
    80002f3c:	00034517          	auipc	a0,0x34
    80002f40:	1c450513          	addi	a0,a0,452 # 80037100 <bcache>
    80002f44:	ffffe097          	auipc	ra,0xffffe
    80002f48:	d1a080e7          	jalr	-742(ra) # 80000c5e <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f4c:	0003c797          	auipc	a5,0x3c
    80002f50:	1b478793          	addi	a5,a5,436 # 8003f100 <bcache+0x8000>
    80002f54:	0003c717          	auipc	a4,0x3c
    80002f58:	41470713          	addi	a4,a4,1044 # 8003f368 <bcache+0x8268>
    80002f5c:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f60:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f64:	00034497          	auipc	s1,0x34
    80002f68:	1b448493          	addi	s1,s1,436 # 80037118 <bcache+0x18>
    b->next = bcache.head.next;
    80002f6c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f6e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f70:	00005a17          	auipc	s4,0x5
    80002f74:	5a0a0a13          	addi	s4,s4,1440 # 80008510 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002f78:	2b893783          	ld	a5,696(s2)
    80002f7c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f7e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f82:	85d2                	mv	a1,s4
    80002f84:	01048513          	addi	a0,s1,16
    80002f88:	00001097          	auipc	ra,0x1
    80002f8c:	4bc080e7          	jalr	1212(ra) # 80004444 <initsleeplock>
    bcache.head.next->prev = b;
    80002f90:	2b893783          	ld	a5,696(s2)
    80002f94:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f96:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f9a:	45848493          	addi	s1,s1,1112
    80002f9e:	fd349de3          	bne	s1,s3,80002f78 <binit+0x54>
  }
}
    80002fa2:	70a2                	ld	ra,40(sp)
    80002fa4:	7402                	ld	s0,32(sp)
    80002fa6:	64e2                	ld	s1,24(sp)
    80002fa8:	6942                	ld	s2,16(sp)
    80002faa:	69a2                	ld	s3,8(sp)
    80002fac:	6a02                	ld	s4,0(sp)
    80002fae:	6145                	addi	sp,sp,48
    80002fb0:	8082                	ret

0000000080002fb2 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002fb2:	7179                	addi	sp,sp,-48
    80002fb4:	f406                	sd	ra,40(sp)
    80002fb6:	f022                	sd	s0,32(sp)
    80002fb8:	ec26                	sd	s1,24(sp)
    80002fba:	e84a                	sd	s2,16(sp)
    80002fbc:	e44e                	sd	s3,8(sp)
    80002fbe:	1800                	addi	s0,sp,48
    80002fc0:	89aa                	mv	s3,a0
    80002fc2:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002fc4:	00034517          	auipc	a0,0x34
    80002fc8:	13c50513          	addi	a0,a0,316 # 80037100 <bcache>
    80002fcc:	ffffe097          	auipc	ra,0xffffe
    80002fd0:	d22080e7          	jalr	-734(ra) # 80000cee <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002fd4:	0003c497          	auipc	s1,0x3c
    80002fd8:	3e44b483          	ld	s1,996(s1) # 8003f3b8 <bcache+0x82b8>
    80002fdc:	0003c797          	auipc	a5,0x3c
    80002fe0:	38c78793          	addi	a5,a5,908 # 8003f368 <bcache+0x8268>
    80002fe4:	02f48f63          	beq	s1,a5,80003022 <bread+0x70>
    80002fe8:	873e                	mv	a4,a5
    80002fea:	a021                	j	80002ff2 <bread+0x40>
    80002fec:	68a4                	ld	s1,80(s1)
    80002fee:	02e48a63          	beq	s1,a4,80003022 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002ff2:	449c                	lw	a5,8(s1)
    80002ff4:	ff379ce3          	bne	a5,s3,80002fec <bread+0x3a>
    80002ff8:	44dc                	lw	a5,12(s1)
    80002ffa:	ff2799e3          	bne	a5,s2,80002fec <bread+0x3a>
      b->refcnt++;
    80002ffe:	40bc                	lw	a5,64(s1)
    80003000:	2785                	addiw	a5,a5,1
    80003002:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003004:	00034517          	auipc	a0,0x34
    80003008:	0fc50513          	addi	a0,a0,252 # 80037100 <bcache>
    8000300c:	ffffe097          	auipc	ra,0xffffe
    80003010:	d96080e7          	jalr	-618(ra) # 80000da2 <release>
      acquiresleep(&b->lock);
    80003014:	01048513          	addi	a0,s1,16
    80003018:	00001097          	auipc	ra,0x1
    8000301c:	466080e7          	jalr	1126(ra) # 8000447e <acquiresleep>
      return b;
    80003020:	a8b9                	j	8000307e <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003022:	0003c497          	auipc	s1,0x3c
    80003026:	38e4b483          	ld	s1,910(s1) # 8003f3b0 <bcache+0x82b0>
    8000302a:	0003c797          	auipc	a5,0x3c
    8000302e:	33e78793          	addi	a5,a5,830 # 8003f368 <bcache+0x8268>
    80003032:	00f48863          	beq	s1,a5,80003042 <bread+0x90>
    80003036:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003038:	40bc                	lw	a5,64(s1)
    8000303a:	cf81                	beqz	a5,80003052 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000303c:	64a4                	ld	s1,72(s1)
    8000303e:	fee49de3          	bne	s1,a4,80003038 <bread+0x86>
  panic("bget: no buffers");
    80003042:	00005517          	auipc	a0,0x5
    80003046:	4d650513          	addi	a0,a0,1238 # 80008518 <syscalls+0xc0>
    8000304a:	ffffd097          	auipc	ra,0xffffd
    8000304e:	4f4080e7          	jalr	1268(ra) # 8000053e <panic>
      b->dev = dev;
    80003052:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003056:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000305a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000305e:	4785                	li	a5,1
    80003060:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003062:	00034517          	auipc	a0,0x34
    80003066:	09e50513          	addi	a0,a0,158 # 80037100 <bcache>
    8000306a:	ffffe097          	auipc	ra,0xffffe
    8000306e:	d38080e7          	jalr	-712(ra) # 80000da2 <release>
      acquiresleep(&b->lock);
    80003072:	01048513          	addi	a0,s1,16
    80003076:	00001097          	auipc	ra,0x1
    8000307a:	408080e7          	jalr	1032(ra) # 8000447e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000307e:	409c                	lw	a5,0(s1)
    80003080:	cb89                	beqz	a5,80003092 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003082:	8526                	mv	a0,s1
    80003084:	70a2                	ld	ra,40(sp)
    80003086:	7402                	ld	s0,32(sp)
    80003088:	64e2                	ld	s1,24(sp)
    8000308a:	6942                	ld	s2,16(sp)
    8000308c:	69a2                	ld	s3,8(sp)
    8000308e:	6145                	addi	sp,sp,48
    80003090:	8082                	ret
    virtio_disk_rw(b, 0);
    80003092:	4581                	li	a1,0
    80003094:	8526                	mv	a0,s1
    80003096:	00003097          	auipc	ra,0x3
    8000309a:	f10080e7          	jalr	-240(ra) # 80005fa6 <virtio_disk_rw>
    b->valid = 1;
    8000309e:	4785                	li	a5,1
    800030a0:	c09c                	sw	a5,0(s1)
  return b;
    800030a2:	b7c5                	j	80003082 <bread+0xd0>

00000000800030a4 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800030a4:	1101                	addi	sp,sp,-32
    800030a6:	ec06                	sd	ra,24(sp)
    800030a8:	e822                	sd	s0,16(sp)
    800030aa:	e426                	sd	s1,8(sp)
    800030ac:	1000                	addi	s0,sp,32
    800030ae:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030b0:	0541                	addi	a0,a0,16
    800030b2:	00001097          	auipc	ra,0x1
    800030b6:	466080e7          	jalr	1126(ra) # 80004518 <holdingsleep>
    800030ba:	cd01                	beqz	a0,800030d2 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800030bc:	4585                	li	a1,1
    800030be:	8526                	mv	a0,s1
    800030c0:	00003097          	auipc	ra,0x3
    800030c4:	ee6080e7          	jalr	-282(ra) # 80005fa6 <virtio_disk_rw>
}
    800030c8:	60e2                	ld	ra,24(sp)
    800030ca:	6442                	ld	s0,16(sp)
    800030cc:	64a2                	ld	s1,8(sp)
    800030ce:	6105                	addi	sp,sp,32
    800030d0:	8082                	ret
    panic("bwrite");
    800030d2:	00005517          	auipc	a0,0x5
    800030d6:	45e50513          	addi	a0,a0,1118 # 80008530 <syscalls+0xd8>
    800030da:	ffffd097          	auipc	ra,0xffffd
    800030de:	464080e7          	jalr	1124(ra) # 8000053e <panic>

00000000800030e2 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030e2:	1101                	addi	sp,sp,-32
    800030e4:	ec06                	sd	ra,24(sp)
    800030e6:	e822                	sd	s0,16(sp)
    800030e8:	e426                	sd	s1,8(sp)
    800030ea:	e04a                	sd	s2,0(sp)
    800030ec:	1000                	addi	s0,sp,32
    800030ee:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030f0:	01050913          	addi	s2,a0,16
    800030f4:	854a                	mv	a0,s2
    800030f6:	00001097          	auipc	ra,0x1
    800030fa:	422080e7          	jalr	1058(ra) # 80004518 <holdingsleep>
    800030fe:	c92d                	beqz	a0,80003170 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003100:	854a                	mv	a0,s2
    80003102:	00001097          	auipc	ra,0x1
    80003106:	3d2080e7          	jalr	978(ra) # 800044d4 <releasesleep>

  acquire(&bcache.lock);
    8000310a:	00034517          	auipc	a0,0x34
    8000310e:	ff650513          	addi	a0,a0,-10 # 80037100 <bcache>
    80003112:	ffffe097          	auipc	ra,0xffffe
    80003116:	bdc080e7          	jalr	-1060(ra) # 80000cee <acquire>
  b->refcnt--;
    8000311a:	40bc                	lw	a5,64(s1)
    8000311c:	37fd                	addiw	a5,a5,-1
    8000311e:	0007871b          	sext.w	a4,a5
    80003122:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003124:	eb05                	bnez	a4,80003154 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003126:	68bc                	ld	a5,80(s1)
    80003128:	64b8                	ld	a4,72(s1)
    8000312a:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000312c:	64bc                	ld	a5,72(s1)
    8000312e:	68b8                	ld	a4,80(s1)
    80003130:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003132:	0003c797          	auipc	a5,0x3c
    80003136:	fce78793          	addi	a5,a5,-50 # 8003f100 <bcache+0x8000>
    8000313a:	2b87b703          	ld	a4,696(a5)
    8000313e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003140:	0003c717          	auipc	a4,0x3c
    80003144:	22870713          	addi	a4,a4,552 # 8003f368 <bcache+0x8268>
    80003148:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000314a:	2b87b703          	ld	a4,696(a5)
    8000314e:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003150:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003154:	00034517          	auipc	a0,0x34
    80003158:	fac50513          	addi	a0,a0,-84 # 80037100 <bcache>
    8000315c:	ffffe097          	auipc	ra,0xffffe
    80003160:	c46080e7          	jalr	-954(ra) # 80000da2 <release>
}
    80003164:	60e2                	ld	ra,24(sp)
    80003166:	6442                	ld	s0,16(sp)
    80003168:	64a2                	ld	s1,8(sp)
    8000316a:	6902                	ld	s2,0(sp)
    8000316c:	6105                	addi	sp,sp,32
    8000316e:	8082                	ret
    panic("brelse");
    80003170:	00005517          	auipc	a0,0x5
    80003174:	3c850513          	addi	a0,a0,968 # 80008538 <syscalls+0xe0>
    80003178:	ffffd097          	auipc	ra,0xffffd
    8000317c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>

0000000080003180 <bpin>:

void
bpin(struct buf *b) {
    80003180:	1101                	addi	sp,sp,-32
    80003182:	ec06                	sd	ra,24(sp)
    80003184:	e822                	sd	s0,16(sp)
    80003186:	e426                	sd	s1,8(sp)
    80003188:	1000                	addi	s0,sp,32
    8000318a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000318c:	00034517          	auipc	a0,0x34
    80003190:	f7450513          	addi	a0,a0,-140 # 80037100 <bcache>
    80003194:	ffffe097          	auipc	ra,0xffffe
    80003198:	b5a080e7          	jalr	-1190(ra) # 80000cee <acquire>
  b->refcnt++;
    8000319c:	40bc                	lw	a5,64(s1)
    8000319e:	2785                	addiw	a5,a5,1
    800031a0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031a2:	00034517          	auipc	a0,0x34
    800031a6:	f5e50513          	addi	a0,a0,-162 # 80037100 <bcache>
    800031aa:	ffffe097          	auipc	ra,0xffffe
    800031ae:	bf8080e7          	jalr	-1032(ra) # 80000da2 <release>
}
    800031b2:	60e2                	ld	ra,24(sp)
    800031b4:	6442                	ld	s0,16(sp)
    800031b6:	64a2                	ld	s1,8(sp)
    800031b8:	6105                	addi	sp,sp,32
    800031ba:	8082                	ret

00000000800031bc <bunpin>:

void
bunpin(struct buf *b) {
    800031bc:	1101                	addi	sp,sp,-32
    800031be:	ec06                	sd	ra,24(sp)
    800031c0:	e822                	sd	s0,16(sp)
    800031c2:	e426                	sd	s1,8(sp)
    800031c4:	1000                	addi	s0,sp,32
    800031c6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031c8:	00034517          	auipc	a0,0x34
    800031cc:	f3850513          	addi	a0,a0,-200 # 80037100 <bcache>
    800031d0:	ffffe097          	auipc	ra,0xffffe
    800031d4:	b1e080e7          	jalr	-1250(ra) # 80000cee <acquire>
  b->refcnt--;
    800031d8:	40bc                	lw	a5,64(s1)
    800031da:	37fd                	addiw	a5,a5,-1
    800031dc:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031de:	00034517          	auipc	a0,0x34
    800031e2:	f2250513          	addi	a0,a0,-222 # 80037100 <bcache>
    800031e6:	ffffe097          	auipc	ra,0xffffe
    800031ea:	bbc080e7          	jalr	-1092(ra) # 80000da2 <release>
}
    800031ee:	60e2                	ld	ra,24(sp)
    800031f0:	6442                	ld	s0,16(sp)
    800031f2:	64a2                	ld	s1,8(sp)
    800031f4:	6105                	addi	sp,sp,32
    800031f6:	8082                	ret

00000000800031f8 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031f8:	1101                	addi	sp,sp,-32
    800031fa:	ec06                	sd	ra,24(sp)
    800031fc:	e822                	sd	s0,16(sp)
    800031fe:	e426                	sd	s1,8(sp)
    80003200:	e04a                	sd	s2,0(sp)
    80003202:	1000                	addi	s0,sp,32
    80003204:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003206:	00d5d59b          	srliw	a1,a1,0xd
    8000320a:	0003c797          	auipc	a5,0x3c
    8000320e:	5d27a783          	lw	a5,1490(a5) # 8003f7dc <sb+0x1c>
    80003212:	9dbd                	addw	a1,a1,a5
    80003214:	00000097          	auipc	ra,0x0
    80003218:	d9e080e7          	jalr	-610(ra) # 80002fb2 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000321c:	0074f713          	andi	a4,s1,7
    80003220:	4785                	li	a5,1
    80003222:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003226:	14ce                	slli	s1,s1,0x33
    80003228:	90d9                	srli	s1,s1,0x36
    8000322a:	00950733          	add	a4,a0,s1
    8000322e:	05874703          	lbu	a4,88(a4)
    80003232:	00e7f6b3          	and	a3,a5,a4
    80003236:	c69d                	beqz	a3,80003264 <bfree+0x6c>
    80003238:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000323a:	94aa                	add	s1,s1,a0
    8000323c:	fff7c793          	not	a5,a5
    80003240:	8ff9                	and	a5,a5,a4
    80003242:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003246:	00001097          	auipc	ra,0x1
    8000324a:	118080e7          	jalr	280(ra) # 8000435e <log_write>
  brelse(bp);
    8000324e:	854a                	mv	a0,s2
    80003250:	00000097          	auipc	ra,0x0
    80003254:	e92080e7          	jalr	-366(ra) # 800030e2 <brelse>
}
    80003258:	60e2                	ld	ra,24(sp)
    8000325a:	6442                	ld	s0,16(sp)
    8000325c:	64a2                	ld	s1,8(sp)
    8000325e:	6902                	ld	s2,0(sp)
    80003260:	6105                	addi	sp,sp,32
    80003262:	8082                	ret
    panic("freeing free block");
    80003264:	00005517          	auipc	a0,0x5
    80003268:	2dc50513          	addi	a0,a0,732 # 80008540 <syscalls+0xe8>
    8000326c:	ffffd097          	auipc	ra,0xffffd
    80003270:	2d2080e7          	jalr	722(ra) # 8000053e <panic>

0000000080003274 <balloc>:
{
    80003274:	711d                	addi	sp,sp,-96
    80003276:	ec86                	sd	ra,88(sp)
    80003278:	e8a2                	sd	s0,80(sp)
    8000327a:	e4a6                	sd	s1,72(sp)
    8000327c:	e0ca                	sd	s2,64(sp)
    8000327e:	fc4e                	sd	s3,56(sp)
    80003280:	f852                	sd	s4,48(sp)
    80003282:	f456                	sd	s5,40(sp)
    80003284:	f05a                	sd	s6,32(sp)
    80003286:	ec5e                	sd	s7,24(sp)
    80003288:	e862                	sd	s8,16(sp)
    8000328a:	e466                	sd	s9,8(sp)
    8000328c:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000328e:	0003c797          	auipc	a5,0x3c
    80003292:	5367a783          	lw	a5,1334(a5) # 8003f7c4 <sb+0x4>
    80003296:	cbd1                	beqz	a5,8000332a <balloc+0xb6>
    80003298:	8baa                	mv	s7,a0
    8000329a:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000329c:	0003cb17          	auipc	s6,0x3c
    800032a0:	524b0b13          	addi	s6,s6,1316 # 8003f7c0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032a4:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800032a6:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032a8:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800032aa:	6c89                	lui	s9,0x2
    800032ac:	a831                	j	800032c8 <balloc+0x54>
    brelse(bp);
    800032ae:	854a                	mv	a0,s2
    800032b0:	00000097          	auipc	ra,0x0
    800032b4:	e32080e7          	jalr	-462(ra) # 800030e2 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800032b8:	015c87bb          	addw	a5,s9,s5
    800032bc:	00078a9b          	sext.w	s5,a5
    800032c0:	004b2703          	lw	a4,4(s6)
    800032c4:	06eaf363          	bgeu	s5,a4,8000332a <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800032c8:	41fad79b          	sraiw	a5,s5,0x1f
    800032cc:	0137d79b          	srliw	a5,a5,0x13
    800032d0:	015787bb          	addw	a5,a5,s5
    800032d4:	40d7d79b          	sraiw	a5,a5,0xd
    800032d8:	01cb2583          	lw	a1,28(s6)
    800032dc:	9dbd                	addw	a1,a1,a5
    800032de:	855e                	mv	a0,s7
    800032e0:	00000097          	auipc	ra,0x0
    800032e4:	cd2080e7          	jalr	-814(ra) # 80002fb2 <bread>
    800032e8:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032ea:	004b2503          	lw	a0,4(s6)
    800032ee:	000a849b          	sext.w	s1,s5
    800032f2:	8662                	mv	a2,s8
    800032f4:	faa4fde3          	bgeu	s1,a0,800032ae <balloc+0x3a>
      m = 1 << (bi % 8);
    800032f8:	41f6579b          	sraiw	a5,a2,0x1f
    800032fc:	01d7d69b          	srliw	a3,a5,0x1d
    80003300:	00c6873b          	addw	a4,a3,a2
    80003304:	00777793          	andi	a5,a4,7
    80003308:	9f95                	subw	a5,a5,a3
    8000330a:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000330e:	4037571b          	sraiw	a4,a4,0x3
    80003312:	00e906b3          	add	a3,s2,a4
    80003316:	0586c683          	lbu	a3,88(a3)
    8000331a:	00d7f5b3          	and	a1,a5,a3
    8000331e:	cd91                	beqz	a1,8000333a <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003320:	2605                	addiw	a2,a2,1
    80003322:	2485                	addiw	s1,s1,1
    80003324:	fd4618e3          	bne	a2,s4,800032f4 <balloc+0x80>
    80003328:	b759                	j	800032ae <balloc+0x3a>
  panic("balloc: out of blocks");
    8000332a:	00005517          	auipc	a0,0x5
    8000332e:	22e50513          	addi	a0,a0,558 # 80008558 <syscalls+0x100>
    80003332:	ffffd097          	auipc	ra,0xffffd
    80003336:	20c080e7          	jalr	524(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000333a:	974a                	add	a4,a4,s2
    8000333c:	8fd5                	or	a5,a5,a3
    8000333e:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003342:	854a                	mv	a0,s2
    80003344:	00001097          	auipc	ra,0x1
    80003348:	01a080e7          	jalr	26(ra) # 8000435e <log_write>
        brelse(bp);
    8000334c:	854a                	mv	a0,s2
    8000334e:	00000097          	auipc	ra,0x0
    80003352:	d94080e7          	jalr	-620(ra) # 800030e2 <brelse>
  bp = bread(dev, bno);
    80003356:	85a6                	mv	a1,s1
    80003358:	855e                	mv	a0,s7
    8000335a:	00000097          	auipc	ra,0x0
    8000335e:	c58080e7          	jalr	-936(ra) # 80002fb2 <bread>
    80003362:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003364:	40000613          	li	a2,1024
    80003368:	4581                	li	a1,0
    8000336a:	05850513          	addi	a0,a0,88
    8000336e:	ffffe097          	auipc	ra,0xffffe
    80003372:	a7c080e7          	jalr	-1412(ra) # 80000dea <memset>
  log_write(bp);
    80003376:	854a                	mv	a0,s2
    80003378:	00001097          	auipc	ra,0x1
    8000337c:	fe6080e7          	jalr	-26(ra) # 8000435e <log_write>
  brelse(bp);
    80003380:	854a                	mv	a0,s2
    80003382:	00000097          	auipc	ra,0x0
    80003386:	d60080e7          	jalr	-672(ra) # 800030e2 <brelse>
}
    8000338a:	8526                	mv	a0,s1
    8000338c:	60e6                	ld	ra,88(sp)
    8000338e:	6446                	ld	s0,80(sp)
    80003390:	64a6                	ld	s1,72(sp)
    80003392:	6906                	ld	s2,64(sp)
    80003394:	79e2                	ld	s3,56(sp)
    80003396:	7a42                	ld	s4,48(sp)
    80003398:	7aa2                	ld	s5,40(sp)
    8000339a:	7b02                	ld	s6,32(sp)
    8000339c:	6be2                	ld	s7,24(sp)
    8000339e:	6c42                	ld	s8,16(sp)
    800033a0:	6ca2                	ld	s9,8(sp)
    800033a2:	6125                	addi	sp,sp,96
    800033a4:	8082                	ret

00000000800033a6 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800033a6:	7179                	addi	sp,sp,-48
    800033a8:	f406                	sd	ra,40(sp)
    800033aa:	f022                	sd	s0,32(sp)
    800033ac:	ec26                	sd	s1,24(sp)
    800033ae:	e84a                	sd	s2,16(sp)
    800033b0:	e44e                	sd	s3,8(sp)
    800033b2:	e052                	sd	s4,0(sp)
    800033b4:	1800                	addi	s0,sp,48
    800033b6:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800033b8:	47ad                	li	a5,11
    800033ba:	04b7fe63          	bgeu	a5,a1,80003416 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800033be:	ff45849b          	addiw	s1,a1,-12
    800033c2:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033c6:	0ff00793          	li	a5,255
    800033ca:	0ae7e363          	bltu	a5,a4,80003470 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800033ce:	08052583          	lw	a1,128(a0)
    800033d2:	c5ad                	beqz	a1,8000343c <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800033d4:	00092503          	lw	a0,0(s2)
    800033d8:	00000097          	auipc	ra,0x0
    800033dc:	bda080e7          	jalr	-1062(ra) # 80002fb2 <bread>
    800033e0:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800033e2:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033e6:	02049593          	slli	a1,s1,0x20
    800033ea:	9181                	srli	a1,a1,0x20
    800033ec:	058a                	slli	a1,a1,0x2
    800033ee:	00b784b3          	add	s1,a5,a1
    800033f2:	0004a983          	lw	s3,0(s1)
    800033f6:	04098d63          	beqz	s3,80003450 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800033fa:	8552                	mv	a0,s4
    800033fc:	00000097          	auipc	ra,0x0
    80003400:	ce6080e7          	jalr	-794(ra) # 800030e2 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003404:	854e                	mv	a0,s3
    80003406:	70a2                	ld	ra,40(sp)
    80003408:	7402                	ld	s0,32(sp)
    8000340a:	64e2                	ld	s1,24(sp)
    8000340c:	6942                	ld	s2,16(sp)
    8000340e:	69a2                	ld	s3,8(sp)
    80003410:	6a02                	ld	s4,0(sp)
    80003412:	6145                	addi	sp,sp,48
    80003414:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003416:	02059493          	slli	s1,a1,0x20
    8000341a:	9081                	srli	s1,s1,0x20
    8000341c:	048a                	slli	s1,s1,0x2
    8000341e:	94aa                	add	s1,s1,a0
    80003420:	0504a983          	lw	s3,80(s1)
    80003424:	fe0990e3          	bnez	s3,80003404 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003428:	4108                	lw	a0,0(a0)
    8000342a:	00000097          	auipc	ra,0x0
    8000342e:	e4a080e7          	jalr	-438(ra) # 80003274 <balloc>
    80003432:	0005099b          	sext.w	s3,a0
    80003436:	0534a823          	sw	s3,80(s1)
    8000343a:	b7e9                	j	80003404 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000343c:	4108                	lw	a0,0(a0)
    8000343e:	00000097          	auipc	ra,0x0
    80003442:	e36080e7          	jalr	-458(ra) # 80003274 <balloc>
    80003446:	0005059b          	sext.w	a1,a0
    8000344a:	08b92023          	sw	a1,128(s2)
    8000344e:	b759                	j	800033d4 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003450:	00092503          	lw	a0,0(s2)
    80003454:	00000097          	auipc	ra,0x0
    80003458:	e20080e7          	jalr	-480(ra) # 80003274 <balloc>
    8000345c:	0005099b          	sext.w	s3,a0
    80003460:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003464:	8552                	mv	a0,s4
    80003466:	00001097          	auipc	ra,0x1
    8000346a:	ef8080e7          	jalr	-264(ra) # 8000435e <log_write>
    8000346e:	b771                	j	800033fa <bmap+0x54>
  panic("bmap: out of range");
    80003470:	00005517          	auipc	a0,0x5
    80003474:	10050513          	addi	a0,a0,256 # 80008570 <syscalls+0x118>
    80003478:	ffffd097          	auipc	ra,0xffffd
    8000347c:	0c6080e7          	jalr	198(ra) # 8000053e <panic>

0000000080003480 <iget>:
{
    80003480:	7179                	addi	sp,sp,-48
    80003482:	f406                	sd	ra,40(sp)
    80003484:	f022                	sd	s0,32(sp)
    80003486:	ec26                	sd	s1,24(sp)
    80003488:	e84a                	sd	s2,16(sp)
    8000348a:	e44e                	sd	s3,8(sp)
    8000348c:	e052                	sd	s4,0(sp)
    8000348e:	1800                	addi	s0,sp,48
    80003490:	89aa                	mv	s3,a0
    80003492:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003494:	0003c517          	auipc	a0,0x3c
    80003498:	34c50513          	addi	a0,a0,844 # 8003f7e0 <itable>
    8000349c:	ffffe097          	auipc	ra,0xffffe
    800034a0:	852080e7          	jalr	-1966(ra) # 80000cee <acquire>
  empty = 0;
    800034a4:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034a6:	0003c497          	auipc	s1,0x3c
    800034aa:	35248493          	addi	s1,s1,850 # 8003f7f8 <itable+0x18>
    800034ae:	0003e697          	auipc	a3,0x3e
    800034b2:	dda68693          	addi	a3,a3,-550 # 80041288 <log>
    800034b6:	a039                	j	800034c4 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034b8:	02090b63          	beqz	s2,800034ee <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034bc:	08848493          	addi	s1,s1,136
    800034c0:	02d48a63          	beq	s1,a3,800034f4 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034c4:	449c                	lw	a5,8(s1)
    800034c6:	fef059e3          	blez	a5,800034b8 <iget+0x38>
    800034ca:	4098                	lw	a4,0(s1)
    800034cc:	ff3716e3          	bne	a4,s3,800034b8 <iget+0x38>
    800034d0:	40d8                	lw	a4,4(s1)
    800034d2:	ff4713e3          	bne	a4,s4,800034b8 <iget+0x38>
      ip->ref++;
    800034d6:	2785                	addiw	a5,a5,1
    800034d8:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800034da:	0003c517          	auipc	a0,0x3c
    800034de:	30650513          	addi	a0,a0,774 # 8003f7e0 <itable>
    800034e2:	ffffe097          	auipc	ra,0xffffe
    800034e6:	8c0080e7          	jalr	-1856(ra) # 80000da2 <release>
      return ip;
    800034ea:	8926                	mv	s2,s1
    800034ec:	a03d                	j	8000351a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034ee:	f7f9                	bnez	a5,800034bc <iget+0x3c>
    800034f0:	8926                	mv	s2,s1
    800034f2:	b7e9                	j	800034bc <iget+0x3c>
  if(empty == 0)
    800034f4:	02090c63          	beqz	s2,8000352c <iget+0xac>
  ip->dev = dev;
    800034f8:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800034fc:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003500:	4785                	li	a5,1
    80003502:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003506:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000350a:	0003c517          	auipc	a0,0x3c
    8000350e:	2d650513          	addi	a0,a0,726 # 8003f7e0 <itable>
    80003512:	ffffe097          	auipc	ra,0xffffe
    80003516:	890080e7          	jalr	-1904(ra) # 80000da2 <release>
}
    8000351a:	854a                	mv	a0,s2
    8000351c:	70a2                	ld	ra,40(sp)
    8000351e:	7402                	ld	s0,32(sp)
    80003520:	64e2                	ld	s1,24(sp)
    80003522:	6942                	ld	s2,16(sp)
    80003524:	69a2                	ld	s3,8(sp)
    80003526:	6a02                	ld	s4,0(sp)
    80003528:	6145                	addi	sp,sp,48
    8000352a:	8082                	ret
    panic("iget: no inodes");
    8000352c:	00005517          	auipc	a0,0x5
    80003530:	05c50513          	addi	a0,a0,92 # 80008588 <syscalls+0x130>
    80003534:	ffffd097          	auipc	ra,0xffffd
    80003538:	00a080e7          	jalr	10(ra) # 8000053e <panic>

000000008000353c <fsinit>:
fsinit(int dev) {
    8000353c:	7179                	addi	sp,sp,-48
    8000353e:	f406                	sd	ra,40(sp)
    80003540:	f022                	sd	s0,32(sp)
    80003542:	ec26                	sd	s1,24(sp)
    80003544:	e84a                	sd	s2,16(sp)
    80003546:	e44e                	sd	s3,8(sp)
    80003548:	1800                	addi	s0,sp,48
    8000354a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000354c:	4585                	li	a1,1
    8000354e:	00000097          	auipc	ra,0x0
    80003552:	a64080e7          	jalr	-1436(ra) # 80002fb2 <bread>
    80003556:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003558:	0003c997          	auipc	s3,0x3c
    8000355c:	26898993          	addi	s3,s3,616 # 8003f7c0 <sb>
    80003560:	02000613          	li	a2,32
    80003564:	05850593          	addi	a1,a0,88
    80003568:	854e                	mv	a0,s3
    8000356a:	ffffe097          	auipc	ra,0xffffe
    8000356e:	8e0080e7          	jalr	-1824(ra) # 80000e4a <memmove>
  brelse(bp);
    80003572:	8526                	mv	a0,s1
    80003574:	00000097          	auipc	ra,0x0
    80003578:	b6e080e7          	jalr	-1170(ra) # 800030e2 <brelse>
  if(sb.magic != FSMAGIC)
    8000357c:	0009a703          	lw	a4,0(s3)
    80003580:	102037b7          	lui	a5,0x10203
    80003584:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003588:	02f71263          	bne	a4,a5,800035ac <fsinit+0x70>
  initlog(dev, &sb);
    8000358c:	0003c597          	auipc	a1,0x3c
    80003590:	23458593          	addi	a1,a1,564 # 8003f7c0 <sb>
    80003594:	854a                	mv	a0,s2
    80003596:	00001097          	auipc	ra,0x1
    8000359a:	b4c080e7          	jalr	-1204(ra) # 800040e2 <initlog>
}
    8000359e:	70a2                	ld	ra,40(sp)
    800035a0:	7402                	ld	s0,32(sp)
    800035a2:	64e2                	ld	s1,24(sp)
    800035a4:	6942                	ld	s2,16(sp)
    800035a6:	69a2                	ld	s3,8(sp)
    800035a8:	6145                	addi	sp,sp,48
    800035aa:	8082                	ret
    panic("invalid file system");
    800035ac:	00005517          	auipc	a0,0x5
    800035b0:	fec50513          	addi	a0,a0,-20 # 80008598 <syscalls+0x140>
    800035b4:	ffffd097          	auipc	ra,0xffffd
    800035b8:	f8a080e7          	jalr	-118(ra) # 8000053e <panic>

00000000800035bc <iinit>:
{
    800035bc:	7179                	addi	sp,sp,-48
    800035be:	f406                	sd	ra,40(sp)
    800035c0:	f022                	sd	s0,32(sp)
    800035c2:	ec26                	sd	s1,24(sp)
    800035c4:	e84a                	sd	s2,16(sp)
    800035c6:	e44e                	sd	s3,8(sp)
    800035c8:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800035ca:	00005597          	auipc	a1,0x5
    800035ce:	fe658593          	addi	a1,a1,-26 # 800085b0 <syscalls+0x158>
    800035d2:	0003c517          	auipc	a0,0x3c
    800035d6:	20e50513          	addi	a0,a0,526 # 8003f7e0 <itable>
    800035da:	ffffd097          	auipc	ra,0xffffd
    800035de:	684080e7          	jalr	1668(ra) # 80000c5e <initlock>
  for(i = 0; i < NINODE; i++) {
    800035e2:	0003c497          	auipc	s1,0x3c
    800035e6:	22648493          	addi	s1,s1,550 # 8003f808 <itable+0x28>
    800035ea:	0003e997          	auipc	s3,0x3e
    800035ee:	cae98993          	addi	s3,s3,-850 # 80041298 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800035f2:	00005917          	auipc	s2,0x5
    800035f6:	fc690913          	addi	s2,s2,-58 # 800085b8 <syscalls+0x160>
    800035fa:	85ca                	mv	a1,s2
    800035fc:	8526                	mv	a0,s1
    800035fe:	00001097          	auipc	ra,0x1
    80003602:	e46080e7          	jalr	-442(ra) # 80004444 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003606:	08848493          	addi	s1,s1,136
    8000360a:	ff3498e3          	bne	s1,s3,800035fa <iinit+0x3e>
}
    8000360e:	70a2                	ld	ra,40(sp)
    80003610:	7402                	ld	s0,32(sp)
    80003612:	64e2                	ld	s1,24(sp)
    80003614:	6942                	ld	s2,16(sp)
    80003616:	69a2                	ld	s3,8(sp)
    80003618:	6145                	addi	sp,sp,48
    8000361a:	8082                	ret

000000008000361c <ialloc>:
{
    8000361c:	715d                	addi	sp,sp,-80
    8000361e:	e486                	sd	ra,72(sp)
    80003620:	e0a2                	sd	s0,64(sp)
    80003622:	fc26                	sd	s1,56(sp)
    80003624:	f84a                	sd	s2,48(sp)
    80003626:	f44e                	sd	s3,40(sp)
    80003628:	f052                	sd	s4,32(sp)
    8000362a:	ec56                	sd	s5,24(sp)
    8000362c:	e85a                	sd	s6,16(sp)
    8000362e:	e45e                	sd	s7,8(sp)
    80003630:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003632:	0003c717          	auipc	a4,0x3c
    80003636:	19a72703          	lw	a4,410(a4) # 8003f7cc <sb+0xc>
    8000363a:	4785                	li	a5,1
    8000363c:	04e7fa63          	bgeu	a5,a4,80003690 <ialloc+0x74>
    80003640:	8aaa                	mv	s5,a0
    80003642:	8bae                	mv	s7,a1
    80003644:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003646:	0003ca17          	auipc	s4,0x3c
    8000364a:	17aa0a13          	addi	s4,s4,378 # 8003f7c0 <sb>
    8000364e:	00048b1b          	sext.w	s6,s1
    80003652:	0044d593          	srli	a1,s1,0x4
    80003656:	018a2783          	lw	a5,24(s4)
    8000365a:	9dbd                	addw	a1,a1,a5
    8000365c:	8556                	mv	a0,s5
    8000365e:	00000097          	auipc	ra,0x0
    80003662:	954080e7          	jalr	-1708(ra) # 80002fb2 <bread>
    80003666:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003668:	05850993          	addi	s3,a0,88
    8000366c:	00f4f793          	andi	a5,s1,15
    80003670:	079a                	slli	a5,a5,0x6
    80003672:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003674:	00099783          	lh	a5,0(s3)
    80003678:	c785                	beqz	a5,800036a0 <ialloc+0x84>
    brelse(bp);
    8000367a:	00000097          	auipc	ra,0x0
    8000367e:	a68080e7          	jalr	-1432(ra) # 800030e2 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003682:	0485                	addi	s1,s1,1
    80003684:	00ca2703          	lw	a4,12(s4)
    80003688:	0004879b          	sext.w	a5,s1
    8000368c:	fce7e1e3          	bltu	a5,a4,8000364e <ialloc+0x32>
  panic("ialloc: no inodes");
    80003690:	00005517          	auipc	a0,0x5
    80003694:	f3050513          	addi	a0,a0,-208 # 800085c0 <syscalls+0x168>
    80003698:	ffffd097          	auipc	ra,0xffffd
    8000369c:	ea6080e7          	jalr	-346(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    800036a0:	04000613          	li	a2,64
    800036a4:	4581                	li	a1,0
    800036a6:	854e                	mv	a0,s3
    800036a8:	ffffd097          	auipc	ra,0xffffd
    800036ac:	742080e7          	jalr	1858(ra) # 80000dea <memset>
      dip->type = type;
    800036b0:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800036b4:	854a                	mv	a0,s2
    800036b6:	00001097          	auipc	ra,0x1
    800036ba:	ca8080e7          	jalr	-856(ra) # 8000435e <log_write>
      brelse(bp);
    800036be:	854a                	mv	a0,s2
    800036c0:	00000097          	auipc	ra,0x0
    800036c4:	a22080e7          	jalr	-1502(ra) # 800030e2 <brelse>
      return iget(dev, inum);
    800036c8:	85da                	mv	a1,s6
    800036ca:	8556                	mv	a0,s5
    800036cc:	00000097          	auipc	ra,0x0
    800036d0:	db4080e7          	jalr	-588(ra) # 80003480 <iget>
}
    800036d4:	60a6                	ld	ra,72(sp)
    800036d6:	6406                	ld	s0,64(sp)
    800036d8:	74e2                	ld	s1,56(sp)
    800036da:	7942                	ld	s2,48(sp)
    800036dc:	79a2                	ld	s3,40(sp)
    800036de:	7a02                	ld	s4,32(sp)
    800036e0:	6ae2                	ld	s5,24(sp)
    800036e2:	6b42                	ld	s6,16(sp)
    800036e4:	6ba2                	ld	s7,8(sp)
    800036e6:	6161                	addi	sp,sp,80
    800036e8:	8082                	ret

00000000800036ea <iupdate>:
{
    800036ea:	1101                	addi	sp,sp,-32
    800036ec:	ec06                	sd	ra,24(sp)
    800036ee:	e822                	sd	s0,16(sp)
    800036f0:	e426                	sd	s1,8(sp)
    800036f2:	e04a                	sd	s2,0(sp)
    800036f4:	1000                	addi	s0,sp,32
    800036f6:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036f8:	415c                	lw	a5,4(a0)
    800036fa:	0047d79b          	srliw	a5,a5,0x4
    800036fe:	0003c597          	auipc	a1,0x3c
    80003702:	0da5a583          	lw	a1,218(a1) # 8003f7d8 <sb+0x18>
    80003706:	9dbd                	addw	a1,a1,a5
    80003708:	4108                	lw	a0,0(a0)
    8000370a:	00000097          	auipc	ra,0x0
    8000370e:	8a8080e7          	jalr	-1880(ra) # 80002fb2 <bread>
    80003712:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003714:	05850793          	addi	a5,a0,88
    80003718:	40c8                	lw	a0,4(s1)
    8000371a:	893d                	andi	a0,a0,15
    8000371c:	051a                	slli	a0,a0,0x6
    8000371e:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003720:	04449703          	lh	a4,68(s1)
    80003724:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003728:	04649703          	lh	a4,70(s1)
    8000372c:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003730:	04849703          	lh	a4,72(s1)
    80003734:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003738:	04a49703          	lh	a4,74(s1)
    8000373c:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003740:	44f8                	lw	a4,76(s1)
    80003742:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003744:	03400613          	li	a2,52
    80003748:	05048593          	addi	a1,s1,80
    8000374c:	0531                	addi	a0,a0,12
    8000374e:	ffffd097          	auipc	ra,0xffffd
    80003752:	6fc080e7          	jalr	1788(ra) # 80000e4a <memmove>
  log_write(bp);
    80003756:	854a                	mv	a0,s2
    80003758:	00001097          	auipc	ra,0x1
    8000375c:	c06080e7          	jalr	-1018(ra) # 8000435e <log_write>
  brelse(bp);
    80003760:	854a                	mv	a0,s2
    80003762:	00000097          	auipc	ra,0x0
    80003766:	980080e7          	jalr	-1664(ra) # 800030e2 <brelse>
}
    8000376a:	60e2                	ld	ra,24(sp)
    8000376c:	6442                	ld	s0,16(sp)
    8000376e:	64a2                	ld	s1,8(sp)
    80003770:	6902                	ld	s2,0(sp)
    80003772:	6105                	addi	sp,sp,32
    80003774:	8082                	ret

0000000080003776 <idup>:
{
    80003776:	1101                	addi	sp,sp,-32
    80003778:	ec06                	sd	ra,24(sp)
    8000377a:	e822                	sd	s0,16(sp)
    8000377c:	e426                	sd	s1,8(sp)
    8000377e:	1000                	addi	s0,sp,32
    80003780:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003782:	0003c517          	auipc	a0,0x3c
    80003786:	05e50513          	addi	a0,a0,94 # 8003f7e0 <itable>
    8000378a:	ffffd097          	auipc	ra,0xffffd
    8000378e:	564080e7          	jalr	1380(ra) # 80000cee <acquire>
  ip->ref++;
    80003792:	449c                	lw	a5,8(s1)
    80003794:	2785                	addiw	a5,a5,1
    80003796:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003798:	0003c517          	auipc	a0,0x3c
    8000379c:	04850513          	addi	a0,a0,72 # 8003f7e0 <itable>
    800037a0:	ffffd097          	auipc	ra,0xffffd
    800037a4:	602080e7          	jalr	1538(ra) # 80000da2 <release>
}
    800037a8:	8526                	mv	a0,s1
    800037aa:	60e2                	ld	ra,24(sp)
    800037ac:	6442                	ld	s0,16(sp)
    800037ae:	64a2                	ld	s1,8(sp)
    800037b0:	6105                	addi	sp,sp,32
    800037b2:	8082                	ret

00000000800037b4 <ilock>:
{
    800037b4:	1101                	addi	sp,sp,-32
    800037b6:	ec06                	sd	ra,24(sp)
    800037b8:	e822                	sd	s0,16(sp)
    800037ba:	e426                	sd	s1,8(sp)
    800037bc:	e04a                	sd	s2,0(sp)
    800037be:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800037c0:	c115                	beqz	a0,800037e4 <ilock+0x30>
    800037c2:	84aa                	mv	s1,a0
    800037c4:	451c                	lw	a5,8(a0)
    800037c6:	00f05f63          	blez	a5,800037e4 <ilock+0x30>
  acquiresleep(&ip->lock);
    800037ca:	0541                	addi	a0,a0,16
    800037cc:	00001097          	auipc	ra,0x1
    800037d0:	cb2080e7          	jalr	-846(ra) # 8000447e <acquiresleep>
  if(ip->valid == 0){
    800037d4:	40bc                	lw	a5,64(s1)
    800037d6:	cf99                	beqz	a5,800037f4 <ilock+0x40>
}
    800037d8:	60e2                	ld	ra,24(sp)
    800037da:	6442                	ld	s0,16(sp)
    800037dc:	64a2                	ld	s1,8(sp)
    800037de:	6902                	ld	s2,0(sp)
    800037e0:	6105                	addi	sp,sp,32
    800037e2:	8082                	ret
    panic("ilock");
    800037e4:	00005517          	auipc	a0,0x5
    800037e8:	df450513          	addi	a0,a0,-524 # 800085d8 <syscalls+0x180>
    800037ec:	ffffd097          	auipc	ra,0xffffd
    800037f0:	d52080e7          	jalr	-686(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037f4:	40dc                	lw	a5,4(s1)
    800037f6:	0047d79b          	srliw	a5,a5,0x4
    800037fa:	0003c597          	auipc	a1,0x3c
    800037fe:	fde5a583          	lw	a1,-34(a1) # 8003f7d8 <sb+0x18>
    80003802:	9dbd                	addw	a1,a1,a5
    80003804:	4088                	lw	a0,0(s1)
    80003806:	fffff097          	auipc	ra,0xfffff
    8000380a:	7ac080e7          	jalr	1964(ra) # 80002fb2 <bread>
    8000380e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003810:	05850593          	addi	a1,a0,88
    80003814:	40dc                	lw	a5,4(s1)
    80003816:	8bbd                	andi	a5,a5,15
    80003818:	079a                	slli	a5,a5,0x6
    8000381a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000381c:	00059783          	lh	a5,0(a1)
    80003820:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003824:	00259783          	lh	a5,2(a1)
    80003828:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000382c:	00459783          	lh	a5,4(a1)
    80003830:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003834:	00659783          	lh	a5,6(a1)
    80003838:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000383c:	459c                	lw	a5,8(a1)
    8000383e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003840:	03400613          	li	a2,52
    80003844:	05b1                	addi	a1,a1,12
    80003846:	05048513          	addi	a0,s1,80
    8000384a:	ffffd097          	auipc	ra,0xffffd
    8000384e:	600080e7          	jalr	1536(ra) # 80000e4a <memmove>
    brelse(bp);
    80003852:	854a                	mv	a0,s2
    80003854:	00000097          	auipc	ra,0x0
    80003858:	88e080e7          	jalr	-1906(ra) # 800030e2 <brelse>
    ip->valid = 1;
    8000385c:	4785                	li	a5,1
    8000385e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003860:	04449783          	lh	a5,68(s1)
    80003864:	fbb5                	bnez	a5,800037d8 <ilock+0x24>
      panic("ilock: no type");
    80003866:	00005517          	auipc	a0,0x5
    8000386a:	d7a50513          	addi	a0,a0,-646 # 800085e0 <syscalls+0x188>
    8000386e:	ffffd097          	auipc	ra,0xffffd
    80003872:	cd0080e7          	jalr	-816(ra) # 8000053e <panic>

0000000080003876 <iunlock>:
{
    80003876:	1101                	addi	sp,sp,-32
    80003878:	ec06                	sd	ra,24(sp)
    8000387a:	e822                	sd	s0,16(sp)
    8000387c:	e426                	sd	s1,8(sp)
    8000387e:	e04a                	sd	s2,0(sp)
    80003880:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003882:	c905                	beqz	a0,800038b2 <iunlock+0x3c>
    80003884:	84aa                	mv	s1,a0
    80003886:	01050913          	addi	s2,a0,16
    8000388a:	854a                	mv	a0,s2
    8000388c:	00001097          	auipc	ra,0x1
    80003890:	c8c080e7          	jalr	-884(ra) # 80004518 <holdingsleep>
    80003894:	cd19                	beqz	a0,800038b2 <iunlock+0x3c>
    80003896:	449c                	lw	a5,8(s1)
    80003898:	00f05d63          	blez	a5,800038b2 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000389c:	854a                	mv	a0,s2
    8000389e:	00001097          	auipc	ra,0x1
    800038a2:	c36080e7          	jalr	-970(ra) # 800044d4 <releasesleep>
}
    800038a6:	60e2                	ld	ra,24(sp)
    800038a8:	6442                	ld	s0,16(sp)
    800038aa:	64a2                	ld	s1,8(sp)
    800038ac:	6902                	ld	s2,0(sp)
    800038ae:	6105                	addi	sp,sp,32
    800038b0:	8082                	ret
    panic("iunlock");
    800038b2:	00005517          	auipc	a0,0x5
    800038b6:	d3e50513          	addi	a0,a0,-706 # 800085f0 <syscalls+0x198>
    800038ba:	ffffd097          	auipc	ra,0xffffd
    800038be:	c84080e7          	jalr	-892(ra) # 8000053e <panic>

00000000800038c2 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800038c2:	7179                	addi	sp,sp,-48
    800038c4:	f406                	sd	ra,40(sp)
    800038c6:	f022                	sd	s0,32(sp)
    800038c8:	ec26                	sd	s1,24(sp)
    800038ca:	e84a                	sd	s2,16(sp)
    800038cc:	e44e                	sd	s3,8(sp)
    800038ce:	e052                	sd	s4,0(sp)
    800038d0:	1800                	addi	s0,sp,48
    800038d2:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038d4:	05050493          	addi	s1,a0,80
    800038d8:	08050913          	addi	s2,a0,128
    800038dc:	a021                	j	800038e4 <itrunc+0x22>
    800038de:	0491                	addi	s1,s1,4
    800038e0:	01248d63          	beq	s1,s2,800038fa <itrunc+0x38>
    if(ip->addrs[i]){
    800038e4:	408c                	lw	a1,0(s1)
    800038e6:	dde5                	beqz	a1,800038de <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800038e8:	0009a503          	lw	a0,0(s3)
    800038ec:	00000097          	auipc	ra,0x0
    800038f0:	90c080e7          	jalr	-1780(ra) # 800031f8 <bfree>
      ip->addrs[i] = 0;
    800038f4:	0004a023          	sw	zero,0(s1)
    800038f8:	b7dd                	j	800038de <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038fa:	0809a583          	lw	a1,128(s3)
    800038fe:	e185                	bnez	a1,8000391e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003900:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003904:	854e                	mv	a0,s3
    80003906:	00000097          	auipc	ra,0x0
    8000390a:	de4080e7          	jalr	-540(ra) # 800036ea <iupdate>
}
    8000390e:	70a2                	ld	ra,40(sp)
    80003910:	7402                	ld	s0,32(sp)
    80003912:	64e2                	ld	s1,24(sp)
    80003914:	6942                	ld	s2,16(sp)
    80003916:	69a2                	ld	s3,8(sp)
    80003918:	6a02                	ld	s4,0(sp)
    8000391a:	6145                	addi	sp,sp,48
    8000391c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000391e:	0009a503          	lw	a0,0(s3)
    80003922:	fffff097          	auipc	ra,0xfffff
    80003926:	690080e7          	jalr	1680(ra) # 80002fb2 <bread>
    8000392a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000392c:	05850493          	addi	s1,a0,88
    80003930:	45850913          	addi	s2,a0,1112
    80003934:	a811                	j	80003948 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003936:	0009a503          	lw	a0,0(s3)
    8000393a:	00000097          	auipc	ra,0x0
    8000393e:	8be080e7          	jalr	-1858(ra) # 800031f8 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003942:	0491                	addi	s1,s1,4
    80003944:	01248563          	beq	s1,s2,8000394e <itrunc+0x8c>
      if(a[j])
    80003948:	408c                	lw	a1,0(s1)
    8000394a:	dde5                	beqz	a1,80003942 <itrunc+0x80>
    8000394c:	b7ed                	j	80003936 <itrunc+0x74>
    brelse(bp);
    8000394e:	8552                	mv	a0,s4
    80003950:	fffff097          	auipc	ra,0xfffff
    80003954:	792080e7          	jalr	1938(ra) # 800030e2 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003958:	0809a583          	lw	a1,128(s3)
    8000395c:	0009a503          	lw	a0,0(s3)
    80003960:	00000097          	auipc	ra,0x0
    80003964:	898080e7          	jalr	-1896(ra) # 800031f8 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003968:	0809a023          	sw	zero,128(s3)
    8000396c:	bf51                	j	80003900 <itrunc+0x3e>

000000008000396e <iput>:
{
    8000396e:	1101                	addi	sp,sp,-32
    80003970:	ec06                	sd	ra,24(sp)
    80003972:	e822                	sd	s0,16(sp)
    80003974:	e426                	sd	s1,8(sp)
    80003976:	e04a                	sd	s2,0(sp)
    80003978:	1000                	addi	s0,sp,32
    8000397a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000397c:	0003c517          	auipc	a0,0x3c
    80003980:	e6450513          	addi	a0,a0,-412 # 8003f7e0 <itable>
    80003984:	ffffd097          	auipc	ra,0xffffd
    80003988:	36a080e7          	jalr	874(ra) # 80000cee <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000398c:	4498                	lw	a4,8(s1)
    8000398e:	4785                	li	a5,1
    80003990:	02f70363          	beq	a4,a5,800039b6 <iput+0x48>
  ip->ref--;
    80003994:	449c                	lw	a5,8(s1)
    80003996:	37fd                	addiw	a5,a5,-1
    80003998:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000399a:	0003c517          	auipc	a0,0x3c
    8000399e:	e4650513          	addi	a0,a0,-442 # 8003f7e0 <itable>
    800039a2:	ffffd097          	auipc	ra,0xffffd
    800039a6:	400080e7          	jalr	1024(ra) # 80000da2 <release>
}
    800039aa:	60e2                	ld	ra,24(sp)
    800039ac:	6442                	ld	s0,16(sp)
    800039ae:	64a2                	ld	s1,8(sp)
    800039b0:	6902                	ld	s2,0(sp)
    800039b2:	6105                	addi	sp,sp,32
    800039b4:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039b6:	40bc                	lw	a5,64(s1)
    800039b8:	dff1                	beqz	a5,80003994 <iput+0x26>
    800039ba:	04a49783          	lh	a5,74(s1)
    800039be:	fbf9                	bnez	a5,80003994 <iput+0x26>
    acquiresleep(&ip->lock);
    800039c0:	01048913          	addi	s2,s1,16
    800039c4:	854a                	mv	a0,s2
    800039c6:	00001097          	auipc	ra,0x1
    800039ca:	ab8080e7          	jalr	-1352(ra) # 8000447e <acquiresleep>
    release(&itable.lock);
    800039ce:	0003c517          	auipc	a0,0x3c
    800039d2:	e1250513          	addi	a0,a0,-494 # 8003f7e0 <itable>
    800039d6:	ffffd097          	auipc	ra,0xffffd
    800039da:	3cc080e7          	jalr	972(ra) # 80000da2 <release>
    itrunc(ip);
    800039de:	8526                	mv	a0,s1
    800039e0:	00000097          	auipc	ra,0x0
    800039e4:	ee2080e7          	jalr	-286(ra) # 800038c2 <itrunc>
    ip->type = 0;
    800039e8:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039ec:	8526                	mv	a0,s1
    800039ee:	00000097          	auipc	ra,0x0
    800039f2:	cfc080e7          	jalr	-772(ra) # 800036ea <iupdate>
    ip->valid = 0;
    800039f6:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039fa:	854a                	mv	a0,s2
    800039fc:	00001097          	auipc	ra,0x1
    80003a00:	ad8080e7          	jalr	-1320(ra) # 800044d4 <releasesleep>
    acquire(&itable.lock);
    80003a04:	0003c517          	auipc	a0,0x3c
    80003a08:	ddc50513          	addi	a0,a0,-548 # 8003f7e0 <itable>
    80003a0c:	ffffd097          	auipc	ra,0xffffd
    80003a10:	2e2080e7          	jalr	738(ra) # 80000cee <acquire>
    80003a14:	b741                	j	80003994 <iput+0x26>

0000000080003a16 <iunlockput>:
{
    80003a16:	1101                	addi	sp,sp,-32
    80003a18:	ec06                	sd	ra,24(sp)
    80003a1a:	e822                	sd	s0,16(sp)
    80003a1c:	e426                	sd	s1,8(sp)
    80003a1e:	1000                	addi	s0,sp,32
    80003a20:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a22:	00000097          	auipc	ra,0x0
    80003a26:	e54080e7          	jalr	-428(ra) # 80003876 <iunlock>
  iput(ip);
    80003a2a:	8526                	mv	a0,s1
    80003a2c:	00000097          	auipc	ra,0x0
    80003a30:	f42080e7          	jalr	-190(ra) # 8000396e <iput>
}
    80003a34:	60e2                	ld	ra,24(sp)
    80003a36:	6442                	ld	s0,16(sp)
    80003a38:	64a2                	ld	s1,8(sp)
    80003a3a:	6105                	addi	sp,sp,32
    80003a3c:	8082                	ret

0000000080003a3e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a3e:	1141                	addi	sp,sp,-16
    80003a40:	e422                	sd	s0,8(sp)
    80003a42:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a44:	411c                	lw	a5,0(a0)
    80003a46:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a48:	415c                	lw	a5,4(a0)
    80003a4a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a4c:	04451783          	lh	a5,68(a0)
    80003a50:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a54:	04a51783          	lh	a5,74(a0)
    80003a58:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a5c:	04c56783          	lwu	a5,76(a0)
    80003a60:	e99c                	sd	a5,16(a1)
}
    80003a62:	6422                	ld	s0,8(sp)
    80003a64:	0141                	addi	sp,sp,16
    80003a66:	8082                	ret

0000000080003a68 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a68:	457c                	lw	a5,76(a0)
    80003a6a:	0ed7e963          	bltu	a5,a3,80003b5c <readi+0xf4>
{
    80003a6e:	7159                	addi	sp,sp,-112
    80003a70:	f486                	sd	ra,104(sp)
    80003a72:	f0a2                	sd	s0,96(sp)
    80003a74:	eca6                	sd	s1,88(sp)
    80003a76:	e8ca                	sd	s2,80(sp)
    80003a78:	e4ce                	sd	s3,72(sp)
    80003a7a:	e0d2                	sd	s4,64(sp)
    80003a7c:	fc56                	sd	s5,56(sp)
    80003a7e:	f85a                	sd	s6,48(sp)
    80003a80:	f45e                	sd	s7,40(sp)
    80003a82:	f062                	sd	s8,32(sp)
    80003a84:	ec66                	sd	s9,24(sp)
    80003a86:	e86a                	sd	s10,16(sp)
    80003a88:	e46e                	sd	s11,8(sp)
    80003a8a:	1880                	addi	s0,sp,112
    80003a8c:	8baa                	mv	s7,a0
    80003a8e:	8c2e                	mv	s8,a1
    80003a90:	8ab2                	mv	s5,a2
    80003a92:	84b6                	mv	s1,a3
    80003a94:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a96:	9f35                	addw	a4,a4,a3
    return 0;
    80003a98:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a9a:	0ad76063          	bltu	a4,a3,80003b3a <readi+0xd2>
  if(off + n > ip->size)
    80003a9e:	00e7f463          	bgeu	a5,a4,80003aa6 <readi+0x3e>
    n = ip->size - off;
    80003aa2:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003aa6:	0a0b0963          	beqz	s6,80003b58 <readi+0xf0>
    80003aaa:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003aac:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003ab0:	5cfd                	li	s9,-1
    80003ab2:	a82d                	j	80003aec <readi+0x84>
    80003ab4:	020a1d93          	slli	s11,s4,0x20
    80003ab8:	020ddd93          	srli	s11,s11,0x20
    80003abc:	05890613          	addi	a2,s2,88
    80003ac0:	86ee                	mv	a3,s11
    80003ac2:	963a                	add	a2,a2,a4
    80003ac4:	85d6                	mv	a1,s5
    80003ac6:	8562                	mv	a0,s8
    80003ac8:	fffff097          	auipc	ra,0xfffff
    80003acc:	a5c080e7          	jalr	-1444(ra) # 80002524 <either_copyout>
    80003ad0:	05950d63          	beq	a0,s9,80003b2a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ad4:	854a                	mv	a0,s2
    80003ad6:	fffff097          	auipc	ra,0xfffff
    80003ada:	60c080e7          	jalr	1548(ra) # 800030e2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ade:	013a09bb          	addw	s3,s4,s3
    80003ae2:	009a04bb          	addw	s1,s4,s1
    80003ae6:	9aee                	add	s5,s5,s11
    80003ae8:	0569f763          	bgeu	s3,s6,80003b36 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003aec:	000ba903          	lw	s2,0(s7)
    80003af0:	00a4d59b          	srliw	a1,s1,0xa
    80003af4:	855e                	mv	a0,s7
    80003af6:	00000097          	auipc	ra,0x0
    80003afa:	8b0080e7          	jalr	-1872(ra) # 800033a6 <bmap>
    80003afe:	0005059b          	sext.w	a1,a0
    80003b02:	854a                	mv	a0,s2
    80003b04:	fffff097          	auipc	ra,0xfffff
    80003b08:	4ae080e7          	jalr	1198(ra) # 80002fb2 <bread>
    80003b0c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b0e:	3ff4f713          	andi	a4,s1,1023
    80003b12:	40ed07bb          	subw	a5,s10,a4
    80003b16:	413b06bb          	subw	a3,s6,s3
    80003b1a:	8a3e                	mv	s4,a5
    80003b1c:	2781                	sext.w	a5,a5
    80003b1e:	0006861b          	sext.w	a2,a3
    80003b22:	f8f679e3          	bgeu	a2,a5,80003ab4 <readi+0x4c>
    80003b26:	8a36                	mv	s4,a3
    80003b28:	b771                	j	80003ab4 <readi+0x4c>
      brelse(bp);
    80003b2a:	854a                	mv	a0,s2
    80003b2c:	fffff097          	auipc	ra,0xfffff
    80003b30:	5b6080e7          	jalr	1462(ra) # 800030e2 <brelse>
      tot = -1;
    80003b34:	59fd                	li	s3,-1
  }
  return tot;
    80003b36:	0009851b          	sext.w	a0,s3
}
    80003b3a:	70a6                	ld	ra,104(sp)
    80003b3c:	7406                	ld	s0,96(sp)
    80003b3e:	64e6                	ld	s1,88(sp)
    80003b40:	6946                	ld	s2,80(sp)
    80003b42:	69a6                	ld	s3,72(sp)
    80003b44:	6a06                	ld	s4,64(sp)
    80003b46:	7ae2                	ld	s5,56(sp)
    80003b48:	7b42                	ld	s6,48(sp)
    80003b4a:	7ba2                	ld	s7,40(sp)
    80003b4c:	7c02                	ld	s8,32(sp)
    80003b4e:	6ce2                	ld	s9,24(sp)
    80003b50:	6d42                	ld	s10,16(sp)
    80003b52:	6da2                	ld	s11,8(sp)
    80003b54:	6165                	addi	sp,sp,112
    80003b56:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b58:	89da                	mv	s3,s6
    80003b5a:	bff1                	j	80003b36 <readi+0xce>
    return 0;
    80003b5c:	4501                	li	a0,0
}
    80003b5e:	8082                	ret

0000000080003b60 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b60:	457c                	lw	a5,76(a0)
    80003b62:	10d7e863          	bltu	a5,a3,80003c72 <writei+0x112>
{
    80003b66:	7159                	addi	sp,sp,-112
    80003b68:	f486                	sd	ra,104(sp)
    80003b6a:	f0a2                	sd	s0,96(sp)
    80003b6c:	eca6                	sd	s1,88(sp)
    80003b6e:	e8ca                	sd	s2,80(sp)
    80003b70:	e4ce                	sd	s3,72(sp)
    80003b72:	e0d2                	sd	s4,64(sp)
    80003b74:	fc56                	sd	s5,56(sp)
    80003b76:	f85a                	sd	s6,48(sp)
    80003b78:	f45e                	sd	s7,40(sp)
    80003b7a:	f062                	sd	s8,32(sp)
    80003b7c:	ec66                	sd	s9,24(sp)
    80003b7e:	e86a                	sd	s10,16(sp)
    80003b80:	e46e                	sd	s11,8(sp)
    80003b82:	1880                	addi	s0,sp,112
    80003b84:	8b2a                	mv	s6,a0
    80003b86:	8c2e                	mv	s8,a1
    80003b88:	8ab2                	mv	s5,a2
    80003b8a:	8936                	mv	s2,a3
    80003b8c:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003b8e:	00e687bb          	addw	a5,a3,a4
    80003b92:	0ed7e263          	bltu	a5,a3,80003c76 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b96:	00043737          	lui	a4,0x43
    80003b9a:	0ef76063          	bltu	a4,a5,80003c7a <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b9e:	0c0b8863          	beqz	s7,80003c6e <writei+0x10e>
    80003ba2:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ba4:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003ba8:	5cfd                	li	s9,-1
    80003baa:	a091                	j	80003bee <writei+0x8e>
    80003bac:	02099d93          	slli	s11,s3,0x20
    80003bb0:	020ddd93          	srli	s11,s11,0x20
    80003bb4:	05848513          	addi	a0,s1,88
    80003bb8:	86ee                	mv	a3,s11
    80003bba:	8656                	mv	a2,s5
    80003bbc:	85e2                	mv	a1,s8
    80003bbe:	953a                	add	a0,a0,a4
    80003bc0:	fffff097          	auipc	ra,0xfffff
    80003bc4:	9ba080e7          	jalr	-1606(ra) # 8000257a <either_copyin>
    80003bc8:	07950263          	beq	a0,s9,80003c2c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003bcc:	8526                	mv	a0,s1
    80003bce:	00000097          	auipc	ra,0x0
    80003bd2:	790080e7          	jalr	1936(ra) # 8000435e <log_write>
    brelse(bp);
    80003bd6:	8526                	mv	a0,s1
    80003bd8:	fffff097          	auipc	ra,0xfffff
    80003bdc:	50a080e7          	jalr	1290(ra) # 800030e2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003be0:	01498a3b          	addw	s4,s3,s4
    80003be4:	0129893b          	addw	s2,s3,s2
    80003be8:	9aee                	add	s5,s5,s11
    80003bea:	057a7663          	bgeu	s4,s7,80003c36 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003bee:	000b2483          	lw	s1,0(s6)
    80003bf2:	00a9559b          	srliw	a1,s2,0xa
    80003bf6:	855a                	mv	a0,s6
    80003bf8:	fffff097          	auipc	ra,0xfffff
    80003bfc:	7ae080e7          	jalr	1966(ra) # 800033a6 <bmap>
    80003c00:	0005059b          	sext.w	a1,a0
    80003c04:	8526                	mv	a0,s1
    80003c06:	fffff097          	auipc	ra,0xfffff
    80003c0a:	3ac080e7          	jalr	940(ra) # 80002fb2 <bread>
    80003c0e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c10:	3ff97713          	andi	a4,s2,1023
    80003c14:	40ed07bb          	subw	a5,s10,a4
    80003c18:	414b86bb          	subw	a3,s7,s4
    80003c1c:	89be                	mv	s3,a5
    80003c1e:	2781                	sext.w	a5,a5
    80003c20:	0006861b          	sext.w	a2,a3
    80003c24:	f8f674e3          	bgeu	a2,a5,80003bac <writei+0x4c>
    80003c28:	89b6                	mv	s3,a3
    80003c2a:	b749                	j	80003bac <writei+0x4c>
      brelse(bp);
    80003c2c:	8526                	mv	a0,s1
    80003c2e:	fffff097          	auipc	ra,0xfffff
    80003c32:	4b4080e7          	jalr	1204(ra) # 800030e2 <brelse>
  }

  if(off > ip->size)
    80003c36:	04cb2783          	lw	a5,76(s6)
    80003c3a:	0127f463          	bgeu	a5,s2,80003c42 <writei+0xe2>
    ip->size = off;
    80003c3e:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c42:	855a                	mv	a0,s6
    80003c44:	00000097          	auipc	ra,0x0
    80003c48:	aa6080e7          	jalr	-1370(ra) # 800036ea <iupdate>

  return tot;
    80003c4c:	000a051b          	sext.w	a0,s4
}
    80003c50:	70a6                	ld	ra,104(sp)
    80003c52:	7406                	ld	s0,96(sp)
    80003c54:	64e6                	ld	s1,88(sp)
    80003c56:	6946                	ld	s2,80(sp)
    80003c58:	69a6                	ld	s3,72(sp)
    80003c5a:	6a06                	ld	s4,64(sp)
    80003c5c:	7ae2                	ld	s5,56(sp)
    80003c5e:	7b42                	ld	s6,48(sp)
    80003c60:	7ba2                	ld	s7,40(sp)
    80003c62:	7c02                	ld	s8,32(sp)
    80003c64:	6ce2                	ld	s9,24(sp)
    80003c66:	6d42                	ld	s10,16(sp)
    80003c68:	6da2                	ld	s11,8(sp)
    80003c6a:	6165                	addi	sp,sp,112
    80003c6c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c6e:	8a5e                	mv	s4,s7
    80003c70:	bfc9                	j	80003c42 <writei+0xe2>
    return -1;
    80003c72:	557d                	li	a0,-1
}
    80003c74:	8082                	ret
    return -1;
    80003c76:	557d                	li	a0,-1
    80003c78:	bfe1                	j	80003c50 <writei+0xf0>
    return -1;
    80003c7a:	557d                	li	a0,-1
    80003c7c:	bfd1                	j	80003c50 <writei+0xf0>

0000000080003c7e <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c7e:	1141                	addi	sp,sp,-16
    80003c80:	e406                	sd	ra,8(sp)
    80003c82:	e022                	sd	s0,0(sp)
    80003c84:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c86:	4639                	li	a2,14
    80003c88:	ffffd097          	auipc	ra,0xffffd
    80003c8c:	23a080e7          	jalr	570(ra) # 80000ec2 <strncmp>
}
    80003c90:	60a2                	ld	ra,8(sp)
    80003c92:	6402                	ld	s0,0(sp)
    80003c94:	0141                	addi	sp,sp,16
    80003c96:	8082                	ret

0000000080003c98 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c98:	7139                	addi	sp,sp,-64
    80003c9a:	fc06                	sd	ra,56(sp)
    80003c9c:	f822                	sd	s0,48(sp)
    80003c9e:	f426                	sd	s1,40(sp)
    80003ca0:	f04a                	sd	s2,32(sp)
    80003ca2:	ec4e                	sd	s3,24(sp)
    80003ca4:	e852                	sd	s4,16(sp)
    80003ca6:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003ca8:	04451703          	lh	a4,68(a0)
    80003cac:	4785                	li	a5,1
    80003cae:	00f71a63          	bne	a4,a5,80003cc2 <dirlookup+0x2a>
    80003cb2:	892a                	mv	s2,a0
    80003cb4:	89ae                	mv	s3,a1
    80003cb6:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cb8:	457c                	lw	a5,76(a0)
    80003cba:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003cbc:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cbe:	e79d                	bnez	a5,80003cec <dirlookup+0x54>
    80003cc0:	a8a5                	j	80003d38 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003cc2:	00005517          	auipc	a0,0x5
    80003cc6:	93650513          	addi	a0,a0,-1738 # 800085f8 <syscalls+0x1a0>
    80003cca:	ffffd097          	auipc	ra,0xffffd
    80003cce:	874080e7          	jalr	-1932(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003cd2:	00005517          	auipc	a0,0x5
    80003cd6:	93e50513          	addi	a0,a0,-1730 # 80008610 <syscalls+0x1b8>
    80003cda:	ffffd097          	auipc	ra,0xffffd
    80003cde:	864080e7          	jalr	-1948(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ce2:	24c1                	addiw	s1,s1,16
    80003ce4:	04c92783          	lw	a5,76(s2)
    80003ce8:	04f4f763          	bgeu	s1,a5,80003d36 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003cec:	4741                	li	a4,16
    80003cee:	86a6                	mv	a3,s1
    80003cf0:	fc040613          	addi	a2,s0,-64
    80003cf4:	4581                	li	a1,0
    80003cf6:	854a                	mv	a0,s2
    80003cf8:	00000097          	auipc	ra,0x0
    80003cfc:	d70080e7          	jalr	-656(ra) # 80003a68 <readi>
    80003d00:	47c1                	li	a5,16
    80003d02:	fcf518e3          	bne	a0,a5,80003cd2 <dirlookup+0x3a>
    if(de.inum == 0)
    80003d06:	fc045783          	lhu	a5,-64(s0)
    80003d0a:	dfe1                	beqz	a5,80003ce2 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d0c:	fc240593          	addi	a1,s0,-62
    80003d10:	854e                	mv	a0,s3
    80003d12:	00000097          	auipc	ra,0x0
    80003d16:	f6c080e7          	jalr	-148(ra) # 80003c7e <namecmp>
    80003d1a:	f561                	bnez	a0,80003ce2 <dirlookup+0x4a>
      if(poff)
    80003d1c:	000a0463          	beqz	s4,80003d24 <dirlookup+0x8c>
        *poff = off;
    80003d20:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d24:	fc045583          	lhu	a1,-64(s0)
    80003d28:	00092503          	lw	a0,0(s2)
    80003d2c:	fffff097          	auipc	ra,0xfffff
    80003d30:	754080e7          	jalr	1876(ra) # 80003480 <iget>
    80003d34:	a011                	j	80003d38 <dirlookup+0xa0>
  return 0;
    80003d36:	4501                	li	a0,0
}
    80003d38:	70e2                	ld	ra,56(sp)
    80003d3a:	7442                	ld	s0,48(sp)
    80003d3c:	74a2                	ld	s1,40(sp)
    80003d3e:	7902                	ld	s2,32(sp)
    80003d40:	69e2                	ld	s3,24(sp)
    80003d42:	6a42                	ld	s4,16(sp)
    80003d44:	6121                	addi	sp,sp,64
    80003d46:	8082                	ret

0000000080003d48 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d48:	711d                	addi	sp,sp,-96
    80003d4a:	ec86                	sd	ra,88(sp)
    80003d4c:	e8a2                	sd	s0,80(sp)
    80003d4e:	e4a6                	sd	s1,72(sp)
    80003d50:	e0ca                	sd	s2,64(sp)
    80003d52:	fc4e                	sd	s3,56(sp)
    80003d54:	f852                	sd	s4,48(sp)
    80003d56:	f456                	sd	s5,40(sp)
    80003d58:	f05a                	sd	s6,32(sp)
    80003d5a:	ec5e                	sd	s7,24(sp)
    80003d5c:	e862                	sd	s8,16(sp)
    80003d5e:	e466                	sd	s9,8(sp)
    80003d60:	1080                	addi	s0,sp,96
    80003d62:	84aa                	mv	s1,a0
    80003d64:	8b2e                	mv	s6,a1
    80003d66:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d68:	00054703          	lbu	a4,0(a0)
    80003d6c:	02f00793          	li	a5,47
    80003d70:	02f70363          	beq	a4,a5,80003d96 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d74:	ffffe097          	auipc	ra,0xffffe
    80003d78:	d50080e7          	jalr	-688(ra) # 80001ac4 <myproc>
    80003d7c:	15053503          	ld	a0,336(a0)
    80003d80:	00000097          	auipc	ra,0x0
    80003d84:	9f6080e7          	jalr	-1546(ra) # 80003776 <idup>
    80003d88:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d8a:	02f00913          	li	s2,47
  len = path - s;
    80003d8e:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003d90:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d92:	4c05                	li	s8,1
    80003d94:	a865                	j	80003e4c <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d96:	4585                	li	a1,1
    80003d98:	4505                	li	a0,1
    80003d9a:	fffff097          	auipc	ra,0xfffff
    80003d9e:	6e6080e7          	jalr	1766(ra) # 80003480 <iget>
    80003da2:	89aa                	mv	s3,a0
    80003da4:	b7dd                	j	80003d8a <namex+0x42>
      iunlockput(ip);
    80003da6:	854e                	mv	a0,s3
    80003da8:	00000097          	auipc	ra,0x0
    80003dac:	c6e080e7          	jalr	-914(ra) # 80003a16 <iunlockput>
      return 0;
    80003db0:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003db2:	854e                	mv	a0,s3
    80003db4:	60e6                	ld	ra,88(sp)
    80003db6:	6446                	ld	s0,80(sp)
    80003db8:	64a6                	ld	s1,72(sp)
    80003dba:	6906                	ld	s2,64(sp)
    80003dbc:	79e2                	ld	s3,56(sp)
    80003dbe:	7a42                	ld	s4,48(sp)
    80003dc0:	7aa2                	ld	s5,40(sp)
    80003dc2:	7b02                	ld	s6,32(sp)
    80003dc4:	6be2                	ld	s7,24(sp)
    80003dc6:	6c42                	ld	s8,16(sp)
    80003dc8:	6ca2                	ld	s9,8(sp)
    80003dca:	6125                	addi	sp,sp,96
    80003dcc:	8082                	ret
      iunlock(ip);
    80003dce:	854e                	mv	a0,s3
    80003dd0:	00000097          	auipc	ra,0x0
    80003dd4:	aa6080e7          	jalr	-1370(ra) # 80003876 <iunlock>
      return ip;
    80003dd8:	bfe9                	j	80003db2 <namex+0x6a>
      iunlockput(ip);
    80003dda:	854e                	mv	a0,s3
    80003ddc:	00000097          	auipc	ra,0x0
    80003de0:	c3a080e7          	jalr	-966(ra) # 80003a16 <iunlockput>
      return 0;
    80003de4:	89d2                	mv	s3,s4
    80003de6:	b7f1                	j	80003db2 <namex+0x6a>
  len = path - s;
    80003de8:	40b48633          	sub	a2,s1,a1
    80003dec:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003df0:	094cd463          	bge	s9,s4,80003e78 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003df4:	4639                	li	a2,14
    80003df6:	8556                	mv	a0,s5
    80003df8:	ffffd097          	auipc	ra,0xffffd
    80003dfc:	052080e7          	jalr	82(ra) # 80000e4a <memmove>
  while(*path == '/')
    80003e00:	0004c783          	lbu	a5,0(s1)
    80003e04:	01279763          	bne	a5,s2,80003e12 <namex+0xca>
    path++;
    80003e08:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e0a:	0004c783          	lbu	a5,0(s1)
    80003e0e:	ff278de3          	beq	a5,s2,80003e08 <namex+0xc0>
    ilock(ip);
    80003e12:	854e                	mv	a0,s3
    80003e14:	00000097          	auipc	ra,0x0
    80003e18:	9a0080e7          	jalr	-1632(ra) # 800037b4 <ilock>
    if(ip->type != T_DIR){
    80003e1c:	04499783          	lh	a5,68(s3)
    80003e20:	f98793e3          	bne	a5,s8,80003da6 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e24:	000b0563          	beqz	s6,80003e2e <namex+0xe6>
    80003e28:	0004c783          	lbu	a5,0(s1)
    80003e2c:	d3cd                	beqz	a5,80003dce <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e2e:	865e                	mv	a2,s7
    80003e30:	85d6                	mv	a1,s5
    80003e32:	854e                	mv	a0,s3
    80003e34:	00000097          	auipc	ra,0x0
    80003e38:	e64080e7          	jalr	-412(ra) # 80003c98 <dirlookup>
    80003e3c:	8a2a                	mv	s4,a0
    80003e3e:	dd51                	beqz	a0,80003dda <namex+0x92>
    iunlockput(ip);
    80003e40:	854e                	mv	a0,s3
    80003e42:	00000097          	auipc	ra,0x0
    80003e46:	bd4080e7          	jalr	-1068(ra) # 80003a16 <iunlockput>
    ip = next;
    80003e4a:	89d2                	mv	s3,s4
  while(*path == '/')
    80003e4c:	0004c783          	lbu	a5,0(s1)
    80003e50:	05279763          	bne	a5,s2,80003e9e <namex+0x156>
    path++;
    80003e54:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e56:	0004c783          	lbu	a5,0(s1)
    80003e5a:	ff278de3          	beq	a5,s2,80003e54 <namex+0x10c>
  if(*path == 0)
    80003e5e:	c79d                	beqz	a5,80003e8c <namex+0x144>
    path++;
    80003e60:	85a6                	mv	a1,s1
  len = path - s;
    80003e62:	8a5e                	mv	s4,s7
    80003e64:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e66:	01278963          	beq	a5,s2,80003e78 <namex+0x130>
    80003e6a:	dfbd                	beqz	a5,80003de8 <namex+0xa0>
    path++;
    80003e6c:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e6e:	0004c783          	lbu	a5,0(s1)
    80003e72:	ff279ce3          	bne	a5,s2,80003e6a <namex+0x122>
    80003e76:	bf8d                	j	80003de8 <namex+0xa0>
    memmove(name, s, len);
    80003e78:	2601                	sext.w	a2,a2
    80003e7a:	8556                	mv	a0,s5
    80003e7c:	ffffd097          	auipc	ra,0xffffd
    80003e80:	fce080e7          	jalr	-50(ra) # 80000e4a <memmove>
    name[len] = 0;
    80003e84:	9a56                	add	s4,s4,s5
    80003e86:	000a0023          	sb	zero,0(s4)
    80003e8a:	bf9d                	j	80003e00 <namex+0xb8>
  if(nameiparent){
    80003e8c:	f20b03e3          	beqz	s6,80003db2 <namex+0x6a>
    iput(ip);
    80003e90:	854e                	mv	a0,s3
    80003e92:	00000097          	auipc	ra,0x0
    80003e96:	adc080e7          	jalr	-1316(ra) # 8000396e <iput>
    return 0;
    80003e9a:	4981                	li	s3,0
    80003e9c:	bf19                	j	80003db2 <namex+0x6a>
  if(*path == 0)
    80003e9e:	d7fd                	beqz	a5,80003e8c <namex+0x144>
  while(*path != '/' && *path != 0)
    80003ea0:	0004c783          	lbu	a5,0(s1)
    80003ea4:	85a6                	mv	a1,s1
    80003ea6:	b7d1                	j	80003e6a <namex+0x122>

0000000080003ea8 <dirlink>:
{
    80003ea8:	7139                	addi	sp,sp,-64
    80003eaa:	fc06                	sd	ra,56(sp)
    80003eac:	f822                	sd	s0,48(sp)
    80003eae:	f426                	sd	s1,40(sp)
    80003eb0:	f04a                	sd	s2,32(sp)
    80003eb2:	ec4e                	sd	s3,24(sp)
    80003eb4:	e852                	sd	s4,16(sp)
    80003eb6:	0080                	addi	s0,sp,64
    80003eb8:	892a                	mv	s2,a0
    80003eba:	8a2e                	mv	s4,a1
    80003ebc:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003ebe:	4601                	li	a2,0
    80003ec0:	00000097          	auipc	ra,0x0
    80003ec4:	dd8080e7          	jalr	-552(ra) # 80003c98 <dirlookup>
    80003ec8:	e93d                	bnez	a0,80003f3e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eca:	04c92483          	lw	s1,76(s2)
    80003ece:	c49d                	beqz	s1,80003efc <dirlink+0x54>
    80003ed0:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ed2:	4741                	li	a4,16
    80003ed4:	86a6                	mv	a3,s1
    80003ed6:	fc040613          	addi	a2,s0,-64
    80003eda:	4581                	li	a1,0
    80003edc:	854a                	mv	a0,s2
    80003ede:	00000097          	auipc	ra,0x0
    80003ee2:	b8a080e7          	jalr	-1142(ra) # 80003a68 <readi>
    80003ee6:	47c1                	li	a5,16
    80003ee8:	06f51163          	bne	a0,a5,80003f4a <dirlink+0xa2>
    if(de.inum == 0)
    80003eec:	fc045783          	lhu	a5,-64(s0)
    80003ef0:	c791                	beqz	a5,80003efc <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ef2:	24c1                	addiw	s1,s1,16
    80003ef4:	04c92783          	lw	a5,76(s2)
    80003ef8:	fcf4ede3          	bltu	s1,a5,80003ed2 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003efc:	4639                	li	a2,14
    80003efe:	85d2                	mv	a1,s4
    80003f00:	fc240513          	addi	a0,s0,-62
    80003f04:	ffffd097          	auipc	ra,0xffffd
    80003f08:	ffa080e7          	jalr	-6(ra) # 80000efe <strncpy>
  de.inum = inum;
    80003f0c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f10:	4741                	li	a4,16
    80003f12:	86a6                	mv	a3,s1
    80003f14:	fc040613          	addi	a2,s0,-64
    80003f18:	4581                	li	a1,0
    80003f1a:	854a                	mv	a0,s2
    80003f1c:	00000097          	auipc	ra,0x0
    80003f20:	c44080e7          	jalr	-956(ra) # 80003b60 <writei>
    80003f24:	872a                	mv	a4,a0
    80003f26:	47c1                	li	a5,16
  return 0;
    80003f28:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f2a:	02f71863          	bne	a4,a5,80003f5a <dirlink+0xb2>
}
    80003f2e:	70e2                	ld	ra,56(sp)
    80003f30:	7442                	ld	s0,48(sp)
    80003f32:	74a2                	ld	s1,40(sp)
    80003f34:	7902                	ld	s2,32(sp)
    80003f36:	69e2                	ld	s3,24(sp)
    80003f38:	6a42                	ld	s4,16(sp)
    80003f3a:	6121                	addi	sp,sp,64
    80003f3c:	8082                	ret
    iput(ip);
    80003f3e:	00000097          	auipc	ra,0x0
    80003f42:	a30080e7          	jalr	-1488(ra) # 8000396e <iput>
    return -1;
    80003f46:	557d                	li	a0,-1
    80003f48:	b7dd                	j	80003f2e <dirlink+0x86>
      panic("dirlink read");
    80003f4a:	00004517          	auipc	a0,0x4
    80003f4e:	6d650513          	addi	a0,a0,1750 # 80008620 <syscalls+0x1c8>
    80003f52:	ffffc097          	auipc	ra,0xffffc
    80003f56:	5ec080e7          	jalr	1516(ra) # 8000053e <panic>
    panic("dirlink");
    80003f5a:	00004517          	auipc	a0,0x4
    80003f5e:	7d650513          	addi	a0,a0,2006 # 80008730 <syscalls+0x2d8>
    80003f62:	ffffc097          	auipc	ra,0xffffc
    80003f66:	5dc080e7          	jalr	1500(ra) # 8000053e <panic>

0000000080003f6a <namei>:

struct inode*
namei(char *path)
{
    80003f6a:	1101                	addi	sp,sp,-32
    80003f6c:	ec06                	sd	ra,24(sp)
    80003f6e:	e822                	sd	s0,16(sp)
    80003f70:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f72:	fe040613          	addi	a2,s0,-32
    80003f76:	4581                	li	a1,0
    80003f78:	00000097          	auipc	ra,0x0
    80003f7c:	dd0080e7          	jalr	-560(ra) # 80003d48 <namex>
}
    80003f80:	60e2                	ld	ra,24(sp)
    80003f82:	6442                	ld	s0,16(sp)
    80003f84:	6105                	addi	sp,sp,32
    80003f86:	8082                	ret

0000000080003f88 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f88:	1141                	addi	sp,sp,-16
    80003f8a:	e406                	sd	ra,8(sp)
    80003f8c:	e022                	sd	s0,0(sp)
    80003f8e:	0800                	addi	s0,sp,16
    80003f90:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f92:	4585                	li	a1,1
    80003f94:	00000097          	auipc	ra,0x0
    80003f98:	db4080e7          	jalr	-588(ra) # 80003d48 <namex>
}
    80003f9c:	60a2                	ld	ra,8(sp)
    80003f9e:	6402                	ld	s0,0(sp)
    80003fa0:	0141                	addi	sp,sp,16
    80003fa2:	8082                	ret

0000000080003fa4 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003fa4:	1101                	addi	sp,sp,-32
    80003fa6:	ec06                	sd	ra,24(sp)
    80003fa8:	e822                	sd	s0,16(sp)
    80003faa:	e426                	sd	s1,8(sp)
    80003fac:	e04a                	sd	s2,0(sp)
    80003fae:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003fb0:	0003d917          	auipc	s2,0x3d
    80003fb4:	2d890913          	addi	s2,s2,728 # 80041288 <log>
    80003fb8:	01892583          	lw	a1,24(s2)
    80003fbc:	02892503          	lw	a0,40(s2)
    80003fc0:	fffff097          	auipc	ra,0xfffff
    80003fc4:	ff2080e7          	jalr	-14(ra) # 80002fb2 <bread>
    80003fc8:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003fca:	02c92683          	lw	a3,44(s2)
    80003fce:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003fd0:	02d05763          	blez	a3,80003ffe <write_head+0x5a>
    80003fd4:	0003d797          	auipc	a5,0x3d
    80003fd8:	2e478793          	addi	a5,a5,740 # 800412b8 <log+0x30>
    80003fdc:	05c50713          	addi	a4,a0,92
    80003fe0:	36fd                	addiw	a3,a3,-1
    80003fe2:	1682                	slli	a3,a3,0x20
    80003fe4:	9281                	srli	a3,a3,0x20
    80003fe6:	068a                	slli	a3,a3,0x2
    80003fe8:	0003d617          	auipc	a2,0x3d
    80003fec:	2d460613          	addi	a2,a2,724 # 800412bc <log+0x34>
    80003ff0:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003ff2:	4390                	lw	a2,0(a5)
    80003ff4:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003ff6:	0791                	addi	a5,a5,4
    80003ff8:	0711                	addi	a4,a4,4
    80003ffa:	fed79ce3          	bne	a5,a3,80003ff2 <write_head+0x4e>
  }
  bwrite(buf);
    80003ffe:	8526                	mv	a0,s1
    80004000:	fffff097          	auipc	ra,0xfffff
    80004004:	0a4080e7          	jalr	164(ra) # 800030a4 <bwrite>
  brelse(buf);
    80004008:	8526                	mv	a0,s1
    8000400a:	fffff097          	auipc	ra,0xfffff
    8000400e:	0d8080e7          	jalr	216(ra) # 800030e2 <brelse>
}
    80004012:	60e2                	ld	ra,24(sp)
    80004014:	6442                	ld	s0,16(sp)
    80004016:	64a2                	ld	s1,8(sp)
    80004018:	6902                	ld	s2,0(sp)
    8000401a:	6105                	addi	sp,sp,32
    8000401c:	8082                	ret

000000008000401e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000401e:	0003d797          	auipc	a5,0x3d
    80004022:	2967a783          	lw	a5,662(a5) # 800412b4 <log+0x2c>
    80004026:	0af05d63          	blez	a5,800040e0 <install_trans+0xc2>
{
    8000402a:	7139                	addi	sp,sp,-64
    8000402c:	fc06                	sd	ra,56(sp)
    8000402e:	f822                	sd	s0,48(sp)
    80004030:	f426                	sd	s1,40(sp)
    80004032:	f04a                	sd	s2,32(sp)
    80004034:	ec4e                	sd	s3,24(sp)
    80004036:	e852                	sd	s4,16(sp)
    80004038:	e456                	sd	s5,8(sp)
    8000403a:	e05a                	sd	s6,0(sp)
    8000403c:	0080                	addi	s0,sp,64
    8000403e:	8b2a                	mv	s6,a0
    80004040:	0003da97          	auipc	s5,0x3d
    80004044:	278a8a93          	addi	s5,s5,632 # 800412b8 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004048:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000404a:	0003d997          	auipc	s3,0x3d
    8000404e:	23e98993          	addi	s3,s3,574 # 80041288 <log>
    80004052:	a035                	j	8000407e <install_trans+0x60>
      bunpin(dbuf);
    80004054:	8526                	mv	a0,s1
    80004056:	fffff097          	auipc	ra,0xfffff
    8000405a:	166080e7          	jalr	358(ra) # 800031bc <bunpin>
    brelse(lbuf);
    8000405e:	854a                	mv	a0,s2
    80004060:	fffff097          	auipc	ra,0xfffff
    80004064:	082080e7          	jalr	130(ra) # 800030e2 <brelse>
    brelse(dbuf);
    80004068:	8526                	mv	a0,s1
    8000406a:	fffff097          	auipc	ra,0xfffff
    8000406e:	078080e7          	jalr	120(ra) # 800030e2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004072:	2a05                	addiw	s4,s4,1
    80004074:	0a91                	addi	s5,s5,4
    80004076:	02c9a783          	lw	a5,44(s3)
    8000407a:	04fa5963          	bge	s4,a5,800040cc <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000407e:	0189a583          	lw	a1,24(s3)
    80004082:	014585bb          	addw	a1,a1,s4
    80004086:	2585                	addiw	a1,a1,1
    80004088:	0289a503          	lw	a0,40(s3)
    8000408c:	fffff097          	auipc	ra,0xfffff
    80004090:	f26080e7          	jalr	-218(ra) # 80002fb2 <bread>
    80004094:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004096:	000aa583          	lw	a1,0(s5)
    8000409a:	0289a503          	lw	a0,40(s3)
    8000409e:	fffff097          	auipc	ra,0xfffff
    800040a2:	f14080e7          	jalr	-236(ra) # 80002fb2 <bread>
    800040a6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800040a8:	40000613          	li	a2,1024
    800040ac:	05890593          	addi	a1,s2,88
    800040b0:	05850513          	addi	a0,a0,88
    800040b4:	ffffd097          	auipc	ra,0xffffd
    800040b8:	d96080e7          	jalr	-618(ra) # 80000e4a <memmove>
    bwrite(dbuf);  // write dst to disk
    800040bc:	8526                	mv	a0,s1
    800040be:	fffff097          	auipc	ra,0xfffff
    800040c2:	fe6080e7          	jalr	-26(ra) # 800030a4 <bwrite>
    if(recovering == 0)
    800040c6:	f80b1ce3          	bnez	s6,8000405e <install_trans+0x40>
    800040ca:	b769                	j	80004054 <install_trans+0x36>
}
    800040cc:	70e2                	ld	ra,56(sp)
    800040ce:	7442                	ld	s0,48(sp)
    800040d0:	74a2                	ld	s1,40(sp)
    800040d2:	7902                	ld	s2,32(sp)
    800040d4:	69e2                	ld	s3,24(sp)
    800040d6:	6a42                	ld	s4,16(sp)
    800040d8:	6aa2                	ld	s5,8(sp)
    800040da:	6b02                	ld	s6,0(sp)
    800040dc:	6121                	addi	sp,sp,64
    800040de:	8082                	ret
    800040e0:	8082                	ret

00000000800040e2 <initlog>:
{
    800040e2:	7179                	addi	sp,sp,-48
    800040e4:	f406                	sd	ra,40(sp)
    800040e6:	f022                	sd	s0,32(sp)
    800040e8:	ec26                	sd	s1,24(sp)
    800040ea:	e84a                	sd	s2,16(sp)
    800040ec:	e44e                	sd	s3,8(sp)
    800040ee:	1800                	addi	s0,sp,48
    800040f0:	892a                	mv	s2,a0
    800040f2:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040f4:	0003d497          	auipc	s1,0x3d
    800040f8:	19448493          	addi	s1,s1,404 # 80041288 <log>
    800040fc:	00004597          	auipc	a1,0x4
    80004100:	53458593          	addi	a1,a1,1332 # 80008630 <syscalls+0x1d8>
    80004104:	8526                	mv	a0,s1
    80004106:	ffffd097          	auipc	ra,0xffffd
    8000410a:	b58080e7          	jalr	-1192(ra) # 80000c5e <initlock>
  log.start = sb->logstart;
    8000410e:	0149a583          	lw	a1,20(s3)
    80004112:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004114:	0109a783          	lw	a5,16(s3)
    80004118:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000411a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000411e:	854a                	mv	a0,s2
    80004120:	fffff097          	auipc	ra,0xfffff
    80004124:	e92080e7          	jalr	-366(ra) # 80002fb2 <bread>
  log.lh.n = lh->n;
    80004128:	4d3c                	lw	a5,88(a0)
    8000412a:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000412c:	02f05563          	blez	a5,80004156 <initlog+0x74>
    80004130:	05c50713          	addi	a4,a0,92
    80004134:	0003d697          	auipc	a3,0x3d
    80004138:	18468693          	addi	a3,a3,388 # 800412b8 <log+0x30>
    8000413c:	37fd                	addiw	a5,a5,-1
    8000413e:	1782                	slli	a5,a5,0x20
    80004140:	9381                	srli	a5,a5,0x20
    80004142:	078a                	slli	a5,a5,0x2
    80004144:	06050613          	addi	a2,a0,96
    80004148:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000414a:	4310                	lw	a2,0(a4)
    8000414c:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000414e:	0711                	addi	a4,a4,4
    80004150:	0691                	addi	a3,a3,4
    80004152:	fef71ce3          	bne	a4,a5,8000414a <initlog+0x68>
  brelse(buf);
    80004156:	fffff097          	auipc	ra,0xfffff
    8000415a:	f8c080e7          	jalr	-116(ra) # 800030e2 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000415e:	4505                	li	a0,1
    80004160:	00000097          	auipc	ra,0x0
    80004164:	ebe080e7          	jalr	-322(ra) # 8000401e <install_trans>
  log.lh.n = 0;
    80004168:	0003d797          	auipc	a5,0x3d
    8000416c:	1407a623          	sw	zero,332(a5) # 800412b4 <log+0x2c>
  write_head(); // clear the log
    80004170:	00000097          	auipc	ra,0x0
    80004174:	e34080e7          	jalr	-460(ra) # 80003fa4 <write_head>
}
    80004178:	70a2                	ld	ra,40(sp)
    8000417a:	7402                	ld	s0,32(sp)
    8000417c:	64e2                	ld	s1,24(sp)
    8000417e:	6942                	ld	s2,16(sp)
    80004180:	69a2                	ld	s3,8(sp)
    80004182:	6145                	addi	sp,sp,48
    80004184:	8082                	ret

0000000080004186 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004186:	1101                	addi	sp,sp,-32
    80004188:	ec06                	sd	ra,24(sp)
    8000418a:	e822                	sd	s0,16(sp)
    8000418c:	e426                	sd	s1,8(sp)
    8000418e:	e04a                	sd	s2,0(sp)
    80004190:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004192:	0003d517          	auipc	a0,0x3d
    80004196:	0f650513          	addi	a0,a0,246 # 80041288 <log>
    8000419a:	ffffd097          	auipc	ra,0xffffd
    8000419e:	b54080e7          	jalr	-1196(ra) # 80000cee <acquire>
  while(1){
    if(log.committing){
    800041a2:	0003d497          	auipc	s1,0x3d
    800041a6:	0e648493          	addi	s1,s1,230 # 80041288 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041aa:	4979                	li	s2,30
    800041ac:	a039                	j	800041ba <begin_op+0x34>
      sleep(&log, &log.lock);
    800041ae:	85a6                	mv	a1,s1
    800041b0:	8526                	mv	a0,s1
    800041b2:	ffffe097          	auipc	ra,0xffffe
    800041b6:	fce080e7          	jalr	-50(ra) # 80002180 <sleep>
    if(log.committing){
    800041ba:	50dc                	lw	a5,36(s1)
    800041bc:	fbed                	bnez	a5,800041ae <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041be:	509c                	lw	a5,32(s1)
    800041c0:	0017871b          	addiw	a4,a5,1
    800041c4:	0007069b          	sext.w	a3,a4
    800041c8:	0027179b          	slliw	a5,a4,0x2
    800041cc:	9fb9                	addw	a5,a5,a4
    800041ce:	0017979b          	slliw	a5,a5,0x1
    800041d2:	54d8                	lw	a4,44(s1)
    800041d4:	9fb9                	addw	a5,a5,a4
    800041d6:	00f95963          	bge	s2,a5,800041e8 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041da:	85a6                	mv	a1,s1
    800041dc:	8526                	mv	a0,s1
    800041de:	ffffe097          	auipc	ra,0xffffe
    800041e2:	fa2080e7          	jalr	-94(ra) # 80002180 <sleep>
    800041e6:	bfd1                	j	800041ba <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041e8:	0003d517          	auipc	a0,0x3d
    800041ec:	0a050513          	addi	a0,a0,160 # 80041288 <log>
    800041f0:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041f2:	ffffd097          	auipc	ra,0xffffd
    800041f6:	bb0080e7          	jalr	-1104(ra) # 80000da2 <release>
      break;
    }
  }
}
    800041fa:	60e2                	ld	ra,24(sp)
    800041fc:	6442                	ld	s0,16(sp)
    800041fe:	64a2                	ld	s1,8(sp)
    80004200:	6902                	ld	s2,0(sp)
    80004202:	6105                	addi	sp,sp,32
    80004204:	8082                	ret

0000000080004206 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004206:	7139                	addi	sp,sp,-64
    80004208:	fc06                	sd	ra,56(sp)
    8000420a:	f822                	sd	s0,48(sp)
    8000420c:	f426                	sd	s1,40(sp)
    8000420e:	f04a                	sd	s2,32(sp)
    80004210:	ec4e                	sd	s3,24(sp)
    80004212:	e852                	sd	s4,16(sp)
    80004214:	e456                	sd	s5,8(sp)
    80004216:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004218:	0003d497          	auipc	s1,0x3d
    8000421c:	07048493          	addi	s1,s1,112 # 80041288 <log>
    80004220:	8526                	mv	a0,s1
    80004222:	ffffd097          	auipc	ra,0xffffd
    80004226:	acc080e7          	jalr	-1332(ra) # 80000cee <acquire>
  log.outstanding -= 1;
    8000422a:	509c                	lw	a5,32(s1)
    8000422c:	37fd                	addiw	a5,a5,-1
    8000422e:	0007891b          	sext.w	s2,a5
    80004232:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004234:	50dc                	lw	a5,36(s1)
    80004236:	efb9                	bnez	a5,80004294 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004238:	06091663          	bnez	s2,800042a4 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000423c:	0003d497          	auipc	s1,0x3d
    80004240:	04c48493          	addi	s1,s1,76 # 80041288 <log>
    80004244:	4785                	li	a5,1
    80004246:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004248:	8526                	mv	a0,s1
    8000424a:	ffffd097          	auipc	ra,0xffffd
    8000424e:	b58080e7          	jalr	-1192(ra) # 80000da2 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004252:	54dc                	lw	a5,44(s1)
    80004254:	06f04763          	bgtz	a5,800042c2 <end_op+0xbc>
    acquire(&log.lock);
    80004258:	0003d497          	auipc	s1,0x3d
    8000425c:	03048493          	addi	s1,s1,48 # 80041288 <log>
    80004260:	8526                	mv	a0,s1
    80004262:	ffffd097          	auipc	ra,0xffffd
    80004266:	a8c080e7          	jalr	-1396(ra) # 80000cee <acquire>
    log.committing = 0;
    8000426a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000426e:	8526                	mv	a0,s1
    80004270:	ffffe097          	auipc	ra,0xffffe
    80004274:	09c080e7          	jalr	156(ra) # 8000230c <wakeup>
    release(&log.lock);
    80004278:	8526                	mv	a0,s1
    8000427a:	ffffd097          	auipc	ra,0xffffd
    8000427e:	b28080e7          	jalr	-1240(ra) # 80000da2 <release>
}
    80004282:	70e2                	ld	ra,56(sp)
    80004284:	7442                	ld	s0,48(sp)
    80004286:	74a2                	ld	s1,40(sp)
    80004288:	7902                	ld	s2,32(sp)
    8000428a:	69e2                	ld	s3,24(sp)
    8000428c:	6a42                	ld	s4,16(sp)
    8000428e:	6aa2                	ld	s5,8(sp)
    80004290:	6121                	addi	sp,sp,64
    80004292:	8082                	ret
    panic("log.committing");
    80004294:	00004517          	auipc	a0,0x4
    80004298:	3a450513          	addi	a0,a0,932 # 80008638 <syscalls+0x1e0>
    8000429c:	ffffc097          	auipc	ra,0xffffc
    800042a0:	2a2080e7          	jalr	674(ra) # 8000053e <panic>
    wakeup(&log);
    800042a4:	0003d497          	auipc	s1,0x3d
    800042a8:	fe448493          	addi	s1,s1,-28 # 80041288 <log>
    800042ac:	8526                	mv	a0,s1
    800042ae:	ffffe097          	auipc	ra,0xffffe
    800042b2:	05e080e7          	jalr	94(ra) # 8000230c <wakeup>
  release(&log.lock);
    800042b6:	8526                	mv	a0,s1
    800042b8:	ffffd097          	auipc	ra,0xffffd
    800042bc:	aea080e7          	jalr	-1302(ra) # 80000da2 <release>
  if(do_commit){
    800042c0:	b7c9                	j	80004282 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042c2:	0003da97          	auipc	s5,0x3d
    800042c6:	ff6a8a93          	addi	s5,s5,-10 # 800412b8 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042ca:	0003da17          	auipc	s4,0x3d
    800042ce:	fbea0a13          	addi	s4,s4,-66 # 80041288 <log>
    800042d2:	018a2583          	lw	a1,24(s4)
    800042d6:	012585bb          	addw	a1,a1,s2
    800042da:	2585                	addiw	a1,a1,1
    800042dc:	028a2503          	lw	a0,40(s4)
    800042e0:	fffff097          	auipc	ra,0xfffff
    800042e4:	cd2080e7          	jalr	-814(ra) # 80002fb2 <bread>
    800042e8:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042ea:	000aa583          	lw	a1,0(s5)
    800042ee:	028a2503          	lw	a0,40(s4)
    800042f2:	fffff097          	auipc	ra,0xfffff
    800042f6:	cc0080e7          	jalr	-832(ra) # 80002fb2 <bread>
    800042fa:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800042fc:	40000613          	li	a2,1024
    80004300:	05850593          	addi	a1,a0,88
    80004304:	05848513          	addi	a0,s1,88
    80004308:	ffffd097          	auipc	ra,0xffffd
    8000430c:	b42080e7          	jalr	-1214(ra) # 80000e4a <memmove>
    bwrite(to);  // write the log
    80004310:	8526                	mv	a0,s1
    80004312:	fffff097          	auipc	ra,0xfffff
    80004316:	d92080e7          	jalr	-622(ra) # 800030a4 <bwrite>
    brelse(from);
    8000431a:	854e                	mv	a0,s3
    8000431c:	fffff097          	auipc	ra,0xfffff
    80004320:	dc6080e7          	jalr	-570(ra) # 800030e2 <brelse>
    brelse(to);
    80004324:	8526                	mv	a0,s1
    80004326:	fffff097          	auipc	ra,0xfffff
    8000432a:	dbc080e7          	jalr	-580(ra) # 800030e2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000432e:	2905                	addiw	s2,s2,1
    80004330:	0a91                	addi	s5,s5,4
    80004332:	02ca2783          	lw	a5,44(s4)
    80004336:	f8f94ee3          	blt	s2,a5,800042d2 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000433a:	00000097          	auipc	ra,0x0
    8000433e:	c6a080e7          	jalr	-918(ra) # 80003fa4 <write_head>
    install_trans(0); // Now install writes to home locations
    80004342:	4501                	li	a0,0
    80004344:	00000097          	auipc	ra,0x0
    80004348:	cda080e7          	jalr	-806(ra) # 8000401e <install_trans>
    log.lh.n = 0;
    8000434c:	0003d797          	auipc	a5,0x3d
    80004350:	f607a423          	sw	zero,-152(a5) # 800412b4 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004354:	00000097          	auipc	ra,0x0
    80004358:	c50080e7          	jalr	-944(ra) # 80003fa4 <write_head>
    8000435c:	bdf5                	j	80004258 <end_op+0x52>

000000008000435e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000435e:	1101                	addi	sp,sp,-32
    80004360:	ec06                	sd	ra,24(sp)
    80004362:	e822                	sd	s0,16(sp)
    80004364:	e426                	sd	s1,8(sp)
    80004366:	e04a                	sd	s2,0(sp)
    80004368:	1000                	addi	s0,sp,32
    8000436a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000436c:	0003d917          	auipc	s2,0x3d
    80004370:	f1c90913          	addi	s2,s2,-228 # 80041288 <log>
    80004374:	854a                	mv	a0,s2
    80004376:	ffffd097          	auipc	ra,0xffffd
    8000437a:	978080e7          	jalr	-1672(ra) # 80000cee <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000437e:	02c92603          	lw	a2,44(s2)
    80004382:	47f5                	li	a5,29
    80004384:	06c7c563          	blt	a5,a2,800043ee <log_write+0x90>
    80004388:	0003d797          	auipc	a5,0x3d
    8000438c:	f1c7a783          	lw	a5,-228(a5) # 800412a4 <log+0x1c>
    80004390:	37fd                	addiw	a5,a5,-1
    80004392:	04f65e63          	bge	a2,a5,800043ee <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004396:	0003d797          	auipc	a5,0x3d
    8000439a:	f127a783          	lw	a5,-238(a5) # 800412a8 <log+0x20>
    8000439e:	06f05063          	blez	a5,800043fe <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800043a2:	4781                	li	a5,0
    800043a4:	06c05563          	blez	a2,8000440e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043a8:	44cc                	lw	a1,12(s1)
    800043aa:	0003d717          	auipc	a4,0x3d
    800043ae:	f0e70713          	addi	a4,a4,-242 # 800412b8 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800043b2:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043b4:	4314                	lw	a3,0(a4)
    800043b6:	04b68c63          	beq	a3,a1,8000440e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800043ba:	2785                	addiw	a5,a5,1
    800043bc:	0711                	addi	a4,a4,4
    800043be:	fef61be3          	bne	a2,a5,800043b4 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043c2:	0621                	addi	a2,a2,8
    800043c4:	060a                	slli	a2,a2,0x2
    800043c6:	0003d797          	auipc	a5,0x3d
    800043ca:	ec278793          	addi	a5,a5,-318 # 80041288 <log>
    800043ce:	963e                	add	a2,a2,a5
    800043d0:	44dc                	lw	a5,12(s1)
    800043d2:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043d4:	8526                	mv	a0,s1
    800043d6:	fffff097          	auipc	ra,0xfffff
    800043da:	daa080e7          	jalr	-598(ra) # 80003180 <bpin>
    log.lh.n++;
    800043de:	0003d717          	auipc	a4,0x3d
    800043e2:	eaa70713          	addi	a4,a4,-342 # 80041288 <log>
    800043e6:	575c                	lw	a5,44(a4)
    800043e8:	2785                	addiw	a5,a5,1
    800043ea:	d75c                	sw	a5,44(a4)
    800043ec:	a835                	j	80004428 <log_write+0xca>
    panic("too big a transaction");
    800043ee:	00004517          	auipc	a0,0x4
    800043f2:	25a50513          	addi	a0,a0,602 # 80008648 <syscalls+0x1f0>
    800043f6:	ffffc097          	auipc	ra,0xffffc
    800043fa:	148080e7          	jalr	328(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800043fe:	00004517          	auipc	a0,0x4
    80004402:	26250513          	addi	a0,a0,610 # 80008660 <syscalls+0x208>
    80004406:	ffffc097          	auipc	ra,0xffffc
    8000440a:	138080e7          	jalr	312(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    8000440e:	00878713          	addi	a4,a5,8
    80004412:	00271693          	slli	a3,a4,0x2
    80004416:	0003d717          	auipc	a4,0x3d
    8000441a:	e7270713          	addi	a4,a4,-398 # 80041288 <log>
    8000441e:	9736                	add	a4,a4,a3
    80004420:	44d4                	lw	a3,12(s1)
    80004422:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004424:	faf608e3          	beq	a2,a5,800043d4 <log_write+0x76>
  }
  release(&log.lock);
    80004428:	0003d517          	auipc	a0,0x3d
    8000442c:	e6050513          	addi	a0,a0,-416 # 80041288 <log>
    80004430:	ffffd097          	auipc	ra,0xffffd
    80004434:	972080e7          	jalr	-1678(ra) # 80000da2 <release>
}
    80004438:	60e2                	ld	ra,24(sp)
    8000443a:	6442                	ld	s0,16(sp)
    8000443c:	64a2                	ld	s1,8(sp)
    8000443e:	6902                	ld	s2,0(sp)
    80004440:	6105                	addi	sp,sp,32
    80004442:	8082                	ret

0000000080004444 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004444:	1101                	addi	sp,sp,-32
    80004446:	ec06                	sd	ra,24(sp)
    80004448:	e822                	sd	s0,16(sp)
    8000444a:	e426                	sd	s1,8(sp)
    8000444c:	e04a                	sd	s2,0(sp)
    8000444e:	1000                	addi	s0,sp,32
    80004450:	84aa                	mv	s1,a0
    80004452:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004454:	00004597          	auipc	a1,0x4
    80004458:	22c58593          	addi	a1,a1,556 # 80008680 <syscalls+0x228>
    8000445c:	0521                	addi	a0,a0,8
    8000445e:	ffffd097          	auipc	ra,0xffffd
    80004462:	800080e7          	jalr	-2048(ra) # 80000c5e <initlock>
  lk->name = name;
    80004466:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000446a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000446e:	0204a423          	sw	zero,40(s1)
}
    80004472:	60e2                	ld	ra,24(sp)
    80004474:	6442                	ld	s0,16(sp)
    80004476:	64a2                	ld	s1,8(sp)
    80004478:	6902                	ld	s2,0(sp)
    8000447a:	6105                	addi	sp,sp,32
    8000447c:	8082                	ret

000000008000447e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000447e:	1101                	addi	sp,sp,-32
    80004480:	ec06                	sd	ra,24(sp)
    80004482:	e822                	sd	s0,16(sp)
    80004484:	e426                	sd	s1,8(sp)
    80004486:	e04a                	sd	s2,0(sp)
    80004488:	1000                	addi	s0,sp,32
    8000448a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000448c:	00850913          	addi	s2,a0,8
    80004490:	854a                	mv	a0,s2
    80004492:	ffffd097          	auipc	ra,0xffffd
    80004496:	85c080e7          	jalr	-1956(ra) # 80000cee <acquire>
  while (lk->locked) {
    8000449a:	409c                	lw	a5,0(s1)
    8000449c:	cb89                	beqz	a5,800044ae <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000449e:	85ca                	mv	a1,s2
    800044a0:	8526                	mv	a0,s1
    800044a2:	ffffe097          	auipc	ra,0xffffe
    800044a6:	cde080e7          	jalr	-802(ra) # 80002180 <sleep>
  while (lk->locked) {
    800044aa:	409c                	lw	a5,0(s1)
    800044ac:	fbed                	bnez	a5,8000449e <acquiresleep+0x20>
  }
  lk->locked = 1;
    800044ae:	4785                	li	a5,1
    800044b0:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800044b2:	ffffd097          	auipc	ra,0xffffd
    800044b6:	612080e7          	jalr	1554(ra) # 80001ac4 <myproc>
    800044ba:	591c                	lw	a5,48(a0)
    800044bc:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044be:	854a                	mv	a0,s2
    800044c0:	ffffd097          	auipc	ra,0xffffd
    800044c4:	8e2080e7          	jalr	-1822(ra) # 80000da2 <release>
}
    800044c8:	60e2                	ld	ra,24(sp)
    800044ca:	6442                	ld	s0,16(sp)
    800044cc:	64a2                	ld	s1,8(sp)
    800044ce:	6902                	ld	s2,0(sp)
    800044d0:	6105                	addi	sp,sp,32
    800044d2:	8082                	ret

00000000800044d4 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044d4:	1101                	addi	sp,sp,-32
    800044d6:	ec06                	sd	ra,24(sp)
    800044d8:	e822                	sd	s0,16(sp)
    800044da:	e426                	sd	s1,8(sp)
    800044dc:	e04a                	sd	s2,0(sp)
    800044de:	1000                	addi	s0,sp,32
    800044e0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044e2:	00850913          	addi	s2,a0,8
    800044e6:	854a                	mv	a0,s2
    800044e8:	ffffd097          	auipc	ra,0xffffd
    800044ec:	806080e7          	jalr	-2042(ra) # 80000cee <acquire>
  lk->locked = 0;
    800044f0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044f4:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044f8:	8526                	mv	a0,s1
    800044fa:	ffffe097          	auipc	ra,0xffffe
    800044fe:	e12080e7          	jalr	-494(ra) # 8000230c <wakeup>
  release(&lk->lk);
    80004502:	854a                	mv	a0,s2
    80004504:	ffffd097          	auipc	ra,0xffffd
    80004508:	89e080e7          	jalr	-1890(ra) # 80000da2 <release>
}
    8000450c:	60e2                	ld	ra,24(sp)
    8000450e:	6442                	ld	s0,16(sp)
    80004510:	64a2                	ld	s1,8(sp)
    80004512:	6902                	ld	s2,0(sp)
    80004514:	6105                	addi	sp,sp,32
    80004516:	8082                	ret

0000000080004518 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004518:	7179                	addi	sp,sp,-48
    8000451a:	f406                	sd	ra,40(sp)
    8000451c:	f022                	sd	s0,32(sp)
    8000451e:	ec26                	sd	s1,24(sp)
    80004520:	e84a                	sd	s2,16(sp)
    80004522:	e44e                	sd	s3,8(sp)
    80004524:	1800                	addi	s0,sp,48
    80004526:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004528:	00850913          	addi	s2,a0,8
    8000452c:	854a                	mv	a0,s2
    8000452e:	ffffc097          	auipc	ra,0xffffc
    80004532:	7c0080e7          	jalr	1984(ra) # 80000cee <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004536:	409c                	lw	a5,0(s1)
    80004538:	ef99                	bnez	a5,80004556 <holdingsleep+0x3e>
    8000453a:	4481                	li	s1,0
  release(&lk->lk);
    8000453c:	854a                	mv	a0,s2
    8000453e:	ffffd097          	auipc	ra,0xffffd
    80004542:	864080e7          	jalr	-1948(ra) # 80000da2 <release>
  return r;
}
    80004546:	8526                	mv	a0,s1
    80004548:	70a2                	ld	ra,40(sp)
    8000454a:	7402                	ld	s0,32(sp)
    8000454c:	64e2                	ld	s1,24(sp)
    8000454e:	6942                	ld	s2,16(sp)
    80004550:	69a2                	ld	s3,8(sp)
    80004552:	6145                	addi	sp,sp,48
    80004554:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004556:	0284a983          	lw	s3,40(s1)
    8000455a:	ffffd097          	auipc	ra,0xffffd
    8000455e:	56a080e7          	jalr	1386(ra) # 80001ac4 <myproc>
    80004562:	5904                	lw	s1,48(a0)
    80004564:	413484b3          	sub	s1,s1,s3
    80004568:	0014b493          	seqz	s1,s1
    8000456c:	bfc1                	j	8000453c <holdingsleep+0x24>

000000008000456e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000456e:	1141                	addi	sp,sp,-16
    80004570:	e406                	sd	ra,8(sp)
    80004572:	e022                	sd	s0,0(sp)
    80004574:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004576:	00004597          	auipc	a1,0x4
    8000457a:	11a58593          	addi	a1,a1,282 # 80008690 <syscalls+0x238>
    8000457e:	0003d517          	auipc	a0,0x3d
    80004582:	e5250513          	addi	a0,a0,-430 # 800413d0 <ftable>
    80004586:	ffffc097          	auipc	ra,0xffffc
    8000458a:	6d8080e7          	jalr	1752(ra) # 80000c5e <initlock>
}
    8000458e:	60a2                	ld	ra,8(sp)
    80004590:	6402                	ld	s0,0(sp)
    80004592:	0141                	addi	sp,sp,16
    80004594:	8082                	ret

0000000080004596 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004596:	1101                	addi	sp,sp,-32
    80004598:	ec06                	sd	ra,24(sp)
    8000459a:	e822                	sd	s0,16(sp)
    8000459c:	e426                	sd	s1,8(sp)
    8000459e:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800045a0:	0003d517          	auipc	a0,0x3d
    800045a4:	e3050513          	addi	a0,a0,-464 # 800413d0 <ftable>
    800045a8:	ffffc097          	auipc	ra,0xffffc
    800045ac:	746080e7          	jalr	1862(ra) # 80000cee <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045b0:	0003d497          	auipc	s1,0x3d
    800045b4:	e3848493          	addi	s1,s1,-456 # 800413e8 <ftable+0x18>
    800045b8:	0003e717          	auipc	a4,0x3e
    800045bc:	dd070713          	addi	a4,a4,-560 # 80042388 <ftable+0xfb8>
    if(f->ref == 0){
    800045c0:	40dc                	lw	a5,4(s1)
    800045c2:	cf99                	beqz	a5,800045e0 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045c4:	02848493          	addi	s1,s1,40
    800045c8:	fee49ce3          	bne	s1,a4,800045c0 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045cc:	0003d517          	auipc	a0,0x3d
    800045d0:	e0450513          	addi	a0,a0,-508 # 800413d0 <ftable>
    800045d4:	ffffc097          	auipc	ra,0xffffc
    800045d8:	7ce080e7          	jalr	1998(ra) # 80000da2 <release>
  return 0;
    800045dc:	4481                	li	s1,0
    800045de:	a819                	j	800045f4 <filealloc+0x5e>
      f->ref = 1;
    800045e0:	4785                	li	a5,1
    800045e2:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045e4:	0003d517          	auipc	a0,0x3d
    800045e8:	dec50513          	addi	a0,a0,-532 # 800413d0 <ftable>
    800045ec:	ffffc097          	auipc	ra,0xffffc
    800045f0:	7b6080e7          	jalr	1974(ra) # 80000da2 <release>
}
    800045f4:	8526                	mv	a0,s1
    800045f6:	60e2                	ld	ra,24(sp)
    800045f8:	6442                	ld	s0,16(sp)
    800045fa:	64a2                	ld	s1,8(sp)
    800045fc:	6105                	addi	sp,sp,32
    800045fe:	8082                	ret

0000000080004600 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004600:	1101                	addi	sp,sp,-32
    80004602:	ec06                	sd	ra,24(sp)
    80004604:	e822                	sd	s0,16(sp)
    80004606:	e426                	sd	s1,8(sp)
    80004608:	1000                	addi	s0,sp,32
    8000460a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000460c:	0003d517          	auipc	a0,0x3d
    80004610:	dc450513          	addi	a0,a0,-572 # 800413d0 <ftable>
    80004614:	ffffc097          	auipc	ra,0xffffc
    80004618:	6da080e7          	jalr	1754(ra) # 80000cee <acquire>
  if(f->ref < 1)
    8000461c:	40dc                	lw	a5,4(s1)
    8000461e:	02f05263          	blez	a5,80004642 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004622:	2785                	addiw	a5,a5,1
    80004624:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004626:	0003d517          	auipc	a0,0x3d
    8000462a:	daa50513          	addi	a0,a0,-598 # 800413d0 <ftable>
    8000462e:	ffffc097          	auipc	ra,0xffffc
    80004632:	774080e7          	jalr	1908(ra) # 80000da2 <release>
  return f;
}
    80004636:	8526                	mv	a0,s1
    80004638:	60e2                	ld	ra,24(sp)
    8000463a:	6442                	ld	s0,16(sp)
    8000463c:	64a2                	ld	s1,8(sp)
    8000463e:	6105                	addi	sp,sp,32
    80004640:	8082                	ret
    panic("filedup");
    80004642:	00004517          	auipc	a0,0x4
    80004646:	05650513          	addi	a0,a0,86 # 80008698 <syscalls+0x240>
    8000464a:	ffffc097          	auipc	ra,0xffffc
    8000464e:	ef4080e7          	jalr	-268(ra) # 8000053e <panic>

0000000080004652 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004652:	7139                	addi	sp,sp,-64
    80004654:	fc06                	sd	ra,56(sp)
    80004656:	f822                	sd	s0,48(sp)
    80004658:	f426                	sd	s1,40(sp)
    8000465a:	f04a                	sd	s2,32(sp)
    8000465c:	ec4e                	sd	s3,24(sp)
    8000465e:	e852                	sd	s4,16(sp)
    80004660:	e456                	sd	s5,8(sp)
    80004662:	0080                	addi	s0,sp,64
    80004664:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004666:	0003d517          	auipc	a0,0x3d
    8000466a:	d6a50513          	addi	a0,a0,-662 # 800413d0 <ftable>
    8000466e:	ffffc097          	auipc	ra,0xffffc
    80004672:	680080e7          	jalr	1664(ra) # 80000cee <acquire>
  if(f->ref < 1)
    80004676:	40dc                	lw	a5,4(s1)
    80004678:	06f05163          	blez	a5,800046da <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000467c:	37fd                	addiw	a5,a5,-1
    8000467e:	0007871b          	sext.w	a4,a5
    80004682:	c0dc                	sw	a5,4(s1)
    80004684:	06e04363          	bgtz	a4,800046ea <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004688:	0004a903          	lw	s2,0(s1)
    8000468c:	0094ca83          	lbu	s5,9(s1)
    80004690:	0104ba03          	ld	s4,16(s1)
    80004694:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004698:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000469c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800046a0:	0003d517          	auipc	a0,0x3d
    800046a4:	d3050513          	addi	a0,a0,-720 # 800413d0 <ftable>
    800046a8:	ffffc097          	auipc	ra,0xffffc
    800046ac:	6fa080e7          	jalr	1786(ra) # 80000da2 <release>

  if(ff.type == FD_PIPE){
    800046b0:	4785                	li	a5,1
    800046b2:	04f90d63          	beq	s2,a5,8000470c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800046b6:	3979                	addiw	s2,s2,-2
    800046b8:	4785                	li	a5,1
    800046ba:	0527e063          	bltu	a5,s2,800046fa <fileclose+0xa8>
    begin_op();
    800046be:	00000097          	auipc	ra,0x0
    800046c2:	ac8080e7          	jalr	-1336(ra) # 80004186 <begin_op>
    iput(ff.ip);
    800046c6:	854e                	mv	a0,s3
    800046c8:	fffff097          	auipc	ra,0xfffff
    800046cc:	2a6080e7          	jalr	678(ra) # 8000396e <iput>
    end_op();
    800046d0:	00000097          	auipc	ra,0x0
    800046d4:	b36080e7          	jalr	-1226(ra) # 80004206 <end_op>
    800046d8:	a00d                	j	800046fa <fileclose+0xa8>
    panic("fileclose");
    800046da:	00004517          	auipc	a0,0x4
    800046de:	fc650513          	addi	a0,a0,-58 # 800086a0 <syscalls+0x248>
    800046e2:	ffffc097          	auipc	ra,0xffffc
    800046e6:	e5c080e7          	jalr	-420(ra) # 8000053e <panic>
    release(&ftable.lock);
    800046ea:	0003d517          	auipc	a0,0x3d
    800046ee:	ce650513          	addi	a0,a0,-794 # 800413d0 <ftable>
    800046f2:	ffffc097          	auipc	ra,0xffffc
    800046f6:	6b0080e7          	jalr	1712(ra) # 80000da2 <release>
  }
}
    800046fa:	70e2                	ld	ra,56(sp)
    800046fc:	7442                	ld	s0,48(sp)
    800046fe:	74a2                	ld	s1,40(sp)
    80004700:	7902                	ld	s2,32(sp)
    80004702:	69e2                	ld	s3,24(sp)
    80004704:	6a42                	ld	s4,16(sp)
    80004706:	6aa2                	ld	s5,8(sp)
    80004708:	6121                	addi	sp,sp,64
    8000470a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000470c:	85d6                	mv	a1,s5
    8000470e:	8552                	mv	a0,s4
    80004710:	00000097          	auipc	ra,0x0
    80004714:	34c080e7          	jalr	844(ra) # 80004a5c <pipeclose>
    80004718:	b7cd                	j	800046fa <fileclose+0xa8>

000000008000471a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000471a:	715d                	addi	sp,sp,-80
    8000471c:	e486                	sd	ra,72(sp)
    8000471e:	e0a2                	sd	s0,64(sp)
    80004720:	fc26                	sd	s1,56(sp)
    80004722:	f84a                	sd	s2,48(sp)
    80004724:	f44e                	sd	s3,40(sp)
    80004726:	0880                	addi	s0,sp,80
    80004728:	84aa                	mv	s1,a0
    8000472a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000472c:	ffffd097          	auipc	ra,0xffffd
    80004730:	398080e7          	jalr	920(ra) # 80001ac4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004734:	409c                	lw	a5,0(s1)
    80004736:	37f9                	addiw	a5,a5,-2
    80004738:	4705                	li	a4,1
    8000473a:	04f76763          	bltu	a4,a5,80004788 <filestat+0x6e>
    8000473e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004740:	6c88                	ld	a0,24(s1)
    80004742:	fffff097          	auipc	ra,0xfffff
    80004746:	072080e7          	jalr	114(ra) # 800037b4 <ilock>
    stati(f->ip, &st);
    8000474a:	fb840593          	addi	a1,s0,-72
    8000474e:	6c88                	ld	a0,24(s1)
    80004750:	fffff097          	auipc	ra,0xfffff
    80004754:	2ee080e7          	jalr	750(ra) # 80003a3e <stati>
    iunlock(f->ip);
    80004758:	6c88                	ld	a0,24(s1)
    8000475a:	fffff097          	auipc	ra,0xfffff
    8000475e:	11c080e7          	jalr	284(ra) # 80003876 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004762:	46e1                	li	a3,24
    80004764:	fb840613          	addi	a2,s0,-72
    80004768:	85ce                	mv	a1,s3
    8000476a:	05093503          	ld	a0,80(s2)
    8000476e:	ffffd097          	auipc	ra,0xffffd
    80004772:	004080e7          	jalr	4(ra) # 80001772 <copyout>
    80004776:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000477a:	60a6                	ld	ra,72(sp)
    8000477c:	6406                	ld	s0,64(sp)
    8000477e:	74e2                	ld	s1,56(sp)
    80004780:	7942                	ld	s2,48(sp)
    80004782:	79a2                	ld	s3,40(sp)
    80004784:	6161                	addi	sp,sp,80
    80004786:	8082                	ret
  return -1;
    80004788:	557d                	li	a0,-1
    8000478a:	bfc5                	j	8000477a <filestat+0x60>

000000008000478c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000478c:	7179                	addi	sp,sp,-48
    8000478e:	f406                	sd	ra,40(sp)
    80004790:	f022                	sd	s0,32(sp)
    80004792:	ec26                	sd	s1,24(sp)
    80004794:	e84a                	sd	s2,16(sp)
    80004796:	e44e                	sd	s3,8(sp)
    80004798:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000479a:	00854783          	lbu	a5,8(a0)
    8000479e:	c3d5                	beqz	a5,80004842 <fileread+0xb6>
    800047a0:	84aa                	mv	s1,a0
    800047a2:	89ae                	mv	s3,a1
    800047a4:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800047a6:	411c                	lw	a5,0(a0)
    800047a8:	4705                	li	a4,1
    800047aa:	04e78963          	beq	a5,a4,800047fc <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047ae:	470d                	li	a4,3
    800047b0:	04e78d63          	beq	a5,a4,8000480a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800047b4:	4709                	li	a4,2
    800047b6:	06e79e63          	bne	a5,a4,80004832 <fileread+0xa6>
    ilock(f->ip);
    800047ba:	6d08                	ld	a0,24(a0)
    800047bc:	fffff097          	auipc	ra,0xfffff
    800047c0:	ff8080e7          	jalr	-8(ra) # 800037b4 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047c4:	874a                	mv	a4,s2
    800047c6:	5094                	lw	a3,32(s1)
    800047c8:	864e                	mv	a2,s3
    800047ca:	4585                	li	a1,1
    800047cc:	6c88                	ld	a0,24(s1)
    800047ce:	fffff097          	auipc	ra,0xfffff
    800047d2:	29a080e7          	jalr	666(ra) # 80003a68 <readi>
    800047d6:	892a                	mv	s2,a0
    800047d8:	00a05563          	blez	a0,800047e2 <fileread+0x56>
      f->off += r;
    800047dc:	509c                	lw	a5,32(s1)
    800047de:	9fa9                	addw	a5,a5,a0
    800047e0:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047e2:	6c88                	ld	a0,24(s1)
    800047e4:	fffff097          	auipc	ra,0xfffff
    800047e8:	092080e7          	jalr	146(ra) # 80003876 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047ec:	854a                	mv	a0,s2
    800047ee:	70a2                	ld	ra,40(sp)
    800047f0:	7402                	ld	s0,32(sp)
    800047f2:	64e2                	ld	s1,24(sp)
    800047f4:	6942                	ld	s2,16(sp)
    800047f6:	69a2                	ld	s3,8(sp)
    800047f8:	6145                	addi	sp,sp,48
    800047fa:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800047fc:	6908                	ld	a0,16(a0)
    800047fe:	00000097          	auipc	ra,0x0
    80004802:	3c8080e7          	jalr	968(ra) # 80004bc6 <piperead>
    80004806:	892a                	mv	s2,a0
    80004808:	b7d5                	j	800047ec <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000480a:	02451783          	lh	a5,36(a0)
    8000480e:	03079693          	slli	a3,a5,0x30
    80004812:	92c1                	srli	a3,a3,0x30
    80004814:	4725                	li	a4,9
    80004816:	02d76863          	bltu	a4,a3,80004846 <fileread+0xba>
    8000481a:	0792                	slli	a5,a5,0x4
    8000481c:	0003d717          	auipc	a4,0x3d
    80004820:	b1470713          	addi	a4,a4,-1260 # 80041330 <devsw>
    80004824:	97ba                	add	a5,a5,a4
    80004826:	639c                	ld	a5,0(a5)
    80004828:	c38d                	beqz	a5,8000484a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000482a:	4505                	li	a0,1
    8000482c:	9782                	jalr	a5
    8000482e:	892a                	mv	s2,a0
    80004830:	bf75                	j	800047ec <fileread+0x60>
    panic("fileread");
    80004832:	00004517          	auipc	a0,0x4
    80004836:	e7e50513          	addi	a0,a0,-386 # 800086b0 <syscalls+0x258>
    8000483a:	ffffc097          	auipc	ra,0xffffc
    8000483e:	d04080e7          	jalr	-764(ra) # 8000053e <panic>
    return -1;
    80004842:	597d                	li	s2,-1
    80004844:	b765                	j	800047ec <fileread+0x60>
      return -1;
    80004846:	597d                	li	s2,-1
    80004848:	b755                	j	800047ec <fileread+0x60>
    8000484a:	597d                	li	s2,-1
    8000484c:	b745                	j	800047ec <fileread+0x60>

000000008000484e <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000484e:	715d                	addi	sp,sp,-80
    80004850:	e486                	sd	ra,72(sp)
    80004852:	e0a2                	sd	s0,64(sp)
    80004854:	fc26                	sd	s1,56(sp)
    80004856:	f84a                	sd	s2,48(sp)
    80004858:	f44e                	sd	s3,40(sp)
    8000485a:	f052                	sd	s4,32(sp)
    8000485c:	ec56                	sd	s5,24(sp)
    8000485e:	e85a                	sd	s6,16(sp)
    80004860:	e45e                	sd	s7,8(sp)
    80004862:	e062                	sd	s8,0(sp)
    80004864:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004866:	00954783          	lbu	a5,9(a0)
    8000486a:	10078663          	beqz	a5,80004976 <filewrite+0x128>
    8000486e:	892a                	mv	s2,a0
    80004870:	8aae                	mv	s5,a1
    80004872:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004874:	411c                	lw	a5,0(a0)
    80004876:	4705                	li	a4,1
    80004878:	02e78263          	beq	a5,a4,8000489c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000487c:	470d                	li	a4,3
    8000487e:	02e78663          	beq	a5,a4,800048aa <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004882:	4709                	li	a4,2
    80004884:	0ee79163          	bne	a5,a4,80004966 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004888:	0ac05d63          	blez	a2,80004942 <filewrite+0xf4>
    int i = 0;
    8000488c:	4981                	li	s3,0
    8000488e:	6b05                	lui	s6,0x1
    80004890:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004894:	6b85                	lui	s7,0x1
    80004896:	c00b8b9b          	addiw	s7,s7,-1024
    8000489a:	a861                	j	80004932 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000489c:	6908                	ld	a0,16(a0)
    8000489e:	00000097          	auipc	ra,0x0
    800048a2:	22e080e7          	jalr	558(ra) # 80004acc <pipewrite>
    800048a6:	8a2a                	mv	s4,a0
    800048a8:	a045                	j	80004948 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800048aa:	02451783          	lh	a5,36(a0)
    800048ae:	03079693          	slli	a3,a5,0x30
    800048b2:	92c1                	srli	a3,a3,0x30
    800048b4:	4725                	li	a4,9
    800048b6:	0cd76263          	bltu	a4,a3,8000497a <filewrite+0x12c>
    800048ba:	0792                	slli	a5,a5,0x4
    800048bc:	0003d717          	auipc	a4,0x3d
    800048c0:	a7470713          	addi	a4,a4,-1420 # 80041330 <devsw>
    800048c4:	97ba                	add	a5,a5,a4
    800048c6:	679c                	ld	a5,8(a5)
    800048c8:	cbdd                	beqz	a5,8000497e <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800048ca:	4505                	li	a0,1
    800048cc:	9782                	jalr	a5
    800048ce:	8a2a                	mv	s4,a0
    800048d0:	a8a5                	j	80004948 <filewrite+0xfa>
    800048d2:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048d6:	00000097          	auipc	ra,0x0
    800048da:	8b0080e7          	jalr	-1872(ra) # 80004186 <begin_op>
      ilock(f->ip);
    800048de:	01893503          	ld	a0,24(s2)
    800048e2:	fffff097          	auipc	ra,0xfffff
    800048e6:	ed2080e7          	jalr	-302(ra) # 800037b4 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048ea:	8762                	mv	a4,s8
    800048ec:	02092683          	lw	a3,32(s2)
    800048f0:	01598633          	add	a2,s3,s5
    800048f4:	4585                	li	a1,1
    800048f6:	01893503          	ld	a0,24(s2)
    800048fa:	fffff097          	auipc	ra,0xfffff
    800048fe:	266080e7          	jalr	614(ra) # 80003b60 <writei>
    80004902:	84aa                	mv	s1,a0
    80004904:	00a05763          	blez	a0,80004912 <filewrite+0xc4>
        f->off += r;
    80004908:	02092783          	lw	a5,32(s2)
    8000490c:	9fa9                	addw	a5,a5,a0
    8000490e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004912:	01893503          	ld	a0,24(s2)
    80004916:	fffff097          	auipc	ra,0xfffff
    8000491a:	f60080e7          	jalr	-160(ra) # 80003876 <iunlock>
      end_op();
    8000491e:	00000097          	auipc	ra,0x0
    80004922:	8e8080e7          	jalr	-1816(ra) # 80004206 <end_op>

      if(r != n1){
    80004926:	009c1f63          	bne	s8,s1,80004944 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000492a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000492e:	0149db63          	bge	s3,s4,80004944 <filewrite+0xf6>
      int n1 = n - i;
    80004932:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004936:	84be                	mv	s1,a5
    80004938:	2781                	sext.w	a5,a5
    8000493a:	f8fb5ce3          	bge	s6,a5,800048d2 <filewrite+0x84>
    8000493e:	84de                	mv	s1,s7
    80004940:	bf49                	j	800048d2 <filewrite+0x84>
    int i = 0;
    80004942:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004944:	013a1f63          	bne	s4,s3,80004962 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004948:	8552                	mv	a0,s4
    8000494a:	60a6                	ld	ra,72(sp)
    8000494c:	6406                	ld	s0,64(sp)
    8000494e:	74e2                	ld	s1,56(sp)
    80004950:	7942                	ld	s2,48(sp)
    80004952:	79a2                	ld	s3,40(sp)
    80004954:	7a02                	ld	s4,32(sp)
    80004956:	6ae2                	ld	s5,24(sp)
    80004958:	6b42                	ld	s6,16(sp)
    8000495a:	6ba2                	ld	s7,8(sp)
    8000495c:	6c02                	ld	s8,0(sp)
    8000495e:	6161                	addi	sp,sp,80
    80004960:	8082                	ret
    ret = (i == n ? n : -1);
    80004962:	5a7d                	li	s4,-1
    80004964:	b7d5                	j	80004948 <filewrite+0xfa>
    panic("filewrite");
    80004966:	00004517          	auipc	a0,0x4
    8000496a:	d5a50513          	addi	a0,a0,-678 # 800086c0 <syscalls+0x268>
    8000496e:	ffffc097          	auipc	ra,0xffffc
    80004972:	bd0080e7          	jalr	-1072(ra) # 8000053e <panic>
    return -1;
    80004976:	5a7d                	li	s4,-1
    80004978:	bfc1                	j	80004948 <filewrite+0xfa>
      return -1;
    8000497a:	5a7d                	li	s4,-1
    8000497c:	b7f1                	j	80004948 <filewrite+0xfa>
    8000497e:	5a7d                	li	s4,-1
    80004980:	b7e1                	j	80004948 <filewrite+0xfa>

0000000080004982 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004982:	7179                	addi	sp,sp,-48
    80004984:	f406                	sd	ra,40(sp)
    80004986:	f022                	sd	s0,32(sp)
    80004988:	ec26                	sd	s1,24(sp)
    8000498a:	e84a                	sd	s2,16(sp)
    8000498c:	e44e                	sd	s3,8(sp)
    8000498e:	e052                	sd	s4,0(sp)
    80004990:	1800                	addi	s0,sp,48
    80004992:	84aa                	mv	s1,a0
    80004994:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004996:	0005b023          	sd	zero,0(a1)
    8000499a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000499e:	00000097          	auipc	ra,0x0
    800049a2:	bf8080e7          	jalr	-1032(ra) # 80004596 <filealloc>
    800049a6:	e088                	sd	a0,0(s1)
    800049a8:	c551                	beqz	a0,80004a34 <pipealloc+0xb2>
    800049aa:	00000097          	auipc	ra,0x0
    800049ae:	bec080e7          	jalr	-1044(ra) # 80004596 <filealloc>
    800049b2:	00aa3023          	sd	a0,0(s4)
    800049b6:	c92d                	beqz	a0,80004a28 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049b8:	ffffc097          	auipc	ra,0xffffc
    800049bc:	040080e7          	jalr	64(ra) # 800009f8 <kalloc>
    800049c0:	892a                	mv	s2,a0
    800049c2:	c125                	beqz	a0,80004a22 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049c4:	4985                	li	s3,1
    800049c6:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049ca:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049ce:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049d2:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049d6:	00004597          	auipc	a1,0x4
    800049da:	cfa58593          	addi	a1,a1,-774 # 800086d0 <syscalls+0x278>
    800049de:	ffffc097          	auipc	ra,0xffffc
    800049e2:	280080e7          	jalr	640(ra) # 80000c5e <initlock>
  (*f0)->type = FD_PIPE;
    800049e6:	609c                	ld	a5,0(s1)
    800049e8:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049ec:	609c                	ld	a5,0(s1)
    800049ee:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049f2:	609c                	ld	a5,0(s1)
    800049f4:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800049f8:	609c                	ld	a5,0(s1)
    800049fa:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800049fe:	000a3783          	ld	a5,0(s4)
    80004a02:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a06:	000a3783          	ld	a5,0(s4)
    80004a0a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a0e:	000a3783          	ld	a5,0(s4)
    80004a12:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a16:	000a3783          	ld	a5,0(s4)
    80004a1a:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a1e:	4501                	li	a0,0
    80004a20:	a025                	j	80004a48 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a22:	6088                	ld	a0,0(s1)
    80004a24:	e501                	bnez	a0,80004a2c <pipealloc+0xaa>
    80004a26:	a039                	j	80004a34 <pipealloc+0xb2>
    80004a28:	6088                	ld	a0,0(s1)
    80004a2a:	c51d                	beqz	a0,80004a58 <pipealloc+0xd6>
    fileclose(*f0);
    80004a2c:	00000097          	auipc	ra,0x0
    80004a30:	c26080e7          	jalr	-986(ra) # 80004652 <fileclose>
  if(*f1)
    80004a34:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a38:	557d                	li	a0,-1
  if(*f1)
    80004a3a:	c799                	beqz	a5,80004a48 <pipealloc+0xc6>
    fileclose(*f1);
    80004a3c:	853e                	mv	a0,a5
    80004a3e:	00000097          	auipc	ra,0x0
    80004a42:	c14080e7          	jalr	-1004(ra) # 80004652 <fileclose>
  return -1;
    80004a46:	557d                	li	a0,-1
}
    80004a48:	70a2                	ld	ra,40(sp)
    80004a4a:	7402                	ld	s0,32(sp)
    80004a4c:	64e2                	ld	s1,24(sp)
    80004a4e:	6942                	ld	s2,16(sp)
    80004a50:	69a2                	ld	s3,8(sp)
    80004a52:	6a02                	ld	s4,0(sp)
    80004a54:	6145                	addi	sp,sp,48
    80004a56:	8082                	ret
  return -1;
    80004a58:	557d                	li	a0,-1
    80004a5a:	b7fd                	j	80004a48 <pipealloc+0xc6>

0000000080004a5c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a5c:	1101                	addi	sp,sp,-32
    80004a5e:	ec06                	sd	ra,24(sp)
    80004a60:	e822                	sd	s0,16(sp)
    80004a62:	e426                	sd	s1,8(sp)
    80004a64:	e04a                	sd	s2,0(sp)
    80004a66:	1000                	addi	s0,sp,32
    80004a68:	84aa                	mv	s1,a0
    80004a6a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a6c:	ffffc097          	auipc	ra,0xffffc
    80004a70:	282080e7          	jalr	642(ra) # 80000cee <acquire>
  if(writable){
    80004a74:	02090d63          	beqz	s2,80004aae <pipeclose+0x52>
    pi->writeopen = 0;
    80004a78:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a7c:	21848513          	addi	a0,s1,536
    80004a80:	ffffe097          	auipc	ra,0xffffe
    80004a84:	88c080e7          	jalr	-1908(ra) # 8000230c <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a88:	2204b783          	ld	a5,544(s1)
    80004a8c:	eb95                	bnez	a5,80004ac0 <pipeclose+0x64>
    release(&pi->lock);
    80004a8e:	8526                	mv	a0,s1
    80004a90:	ffffc097          	auipc	ra,0xffffc
    80004a94:	312080e7          	jalr	786(ra) # 80000da2 <release>
    kfree((char*)pi);
    80004a98:	8526                	mv	a0,s1
    80004a9a:	ffffc097          	auipc	ra,0xffffc
    80004a9e:	072080e7          	jalr	114(ra) # 80000b0c <kfree>
  } else
    release(&pi->lock);
}
    80004aa2:	60e2                	ld	ra,24(sp)
    80004aa4:	6442                	ld	s0,16(sp)
    80004aa6:	64a2                	ld	s1,8(sp)
    80004aa8:	6902                	ld	s2,0(sp)
    80004aaa:	6105                	addi	sp,sp,32
    80004aac:	8082                	ret
    pi->readopen = 0;
    80004aae:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004ab2:	21c48513          	addi	a0,s1,540
    80004ab6:	ffffe097          	auipc	ra,0xffffe
    80004aba:	856080e7          	jalr	-1962(ra) # 8000230c <wakeup>
    80004abe:	b7e9                	j	80004a88 <pipeclose+0x2c>
    release(&pi->lock);
    80004ac0:	8526                	mv	a0,s1
    80004ac2:	ffffc097          	auipc	ra,0xffffc
    80004ac6:	2e0080e7          	jalr	736(ra) # 80000da2 <release>
}
    80004aca:	bfe1                	j	80004aa2 <pipeclose+0x46>

0000000080004acc <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004acc:	7159                	addi	sp,sp,-112
    80004ace:	f486                	sd	ra,104(sp)
    80004ad0:	f0a2                	sd	s0,96(sp)
    80004ad2:	eca6                	sd	s1,88(sp)
    80004ad4:	e8ca                	sd	s2,80(sp)
    80004ad6:	e4ce                	sd	s3,72(sp)
    80004ad8:	e0d2                	sd	s4,64(sp)
    80004ada:	fc56                	sd	s5,56(sp)
    80004adc:	f85a                	sd	s6,48(sp)
    80004ade:	f45e                	sd	s7,40(sp)
    80004ae0:	f062                	sd	s8,32(sp)
    80004ae2:	ec66                	sd	s9,24(sp)
    80004ae4:	1880                	addi	s0,sp,112
    80004ae6:	84aa                	mv	s1,a0
    80004ae8:	8aae                	mv	s5,a1
    80004aea:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004aec:	ffffd097          	auipc	ra,0xffffd
    80004af0:	fd8080e7          	jalr	-40(ra) # 80001ac4 <myproc>
    80004af4:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004af6:	8526                	mv	a0,s1
    80004af8:	ffffc097          	auipc	ra,0xffffc
    80004afc:	1f6080e7          	jalr	502(ra) # 80000cee <acquire>
  while(i < n){
    80004b00:	0d405163          	blez	s4,80004bc2 <pipewrite+0xf6>
    80004b04:	8ba6                	mv	s7,s1
  int i = 0;
    80004b06:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b08:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b0a:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b0e:	21c48c13          	addi	s8,s1,540
    80004b12:	a08d                	j	80004b74 <pipewrite+0xa8>
      release(&pi->lock);
    80004b14:	8526                	mv	a0,s1
    80004b16:	ffffc097          	auipc	ra,0xffffc
    80004b1a:	28c080e7          	jalr	652(ra) # 80000da2 <release>
      return -1;
    80004b1e:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b20:	854a                	mv	a0,s2
    80004b22:	70a6                	ld	ra,104(sp)
    80004b24:	7406                	ld	s0,96(sp)
    80004b26:	64e6                	ld	s1,88(sp)
    80004b28:	6946                	ld	s2,80(sp)
    80004b2a:	69a6                	ld	s3,72(sp)
    80004b2c:	6a06                	ld	s4,64(sp)
    80004b2e:	7ae2                	ld	s5,56(sp)
    80004b30:	7b42                	ld	s6,48(sp)
    80004b32:	7ba2                	ld	s7,40(sp)
    80004b34:	7c02                	ld	s8,32(sp)
    80004b36:	6ce2                	ld	s9,24(sp)
    80004b38:	6165                	addi	sp,sp,112
    80004b3a:	8082                	ret
      wakeup(&pi->nread);
    80004b3c:	8566                	mv	a0,s9
    80004b3e:	ffffd097          	auipc	ra,0xffffd
    80004b42:	7ce080e7          	jalr	1998(ra) # 8000230c <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b46:	85de                	mv	a1,s7
    80004b48:	8562                	mv	a0,s8
    80004b4a:	ffffd097          	auipc	ra,0xffffd
    80004b4e:	636080e7          	jalr	1590(ra) # 80002180 <sleep>
    80004b52:	a839                	j	80004b70 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b54:	21c4a783          	lw	a5,540(s1)
    80004b58:	0017871b          	addiw	a4,a5,1
    80004b5c:	20e4ae23          	sw	a4,540(s1)
    80004b60:	1ff7f793          	andi	a5,a5,511
    80004b64:	97a6                	add	a5,a5,s1
    80004b66:	f9f44703          	lbu	a4,-97(s0)
    80004b6a:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b6e:	2905                	addiw	s2,s2,1
  while(i < n){
    80004b70:	03495d63          	bge	s2,s4,80004baa <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004b74:	2204a783          	lw	a5,544(s1)
    80004b78:	dfd1                	beqz	a5,80004b14 <pipewrite+0x48>
    80004b7a:	0289a783          	lw	a5,40(s3)
    80004b7e:	fbd9                	bnez	a5,80004b14 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b80:	2184a783          	lw	a5,536(s1)
    80004b84:	21c4a703          	lw	a4,540(s1)
    80004b88:	2007879b          	addiw	a5,a5,512
    80004b8c:	faf708e3          	beq	a4,a5,80004b3c <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b90:	4685                	li	a3,1
    80004b92:	01590633          	add	a2,s2,s5
    80004b96:	f9f40593          	addi	a1,s0,-97
    80004b9a:	0509b503          	ld	a0,80(s3)
    80004b9e:	ffffd097          	auipc	ra,0xffffd
    80004ba2:	c74080e7          	jalr	-908(ra) # 80001812 <copyin>
    80004ba6:	fb6517e3          	bne	a0,s6,80004b54 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004baa:	21848513          	addi	a0,s1,536
    80004bae:	ffffd097          	auipc	ra,0xffffd
    80004bb2:	75e080e7          	jalr	1886(ra) # 8000230c <wakeup>
  release(&pi->lock);
    80004bb6:	8526                	mv	a0,s1
    80004bb8:	ffffc097          	auipc	ra,0xffffc
    80004bbc:	1ea080e7          	jalr	490(ra) # 80000da2 <release>
  return i;
    80004bc0:	b785                	j	80004b20 <pipewrite+0x54>
  int i = 0;
    80004bc2:	4901                	li	s2,0
    80004bc4:	b7dd                	j	80004baa <pipewrite+0xde>

0000000080004bc6 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004bc6:	715d                	addi	sp,sp,-80
    80004bc8:	e486                	sd	ra,72(sp)
    80004bca:	e0a2                	sd	s0,64(sp)
    80004bcc:	fc26                	sd	s1,56(sp)
    80004bce:	f84a                	sd	s2,48(sp)
    80004bd0:	f44e                	sd	s3,40(sp)
    80004bd2:	f052                	sd	s4,32(sp)
    80004bd4:	ec56                	sd	s5,24(sp)
    80004bd6:	e85a                	sd	s6,16(sp)
    80004bd8:	0880                	addi	s0,sp,80
    80004bda:	84aa                	mv	s1,a0
    80004bdc:	892e                	mv	s2,a1
    80004bde:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004be0:	ffffd097          	auipc	ra,0xffffd
    80004be4:	ee4080e7          	jalr	-284(ra) # 80001ac4 <myproc>
    80004be8:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004bea:	8b26                	mv	s6,s1
    80004bec:	8526                	mv	a0,s1
    80004bee:	ffffc097          	auipc	ra,0xffffc
    80004bf2:	100080e7          	jalr	256(ra) # 80000cee <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bf6:	2184a703          	lw	a4,536(s1)
    80004bfa:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bfe:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c02:	02f71463          	bne	a4,a5,80004c2a <piperead+0x64>
    80004c06:	2244a783          	lw	a5,548(s1)
    80004c0a:	c385                	beqz	a5,80004c2a <piperead+0x64>
    if(pr->killed){
    80004c0c:	028a2783          	lw	a5,40(s4)
    80004c10:	ebc1                	bnez	a5,80004ca0 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c12:	85da                	mv	a1,s6
    80004c14:	854e                	mv	a0,s3
    80004c16:	ffffd097          	auipc	ra,0xffffd
    80004c1a:	56a080e7          	jalr	1386(ra) # 80002180 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c1e:	2184a703          	lw	a4,536(s1)
    80004c22:	21c4a783          	lw	a5,540(s1)
    80004c26:	fef700e3          	beq	a4,a5,80004c06 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c2a:	09505263          	blez	s5,80004cae <piperead+0xe8>
    80004c2e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c30:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004c32:	2184a783          	lw	a5,536(s1)
    80004c36:	21c4a703          	lw	a4,540(s1)
    80004c3a:	02f70d63          	beq	a4,a5,80004c74 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c3e:	0017871b          	addiw	a4,a5,1
    80004c42:	20e4ac23          	sw	a4,536(s1)
    80004c46:	1ff7f793          	andi	a5,a5,511
    80004c4a:	97a6                	add	a5,a5,s1
    80004c4c:	0187c783          	lbu	a5,24(a5)
    80004c50:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c54:	4685                	li	a3,1
    80004c56:	fbf40613          	addi	a2,s0,-65
    80004c5a:	85ca                	mv	a1,s2
    80004c5c:	050a3503          	ld	a0,80(s4)
    80004c60:	ffffd097          	auipc	ra,0xffffd
    80004c64:	b12080e7          	jalr	-1262(ra) # 80001772 <copyout>
    80004c68:	01650663          	beq	a0,s6,80004c74 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c6c:	2985                	addiw	s3,s3,1
    80004c6e:	0905                	addi	s2,s2,1
    80004c70:	fd3a91e3          	bne	s5,s3,80004c32 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c74:	21c48513          	addi	a0,s1,540
    80004c78:	ffffd097          	auipc	ra,0xffffd
    80004c7c:	694080e7          	jalr	1684(ra) # 8000230c <wakeup>
  release(&pi->lock);
    80004c80:	8526                	mv	a0,s1
    80004c82:	ffffc097          	auipc	ra,0xffffc
    80004c86:	120080e7          	jalr	288(ra) # 80000da2 <release>
  return i;
}
    80004c8a:	854e                	mv	a0,s3
    80004c8c:	60a6                	ld	ra,72(sp)
    80004c8e:	6406                	ld	s0,64(sp)
    80004c90:	74e2                	ld	s1,56(sp)
    80004c92:	7942                	ld	s2,48(sp)
    80004c94:	79a2                	ld	s3,40(sp)
    80004c96:	7a02                	ld	s4,32(sp)
    80004c98:	6ae2                	ld	s5,24(sp)
    80004c9a:	6b42                	ld	s6,16(sp)
    80004c9c:	6161                	addi	sp,sp,80
    80004c9e:	8082                	ret
      release(&pi->lock);
    80004ca0:	8526                	mv	a0,s1
    80004ca2:	ffffc097          	auipc	ra,0xffffc
    80004ca6:	100080e7          	jalr	256(ra) # 80000da2 <release>
      return -1;
    80004caa:	59fd                	li	s3,-1
    80004cac:	bff9                	j	80004c8a <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cae:	4981                	li	s3,0
    80004cb0:	b7d1                	j	80004c74 <piperead+0xae>

0000000080004cb2 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004cb2:	df010113          	addi	sp,sp,-528
    80004cb6:	20113423          	sd	ra,520(sp)
    80004cba:	20813023          	sd	s0,512(sp)
    80004cbe:	ffa6                	sd	s1,504(sp)
    80004cc0:	fbca                	sd	s2,496(sp)
    80004cc2:	f7ce                	sd	s3,488(sp)
    80004cc4:	f3d2                	sd	s4,480(sp)
    80004cc6:	efd6                	sd	s5,472(sp)
    80004cc8:	ebda                	sd	s6,464(sp)
    80004cca:	e7de                	sd	s7,456(sp)
    80004ccc:	e3e2                	sd	s8,448(sp)
    80004cce:	ff66                	sd	s9,440(sp)
    80004cd0:	fb6a                	sd	s10,432(sp)
    80004cd2:	f76e                	sd	s11,424(sp)
    80004cd4:	0c00                	addi	s0,sp,528
    80004cd6:	84aa                	mv	s1,a0
    80004cd8:	dea43c23          	sd	a0,-520(s0)
    80004cdc:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004ce0:	ffffd097          	auipc	ra,0xffffd
    80004ce4:	de4080e7          	jalr	-540(ra) # 80001ac4 <myproc>
    80004ce8:	892a                	mv	s2,a0

  begin_op();
    80004cea:	fffff097          	auipc	ra,0xfffff
    80004cee:	49c080e7          	jalr	1180(ra) # 80004186 <begin_op>

  if((ip = namei(path)) == 0){
    80004cf2:	8526                	mv	a0,s1
    80004cf4:	fffff097          	auipc	ra,0xfffff
    80004cf8:	276080e7          	jalr	630(ra) # 80003f6a <namei>
    80004cfc:	c92d                	beqz	a0,80004d6e <exec+0xbc>
    80004cfe:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d00:	fffff097          	auipc	ra,0xfffff
    80004d04:	ab4080e7          	jalr	-1356(ra) # 800037b4 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d08:	04000713          	li	a4,64
    80004d0c:	4681                	li	a3,0
    80004d0e:	e5040613          	addi	a2,s0,-432
    80004d12:	4581                	li	a1,0
    80004d14:	8526                	mv	a0,s1
    80004d16:	fffff097          	auipc	ra,0xfffff
    80004d1a:	d52080e7          	jalr	-686(ra) # 80003a68 <readi>
    80004d1e:	04000793          	li	a5,64
    80004d22:	00f51a63          	bne	a0,a5,80004d36 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d26:	e5042703          	lw	a4,-432(s0)
    80004d2a:	464c47b7          	lui	a5,0x464c4
    80004d2e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d32:	04f70463          	beq	a4,a5,80004d7a <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d36:	8526                	mv	a0,s1
    80004d38:	fffff097          	auipc	ra,0xfffff
    80004d3c:	cde080e7          	jalr	-802(ra) # 80003a16 <iunlockput>
    end_op();
    80004d40:	fffff097          	auipc	ra,0xfffff
    80004d44:	4c6080e7          	jalr	1222(ra) # 80004206 <end_op>
  }
  return -1;
    80004d48:	557d                	li	a0,-1
}
    80004d4a:	20813083          	ld	ra,520(sp)
    80004d4e:	20013403          	ld	s0,512(sp)
    80004d52:	74fe                	ld	s1,504(sp)
    80004d54:	795e                	ld	s2,496(sp)
    80004d56:	79be                	ld	s3,488(sp)
    80004d58:	7a1e                	ld	s4,480(sp)
    80004d5a:	6afe                	ld	s5,472(sp)
    80004d5c:	6b5e                	ld	s6,464(sp)
    80004d5e:	6bbe                	ld	s7,456(sp)
    80004d60:	6c1e                	ld	s8,448(sp)
    80004d62:	7cfa                	ld	s9,440(sp)
    80004d64:	7d5a                	ld	s10,432(sp)
    80004d66:	7dba                	ld	s11,424(sp)
    80004d68:	21010113          	addi	sp,sp,528
    80004d6c:	8082                	ret
    end_op();
    80004d6e:	fffff097          	auipc	ra,0xfffff
    80004d72:	498080e7          	jalr	1176(ra) # 80004206 <end_op>
    return -1;
    80004d76:	557d                	li	a0,-1
    80004d78:	bfc9                	j	80004d4a <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d7a:	854a                	mv	a0,s2
    80004d7c:	ffffd097          	auipc	ra,0xffffd
    80004d80:	e0c080e7          	jalr	-500(ra) # 80001b88 <proc_pagetable>
    80004d84:	8baa                	mv	s7,a0
    80004d86:	d945                	beqz	a0,80004d36 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d88:	e7042983          	lw	s3,-400(s0)
    80004d8c:	e8845783          	lhu	a5,-376(s0)
    80004d90:	c7ad                	beqz	a5,80004dfa <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d92:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d94:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004d96:	6c85                	lui	s9,0x1
    80004d98:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004d9c:	def43823          	sd	a5,-528(s0)
    80004da0:	a42d                	j	80004fca <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004da2:	00004517          	auipc	a0,0x4
    80004da6:	93650513          	addi	a0,a0,-1738 # 800086d8 <syscalls+0x280>
    80004daa:	ffffb097          	auipc	ra,0xffffb
    80004dae:	794080e7          	jalr	1940(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004db2:	8756                	mv	a4,s5
    80004db4:	012d86bb          	addw	a3,s11,s2
    80004db8:	4581                	li	a1,0
    80004dba:	8526                	mv	a0,s1
    80004dbc:	fffff097          	auipc	ra,0xfffff
    80004dc0:	cac080e7          	jalr	-852(ra) # 80003a68 <readi>
    80004dc4:	2501                	sext.w	a0,a0
    80004dc6:	1aaa9963          	bne	s5,a0,80004f78 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004dca:	6785                	lui	a5,0x1
    80004dcc:	0127893b          	addw	s2,a5,s2
    80004dd0:	77fd                	lui	a5,0xfffff
    80004dd2:	01478a3b          	addw	s4,a5,s4
    80004dd6:	1f897163          	bgeu	s2,s8,80004fb8 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004dda:	02091593          	slli	a1,s2,0x20
    80004dde:	9181                	srli	a1,a1,0x20
    80004de0:	95ea                	add	a1,a1,s10
    80004de2:	855e                	mv	a0,s7
    80004de4:	ffffc097          	auipc	ra,0xffffc
    80004de8:	394080e7          	jalr	916(ra) # 80001178 <walkaddr>
    80004dec:	862a                	mv	a2,a0
    if(pa == 0)
    80004dee:	d955                	beqz	a0,80004da2 <exec+0xf0>
      n = PGSIZE;
    80004df0:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004df2:	fd9a70e3          	bgeu	s4,s9,80004db2 <exec+0x100>
      n = sz - i;
    80004df6:	8ad2                	mv	s5,s4
    80004df8:	bf6d                	j	80004db2 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004dfa:	4901                	li	s2,0
  iunlockput(ip);
    80004dfc:	8526                	mv	a0,s1
    80004dfe:	fffff097          	auipc	ra,0xfffff
    80004e02:	c18080e7          	jalr	-1000(ra) # 80003a16 <iunlockput>
  end_op();
    80004e06:	fffff097          	auipc	ra,0xfffff
    80004e0a:	400080e7          	jalr	1024(ra) # 80004206 <end_op>
  p = myproc();
    80004e0e:	ffffd097          	auipc	ra,0xffffd
    80004e12:	cb6080e7          	jalr	-842(ra) # 80001ac4 <myproc>
    80004e16:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e18:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e1c:	6785                	lui	a5,0x1
    80004e1e:	17fd                	addi	a5,a5,-1
    80004e20:	993e                	add	s2,s2,a5
    80004e22:	757d                	lui	a0,0xfffff
    80004e24:	00a977b3          	and	a5,s2,a0
    80004e28:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e2c:	6609                	lui	a2,0x2
    80004e2e:	963e                	add	a2,a2,a5
    80004e30:	85be                	mv	a1,a5
    80004e32:	855e                	mv	a0,s7
    80004e34:	ffffc097          	auipc	ra,0xffffc
    80004e38:	6f8080e7          	jalr	1784(ra) # 8000152c <uvmalloc>
    80004e3c:	8b2a                	mv	s6,a0
  ip = 0;
    80004e3e:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e40:	12050c63          	beqz	a0,80004f78 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e44:	75f9                	lui	a1,0xffffe
    80004e46:	95aa                	add	a1,a1,a0
    80004e48:	855e                	mv	a0,s7
    80004e4a:	ffffd097          	auipc	ra,0xffffd
    80004e4e:	8f6080e7          	jalr	-1802(ra) # 80001740 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e52:	7c7d                	lui	s8,0xfffff
    80004e54:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e56:	e0043783          	ld	a5,-512(s0)
    80004e5a:	6388                	ld	a0,0(a5)
    80004e5c:	c535                	beqz	a0,80004ec8 <exec+0x216>
    80004e5e:	e9040993          	addi	s3,s0,-368
    80004e62:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004e66:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004e68:	ffffc097          	auipc	ra,0xffffc
    80004e6c:	106080e7          	jalr	262(ra) # 80000f6e <strlen>
    80004e70:	2505                	addiw	a0,a0,1
    80004e72:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e76:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e7a:	13896363          	bltu	s2,s8,80004fa0 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e7e:	e0043d83          	ld	s11,-512(s0)
    80004e82:	000dba03          	ld	s4,0(s11)
    80004e86:	8552                	mv	a0,s4
    80004e88:	ffffc097          	auipc	ra,0xffffc
    80004e8c:	0e6080e7          	jalr	230(ra) # 80000f6e <strlen>
    80004e90:	0015069b          	addiw	a3,a0,1
    80004e94:	8652                	mv	a2,s4
    80004e96:	85ca                	mv	a1,s2
    80004e98:	855e                	mv	a0,s7
    80004e9a:	ffffd097          	auipc	ra,0xffffd
    80004e9e:	8d8080e7          	jalr	-1832(ra) # 80001772 <copyout>
    80004ea2:	10054363          	bltz	a0,80004fa8 <exec+0x2f6>
    ustack[argc] = sp;
    80004ea6:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004eaa:	0485                	addi	s1,s1,1
    80004eac:	008d8793          	addi	a5,s11,8
    80004eb0:	e0f43023          	sd	a5,-512(s0)
    80004eb4:	008db503          	ld	a0,8(s11)
    80004eb8:	c911                	beqz	a0,80004ecc <exec+0x21a>
    if(argc >= MAXARG)
    80004eba:	09a1                	addi	s3,s3,8
    80004ebc:	fb3c96e3          	bne	s9,s3,80004e68 <exec+0x1b6>
  sz = sz1;
    80004ec0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ec4:	4481                	li	s1,0
    80004ec6:	a84d                	j	80004f78 <exec+0x2c6>
  sp = sz;
    80004ec8:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004eca:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ecc:	00349793          	slli	a5,s1,0x3
    80004ed0:	f9040713          	addi	a4,s0,-112
    80004ed4:	97ba                	add	a5,a5,a4
    80004ed6:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004eda:	00148693          	addi	a3,s1,1
    80004ede:	068e                	slli	a3,a3,0x3
    80004ee0:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004ee4:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004ee8:	01897663          	bgeu	s2,s8,80004ef4 <exec+0x242>
  sz = sz1;
    80004eec:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ef0:	4481                	li	s1,0
    80004ef2:	a059                	j	80004f78 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004ef4:	e9040613          	addi	a2,s0,-368
    80004ef8:	85ca                	mv	a1,s2
    80004efa:	855e                	mv	a0,s7
    80004efc:	ffffd097          	auipc	ra,0xffffd
    80004f00:	876080e7          	jalr	-1930(ra) # 80001772 <copyout>
    80004f04:	0a054663          	bltz	a0,80004fb0 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004f08:	058ab783          	ld	a5,88(s5)
    80004f0c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f10:	df843783          	ld	a5,-520(s0)
    80004f14:	0007c703          	lbu	a4,0(a5)
    80004f18:	cf11                	beqz	a4,80004f34 <exec+0x282>
    80004f1a:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f1c:	02f00693          	li	a3,47
    80004f20:	a039                	j	80004f2e <exec+0x27c>
      last = s+1;
    80004f22:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004f26:	0785                	addi	a5,a5,1
    80004f28:	fff7c703          	lbu	a4,-1(a5)
    80004f2c:	c701                	beqz	a4,80004f34 <exec+0x282>
    if(*s == '/')
    80004f2e:	fed71ce3          	bne	a4,a3,80004f26 <exec+0x274>
    80004f32:	bfc5                	j	80004f22 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f34:	4641                	li	a2,16
    80004f36:	df843583          	ld	a1,-520(s0)
    80004f3a:	158a8513          	addi	a0,s5,344
    80004f3e:	ffffc097          	auipc	ra,0xffffc
    80004f42:	ffe080e7          	jalr	-2(ra) # 80000f3c <safestrcpy>
  oldpagetable = p->pagetable;
    80004f46:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f4a:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004f4e:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f52:	058ab783          	ld	a5,88(s5)
    80004f56:	e6843703          	ld	a4,-408(s0)
    80004f5a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f5c:	058ab783          	ld	a5,88(s5)
    80004f60:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f64:	85ea                	mv	a1,s10
    80004f66:	ffffd097          	auipc	ra,0xffffd
    80004f6a:	cbe080e7          	jalr	-834(ra) # 80001c24 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f6e:	0004851b          	sext.w	a0,s1
    80004f72:	bbe1                	j	80004d4a <exec+0x98>
    80004f74:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004f78:	e0843583          	ld	a1,-504(s0)
    80004f7c:	855e                	mv	a0,s7
    80004f7e:	ffffd097          	auipc	ra,0xffffd
    80004f82:	ca6080e7          	jalr	-858(ra) # 80001c24 <proc_freepagetable>
  if(ip){
    80004f86:	da0498e3          	bnez	s1,80004d36 <exec+0x84>
  return -1;
    80004f8a:	557d                	li	a0,-1
    80004f8c:	bb7d                	j	80004d4a <exec+0x98>
    80004f8e:	e1243423          	sd	s2,-504(s0)
    80004f92:	b7dd                	j	80004f78 <exec+0x2c6>
    80004f94:	e1243423          	sd	s2,-504(s0)
    80004f98:	b7c5                	j	80004f78 <exec+0x2c6>
    80004f9a:	e1243423          	sd	s2,-504(s0)
    80004f9e:	bfe9                	j	80004f78 <exec+0x2c6>
  sz = sz1;
    80004fa0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fa4:	4481                	li	s1,0
    80004fa6:	bfc9                	j	80004f78 <exec+0x2c6>
  sz = sz1;
    80004fa8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fac:	4481                	li	s1,0
    80004fae:	b7e9                	j	80004f78 <exec+0x2c6>
  sz = sz1;
    80004fb0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fb4:	4481                	li	s1,0
    80004fb6:	b7c9                	j	80004f78 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004fb8:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fbc:	2b05                	addiw	s6,s6,1
    80004fbe:	0389899b          	addiw	s3,s3,56
    80004fc2:	e8845783          	lhu	a5,-376(s0)
    80004fc6:	e2fb5be3          	bge	s6,a5,80004dfc <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004fca:	2981                	sext.w	s3,s3
    80004fcc:	03800713          	li	a4,56
    80004fd0:	86ce                	mv	a3,s3
    80004fd2:	e1840613          	addi	a2,s0,-488
    80004fd6:	4581                	li	a1,0
    80004fd8:	8526                	mv	a0,s1
    80004fda:	fffff097          	auipc	ra,0xfffff
    80004fde:	a8e080e7          	jalr	-1394(ra) # 80003a68 <readi>
    80004fe2:	03800793          	li	a5,56
    80004fe6:	f8f517e3          	bne	a0,a5,80004f74 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004fea:	e1842783          	lw	a5,-488(s0)
    80004fee:	4705                	li	a4,1
    80004ff0:	fce796e3          	bne	a5,a4,80004fbc <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004ff4:	e4043603          	ld	a2,-448(s0)
    80004ff8:	e3843783          	ld	a5,-456(s0)
    80004ffc:	f8f669e3          	bltu	a2,a5,80004f8e <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005000:	e2843783          	ld	a5,-472(s0)
    80005004:	963e                	add	a2,a2,a5
    80005006:	f8f667e3          	bltu	a2,a5,80004f94 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000500a:	85ca                	mv	a1,s2
    8000500c:	855e                	mv	a0,s7
    8000500e:	ffffc097          	auipc	ra,0xffffc
    80005012:	51e080e7          	jalr	1310(ra) # 8000152c <uvmalloc>
    80005016:	e0a43423          	sd	a0,-504(s0)
    8000501a:	d141                	beqz	a0,80004f9a <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    8000501c:	e2843d03          	ld	s10,-472(s0)
    80005020:	df043783          	ld	a5,-528(s0)
    80005024:	00fd77b3          	and	a5,s10,a5
    80005028:	fba1                	bnez	a5,80004f78 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000502a:	e2042d83          	lw	s11,-480(s0)
    8000502e:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005032:	f80c03e3          	beqz	s8,80004fb8 <exec+0x306>
    80005036:	8a62                	mv	s4,s8
    80005038:	4901                	li	s2,0
    8000503a:	b345                	j	80004dda <exec+0x128>

000000008000503c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000503c:	7179                	addi	sp,sp,-48
    8000503e:	f406                	sd	ra,40(sp)
    80005040:	f022                	sd	s0,32(sp)
    80005042:	ec26                	sd	s1,24(sp)
    80005044:	e84a                	sd	s2,16(sp)
    80005046:	1800                	addi	s0,sp,48
    80005048:	892e                	mv	s2,a1
    8000504a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000504c:	fdc40593          	addi	a1,s0,-36
    80005050:	ffffe097          	auipc	ra,0xffffe
    80005054:	bf2080e7          	jalr	-1038(ra) # 80002c42 <argint>
    80005058:	04054063          	bltz	a0,80005098 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000505c:	fdc42703          	lw	a4,-36(s0)
    80005060:	47bd                	li	a5,15
    80005062:	02e7ed63          	bltu	a5,a4,8000509c <argfd+0x60>
    80005066:	ffffd097          	auipc	ra,0xffffd
    8000506a:	a5e080e7          	jalr	-1442(ra) # 80001ac4 <myproc>
    8000506e:	fdc42703          	lw	a4,-36(s0)
    80005072:	01a70793          	addi	a5,a4,26
    80005076:	078e                	slli	a5,a5,0x3
    80005078:	953e                	add	a0,a0,a5
    8000507a:	611c                	ld	a5,0(a0)
    8000507c:	c395                	beqz	a5,800050a0 <argfd+0x64>
    return -1;
  if(pfd)
    8000507e:	00090463          	beqz	s2,80005086 <argfd+0x4a>
    *pfd = fd;
    80005082:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005086:	4501                	li	a0,0
  if(pf)
    80005088:	c091                	beqz	s1,8000508c <argfd+0x50>
    *pf = f;
    8000508a:	e09c                	sd	a5,0(s1)
}
    8000508c:	70a2                	ld	ra,40(sp)
    8000508e:	7402                	ld	s0,32(sp)
    80005090:	64e2                	ld	s1,24(sp)
    80005092:	6942                	ld	s2,16(sp)
    80005094:	6145                	addi	sp,sp,48
    80005096:	8082                	ret
    return -1;
    80005098:	557d                	li	a0,-1
    8000509a:	bfcd                	j	8000508c <argfd+0x50>
    return -1;
    8000509c:	557d                	li	a0,-1
    8000509e:	b7fd                	j	8000508c <argfd+0x50>
    800050a0:	557d                	li	a0,-1
    800050a2:	b7ed                	j	8000508c <argfd+0x50>

00000000800050a4 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050a4:	1101                	addi	sp,sp,-32
    800050a6:	ec06                	sd	ra,24(sp)
    800050a8:	e822                	sd	s0,16(sp)
    800050aa:	e426                	sd	s1,8(sp)
    800050ac:	1000                	addi	s0,sp,32
    800050ae:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050b0:	ffffd097          	auipc	ra,0xffffd
    800050b4:	a14080e7          	jalr	-1516(ra) # 80001ac4 <myproc>
    800050b8:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050ba:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffb90d0>
    800050be:	4501                	li	a0,0
    800050c0:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050c2:	6398                	ld	a4,0(a5)
    800050c4:	cb19                	beqz	a4,800050da <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050c6:	2505                	addiw	a0,a0,1
    800050c8:	07a1                	addi	a5,a5,8
    800050ca:	fed51ce3          	bne	a0,a3,800050c2 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050ce:	557d                	li	a0,-1
}
    800050d0:	60e2                	ld	ra,24(sp)
    800050d2:	6442                	ld	s0,16(sp)
    800050d4:	64a2                	ld	s1,8(sp)
    800050d6:	6105                	addi	sp,sp,32
    800050d8:	8082                	ret
      p->ofile[fd] = f;
    800050da:	01a50793          	addi	a5,a0,26
    800050de:	078e                	slli	a5,a5,0x3
    800050e0:	963e                	add	a2,a2,a5
    800050e2:	e204                	sd	s1,0(a2)
      return fd;
    800050e4:	b7f5                	j	800050d0 <fdalloc+0x2c>

00000000800050e6 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050e6:	715d                	addi	sp,sp,-80
    800050e8:	e486                	sd	ra,72(sp)
    800050ea:	e0a2                	sd	s0,64(sp)
    800050ec:	fc26                	sd	s1,56(sp)
    800050ee:	f84a                	sd	s2,48(sp)
    800050f0:	f44e                	sd	s3,40(sp)
    800050f2:	f052                	sd	s4,32(sp)
    800050f4:	ec56                	sd	s5,24(sp)
    800050f6:	0880                	addi	s0,sp,80
    800050f8:	89ae                	mv	s3,a1
    800050fa:	8ab2                	mv	s5,a2
    800050fc:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800050fe:	fb040593          	addi	a1,s0,-80
    80005102:	fffff097          	auipc	ra,0xfffff
    80005106:	e86080e7          	jalr	-378(ra) # 80003f88 <nameiparent>
    8000510a:	892a                	mv	s2,a0
    8000510c:	12050f63          	beqz	a0,8000524a <create+0x164>
    return 0;

  ilock(dp);
    80005110:	ffffe097          	auipc	ra,0xffffe
    80005114:	6a4080e7          	jalr	1700(ra) # 800037b4 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005118:	4601                	li	a2,0
    8000511a:	fb040593          	addi	a1,s0,-80
    8000511e:	854a                	mv	a0,s2
    80005120:	fffff097          	auipc	ra,0xfffff
    80005124:	b78080e7          	jalr	-1160(ra) # 80003c98 <dirlookup>
    80005128:	84aa                	mv	s1,a0
    8000512a:	c921                	beqz	a0,8000517a <create+0x94>
    iunlockput(dp);
    8000512c:	854a                	mv	a0,s2
    8000512e:	fffff097          	auipc	ra,0xfffff
    80005132:	8e8080e7          	jalr	-1816(ra) # 80003a16 <iunlockput>
    ilock(ip);
    80005136:	8526                	mv	a0,s1
    80005138:	ffffe097          	auipc	ra,0xffffe
    8000513c:	67c080e7          	jalr	1660(ra) # 800037b4 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005140:	2981                	sext.w	s3,s3
    80005142:	4789                	li	a5,2
    80005144:	02f99463          	bne	s3,a5,8000516c <create+0x86>
    80005148:	0444d783          	lhu	a5,68(s1)
    8000514c:	37f9                	addiw	a5,a5,-2
    8000514e:	17c2                	slli	a5,a5,0x30
    80005150:	93c1                	srli	a5,a5,0x30
    80005152:	4705                	li	a4,1
    80005154:	00f76c63          	bltu	a4,a5,8000516c <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005158:	8526                	mv	a0,s1
    8000515a:	60a6                	ld	ra,72(sp)
    8000515c:	6406                	ld	s0,64(sp)
    8000515e:	74e2                	ld	s1,56(sp)
    80005160:	7942                	ld	s2,48(sp)
    80005162:	79a2                	ld	s3,40(sp)
    80005164:	7a02                	ld	s4,32(sp)
    80005166:	6ae2                	ld	s5,24(sp)
    80005168:	6161                	addi	sp,sp,80
    8000516a:	8082                	ret
    iunlockput(ip);
    8000516c:	8526                	mv	a0,s1
    8000516e:	fffff097          	auipc	ra,0xfffff
    80005172:	8a8080e7          	jalr	-1880(ra) # 80003a16 <iunlockput>
    return 0;
    80005176:	4481                	li	s1,0
    80005178:	b7c5                	j	80005158 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000517a:	85ce                	mv	a1,s3
    8000517c:	00092503          	lw	a0,0(s2)
    80005180:	ffffe097          	auipc	ra,0xffffe
    80005184:	49c080e7          	jalr	1180(ra) # 8000361c <ialloc>
    80005188:	84aa                	mv	s1,a0
    8000518a:	c529                	beqz	a0,800051d4 <create+0xee>
  ilock(ip);
    8000518c:	ffffe097          	auipc	ra,0xffffe
    80005190:	628080e7          	jalr	1576(ra) # 800037b4 <ilock>
  ip->major = major;
    80005194:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005198:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000519c:	4785                	li	a5,1
    8000519e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800051a2:	8526                	mv	a0,s1
    800051a4:	ffffe097          	auipc	ra,0xffffe
    800051a8:	546080e7          	jalr	1350(ra) # 800036ea <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051ac:	2981                	sext.w	s3,s3
    800051ae:	4785                	li	a5,1
    800051b0:	02f98a63          	beq	s3,a5,800051e4 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800051b4:	40d0                	lw	a2,4(s1)
    800051b6:	fb040593          	addi	a1,s0,-80
    800051ba:	854a                	mv	a0,s2
    800051bc:	fffff097          	auipc	ra,0xfffff
    800051c0:	cec080e7          	jalr	-788(ra) # 80003ea8 <dirlink>
    800051c4:	06054b63          	bltz	a0,8000523a <create+0x154>
  iunlockput(dp);
    800051c8:	854a                	mv	a0,s2
    800051ca:	fffff097          	auipc	ra,0xfffff
    800051ce:	84c080e7          	jalr	-1972(ra) # 80003a16 <iunlockput>
  return ip;
    800051d2:	b759                	j	80005158 <create+0x72>
    panic("create: ialloc");
    800051d4:	00003517          	auipc	a0,0x3
    800051d8:	52450513          	addi	a0,a0,1316 # 800086f8 <syscalls+0x2a0>
    800051dc:	ffffb097          	auipc	ra,0xffffb
    800051e0:	362080e7          	jalr	866(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800051e4:	04a95783          	lhu	a5,74(s2)
    800051e8:	2785                	addiw	a5,a5,1
    800051ea:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800051ee:	854a                	mv	a0,s2
    800051f0:	ffffe097          	auipc	ra,0xffffe
    800051f4:	4fa080e7          	jalr	1274(ra) # 800036ea <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800051f8:	40d0                	lw	a2,4(s1)
    800051fa:	00003597          	auipc	a1,0x3
    800051fe:	50e58593          	addi	a1,a1,1294 # 80008708 <syscalls+0x2b0>
    80005202:	8526                	mv	a0,s1
    80005204:	fffff097          	auipc	ra,0xfffff
    80005208:	ca4080e7          	jalr	-860(ra) # 80003ea8 <dirlink>
    8000520c:	00054f63          	bltz	a0,8000522a <create+0x144>
    80005210:	00492603          	lw	a2,4(s2)
    80005214:	00003597          	auipc	a1,0x3
    80005218:	4fc58593          	addi	a1,a1,1276 # 80008710 <syscalls+0x2b8>
    8000521c:	8526                	mv	a0,s1
    8000521e:	fffff097          	auipc	ra,0xfffff
    80005222:	c8a080e7          	jalr	-886(ra) # 80003ea8 <dirlink>
    80005226:	f80557e3          	bgez	a0,800051b4 <create+0xce>
      panic("create dots");
    8000522a:	00003517          	auipc	a0,0x3
    8000522e:	4ee50513          	addi	a0,a0,1262 # 80008718 <syscalls+0x2c0>
    80005232:	ffffb097          	auipc	ra,0xffffb
    80005236:	30c080e7          	jalr	780(ra) # 8000053e <panic>
    panic("create: dirlink");
    8000523a:	00003517          	auipc	a0,0x3
    8000523e:	4ee50513          	addi	a0,a0,1262 # 80008728 <syscalls+0x2d0>
    80005242:	ffffb097          	auipc	ra,0xffffb
    80005246:	2fc080e7          	jalr	764(ra) # 8000053e <panic>
    return 0;
    8000524a:	84aa                	mv	s1,a0
    8000524c:	b731                	j	80005158 <create+0x72>

000000008000524e <sys_dup>:
{
    8000524e:	7179                	addi	sp,sp,-48
    80005250:	f406                	sd	ra,40(sp)
    80005252:	f022                	sd	s0,32(sp)
    80005254:	ec26                	sd	s1,24(sp)
    80005256:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005258:	fd840613          	addi	a2,s0,-40
    8000525c:	4581                	li	a1,0
    8000525e:	4501                	li	a0,0
    80005260:	00000097          	auipc	ra,0x0
    80005264:	ddc080e7          	jalr	-548(ra) # 8000503c <argfd>
    return -1;
    80005268:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000526a:	02054363          	bltz	a0,80005290 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000526e:	fd843503          	ld	a0,-40(s0)
    80005272:	00000097          	auipc	ra,0x0
    80005276:	e32080e7          	jalr	-462(ra) # 800050a4 <fdalloc>
    8000527a:	84aa                	mv	s1,a0
    return -1;
    8000527c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000527e:	00054963          	bltz	a0,80005290 <sys_dup+0x42>
  filedup(f);
    80005282:	fd843503          	ld	a0,-40(s0)
    80005286:	fffff097          	auipc	ra,0xfffff
    8000528a:	37a080e7          	jalr	890(ra) # 80004600 <filedup>
  return fd;
    8000528e:	87a6                	mv	a5,s1
}
    80005290:	853e                	mv	a0,a5
    80005292:	70a2                	ld	ra,40(sp)
    80005294:	7402                	ld	s0,32(sp)
    80005296:	64e2                	ld	s1,24(sp)
    80005298:	6145                	addi	sp,sp,48
    8000529a:	8082                	ret

000000008000529c <sys_read>:
{
    8000529c:	7179                	addi	sp,sp,-48
    8000529e:	f406                	sd	ra,40(sp)
    800052a0:	f022                	sd	s0,32(sp)
    800052a2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052a4:	fe840613          	addi	a2,s0,-24
    800052a8:	4581                	li	a1,0
    800052aa:	4501                	li	a0,0
    800052ac:	00000097          	auipc	ra,0x0
    800052b0:	d90080e7          	jalr	-624(ra) # 8000503c <argfd>
    return -1;
    800052b4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052b6:	04054163          	bltz	a0,800052f8 <sys_read+0x5c>
    800052ba:	fe440593          	addi	a1,s0,-28
    800052be:	4509                	li	a0,2
    800052c0:	ffffe097          	auipc	ra,0xffffe
    800052c4:	982080e7          	jalr	-1662(ra) # 80002c42 <argint>
    return -1;
    800052c8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052ca:	02054763          	bltz	a0,800052f8 <sys_read+0x5c>
    800052ce:	fd840593          	addi	a1,s0,-40
    800052d2:	4505                	li	a0,1
    800052d4:	ffffe097          	auipc	ra,0xffffe
    800052d8:	990080e7          	jalr	-1648(ra) # 80002c64 <argaddr>
    return -1;
    800052dc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052de:	00054d63          	bltz	a0,800052f8 <sys_read+0x5c>
  return fileread(f, p, n);
    800052e2:	fe442603          	lw	a2,-28(s0)
    800052e6:	fd843583          	ld	a1,-40(s0)
    800052ea:	fe843503          	ld	a0,-24(s0)
    800052ee:	fffff097          	auipc	ra,0xfffff
    800052f2:	49e080e7          	jalr	1182(ra) # 8000478c <fileread>
    800052f6:	87aa                	mv	a5,a0
}
    800052f8:	853e                	mv	a0,a5
    800052fa:	70a2                	ld	ra,40(sp)
    800052fc:	7402                	ld	s0,32(sp)
    800052fe:	6145                	addi	sp,sp,48
    80005300:	8082                	ret

0000000080005302 <sys_write>:
{
    80005302:	7179                	addi	sp,sp,-48
    80005304:	f406                	sd	ra,40(sp)
    80005306:	f022                	sd	s0,32(sp)
    80005308:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000530a:	fe840613          	addi	a2,s0,-24
    8000530e:	4581                	li	a1,0
    80005310:	4501                	li	a0,0
    80005312:	00000097          	auipc	ra,0x0
    80005316:	d2a080e7          	jalr	-726(ra) # 8000503c <argfd>
    return -1;
    8000531a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000531c:	04054163          	bltz	a0,8000535e <sys_write+0x5c>
    80005320:	fe440593          	addi	a1,s0,-28
    80005324:	4509                	li	a0,2
    80005326:	ffffe097          	auipc	ra,0xffffe
    8000532a:	91c080e7          	jalr	-1764(ra) # 80002c42 <argint>
    return -1;
    8000532e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005330:	02054763          	bltz	a0,8000535e <sys_write+0x5c>
    80005334:	fd840593          	addi	a1,s0,-40
    80005338:	4505                	li	a0,1
    8000533a:	ffffe097          	auipc	ra,0xffffe
    8000533e:	92a080e7          	jalr	-1750(ra) # 80002c64 <argaddr>
    return -1;
    80005342:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005344:	00054d63          	bltz	a0,8000535e <sys_write+0x5c>
  return filewrite(f, p, n);
    80005348:	fe442603          	lw	a2,-28(s0)
    8000534c:	fd843583          	ld	a1,-40(s0)
    80005350:	fe843503          	ld	a0,-24(s0)
    80005354:	fffff097          	auipc	ra,0xfffff
    80005358:	4fa080e7          	jalr	1274(ra) # 8000484e <filewrite>
    8000535c:	87aa                	mv	a5,a0
}
    8000535e:	853e                	mv	a0,a5
    80005360:	70a2                	ld	ra,40(sp)
    80005362:	7402                	ld	s0,32(sp)
    80005364:	6145                	addi	sp,sp,48
    80005366:	8082                	ret

0000000080005368 <sys_close>:
{
    80005368:	1101                	addi	sp,sp,-32
    8000536a:	ec06                	sd	ra,24(sp)
    8000536c:	e822                	sd	s0,16(sp)
    8000536e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005370:	fe040613          	addi	a2,s0,-32
    80005374:	fec40593          	addi	a1,s0,-20
    80005378:	4501                	li	a0,0
    8000537a:	00000097          	auipc	ra,0x0
    8000537e:	cc2080e7          	jalr	-830(ra) # 8000503c <argfd>
    return -1;
    80005382:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005384:	02054463          	bltz	a0,800053ac <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005388:	ffffc097          	auipc	ra,0xffffc
    8000538c:	73c080e7          	jalr	1852(ra) # 80001ac4 <myproc>
    80005390:	fec42783          	lw	a5,-20(s0)
    80005394:	07e9                	addi	a5,a5,26
    80005396:	078e                	slli	a5,a5,0x3
    80005398:	97aa                	add	a5,a5,a0
    8000539a:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000539e:	fe043503          	ld	a0,-32(s0)
    800053a2:	fffff097          	auipc	ra,0xfffff
    800053a6:	2b0080e7          	jalr	688(ra) # 80004652 <fileclose>
  return 0;
    800053aa:	4781                	li	a5,0
}
    800053ac:	853e                	mv	a0,a5
    800053ae:	60e2                	ld	ra,24(sp)
    800053b0:	6442                	ld	s0,16(sp)
    800053b2:	6105                	addi	sp,sp,32
    800053b4:	8082                	ret

00000000800053b6 <sys_fstat>:
{
    800053b6:	1101                	addi	sp,sp,-32
    800053b8:	ec06                	sd	ra,24(sp)
    800053ba:	e822                	sd	s0,16(sp)
    800053bc:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053be:	fe840613          	addi	a2,s0,-24
    800053c2:	4581                	li	a1,0
    800053c4:	4501                	li	a0,0
    800053c6:	00000097          	auipc	ra,0x0
    800053ca:	c76080e7          	jalr	-906(ra) # 8000503c <argfd>
    return -1;
    800053ce:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053d0:	02054563          	bltz	a0,800053fa <sys_fstat+0x44>
    800053d4:	fe040593          	addi	a1,s0,-32
    800053d8:	4505                	li	a0,1
    800053da:	ffffe097          	auipc	ra,0xffffe
    800053de:	88a080e7          	jalr	-1910(ra) # 80002c64 <argaddr>
    return -1;
    800053e2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053e4:	00054b63          	bltz	a0,800053fa <sys_fstat+0x44>
  return filestat(f, st);
    800053e8:	fe043583          	ld	a1,-32(s0)
    800053ec:	fe843503          	ld	a0,-24(s0)
    800053f0:	fffff097          	auipc	ra,0xfffff
    800053f4:	32a080e7          	jalr	810(ra) # 8000471a <filestat>
    800053f8:	87aa                	mv	a5,a0
}
    800053fa:	853e                	mv	a0,a5
    800053fc:	60e2                	ld	ra,24(sp)
    800053fe:	6442                	ld	s0,16(sp)
    80005400:	6105                	addi	sp,sp,32
    80005402:	8082                	ret

0000000080005404 <sys_link>:
{
    80005404:	7169                	addi	sp,sp,-304
    80005406:	f606                	sd	ra,296(sp)
    80005408:	f222                	sd	s0,288(sp)
    8000540a:	ee26                	sd	s1,280(sp)
    8000540c:	ea4a                	sd	s2,272(sp)
    8000540e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005410:	08000613          	li	a2,128
    80005414:	ed040593          	addi	a1,s0,-304
    80005418:	4501                	li	a0,0
    8000541a:	ffffe097          	auipc	ra,0xffffe
    8000541e:	86c080e7          	jalr	-1940(ra) # 80002c86 <argstr>
    return -1;
    80005422:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005424:	10054e63          	bltz	a0,80005540 <sys_link+0x13c>
    80005428:	08000613          	li	a2,128
    8000542c:	f5040593          	addi	a1,s0,-176
    80005430:	4505                	li	a0,1
    80005432:	ffffe097          	auipc	ra,0xffffe
    80005436:	854080e7          	jalr	-1964(ra) # 80002c86 <argstr>
    return -1;
    8000543a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000543c:	10054263          	bltz	a0,80005540 <sys_link+0x13c>
  begin_op();
    80005440:	fffff097          	auipc	ra,0xfffff
    80005444:	d46080e7          	jalr	-698(ra) # 80004186 <begin_op>
  if((ip = namei(old)) == 0){
    80005448:	ed040513          	addi	a0,s0,-304
    8000544c:	fffff097          	auipc	ra,0xfffff
    80005450:	b1e080e7          	jalr	-1250(ra) # 80003f6a <namei>
    80005454:	84aa                	mv	s1,a0
    80005456:	c551                	beqz	a0,800054e2 <sys_link+0xde>
  ilock(ip);
    80005458:	ffffe097          	auipc	ra,0xffffe
    8000545c:	35c080e7          	jalr	860(ra) # 800037b4 <ilock>
  if(ip->type == T_DIR){
    80005460:	04449703          	lh	a4,68(s1)
    80005464:	4785                	li	a5,1
    80005466:	08f70463          	beq	a4,a5,800054ee <sys_link+0xea>
  ip->nlink++;
    8000546a:	04a4d783          	lhu	a5,74(s1)
    8000546e:	2785                	addiw	a5,a5,1
    80005470:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005474:	8526                	mv	a0,s1
    80005476:	ffffe097          	auipc	ra,0xffffe
    8000547a:	274080e7          	jalr	628(ra) # 800036ea <iupdate>
  iunlock(ip);
    8000547e:	8526                	mv	a0,s1
    80005480:	ffffe097          	auipc	ra,0xffffe
    80005484:	3f6080e7          	jalr	1014(ra) # 80003876 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005488:	fd040593          	addi	a1,s0,-48
    8000548c:	f5040513          	addi	a0,s0,-176
    80005490:	fffff097          	auipc	ra,0xfffff
    80005494:	af8080e7          	jalr	-1288(ra) # 80003f88 <nameiparent>
    80005498:	892a                	mv	s2,a0
    8000549a:	c935                	beqz	a0,8000550e <sys_link+0x10a>
  ilock(dp);
    8000549c:	ffffe097          	auipc	ra,0xffffe
    800054a0:	318080e7          	jalr	792(ra) # 800037b4 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054a4:	00092703          	lw	a4,0(s2)
    800054a8:	409c                	lw	a5,0(s1)
    800054aa:	04f71d63          	bne	a4,a5,80005504 <sys_link+0x100>
    800054ae:	40d0                	lw	a2,4(s1)
    800054b0:	fd040593          	addi	a1,s0,-48
    800054b4:	854a                	mv	a0,s2
    800054b6:	fffff097          	auipc	ra,0xfffff
    800054ba:	9f2080e7          	jalr	-1550(ra) # 80003ea8 <dirlink>
    800054be:	04054363          	bltz	a0,80005504 <sys_link+0x100>
  iunlockput(dp);
    800054c2:	854a                	mv	a0,s2
    800054c4:	ffffe097          	auipc	ra,0xffffe
    800054c8:	552080e7          	jalr	1362(ra) # 80003a16 <iunlockput>
  iput(ip);
    800054cc:	8526                	mv	a0,s1
    800054ce:	ffffe097          	auipc	ra,0xffffe
    800054d2:	4a0080e7          	jalr	1184(ra) # 8000396e <iput>
  end_op();
    800054d6:	fffff097          	auipc	ra,0xfffff
    800054da:	d30080e7          	jalr	-720(ra) # 80004206 <end_op>
  return 0;
    800054de:	4781                	li	a5,0
    800054e0:	a085                	j	80005540 <sys_link+0x13c>
    end_op();
    800054e2:	fffff097          	auipc	ra,0xfffff
    800054e6:	d24080e7          	jalr	-732(ra) # 80004206 <end_op>
    return -1;
    800054ea:	57fd                	li	a5,-1
    800054ec:	a891                	j	80005540 <sys_link+0x13c>
    iunlockput(ip);
    800054ee:	8526                	mv	a0,s1
    800054f0:	ffffe097          	auipc	ra,0xffffe
    800054f4:	526080e7          	jalr	1318(ra) # 80003a16 <iunlockput>
    end_op();
    800054f8:	fffff097          	auipc	ra,0xfffff
    800054fc:	d0e080e7          	jalr	-754(ra) # 80004206 <end_op>
    return -1;
    80005500:	57fd                	li	a5,-1
    80005502:	a83d                	j	80005540 <sys_link+0x13c>
    iunlockput(dp);
    80005504:	854a                	mv	a0,s2
    80005506:	ffffe097          	auipc	ra,0xffffe
    8000550a:	510080e7          	jalr	1296(ra) # 80003a16 <iunlockput>
  ilock(ip);
    8000550e:	8526                	mv	a0,s1
    80005510:	ffffe097          	auipc	ra,0xffffe
    80005514:	2a4080e7          	jalr	676(ra) # 800037b4 <ilock>
  ip->nlink--;
    80005518:	04a4d783          	lhu	a5,74(s1)
    8000551c:	37fd                	addiw	a5,a5,-1
    8000551e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005522:	8526                	mv	a0,s1
    80005524:	ffffe097          	auipc	ra,0xffffe
    80005528:	1c6080e7          	jalr	454(ra) # 800036ea <iupdate>
  iunlockput(ip);
    8000552c:	8526                	mv	a0,s1
    8000552e:	ffffe097          	auipc	ra,0xffffe
    80005532:	4e8080e7          	jalr	1256(ra) # 80003a16 <iunlockput>
  end_op();
    80005536:	fffff097          	auipc	ra,0xfffff
    8000553a:	cd0080e7          	jalr	-816(ra) # 80004206 <end_op>
  return -1;
    8000553e:	57fd                	li	a5,-1
}
    80005540:	853e                	mv	a0,a5
    80005542:	70b2                	ld	ra,296(sp)
    80005544:	7412                	ld	s0,288(sp)
    80005546:	64f2                	ld	s1,280(sp)
    80005548:	6952                	ld	s2,272(sp)
    8000554a:	6155                	addi	sp,sp,304
    8000554c:	8082                	ret

000000008000554e <sys_unlink>:
{
    8000554e:	7151                	addi	sp,sp,-240
    80005550:	f586                	sd	ra,232(sp)
    80005552:	f1a2                	sd	s0,224(sp)
    80005554:	eda6                	sd	s1,216(sp)
    80005556:	e9ca                	sd	s2,208(sp)
    80005558:	e5ce                	sd	s3,200(sp)
    8000555a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000555c:	08000613          	li	a2,128
    80005560:	f3040593          	addi	a1,s0,-208
    80005564:	4501                	li	a0,0
    80005566:	ffffd097          	auipc	ra,0xffffd
    8000556a:	720080e7          	jalr	1824(ra) # 80002c86 <argstr>
    8000556e:	18054163          	bltz	a0,800056f0 <sys_unlink+0x1a2>
  begin_op();
    80005572:	fffff097          	auipc	ra,0xfffff
    80005576:	c14080e7          	jalr	-1004(ra) # 80004186 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000557a:	fb040593          	addi	a1,s0,-80
    8000557e:	f3040513          	addi	a0,s0,-208
    80005582:	fffff097          	auipc	ra,0xfffff
    80005586:	a06080e7          	jalr	-1530(ra) # 80003f88 <nameiparent>
    8000558a:	84aa                	mv	s1,a0
    8000558c:	c979                	beqz	a0,80005662 <sys_unlink+0x114>
  ilock(dp);
    8000558e:	ffffe097          	auipc	ra,0xffffe
    80005592:	226080e7          	jalr	550(ra) # 800037b4 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005596:	00003597          	auipc	a1,0x3
    8000559a:	17258593          	addi	a1,a1,370 # 80008708 <syscalls+0x2b0>
    8000559e:	fb040513          	addi	a0,s0,-80
    800055a2:	ffffe097          	auipc	ra,0xffffe
    800055a6:	6dc080e7          	jalr	1756(ra) # 80003c7e <namecmp>
    800055aa:	14050a63          	beqz	a0,800056fe <sys_unlink+0x1b0>
    800055ae:	00003597          	auipc	a1,0x3
    800055b2:	16258593          	addi	a1,a1,354 # 80008710 <syscalls+0x2b8>
    800055b6:	fb040513          	addi	a0,s0,-80
    800055ba:	ffffe097          	auipc	ra,0xffffe
    800055be:	6c4080e7          	jalr	1732(ra) # 80003c7e <namecmp>
    800055c2:	12050e63          	beqz	a0,800056fe <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055c6:	f2c40613          	addi	a2,s0,-212
    800055ca:	fb040593          	addi	a1,s0,-80
    800055ce:	8526                	mv	a0,s1
    800055d0:	ffffe097          	auipc	ra,0xffffe
    800055d4:	6c8080e7          	jalr	1736(ra) # 80003c98 <dirlookup>
    800055d8:	892a                	mv	s2,a0
    800055da:	12050263          	beqz	a0,800056fe <sys_unlink+0x1b0>
  ilock(ip);
    800055de:	ffffe097          	auipc	ra,0xffffe
    800055e2:	1d6080e7          	jalr	470(ra) # 800037b4 <ilock>
  if(ip->nlink < 1)
    800055e6:	04a91783          	lh	a5,74(s2)
    800055ea:	08f05263          	blez	a5,8000566e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055ee:	04491703          	lh	a4,68(s2)
    800055f2:	4785                	li	a5,1
    800055f4:	08f70563          	beq	a4,a5,8000567e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800055f8:	4641                	li	a2,16
    800055fa:	4581                	li	a1,0
    800055fc:	fc040513          	addi	a0,s0,-64
    80005600:	ffffb097          	auipc	ra,0xffffb
    80005604:	7ea080e7          	jalr	2026(ra) # 80000dea <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005608:	4741                	li	a4,16
    8000560a:	f2c42683          	lw	a3,-212(s0)
    8000560e:	fc040613          	addi	a2,s0,-64
    80005612:	4581                	li	a1,0
    80005614:	8526                	mv	a0,s1
    80005616:	ffffe097          	auipc	ra,0xffffe
    8000561a:	54a080e7          	jalr	1354(ra) # 80003b60 <writei>
    8000561e:	47c1                	li	a5,16
    80005620:	0af51563          	bne	a0,a5,800056ca <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005624:	04491703          	lh	a4,68(s2)
    80005628:	4785                	li	a5,1
    8000562a:	0af70863          	beq	a4,a5,800056da <sys_unlink+0x18c>
  iunlockput(dp);
    8000562e:	8526                	mv	a0,s1
    80005630:	ffffe097          	auipc	ra,0xffffe
    80005634:	3e6080e7          	jalr	998(ra) # 80003a16 <iunlockput>
  ip->nlink--;
    80005638:	04a95783          	lhu	a5,74(s2)
    8000563c:	37fd                	addiw	a5,a5,-1
    8000563e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005642:	854a                	mv	a0,s2
    80005644:	ffffe097          	auipc	ra,0xffffe
    80005648:	0a6080e7          	jalr	166(ra) # 800036ea <iupdate>
  iunlockput(ip);
    8000564c:	854a                	mv	a0,s2
    8000564e:	ffffe097          	auipc	ra,0xffffe
    80005652:	3c8080e7          	jalr	968(ra) # 80003a16 <iunlockput>
  end_op();
    80005656:	fffff097          	auipc	ra,0xfffff
    8000565a:	bb0080e7          	jalr	-1104(ra) # 80004206 <end_op>
  return 0;
    8000565e:	4501                	li	a0,0
    80005660:	a84d                	j	80005712 <sys_unlink+0x1c4>
    end_op();
    80005662:	fffff097          	auipc	ra,0xfffff
    80005666:	ba4080e7          	jalr	-1116(ra) # 80004206 <end_op>
    return -1;
    8000566a:	557d                	li	a0,-1
    8000566c:	a05d                	j	80005712 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000566e:	00003517          	auipc	a0,0x3
    80005672:	0ca50513          	addi	a0,a0,202 # 80008738 <syscalls+0x2e0>
    80005676:	ffffb097          	auipc	ra,0xffffb
    8000567a:	ec8080e7          	jalr	-312(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000567e:	04c92703          	lw	a4,76(s2)
    80005682:	02000793          	li	a5,32
    80005686:	f6e7f9e3          	bgeu	a5,a4,800055f8 <sys_unlink+0xaa>
    8000568a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000568e:	4741                	li	a4,16
    80005690:	86ce                	mv	a3,s3
    80005692:	f1840613          	addi	a2,s0,-232
    80005696:	4581                	li	a1,0
    80005698:	854a                	mv	a0,s2
    8000569a:	ffffe097          	auipc	ra,0xffffe
    8000569e:	3ce080e7          	jalr	974(ra) # 80003a68 <readi>
    800056a2:	47c1                	li	a5,16
    800056a4:	00f51b63          	bne	a0,a5,800056ba <sys_unlink+0x16c>
    if(de.inum != 0)
    800056a8:	f1845783          	lhu	a5,-232(s0)
    800056ac:	e7a1                	bnez	a5,800056f4 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056ae:	29c1                	addiw	s3,s3,16
    800056b0:	04c92783          	lw	a5,76(s2)
    800056b4:	fcf9ede3          	bltu	s3,a5,8000568e <sys_unlink+0x140>
    800056b8:	b781                	j	800055f8 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056ba:	00003517          	auipc	a0,0x3
    800056be:	09650513          	addi	a0,a0,150 # 80008750 <syscalls+0x2f8>
    800056c2:	ffffb097          	auipc	ra,0xffffb
    800056c6:	e7c080e7          	jalr	-388(ra) # 8000053e <panic>
    panic("unlink: writei");
    800056ca:	00003517          	auipc	a0,0x3
    800056ce:	09e50513          	addi	a0,a0,158 # 80008768 <syscalls+0x310>
    800056d2:	ffffb097          	auipc	ra,0xffffb
    800056d6:	e6c080e7          	jalr	-404(ra) # 8000053e <panic>
    dp->nlink--;
    800056da:	04a4d783          	lhu	a5,74(s1)
    800056de:	37fd                	addiw	a5,a5,-1
    800056e0:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056e4:	8526                	mv	a0,s1
    800056e6:	ffffe097          	auipc	ra,0xffffe
    800056ea:	004080e7          	jalr	4(ra) # 800036ea <iupdate>
    800056ee:	b781                	j	8000562e <sys_unlink+0xe0>
    return -1;
    800056f0:	557d                	li	a0,-1
    800056f2:	a005                	j	80005712 <sys_unlink+0x1c4>
    iunlockput(ip);
    800056f4:	854a                	mv	a0,s2
    800056f6:	ffffe097          	auipc	ra,0xffffe
    800056fa:	320080e7          	jalr	800(ra) # 80003a16 <iunlockput>
  iunlockput(dp);
    800056fe:	8526                	mv	a0,s1
    80005700:	ffffe097          	auipc	ra,0xffffe
    80005704:	316080e7          	jalr	790(ra) # 80003a16 <iunlockput>
  end_op();
    80005708:	fffff097          	auipc	ra,0xfffff
    8000570c:	afe080e7          	jalr	-1282(ra) # 80004206 <end_op>
  return -1;
    80005710:	557d                	li	a0,-1
}
    80005712:	70ae                	ld	ra,232(sp)
    80005714:	740e                	ld	s0,224(sp)
    80005716:	64ee                	ld	s1,216(sp)
    80005718:	694e                	ld	s2,208(sp)
    8000571a:	69ae                	ld	s3,200(sp)
    8000571c:	616d                	addi	sp,sp,240
    8000571e:	8082                	ret

0000000080005720 <sys_open>:

uint64
sys_open(void)
{
    80005720:	7131                	addi	sp,sp,-192
    80005722:	fd06                	sd	ra,184(sp)
    80005724:	f922                	sd	s0,176(sp)
    80005726:	f526                	sd	s1,168(sp)
    80005728:	f14a                	sd	s2,160(sp)
    8000572a:	ed4e                	sd	s3,152(sp)
    8000572c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000572e:	08000613          	li	a2,128
    80005732:	f5040593          	addi	a1,s0,-176
    80005736:	4501                	li	a0,0
    80005738:	ffffd097          	auipc	ra,0xffffd
    8000573c:	54e080e7          	jalr	1358(ra) # 80002c86 <argstr>
    return -1;
    80005740:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005742:	0c054163          	bltz	a0,80005804 <sys_open+0xe4>
    80005746:	f4c40593          	addi	a1,s0,-180
    8000574a:	4505                	li	a0,1
    8000574c:	ffffd097          	auipc	ra,0xffffd
    80005750:	4f6080e7          	jalr	1270(ra) # 80002c42 <argint>
    80005754:	0a054863          	bltz	a0,80005804 <sys_open+0xe4>

  begin_op();
    80005758:	fffff097          	auipc	ra,0xfffff
    8000575c:	a2e080e7          	jalr	-1490(ra) # 80004186 <begin_op>

  if(omode & O_CREATE){
    80005760:	f4c42783          	lw	a5,-180(s0)
    80005764:	2007f793          	andi	a5,a5,512
    80005768:	cbdd                	beqz	a5,8000581e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000576a:	4681                	li	a3,0
    8000576c:	4601                	li	a2,0
    8000576e:	4589                	li	a1,2
    80005770:	f5040513          	addi	a0,s0,-176
    80005774:	00000097          	auipc	ra,0x0
    80005778:	972080e7          	jalr	-1678(ra) # 800050e6 <create>
    8000577c:	892a                	mv	s2,a0
    if(ip == 0){
    8000577e:	c959                	beqz	a0,80005814 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005780:	04491703          	lh	a4,68(s2)
    80005784:	478d                	li	a5,3
    80005786:	00f71763          	bne	a4,a5,80005794 <sys_open+0x74>
    8000578a:	04695703          	lhu	a4,70(s2)
    8000578e:	47a5                	li	a5,9
    80005790:	0ce7ec63          	bltu	a5,a4,80005868 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005794:	fffff097          	auipc	ra,0xfffff
    80005798:	e02080e7          	jalr	-510(ra) # 80004596 <filealloc>
    8000579c:	89aa                	mv	s3,a0
    8000579e:	10050263          	beqz	a0,800058a2 <sys_open+0x182>
    800057a2:	00000097          	auipc	ra,0x0
    800057a6:	902080e7          	jalr	-1790(ra) # 800050a4 <fdalloc>
    800057aa:	84aa                	mv	s1,a0
    800057ac:	0e054663          	bltz	a0,80005898 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057b0:	04491703          	lh	a4,68(s2)
    800057b4:	478d                	li	a5,3
    800057b6:	0cf70463          	beq	a4,a5,8000587e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057ba:	4789                	li	a5,2
    800057bc:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800057c0:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057c4:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057c8:	f4c42783          	lw	a5,-180(s0)
    800057cc:	0017c713          	xori	a4,a5,1
    800057d0:	8b05                	andi	a4,a4,1
    800057d2:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057d6:	0037f713          	andi	a4,a5,3
    800057da:	00e03733          	snez	a4,a4
    800057de:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057e2:	4007f793          	andi	a5,a5,1024
    800057e6:	c791                	beqz	a5,800057f2 <sys_open+0xd2>
    800057e8:	04491703          	lh	a4,68(s2)
    800057ec:	4789                	li	a5,2
    800057ee:	08f70f63          	beq	a4,a5,8000588c <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800057f2:	854a                	mv	a0,s2
    800057f4:	ffffe097          	auipc	ra,0xffffe
    800057f8:	082080e7          	jalr	130(ra) # 80003876 <iunlock>
  end_op();
    800057fc:	fffff097          	auipc	ra,0xfffff
    80005800:	a0a080e7          	jalr	-1526(ra) # 80004206 <end_op>

  return fd;
}
    80005804:	8526                	mv	a0,s1
    80005806:	70ea                	ld	ra,184(sp)
    80005808:	744a                	ld	s0,176(sp)
    8000580a:	74aa                	ld	s1,168(sp)
    8000580c:	790a                	ld	s2,160(sp)
    8000580e:	69ea                	ld	s3,152(sp)
    80005810:	6129                	addi	sp,sp,192
    80005812:	8082                	ret
      end_op();
    80005814:	fffff097          	auipc	ra,0xfffff
    80005818:	9f2080e7          	jalr	-1550(ra) # 80004206 <end_op>
      return -1;
    8000581c:	b7e5                	j	80005804 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000581e:	f5040513          	addi	a0,s0,-176
    80005822:	ffffe097          	auipc	ra,0xffffe
    80005826:	748080e7          	jalr	1864(ra) # 80003f6a <namei>
    8000582a:	892a                	mv	s2,a0
    8000582c:	c905                	beqz	a0,8000585c <sys_open+0x13c>
    ilock(ip);
    8000582e:	ffffe097          	auipc	ra,0xffffe
    80005832:	f86080e7          	jalr	-122(ra) # 800037b4 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005836:	04491703          	lh	a4,68(s2)
    8000583a:	4785                	li	a5,1
    8000583c:	f4f712e3          	bne	a4,a5,80005780 <sys_open+0x60>
    80005840:	f4c42783          	lw	a5,-180(s0)
    80005844:	dba1                	beqz	a5,80005794 <sys_open+0x74>
      iunlockput(ip);
    80005846:	854a                	mv	a0,s2
    80005848:	ffffe097          	auipc	ra,0xffffe
    8000584c:	1ce080e7          	jalr	462(ra) # 80003a16 <iunlockput>
      end_op();
    80005850:	fffff097          	auipc	ra,0xfffff
    80005854:	9b6080e7          	jalr	-1610(ra) # 80004206 <end_op>
      return -1;
    80005858:	54fd                	li	s1,-1
    8000585a:	b76d                	j	80005804 <sys_open+0xe4>
      end_op();
    8000585c:	fffff097          	auipc	ra,0xfffff
    80005860:	9aa080e7          	jalr	-1622(ra) # 80004206 <end_op>
      return -1;
    80005864:	54fd                	li	s1,-1
    80005866:	bf79                	j	80005804 <sys_open+0xe4>
    iunlockput(ip);
    80005868:	854a                	mv	a0,s2
    8000586a:	ffffe097          	auipc	ra,0xffffe
    8000586e:	1ac080e7          	jalr	428(ra) # 80003a16 <iunlockput>
    end_op();
    80005872:	fffff097          	auipc	ra,0xfffff
    80005876:	994080e7          	jalr	-1644(ra) # 80004206 <end_op>
    return -1;
    8000587a:	54fd                	li	s1,-1
    8000587c:	b761                	j	80005804 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000587e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005882:	04691783          	lh	a5,70(s2)
    80005886:	02f99223          	sh	a5,36(s3)
    8000588a:	bf2d                	j	800057c4 <sys_open+0xa4>
    itrunc(ip);
    8000588c:	854a                	mv	a0,s2
    8000588e:	ffffe097          	auipc	ra,0xffffe
    80005892:	034080e7          	jalr	52(ra) # 800038c2 <itrunc>
    80005896:	bfb1                	j	800057f2 <sys_open+0xd2>
      fileclose(f);
    80005898:	854e                	mv	a0,s3
    8000589a:	fffff097          	auipc	ra,0xfffff
    8000589e:	db8080e7          	jalr	-584(ra) # 80004652 <fileclose>
    iunlockput(ip);
    800058a2:	854a                	mv	a0,s2
    800058a4:	ffffe097          	auipc	ra,0xffffe
    800058a8:	172080e7          	jalr	370(ra) # 80003a16 <iunlockput>
    end_op();
    800058ac:	fffff097          	auipc	ra,0xfffff
    800058b0:	95a080e7          	jalr	-1702(ra) # 80004206 <end_op>
    return -1;
    800058b4:	54fd                	li	s1,-1
    800058b6:	b7b9                	j	80005804 <sys_open+0xe4>

00000000800058b8 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058b8:	7175                	addi	sp,sp,-144
    800058ba:	e506                	sd	ra,136(sp)
    800058bc:	e122                	sd	s0,128(sp)
    800058be:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058c0:	fffff097          	auipc	ra,0xfffff
    800058c4:	8c6080e7          	jalr	-1850(ra) # 80004186 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058c8:	08000613          	li	a2,128
    800058cc:	f7040593          	addi	a1,s0,-144
    800058d0:	4501                	li	a0,0
    800058d2:	ffffd097          	auipc	ra,0xffffd
    800058d6:	3b4080e7          	jalr	948(ra) # 80002c86 <argstr>
    800058da:	02054963          	bltz	a0,8000590c <sys_mkdir+0x54>
    800058de:	4681                	li	a3,0
    800058e0:	4601                	li	a2,0
    800058e2:	4585                	li	a1,1
    800058e4:	f7040513          	addi	a0,s0,-144
    800058e8:	fffff097          	auipc	ra,0xfffff
    800058ec:	7fe080e7          	jalr	2046(ra) # 800050e6 <create>
    800058f0:	cd11                	beqz	a0,8000590c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058f2:	ffffe097          	auipc	ra,0xffffe
    800058f6:	124080e7          	jalr	292(ra) # 80003a16 <iunlockput>
  end_op();
    800058fa:	fffff097          	auipc	ra,0xfffff
    800058fe:	90c080e7          	jalr	-1780(ra) # 80004206 <end_op>
  return 0;
    80005902:	4501                	li	a0,0
}
    80005904:	60aa                	ld	ra,136(sp)
    80005906:	640a                	ld	s0,128(sp)
    80005908:	6149                	addi	sp,sp,144
    8000590a:	8082                	ret
    end_op();
    8000590c:	fffff097          	auipc	ra,0xfffff
    80005910:	8fa080e7          	jalr	-1798(ra) # 80004206 <end_op>
    return -1;
    80005914:	557d                	li	a0,-1
    80005916:	b7fd                	j	80005904 <sys_mkdir+0x4c>

0000000080005918 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005918:	7135                	addi	sp,sp,-160
    8000591a:	ed06                	sd	ra,152(sp)
    8000591c:	e922                	sd	s0,144(sp)
    8000591e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005920:	fffff097          	auipc	ra,0xfffff
    80005924:	866080e7          	jalr	-1946(ra) # 80004186 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005928:	08000613          	li	a2,128
    8000592c:	f7040593          	addi	a1,s0,-144
    80005930:	4501                	li	a0,0
    80005932:	ffffd097          	auipc	ra,0xffffd
    80005936:	354080e7          	jalr	852(ra) # 80002c86 <argstr>
    8000593a:	04054a63          	bltz	a0,8000598e <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    8000593e:	f6c40593          	addi	a1,s0,-148
    80005942:	4505                	li	a0,1
    80005944:	ffffd097          	auipc	ra,0xffffd
    80005948:	2fe080e7          	jalr	766(ra) # 80002c42 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000594c:	04054163          	bltz	a0,8000598e <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005950:	f6840593          	addi	a1,s0,-152
    80005954:	4509                	li	a0,2
    80005956:	ffffd097          	auipc	ra,0xffffd
    8000595a:	2ec080e7          	jalr	748(ra) # 80002c42 <argint>
     argint(1, &major) < 0 ||
    8000595e:	02054863          	bltz	a0,8000598e <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005962:	f6841683          	lh	a3,-152(s0)
    80005966:	f6c41603          	lh	a2,-148(s0)
    8000596a:	458d                	li	a1,3
    8000596c:	f7040513          	addi	a0,s0,-144
    80005970:	fffff097          	auipc	ra,0xfffff
    80005974:	776080e7          	jalr	1910(ra) # 800050e6 <create>
     argint(2, &minor) < 0 ||
    80005978:	c919                	beqz	a0,8000598e <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000597a:	ffffe097          	auipc	ra,0xffffe
    8000597e:	09c080e7          	jalr	156(ra) # 80003a16 <iunlockput>
  end_op();
    80005982:	fffff097          	auipc	ra,0xfffff
    80005986:	884080e7          	jalr	-1916(ra) # 80004206 <end_op>
  return 0;
    8000598a:	4501                	li	a0,0
    8000598c:	a031                	j	80005998 <sys_mknod+0x80>
    end_op();
    8000598e:	fffff097          	auipc	ra,0xfffff
    80005992:	878080e7          	jalr	-1928(ra) # 80004206 <end_op>
    return -1;
    80005996:	557d                	li	a0,-1
}
    80005998:	60ea                	ld	ra,152(sp)
    8000599a:	644a                	ld	s0,144(sp)
    8000599c:	610d                	addi	sp,sp,160
    8000599e:	8082                	ret

00000000800059a0 <sys_chdir>:

uint64
sys_chdir(void)
{
    800059a0:	7135                	addi	sp,sp,-160
    800059a2:	ed06                	sd	ra,152(sp)
    800059a4:	e922                	sd	s0,144(sp)
    800059a6:	e526                	sd	s1,136(sp)
    800059a8:	e14a                	sd	s2,128(sp)
    800059aa:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059ac:	ffffc097          	auipc	ra,0xffffc
    800059b0:	118080e7          	jalr	280(ra) # 80001ac4 <myproc>
    800059b4:	892a                	mv	s2,a0
  
  begin_op();
    800059b6:	ffffe097          	auipc	ra,0xffffe
    800059ba:	7d0080e7          	jalr	2000(ra) # 80004186 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059be:	08000613          	li	a2,128
    800059c2:	f6040593          	addi	a1,s0,-160
    800059c6:	4501                	li	a0,0
    800059c8:	ffffd097          	auipc	ra,0xffffd
    800059cc:	2be080e7          	jalr	702(ra) # 80002c86 <argstr>
    800059d0:	04054b63          	bltz	a0,80005a26 <sys_chdir+0x86>
    800059d4:	f6040513          	addi	a0,s0,-160
    800059d8:	ffffe097          	auipc	ra,0xffffe
    800059dc:	592080e7          	jalr	1426(ra) # 80003f6a <namei>
    800059e0:	84aa                	mv	s1,a0
    800059e2:	c131                	beqz	a0,80005a26 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059e4:	ffffe097          	auipc	ra,0xffffe
    800059e8:	dd0080e7          	jalr	-560(ra) # 800037b4 <ilock>
  if(ip->type != T_DIR){
    800059ec:	04449703          	lh	a4,68(s1)
    800059f0:	4785                	li	a5,1
    800059f2:	04f71063          	bne	a4,a5,80005a32 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800059f6:	8526                	mv	a0,s1
    800059f8:	ffffe097          	auipc	ra,0xffffe
    800059fc:	e7e080e7          	jalr	-386(ra) # 80003876 <iunlock>
  iput(p->cwd);
    80005a00:	15093503          	ld	a0,336(s2)
    80005a04:	ffffe097          	auipc	ra,0xffffe
    80005a08:	f6a080e7          	jalr	-150(ra) # 8000396e <iput>
  end_op();
    80005a0c:	ffffe097          	auipc	ra,0xffffe
    80005a10:	7fa080e7          	jalr	2042(ra) # 80004206 <end_op>
  p->cwd = ip;
    80005a14:	14993823          	sd	s1,336(s2)
  return 0;
    80005a18:	4501                	li	a0,0
}
    80005a1a:	60ea                	ld	ra,152(sp)
    80005a1c:	644a                	ld	s0,144(sp)
    80005a1e:	64aa                	ld	s1,136(sp)
    80005a20:	690a                	ld	s2,128(sp)
    80005a22:	610d                	addi	sp,sp,160
    80005a24:	8082                	ret
    end_op();
    80005a26:	ffffe097          	auipc	ra,0xffffe
    80005a2a:	7e0080e7          	jalr	2016(ra) # 80004206 <end_op>
    return -1;
    80005a2e:	557d                	li	a0,-1
    80005a30:	b7ed                	j	80005a1a <sys_chdir+0x7a>
    iunlockput(ip);
    80005a32:	8526                	mv	a0,s1
    80005a34:	ffffe097          	auipc	ra,0xffffe
    80005a38:	fe2080e7          	jalr	-30(ra) # 80003a16 <iunlockput>
    end_op();
    80005a3c:	ffffe097          	auipc	ra,0xffffe
    80005a40:	7ca080e7          	jalr	1994(ra) # 80004206 <end_op>
    return -1;
    80005a44:	557d                	li	a0,-1
    80005a46:	bfd1                	j	80005a1a <sys_chdir+0x7a>

0000000080005a48 <sys_exec>:

uint64
sys_exec(void)
{
    80005a48:	7145                	addi	sp,sp,-464
    80005a4a:	e786                	sd	ra,456(sp)
    80005a4c:	e3a2                	sd	s0,448(sp)
    80005a4e:	ff26                	sd	s1,440(sp)
    80005a50:	fb4a                	sd	s2,432(sp)
    80005a52:	f74e                	sd	s3,424(sp)
    80005a54:	f352                	sd	s4,416(sp)
    80005a56:	ef56                	sd	s5,408(sp)
    80005a58:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a5a:	08000613          	li	a2,128
    80005a5e:	f4040593          	addi	a1,s0,-192
    80005a62:	4501                	li	a0,0
    80005a64:	ffffd097          	auipc	ra,0xffffd
    80005a68:	222080e7          	jalr	546(ra) # 80002c86 <argstr>
    return -1;
    80005a6c:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a6e:	0c054a63          	bltz	a0,80005b42 <sys_exec+0xfa>
    80005a72:	e3840593          	addi	a1,s0,-456
    80005a76:	4505                	li	a0,1
    80005a78:	ffffd097          	auipc	ra,0xffffd
    80005a7c:	1ec080e7          	jalr	492(ra) # 80002c64 <argaddr>
    80005a80:	0c054163          	bltz	a0,80005b42 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a84:	10000613          	li	a2,256
    80005a88:	4581                	li	a1,0
    80005a8a:	e4040513          	addi	a0,s0,-448
    80005a8e:	ffffb097          	auipc	ra,0xffffb
    80005a92:	35c080e7          	jalr	860(ra) # 80000dea <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a96:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a9a:	89a6                	mv	s3,s1
    80005a9c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a9e:	02000a13          	li	s4,32
    80005aa2:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005aa6:	00391513          	slli	a0,s2,0x3
    80005aaa:	e3040593          	addi	a1,s0,-464
    80005aae:	e3843783          	ld	a5,-456(s0)
    80005ab2:	953e                	add	a0,a0,a5
    80005ab4:	ffffd097          	auipc	ra,0xffffd
    80005ab8:	0f4080e7          	jalr	244(ra) # 80002ba8 <fetchaddr>
    80005abc:	02054a63          	bltz	a0,80005af0 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005ac0:	e3043783          	ld	a5,-464(s0)
    80005ac4:	c3b9                	beqz	a5,80005b0a <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ac6:	ffffb097          	auipc	ra,0xffffb
    80005aca:	f32080e7          	jalr	-206(ra) # 800009f8 <kalloc>
    80005ace:	85aa                	mv	a1,a0
    80005ad0:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ad4:	cd11                	beqz	a0,80005af0 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ad6:	6605                	lui	a2,0x1
    80005ad8:	e3043503          	ld	a0,-464(s0)
    80005adc:	ffffd097          	auipc	ra,0xffffd
    80005ae0:	11e080e7          	jalr	286(ra) # 80002bfa <fetchstr>
    80005ae4:	00054663          	bltz	a0,80005af0 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005ae8:	0905                	addi	s2,s2,1
    80005aea:	09a1                	addi	s3,s3,8
    80005aec:	fb491be3          	bne	s2,s4,80005aa2 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005af0:	10048913          	addi	s2,s1,256
    80005af4:	6088                	ld	a0,0(s1)
    80005af6:	c529                	beqz	a0,80005b40 <sys_exec+0xf8>
    kfree(argv[i]);
    80005af8:	ffffb097          	auipc	ra,0xffffb
    80005afc:	014080e7          	jalr	20(ra) # 80000b0c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b00:	04a1                	addi	s1,s1,8
    80005b02:	ff2499e3          	bne	s1,s2,80005af4 <sys_exec+0xac>
  return -1;
    80005b06:	597d                	li	s2,-1
    80005b08:	a82d                	j	80005b42 <sys_exec+0xfa>
      argv[i] = 0;
    80005b0a:	0a8e                	slli	s5,s5,0x3
    80005b0c:	fc040793          	addi	a5,s0,-64
    80005b10:	9abe                	add	s5,s5,a5
    80005b12:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b16:	e4040593          	addi	a1,s0,-448
    80005b1a:	f4040513          	addi	a0,s0,-192
    80005b1e:	fffff097          	auipc	ra,0xfffff
    80005b22:	194080e7          	jalr	404(ra) # 80004cb2 <exec>
    80005b26:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b28:	10048993          	addi	s3,s1,256
    80005b2c:	6088                	ld	a0,0(s1)
    80005b2e:	c911                	beqz	a0,80005b42 <sys_exec+0xfa>
    kfree(argv[i]);
    80005b30:	ffffb097          	auipc	ra,0xffffb
    80005b34:	fdc080e7          	jalr	-36(ra) # 80000b0c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b38:	04a1                	addi	s1,s1,8
    80005b3a:	ff3499e3          	bne	s1,s3,80005b2c <sys_exec+0xe4>
    80005b3e:	a011                	j	80005b42 <sys_exec+0xfa>
  return -1;
    80005b40:	597d                	li	s2,-1
}
    80005b42:	854a                	mv	a0,s2
    80005b44:	60be                	ld	ra,456(sp)
    80005b46:	641e                	ld	s0,448(sp)
    80005b48:	74fa                	ld	s1,440(sp)
    80005b4a:	795a                	ld	s2,432(sp)
    80005b4c:	79ba                	ld	s3,424(sp)
    80005b4e:	7a1a                	ld	s4,416(sp)
    80005b50:	6afa                	ld	s5,408(sp)
    80005b52:	6179                	addi	sp,sp,464
    80005b54:	8082                	ret

0000000080005b56 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b56:	7139                	addi	sp,sp,-64
    80005b58:	fc06                	sd	ra,56(sp)
    80005b5a:	f822                	sd	s0,48(sp)
    80005b5c:	f426                	sd	s1,40(sp)
    80005b5e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b60:	ffffc097          	auipc	ra,0xffffc
    80005b64:	f64080e7          	jalr	-156(ra) # 80001ac4 <myproc>
    80005b68:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005b6a:	fd840593          	addi	a1,s0,-40
    80005b6e:	4501                	li	a0,0
    80005b70:	ffffd097          	auipc	ra,0xffffd
    80005b74:	0f4080e7          	jalr	244(ra) # 80002c64 <argaddr>
    return -1;
    80005b78:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b7a:	0e054063          	bltz	a0,80005c5a <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b7e:	fc840593          	addi	a1,s0,-56
    80005b82:	fd040513          	addi	a0,s0,-48
    80005b86:	fffff097          	auipc	ra,0xfffff
    80005b8a:	dfc080e7          	jalr	-516(ra) # 80004982 <pipealloc>
    return -1;
    80005b8e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b90:	0c054563          	bltz	a0,80005c5a <sys_pipe+0x104>
  fd0 = -1;
    80005b94:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b98:	fd043503          	ld	a0,-48(s0)
    80005b9c:	fffff097          	auipc	ra,0xfffff
    80005ba0:	508080e7          	jalr	1288(ra) # 800050a4 <fdalloc>
    80005ba4:	fca42223          	sw	a0,-60(s0)
    80005ba8:	08054c63          	bltz	a0,80005c40 <sys_pipe+0xea>
    80005bac:	fc843503          	ld	a0,-56(s0)
    80005bb0:	fffff097          	auipc	ra,0xfffff
    80005bb4:	4f4080e7          	jalr	1268(ra) # 800050a4 <fdalloc>
    80005bb8:	fca42023          	sw	a0,-64(s0)
    80005bbc:	06054863          	bltz	a0,80005c2c <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bc0:	4691                	li	a3,4
    80005bc2:	fc440613          	addi	a2,s0,-60
    80005bc6:	fd843583          	ld	a1,-40(s0)
    80005bca:	68a8                	ld	a0,80(s1)
    80005bcc:	ffffc097          	auipc	ra,0xffffc
    80005bd0:	ba6080e7          	jalr	-1114(ra) # 80001772 <copyout>
    80005bd4:	02054063          	bltz	a0,80005bf4 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005bd8:	4691                	li	a3,4
    80005bda:	fc040613          	addi	a2,s0,-64
    80005bde:	fd843583          	ld	a1,-40(s0)
    80005be2:	0591                	addi	a1,a1,4
    80005be4:	68a8                	ld	a0,80(s1)
    80005be6:	ffffc097          	auipc	ra,0xffffc
    80005bea:	b8c080e7          	jalr	-1140(ra) # 80001772 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005bee:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bf0:	06055563          	bgez	a0,80005c5a <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005bf4:	fc442783          	lw	a5,-60(s0)
    80005bf8:	07e9                	addi	a5,a5,26
    80005bfa:	078e                	slli	a5,a5,0x3
    80005bfc:	97a6                	add	a5,a5,s1
    80005bfe:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c02:	fc042503          	lw	a0,-64(s0)
    80005c06:	0569                	addi	a0,a0,26
    80005c08:	050e                	slli	a0,a0,0x3
    80005c0a:	9526                	add	a0,a0,s1
    80005c0c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c10:	fd043503          	ld	a0,-48(s0)
    80005c14:	fffff097          	auipc	ra,0xfffff
    80005c18:	a3e080e7          	jalr	-1474(ra) # 80004652 <fileclose>
    fileclose(wf);
    80005c1c:	fc843503          	ld	a0,-56(s0)
    80005c20:	fffff097          	auipc	ra,0xfffff
    80005c24:	a32080e7          	jalr	-1486(ra) # 80004652 <fileclose>
    return -1;
    80005c28:	57fd                	li	a5,-1
    80005c2a:	a805                	j	80005c5a <sys_pipe+0x104>
    if(fd0 >= 0)
    80005c2c:	fc442783          	lw	a5,-60(s0)
    80005c30:	0007c863          	bltz	a5,80005c40 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005c34:	01a78513          	addi	a0,a5,26
    80005c38:	050e                	slli	a0,a0,0x3
    80005c3a:	9526                	add	a0,a0,s1
    80005c3c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c40:	fd043503          	ld	a0,-48(s0)
    80005c44:	fffff097          	auipc	ra,0xfffff
    80005c48:	a0e080e7          	jalr	-1522(ra) # 80004652 <fileclose>
    fileclose(wf);
    80005c4c:	fc843503          	ld	a0,-56(s0)
    80005c50:	fffff097          	auipc	ra,0xfffff
    80005c54:	a02080e7          	jalr	-1534(ra) # 80004652 <fileclose>
    return -1;
    80005c58:	57fd                	li	a5,-1
}
    80005c5a:	853e                	mv	a0,a5
    80005c5c:	70e2                	ld	ra,56(sp)
    80005c5e:	7442                	ld	s0,48(sp)
    80005c60:	74a2                	ld	s1,40(sp)
    80005c62:	6121                	addi	sp,sp,64
    80005c64:	8082                	ret
	...

0000000080005c70 <kernelvec>:
    80005c70:	7111                	addi	sp,sp,-256
    80005c72:	e006                	sd	ra,0(sp)
    80005c74:	e40a                	sd	sp,8(sp)
    80005c76:	e80e                	sd	gp,16(sp)
    80005c78:	ec12                	sd	tp,24(sp)
    80005c7a:	f016                	sd	t0,32(sp)
    80005c7c:	f41a                	sd	t1,40(sp)
    80005c7e:	f81e                	sd	t2,48(sp)
    80005c80:	fc22                	sd	s0,56(sp)
    80005c82:	e0a6                	sd	s1,64(sp)
    80005c84:	e4aa                	sd	a0,72(sp)
    80005c86:	e8ae                	sd	a1,80(sp)
    80005c88:	ecb2                	sd	a2,88(sp)
    80005c8a:	f0b6                	sd	a3,96(sp)
    80005c8c:	f4ba                	sd	a4,104(sp)
    80005c8e:	f8be                	sd	a5,112(sp)
    80005c90:	fcc2                	sd	a6,120(sp)
    80005c92:	e146                	sd	a7,128(sp)
    80005c94:	e54a                	sd	s2,136(sp)
    80005c96:	e94e                	sd	s3,144(sp)
    80005c98:	ed52                	sd	s4,152(sp)
    80005c9a:	f156                	sd	s5,160(sp)
    80005c9c:	f55a                	sd	s6,168(sp)
    80005c9e:	f95e                	sd	s7,176(sp)
    80005ca0:	fd62                	sd	s8,184(sp)
    80005ca2:	e1e6                	sd	s9,192(sp)
    80005ca4:	e5ea                	sd	s10,200(sp)
    80005ca6:	e9ee                	sd	s11,208(sp)
    80005ca8:	edf2                	sd	t3,216(sp)
    80005caa:	f1f6                	sd	t4,224(sp)
    80005cac:	f5fa                	sd	t5,232(sp)
    80005cae:	f9fe                	sd	t6,240(sp)
    80005cb0:	dc5fc0ef          	jal	ra,80002a74 <kerneltrap>
    80005cb4:	6082                	ld	ra,0(sp)
    80005cb6:	6122                	ld	sp,8(sp)
    80005cb8:	61c2                	ld	gp,16(sp)
    80005cba:	7282                	ld	t0,32(sp)
    80005cbc:	7322                	ld	t1,40(sp)
    80005cbe:	73c2                	ld	t2,48(sp)
    80005cc0:	7462                	ld	s0,56(sp)
    80005cc2:	6486                	ld	s1,64(sp)
    80005cc4:	6526                	ld	a0,72(sp)
    80005cc6:	65c6                	ld	a1,80(sp)
    80005cc8:	6666                	ld	a2,88(sp)
    80005cca:	7686                	ld	a3,96(sp)
    80005ccc:	7726                	ld	a4,104(sp)
    80005cce:	77c6                	ld	a5,112(sp)
    80005cd0:	7866                	ld	a6,120(sp)
    80005cd2:	688a                	ld	a7,128(sp)
    80005cd4:	692a                	ld	s2,136(sp)
    80005cd6:	69ca                	ld	s3,144(sp)
    80005cd8:	6a6a                	ld	s4,152(sp)
    80005cda:	7a8a                	ld	s5,160(sp)
    80005cdc:	7b2a                	ld	s6,168(sp)
    80005cde:	7bca                	ld	s7,176(sp)
    80005ce0:	7c6a                	ld	s8,184(sp)
    80005ce2:	6c8e                	ld	s9,192(sp)
    80005ce4:	6d2e                	ld	s10,200(sp)
    80005ce6:	6dce                	ld	s11,208(sp)
    80005ce8:	6e6e                	ld	t3,216(sp)
    80005cea:	7e8e                	ld	t4,224(sp)
    80005cec:	7f2e                	ld	t5,232(sp)
    80005cee:	7fce                	ld	t6,240(sp)
    80005cf0:	6111                	addi	sp,sp,256
    80005cf2:	10200073          	sret
    80005cf6:	00000013          	nop
    80005cfa:	00000013          	nop
    80005cfe:	0001                	nop

0000000080005d00 <timervec>:
    80005d00:	34051573          	csrrw	a0,mscratch,a0
    80005d04:	e10c                	sd	a1,0(a0)
    80005d06:	e510                	sd	a2,8(a0)
    80005d08:	e914                	sd	a3,16(a0)
    80005d0a:	6d0c                	ld	a1,24(a0)
    80005d0c:	7110                	ld	a2,32(a0)
    80005d0e:	6194                	ld	a3,0(a1)
    80005d10:	96b2                	add	a3,a3,a2
    80005d12:	e194                	sd	a3,0(a1)
    80005d14:	4589                	li	a1,2
    80005d16:	14459073          	csrw	sip,a1
    80005d1a:	6914                	ld	a3,16(a0)
    80005d1c:	6510                	ld	a2,8(a0)
    80005d1e:	610c                	ld	a1,0(a0)
    80005d20:	34051573          	csrrw	a0,mscratch,a0
    80005d24:	30200073          	mret
	...

0000000080005d2a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d2a:	1141                	addi	sp,sp,-16
    80005d2c:	e422                	sd	s0,8(sp)
    80005d2e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d30:	0c0007b7          	lui	a5,0xc000
    80005d34:	4705                	li	a4,1
    80005d36:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d38:	c3d8                	sw	a4,4(a5)
}
    80005d3a:	6422                	ld	s0,8(sp)
    80005d3c:	0141                	addi	sp,sp,16
    80005d3e:	8082                	ret

0000000080005d40 <plicinithart>:

void
plicinithart(void)
{
    80005d40:	1141                	addi	sp,sp,-16
    80005d42:	e406                	sd	ra,8(sp)
    80005d44:	e022                	sd	s0,0(sp)
    80005d46:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d48:	ffffc097          	auipc	ra,0xffffc
    80005d4c:	d50080e7          	jalr	-688(ra) # 80001a98 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d50:	0085171b          	slliw	a4,a0,0x8
    80005d54:	0c0027b7          	lui	a5,0xc002
    80005d58:	97ba                	add	a5,a5,a4
    80005d5a:	40200713          	li	a4,1026
    80005d5e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d62:	00d5151b          	slliw	a0,a0,0xd
    80005d66:	0c2017b7          	lui	a5,0xc201
    80005d6a:	953e                	add	a0,a0,a5
    80005d6c:	00052023          	sw	zero,0(a0)
}
    80005d70:	60a2                	ld	ra,8(sp)
    80005d72:	6402                	ld	s0,0(sp)
    80005d74:	0141                	addi	sp,sp,16
    80005d76:	8082                	ret

0000000080005d78 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d78:	1141                	addi	sp,sp,-16
    80005d7a:	e406                	sd	ra,8(sp)
    80005d7c:	e022                	sd	s0,0(sp)
    80005d7e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d80:	ffffc097          	auipc	ra,0xffffc
    80005d84:	d18080e7          	jalr	-744(ra) # 80001a98 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d88:	00d5179b          	slliw	a5,a0,0xd
    80005d8c:	0c201537          	lui	a0,0xc201
    80005d90:	953e                	add	a0,a0,a5
  return irq;
}
    80005d92:	4148                	lw	a0,4(a0)
    80005d94:	60a2                	ld	ra,8(sp)
    80005d96:	6402                	ld	s0,0(sp)
    80005d98:	0141                	addi	sp,sp,16
    80005d9a:	8082                	ret

0000000080005d9c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d9c:	1101                	addi	sp,sp,-32
    80005d9e:	ec06                	sd	ra,24(sp)
    80005da0:	e822                	sd	s0,16(sp)
    80005da2:	e426                	sd	s1,8(sp)
    80005da4:	1000                	addi	s0,sp,32
    80005da6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005da8:	ffffc097          	auipc	ra,0xffffc
    80005dac:	cf0080e7          	jalr	-784(ra) # 80001a98 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005db0:	00d5151b          	slliw	a0,a0,0xd
    80005db4:	0c2017b7          	lui	a5,0xc201
    80005db8:	97aa                	add	a5,a5,a0
    80005dba:	c3c4                	sw	s1,4(a5)
}
    80005dbc:	60e2                	ld	ra,24(sp)
    80005dbe:	6442                	ld	s0,16(sp)
    80005dc0:	64a2                	ld	s1,8(sp)
    80005dc2:	6105                	addi	sp,sp,32
    80005dc4:	8082                	ret

0000000080005dc6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005dc6:	1141                	addi	sp,sp,-16
    80005dc8:	e406                	sd	ra,8(sp)
    80005dca:	e022                	sd	s0,0(sp)
    80005dcc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005dce:	479d                	li	a5,7
    80005dd0:	06a7c963          	blt	a5,a0,80005e42 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005dd4:	0003d797          	auipc	a5,0x3d
    80005dd8:	22c78793          	addi	a5,a5,556 # 80043000 <disk>
    80005ddc:	00a78733          	add	a4,a5,a0
    80005de0:	6789                	lui	a5,0x2
    80005de2:	97ba                	add	a5,a5,a4
    80005de4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005de8:	e7ad                	bnez	a5,80005e52 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005dea:	00451793          	slli	a5,a0,0x4
    80005dee:	0003f717          	auipc	a4,0x3f
    80005df2:	21270713          	addi	a4,a4,530 # 80045000 <disk+0x2000>
    80005df6:	6314                	ld	a3,0(a4)
    80005df8:	96be                	add	a3,a3,a5
    80005dfa:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005dfe:	6314                	ld	a3,0(a4)
    80005e00:	96be                	add	a3,a3,a5
    80005e02:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005e06:	6314                	ld	a3,0(a4)
    80005e08:	96be                	add	a3,a3,a5
    80005e0a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005e0e:	6318                	ld	a4,0(a4)
    80005e10:	97ba                	add	a5,a5,a4
    80005e12:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005e16:	0003d797          	auipc	a5,0x3d
    80005e1a:	1ea78793          	addi	a5,a5,490 # 80043000 <disk>
    80005e1e:	97aa                	add	a5,a5,a0
    80005e20:	6509                	lui	a0,0x2
    80005e22:	953e                	add	a0,a0,a5
    80005e24:	4785                	li	a5,1
    80005e26:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005e2a:	0003f517          	auipc	a0,0x3f
    80005e2e:	1ee50513          	addi	a0,a0,494 # 80045018 <disk+0x2018>
    80005e32:	ffffc097          	auipc	ra,0xffffc
    80005e36:	4da080e7          	jalr	1242(ra) # 8000230c <wakeup>
}
    80005e3a:	60a2                	ld	ra,8(sp)
    80005e3c:	6402                	ld	s0,0(sp)
    80005e3e:	0141                	addi	sp,sp,16
    80005e40:	8082                	ret
    panic("free_desc 1");
    80005e42:	00003517          	auipc	a0,0x3
    80005e46:	93650513          	addi	a0,a0,-1738 # 80008778 <syscalls+0x320>
    80005e4a:	ffffa097          	auipc	ra,0xffffa
    80005e4e:	6f4080e7          	jalr	1780(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005e52:	00003517          	auipc	a0,0x3
    80005e56:	93650513          	addi	a0,a0,-1738 # 80008788 <syscalls+0x330>
    80005e5a:	ffffa097          	auipc	ra,0xffffa
    80005e5e:	6e4080e7          	jalr	1764(ra) # 8000053e <panic>

0000000080005e62 <virtio_disk_init>:
{
    80005e62:	1101                	addi	sp,sp,-32
    80005e64:	ec06                	sd	ra,24(sp)
    80005e66:	e822                	sd	s0,16(sp)
    80005e68:	e426                	sd	s1,8(sp)
    80005e6a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e6c:	00003597          	auipc	a1,0x3
    80005e70:	92c58593          	addi	a1,a1,-1748 # 80008798 <syscalls+0x340>
    80005e74:	0003f517          	auipc	a0,0x3f
    80005e78:	2b450513          	addi	a0,a0,692 # 80045128 <disk+0x2128>
    80005e7c:	ffffb097          	auipc	ra,0xffffb
    80005e80:	de2080e7          	jalr	-542(ra) # 80000c5e <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e84:	100017b7          	lui	a5,0x10001
    80005e88:	4398                	lw	a4,0(a5)
    80005e8a:	2701                	sext.w	a4,a4
    80005e8c:	747277b7          	lui	a5,0x74727
    80005e90:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e94:	0ef71163          	bne	a4,a5,80005f76 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e98:	100017b7          	lui	a5,0x10001
    80005e9c:	43dc                	lw	a5,4(a5)
    80005e9e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ea0:	4705                	li	a4,1
    80005ea2:	0ce79a63          	bne	a5,a4,80005f76 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ea6:	100017b7          	lui	a5,0x10001
    80005eaa:	479c                	lw	a5,8(a5)
    80005eac:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005eae:	4709                	li	a4,2
    80005eb0:	0ce79363          	bne	a5,a4,80005f76 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005eb4:	100017b7          	lui	a5,0x10001
    80005eb8:	47d8                	lw	a4,12(a5)
    80005eba:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ebc:	554d47b7          	lui	a5,0x554d4
    80005ec0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005ec4:	0af71963          	bne	a4,a5,80005f76 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ec8:	100017b7          	lui	a5,0x10001
    80005ecc:	4705                	li	a4,1
    80005ece:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ed0:	470d                	li	a4,3
    80005ed2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005ed4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005ed6:	c7ffe737          	lui	a4,0xc7ffe
    80005eda:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fb875f>
    80005ede:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005ee0:	2701                	sext.w	a4,a4
    80005ee2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ee4:	472d                	li	a4,11
    80005ee6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ee8:	473d                	li	a4,15
    80005eea:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005eec:	6705                	lui	a4,0x1
    80005eee:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005ef0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005ef4:	5bdc                	lw	a5,52(a5)
    80005ef6:	2781                	sext.w	a5,a5
  if(max == 0)
    80005ef8:	c7d9                	beqz	a5,80005f86 <virtio_disk_init+0x124>
  if(max < NUM)
    80005efa:	471d                	li	a4,7
    80005efc:	08f77d63          	bgeu	a4,a5,80005f96 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f00:	100014b7          	lui	s1,0x10001
    80005f04:	47a1                	li	a5,8
    80005f06:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005f08:	6609                	lui	a2,0x2
    80005f0a:	4581                	li	a1,0
    80005f0c:	0003d517          	auipc	a0,0x3d
    80005f10:	0f450513          	addi	a0,a0,244 # 80043000 <disk>
    80005f14:	ffffb097          	auipc	ra,0xffffb
    80005f18:	ed6080e7          	jalr	-298(ra) # 80000dea <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005f1c:	0003d717          	auipc	a4,0x3d
    80005f20:	0e470713          	addi	a4,a4,228 # 80043000 <disk>
    80005f24:	00c75793          	srli	a5,a4,0xc
    80005f28:	2781                	sext.w	a5,a5
    80005f2a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005f2c:	0003f797          	auipc	a5,0x3f
    80005f30:	0d478793          	addi	a5,a5,212 # 80045000 <disk+0x2000>
    80005f34:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005f36:	0003d717          	auipc	a4,0x3d
    80005f3a:	14a70713          	addi	a4,a4,330 # 80043080 <disk+0x80>
    80005f3e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005f40:	0003e717          	auipc	a4,0x3e
    80005f44:	0c070713          	addi	a4,a4,192 # 80044000 <disk+0x1000>
    80005f48:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005f4a:	4705                	li	a4,1
    80005f4c:	00e78c23          	sb	a4,24(a5)
    80005f50:	00e78ca3          	sb	a4,25(a5)
    80005f54:	00e78d23          	sb	a4,26(a5)
    80005f58:	00e78da3          	sb	a4,27(a5)
    80005f5c:	00e78e23          	sb	a4,28(a5)
    80005f60:	00e78ea3          	sb	a4,29(a5)
    80005f64:	00e78f23          	sb	a4,30(a5)
    80005f68:	00e78fa3          	sb	a4,31(a5)
}
    80005f6c:	60e2                	ld	ra,24(sp)
    80005f6e:	6442                	ld	s0,16(sp)
    80005f70:	64a2                	ld	s1,8(sp)
    80005f72:	6105                	addi	sp,sp,32
    80005f74:	8082                	ret
    panic("could not find virtio disk");
    80005f76:	00003517          	auipc	a0,0x3
    80005f7a:	83250513          	addi	a0,a0,-1998 # 800087a8 <syscalls+0x350>
    80005f7e:	ffffa097          	auipc	ra,0xffffa
    80005f82:	5c0080e7          	jalr	1472(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80005f86:	00003517          	auipc	a0,0x3
    80005f8a:	84250513          	addi	a0,a0,-1982 # 800087c8 <syscalls+0x370>
    80005f8e:	ffffa097          	auipc	ra,0xffffa
    80005f92:	5b0080e7          	jalr	1456(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80005f96:	00003517          	auipc	a0,0x3
    80005f9a:	85250513          	addi	a0,a0,-1966 # 800087e8 <syscalls+0x390>
    80005f9e:	ffffa097          	auipc	ra,0xffffa
    80005fa2:	5a0080e7          	jalr	1440(ra) # 8000053e <panic>

0000000080005fa6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005fa6:	7159                	addi	sp,sp,-112
    80005fa8:	f486                	sd	ra,104(sp)
    80005faa:	f0a2                	sd	s0,96(sp)
    80005fac:	eca6                	sd	s1,88(sp)
    80005fae:	e8ca                	sd	s2,80(sp)
    80005fb0:	e4ce                	sd	s3,72(sp)
    80005fb2:	e0d2                	sd	s4,64(sp)
    80005fb4:	fc56                	sd	s5,56(sp)
    80005fb6:	f85a                	sd	s6,48(sp)
    80005fb8:	f45e                	sd	s7,40(sp)
    80005fba:	f062                	sd	s8,32(sp)
    80005fbc:	ec66                	sd	s9,24(sp)
    80005fbe:	e86a                	sd	s10,16(sp)
    80005fc0:	1880                	addi	s0,sp,112
    80005fc2:	892a                	mv	s2,a0
    80005fc4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005fc6:	00c52c83          	lw	s9,12(a0)
    80005fca:	001c9c9b          	slliw	s9,s9,0x1
    80005fce:	1c82                	slli	s9,s9,0x20
    80005fd0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005fd4:	0003f517          	auipc	a0,0x3f
    80005fd8:	15450513          	addi	a0,a0,340 # 80045128 <disk+0x2128>
    80005fdc:	ffffb097          	auipc	ra,0xffffb
    80005fe0:	d12080e7          	jalr	-750(ra) # 80000cee <acquire>
  for(int i = 0; i < 3; i++){
    80005fe4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005fe6:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005fe8:	0003db97          	auipc	s7,0x3d
    80005fec:	018b8b93          	addi	s7,s7,24 # 80043000 <disk>
    80005ff0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005ff2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005ff4:	8a4e                	mv	s4,s3
    80005ff6:	a051                	j	8000607a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005ff8:	00fb86b3          	add	a3,s7,a5
    80005ffc:	96da                	add	a3,a3,s6
    80005ffe:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006002:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006004:	0207c563          	bltz	a5,8000602e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006008:	2485                	addiw	s1,s1,1
    8000600a:	0711                	addi	a4,a4,4
    8000600c:	25548063          	beq	s1,s5,8000624c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006010:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006012:	0003f697          	auipc	a3,0x3f
    80006016:	00668693          	addi	a3,a3,6 # 80045018 <disk+0x2018>
    8000601a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000601c:	0006c583          	lbu	a1,0(a3)
    80006020:	fde1                	bnez	a1,80005ff8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006022:	2785                	addiw	a5,a5,1
    80006024:	0685                	addi	a3,a3,1
    80006026:	ff879be3          	bne	a5,s8,8000601c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000602a:	57fd                	li	a5,-1
    8000602c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000602e:	02905a63          	blez	s1,80006062 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006032:	f9042503          	lw	a0,-112(s0)
    80006036:	00000097          	auipc	ra,0x0
    8000603a:	d90080e7          	jalr	-624(ra) # 80005dc6 <free_desc>
      for(int j = 0; j < i; j++)
    8000603e:	4785                	li	a5,1
    80006040:	0297d163          	bge	a5,s1,80006062 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006044:	f9442503          	lw	a0,-108(s0)
    80006048:	00000097          	auipc	ra,0x0
    8000604c:	d7e080e7          	jalr	-642(ra) # 80005dc6 <free_desc>
      for(int j = 0; j < i; j++)
    80006050:	4789                	li	a5,2
    80006052:	0097d863          	bge	a5,s1,80006062 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006056:	f9842503          	lw	a0,-104(s0)
    8000605a:	00000097          	auipc	ra,0x0
    8000605e:	d6c080e7          	jalr	-660(ra) # 80005dc6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006062:	0003f597          	auipc	a1,0x3f
    80006066:	0c658593          	addi	a1,a1,198 # 80045128 <disk+0x2128>
    8000606a:	0003f517          	auipc	a0,0x3f
    8000606e:	fae50513          	addi	a0,a0,-82 # 80045018 <disk+0x2018>
    80006072:	ffffc097          	auipc	ra,0xffffc
    80006076:	10e080e7          	jalr	270(ra) # 80002180 <sleep>
  for(int i = 0; i < 3; i++){
    8000607a:	f9040713          	addi	a4,s0,-112
    8000607e:	84ce                	mv	s1,s3
    80006080:	bf41                	j	80006010 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006082:	20058713          	addi	a4,a1,512
    80006086:	00471693          	slli	a3,a4,0x4
    8000608a:	0003d717          	auipc	a4,0x3d
    8000608e:	f7670713          	addi	a4,a4,-138 # 80043000 <disk>
    80006092:	9736                	add	a4,a4,a3
    80006094:	4685                	li	a3,1
    80006096:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000609a:	20058713          	addi	a4,a1,512
    8000609e:	00471693          	slli	a3,a4,0x4
    800060a2:	0003d717          	auipc	a4,0x3d
    800060a6:	f5e70713          	addi	a4,a4,-162 # 80043000 <disk>
    800060aa:	9736                	add	a4,a4,a3
    800060ac:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800060b0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800060b4:	7679                	lui	a2,0xffffe
    800060b6:	963e                	add	a2,a2,a5
    800060b8:	0003f697          	auipc	a3,0x3f
    800060bc:	f4868693          	addi	a3,a3,-184 # 80045000 <disk+0x2000>
    800060c0:	6298                	ld	a4,0(a3)
    800060c2:	9732                	add	a4,a4,a2
    800060c4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800060c6:	6298                	ld	a4,0(a3)
    800060c8:	9732                	add	a4,a4,a2
    800060ca:	4541                	li	a0,16
    800060cc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800060ce:	6298                	ld	a4,0(a3)
    800060d0:	9732                	add	a4,a4,a2
    800060d2:	4505                	li	a0,1
    800060d4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800060d8:	f9442703          	lw	a4,-108(s0)
    800060dc:	6288                	ld	a0,0(a3)
    800060de:	962a                	add	a2,a2,a0
    800060e0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffb800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800060e4:	0712                	slli	a4,a4,0x4
    800060e6:	6290                	ld	a2,0(a3)
    800060e8:	963a                	add	a2,a2,a4
    800060ea:	05890513          	addi	a0,s2,88
    800060ee:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800060f0:	6294                	ld	a3,0(a3)
    800060f2:	96ba                	add	a3,a3,a4
    800060f4:	40000613          	li	a2,1024
    800060f8:	c690                	sw	a2,8(a3)
  if(write)
    800060fa:	140d0063          	beqz	s10,8000623a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800060fe:	0003f697          	auipc	a3,0x3f
    80006102:	f026b683          	ld	a3,-254(a3) # 80045000 <disk+0x2000>
    80006106:	96ba                	add	a3,a3,a4
    80006108:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000610c:	0003d817          	auipc	a6,0x3d
    80006110:	ef480813          	addi	a6,a6,-268 # 80043000 <disk>
    80006114:	0003f517          	auipc	a0,0x3f
    80006118:	eec50513          	addi	a0,a0,-276 # 80045000 <disk+0x2000>
    8000611c:	6114                	ld	a3,0(a0)
    8000611e:	96ba                	add	a3,a3,a4
    80006120:	00c6d603          	lhu	a2,12(a3)
    80006124:	00166613          	ori	a2,a2,1
    80006128:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000612c:	f9842683          	lw	a3,-104(s0)
    80006130:	6110                	ld	a2,0(a0)
    80006132:	9732                	add	a4,a4,a2
    80006134:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006138:	20058613          	addi	a2,a1,512
    8000613c:	0612                	slli	a2,a2,0x4
    8000613e:	9642                	add	a2,a2,a6
    80006140:	577d                	li	a4,-1
    80006142:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006146:	00469713          	slli	a4,a3,0x4
    8000614a:	6114                	ld	a3,0(a0)
    8000614c:	96ba                	add	a3,a3,a4
    8000614e:	03078793          	addi	a5,a5,48
    80006152:	97c2                	add	a5,a5,a6
    80006154:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006156:	611c                	ld	a5,0(a0)
    80006158:	97ba                	add	a5,a5,a4
    8000615a:	4685                	li	a3,1
    8000615c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000615e:	611c                	ld	a5,0(a0)
    80006160:	97ba                	add	a5,a5,a4
    80006162:	4809                	li	a6,2
    80006164:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006168:	611c                	ld	a5,0(a0)
    8000616a:	973e                	add	a4,a4,a5
    8000616c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006170:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006174:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006178:	6518                	ld	a4,8(a0)
    8000617a:	00275783          	lhu	a5,2(a4)
    8000617e:	8b9d                	andi	a5,a5,7
    80006180:	0786                	slli	a5,a5,0x1
    80006182:	97ba                	add	a5,a5,a4
    80006184:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006188:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000618c:	6518                	ld	a4,8(a0)
    8000618e:	00275783          	lhu	a5,2(a4)
    80006192:	2785                	addiw	a5,a5,1
    80006194:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006198:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000619c:	100017b7          	lui	a5,0x10001
    800061a0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800061a4:	00492703          	lw	a4,4(s2)
    800061a8:	4785                	li	a5,1
    800061aa:	02f71163          	bne	a4,a5,800061cc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800061ae:	0003f997          	auipc	s3,0x3f
    800061b2:	f7a98993          	addi	s3,s3,-134 # 80045128 <disk+0x2128>
  while(b->disk == 1) {
    800061b6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800061b8:	85ce                	mv	a1,s3
    800061ba:	854a                	mv	a0,s2
    800061bc:	ffffc097          	auipc	ra,0xffffc
    800061c0:	fc4080e7          	jalr	-60(ra) # 80002180 <sleep>
  while(b->disk == 1) {
    800061c4:	00492783          	lw	a5,4(s2)
    800061c8:	fe9788e3          	beq	a5,s1,800061b8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800061cc:	f9042903          	lw	s2,-112(s0)
    800061d0:	20090793          	addi	a5,s2,512
    800061d4:	00479713          	slli	a4,a5,0x4
    800061d8:	0003d797          	auipc	a5,0x3d
    800061dc:	e2878793          	addi	a5,a5,-472 # 80043000 <disk>
    800061e0:	97ba                	add	a5,a5,a4
    800061e2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800061e6:	0003f997          	auipc	s3,0x3f
    800061ea:	e1a98993          	addi	s3,s3,-486 # 80045000 <disk+0x2000>
    800061ee:	00491713          	slli	a4,s2,0x4
    800061f2:	0009b783          	ld	a5,0(s3)
    800061f6:	97ba                	add	a5,a5,a4
    800061f8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800061fc:	854a                	mv	a0,s2
    800061fe:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006202:	00000097          	auipc	ra,0x0
    80006206:	bc4080e7          	jalr	-1084(ra) # 80005dc6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000620a:	8885                	andi	s1,s1,1
    8000620c:	f0ed                	bnez	s1,800061ee <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000620e:	0003f517          	auipc	a0,0x3f
    80006212:	f1a50513          	addi	a0,a0,-230 # 80045128 <disk+0x2128>
    80006216:	ffffb097          	auipc	ra,0xffffb
    8000621a:	b8c080e7          	jalr	-1140(ra) # 80000da2 <release>
}
    8000621e:	70a6                	ld	ra,104(sp)
    80006220:	7406                	ld	s0,96(sp)
    80006222:	64e6                	ld	s1,88(sp)
    80006224:	6946                	ld	s2,80(sp)
    80006226:	69a6                	ld	s3,72(sp)
    80006228:	6a06                	ld	s4,64(sp)
    8000622a:	7ae2                	ld	s5,56(sp)
    8000622c:	7b42                	ld	s6,48(sp)
    8000622e:	7ba2                	ld	s7,40(sp)
    80006230:	7c02                	ld	s8,32(sp)
    80006232:	6ce2                	ld	s9,24(sp)
    80006234:	6d42                	ld	s10,16(sp)
    80006236:	6165                	addi	sp,sp,112
    80006238:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000623a:	0003f697          	auipc	a3,0x3f
    8000623e:	dc66b683          	ld	a3,-570(a3) # 80045000 <disk+0x2000>
    80006242:	96ba                	add	a3,a3,a4
    80006244:	4609                	li	a2,2
    80006246:	00c69623          	sh	a2,12(a3)
    8000624a:	b5c9                	j	8000610c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000624c:	f9042583          	lw	a1,-112(s0)
    80006250:	20058793          	addi	a5,a1,512
    80006254:	0792                	slli	a5,a5,0x4
    80006256:	0003d517          	auipc	a0,0x3d
    8000625a:	e5250513          	addi	a0,a0,-430 # 800430a8 <disk+0xa8>
    8000625e:	953e                	add	a0,a0,a5
  if(write)
    80006260:	e20d11e3          	bnez	s10,80006082 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006264:	20058713          	addi	a4,a1,512
    80006268:	00471693          	slli	a3,a4,0x4
    8000626c:	0003d717          	auipc	a4,0x3d
    80006270:	d9470713          	addi	a4,a4,-620 # 80043000 <disk>
    80006274:	9736                	add	a4,a4,a3
    80006276:	0a072423          	sw	zero,168(a4)
    8000627a:	b505                	j	8000609a <virtio_disk_rw+0xf4>

000000008000627c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000627c:	1101                	addi	sp,sp,-32
    8000627e:	ec06                	sd	ra,24(sp)
    80006280:	e822                	sd	s0,16(sp)
    80006282:	e426                	sd	s1,8(sp)
    80006284:	e04a                	sd	s2,0(sp)
    80006286:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006288:	0003f517          	auipc	a0,0x3f
    8000628c:	ea050513          	addi	a0,a0,-352 # 80045128 <disk+0x2128>
    80006290:	ffffb097          	auipc	ra,0xffffb
    80006294:	a5e080e7          	jalr	-1442(ra) # 80000cee <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006298:	10001737          	lui	a4,0x10001
    8000629c:	533c                	lw	a5,96(a4)
    8000629e:	8b8d                	andi	a5,a5,3
    800062a0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800062a2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800062a6:	0003f797          	auipc	a5,0x3f
    800062aa:	d5a78793          	addi	a5,a5,-678 # 80045000 <disk+0x2000>
    800062ae:	6b94                	ld	a3,16(a5)
    800062b0:	0207d703          	lhu	a4,32(a5)
    800062b4:	0026d783          	lhu	a5,2(a3)
    800062b8:	06f70163          	beq	a4,a5,8000631a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800062bc:	0003d917          	auipc	s2,0x3d
    800062c0:	d4490913          	addi	s2,s2,-700 # 80043000 <disk>
    800062c4:	0003f497          	auipc	s1,0x3f
    800062c8:	d3c48493          	addi	s1,s1,-708 # 80045000 <disk+0x2000>
    __sync_synchronize();
    800062cc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800062d0:	6898                	ld	a4,16(s1)
    800062d2:	0204d783          	lhu	a5,32(s1)
    800062d6:	8b9d                	andi	a5,a5,7
    800062d8:	078e                	slli	a5,a5,0x3
    800062da:	97ba                	add	a5,a5,a4
    800062dc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800062de:	20078713          	addi	a4,a5,512
    800062e2:	0712                	slli	a4,a4,0x4
    800062e4:	974a                	add	a4,a4,s2
    800062e6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800062ea:	e731                	bnez	a4,80006336 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800062ec:	20078793          	addi	a5,a5,512
    800062f0:	0792                	slli	a5,a5,0x4
    800062f2:	97ca                	add	a5,a5,s2
    800062f4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800062f6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800062fa:	ffffc097          	auipc	ra,0xffffc
    800062fe:	012080e7          	jalr	18(ra) # 8000230c <wakeup>

    disk.used_idx += 1;
    80006302:	0204d783          	lhu	a5,32(s1)
    80006306:	2785                	addiw	a5,a5,1
    80006308:	17c2                	slli	a5,a5,0x30
    8000630a:	93c1                	srli	a5,a5,0x30
    8000630c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006310:	6898                	ld	a4,16(s1)
    80006312:	00275703          	lhu	a4,2(a4)
    80006316:	faf71be3          	bne	a4,a5,800062cc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000631a:	0003f517          	auipc	a0,0x3f
    8000631e:	e0e50513          	addi	a0,a0,-498 # 80045128 <disk+0x2128>
    80006322:	ffffb097          	auipc	ra,0xffffb
    80006326:	a80080e7          	jalr	-1408(ra) # 80000da2 <release>
}
    8000632a:	60e2                	ld	ra,24(sp)
    8000632c:	6442                	ld	s0,16(sp)
    8000632e:	64a2                	ld	s1,8(sp)
    80006330:	6902                	ld	s2,0(sp)
    80006332:	6105                	addi	sp,sp,32
    80006334:	8082                	ret
      panic("virtio_disk_intr status");
    80006336:	00002517          	auipc	a0,0x2
    8000633a:	4d250513          	addi	a0,a0,1234 # 80008808 <syscalls+0x3b0>
    8000633e:	ffffa097          	auipc	ra,0xffffa
    80006342:	200080e7          	jalr	512(ra) # 8000053e <panic>

0000000080006346 <cas>:
    80006346:	100522af          	lr.w	t0,(a0)
    8000634a:	00b29563          	bne	t0,a1,80006354 <fail>
    8000634e:	18c5252f          	sc.w	a0,a2,(a0)
    80006352:	8082                	ret

0000000080006354 <fail>:
    80006354:	4505                	li	a0,1
    80006356:	8082                	ret
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
