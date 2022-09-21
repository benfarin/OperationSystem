
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	88013103          	ld	sp,-1920(sp) # 80008880 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000056:	ffe70713          	addi	a4,a4,-2 # 80009050 <timer_scratch>
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
    80000068:	2cc78793          	addi	a5,a5,716 # 80006330 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
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
    8000012c:	00003097          	auipc	ra,0x3
    80000130:	a36080e7          	jalr	-1482(ra) # 80002b62 <either_copyin>
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
    80000190:	00450513          	addi	a0,a0,4 # 80011190 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	ff448493          	addi	s1,s1,-12 # 80011190 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	08290913          	addi	s2,s2,130 # 80011228 <cons+0x98>
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
    800001c8:	aea080e7          	jalr	-1302(ra) # 80001cae <myproc>
    800001cc:	413c                	lw	a5,64(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	46a080e7          	jalr	1130(ra) # 8000263e <sleep>
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
    80000210:	00003097          	auipc	ra,0x3
    80000214:	8fc080e7          	jalr	-1796(ra) # 80002b0c <either_copyout>
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
    80000228:	f6c50513          	addi	a0,a0,-148 # 80011190 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f5650513          	addi	a0,a0,-170 # 80011190 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
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
    80000276:	faf72b23          	sw	a5,-74(a4) # 80011228 <cons+0x98>
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
    800002d0:	ec450513          	addi	a0,a0,-316 # 80011190 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

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
    800002f2:	00003097          	auipc	ra,0x3
    800002f6:	8c6080e7          	jalr	-1850(ra) # 80002bb8 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e9650513          	addi	a0,a0,-362 # 80011190 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
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
    80000322:	e7270713          	addi	a4,a4,-398 # 80011190 <cons>
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
    8000034c:	e4878793          	addi	a5,a5,-440 # 80011190 <cons>
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
    8000037a:	eb27a783          	lw	a5,-334(a5) # 80011228 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	e0670713          	addi	a4,a4,-506 # 80011190 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	df648493          	addi	s1,s1,-522 # 80011190 <cons>
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
    800003da:	dba70713          	addi	a4,a4,-582 # 80011190 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e4f72223          	sw	a5,-444(a4) # 80011230 <cons+0xa0>
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
    80000416:	d7e78793          	addi	a5,a5,-642 # 80011190 <cons>
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
    8000043a:	dec7ab23          	sw	a2,-522(a5) # 8001122c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dea50513          	addi	a0,a0,-534 # 80011228 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	3f4080e7          	jalr	1012(ra) # 8000283a <wakeup>
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
    80000464:	d3050513          	addi	a0,a0,-720 # 80011190 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00022797          	auipc	a5,0x22
    8000047c:	91078793          	addi	a5,a5,-1776 # 80021d88 <devsw>
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
    8000054e:	d007a323          	sw	zero,-762(a5) # 80011250 <pr+0x18>
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
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
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
    800005be:	c96dad83          	lw	s11,-874(s11) # 80011250 <pr+0x18>
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
    800005fc:	c4050513          	addi	a0,a0,-960 # 80011238 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
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
    80000760:	adc50513          	addi	a0,a0,-1316 # 80011238 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
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
    8000077c:	ac048493          	addi	s1,s1,-1344 # 80011238 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
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
    800007dc:	a8050513          	addi	a0,a0,-1408 # 80011258 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
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
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

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
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
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
    8000086e:	9eea0a13          	addi	s4,s4,-1554 # 80011258 <uart_tx_lock>
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
    800008a4:	f9a080e7          	jalr	-102(ra) # 8000283a <wakeup>
    
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
    800008e0:	97c50513          	addi	a0,a0,-1668 # 80011258 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
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
    80000914:	948a0a13          	addi	s4,s4,-1720 # 80011258 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	d12080e7          	jalr	-750(ra) # 8000263e <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	91648493          	addi	s1,s1,-1770 # 80011258 <uart_tx_lock>
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
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
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
    800009ce:	88e48493          	addi	s1,s1,-1906 # 80011258 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00025797          	auipc	a5,0x25
    80000a10:	5f478793          	addi	a5,a5,1524 # 80026000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	86490913          	addi	s2,s2,-1948 # 80011290 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7c850513          	addi	a0,a0,1992 # 80011290 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00025517          	auipc	a0,0x25
    80000ae0:	52450513          	addi	a0,a0,1316 # 80026000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	79248493          	addi	s1,s1,1938 # 80011290 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	77a50513          	addi	a0,a0,1914 # 80011290 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	74e50513          	addi	a0,a0,1870 # 80011290 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	114080e7          	jalr	276(ra) # 80001c92 <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	0e2080e7          	jalr	226(ra) # 80001c92 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	0d6080e7          	jalr	214(ra) # 80001c92 <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	0be080e7          	jalr	190(ra) # 80001c92 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	07e080e7          	jalr	126(ra) # 80001c92 <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	052080e7          	jalr	82(ra) # 80001c92 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	dec080e7          	jalr	-532(ra) # 80001c82 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c139                	beqz	a0,80000eec <main+0x5e>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	dd0080e7          	jalr	-560(ra) # 80001c82 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	ebe080e7          	jalr	-322(ra) # 80002d92 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	494080e7          	jalr	1172(ra) # 80006370 <plicinithart>

  #ifdef ON
    scheduler();
  #endif
  #ifdef OFF
    scheduler();
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	52c080e7          	jalr	1324(ra) # 80002410 <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	1cc50513          	addi	a0,a0,460 # 800080c8 <digits+0x88>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	1ac50513          	addi	a0,a0,428 # 800080c8 <digits+0x88>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	b8c080e7          	jalr	-1140(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	322080e7          	jalr	802(ra) # 80001256 <kvminit>
    kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	068080e7          	jalr	104(ra) # 80000fa4 <kvminithart>
    procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	c1c080e7          	jalr	-996(ra) # 80001b60 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	e1e080e7          	jalr	-482(ra) # 80002d6a <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	e3e080e7          	jalr	-450(ra) # 80002d92 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	3fe080e7          	jalr	1022(ra) # 8000635a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	40c080e7          	jalr	1036(ra) # 80006370 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	5e4080e7          	jalr	1508(ra) # 80003550 <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	c74080e7          	jalr	-908(ra) # 80003be8 <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	c1e080e7          	jalr	-994(ra) # 80004b9a <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	50e080e7          	jalr	1294(ra) # 80006492 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	04e080e7          	jalr	78(ra) # 80001fda <userinit>
    __sync_synchronize();
    80000f94:	0ff0000f          	fence
    started = 1;
    80000f98:	4785                	li	a5,1
    80000f9a:	00008717          	auipc	a4,0x8
    80000f9e:	06f72f23          	sw	a5,126(a4) # 80009018 <started>
    80000fa2:	b789                	j	80000ee4 <main+0x56>

0000000080000fa4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000faa:	00008797          	auipc	a5,0x8
    80000fae:	0767b783          	ld	a5,118(a5) # 80009020 <kernel_pagetable>
    80000fb2:	83b1                	srli	a5,a5,0xc
    80000fb4:	577d                	li	a4,-1
    80000fb6:	177e                	slli	a4,a4,0x3f
    80000fb8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fba:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fbe:	12000073          	sfence.vma
  sfence_vma();
}
    80000fc2:	6422                	ld	s0,8(sp)
    80000fc4:	0141                	addi	sp,sp,16
    80000fc6:	8082                	ret

0000000080000fc8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fc8:	7139                	addi	sp,sp,-64
    80000fca:	fc06                	sd	ra,56(sp)
    80000fcc:	f822                	sd	s0,48(sp)
    80000fce:	f426                	sd	s1,40(sp)
    80000fd0:	f04a                	sd	s2,32(sp)
    80000fd2:	ec4e                	sd	s3,24(sp)
    80000fd4:	e852                	sd	s4,16(sp)
    80000fd6:	e456                	sd	s5,8(sp)
    80000fd8:	e05a                	sd	s6,0(sp)
    80000fda:	0080                	addi	s0,sp,64
    80000fdc:	84aa                	mv	s1,a0
    80000fde:	89ae                	mv	s3,a1
    80000fe0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe2:	57fd                	li	a5,-1
    80000fe4:	83e9                	srli	a5,a5,0x1a
    80000fe6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fe8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fea:	04b7f263          	bgeu	a5,a1,8000102e <walk+0x66>
    panic("walk");
    80000fee:	00007517          	auipc	a0,0x7
    80000ff2:	0e250513          	addi	a0,a0,226 # 800080d0 <digits+0x90>
    80000ff6:	fffff097          	auipc	ra,0xfffff
    80000ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ffe:	060a8663          	beqz	s5,8000106a <walk+0xa2>
    80001002:	00000097          	auipc	ra,0x0
    80001006:	af2080e7          	jalr	-1294(ra) # 80000af4 <kalloc>
    8000100a:	84aa                	mv	s1,a0
    8000100c:	c529                	beqz	a0,80001056 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000100e:	6605                	lui	a2,0x1
    80001010:	4581                	li	a1,0
    80001012:	00000097          	auipc	ra,0x0
    80001016:	cce080e7          	jalr	-818(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101a:	00c4d793          	srli	a5,s1,0xc
    8000101e:	07aa                	slli	a5,a5,0xa
    80001020:	0017e793          	ori	a5,a5,1
    80001024:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001028:	3a5d                	addiw	s4,s4,-9
    8000102a:	036a0063          	beq	s4,s6,8000104a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000102e:	0149d933          	srl	s2,s3,s4
    80001032:	1ff97913          	andi	s2,s2,511
    80001036:	090e                	slli	s2,s2,0x3
    80001038:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000103a:	00093483          	ld	s1,0(s2)
    8000103e:	0014f793          	andi	a5,s1,1
    80001042:	dfd5                	beqz	a5,80000ffe <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001044:	80a9                	srli	s1,s1,0xa
    80001046:	04b2                	slli	s1,s1,0xc
    80001048:	b7c5                	j	80001028 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000104a:	00c9d513          	srli	a0,s3,0xc
    8000104e:	1ff57513          	andi	a0,a0,511
    80001052:	050e                	slli	a0,a0,0x3
    80001054:	9526                	add	a0,a0,s1
}
    80001056:	70e2                	ld	ra,56(sp)
    80001058:	7442                	ld	s0,48(sp)
    8000105a:	74a2                	ld	s1,40(sp)
    8000105c:	7902                	ld	s2,32(sp)
    8000105e:	69e2                	ld	s3,24(sp)
    80001060:	6a42                	ld	s4,16(sp)
    80001062:	6aa2                	ld	s5,8(sp)
    80001064:	6b02                	ld	s6,0(sp)
    80001066:	6121                	addi	sp,sp,64
    80001068:	8082                	ret
        return 0;
    8000106a:	4501                	li	a0,0
    8000106c:	b7ed                	j	80001056 <walk+0x8e>

000000008000106e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000106e:	57fd                	li	a5,-1
    80001070:	83e9                	srli	a5,a5,0x1a
    80001072:	00b7f463          	bgeu	a5,a1,8000107a <walkaddr+0xc>
    return 0;
    80001076:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001078:	8082                	ret
{
    8000107a:	1141                	addi	sp,sp,-16
    8000107c:	e406                	sd	ra,8(sp)
    8000107e:	e022                	sd	s0,0(sp)
    80001080:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001082:	4601                	li	a2,0
    80001084:	00000097          	auipc	ra,0x0
    80001088:	f44080e7          	jalr	-188(ra) # 80000fc8 <walk>
  if(pte == 0)
    8000108c:	c105                	beqz	a0,800010ac <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000108e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001090:	0117f693          	andi	a3,a5,17
    80001094:	4745                	li	a4,17
    return 0;
    80001096:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001098:	00e68663          	beq	a3,a4,800010a4 <walkaddr+0x36>
}
    8000109c:	60a2                	ld	ra,8(sp)
    8000109e:	6402                	ld	s0,0(sp)
    800010a0:	0141                	addi	sp,sp,16
    800010a2:	8082                	ret
  pa = PTE2PA(*pte);
    800010a4:	00a7d513          	srli	a0,a5,0xa
    800010a8:	0532                	slli	a0,a0,0xc
  return pa;
    800010aa:	bfcd                	j	8000109c <walkaddr+0x2e>
    return 0;
    800010ac:	4501                	li	a0,0
    800010ae:	b7fd                	j	8000109c <walkaddr+0x2e>

00000000800010b0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b0:	715d                	addi	sp,sp,-80
    800010b2:	e486                	sd	ra,72(sp)
    800010b4:	e0a2                	sd	s0,64(sp)
    800010b6:	fc26                	sd	s1,56(sp)
    800010b8:	f84a                	sd	s2,48(sp)
    800010ba:	f44e                	sd	s3,40(sp)
    800010bc:	f052                	sd	s4,32(sp)
    800010be:	ec56                	sd	s5,24(sp)
    800010c0:	e85a                	sd	s6,16(sp)
    800010c2:	e45e                	sd	s7,8(sp)
    800010c4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010c6:	c205                	beqz	a2,800010e6 <mappages+0x36>
    800010c8:	8aaa                	mv	s5,a0
    800010ca:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010cc:	77fd                	lui	a5,0xfffff
    800010ce:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010d2:	15fd                	addi	a1,a1,-1
    800010d4:	00c589b3          	add	s3,a1,a2
    800010d8:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010dc:	8952                	mv	s2,s4
    800010de:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010e2:	6b85                	lui	s7,0x1
    800010e4:	a015                	j	80001108 <mappages+0x58>
    panic("mappages: size");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	ff250513          	addi	a0,a0,-14 # 800080d8 <digits+0x98>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	ff250513          	addi	a0,a0,-14 # 800080e8 <digits+0xa8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    a += PGSIZE;
    80001106:	995e                	add	s2,s2,s7
  for(;;){
    80001108:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000110c:	4605                	li	a2,1
    8000110e:	85ca                	mv	a1,s2
    80001110:	8556                	mv	a0,s5
    80001112:	00000097          	auipc	ra,0x0
    80001116:	eb6080e7          	jalr	-330(ra) # 80000fc8 <walk>
    8000111a:	cd19                	beqz	a0,80001138 <mappages+0x88>
    if(*pte & PTE_V)
    8000111c:	611c                	ld	a5,0(a0)
    8000111e:	8b85                	andi	a5,a5,1
    80001120:	fbf9                	bnez	a5,800010f6 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001122:	80b1                	srli	s1,s1,0xc
    80001124:	04aa                	slli	s1,s1,0xa
    80001126:	0164e4b3          	or	s1,s1,s6
    8000112a:	0014e493          	ori	s1,s1,1
    8000112e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001130:	fd391be3          	bne	s2,s3,80001106 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	a011                	j	8000113a <mappages+0x8a>
      return -1;
    80001138:	557d                	li	a0,-1
}
    8000113a:	60a6                	ld	ra,72(sp)
    8000113c:	6406                	ld	s0,64(sp)
    8000113e:	74e2                	ld	s1,56(sp)
    80001140:	7942                	ld	s2,48(sp)
    80001142:	79a2                	ld	s3,40(sp)
    80001144:	7a02                	ld	s4,32(sp)
    80001146:	6ae2                	ld	s5,24(sp)
    80001148:	6b42                	ld	s6,16(sp)
    8000114a:	6ba2                	ld	s7,8(sp)
    8000114c:	6161                	addi	sp,sp,80
    8000114e:	8082                	ret

0000000080001150 <kvmmap>:
{
    80001150:	1141                	addi	sp,sp,-16
    80001152:	e406                	sd	ra,8(sp)
    80001154:	e022                	sd	s0,0(sp)
    80001156:	0800                	addi	s0,sp,16
    80001158:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000115a:	86b2                	mv	a3,a2
    8000115c:	863e                	mv	a2,a5
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	f52080e7          	jalr	-174(ra) # 800010b0 <mappages>
    80001166:	e509                	bnez	a0,80001170 <kvmmap+0x20>
}
    80001168:	60a2                	ld	ra,8(sp)
    8000116a:	6402                	ld	s0,0(sp)
    8000116c:	0141                	addi	sp,sp,16
    8000116e:	8082                	ret
    panic("kvmmap");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f8850513          	addi	a0,a0,-120 # 800080f8 <digits+0xb8>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>

0000000080001180 <kvmmake>:
{
    80001180:	1101                	addi	sp,sp,-32
    80001182:	ec06                	sd	ra,24(sp)
    80001184:	e822                	sd	s0,16(sp)
    80001186:	e426                	sd	s1,8(sp)
    80001188:	e04a                	sd	s2,0(sp)
    8000118a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	968080e7          	jalr	-1688(ra) # 80000af4 <kalloc>
    80001194:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001196:	6605                	lui	a2,0x1
    80001198:	4581                	li	a1,0
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	b46080e7          	jalr	-1210(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a2:	4719                	li	a4,6
    800011a4:	6685                	lui	a3,0x1
    800011a6:	10000637          	lui	a2,0x10000
    800011aa:	100005b7          	lui	a1,0x10000
    800011ae:	8526                	mv	a0,s1
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	fa0080e7          	jalr	-96(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b8:	4719                	li	a4,6
    800011ba:	6685                	lui	a3,0x1
    800011bc:	10001637          	lui	a2,0x10001
    800011c0:	100015b7          	lui	a1,0x10001
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f8a080e7          	jalr	-118(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	004006b7          	lui	a3,0x400
    800011d4:	0c000637          	lui	a2,0xc000
    800011d8:	0c0005b7          	lui	a1,0xc000
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f72080e7          	jalr	-142(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e6:	00007917          	auipc	s2,0x7
    800011ea:	e1a90913          	addi	s2,s2,-486 # 80008000 <etext>
    800011ee:	4729                	li	a4,10
    800011f0:	80007697          	auipc	a3,0x80007
    800011f4:	e1068693          	addi	a3,a3,-496 # 8000 <_entry-0x7fff8000>
    800011f8:	4605                	li	a2,1
    800011fa:	067e                	slli	a2,a2,0x1f
    800011fc:	85b2                	mv	a1,a2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f50080e7          	jalr	-176(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	46c5                	li	a3,17
    8000120c:	06ee                	slli	a3,a3,0x1b
    8000120e:	412686b3          	sub	a3,a3,s2
    80001212:	864a                	mv	a2,s2
    80001214:	85ca                	mv	a1,s2
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f38080e7          	jalr	-200(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001220:	4729                	li	a4,10
    80001222:	6685                	lui	a3,0x1
    80001224:	00006617          	auipc	a2,0x6
    80001228:	ddc60613          	addi	a2,a2,-548 # 80007000 <_trampoline>
    8000122c:	040005b7          	lui	a1,0x4000
    80001230:	15fd                	addi	a1,a1,-1
    80001232:	05b2                	slli	a1,a1,0xc
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f1a080e7          	jalr	-230(ra) # 80001150 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000123e:	8526                	mv	a0,s1
    80001240:	00001097          	auipc	ra,0x1
    80001244:	88a080e7          	jalr	-1910(ra) # 80001aca <proc_mapstacks>
}
    80001248:	8526                	mv	a0,s1
    8000124a:	60e2                	ld	ra,24(sp)
    8000124c:	6442                	ld	s0,16(sp)
    8000124e:	64a2                	ld	s1,8(sp)
    80001250:	6902                	ld	s2,0(sp)
    80001252:	6105                	addi	sp,sp,32
    80001254:	8082                	ret

0000000080001256 <kvminit>:
{
    80001256:	1141                	addi	sp,sp,-16
    80001258:	e406                	sd	ra,8(sp)
    8000125a:	e022                	sd	s0,0(sp)
    8000125c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f22080e7          	jalr	-222(ra) # 80001180 <kvmmake>
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	daa7bd23          	sd	a0,-582(a5) # 80009020 <kernel_pagetable>
}
    8000126e:	60a2                	ld	ra,8(sp)
    80001270:	6402                	ld	s0,0(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret

0000000080001276 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001276:	715d                	addi	sp,sp,-80
    80001278:	e486                	sd	ra,72(sp)
    8000127a:	e0a2                	sd	s0,64(sp)
    8000127c:	fc26                	sd	s1,56(sp)
    8000127e:	f84a                	sd	s2,48(sp)
    80001280:	f44e                	sd	s3,40(sp)
    80001282:	f052                	sd	s4,32(sp)
    80001284:	ec56                	sd	s5,24(sp)
    80001286:	e85a                	sd	s6,16(sp)
    80001288:	e45e                	sd	s7,8(sp)
    8000128a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128c:	03459793          	slli	a5,a1,0x34
    80001290:	e795                	bnez	a5,800012bc <uvmunmap+0x46>
    80001292:	8a2a                	mv	s4,a0
    80001294:	892e                	mv	s2,a1
    80001296:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001298:	0632                	slli	a2,a2,0xc
    8000129a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	6b05                	lui	s6,0x1
    800012a2:	0735e863          	bltu	a1,s3,80001312 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a6:	60a6                	ld	ra,72(sp)
    800012a8:	6406                	ld	s0,64(sp)
    800012aa:	74e2                	ld	s1,56(sp)
    800012ac:	7942                	ld	s2,48(sp)
    800012ae:	79a2                	ld	s3,40(sp)
    800012b0:	7a02                	ld	s4,32(sp)
    800012b2:	6ae2                	ld	s5,24(sp)
    800012b4:	6b42                	ld	s6,16(sp)
    800012b6:	6ba2                	ld	s7,8(sp)
    800012b8:	6161                	addi	sp,sp,80
    800012ba:	8082                	ret
    panic("uvmunmap: not aligned");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e4450513          	addi	a0,a0,-444 # 80008100 <digits+0xc0>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	27a080e7          	jalr	634(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e5450513          	addi	a0,a0,-428 # 80008140 <digits+0x100>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012fc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fe:	0532                	slli	a0,a0,0xc
    80001300:	fffff097          	auipc	ra,0xfffff
    80001304:	6f8080e7          	jalr	1784(ra) # 800009f8 <kfree>
    *pte = 0;
    80001308:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130c:	995a                	add	s2,s2,s6
    8000130e:	f9397ce3          	bgeu	s2,s3,800012a6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001312:	4601                	li	a2,0
    80001314:	85ca                	mv	a1,s2
    80001316:	8552                	mv	a0,s4
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	cb0080e7          	jalr	-848(ra) # 80000fc8 <walk>
    80001320:	84aa                	mv	s1,a0
    80001322:	d54d                	beqz	a0,800012cc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001324:	6108                	ld	a0,0(a0)
    80001326:	00157793          	andi	a5,a0,1
    8000132a:	dbcd                	beqz	a5,800012dc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132c:	3ff57793          	andi	a5,a0,1023
    80001330:	fb778ee3          	beq	a5,s7,800012ec <uvmunmap+0x76>
    if(do_free){
    80001334:	fc0a8ae3          	beqz	s5,80001308 <uvmunmap+0x92>
    80001338:	b7d1                	j	800012fc <uvmunmap+0x86>

000000008000133a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000133a:	1101                	addi	sp,sp,-32
    8000133c:	ec06                	sd	ra,24(sp)
    8000133e:	e822                	sd	s0,16(sp)
    80001340:	e426                	sd	s1,8(sp)
    80001342:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	7b0080e7          	jalr	1968(ra) # 80000af4 <kalloc>
    8000134c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000134e:	c519                	beqz	a0,8000135c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001350:	6605                	lui	a2,0x1
    80001352:	4581                	li	a1,0
    80001354:	00000097          	auipc	ra,0x0
    80001358:	98c080e7          	jalr	-1652(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000135c:	8526                	mv	a0,s1
    8000135e:	60e2                	ld	ra,24(sp)
    80001360:	6442                	ld	s0,16(sp)
    80001362:	64a2                	ld	s1,8(sp)
    80001364:	6105                	addi	sp,sp,32
    80001366:	8082                	ret

0000000080001368 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001368:	7179                	addi	sp,sp,-48
    8000136a:	f406                	sd	ra,40(sp)
    8000136c:	f022                	sd	s0,32(sp)
    8000136e:	ec26                	sd	s1,24(sp)
    80001370:	e84a                	sd	s2,16(sp)
    80001372:	e44e                	sd	s3,8(sp)
    80001374:	e052                	sd	s4,0(sp)
    80001376:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001378:	6785                	lui	a5,0x1
    8000137a:	04f67863          	bgeu	a2,a5,800013ca <uvminit+0x62>
    8000137e:	8a2a                	mv	s4,a0
    80001380:	89ae                	mv	s3,a1
    80001382:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	770080e7          	jalr	1904(ra) # 80000af4 <kalloc>
    8000138c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000138e:	6605                	lui	a2,0x1
    80001390:	4581                	li	a1,0
    80001392:	00000097          	auipc	ra,0x0
    80001396:	94e080e7          	jalr	-1714(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000139a:	4779                	li	a4,30
    8000139c:	86ca                	mv	a3,s2
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	8552                	mv	a0,s4
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	d0c080e7          	jalr	-756(ra) # 800010b0 <mappages>
  memmove(mem, src, sz);
    800013ac:	8626                	mv	a2,s1
    800013ae:	85ce                	mv	a1,s3
    800013b0:	854a                	mv	a0,s2
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	98e080e7          	jalr	-1650(ra) # 80000d40 <memmove>
}
    800013ba:	70a2                	ld	ra,40(sp)
    800013bc:	7402                	ld	s0,32(sp)
    800013be:	64e2                	ld	s1,24(sp)
    800013c0:	6942                	ld	s2,16(sp)
    800013c2:	69a2                	ld	s3,8(sp)
    800013c4:	6a02                	ld	s4,0(sp)
    800013c6:	6145                	addi	sp,sp,48
    800013c8:	8082                	ret
    panic("inituvm: more than a page");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d8e50513          	addi	a0,a0,-626 # 80008158 <digits+0x118>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>

00000000800013da <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013da:	1101                	addi	sp,sp,-32
    800013dc:	ec06                	sd	ra,24(sp)
    800013de:	e822                	sd	s0,16(sp)
    800013e0:	e426                	sd	s1,8(sp)
    800013e2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e6:	00b67d63          	bgeu	a2,a1,80001400 <uvmdealloc+0x26>
    800013ea:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ec:	6785                	lui	a5,0x1
    800013ee:	17fd                	addi	a5,a5,-1
    800013f0:	00f60733          	add	a4,a2,a5
    800013f4:	767d                	lui	a2,0xfffff
    800013f6:	8f71                	and	a4,a4,a2
    800013f8:	97ae                	add	a5,a5,a1
    800013fa:	8ff1                	and	a5,a5,a2
    800013fc:	00f76863          	bltu	a4,a5,8000140c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140c:	8f99                	sub	a5,a5,a4
    8000140e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001410:	4685                	li	a3,1
    80001412:	0007861b          	sext.w	a2,a5
    80001416:	85ba                	mv	a1,a4
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	e5e080e7          	jalr	-418(ra) # 80001276 <uvmunmap>
    80001420:	b7c5                	j	80001400 <uvmdealloc+0x26>

0000000080001422 <uvmalloc>:
  if(newsz < oldsz)
    80001422:	0ab66163          	bltu	a2,a1,800014c4 <uvmalloc+0xa2>
{
    80001426:	7139                	addi	sp,sp,-64
    80001428:	fc06                	sd	ra,56(sp)
    8000142a:	f822                	sd	s0,48(sp)
    8000142c:	f426                	sd	s1,40(sp)
    8000142e:	f04a                	sd	s2,32(sp)
    80001430:	ec4e                	sd	s3,24(sp)
    80001432:	e852                	sd	s4,16(sp)
    80001434:	e456                	sd	s5,8(sp)
    80001436:	0080                	addi	s0,sp,64
    80001438:	8aaa                	mv	s5,a0
    8000143a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000143c:	6985                	lui	s3,0x1
    8000143e:	19fd                	addi	s3,s3,-1
    80001440:	95ce                	add	a1,a1,s3
    80001442:	79fd                	lui	s3,0xfffff
    80001444:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001448:	08c9f063          	bgeu	s3,a2,800014c8 <uvmalloc+0xa6>
    8000144c:	894e                	mv	s2,s3
    mem = kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	6a6080e7          	jalr	1702(ra) # 80000af4 <kalloc>
    80001456:	84aa                	mv	s1,a0
    if(mem == 0){
    80001458:	c51d                	beqz	a0,80001486 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	882080e7          	jalr	-1918(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001466:	4779                	li	a4,30
    80001468:	86a6                	mv	a3,s1
    8000146a:	6605                	lui	a2,0x1
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	c40080e7          	jalr	-960(ra) # 800010b0 <mappages>
    80001478:	e905                	bnez	a0,800014a8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147a:	6785                	lui	a5,0x1
    8000147c:	993e                	add	s2,s2,a5
    8000147e:	fd4968e3          	bltu	s2,s4,8000144e <uvmalloc+0x2c>
  return newsz;
    80001482:	8552                	mv	a0,s4
    80001484:	a809                	j	80001496 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001486:	864e                	mv	a2,s3
    80001488:	85ca                	mv	a1,s2
    8000148a:	8556                	mv	a0,s5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f4e080e7          	jalr	-178(ra) # 800013da <uvmdealloc>
      return 0;
    80001494:	4501                	li	a0,0
}
    80001496:	70e2                	ld	ra,56(sp)
    80001498:	7442                	ld	s0,48(sp)
    8000149a:	74a2                	ld	s1,40(sp)
    8000149c:	7902                	ld	s2,32(sp)
    8000149e:	69e2                	ld	s3,24(sp)
    800014a0:	6a42                	ld	s4,16(sp)
    800014a2:	6aa2                	ld	s5,8(sp)
    800014a4:	6121                	addi	sp,sp,64
    800014a6:	8082                	ret
      kfree(mem);
    800014a8:	8526                	mv	a0,s1
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	54e080e7          	jalr	1358(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f22080e7          	jalr	-222(ra) # 800013da <uvmdealloc>
      return 0;
    800014c0:	4501                	li	a0,0
    800014c2:	bfd1                	j	80001496 <uvmalloc+0x74>
    return oldsz;
    800014c4:	852e                	mv	a0,a1
}
    800014c6:	8082                	ret
  return newsz;
    800014c8:	8532                	mv	a0,a2
    800014ca:	b7f1                	j	80001496 <uvmalloc+0x74>

00000000800014cc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014cc:	7179                	addi	sp,sp,-48
    800014ce:	f406                	sd	ra,40(sp)
    800014d0:	f022                	sd	s0,32(sp)
    800014d2:	ec26                	sd	s1,24(sp)
    800014d4:	e84a                	sd	s2,16(sp)
    800014d6:	e44e                	sd	s3,8(sp)
    800014d8:	e052                	sd	s4,0(sp)
    800014da:	1800                	addi	s0,sp,48
    800014dc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014de:	84aa                	mv	s1,a0
    800014e0:	6905                	lui	s2,0x1
    800014e2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	4985                	li	s3,1
    800014e6:	a821                	j	800014fe <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ea:	0532                	slli	a0,a0,0xc
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	fe0080e7          	jalr	-32(ra) # 800014cc <freewalk>
      pagetable[i] = 0;
    800014f4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f8:	04a1                	addi	s1,s1,8
    800014fa:	03248163          	beq	s1,s2,8000151c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fe:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001500:	00f57793          	andi	a5,a0,15
    80001504:	ff3782e3          	beq	a5,s3,800014e8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001508:	8905                	andi	a0,a0,1
    8000150a:	d57d                	beqz	a0,800014f8 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c6c50513          	addi	a0,a0,-916 # 80008178 <digits+0x138>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	02a080e7          	jalr	42(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151c:	8552                	mv	a0,s4
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	4da080e7          	jalr	1242(ra) # 800009f8 <kfree>
}
    80001526:	70a2                	ld	ra,40(sp)
    80001528:	7402                	ld	s0,32(sp)
    8000152a:	64e2                	ld	s1,24(sp)
    8000152c:	6942                	ld	s2,16(sp)
    8000152e:	69a2                	ld	s3,8(sp)
    80001530:	6a02                	ld	s4,0(sp)
    80001532:	6145                	addi	sp,sp,48
    80001534:	8082                	ret

0000000080001536 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001536:	1101                	addi	sp,sp,-32
    80001538:	ec06                	sd	ra,24(sp)
    8000153a:	e822                	sd	s0,16(sp)
    8000153c:	e426                	sd	s1,8(sp)
    8000153e:	1000                	addi	s0,sp,32
    80001540:	84aa                	mv	s1,a0
  if(sz > 0)
    80001542:	e999                	bnez	a1,80001558 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001544:	8526                	mv	a0,s1
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	f86080e7          	jalr	-122(ra) # 800014cc <freewalk>
}
    8000154e:	60e2                	ld	ra,24(sp)
    80001550:	6442                	ld	s0,16(sp)
    80001552:	64a2                	ld	s1,8(sp)
    80001554:	6105                	addi	sp,sp,32
    80001556:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001558:	6605                	lui	a2,0x1
    8000155a:	167d                	addi	a2,a2,-1
    8000155c:	962e                	add	a2,a2,a1
    8000155e:	4685                	li	a3,1
    80001560:	8231                	srli	a2,a2,0xc
    80001562:	4581                	li	a1,0
    80001564:	00000097          	auipc	ra,0x0
    80001568:	d12080e7          	jalr	-750(ra) # 80001276 <uvmunmap>
    8000156c:	bfe1                	j	80001544 <uvmfree+0xe>

000000008000156e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156e:	c679                	beqz	a2,8000163c <uvmcopy+0xce>
{
    80001570:	715d                	addi	sp,sp,-80
    80001572:	e486                	sd	ra,72(sp)
    80001574:	e0a2                	sd	s0,64(sp)
    80001576:	fc26                	sd	s1,56(sp)
    80001578:	f84a                	sd	s2,48(sp)
    8000157a:	f44e                	sd	s3,40(sp)
    8000157c:	f052                	sd	s4,32(sp)
    8000157e:	ec56                	sd	s5,24(sp)
    80001580:	e85a                	sd	s6,16(sp)
    80001582:	e45e                	sd	s7,8(sp)
    80001584:	0880                	addi	s0,sp,80
    80001586:	8b2a                	mv	s6,a0
    80001588:	8aae                	mv	s5,a1
    8000158a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158e:	4601                	li	a2,0
    80001590:	85ce                	mv	a1,s3
    80001592:	855a                	mv	a0,s6
    80001594:	00000097          	auipc	ra,0x0
    80001598:	a34080e7          	jalr	-1484(ra) # 80000fc8 <walk>
    8000159c:	c531                	beqz	a0,800015e8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159e:	6118                	ld	a4,0(a0)
    800015a0:	00177793          	andi	a5,a4,1
    800015a4:	cbb1                	beqz	a5,800015f8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a6:	00a75593          	srli	a1,a4,0xa
    800015aa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ae:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	542080e7          	jalr	1346(ra) # 80000af4 <kalloc>
    800015ba:	892a                	mv	s2,a0
    800015bc:	c939                	beqz	a0,80001612 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015be:	6605                	lui	a2,0x1
    800015c0:	85de                	mv	a1,s7
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	77e080e7          	jalr	1918(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ca:	8726                	mv	a4,s1
    800015cc:	86ca                	mv	a3,s2
    800015ce:	6605                	lui	a2,0x1
    800015d0:	85ce                	mv	a1,s3
    800015d2:	8556                	mv	a0,s5
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	adc080e7          	jalr	-1316(ra) # 800010b0 <mappages>
    800015dc:	e515                	bnez	a0,80001608 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015de:	6785                	lui	a5,0x1
    800015e0:	99be                	add	s3,s3,a5
    800015e2:	fb49e6e3          	bltu	s3,s4,8000158e <uvmcopy+0x20>
    800015e6:	a081                	j	80001626 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	ba050513          	addi	a0,a0,-1120 # 80008188 <digits+0x148>
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	f4e080e7          	jalr	-178(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb050513          	addi	a0,a0,-1104 # 800081a8 <digits+0x168>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
      kfree(mem);
    80001608:	854a                	mv	a0,s2
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3ee080e7          	jalr	1006(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001612:	4685                	li	a3,1
    80001614:	00c9d613          	srli	a2,s3,0xc
    80001618:	4581                	li	a1,0
    8000161a:	8556                	mv	a0,s5
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	c5a080e7          	jalr	-934(ra) # 80001276 <uvmunmap>
  return -1;
    80001624:	557d                	li	a0,-1
}
    80001626:	60a6                	ld	ra,72(sp)
    80001628:	6406                	ld	s0,64(sp)
    8000162a:	74e2                	ld	s1,56(sp)
    8000162c:	7942                	ld	s2,48(sp)
    8000162e:	79a2                	ld	s3,40(sp)
    80001630:	7a02                	ld	s4,32(sp)
    80001632:	6ae2                	ld	s5,24(sp)
    80001634:	6b42                	ld	s6,16(sp)
    80001636:	6ba2                	ld	s7,8(sp)
    80001638:	6161                	addi	sp,sp,80
    8000163a:	8082                	ret
  return 0;
    8000163c:	4501                	li	a0,0
}
    8000163e:	8082                	ret

0000000080001640 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001640:	1141                	addi	sp,sp,-16
    80001642:	e406                	sd	ra,8(sp)
    80001644:	e022                	sd	s0,0(sp)
    80001646:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001648:	4601                	li	a2,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	97e080e7          	jalr	-1666(ra) # 80000fc8 <walk>
  if(pte == 0)
    80001652:	c901                	beqz	a0,80001662 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001654:	611c                	ld	a5,0(a0)
    80001656:	9bbd                	andi	a5,a5,-17
    80001658:	e11c                	sd	a5,0(a0)
}
    8000165a:	60a2                	ld	ra,8(sp)
    8000165c:	6402                	ld	s0,0(sp)
    8000165e:	0141                	addi	sp,sp,16
    80001660:	8082                	ret
    panic("uvmclear");
    80001662:	00007517          	auipc	a0,0x7
    80001666:	b6650513          	addi	a0,a0,-1178 # 800081c8 <digits+0x188>
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080001672 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001672:	c6bd                	beqz	a3,800016e0 <copyout+0x6e>
{
    80001674:	715d                	addi	sp,sp,-80
    80001676:	e486                	sd	ra,72(sp)
    80001678:	e0a2                	sd	s0,64(sp)
    8000167a:	fc26                	sd	s1,56(sp)
    8000167c:	f84a                	sd	s2,48(sp)
    8000167e:	f44e                	sd	s3,40(sp)
    80001680:	f052                	sd	s4,32(sp)
    80001682:	ec56                	sd	s5,24(sp)
    80001684:	e85a                	sd	s6,16(sp)
    80001686:	e45e                	sd	s7,8(sp)
    80001688:	e062                	sd	s8,0(sp)
    8000168a:	0880                	addi	s0,sp,80
    8000168c:	8b2a                	mv	s6,a0
    8000168e:	8c2e                	mv	s8,a1
    80001690:	8a32                	mv	s4,a2
    80001692:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001694:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001696:	6a85                	lui	s5,0x1
    80001698:	a015                	j	800016bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000169a:	9562                	add	a0,a0,s8
    8000169c:	0004861b          	sext.w	a2,s1
    800016a0:	85d2                	mv	a1,s4
    800016a2:	41250533          	sub	a0,a0,s2
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	69a080e7          	jalr	1690(ra) # 80000d40 <memmove>

    len -= n;
    800016ae:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b8:	02098263          	beqz	s3,800016dc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c0:	85ca                	mv	a1,s2
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	9aa080e7          	jalr	-1622(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800016cc:	cd01                	beqz	a0,800016e4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ce:	418904b3          	sub	s1,s2,s8
    800016d2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d4:	fc99f3e3          	bgeu	s3,s1,8000169a <copyout+0x28>
    800016d8:	84ce                	mv	s1,s3
    800016da:	b7c1                	j	8000169a <copyout+0x28>
  }
  return 0;
    800016dc:	4501                	li	a0,0
    800016de:	a021                	j	800016e6 <copyout+0x74>
    800016e0:	4501                	li	a0,0
}
    800016e2:	8082                	ret
      return -1;
    800016e4:	557d                	li	a0,-1
}
    800016e6:	60a6                	ld	ra,72(sp)
    800016e8:	6406                	ld	s0,64(sp)
    800016ea:	74e2                	ld	s1,56(sp)
    800016ec:	7942                	ld	s2,48(sp)
    800016ee:	79a2                	ld	s3,40(sp)
    800016f0:	7a02                	ld	s4,32(sp)
    800016f2:	6ae2                	ld	s5,24(sp)
    800016f4:	6b42                	ld	s6,16(sp)
    800016f6:	6ba2                	ld	s7,8(sp)
    800016f8:	6c02                	ld	s8,0(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret

00000000800016fe <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fe:	c6bd                	beqz	a3,8000176c <copyin+0x6e>
{
    80001700:	715d                	addi	sp,sp,-80
    80001702:	e486                	sd	ra,72(sp)
    80001704:	e0a2                	sd	s0,64(sp)
    80001706:	fc26                	sd	s1,56(sp)
    80001708:	f84a                	sd	s2,48(sp)
    8000170a:	f44e                	sd	s3,40(sp)
    8000170c:	f052                	sd	s4,32(sp)
    8000170e:	ec56                	sd	s5,24(sp)
    80001710:	e85a                	sd	s6,16(sp)
    80001712:	e45e                	sd	s7,8(sp)
    80001714:	e062                	sd	s8,0(sp)
    80001716:	0880                	addi	s0,sp,80
    80001718:	8b2a                	mv	s6,a0
    8000171a:	8a2e                	mv	s4,a1
    8000171c:	8c32                	mv	s8,a2
    8000171e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001720:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001722:	6a85                	lui	s5,0x1
    80001724:	a015                	j	80001748 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001726:	9562                	add	a0,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412505b3          	sub	a1,a0,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	60e080e7          	jalr	1550(ra) # 80000d40 <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	91e080e7          	jalr	-1762(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f3e3          	bgeu	s3,s1,80001726 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	b7c1                	j	80001726 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x74>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	88c080e7          	jalr	-1908(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <set_next_to_last>:

//Modify lists - start

int
set_next_to_last(struct proc *proc_to_add)
{
    8000183e:	1101                	addi	sp,sp,-32
    80001840:	ec06                	sd	ra,24(sp)
    80001842:	e822                	sd	s0,16(sp)
    80001844:	e426                	sd	s1,8(sp)
    80001846:	e04a                	sd	s2,0(sp)
    80001848:	1000                	addi	s0,sp,32
    8000184a:	84aa                	mv	s1,a0
  int curr_index;
    do{ 
    curr_index = (proc_to_add)->nextIndex;
  } while(cas(&((proc_to_add)->nextIndex), curr_index, -1));
    8000184c:	05850913          	addi	s2,a0,88
    80001850:	567d                	li	a2,-1
    80001852:	4cac                	lw	a1,88(s1)
    80001854:	854a                	mv	a0,s2
    80001856:	00005097          	auipc	ra,0x5
    8000185a:	120080e7          	jalr	288(ra) # 80006976 <cas>
    8000185e:	f96d                	bnez	a0,80001850 <set_next_to_last+0x12>
  return 1;
}
    80001860:	4505                	li	a0,1
    80001862:	60e2                	ld	ra,24(sp)
    80001864:	6442                	ld	s0,16(sp)
    80001866:	64a2                	ld	s1,8(sp)
    80001868:	6902                	ld	s2,0(sp)
    8000186a:	6105                	addi	sp,sp,32
    8000186c:	8082                	ret

000000008000186e <add_to_ls>:

int
add_to_ls(int cpuID, int *proc_ls, int new_proc_index){
    8000186e:	711d                	addi	sp,sp,-96
    80001870:	ec86                	sd	ra,88(sp)
    80001872:	e8a2                	sd	s0,80(sp)
    80001874:	e4a6                	sd	s1,72(sp)
    80001876:	e0ca                	sd	s2,64(sp)
    80001878:	fc4e                	sd	s3,56(sp)
    8000187a:	f852                	sd	s4,48(sp)
    8000187c:	f456                	sd	s5,40(sp)
    8000187e:	f05a                	sd	s6,32(sp)
    80001880:	ec5e                	sd	s7,24(sp)
    80001882:	e862                	sd	s8,16(sp)
    80001884:	e466                	sd	s9,8(sp)
    80001886:	1080                	addi	s0,sp,96
    80001888:	892a                	mv	s2,a0
    8000188a:	8c2e                	mv	s8,a1
    8000188c:	8b32                	mv	s6,a2

  int next_index, curr_index;
  struct proc *proc_to_add = proc + new_proc_index;
    8000188e:	19000b93          	li	s7,400
    80001892:	03760bb3          	mul	s7,a2,s7
    80001896:	00010797          	auipc	a5,0x10
    8000189a:	eaa78793          	addi	a5,a5,-342 # 80011740 <proc>
    8000189e:	9bbe                	add	s7,s7,a5

    do{
      curr_index = proc_to_add->cpu_num;
    } while(cpuID > -1 && cas(&((proc_to_add)->cpu_num), curr_index, cpuID));
    800018a0:	050b8493          	addi	s1,s7,80 # fffffffffffff050 <end+0xffffffff7ffd9050>
      curr_index = proc_to_add->cpu_num;
    800018a4:	050ba583          	lw	a1,80(s7)
    } while(cpuID > -1 && cas(&((proc_to_add)->cpu_num), curr_index, cpuID));
    800018a8:	00094963          	bltz	s2,800018ba <add_to_ls+0x4c>
    800018ac:	864a                	mv	a2,s2
    800018ae:	8526                	mv	a0,s1
    800018b0:	00005097          	auipc	ra,0x5
    800018b4:	0c6080e7          	jalr	198(ra) # 80006976 <cas>
    800018b8:	f575                	bnez	a0,800018a4 <add_to_ls+0x36>
  

  if(*proc_ls == -1){ // ls empty
    800018ba:	000c2703          	lw	a4,0(s8)
    800018be:	57fd                	li	a5,-1
    800018c0:	00f70d63          	beq	a4,a5,800018da <add_to_ls+0x6c>
    { set_next_to_last(proc_to_add);
      return 1;
    }
  }

  next_index = *proc_ls;
    800018c4:	000c2483          	lw	s1,0(s8)
  do{ 
    curr_index = next_index;
    if(curr_index != -1 && (proc + curr_index)->canDelete == 1) return add_to_ls(cpuID,proc_ls,new_proc_index);
    800018c8:	59fd                	li	s3,-1
    800018ca:	19000a93          	li	s5,400
    800018ce:	00010a17          	auipc	s4,0x10
    800018d2:	e72a0a13          	addi	s4,s4,-398 # 80011740 <proc>
    800018d6:	4c85                	li	s9,1
    800018d8:	a0b1                	j	80001924 <add_to_ls+0xb6>
    } while(*proc_ls == -1 && cas(proc_ls, curr_index, new_proc_index));
    800018da:	865a                	mv	a2,s6
    800018dc:	55fd                	li	a1,-1
    800018de:	8562                	mv	a0,s8
    800018e0:	00005097          	auipc	ra,0x5
    800018e4:	096080e7          	jalr	150(ra) # 80006976 <cas>
    800018e8:	c511                	beqz	a0,800018f4 <add_to_ls+0x86>
    800018ea:	000c2703          	lw	a4,0(s8)
    800018ee:	57fd                	li	a5,-1
    800018f0:	fef705e3          	beq	a4,a5,800018da <add_to_ls+0x6c>
    if(*proc_ls == new_proc_index) 
    800018f4:	000c2783          	lw	a5,0(s8)
    800018f8:	fd6796e3          	bne	a5,s6,800018c4 <add_to_ls+0x56>
    { set_next_to_last(proc_to_add);
    800018fc:	855e                	mv	a0,s7
    800018fe:	00000097          	auipc	ra,0x0
    80001902:	f40080e7          	jalr	-192(ra) # 8000183e <set_next_to_last>
      return 1;
    80001906:	4505                	li	a0,1
    80001908:	a0a1                	j	80001950 <add_to_ls+0xe2>
    next_index = (proc + curr_index)->nextIndex;
    8000190a:	03548533          	mul	a0,s1,s5
    8000190e:	9552                	add	a0,a0,s4
    80001910:	4d24                	lw	s1,88(a0)
  } while(cas(&((proc + curr_index)->nextIndex), -1, new_proc_index));
    80001912:	865a                	mv	a2,s6
    80001914:	85ce                	mv	a1,s3
    80001916:	05850513          	addi	a0,a0,88
    8000191a:	00005097          	auipc	ra,0x5
    8000191e:	05c080e7          	jalr	92(ra) # 80006976 <cas>
    80001922:	c10d                	beqz	a0,80001944 <add_to_ls+0xd6>
    if(curr_index != -1 && (proc + curr_index)->canDelete == 1) return add_to_ls(cpuID,proc_ls,new_proc_index);
    80001924:	ff3483e3          	beq	s1,s3,8000190a <add_to_ls+0x9c>
    80001928:	035487b3          	mul	a5,s1,s5
    8000192c:	97d2                	add	a5,a5,s4
    8000192e:	47fc                	lw	a5,76(a5)
    80001930:	fd979de3          	bne	a5,s9,8000190a <add_to_ls+0x9c>
    80001934:	865a                	mv	a2,s6
    80001936:	85e2                	mv	a1,s8
    80001938:	854a                	mv	a0,s2
    8000193a:	00000097          	auipc	ra,0x0
    8000193e:	f34080e7          	jalr	-204(ra) # 8000186e <add_to_ls>
    80001942:	a039                	j	80001950 <add_to_ls+0xe2>

  set_next_to_last(proc_to_add);
    80001944:	855e                	mv	a0,s7
    80001946:	00000097          	auipc	ra,0x0
    8000194a:	ef8080e7          	jalr	-264(ra) # 8000183e <set_next_to_last>
  return 1;
    8000194e:	4505                	li	a0,1
}
    80001950:	60e6                	ld	ra,88(sp)
    80001952:	6446                	ld	s0,80(sp)
    80001954:	64a6                	ld	s1,72(sp)
    80001956:	6906                	ld	s2,64(sp)
    80001958:	79e2                	ld	s3,56(sp)
    8000195a:	7a42                	ld	s4,48(sp)
    8000195c:	7aa2                	ld	s5,40(sp)
    8000195e:	7b02                	ld	s6,32(sp)
    80001960:	6be2                	ld	s7,24(sp)
    80001962:	6c42                	ld	s8,16(sp)
    80001964:	6ca2                	ld	s9,8(sp)
    80001966:	6125                	addi	sp,sp,96
    80001968:	8082                	ret

000000008000196a <set_can_be_deleted>:

int
set_can_be_deleted(struct proc *proc_to_remove)
{
    8000196a:	1101                	addi	sp,sp,-32
    8000196c:	ec06                	sd	ra,24(sp)
    8000196e:	e822                	sd	s0,16(sp)
    80001970:	e426                	sd	s1,8(sp)
    80001972:	e04a                	sd	s2,0(sp)
    80001974:	1000                	addi	s0,sp,32
    80001976:	84aa                	mv	s1,a0
  int delFlag;
  do{
    delFlag = (proc_to_remove)->canDelete;
  } while(cas(&((proc_to_remove)->canDelete), delFlag, 0)) ;
    80001978:	04c50913          	addi	s2,a0,76
    8000197c:	4601                	li	a2,0
    8000197e:	44ec                	lw	a1,76(s1)
    80001980:	854a                	mv	a0,s2
    80001982:	00005097          	auipc	ra,0x5
    80001986:	ff4080e7          	jalr	-12(ra) # 80006976 <cas>
    8000198a:	f96d                	bnez	a0,8000197c <set_can_be_deleted+0x12>
  return 0;

}
    8000198c:	60e2                	ld	ra,24(sp)
    8000198e:	6442                	ld	s0,16(sp)
    80001990:	64a2                	ld	s1,8(sp)
    80001992:	6902                	ld	s2,0(sp)
    80001994:	6105                	addi	sp,sp,32
    80001996:	8082                	ret

0000000080001998 <remove_from_ls>:

int
remove_from_ls(int *proc_ls, int remove_index){
    80001998:	711d                	addi	sp,sp,-96
    8000199a:	ec86                	sd	ra,88(sp)
    8000199c:	e8a2                	sd	s0,80(sp)
    8000199e:	e4a6                	sd	s1,72(sp)
    800019a0:	e0ca                	sd	s2,64(sp)
    800019a2:	fc4e                	sd	s3,56(sp)
    800019a4:	f852                	sd	s4,48(sp)
    800019a6:	f456                	sd	s5,40(sp)
    800019a8:	f05a                	sd	s6,32(sp)
    800019aa:	ec5e                	sd	s7,24(sp)
    800019ac:	e862                	sd	s8,16(sp)
    800019ae:	e466                	sd	s9,8(sp)
    800019b0:	1080                	addi	s0,sp,96
  int res,delFlag, curr_link, prev_link, next_link;
  struct proc *proc_to_remove = proc + remove_index;
    800019b2:	19000913          	li	s2,400
    800019b6:	03258933          	mul	s2,a1,s2
    800019ba:	00010797          	auipc	a5,0x10
    800019be:	d8678793          	addi	a5,a5,-634 # 80011740 <proc>
    800019c2:	993e                	add	s2,s2,a5

  res = 0;
  if (*proc_ls == -1) { // ls empty
    800019c4:	4118                	lw	a4,0(a0)
    800019c6:	57fd                	li	a5,-1
    return 0;
    800019c8:	4481                	li	s1,0
  if (*proc_ls == -1) { // ls empty
    800019ca:	0cf70563          	beq	a4,a5,80001a94 <remove_from_ls+0xfc>
    800019ce:	8b2a                	mv	s6,a0
    800019d0:	89ae                	mv	s3,a1
  }

  if((proc_to_remove)->canDelete == 1) return 0;
    800019d2:	04c92703          	lw	a4,76(s2) # 104c <_entry-0x7fffefb4>
    800019d6:	4785                	li	a5,1
    800019d8:	4481                	li	s1,0
    800019da:	0af70d63          	beq	a4,a5,80001a94 <remove_from_ls+0xfc>

  do{
    delFlag = (proc_to_remove)->canDelete;
  } while(cas(&((proc_to_remove)->canDelete), delFlag, 1)) ;
    800019de:	04c90493          	addi	s1,s2,76
    800019e2:	4605                	li	a2,1
    800019e4:	04c92583          	lw	a1,76(s2)
    800019e8:	8526                	mv	a0,s1
    800019ea:	00005097          	auipc	ra,0x5
    800019ee:	f8c080e7          	jalr	-116(ra) # 80006976 <cas>
    800019f2:	f965                	bnez	a0,800019e2 <remove_from_ls+0x4a>

  if(*proc_ls == remove_index){ 
    800019f4:	000b2783          	lw	a5,0(s6) # 1000 <_entry-0x7ffff000>
    800019f8:	01378d63          	beq	a5,s3,80001a12 <remove_from_ls+0x7a>
      set_can_be_deleted(proc_to_remove);
      return res;
    } 
  }

  curr_link = *proc_ls;
    800019fc:	000b2483          	lw	s1,0(s6)
  do {
    prev_link = curr_link;
    if(prev_link != remove_index && (proc + prev_link)->canDelete == 1) return remove_from_ls(proc_ls,remove_index);
    80001a00:	19000a93          	li	s5,400
    80001a04:	00010a17          	auipc	s4,0x10
    80001a08:	d3ca0a13          	addi	s4,s4,-708 # 80011740 <proc>
    80001a0c:	4c05                	li	s8,1
    curr_link = (proc + prev_link)->nextIndex;
  } while(cas(&((proc + prev_link)->nextIndex), remove_index, (proc_to_remove)->nextIndex) 
          && prev_link != -1) ;
    80001a0e:	5bfd                	li	s7,-1
    80001a10:	a891                	j	80001a64 <remove_from_ls+0xcc>
    } while(!cas(proc_ls, remove_index, next_link)) ;
    80001a12:	05892603          	lw	a2,88(s2)
    80001a16:	85ce                	mv	a1,s3
    80001a18:	855a                	mv	a0,s6
    80001a1a:	00005097          	auipc	ra,0x5
    80001a1e:	f5c080e7          	jalr	-164(ra) # 80006976 <cas>
    80001a22:	d965                	beqz	a0,80001a12 <remove_from_ls+0x7a>
    if(*proc_ls == (proc_to_remove)->nextIndex){
    80001a24:	000b2703          	lw	a4,0(s6)
    80001a28:	05892783          	lw	a5,88(s2)
    80001a2c:	fcf718e3          	bne	a4,a5,800019fc <remove_from_ls+0x64>
      res = remove_index + 1;
    80001a30:	0019849b          	addiw	s1,s3,1
      set_can_be_deleted(proc_to_remove);
    80001a34:	854a                	mv	a0,s2
    80001a36:	00000097          	auipc	ra,0x0
    80001a3a:	f34080e7          	jalr	-204(ra) # 8000196a <set_can_be_deleted>
      return res;
    80001a3e:	a899                	j	80001a94 <remove_from_ls+0xfc>
    curr_link = (proc + prev_link)->nextIndex;
    80001a40:	03548533          	mul	a0,s1,s5
    80001a44:	9552                	add	a0,a0,s4
    80001a46:	05852c83          	lw	s9,88(a0)
  } while(cas(&((proc + prev_link)->nextIndex), remove_index, (proc_to_remove)->nextIndex) 
    80001a4a:	05892603          	lw	a2,88(s2)
    80001a4e:	85ce                	mv	a1,s3
    80001a50:	05850513          	addi	a0,a0,88
    80001a54:	00005097          	auipc	ra,0x5
    80001a58:	f22080e7          	jalr	-222(ra) # 80006976 <cas>
          && prev_link != -1) ;
    80001a5c:	c505                	beqz	a0,80001a84 <remove_from_ls+0xec>
    80001a5e:	05748963          	beq	s1,s7,80001ab0 <remove_from_ls+0x118>
    curr_link = (proc + prev_link)->nextIndex;
    80001a62:	84e6                	mv	s1,s9
    if(prev_link != remove_index && (proc + prev_link)->canDelete == 1) return remove_from_ls(proc_ls,remove_index);
    80001a64:	fd348ee3          	beq	s1,s3,80001a40 <remove_from_ls+0xa8>
    80001a68:	035487b3          	mul	a5,s1,s5
    80001a6c:	97d2                	add	a5,a5,s4
    80001a6e:	47fc                	lw	a5,76(a5)
    80001a70:	fd8798e3          	bne	a5,s8,80001a40 <remove_from_ls+0xa8>
    80001a74:	85ce                	mv	a1,s3
    80001a76:	855a                	mv	a0,s6
    80001a78:	00000097          	auipc	ra,0x0
    80001a7c:	f20080e7          	jalr	-224(ra) # 80001998 <remove_from_ls>
    80001a80:	84aa                	mv	s1,a0
    80001a82:	a809                	j	80001a94 <remove_from_ls+0xfc>

  if (prev_link == -1){ // <proc_to_remove> isn't in the list
    80001a84:	57fd                	li	a5,-1
    80001a86:	02f48563          	beq	s1,a5,80001ab0 <remove_from_ls+0x118>
    res = 0;
    set_can_be_deleted(proc_to_remove);
    return res;
  }

  res = remove_index+1;
    80001a8a:	0019849b          	addiw	s1,s3,1
  if(proc_to_remove->canDelete == 0)
    80001a8e:	04c92783          	lw	a5,76(s2)
    80001a92:	e795                	bnez	a5,80001abe <remove_from_ls+0x126>
    return res;
  set_can_be_deleted(proc_to_remove);
  return res;
}
    80001a94:	8526                	mv	a0,s1
    80001a96:	60e6                	ld	ra,88(sp)
    80001a98:	6446                	ld	s0,80(sp)
    80001a9a:	64a6                	ld	s1,72(sp)
    80001a9c:	6906                	ld	s2,64(sp)
    80001a9e:	79e2                	ld	s3,56(sp)
    80001aa0:	7a42                	ld	s4,48(sp)
    80001aa2:	7aa2                	ld	s5,40(sp)
    80001aa4:	7b02                	ld	s6,32(sp)
    80001aa6:	6be2                	ld	s7,24(sp)
    80001aa8:	6c42                	ld	s8,16(sp)
    80001aaa:	6ca2                	ld	s9,8(sp)
    80001aac:	6125                	addi	sp,sp,96
    80001aae:	8082                	ret
    set_can_be_deleted(proc_to_remove);
    80001ab0:	854a                	mv	a0,s2
    80001ab2:	00000097          	auipc	ra,0x0
    80001ab6:	eb8080e7          	jalr	-328(ra) # 8000196a <set_can_be_deleted>
    return res;
    80001aba:	4481                	li	s1,0
    80001abc:	bfe1                	j	80001a94 <remove_from_ls+0xfc>
  set_can_be_deleted(proc_to_remove);
    80001abe:	854a                	mv	a0,s2
    80001ac0:	00000097          	auipc	ra,0x0
    80001ac4:	eaa080e7          	jalr	-342(ra) # 8000196a <set_can_be_deleted>
  return res;
    80001ac8:	b7f1                	j	80001a94 <remove_from_ls+0xfc>

0000000080001aca <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001aca:	7139                	addi	sp,sp,-64
    80001acc:	fc06                	sd	ra,56(sp)
    80001ace:	f822                	sd	s0,48(sp)
    80001ad0:	f426                	sd	s1,40(sp)
    80001ad2:	f04a                	sd	s2,32(sp)
    80001ad4:	ec4e                	sd	s3,24(sp)
    80001ad6:	e852                	sd	s4,16(sp)
    80001ad8:	e456                	sd	s5,8(sp)
    80001ada:	e05a                	sd	s6,0(sp)
    80001adc:	0080                	addi	s0,sp,64
    80001ade:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ae0:	00010497          	auipc	s1,0x10
    80001ae4:	c6048493          	addi	s1,s1,-928 # 80011740 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001ae8:	8b26                	mv	s6,s1
    80001aea:	00006a97          	auipc	s5,0x6
    80001aee:	516a8a93          	addi	s5,s5,1302 # 80008000 <etext>
    80001af2:	04000937          	lui	s2,0x4000
    80001af6:	197d                	addi	s2,s2,-1
    80001af8:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001afa:	00016a17          	auipc	s4,0x16
    80001afe:	046a0a13          	addi	s4,s4,70 # 80017b40 <tickslock>
    char *pa = kalloc();
    80001b02:	fffff097          	auipc	ra,0xfffff
    80001b06:	ff2080e7          	jalr	-14(ra) # 80000af4 <kalloc>
    80001b0a:	862a                	mv	a2,a0
    if(pa == 0)
    80001b0c:	c131                	beqz	a0,80001b50 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001b0e:	416485b3          	sub	a1,s1,s6
    80001b12:	8591                	srai	a1,a1,0x4
    80001b14:	000ab783          	ld	a5,0(s5)
    80001b18:	02f585b3          	mul	a1,a1,a5
    80001b1c:	2585                	addiw	a1,a1,1
    80001b1e:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001b22:	4719                	li	a4,6
    80001b24:	6685                	lui	a3,0x1
    80001b26:	40b905b3          	sub	a1,s2,a1
    80001b2a:	854e                	mv	a0,s3
    80001b2c:	fffff097          	auipc	ra,0xfffff
    80001b30:	624080e7          	jalr	1572(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b34:	19048493          	addi	s1,s1,400
    80001b38:	fd4495e3          	bne	s1,s4,80001b02 <proc_mapstacks+0x38>
  }
}
    80001b3c:	70e2                	ld	ra,56(sp)
    80001b3e:	7442                	ld	s0,48(sp)
    80001b40:	74a2                	ld	s1,40(sp)
    80001b42:	7902                	ld	s2,32(sp)
    80001b44:	69e2                	ld	s3,24(sp)
    80001b46:	6a42                	ld	s4,16(sp)
    80001b48:	6aa2                	ld	s5,8(sp)
    80001b4a:	6b02                	ld	s6,0(sp)
    80001b4c:	6121                	addi	sp,sp,64
    80001b4e:	8082                	ret
      panic("kalloc");
    80001b50:	00006517          	auipc	a0,0x6
    80001b54:	68850513          	addi	a0,a0,1672 # 800081d8 <digits+0x198>
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	9e6080e7          	jalr	-1562(ra) # 8000053e <panic>

0000000080001b60 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001b60:	715d                	addi	sp,sp,-80
    80001b62:	e486                	sd	ra,72(sp)
    80001b64:	e0a2                	sd	s0,64(sp)
    80001b66:	fc26                	sd	s1,56(sp)
    80001b68:	f84a                	sd	s2,48(sp)
    80001b6a:	f44e                	sd	s3,40(sp)
    80001b6c:	f052                	sd	s4,32(sp)
    80001b6e:	ec56                	sd	s5,24(sp)
    80001b70:	e85a                	sd	s6,16(sp)
    80001b72:	e45e                	sd	s7,8(sp)
    80001b74:	e062                	sd	s8,0(sp)
    80001b76:	0880                	addi	s0,sp,80

  struct proc *p;
  int i;
  unusedLS = -1;
    80001b78:	57fd                	li	a5,-1
    80001b7a:	00007717          	auipc	a4,0x7
    80001b7e:	4af72b23          	sw	a5,1206(a4) # 80009030 <unusedLS>
  sleepingLS = -1;
    80001b82:	00007717          	auipc	a4,0x7
    80001b86:	4af72523          	sw	a5,1194(a4) # 8000902c <sleepingLS>
  zombieLS = -1;
    80001b8a:	00007717          	auipc	a4,0x7
    80001b8e:	48f72f23          	sw	a5,1182(a4) # 80009028 <zombieLS>
  #ifdef ON
    flag = 1;
  #endif
  #ifdef OFF
    flag = 0;
    80001b92:	00007797          	auipc	a5,0x7
    80001b96:	4a07a123          	sw	zero,1186(a5) # 80009034 <flag>
  #endif
  initlock(&pid_lock, "nextpid");
    80001b9a:	00006597          	auipc	a1,0x6
    80001b9e:	64658593          	addi	a1,a1,1606 # 800081e0 <digits+0x1a0>
    80001ba2:	0000f517          	auipc	a0,0xf
    80001ba6:	70e50513          	addi	a0,a0,1806 # 800112b0 <pid_lock>
    80001baa:	fffff097          	auipc	ra,0xfffff
    80001bae:	faa080e7          	jalr	-86(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001bb2:	00006597          	auipc	a1,0x6
    80001bb6:	63658593          	addi	a1,a1,1590 # 800081e8 <digits+0x1a8>
    80001bba:	0000f517          	auipc	a0,0xf
    80001bbe:	70e50513          	addi	a0,a0,1806 # 800112c8 <wait_lock>
    80001bc2:	fffff097          	auipc	ra,0xfffff
    80001bc6:	f92080e7          	jalr	-110(ra) # 80000b54 <initlock>
  for(i=0; i<NCPU; i++ )
    80001bca:	0000f797          	auipc	a5,0xf
    80001bce:	71678793          	addi	a5,a5,1814 # 800112e0 <counters>
    80001bd2:	0000f717          	auipc	a4,0xf
    80001bd6:	74e70713          	addi	a4,a4,1870 # 80011320 <runnableLS>
    80001bda:	863a                	mv	a2,a4
  {
    counters[i] = 0;
    runnableLS[i] = -1;
    80001bdc:	56fd                	li	a3,-1
    counters[i] = 0;
    80001bde:	0007b023          	sd	zero,0(a5)
    runnableLS[i] = -1;
    80001be2:	c314                	sw	a3,0(a4)
  for(i=0; i<NCPU; i++ )
    80001be4:	07a1                	addi	a5,a5,8
    80001be6:	0711                	addi	a4,a4,4
    80001be8:	fec79be3          	bne	a5,a2,80001bde <procinit+0x7e>
  }
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bec:	00010497          	auipc	s1,0x10
    80001bf0:	b5448493          	addi	s1,s1,-1196 # 80011740 <proc>
    initlock(&p->lock, "proc");
    80001bf4:	00006c17          	auipc	s8,0x6
    80001bf8:	604c0c13          	addi	s8,s8,1540 # 800081f8 <digits+0x1b8>
    p->kstack = KSTACK((int) (p - proc));
    80001bfc:	8ba6                	mv	s7,s1
    80001bfe:	00006b17          	auipc	s6,0x6
    80001c02:	402b0b13          	addi	s6,s6,1026 # 80008000 <etext>
    80001c06:	040009b7          	lui	s3,0x4000
    80001c0a:	19fd                	addi	s3,s3,-1
    80001c0c:	09b2                	slli	s3,s3,0xc
    p->index = (p - proc);
    p->nextIndex = -1;
    80001c0e:	597d                	li	s2,-1
    p->cpu_num = -1;
    p->canDelete = 0;
    add_to_ls(-1, &unusedLS, p->index);
    80001c10:	00007a97          	auipc	s5,0x7
    80001c14:	420a8a93          	addi	s5,s5,1056 # 80009030 <unusedLS>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c18:	00016a17          	auipc	s4,0x16
    80001c1c:	f28a0a13          	addi	s4,s4,-216 # 80017b40 <tickslock>
    initlock(&p->lock, "proc");
    80001c20:	85e2                	mv	a1,s8
    80001c22:	8526                	mv	a0,s1
    80001c24:	fffff097          	auipc	ra,0xfffff
    80001c28:	f30080e7          	jalr	-208(ra) # 80000b54 <initlock>
    p->kstack = KSTACK((int) (p - proc));
    80001c2c:	41748633          	sub	a2,s1,s7
    80001c30:	8611                	srai	a2,a2,0x4
    80001c32:	000b3783          	ld	a5,0(s6)
    80001c36:	02f6063b          	mulw	a2,a2,a5
    80001c3a:	0016079b          	addiw	a5,a2,1
    80001c3e:	00d7979b          	slliw	a5,a5,0xd
    80001c42:	40f987b3          	sub	a5,s3,a5
    80001c46:	f4bc                	sd	a5,104(s1)
    p->index = (p - proc);
    80001c48:	c8f0                	sw	a2,84(s1)
    p->nextIndex = -1;
    80001c4a:	0524ac23          	sw	s2,88(s1)
    p->cpu_num = -1;
    80001c4e:	0524a823          	sw	s2,80(s1)
    p->canDelete = 0;
    80001c52:	0404a623          	sw	zero,76(s1)
    add_to_ls(-1, &unusedLS, p->index);
    80001c56:	85d6                	mv	a1,s5
    80001c58:	557d                	li	a0,-1
    80001c5a:	00000097          	auipc	ra,0x0
    80001c5e:	c14080e7          	jalr	-1004(ra) # 8000186e <add_to_ls>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c62:	19048493          	addi	s1,s1,400
    80001c66:	fb449de3          	bne	s1,s4,80001c20 <procinit+0xc0>
  }

}
    80001c6a:	60a6                	ld	ra,72(sp)
    80001c6c:	6406                	ld	s0,64(sp)
    80001c6e:	74e2                	ld	s1,56(sp)
    80001c70:	7942                	ld	s2,48(sp)
    80001c72:	79a2                	ld	s3,40(sp)
    80001c74:	7a02                	ld	s4,32(sp)
    80001c76:	6ae2                	ld	s5,24(sp)
    80001c78:	6b42                	ld	s6,16(sp)
    80001c7a:	6ba2                	ld	s7,8(sp)
    80001c7c:	6c02                	ld	s8,0(sp)
    80001c7e:	6161                	addi	sp,sp,80
    80001c80:	8082                	ret

0000000080001c82 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001c82:	1141                	addi	sp,sp,-16
    80001c84:	e422                	sd	s0,8(sp)
    80001c86:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001c88:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001c8a:	2501                	sext.w	a0,a0
    80001c8c:	6422                	ld	s0,8(sp)
    80001c8e:	0141                	addi	sp,sp,16
    80001c90:	8082                	ret

0000000080001c92 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001c92:	1141                	addi	sp,sp,-16
    80001c94:	e422                	sd	s0,8(sp)
    80001c96:	0800                	addi	s0,sp,16
    80001c98:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001c9a:	2781                	sext.w	a5,a5
    80001c9c:	079e                	slli	a5,a5,0x7
  return c;
}
    80001c9e:	0000f517          	auipc	a0,0xf
    80001ca2:	6a250513          	addi	a0,a0,1698 # 80011340 <cpus>
    80001ca6:	953e                	add	a0,a0,a5
    80001ca8:	6422                	ld	s0,8(sp)
    80001caa:	0141                	addi	sp,sp,16
    80001cac:	8082                	ret

0000000080001cae <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001cae:	1101                	addi	sp,sp,-32
    80001cb0:	ec06                	sd	ra,24(sp)
    80001cb2:	e822                	sd	s0,16(sp)
    80001cb4:	e426                	sd	s1,8(sp)
    80001cb6:	1000                	addi	s0,sp,32
  push_off();
    80001cb8:	fffff097          	auipc	ra,0xfffff
    80001cbc:	ee0080e7          	jalr	-288(ra) # 80000b98 <push_off>
    80001cc0:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001cc2:	2781                	sext.w	a5,a5
    80001cc4:	079e                	slli	a5,a5,0x7
    80001cc6:	0000f717          	auipc	a4,0xf
    80001cca:	5ea70713          	addi	a4,a4,1514 # 800112b0 <pid_lock>
    80001cce:	97ba                	add	a5,a5,a4
    80001cd0:	6bc4                	ld	s1,144(a5)
  pop_off();
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	f66080e7          	jalr	-154(ra) # 80000c38 <pop_off>
  return p;
}
    80001cda:	8526                	mv	a0,s1
    80001cdc:	60e2                	ld	ra,24(sp)
    80001cde:	6442                	ld	s0,16(sp)
    80001ce0:	64a2                	ld	s1,8(sp)
    80001ce2:	6105                	addi	sp,sp,32
    80001ce4:	8082                	ret

0000000080001ce6 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001ce6:	1141                	addi	sp,sp,-16
    80001ce8:	e406                	sd	ra,8(sp)
    80001cea:	e022                	sd	s0,0(sp)
    80001cec:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001cee:	00000097          	auipc	ra,0x0
    80001cf2:	fc0080e7          	jalr	-64(ra) # 80001cae <myproc>
    80001cf6:	fffff097          	auipc	ra,0xfffff
    80001cfa:	fa2080e7          	jalr	-94(ra) # 80000c98 <release>

  if (first) {
    80001cfe:	00007797          	auipc	a5,0x7
    80001d02:	b327a783          	lw	a5,-1230(a5) # 80008830 <first.1793>
    80001d06:	eb89                	bnez	a5,80001d18 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001d08:	00001097          	auipc	ra,0x1
    80001d0c:	0a2080e7          	jalr	162(ra) # 80002daa <usertrapret>
}
    80001d10:	60a2                	ld	ra,8(sp)
    80001d12:	6402                	ld	s0,0(sp)
    80001d14:	0141                	addi	sp,sp,16
    80001d16:	8082                	ret
    first = 0;
    80001d18:	00007797          	auipc	a5,0x7
    80001d1c:	b007ac23          	sw	zero,-1256(a5) # 80008830 <first.1793>
    fsinit(ROOTDEV);
    80001d20:	4505                	li	a0,1
    80001d22:	00002097          	auipc	ra,0x2
    80001d26:	e46080e7          	jalr	-442(ra) # 80003b68 <fsinit>
    80001d2a:	bff9                	j	80001d08 <forkret+0x22>

0000000080001d2c <allocpid>:
allocpid() { // Changed as required
    80001d2c:	1101                	addi	sp,sp,-32
    80001d2e:	ec06                	sd	ra,24(sp)
    80001d30:	e822                	sd	s0,16(sp)
    80001d32:	e426                	sd	s1,8(sp)
    80001d34:	e04a                	sd	s2,0(sp)
    80001d36:	1000                	addi	s0,sp,32
  push_off();
    80001d38:	fffff097          	auipc	ra,0xfffff
    80001d3c:	e60080e7          	jalr	-416(ra) # 80000b98 <push_off>
    pid = nextpid;
    80001d40:	00007917          	auipc	s2,0x7
    80001d44:	af490913          	addi	s2,s2,-1292 # 80008834 <nextpid>
    80001d48:	00092483          	lw	s1,0(s2)
  while(cas(&nextpid, pid, pid + 1));
    80001d4c:	0014861b          	addiw	a2,s1,1
    80001d50:	85a6                	mv	a1,s1
    80001d52:	854a                	mv	a0,s2
    80001d54:	00005097          	auipc	ra,0x5
    80001d58:	c22080e7          	jalr	-990(ra) # 80006976 <cas>
    80001d5c:	f575                	bnez	a0,80001d48 <allocpid+0x1c>
  pop_off();
    80001d5e:	fffff097          	auipc	ra,0xfffff
    80001d62:	eda080e7          	jalr	-294(ra) # 80000c38 <pop_off>
}
    80001d66:	8526                	mv	a0,s1
    80001d68:	60e2                	ld	ra,24(sp)
    80001d6a:	6442                	ld	s0,16(sp)
    80001d6c:	64a2                	ld	s1,8(sp)
    80001d6e:	6902                	ld	s2,0(sp)
    80001d70:	6105                	addi	sp,sp,32
    80001d72:	8082                	ret

0000000080001d74 <proc_pagetable>:
{
    80001d74:	1101                	addi	sp,sp,-32
    80001d76:	ec06                	sd	ra,24(sp)
    80001d78:	e822                	sd	s0,16(sp)
    80001d7a:	e426                	sd	s1,8(sp)
    80001d7c:	e04a                	sd	s2,0(sp)
    80001d7e:	1000                	addi	s0,sp,32
    80001d80:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001d82:	fffff097          	auipc	ra,0xfffff
    80001d86:	5b8080e7          	jalr	1464(ra) # 8000133a <uvmcreate>
    80001d8a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001d8c:	c121                	beqz	a0,80001dcc <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001d8e:	4729                	li	a4,10
    80001d90:	00005697          	auipc	a3,0x5
    80001d94:	27068693          	addi	a3,a3,624 # 80007000 <_trampoline>
    80001d98:	6605                	lui	a2,0x1
    80001d9a:	040005b7          	lui	a1,0x4000
    80001d9e:	15fd                	addi	a1,a1,-1
    80001da0:	05b2                	slli	a1,a1,0xc
    80001da2:	fffff097          	auipc	ra,0xfffff
    80001da6:	30e080e7          	jalr	782(ra) # 800010b0 <mappages>
    80001daa:	02054863          	bltz	a0,80001dda <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001dae:	4719                	li	a4,6
    80001db0:	08093683          	ld	a3,128(s2)
    80001db4:	6605                	lui	a2,0x1
    80001db6:	020005b7          	lui	a1,0x2000
    80001dba:	15fd                	addi	a1,a1,-1
    80001dbc:	05b6                	slli	a1,a1,0xd
    80001dbe:	8526                	mv	a0,s1
    80001dc0:	fffff097          	auipc	ra,0xfffff
    80001dc4:	2f0080e7          	jalr	752(ra) # 800010b0 <mappages>
    80001dc8:	02054163          	bltz	a0,80001dea <proc_pagetable+0x76>
}
    80001dcc:	8526                	mv	a0,s1
    80001dce:	60e2                	ld	ra,24(sp)
    80001dd0:	6442                	ld	s0,16(sp)
    80001dd2:	64a2                	ld	s1,8(sp)
    80001dd4:	6902                	ld	s2,0(sp)
    80001dd6:	6105                	addi	sp,sp,32
    80001dd8:	8082                	ret
    uvmfree(pagetable, 0);
    80001dda:	4581                	li	a1,0
    80001ddc:	8526                	mv	a0,s1
    80001dde:	fffff097          	auipc	ra,0xfffff
    80001de2:	758080e7          	jalr	1880(ra) # 80001536 <uvmfree>
    return 0;
    80001de6:	4481                	li	s1,0
    80001de8:	b7d5                	j	80001dcc <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001dea:	4681                	li	a3,0
    80001dec:	4605                	li	a2,1
    80001dee:	040005b7          	lui	a1,0x4000
    80001df2:	15fd                	addi	a1,a1,-1
    80001df4:	05b2                	slli	a1,a1,0xc
    80001df6:	8526                	mv	a0,s1
    80001df8:	fffff097          	auipc	ra,0xfffff
    80001dfc:	47e080e7          	jalr	1150(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001e00:	4581                	li	a1,0
    80001e02:	8526                	mv	a0,s1
    80001e04:	fffff097          	auipc	ra,0xfffff
    80001e08:	732080e7          	jalr	1842(ra) # 80001536 <uvmfree>
    return 0;
    80001e0c:	4481                	li	s1,0
    80001e0e:	bf7d                	j	80001dcc <proc_pagetable+0x58>

0000000080001e10 <proc_freepagetable>:
{
    80001e10:	1101                	addi	sp,sp,-32
    80001e12:	ec06                	sd	ra,24(sp)
    80001e14:	e822                	sd	s0,16(sp)
    80001e16:	e426                	sd	s1,8(sp)
    80001e18:	e04a                	sd	s2,0(sp)
    80001e1a:	1000                	addi	s0,sp,32
    80001e1c:	84aa                	mv	s1,a0
    80001e1e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e20:	4681                	li	a3,0
    80001e22:	4605                	li	a2,1
    80001e24:	040005b7          	lui	a1,0x4000
    80001e28:	15fd                	addi	a1,a1,-1
    80001e2a:	05b2                	slli	a1,a1,0xc
    80001e2c:	fffff097          	auipc	ra,0xfffff
    80001e30:	44a080e7          	jalr	1098(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001e34:	4681                	li	a3,0
    80001e36:	4605                	li	a2,1
    80001e38:	020005b7          	lui	a1,0x2000
    80001e3c:	15fd                	addi	a1,a1,-1
    80001e3e:	05b6                	slli	a1,a1,0xd
    80001e40:	8526                	mv	a0,s1
    80001e42:	fffff097          	auipc	ra,0xfffff
    80001e46:	434080e7          	jalr	1076(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001e4a:	85ca                	mv	a1,s2
    80001e4c:	8526                	mv	a0,s1
    80001e4e:	fffff097          	auipc	ra,0xfffff
    80001e52:	6e8080e7          	jalr	1768(ra) # 80001536 <uvmfree>
}
    80001e56:	60e2                	ld	ra,24(sp)
    80001e58:	6442                	ld	s0,16(sp)
    80001e5a:	64a2                	ld	s1,8(sp)
    80001e5c:	6902                	ld	s2,0(sp)
    80001e5e:	6105                	addi	sp,sp,32
    80001e60:	8082                	ret

0000000080001e62 <freeproc>:
freeproc(struct proc *p){
    80001e62:	1101                	addi	sp,sp,-32
    80001e64:	ec06                	sd	ra,24(sp)
    80001e66:	e822                	sd	s0,16(sp)
    80001e68:	e426                	sd	s1,8(sp)
    80001e6a:	1000                	addi	s0,sp,32
    80001e6c:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001e6e:	6148                	ld	a0,128(a0)
    80001e70:	c509                	beqz	a0,80001e7a <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001e72:	fffff097          	auipc	ra,0xfffff
    80001e76:	b86080e7          	jalr	-1146(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001e7a:	0804b023          	sd	zero,128(s1)
  if(p->pagetable)
    80001e7e:	7ca8                	ld	a0,120(s1)
    80001e80:	c511                	beqz	a0,80001e8c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001e82:	78ac                	ld	a1,112(s1)
    80001e84:	00000097          	auipc	ra,0x0
    80001e88:	f8c080e7          	jalr	-116(ra) # 80001e10 <proc_freepagetable>
  remove_from_ls(&zombieLS, p->index);
    80001e8c:	48ec                	lw	a1,84(s1)
    80001e8e:	00007517          	auipc	a0,0x7
    80001e92:	19a50513          	addi	a0,a0,410 # 80009028 <zombieLS>
    80001e96:	00000097          	auipc	ra,0x0
    80001e9a:	b02080e7          	jalr	-1278(ra) # 80001998 <remove_from_ls>
  add_to_ls(-1, &unusedLS, p->index);
    80001e9e:	48f0                	lw	a2,84(s1)
    80001ea0:	00007597          	auipc	a1,0x7
    80001ea4:	19058593          	addi	a1,a1,400 # 80009030 <unusedLS>
    80001ea8:	557d                	li	a0,-1
    80001eaa:	00000097          	auipc	ra,0x0
    80001eae:	9c4080e7          	jalr	-1596(ra) # 8000186e <add_to_ls>
  p->pagetable = 0;
    80001eb2:	0604bc23          	sd	zero,120(s1)
  p->sz = 0;
    80001eb6:	0604b823          	sd	zero,112(s1)
  p->pid = 0;
    80001eba:	0404a423          	sw	zero,72(s1)
  p->parent = 0;
    80001ebe:	0604b023          	sd	zero,96(s1)
  p->name[0] = 0;
    80001ec2:	18048023          	sb	zero,384(s1)
  p->chan = 0;
    80001ec6:	0204bc23          	sd	zero,56(s1)
  p->killed = 0;
    80001eca:	0404a023          	sw	zero,64(s1)
  p->xstate = 0;
    80001ece:	0404a223          	sw	zero,68(s1)
  p->cpu_num = -1;
    80001ed2:	57fd                	li	a5,-1
    80001ed4:	c8bc                	sw	a5,80(s1)
  p->nextIndex = -1;
    80001ed6:	ccbc                	sw	a5,88(s1)
  p->state = UNUSED;
    80001ed8:	0204a823          	sw	zero,48(s1)
  p->canDelete = 0;
    80001edc:	0404a623          	sw	zero,76(s1)
}
    80001ee0:	60e2                	ld	ra,24(sp)
    80001ee2:	6442                	ld	s0,16(sp)
    80001ee4:	64a2                	ld	s1,8(sp)
    80001ee6:	6105                	addi	sp,sp,32
    80001ee8:	8082                	ret

0000000080001eea <allocproc>:
allocproc(void){
    80001eea:	7179                	addi	sp,sp,-48
    80001eec:	f406                	sd	ra,40(sp)
    80001eee:	f022                	sd	s0,32(sp)
    80001ef0:	ec26                	sd	s1,24(sp)
    80001ef2:	e84a                	sd	s2,16(sp)
    80001ef4:	e44e                	sd	s3,8(sp)
    80001ef6:	1800                	addi	s0,sp,48
  if(unusedLS == -1){ // No free entry
    80001ef8:	00007917          	auipc	s2,0x7
    80001efc:	13892903          	lw	s2,312(s2) # 80009030 <unusedLS>
    80001f00:	57fd                	li	a5,-1
    80001f02:	0cf90a63          	beq	s2,a5,80001fd6 <allocproc+0xec>
  if(remove_from_ls(&unusedLS, unusedLS) > 0){
    80001f06:	85ca                	mv	a1,s2
    80001f08:	00007517          	auipc	a0,0x7
    80001f0c:	12850513          	addi	a0,a0,296 # 80009030 <unusedLS>
    80001f10:	00000097          	auipc	ra,0x0
    80001f14:	a88080e7          	jalr	-1400(ra) # 80001998 <remove_from_ls>
  return 0;
    80001f18:	4481                	li	s1,0
  if(remove_from_ls(&unusedLS, unusedLS) > 0){
    80001f1a:	00a04a63          	bgtz	a0,80001f2e <allocproc+0x44>
}
    80001f1e:	8526                	mv	a0,s1
    80001f20:	70a2                	ld	ra,40(sp)
    80001f22:	7402                	ld	s0,32(sp)
    80001f24:	64e2                	ld	s1,24(sp)
    80001f26:	6942                	ld	s2,16(sp)
    80001f28:	69a2                	ld	s3,8(sp)
    80001f2a:	6145                	addi	sp,sp,48
    80001f2c:	8082                	ret
    p = proc + temp;
    80001f2e:	19000493          	li	s1,400
    80001f32:	02990933          	mul	s2,s2,s1
    80001f36:	00010497          	auipc	s1,0x10
    80001f3a:	80a48493          	addi	s1,s1,-2038 # 80011740 <proc>
    80001f3e:	94ca                	add	s1,s1,s2
    acquire(&p->lock);
    80001f40:	8526                	mv	a0,s1
    80001f42:	fffff097          	auipc	ra,0xfffff
    80001f46:	ca2080e7          	jalr	-862(ra) # 80000be4 <acquire>
  p->pid = allocpid();
    80001f4a:	00000097          	auipc	ra,0x0
    80001f4e:	de2080e7          	jalr	-542(ra) # 80001d2c <allocpid>
    80001f52:	c4a8                	sw	a0,72(s1)
  p->state = USED;
    80001f54:	4785                	li	a5,1
    80001f56:	d89c                	sw	a5,48(s1)
  p->cpu_num = -1;
    80001f58:	57fd                	li	a5,-1
    80001f5a:	c8bc                	sw	a5,80(s1)
  p->nextIndex = -1;
    80001f5c:	ccbc                	sw	a5,88(s1)
  p->canDelete = 0;
    80001f5e:	0404a623          	sw	zero,76(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001f62:	fffff097          	auipc	ra,0xfffff
    80001f66:	b92080e7          	jalr	-1134(ra) # 80000af4 <kalloc>
    80001f6a:	892a                	mv	s2,a0
    80001f6c:	e0c8                	sd	a0,128(s1)
    80001f6e:	cd05                	beqz	a0,80001fa6 <allocproc+0xbc>
  p->pagetable = proc_pagetable(p);
    80001f70:	8526                	mv	a0,s1
    80001f72:	00000097          	auipc	ra,0x0
    80001f76:	e02080e7          	jalr	-510(ra) # 80001d74 <proc_pagetable>
    80001f7a:	892a                	mv	s2,a0
    80001f7c:	fca8                	sd	a0,120(s1)
  if(p->pagetable == 0){
    80001f7e:	c121                	beqz	a0,80001fbe <allocproc+0xd4>
  memset(&p->context, 0, sizeof(p->context));
    80001f80:	07000613          	li	a2,112
    80001f84:	4581                	li	a1,0
    80001f86:	08848513          	addi	a0,s1,136
    80001f8a:	fffff097          	auipc	ra,0xfffff
    80001f8e:	d56080e7          	jalr	-682(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001f92:	00000797          	auipc	a5,0x0
    80001f96:	d5478793          	addi	a5,a5,-684 # 80001ce6 <forkret>
    80001f9a:	e4dc                	sd	a5,136(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001f9c:	74bc                	ld	a5,104(s1)
    80001f9e:	6705                	lui	a4,0x1
    80001fa0:	97ba                	add	a5,a5,a4
    80001fa2:	e8dc                	sd	a5,144(s1)
  return p;
    80001fa4:	bfad                	j	80001f1e <allocproc+0x34>
    freeproc(p);
    80001fa6:	8526                	mv	a0,s1
    80001fa8:	00000097          	auipc	ra,0x0
    80001fac:	eba080e7          	jalr	-326(ra) # 80001e62 <freeproc>
    release(&p->lock);
    80001fb0:	8526                	mv	a0,s1
    80001fb2:	fffff097          	auipc	ra,0xfffff
    80001fb6:	ce6080e7          	jalr	-794(ra) # 80000c98 <release>
    return 0;
    80001fba:	84ca                	mv	s1,s2
    80001fbc:	b78d                	j	80001f1e <allocproc+0x34>
    freeproc(p);
    80001fbe:	8526                	mv	a0,s1
    80001fc0:	00000097          	auipc	ra,0x0
    80001fc4:	ea2080e7          	jalr	-350(ra) # 80001e62 <freeproc>
    release(&p->lock);
    80001fc8:	8526                	mv	a0,s1
    80001fca:	fffff097          	auipc	ra,0xfffff
    80001fce:	cce080e7          	jalr	-818(ra) # 80000c98 <release>
    return 0;
    80001fd2:	84ca                	mv	s1,s2
    80001fd4:	b7a9                	j	80001f1e <allocproc+0x34>
    return 0;
    80001fd6:	4481                	li	s1,0
    80001fd8:	b799                	j	80001f1e <allocproc+0x34>

0000000080001fda <userinit>:
userinit(void){
    80001fda:	7179                	addi	sp,sp,-48
    80001fdc:	f406                	sd	ra,40(sp)
    80001fde:	f022                	sd	s0,32(sp)
    80001fe0:	ec26                	sd	s1,24(sp)
    80001fe2:	e84a                	sd	s2,16(sp)
    80001fe4:	e44e                	sd	s3,8(sp)
    80001fe6:	1800                	addi	s0,sp,48
  p = allocproc();
    80001fe8:	00000097          	auipc	ra,0x0
    80001fec:	f02080e7          	jalr	-254(ra) # 80001eea <allocproc>
    80001ff0:	84aa                	mv	s1,a0
  initproc = p;
    80001ff2:	00007797          	auipc	a5,0x7
    80001ff6:	04a7b323          	sd	a0,70(a5) # 80009038 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001ffa:	03400613          	li	a2,52
    80001ffe:	00007597          	auipc	a1,0x7
    80002002:	84258593          	addi	a1,a1,-1982 # 80008840 <initcode>
    80002006:	7d28                	ld	a0,120(a0)
    80002008:	fffff097          	auipc	ra,0xfffff
    8000200c:	360080e7          	jalr	864(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80002010:	6785                	lui	a5,0x1
    80002012:	f8bc                	sd	a5,112(s1)
  p->trapframe->epc = 0;      // user program counter
    80002014:	60d8                	ld	a4,128(s1)
    80002016:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    8000201a:	60d8                	ld	a4,128(s1)
    8000201c:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    8000201e:	4641                	li	a2,16
    80002020:	00006597          	auipc	a1,0x6
    80002024:	1e058593          	addi	a1,a1,480 # 80008200 <digits+0x1c0>
    80002028:	18048513          	addi	a0,s1,384
    8000202c:	fffff097          	auipc	ra,0xfffff
    80002030:	e06080e7          	jalr	-506(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80002034:	00006517          	auipc	a0,0x6
    80002038:	1dc50513          	addi	a0,a0,476 # 80008210 <digits+0x1d0>
    8000203c:	00002097          	auipc	ra,0x2
    80002040:	55a080e7          	jalr	1370(ra) # 80004596 <namei>
    80002044:	16a4bc23          	sd	a0,376(s1)
  p->state = RUNNABLE;
    80002048:	478d                	li	a5,3
    8000204a:	d89c                	sw	a5,48(s1)
  add_to_ls(0, runnableLS, p->index);
    8000204c:	48f0                	lw	a2,84(s1)
    8000204e:	0000f597          	auipc	a1,0xf
    80002052:	2d258593          	addi	a1,a1,722 # 80011320 <runnableLS>
    80002056:	4501                	li	a0,0
    80002058:	00000097          	auipc	ra,0x0
    8000205c:	816080e7          	jalr	-2026(ra) # 8000186e <add_to_ls>
  if(flag > 0){
    80002060:	00007797          	auipc	a5,0x7
    80002064:	fd47a783          	lw	a5,-44(a5) # 80009034 <flag>
    80002068:	02f05463          	blez	a5,80002090 <userinit+0xb6>
      curr_cpu_count = counters[0]; 
    8000206c:	0000f997          	auipc	s3,0xf
    80002070:	24498993          	addi	s3,s3,580 # 800112b0 <pid_lock>
    } while(cas(&(counters[0]), curr_cpu_count, curr_cpu_count + 1)) ;
    80002074:	0000f917          	auipc	s2,0xf
    80002078:	26c90913          	addi	s2,s2,620 # 800112e0 <counters>
      curr_cpu_count = counters[0]; 
    8000207c:	0309a583          	lw	a1,48(s3)
    } while(cas(&(counters[0]), curr_cpu_count, curr_cpu_count + 1)) ;
    80002080:	0015861b          	addiw	a2,a1,1
    80002084:	854a                	mv	a0,s2
    80002086:	00005097          	auipc	ra,0x5
    8000208a:	8f0080e7          	jalr	-1808(ra) # 80006976 <cas>
    8000208e:	f57d                	bnez	a0,8000207c <userinit+0xa2>
  release(&p->lock);
    80002090:	8526                	mv	a0,s1
    80002092:	fffff097          	auipc	ra,0xfffff
    80002096:	c06080e7          	jalr	-1018(ra) # 80000c98 <release>
}
    8000209a:	70a2                	ld	ra,40(sp)
    8000209c:	7402                	ld	s0,32(sp)
    8000209e:	64e2                	ld	s1,24(sp)
    800020a0:	6942                	ld	s2,16(sp)
    800020a2:	69a2                	ld	s3,8(sp)
    800020a4:	6145                	addi	sp,sp,48
    800020a6:	8082                	ret

00000000800020a8 <growproc>:
{
    800020a8:	1101                	addi	sp,sp,-32
    800020aa:	ec06                	sd	ra,24(sp)
    800020ac:	e822                	sd	s0,16(sp)
    800020ae:	e426                	sd	s1,8(sp)
    800020b0:	e04a                	sd	s2,0(sp)
    800020b2:	1000                	addi	s0,sp,32
    800020b4:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800020b6:	00000097          	auipc	ra,0x0
    800020ba:	bf8080e7          	jalr	-1032(ra) # 80001cae <myproc>
    800020be:	892a                	mv	s2,a0
  sz = p->sz;
    800020c0:	792c                	ld	a1,112(a0)
    800020c2:	0005861b          	sext.w	a2,a1
  if(n > 0){
    800020c6:	00904f63          	bgtz	s1,800020e4 <growproc+0x3c>
  } else if(n < 0){
    800020ca:	0204cc63          	bltz	s1,80002102 <growproc+0x5a>
  p->sz = sz;
    800020ce:	1602                	slli	a2,a2,0x20
    800020d0:	9201                	srli	a2,a2,0x20
    800020d2:	06c93823          	sd	a2,112(s2)
  return 0;
    800020d6:	4501                	li	a0,0
}
    800020d8:	60e2                	ld	ra,24(sp)
    800020da:	6442                	ld	s0,16(sp)
    800020dc:	64a2                	ld	s1,8(sp)
    800020de:	6902                	ld	s2,0(sp)
    800020e0:	6105                	addi	sp,sp,32
    800020e2:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    800020e4:	9e25                	addw	a2,a2,s1
    800020e6:	1602                	slli	a2,a2,0x20
    800020e8:	9201                	srli	a2,a2,0x20
    800020ea:	1582                	slli	a1,a1,0x20
    800020ec:	9181                	srli	a1,a1,0x20
    800020ee:	7d28                	ld	a0,120(a0)
    800020f0:	fffff097          	auipc	ra,0xfffff
    800020f4:	332080e7          	jalr	818(ra) # 80001422 <uvmalloc>
    800020f8:	0005061b          	sext.w	a2,a0
    800020fc:	fa69                	bnez	a2,800020ce <growproc+0x26>
      return -1;
    800020fe:	557d                	li	a0,-1
    80002100:	bfe1                	j	800020d8 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002102:	9e25                	addw	a2,a2,s1
    80002104:	1602                	slli	a2,a2,0x20
    80002106:	9201                	srli	a2,a2,0x20
    80002108:	1582                	slli	a1,a1,0x20
    8000210a:	9181                	srli	a1,a1,0x20
    8000210c:	7d28                	ld	a0,120(a0)
    8000210e:	fffff097          	auipc	ra,0xfffff
    80002112:	2cc080e7          	jalr	716(ra) # 800013da <uvmdealloc>
    80002116:	0005061b          	sext.w	a2,a0
    8000211a:	bf55                	j	800020ce <growproc+0x26>

000000008000211c <get_min_cpu>:
{
    8000211c:	1141                	addi	sp,sp,-16
    8000211e:	e422                	sd	s0,8(sp)
    80002120:	0800                	addi	s0,sp,16
  for(i = 0; i < CPUS; i++){
    80002122:	0000f717          	auipc	a4,0xf
    80002126:	1be70713          	addi	a4,a4,446 # 800112e0 <counters>
  uint64 min = __UINT64_MAX__;
    8000212a:	567d                	li	a2,-1
  res = -1;
    8000212c:	557d                	li	a0,-1
  for(i = 0; i < CPUS; i++){
    8000212e:	4781                	li	a5,0
    80002130:	45a1                	li	a1,8
    80002132:	a029                	j	8000213c <get_min_cpu+0x20>
    80002134:	2785                	addiw	a5,a5,1
    80002136:	0721                	addi	a4,a4,8
    80002138:	00b78863          	beq	a5,a1,80002148 <get_min_cpu+0x2c>
    if(counters[i] < min){
    8000213c:	6314                	ld	a3,0(a4)
    8000213e:	fec6fbe3          	bgeu	a3,a2,80002134 <get_min_cpu+0x18>
        min = counters[i];
    80002142:	8636                	mv	a2,a3
    if(counters[i] < min){
    80002144:	853e                	mv	a0,a5
    80002146:	b7fd                	j	80002134 <get_min_cpu+0x18>
}
    80002148:	6422                	ld	s0,8(sp)
    8000214a:	0141                	addi	sp,sp,16
    8000214c:	8082                	ret

000000008000214e <get_my_cpu>:
{
    8000214e:	7179                	addi	sp,sp,-48
    80002150:	f406                	sd	ra,40(sp)
    80002152:	f022                	sd	s0,32(sp)
    80002154:	ec26                	sd	s1,24(sp)
    80002156:	e84a                	sd	s2,16(sp)
    80002158:	e44e                	sd	s3,8(sp)
    8000215a:	1800                	addi	s0,sp,48
  if(flag > 0){
    8000215c:	00007797          	auipc	a5,0x7
    80002160:	ed87a783          	lw	a5,-296(a5) # 80009034 <flag>
    res = my_cpu;
    80002164:	84aa                	mv	s1,a0
  if(flag > 0){
    80002166:	02f05d63          	blez	a5,800021a0 <get_my_cpu+0x52>
    res = get_min_cpu();
    8000216a:	00000097          	auipc	ra,0x0
    8000216e:	fb2080e7          	jalr	-78(ra) # 8000211c <get_min_cpu>
    80002172:	84aa                	mv	s1,a0
    } while(cas(counters + res, i, i + 1)) ;  
    80002174:	00351793          	slli	a5,a0,0x3
    80002178:	0000f997          	auipc	s3,0xf
    8000217c:	16898993          	addi	s3,s3,360 # 800112e0 <counters>
    80002180:	99be                	add	s3,s3,a5
      i = counters[res];
    80002182:	0000f917          	auipc	s2,0xf
    80002186:	12e90913          	addi	s2,s2,302 # 800112b0 <pid_lock>
    8000218a:	993e                	add	s2,s2,a5
    8000218c:	03092583          	lw	a1,48(s2)
    } while(cas(counters + res, i, i + 1)) ;  
    80002190:	0015861b          	addiw	a2,a1,1
    80002194:	854e                	mv	a0,s3
    80002196:	00004097          	auipc	ra,0x4
    8000219a:	7e0080e7          	jalr	2016(ra) # 80006976 <cas>
    8000219e:	f57d                	bnez	a0,8000218c <get_my_cpu+0x3e>
}
    800021a0:	8526                	mv	a0,s1
    800021a2:	70a2                	ld	ra,40(sp)
    800021a4:	7402                	ld	s0,32(sp)
    800021a6:	64e2                	ld	s1,24(sp)
    800021a8:	6942                	ld	s2,16(sp)
    800021aa:	69a2                	ld	s3,8(sp)
    800021ac:	6145                	addi	sp,sp,48
    800021ae:	8082                	ret

00000000800021b0 <fork>:
fork(void){
    800021b0:	7179                	addi	sp,sp,-48
    800021b2:	f406                	sd	ra,40(sp)
    800021b4:	f022                	sd	s0,32(sp)
    800021b6:	ec26                	sd	s1,24(sp)
    800021b8:	e84a                	sd	s2,16(sp)
    800021ba:	e44e                	sd	s3,8(sp)
    800021bc:	e052                	sd	s4,0(sp)
    800021be:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800021c0:	00000097          	auipc	ra,0x0
    800021c4:	aee080e7          	jalr	-1298(ra) # 80001cae <myproc>
    800021c8:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    800021ca:	00000097          	auipc	ra,0x0
    800021ce:	d20080e7          	jalr	-736(ra) # 80001eea <allocproc>
    800021d2:	12050e63          	beqz	a0,8000230e <fork+0x15e>
    800021d6:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800021d8:	07093603          	ld	a2,112(s2)
    800021dc:	7d2c                	ld	a1,120(a0)
    800021de:	07893503          	ld	a0,120(s2)
    800021e2:	fffff097          	auipc	ra,0xfffff
    800021e6:	38c080e7          	jalr	908(ra) # 8000156e <uvmcopy>
    800021ea:	04054663          	bltz	a0,80002236 <fork+0x86>
  np->sz = p->sz;
    800021ee:	07093783          	ld	a5,112(s2)
    800021f2:	06f9b823          	sd	a5,112(s3)
  *(np->trapframe) = *(p->trapframe);
    800021f6:	08093683          	ld	a3,128(s2)
    800021fa:	87b6                	mv	a5,a3
    800021fc:	0809b703          	ld	a4,128(s3)
    80002200:	12068693          	addi	a3,a3,288
    80002204:	0007b803          	ld	a6,0(a5)
    80002208:	6788                	ld	a0,8(a5)
    8000220a:	6b8c                	ld	a1,16(a5)
    8000220c:	6f90                	ld	a2,24(a5)
    8000220e:	01073023          	sd	a6,0(a4)
    80002212:	e708                	sd	a0,8(a4)
    80002214:	eb0c                	sd	a1,16(a4)
    80002216:	ef10                	sd	a2,24(a4)
    80002218:	02078793          	addi	a5,a5,32
    8000221c:	02070713          	addi	a4,a4,32
    80002220:	fed792e3          	bne	a5,a3,80002204 <fork+0x54>
  np->trapframe->a0 = 0;
    80002224:	0809b783          	ld	a5,128(s3)
    80002228:	0607b823          	sd	zero,112(a5)
    8000222c:	0f800493          	li	s1,248
  for(i = 0; i < NOFILE; i++)
    80002230:	17800a13          	li	s4,376
    80002234:	a03d                	j	80002262 <fork+0xb2>
    freeproc(np);
    80002236:	854e                	mv	a0,s3
    80002238:	00000097          	auipc	ra,0x0
    8000223c:	c2a080e7          	jalr	-982(ra) # 80001e62 <freeproc>
    release(&np->lock);
    80002240:	854e                	mv	a0,s3
    80002242:	fffff097          	auipc	ra,0xfffff
    80002246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
    return -1;
    8000224a:	5a7d                	li	s4,-1
    8000224c:	a845                	j	800022fc <fork+0x14c>
      np->ofile[i] = filedup(p->ofile[i]);
    8000224e:	00003097          	auipc	ra,0x3
    80002252:	9de080e7          	jalr	-1570(ra) # 80004c2c <filedup>
    80002256:	009987b3          	add	a5,s3,s1
    8000225a:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    8000225c:	04a1                	addi	s1,s1,8
    8000225e:	01448763          	beq	s1,s4,8000226c <fork+0xbc>
    if(p->ofile[i])
    80002262:	009907b3          	add	a5,s2,s1
    80002266:	6388                	ld	a0,0(a5)
    80002268:	f17d                	bnez	a0,8000224e <fork+0x9e>
    8000226a:	bfcd                	j	8000225c <fork+0xac>
  np->cwd = idup(p->cwd);
    8000226c:	17893503          	ld	a0,376(s2)
    80002270:	00002097          	auipc	ra,0x2
    80002274:	b32080e7          	jalr	-1230(ra) # 80003da2 <idup>
    80002278:	16a9bc23          	sd	a0,376(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    8000227c:	4641                	li	a2,16
    8000227e:	18090593          	addi	a1,s2,384
    80002282:	18098513          	addi	a0,s3,384
    80002286:	fffff097          	auipc	ra,0xfffff
    8000228a:	bac080e7          	jalr	-1108(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    8000228e:	0489aa03          	lw	s4,72(s3)
  release(&np->lock);
    80002292:	854e                	mv	a0,s3
    80002294:	fffff097          	auipc	ra,0xfffff
    80002298:	a04080e7          	jalr	-1532(ra) # 80000c98 <release>
  acquire(&wait_lock);
    8000229c:	0000f497          	auipc	s1,0xf
    800022a0:	02c48493          	addi	s1,s1,44 # 800112c8 <wait_lock>
    800022a4:	8526                	mv	a0,s1
    800022a6:	fffff097          	auipc	ra,0xfffff
    800022aa:	93e080e7          	jalr	-1730(ra) # 80000be4 <acquire>
  np->parent = p;
    800022ae:	0729b023          	sd	s2,96(s3)
  release(&wait_lock);
    800022b2:	8526                	mv	a0,s1
    800022b4:	fffff097          	auipc	ra,0xfffff
    800022b8:	9e4080e7          	jalr	-1564(ra) # 80000c98 <release>
  acquire(&np->lock);
    800022bc:	854e                	mv	a0,s3
    800022be:	fffff097          	auipc	ra,0xfffff
    800022c2:	926080e7          	jalr	-1754(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    800022c6:	478d                	li	a5,3
    800022c8:	02f9a823          	sw	a5,48(s3)
  release(&np->lock);
    800022cc:	854e                	mv	a0,s3
    800022ce:	fffff097          	auipc	ra,0xfffff
    800022d2:	9ca080e7          	jalr	-1590(ra) # 80000c98 <release>
  cpu_to_add = get_my_cpu(p->cpu_num);
    800022d6:	05092503          	lw	a0,80(s2)
    800022da:	00000097          	auipc	ra,0x0
    800022de:	e74080e7          	jalr	-396(ra) # 8000214e <get_my_cpu>
  add_to_ls(cpu_to_add,(runnableLS + cpu_to_add), np->index); 
    800022e2:	00251793          	slli	a5,a0,0x2
    800022e6:	0549a603          	lw	a2,84(s3)
    800022ea:	0000f597          	auipc	a1,0xf
    800022ee:	03658593          	addi	a1,a1,54 # 80011320 <runnableLS>
    800022f2:	95be                	add	a1,a1,a5
    800022f4:	fffff097          	auipc	ra,0xfffff
    800022f8:	57a080e7          	jalr	1402(ra) # 8000186e <add_to_ls>
}
    800022fc:	8552                	mv	a0,s4
    800022fe:	70a2                	ld	ra,40(sp)
    80002300:	7402                	ld	s0,32(sp)
    80002302:	64e2                	ld	s1,24(sp)
    80002304:	6942                	ld	s2,16(sp)
    80002306:	69a2                	ld	s3,8(sp)
    80002308:	6a02                	ld	s4,0(sp)
    8000230a:	6145                	addi	sp,sp,48
    8000230c:	8082                	ret
    return -1;
    8000230e:	5a7d                	li	s4,-1
    80002310:	b7f5                	j	800022fc <fork+0x14c>

0000000080002312 <schedulerNew>:
{
    80002312:	7139                	addi	sp,sp,-64
    80002314:	fc06                	sd	ra,56(sp)
    80002316:	f822                	sd	s0,48(sp)
    80002318:	f426                	sd	s1,40(sp)
    8000231a:	f04a                	sd	s2,32(sp)
    8000231c:	ec4e                	sd	s3,24(sp)
    8000231e:	e852                	sd	s4,16(sp)
    80002320:	e456                	sd	s5,8(sp)
    80002322:	e05a                	sd	s6,0(sp)
    80002324:	0080                	addi	s0,sp,64
    80002326:	8a2a                	mv	s4,a0
    80002328:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000232a:	00000097          	auipc	ra,0x0
    8000232e:	984080e7          	jalr	-1660(ra) # 80001cae <myproc>
  for(int i = 0; i < CPUS; i++){
    80002332:	0000f797          	auipc	a5,0xf
    80002336:	fee78793          	addi	a5,a5,-18 # 80011320 <runnableLS>
    8000233a:	4481                	li	s1,0
    if(runnableLS[i] != -1){ 
    8000233c:	56fd                	li	a3,-1
  for(int i = 0; i < CPUS; i++){
    8000233e:	45a1                	li	a1,8
    if(runnableLS[i] != -1){ 
    80002340:	4398                	lw	a4,0(a5)
    80002342:	02d71063          	bne	a4,a3,80002362 <schedulerNew+0x50>
  for(int i = 0; i < CPUS; i++){
    80002346:	2485                	addiw	s1,s1,1
    80002348:	0791                	addi	a5,a5,4
    8000234a:	feb49be3          	bne	s1,a1,80002340 <schedulerNew+0x2e>
}
    8000234e:	70e2                	ld	ra,56(sp)
    80002350:	7442                	ld	s0,48(sp)
    80002352:	74a2                	ld	s1,40(sp)
    80002354:	7902                	ld	s2,32(sp)
    80002356:	69e2                	ld	s3,24(sp)
    80002358:	6a42                	ld	s4,16(sp)
    8000235a:	6aa2                	ld	s5,8(sp)
    8000235c:	6b02                	ld	s6,0(sp)
    8000235e:	6121                	addi	sp,sp,64
    80002360:	8082                	ret
    p = proc + runnableLS[i];
    80002362:	19000913          	li	s2,400
    80002366:	03270733          	mul	a4,a4,s2
    8000236a:	0000f917          	auipc	s2,0xf
    8000236e:	3d690913          	addi	s2,s2,982 # 80011740 <proc>
    80002372:	993a                	add	s2,s2,a4
    acquire(&p->lock);
    80002374:	854a                	mv	a0,s2
    80002376:	fffff097          	auipc	ra,0xfffff
    8000237a:	86e080e7          	jalr	-1938(ra) # 80000be4 <acquire>
    if(remove_from_ls((runnableLS + i), p->index) > 0 && !cas(&p->state, RUNNABLE, RUNNING)){
    8000237e:	00249793          	slli	a5,s1,0x2
    80002382:	05492583          	lw	a1,84(s2)
    80002386:	0000f517          	auipc	a0,0xf
    8000238a:	f9a50513          	addi	a0,a0,-102 # 80011320 <runnableLS>
    8000238e:	953e                	add	a0,a0,a5
    80002390:	fffff097          	auipc	ra,0xfffff
    80002394:	608080e7          	jalr	1544(ra) # 80001998 <remove_from_ls>
    80002398:	00a04863          	bgtz	a0,800023a8 <schedulerNew+0x96>
    release(&p->lock);
    8000239c:	854a                	mv	a0,s2
    8000239e:	fffff097          	auipc	ra,0xfffff
    800023a2:	8fa080e7          	jalr	-1798(ra) # 80000c98 <release>
    break;
    800023a6:	b765                	j	8000234e <schedulerNew+0x3c>
    if(remove_from_ls((runnableLS + i), p->index) > 0 && !cas(&p->state, RUNNABLE, RUNNING)){
    800023a8:	4611                	li	a2,4
    800023aa:	458d                	li	a1,3
    800023ac:	03090513          	addi	a0,s2,48
    800023b0:	00004097          	auipc	ra,0x4
    800023b4:	5c6080e7          	jalr	1478(ra) # 80006976 <cas>
    800023b8:	f175                	bnez	a0,8000239c <schedulerNew+0x8a>
        } while(cas(&counters[cpu_id], index, index + 1)) ;
    800023ba:	003a1793          	slli	a5,s4,0x3
    800023be:	0000fb17          	auipc	s6,0xf
    800023c2:	f22b0b13          	addi	s6,s6,-222 # 800112e0 <counters>
    800023c6:	9b3e                	add	s6,s6,a5
        index = counters[cpu_id];
    800023c8:	0000fa97          	auipc	s5,0xf
    800023cc:	ee8a8a93          	addi	s5,s5,-280 # 800112b0 <pid_lock>
    800023d0:	9abe                	add	s5,s5,a5
    800023d2:	030aa583          	lw	a1,48(s5)
        } while(cas(&counters[cpu_id], index, index + 1)) ;
    800023d6:	0015861b          	addiw	a2,a1,1
    800023da:	855a                	mv	a0,s6
    800023dc:	00004097          	auipc	ra,0x4
    800023e0:	59a080e7          	jalr	1434(ra) # 80006976 <cas>
    800023e4:	f57d                	bnez	a0,800023d2 <schedulerNew+0xc0>
      cas(&(p->cpu_num), i, cpu_id);
    800023e6:	8652                	mv	a2,s4
    800023e8:	85a6                	mv	a1,s1
    800023ea:	05090513          	addi	a0,s2,80
    800023ee:	00004097          	auipc	ra,0x4
    800023f2:	588080e7          	jalr	1416(ra) # 80006976 <cas>
      c->proc = p;
    800023f6:	0129b023          	sd	s2,0(s3)
      swtch(&c->context, &p->context);
    800023fa:	08890593          	addi	a1,s2,136
    800023fe:	00898513          	addi	a0,s3,8
    80002402:	00001097          	auipc	ra,0x1
    80002406:	8fe080e7          	jalr	-1794(ra) # 80002d00 <swtch>
      c->proc = 0;
    8000240a:	0009b023          	sd	zero,0(s3)
    8000240e:	b779                	j	8000239c <schedulerNew+0x8a>

0000000080002410 <scheduler>:
scheduler(void){
    80002410:	711d                	addi	sp,sp,-96
    80002412:	ec86                	sd	ra,88(sp)
    80002414:	e8a2                	sd	s0,80(sp)
    80002416:	e4a6                	sd	s1,72(sp)
    80002418:	e0ca                	sd	s2,64(sp)
    8000241a:	fc4e                	sd	s3,56(sp)
    8000241c:	f852                	sd	s4,48(sp)
    8000241e:	f456                	sd	s5,40(sp)
    80002420:	f05a                	sd	s6,32(sp)
    80002422:	ec5e                	sd	s7,24(sp)
    80002424:	e862                	sd	s8,16(sp)
    80002426:	e466                	sd	s9,8(sp)
    80002428:	e06a                	sd	s10,0(sp)
    8000242a:	1080                	addi	s0,sp,96
    8000242c:	8792                	mv	a5,tp
  int id = r_tp();
    8000242e:	2781                	sext.w	a5,a5
  struct cpu *c = &cpus[id];
    80002430:	00779713          	slli	a4,a5,0x7
    80002434:	0000fc97          	auipc	s9,0xf
    80002438:	f0cc8c93          	addi	s9,s9,-244 # 80011340 <cpus>
    8000243c:	00ec8bb3          	add	s7,s9,a4
    80002440:	8a92                	mv	s5,tp
  int id = r_tp();
    80002442:	2a81                	sext.w	s5,s5
  c->proc = 0;
    80002444:	0000f697          	auipc	a3,0xf
    80002448:	e6c68693          	addi	a3,a3,-404 # 800112b0 <pid_lock>
    8000244c:	96ba                	add	a3,a3,a4
    8000244e:	0806b823          	sd	zero,144(a3)
    first_proc = &runnableLS[cpu_id];
    80002452:	002a9693          	slli	a3,s5,0x2
    80002456:	0000f997          	auipc	s3,0xf
    8000245a:	eca98993          	addi	s3,s3,-310 # 80011320 <runnableLS>
    8000245e:	99b6                	add	s3,s3,a3
          swtch(&c->context, &p->context);
    80002460:	0721                	addi	a4,a4,8
    80002462:	9cba                	add	s9,s9,a4
    curr_index = runnableLS[cpu_id];
    80002464:	0000fc17          	auipc	s8,0xf
    80002468:	e4cc0c13          	addi	s8,s8,-436 # 800112b0 <pid_lock>
    8000246c:	00dc0933          	add	s2,s8,a3
    else if(flag > 0){
    80002470:	00007a17          	auipc	s4,0x7
    80002474:	bc4a0a13          	addi	s4,s4,-1084 # 80009034 <flag>
      acquire(&p->lock);
    80002478:	0000f497          	auipc	s1,0xf
    8000247c:	2c848493          	addi	s1,s1,712 # 80011740 <proc>
      if(remove_from_ls(first_proc, curr_index) > 0 && !cas(&p->state, RUNNABLE, RUNNING)){
    80002480:	0000fb17          	auipc	s6,0xf
    80002484:	2f0b0b13          	addi	s6,s6,752 # 80011770 <proc+0x30>
          c->proc = p;
    80002488:	079e                	slli	a5,a5,0x7
    8000248a:	9c3e                	add	s8,s8,a5
          swtch(&c->context, &p->context);
    8000248c:	0000fd17          	auipc	s10,0xf
    80002490:	33cd0d13          	addi	s10,s10,828 # 800117c8 <proc+0x88>
    80002494:	a005                	j	800024b4 <scheduler+0xa4>
          c->proc = p;
    80002496:	089c3823          	sd	s1,144(s8)
          swtch(&c->context, &p->context);
    8000249a:	85ea                	mv	a1,s10
    8000249c:	8566                	mv	a0,s9
    8000249e:	00001097          	auipc	ra,0x1
    800024a2:	862080e7          	jalr	-1950(ra) # 80002d00 <swtch>
          c->proc = 0;
    800024a6:	080c3823          	sd	zero,144(s8)
      release(&p->lock);
    800024aa:	8526                	mv	a0,s1
    800024ac:	ffffe097          	auipc	ra,0xffffe
    800024b0:	7ec080e7          	jalr	2028(ra) # 80000c98 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800024b4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800024b8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800024bc:	10079073          	csrw	sstatus,a5
    if(!curr_index){ 
    800024c0:	07092783          	lw	a5,112(s2)
    800024c4:	e79d                	bnez	a5,800024f2 <scheduler+0xe2>
      acquire(&p->lock);
    800024c6:	8526                	mv	a0,s1
    800024c8:	ffffe097          	auipc	ra,0xffffe
    800024cc:	71c080e7          	jalr	1820(ra) # 80000be4 <acquire>
      if(remove_from_ls(first_proc, curr_index) > 0 && !cas(&p->state, RUNNABLE, RUNNING)){
    800024d0:	4581                	li	a1,0
    800024d2:	854e                	mv	a0,s3
    800024d4:	fffff097          	auipc	ra,0xfffff
    800024d8:	4c4080e7          	jalr	1220(ra) # 80001998 <remove_from_ls>
    800024dc:	fca057e3          	blez	a0,800024aa <scheduler+0x9a>
    800024e0:	4611                	li	a2,4
    800024e2:	458d                	li	a1,3
    800024e4:	855a                	mv	a0,s6
    800024e6:	00004097          	auipc	ra,0x4
    800024ea:	490080e7          	jalr	1168(ra) # 80006976 <cas>
    800024ee:	fd55                	bnez	a0,800024aa <scheduler+0x9a>
    800024f0:	b75d                	j	80002496 <scheduler+0x86>
    else if(flag > 0){
    800024f2:	000a2783          	lw	a5,0(s4)
    800024f6:	faf05fe3          	blez	a5,800024b4 <scheduler+0xa4>
      schedulerNew(cpu_id,first_proc,c);
    800024fa:	865e                	mv	a2,s7
    800024fc:	85ce                	mv	a1,s3
    800024fe:	8556                	mv	a0,s5
    80002500:	00000097          	auipc	ra,0x0
    80002504:	e12080e7          	jalr	-494(ra) # 80002312 <schedulerNew>
    80002508:	b775                	j	800024b4 <scheduler+0xa4>

000000008000250a <sched>:
{
    8000250a:	7179                	addi	sp,sp,-48
    8000250c:	f406                	sd	ra,40(sp)
    8000250e:	f022                	sd	s0,32(sp)
    80002510:	ec26                	sd	s1,24(sp)
    80002512:	e84a                	sd	s2,16(sp)
    80002514:	e44e                	sd	s3,8(sp)
    80002516:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002518:	fffff097          	auipc	ra,0xfffff
    8000251c:	796080e7          	jalr	1942(ra) # 80001cae <myproc>
    80002520:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002522:	ffffe097          	auipc	ra,0xffffe
    80002526:	648080e7          	jalr	1608(ra) # 80000b6a <holding>
    8000252a:	c93d                	beqz	a0,800025a0 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000252c:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000252e:	2781                	sext.w	a5,a5
    80002530:	079e                	slli	a5,a5,0x7
    80002532:	0000f717          	auipc	a4,0xf
    80002536:	d7e70713          	addi	a4,a4,-642 # 800112b0 <pid_lock>
    8000253a:	97ba                	add	a5,a5,a4
    8000253c:	1087a703          	lw	a4,264(a5)
    80002540:	4785                	li	a5,1
    80002542:	06f71763          	bne	a4,a5,800025b0 <sched+0xa6>
  if(p->state == RUNNING)
    80002546:	5898                	lw	a4,48(s1)
    80002548:	4791                	li	a5,4
    8000254a:	06f70b63          	beq	a4,a5,800025c0 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000254e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002552:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002554:	efb5                	bnez	a5,800025d0 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002556:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002558:	0000f917          	auipc	s2,0xf
    8000255c:	d5890913          	addi	s2,s2,-680 # 800112b0 <pid_lock>
    80002560:	2781                	sext.w	a5,a5
    80002562:	079e                	slli	a5,a5,0x7
    80002564:	97ca                	add	a5,a5,s2
    80002566:	10c7a983          	lw	s3,268(a5)
    8000256a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000256c:	2781                	sext.w	a5,a5
    8000256e:	079e                	slli	a5,a5,0x7
    80002570:	0000f597          	auipc	a1,0xf
    80002574:	dd858593          	addi	a1,a1,-552 # 80011348 <cpus+0x8>
    80002578:	95be                	add	a1,a1,a5
    8000257a:	08848513          	addi	a0,s1,136
    8000257e:	00000097          	auipc	ra,0x0
    80002582:	782080e7          	jalr	1922(ra) # 80002d00 <swtch>
    80002586:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002588:	2781                	sext.w	a5,a5
    8000258a:	079e                	slli	a5,a5,0x7
    8000258c:	97ca                	add	a5,a5,s2
    8000258e:	1137a623          	sw	s3,268(a5)
}
    80002592:	70a2                	ld	ra,40(sp)
    80002594:	7402                	ld	s0,32(sp)
    80002596:	64e2                	ld	s1,24(sp)
    80002598:	6942                	ld	s2,16(sp)
    8000259a:	69a2                	ld	s3,8(sp)
    8000259c:	6145                	addi	sp,sp,48
    8000259e:	8082                	ret
    panic("sched p->lock");
    800025a0:	00006517          	auipc	a0,0x6
    800025a4:	c7850513          	addi	a0,a0,-904 # 80008218 <digits+0x1d8>
    800025a8:	ffffe097          	auipc	ra,0xffffe
    800025ac:	f96080e7          	jalr	-106(ra) # 8000053e <panic>
    panic("sched locks");
    800025b0:	00006517          	auipc	a0,0x6
    800025b4:	c7850513          	addi	a0,a0,-904 # 80008228 <digits+0x1e8>
    800025b8:	ffffe097          	auipc	ra,0xffffe
    800025bc:	f86080e7          	jalr	-122(ra) # 8000053e <panic>
    panic("sched running");
    800025c0:	00006517          	auipc	a0,0x6
    800025c4:	c7850513          	addi	a0,a0,-904 # 80008238 <digits+0x1f8>
    800025c8:	ffffe097          	auipc	ra,0xffffe
    800025cc:	f76080e7          	jalr	-138(ra) # 8000053e <panic>
    panic("sched interruptible");
    800025d0:	00006517          	auipc	a0,0x6
    800025d4:	c7850513          	addi	a0,a0,-904 # 80008248 <digits+0x208>
    800025d8:	ffffe097          	auipc	ra,0xffffe
    800025dc:	f66080e7          	jalr	-154(ra) # 8000053e <panic>

00000000800025e0 <yield>:
yield(void){
    800025e0:	1101                	addi	sp,sp,-32
    800025e2:	ec06                	sd	ra,24(sp)
    800025e4:	e822                	sd	s0,16(sp)
    800025e6:	e426                	sd	s1,8(sp)
    800025e8:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800025ea:	fffff097          	auipc	ra,0xfffff
    800025ee:	6c4080e7          	jalr	1732(ra) # 80001cae <myproc>
    800025f2:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800025f4:	ffffe097          	auipc	ra,0xffffe
    800025f8:	5f0080e7          	jalr	1520(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800025fc:	478d                	li	a5,3
    800025fe:	d89c                	sw	a5,48(s1)
  cpu_to_add = get_my_cpu(p->cpu_num);
    80002600:	48a8                	lw	a0,80(s1)
    80002602:	00000097          	auipc	ra,0x0
    80002606:	b4c080e7          	jalr	-1204(ra) # 8000214e <get_my_cpu>
  add_to_ls(cpu_to_add,(runnableLS + p->cpu_num), p->index);
    8000260a:	48bc                	lw	a5,80(s1)
    8000260c:	078a                	slli	a5,a5,0x2
    8000260e:	48f0                	lw	a2,84(s1)
    80002610:	0000f597          	auipc	a1,0xf
    80002614:	d1058593          	addi	a1,a1,-752 # 80011320 <runnableLS>
    80002618:	95be                	add	a1,a1,a5
    8000261a:	fffff097          	auipc	ra,0xfffff
    8000261e:	254080e7          	jalr	596(ra) # 8000186e <add_to_ls>
  sched();
    80002622:	00000097          	auipc	ra,0x0
    80002626:	ee8080e7          	jalr	-280(ra) # 8000250a <sched>
  release(&p->lock);
    8000262a:	8526                	mv	a0,s1
    8000262c:	ffffe097          	auipc	ra,0xffffe
    80002630:	66c080e7          	jalr	1644(ra) # 80000c98 <release>
}
    80002634:	60e2                	ld	ra,24(sp)
    80002636:	6442                	ld	s0,16(sp)
    80002638:	64a2                	ld	s1,8(sp)
    8000263a:	6105                	addi	sp,sp,32
    8000263c:	8082                	ret

000000008000263e <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk){
    8000263e:	7179                	addi	sp,sp,-48
    80002640:	f406                	sd	ra,40(sp)
    80002642:	f022                	sd	s0,32(sp)
    80002644:	ec26                	sd	s1,24(sp)
    80002646:	e84a                	sd	s2,16(sp)
    80002648:	e44e                	sd	s3,8(sp)
    8000264a:	1800                	addi	s0,sp,48
    8000264c:	892a                	mv	s2,a0
    8000264e:	89ae                	mv	s3,a1
  int res;
  struct proc *p = myproc();
    80002650:	fffff097          	auipc	ra,0xfffff
    80002654:	65e080e7          	jalr	1630(ra) # 80001cae <myproc>
    80002658:	84aa                	mv	s1,a0
  res = 0;
  
  p->chan = chan;
    8000265a:	03253c23          	sd	s2,56(a0)
  if (remove_from_ls((runnableLS + p->cpu_num), p->index) > 0){
    8000265e:	493c                	lw	a5,80(a0)
    80002660:	078a                	slli	a5,a5,0x2
    80002662:	496c                	lw	a1,84(a0)
    80002664:	0000f517          	auipc	a0,0xf
    80002668:	cbc50513          	addi	a0,a0,-836 # 80011320 <runnableLS>
    8000266c:	953e                	add	a0,a0,a5
    8000266e:	fffff097          	auipc	ra,0xfffff
    80002672:	32a080e7          	jalr	810(ra) # 80001998 <remove_from_ls>
    do{
      res = p->state;
    } while(cas(&p->state, res, SLEEPING));
    80002676:	03048913          	addi	s2,s1,48
  if (remove_from_ls((runnableLS + p->cpu_num), p->index) > 0){
    8000267a:	06a05563          	blez	a0,800026e4 <sleep+0xa6>
    } while(cas(&p->state, res, SLEEPING));
    8000267e:	4609                	li	a2,2
    80002680:	588c                	lw	a1,48(s1)
    80002682:	854a                	mv	a0,s2
    80002684:	00004097          	auipc	ra,0x4
    80002688:	2f2080e7          	jalr	754(ra) # 80006976 <cas>
    8000268c:	f96d                	bnez	a0,8000267e <sleep+0x40>
    res = 2;
    add_to_ls(-1, &sleepingLS, p->index);
    8000268e:	48f0                	lw	a2,84(s1)
    80002690:	00007597          	auipc	a1,0x7
    80002694:	99c58593          	addi	a1,a1,-1636 # 8000902c <sleepingLS>
    80002698:	557d                	li	a0,-1
    8000269a:	fffff097          	auipc	ra,0xfffff
    8000269e:	1d4080e7          	jalr	468(ra) # 8000186e <add_to_ls>
    acquire(&p->lock);
    800026a2:	8526                	mv	a0,s1
    800026a4:	ffffe097          	auipc	ra,0xffffe
    800026a8:	540080e7          	jalr	1344(ra) # 80000be4 <acquire>
    release(lk);
    800026ac:	854e                	mv	a0,s3
    800026ae:	ffffe097          	auipc	ra,0xffffe
    800026b2:	5ea080e7          	jalr	1514(ra) # 80000c98 <release>
    sched();
    800026b6:	00000097          	auipc	ra,0x0
    800026ba:	e54080e7          	jalr	-428(ra) # 8000250a <sched>

  }

  if(res>0){
    // Go to sleep.
    p->chan = 0;
    800026be:	0204bc23          	sd	zero,56(s1)
    release(&p->lock);
    800026c2:	8526                	mv	a0,s1
    800026c4:	ffffe097          	auipc	ra,0xffffe
    800026c8:	5d4080e7          	jalr	1492(ra) # 80000c98 <release>
    acquire(lk);
    800026cc:	854e                	mv	a0,s3
    800026ce:	ffffe097          	auipc	ra,0xffffe
    800026d2:	516080e7          	jalr	1302(ra) # 80000be4 <acquire>
    acquire(lk);

  }
  

}
    800026d6:	70a2                	ld	ra,40(sp)
    800026d8:	7402                	ld	s0,32(sp)
    800026da:	64e2                	ld	s1,24(sp)
    800026dc:	6942                	ld	s2,16(sp)
    800026de:	69a2                	ld	s3,8(sp)
    800026e0:	6145                	addi	sp,sp,48
    800026e2:	8082                	ret
    acquire(&p->lock);
    800026e4:	8526                	mv	a0,s1
    800026e6:	ffffe097          	auipc	ra,0xffffe
    800026ea:	4fe080e7          	jalr	1278(ra) # 80000be4 <acquire>
    release(lk);
    800026ee:	854e                	mv	a0,s3
    800026f0:	ffffe097          	auipc	ra,0xffffe
    800026f4:	5a8080e7          	jalr	1448(ra) # 80000c98 <release>
    p->chan = 0;
    800026f8:	0204bc23          	sd	zero,56(s1)
    release(&p->lock);
    800026fc:	8526                	mv	a0,s1
    800026fe:	ffffe097          	auipc	ra,0xffffe
    80002702:	59a080e7          	jalr	1434(ra) # 80000c98 <release>
    acquire(lk);
    80002706:	854e                	mv	a0,s3
    80002708:	ffffe097          	auipc	ra,0xffffe
    8000270c:	4dc080e7          	jalr	1244(ra) # 80000be4 <acquire>
    80002710:	b7d9                	j	800026d6 <sleep+0x98>

0000000080002712 <wait>:
wait(uint64 addr){
    80002712:	715d                	addi	sp,sp,-80
    80002714:	e486                	sd	ra,72(sp)
    80002716:	e0a2                	sd	s0,64(sp)
    80002718:	fc26                	sd	s1,56(sp)
    8000271a:	f84a                	sd	s2,48(sp)
    8000271c:	f44e                	sd	s3,40(sp)
    8000271e:	f052                	sd	s4,32(sp)
    80002720:	ec56                	sd	s5,24(sp)
    80002722:	e85a                	sd	s6,16(sp)
    80002724:	e45e                	sd	s7,8(sp)
    80002726:	e062                	sd	s8,0(sp)
    80002728:	0880                	addi	s0,sp,80
    8000272a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000272c:	fffff097          	auipc	ra,0xfffff
    80002730:	582080e7          	jalr	1410(ra) # 80001cae <myproc>
    80002734:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002736:	0000f517          	auipc	a0,0xf
    8000273a:	b9250513          	addi	a0,a0,-1134 # 800112c8 <wait_lock>
    8000273e:	ffffe097          	auipc	ra,0xffffe
    80002742:	4a6080e7          	jalr	1190(ra) # 80000be4 <acquire>
    havekids = 0;
    80002746:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002748:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    8000274a:	00015997          	auipc	s3,0x15
    8000274e:	3f698993          	addi	s3,s3,1014 # 80017b40 <tickslock>
        havekids = 1;
    80002752:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002754:	0000fc17          	auipc	s8,0xf
    80002758:	b74c0c13          	addi	s8,s8,-1164 # 800112c8 <wait_lock>
    havekids = 0;
    8000275c:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000275e:	0000f497          	auipc	s1,0xf
    80002762:	fe248493          	addi	s1,s1,-30 # 80011740 <proc>
    80002766:	a0bd                	j	800027d4 <wait+0xc2>
          pid = np->pid;
    80002768:	0484a983          	lw	s3,72(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000276c:	000b0e63          	beqz	s6,80002788 <wait+0x76>
    80002770:	4691                	li	a3,4
    80002772:	04448613          	addi	a2,s1,68
    80002776:	85da                	mv	a1,s6
    80002778:	07893503          	ld	a0,120(s2)
    8000277c:	fffff097          	auipc	ra,0xfffff
    80002780:	ef6080e7          	jalr	-266(ra) # 80001672 <copyout>
    80002784:	02054563          	bltz	a0,800027ae <wait+0x9c>
          freeproc(np);
    80002788:	8526                	mv	a0,s1
    8000278a:	fffff097          	auipc	ra,0xfffff
    8000278e:	6d8080e7          	jalr	1752(ra) # 80001e62 <freeproc>
          release(&np->lock);
    80002792:	8526                	mv	a0,s1
    80002794:	ffffe097          	auipc	ra,0xffffe
    80002798:	504080e7          	jalr	1284(ra) # 80000c98 <release>
          release(&wait_lock);
    8000279c:	0000f517          	auipc	a0,0xf
    800027a0:	b2c50513          	addi	a0,a0,-1236 # 800112c8 <wait_lock>
    800027a4:	ffffe097          	auipc	ra,0xffffe
    800027a8:	4f4080e7          	jalr	1268(ra) # 80000c98 <release>
          return pid;
    800027ac:	a09d                	j	80002812 <wait+0x100>
            release(&np->lock);
    800027ae:	8526                	mv	a0,s1
    800027b0:	ffffe097          	auipc	ra,0xffffe
    800027b4:	4e8080e7          	jalr	1256(ra) # 80000c98 <release>
            release(&wait_lock);
    800027b8:	0000f517          	auipc	a0,0xf
    800027bc:	b1050513          	addi	a0,a0,-1264 # 800112c8 <wait_lock>
    800027c0:	ffffe097          	auipc	ra,0xffffe
    800027c4:	4d8080e7          	jalr	1240(ra) # 80000c98 <release>
            return -1;
    800027c8:	59fd                	li	s3,-1
    800027ca:	a0a1                	j	80002812 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800027cc:	19048493          	addi	s1,s1,400
    800027d0:	03348463          	beq	s1,s3,800027f8 <wait+0xe6>
      if(np->parent == p){
    800027d4:	70bc                	ld	a5,96(s1)
    800027d6:	ff279be3          	bne	a5,s2,800027cc <wait+0xba>
        acquire(&np->lock);
    800027da:	8526                	mv	a0,s1
    800027dc:	ffffe097          	auipc	ra,0xffffe
    800027e0:	408080e7          	jalr	1032(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800027e4:	589c                	lw	a5,48(s1)
    800027e6:	f94781e3          	beq	a5,s4,80002768 <wait+0x56>
        release(&np->lock);
    800027ea:	8526                	mv	a0,s1
    800027ec:	ffffe097          	auipc	ra,0xffffe
    800027f0:	4ac080e7          	jalr	1196(ra) # 80000c98 <release>
        havekids = 1;
    800027f4:	8756                	mv	a4,s5
    800027f6:	bfd9                	j	800027cc <wait+0xba>
    if(!havekids || p->killed){
    800027f8:	c701                	beqz	a4,80002800 <wait+0xee>
    800027fa:	04092783          	lw	a5,64(s2)
    800027fe:	c79d                	beqz	a5,8000282c <wait+0x11a>
      release(&wait_lock);
    80002800:	0000f517          	auipc	a0,0xf
    80002804:	ac850513          	addi	a0,a0,-1336 # 800112c8 <wait_lock>
    80002808:	ffffe097          	auipc	ra,0xffffe
    8000280c:	490080e7          	jalr	1168(ra) # 80000c98 <release>
      return -1;
    80002810:	59fd                	li	s3,-1
}
    80002812:	854e                	mv	a0,s3
    80002814:	60a6                	ld	ra,72(sp)
    80002816:	6406                	ld	s0,64(sp)
    80002818:	74e2                	ld	s1,56(sp)
    8000281a:	7942                	ld	s2,48(sp)
    8000281c:	79a2                	ld	s3,40(sp)
    8000281e:	7a02                	ld	s4,32(sp)
    80002820:	6ae2                	ld	s5,24(sp)
    80002822:	6b42                	ld	s6,16(sp)
    80002824:	6ba2                	ld	s7,8(sp)
    80002826:	6c02                	ld	s8,0(sp)
    80002828:	6161                	addi	sp,sp,80
    8000282a:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000282c:	85e2                	mv	a1,s8
    8000282e:	854a                	mv	a0,s2
    80002830:	00000097          	auipc	ra,0x0
    80002834:	e0e080e7          	jalr	-498(ra) # 8000263e <sleep>
    havekids = 0;
    80002838:	b715                	j	8000275c <wait+0x4a>

000000008000283a <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan){
    8000283a:	711d                	addi	sp,sp,-96
    8000283c:	ec86                	sd	ra,88(sp)
    8000283e:	e8a2                	sd	s0,80(sp)
    80002840:	e4a6                	sd	s1,72(sp)
    80002842:	e0ca                	sd	s2,64(sp)
    80002844:	fc4e                	sd	s3,56(sp)
    80002846:	f852                	sd	s4,48(sp)
    80002848:	f456                	sd	s5,40(sp)
    8000284a:	f05a                	sd	s6,32(sp)
    8000284c:	ec5e                	sd	s7,24(sp)
    8000284e:	1080                	addi	s0,sp,96
    80002850:	8aaa                	mv	s5,a0
  struct proc *p;
  int curr_index, old_index, cpu_to_add;
  curr_index = sleepingLS;
    80002852:	00006797          	auipc	a5,0x6
    80002856:	7da7a783          	lw	a5,2010(a5) # 8000902c <sleepingLS>
    8000285a:	faf42623          	sw	a5,-84(s0)

  do{
    if(curr_index == -1){ 
    8000285e:	5a7d                	li	s4,-1
      return;
    }
    p = (proc + curr_index);
    80002860:	19000993          	li	s3,400
    80002864:	0000f917          	auipc	s2,0xf
    80002868:	edc90913          	addi	s2,s2,-292 # 80011740 <proc>
    if(p != myproc()){
      acquire(&(p->lock));
      if (p->chan == chan){ // p is sleeping on <chan>
        if (remove_from_ls(&sleepingLS, curr_index) > 0){
    8000286c:	00006b17          	auipc	s6,0x6
    80002870:	7c0b0b13          	addi	s6,s6,1984 # 8000902c <sleepingLS>
          p->chan = 0;
          if(!cas(&p->state, SLEEPING, RUNNABLE)){
            cpu_to_add = get_my_cpu(p->cpu_num);
            add_to_ls(cpu_to_add,(runnableLS + cpu_to_add), p->index);  
    80002874:	0000fb97          	auipc	s7,0xf
    80002878:	aacb8b93          	addi	s7,s7,-1364 # 80011320 <runnableLS>
    8000287c:	a01d                	j	800028a2 <wakeup+0x68>

          }
        }
      }
      release(&p->lock);
    8000287e:	8526                	mv	a0,s1
    80002880:	ffffe097          	auipc	ra,0xffffe
    80002884:	418080e7          	jalr	1048(ra) # 80000c98 <release>
    }
    old_index = curr_index;
    80002888:	fac42583          	lw	a1,-84(s0)
  } while(!cas(&curr_index, old_index, (proc + curr_index)->nextIndex));
    8000288c:	033587b3          	mul	a5,a1,s3
    80002890:	97ca                	add	a5,a5,s2
    80002892:	4fb0                	lw	a2,88(a5)
    80002894:	fac40513          	addi	a0,s0,-84
    80002898:	00004097          	auipc	ra,0x4
    8000289c:	0de080e7          	jalr	222(ra) # 80006976 <cas>
    800028a0:	e925                	bnez	a0,80002910 <wakeup+0xd6>
    if(curr_index == -1){ 
    800028a2:	fac42483          	lw	s1,-84(s0)
    800028a6:	07448563          	beq	s1,s4,80002910 <wakeup+0xd6>
    p = (proc + curr_index);
    800028aa:	033484b3          	mul	s1,s1,s3
    800028ae:	94ca                	add	s1,s1,s2
    if(p != myproc()){
    800028b0:	fffff097          	auipc	ra,0xfffff
    800028b4:	3fe080e7          	jalr	1022(ra) # 80001cae <myproc>
    800028b8:	fca488e3          	beq	s1,a0,80002888 <wakeup+0x4e>
      acquire(&(p->lock));
    800028bc:	8526                	mv	a0,s1
    800028be:	ffffe097          	auipc	ra,0xffffe
    800028c2:	326080e7          	jalr	806(ra) # 80000be4 <acquire>
      if (p->chan == chan){ // p is sleeping on <chan>
    800028c6:	7c9c                	ld	a5,56(s1)
    800028c8:	fb579be3          	bne	a5,s5,8000287e <wakeup+0x44>
        if (remove_from_ls(&sleepingLS, curr_index) > 0){
    800028cc:	fac42583          	lw	a1,-84(s0)
    800028d0:	855a                	mv	a0,s6
    800028d2:	fffff097          	auipc	ra,0xfffff
    800028d6:	0c6080e7          	jalr	198(ra) # 80001998 <remove_from_ls>
    800028da:	faa052e3          	blez	a0,8000287e <wakeup+0x44>
          p->chan = 0;
    800028de:	0204bc23          	sd	zero,56(s1)
          if(!cas(&p->state, SLEEPING, RUNNABLE)){
    800028e2:	460d                	li	a2,3
    800028e4:	4589                	li	a1,2
    800028e6:	03048513          	addi	a0,s1,48
    800028ea:	00004097          	auipc	ra,0x4
    800028ee:	08c080e7          	jalr	140(ra) # 80006976 <cas>
    800028f2:	f551                	bnez	a0,8000287e <wakeup+0x44>
            cpu_to_add = get_my_cpu(p->cpu_num);
    800028f4:	48a8                	lw	a0,80(s1)
    800028f6:	00000097          	auipc	ra,0x0
    800028fa:	858080e7          	jalr	-1960(ra) # 8000214e <get_my_cpu>
            add_to_ls(cpu_to_add,(runnableLS + cpu_to_add), p->index);  
    800028fe:	00251593          	slli	a1,a0,0x2
    80002902:	48f0                	lw	a2,84(s1)
    80002904:	95de                	add	a1,a1,s7
    80002906:	fffff097          	auipc	ra,0xfffff
    8000290a:	f68080e7          	jalr	-152(ra) # 8000186e <add_to_ls>
    8000290e:	bf85                	j	8000287e <wakeup+0x44>
}
    80002910:	60e6                	ld	ra,88(sp)
    80002912:	6446                	ld	s0,80(sp)
    80002914:	64a6                	ld	s1,72(sp)
    80002916:	6906                	ld	s2,64(sp)
    80002918:	79e2                	ld	s3,56(sp)
    8000291a:	7a42                	ld	s4,48(sp)
    8000291c:	7aa2                	ld	s5,40(sp)
    8000291e:	7b02                	ld	s6,32(sp)
    80002920:	6be2                	ld	s7,24(sp)
    80002922:	6125                	addi	sp,sp,96
    80002924:	8082                	ret

0000000080002926 <reparent>:
{
    80002926:	7179                	addi	sp,sp,-48
    80002928:	f406                	sd	ra,40(sp)
    8000292a:	f022                	sd	s0,32(sp)
    8000292c:	ec26                	sd	s1,24(sp)
    8000292e:	e84a                	sd	s2,16(sp)
    80002930:	e44e                	sd	s3,8(sp)
    80002932:	e052                	sd	s4,0(sp)
    80002934:	1800                	addi	s0,sp,48
    80002936:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002938:	0000f497          	auipc	s1,0xf
    8000293c:	e0848493          	addi	s1,s1,-504 # 80011740 <proc>
      pp->parent = initproc;
    80002940:	00006a17          	auipc	s4,0x6
    80002944:	6f8a0a13          	addi	s4,s4,1784 # 80009038 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002948:	00015997          	auipc	s3,0x15
    8000294c:	1f898993          	addi	s3,s3,504 # 80017b40 <tickslock>
    80002950:	a029                	j	8000295a <reparent+0x34>
    80002952:	19048493          	addi	s1,s1,400
    80002956:	01348d63          	beq	s1,s3,80002970 <reparent+0x4a>
    if(pp->parent == p){
    8000295a:	70bc                	ld	a5,96(s1)
    8000295c:	ff279be3          	bne	a5,s2,80002952 <reparent+0x2c>
      pp->parent = initproc;
    80002960:	000a3503          	ld	a0,0(s4)
    80002964:	f0a8                	sd	a0,96(s1)
      wakeup(initproc);
    80002966:	00000097          	auipc	ra,0x0
    8000296a:	ed4080e7          	jalr	-300(ra) # 8000283a <wakeup>
    8000296e:	b7d5                	j	80002952 <reparent+0x2c>
}
    80002970:	70a2                	ld	ra,40(sp)
    80002972:	7402                	ld	s0,32(sp)
    80002974:	64e2                	ld	s1,24(sp)
    80002976:	6942                	ld	s2,16(sp)
    80002978:	69a2                	ld	s3,8(sp)
    8000297a:	6a02                	ld	s4,0(sp)
    8000297c:	6145                	addi	sp,sp,48
    8000297e:	8082                	ret

0000000080002980 <exit>:
exit(int status){
    80002980:	7179                	addi	sp,sp,-48
    80002982:	f406                	sd	ra,40(sp)
    80002984:	f022                	sd	s0,32(sp)
    80002986:	ec26                	sd	s1,24(sp)
    80002988:	e84a                	sd	s2,16(sp)
    8000298a:	e44e                	sd	s3,8(sp)
    8000298c:	e052                	sd	s4,0(sp)
    8000298e:	1800                	addi	s0,sp,48
    80002990:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002992:	fffff097          	auipc	ra,0xfffff
    80002996:	31c080e7          	jalr	796(ra) # 80001cae <myproc>
    8000299a:	89aa                	mv	s3,a0
  if(p == initproc)
    8000299c:	00006797          	auipc	a5,0x6
    800029a0:	69c7b783          	ld	a5,1692(a5) # 80009038 <initproc>
    800029a4:	0f850493          	addi	s1,a0,248
    800029a8:	17850913          	addi	s2,a0,376
    800029ac:	02a79363          	bne	a5,a0,800029d2 <exit+0x52>
    panic("init exiting");
    800029b0:	00006517          	auipc	a0,0x6
    800029b4:	8b050513          	addi	a0,a0,-1872 # 80008260 <digits+0x220>
    800029b8:	ffffe097          	auipc	ra,0xffffe
    800029bc:	b86080e7          	jalr	-1146(ra) # 8000053e <panic>
      fileclose(f);
    800029c0:	00002097          	auipc	ra,0x2
    800029c4:	2be080e7          	jalr	702(ra) # 80004c7e <fileclose>
      p->ofile[fd] = 0;
    800029c8:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800029cc:	04a1                	addi	s1,s1,8
    800029ce:	01248563          	beq	s1,s2,800029d8 <exit+0x58>
    if(p->ofile[fd]){
    800029d2:	6088                	ld	a0,0(s1)
    800029d4:	f575                	bnez	a0,800029c0 <exit+0x40>
    800029d6:	bfdd                	j	800029cc <exit+0x4c>
  begin_op();
    800029d8:	00002097          	auipc	ra,0x2
    800029dc:	dda080e7          	jalr	-550(ra) # 800047b2 <begin_op>
  iput(p->cwd);
    800029e0:	1789b503          	ld	a0,376(s3)
    800029e4:	00001097          	auipc	ra,0x1
    800029e8:	5b6080e7          	jalr	1462(ra) # 80003f9a <iput>
  end_op();
    800029ec:	00002097          	auipc	ra,0x2
    800029f0:	e46080e7          	jalr	-442(ra) # 80004832 <end_op>
  p->cwd = 0;
    800029f4:	1609bc23          	sd	zero,376(s3)
  acquire(&wait_lock);
    800029f8:	0000f497          	auipc	s1,0xf
    800029fc:	8d048493          	addi	s1,s1,-1840 # 800112c8 <wait_lock>
    80002a00:	8526                	mv	a0,s1
    80002a02:	ffffe097          	auipc	ra,0xffffe
    80002a06:	1e2080e7          	jalr	482(ra) # 80000be4 <acquire>
  reparent(p);
    80002a0a:	854e                	mv	a0,s3
    80002a0c:	00000097          	auipc	ra,0x0
    80002a10:	f1a080e7          	jalr	-230(ra) # 80002926 <reparent>
  wakeup(p->parent);
    80002a14:	0609b503          	ld	a0,96(s3)
    80002a18:	00000097          	auipc	ra,0x0
    80002a1c:	e22080e7          	jalr	-478(ra) # 8000283a <wakeup>
  acquire(&p->lock);
    80002a20:	854e                	mv	a0,s3
    80002a22:	ffffe097          	auipc	ra,0xffffe
    80002a26:	1c2080e7          	jalr	450(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002a2a:	0549a223          	sw	s4,68(s3)
  remove_from_ls((runnableLS + p->cpu_num), p->index);
    80002a2e:	0509a783          	lw	a5,80(s3)
    80002a32:	078a                	slli	a5,a5,0x2
    80002a34:	0549a583          	lw	a1,84(s3)
    80002a38:	0000f517          	auipc	a0,0xf
    80002a3c:	8e850513          	addi	a0,a0,-1816 # 80011320 <runnableLS>
    80002a40:	953e                	add	a0,a0,a5
    80002a42:	fffff097          	auipc	ra,0xfffff
    80002a46:	f56080e7          	jalr	-170(ra) # 80001998 <remove_from_ls>
  p->state = ZOMBIE;
    80002a4a:	4795                	li	a5,5
    80002a4c:	02f9a823          	sw	a5,48(s3)
  add_to_ls(-1,&zombieLS, p->index); 
    80002a50:	0549a603          	lw	a2,84(s3)
    80002a54:	00006597          	auipc	a1,0x6
    80002a58:	5d458593          	addi	a1,a1,1492 # 80009028 <zombieLS>
    80002a5c:	557d                	li	a0,-1
    80002a5e:	fffff097          	auipc	ra,0xfffff
    80002a62:	e10080e7          	jalr	-496(ra) # 8000186e <add_to_ls>
  release(&wait_lock);
    80002a66:	8526                	mv	a0,s1
    80002a68:	ffffe097          	auipc	ra,0xffffe
    80002a6c:	230080e7          	jalr	560(ra) # 80000c98 <release>
  sched();
    80002a70:	00000097          	auipc	ra,0x0
    80002a74:	a9a080e7          	jalr	-1382(ra) # 8000250a <sched>
  panic("zombie exit");
    80002a78:	00005517          	auipc	a0,0x5
    80002a7c:	7f850513          	addi	a0,a0,2040 # 80008270 <digits+0x230>
    80002a80:	ffffe097          	auipc	ra,0xffffe
    80002a84:	abe080e7          	jalr	-1346(ra) # 8000053e <panic>

0000000080002a88 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid){
    80002a88:	7179                	addi	sp,sp,-48
    80002a8a:	f406                	sd	ra,40(sp)
    80002a8c:	f022                	sd	s0,32(sp)
    80002a8e:	ec26                	sd	s1,24(sp)
    80002a90:	e84a                	sd	s2,16(sp)
    80002a92:	e44e                	sd	s3,8(sp)
    80002a94:	1800                	addi	s0,sp,48
    80002a96:	892a                	mv	s2,a0
  struct proc *p;
  //int cpu_to_add;
  for(p = proc; p < &proc[NPROC]; p++){
    80002a98:	0000f497          	auipc	s1,0xf
    80002a9c:	ca848493          	addi	s1,s1,-856 # 80011740 <proc>
    80002aa0:	00015997          	auipc	s3,0x15
    80002aa4:	0a098993          	addi	s3,s3,160 # 80017b40 <tickslock>
    acquire(&p->lock);
    80002aa8:	8526                	mv	a0,s1
    80002aaa:	ffffe097          	auipc	ra,0xffffe
    80002aae:	13a080e7          	jalr	314(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002ab2:	44bc                	lw	a5,72(s1)
    80002ab4:	01278d63          	beq	a5,s2,80002ace <kill+0x46>
        // add_to_ls(cpu_to_add, (runnableLS + p->cpu_num), p->index);
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002ab8:	8526                	mv	a0,s1
    80002aba:	ffffe097          	auipc	ra,0xffffe
    80002abe:	1de080e7          	jalr	478(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002ac2:	19048493          	addi	s1,s1,400
    80002ac6:	ff3491e3          	bne	s1,s3,80002aa8 <kill+0x20>
  }
  return -1;
    80002aca:	557d                	li	a0,-1
    80002acc:	a829                	j	80002ae6 <kill+0x5e>
      p->killed = 1;
    80002ace:	4785                	li	a5,1
    80002ad0:	c0bc                	sw	a5,64(s1)
      if(p->state == SLEEPING){
    80002ad2:	5898                	lw	a4,48(s1)
    80002ad4:	4789                	li	a5,2
    80002ad6:	00f70f63          	beq	a4,a5,80002af4 <kill+0x6c>
      release(&p->lock);
    80002ada:	8526                	mv	a0,s1
    80002adc:	ffffe097          	auipc	ra,0xffffe
    80002ae0:	1bc080e7          	jalr	444(ra) # 80000c98 <release>
      return 0;
    80002ae4:	4501                	li	a0,0
}
    80002ae6:	70a2                	ld	ra,40(sp)
    80002ae8:	7402                	ld	s0,32(sp)
    80002aea:	64e2                	ld	s1,24(sp)
    80002aec:	6942                	ld	s2,16(sp)
    80002aee:	69a2                	ld	s3,8(sp)
    80002af0:	6145                	addi	sp,sp,48
    80002af2:	8082                	ret
        remove_from_ls(&sleepingLS, p->index);
    80002af4:	48ec                	lw	a1,84(s1)
    80002af6:	00006517          	auipc	a0,0x6
    80002afa:	53650513          	addi	a0,a0,1334 # 8000902c <sleepingLS>
    80002afe:	fffff097          	auipc	ra,0xfffff
    80002b02:	e9a080e7          	jalr	-358(ra) # 80001998 <remove_from_ls>
        p->state = RUNNABLE;
    80002b06:	478d                	li	a5,3
    80002b08:	d89c                	sw	a5,48(s1)
    80002b0a:	bfc1                	j	80002ada <kill+0x52>

0000000080002b0c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002b0c:	7179                	addi	sp,sp,-48
    80002b0e:	f406                	sd	ra,40(sp)
    80002b10:	f022                	sd	s0,32(sp)
    80002b12:	ec26                	sd	s1,24(sp)
    80002b14:	e84a                	sd	s2,16(sp)
    80002b16:	e44e                	sd	s3,8(sp)
    80002b18:	e052                	sd	s4,0(sp)
    80002b1a:	1800                	addi	s0,sp,48
    80002b1c:	84aa                	mv	s1,a0
    80002b1e:	892e                	mv	s2,a1
    80002b20:	89b2                	mv	s3,a2
    80002b22:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002b24:	fffff097          	auipc	ra,0xfffff
    80002b28:	18a080e7          	jalr	394(ra) # 80001cae <myproc>
  if(user_dst){
    80002b2c:	c08d                	beqz	s1,80002b4e <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002b2e:	86d2                	mv	a3,s4
    80002b30:	864e                	mv	a2,s3
    80002b32:	85ca                	mv	a1,s2
    80002b34:	7d28                	ld	a0,120(a0)
    80002b36:	fffff097          	auipc	ra,0xfffff
    80002b3a:	b3c080e7          	jalr	-1220(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002b3e:	70a2                	ld	ra,40(sp)
    80002b40:	7402                	ld	s0,32(sp)
    80002b42:	64e2                	ld	s1,24(sp)
    80002b44:	6942                	ld	s2,16(sp)
    80002b46:	69a2                	ld	s3,8(sp)
    80002b48:	6a02                	ld	s4,0(sp)
    80002b4a:	6145                	addi	sp,sp,48
    80002b4c:	8082                	ret
    memmove((char *)dst, src, len);
    80002b4e:	000a061b          	sext.w	a2,s4
    80002b52:	85ce                	mv	a1,s3
    80002b54:	854a                	mv	a0,s2
    80002b56:	ffffe097          	auipc	ra,0xffffe
    80002b5a:	1ea080e7          	jalr	490(ra) # 80000d40 <memmove>
    return 0;
    80002b5e:	8526                	mv	a0,s1
    80002b60:	bff9                	j	80002b3e <either_copyout+0x32>

0000000080002b62 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002b62:	7179                	addi	sp,sp,-48
    80002b64:	f406                	sd	ra,40(sp)
    80002b66:	f022                	sd	s0,32(sp)
    80002b68:	ec26                	sd	s1,24(sp)
    80002b6a:	e84a                	sd	s2,16(sp)
    80002b6c:	e44e                	sd	s3,8(sp)
    80002b6e:	e052                	sd	s4,0(sp)
    80002b70:	1800                	addi	s0,sp,48
    80002b72:	892a                	mv	s2,a0
    80002b74:	84ae                	mv	s1,a1
    80002b76:	89b2                	mv	s3,a2
    80002b78:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002b7a:	fffff097          	auipc	ra,0xfffff
    80002b7e:	134080e7          	jalr	308(ra) # 80001cae <myproc>
  if(user_src){
    80002b82:	c08d                	beqz	s1,80002ba4 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002b84:	86d2                	mv	a3,s4
    80002b86:	864e                	mv	a2,s3
    80002b88:	85ca                	mv	a1,s2
    80002b8a:	7d28                	ld	a0,120(a0)
    80002b8c:	fffff097          	auipc	ra,0xfffff
    80002b90:	b72080e7          	jalr	-1166(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002b94:	70a2                	ld	ra,40(sp)
    80002b96:	7402                	ld	s0,32(sp)
    80002b98:	64e2                	ld	s1,24(sp)
    80002b9a:	6942                	ld	s2,16(sp)
    80002b9c:	69a2                	ld	s3,8(sp)
    80002b9e:	6a02                	ld	s4,0(sp)
    80002ba0:	6145                	addi	sp,sp,48
    80002ba2:	8082                	ret
    memmove(dst, (char*)src, len);
    80002ba4:	000a061b          	sext.w	a2,s4
    80002ba8:	85ce                	mv	a1,s3
    80002baa:	854a                	mv	a0,s2
    80002bac:	ffffe097          	auipc	ra,0xffffe
    80002bb0:	194080e7          	jalr	404(ra) # 80000d40 <memmove>
    return 0;
    80002bb4:	8526                	mv	a0,s1
    80002bb6:	bff9                	j	80002b94 <either_copyin+0x32>

0000000080002bb8 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002bb8:	715d                	addi	sp,sp,-80
    80002bba:	e486                	sd	ra,72(sp)
    80002bbc:	e0a2                	sd	s0,64(sp)
    80002bbe:	fc26                	sd	s1,56(sp)
    80002bc0:	f84a                	sd	s2,48(sp)
    80002bc2:	f44e                	sd	s3,40(sp)
    80002bc4:	f052                	sd	s4,32(sp)
    80002bc6:	ec56                	sd	s5,24(sp)
    80002bc8:	e85a                	sd	s6,16(sp)
    80002bca:	e45e                	sd	s7,8(sp)
    80002bcc:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002bce:	00005517          	auipc	a0,0x5
    80002bd2:	4fa50513          	addi	a0,a0,1274 # 800080c8 <digits+0x88>
    80002bd6:	ffffe097          	auipc	ra,0xffffe
    80002bda:	9b2080e7          	jalr	-1614(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002bde:	0000f497          	auipc	s1,0xf
    80002be2:	ce248493          	addi	s1,s1,-798 # 800118c0 <proc+0x180>
    80002be6:	00015917          	auipc	s2,0x15
    80002bea:	0da90913          	addi	s2,s2,218 # 80017cc0 <bcache+0x168>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002bee:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002bf0:	00005997          	auipc	s3,0x5
    80002bf4:	69098993          	addi	s3,s3,1680 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002bf8:	00005a97          	auipc	s5,0x5
    80002bfc:	690a8a93          	addi	s5,s5,1680 # 80008288 <digits+0x248>
    printf("\n");
    80002c00:	00005a17          	auipc	s4,0x5
    80002c04:	4c8a0a13          	addi	s4,s4,1224 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002c08:	00005b97          	auipc	s7,0x5
    80002c0c:	6b8b8b93          	addi	s7,s7,1720 # 800082c0 <states.1835>
    80002c10:	a00d                	j	80002c32 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002c12:	ec86a583          	lw	a1,-312(a3)
    80002c16:	8556                	mv	a0,s5
    80002c18:	ffffe097          	auipc	ra,0xffffe
    80002c1c:	970080e7          	jalr	-1680(ra) # 80000588 <printf>
    printf("\n");
    80002c20:	8552                	mv	a0,s4
    80002c22:	ffffe097          	auipc	ra,0xffffe
    80002c26:	966080e7          	jalr	-1690(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002c2a:	19048493          	addi	s1,s1,400
    80002c2e:	03248163          	beq	s1,s2,80002c50 <procdump+0x98>
    if(p->state == UNUSED)
    80002c32:	86a6                	mv	a3,s1
    80002c34:	eb04a783          	lw	a5,-336(s1)
    80002c38:	dbed                	beqz	a5,80002c2a <procdump+0x72>
      state = "???";
    80002c3a:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002c3c:	fcfb6be3          	bltu	s6,a5,80002c12 <procdump+0x5a>
    80002c40:	1782                	slli	a5,a5,0x20
    80002c42:	9381                	srli	a5,a5,0x20
    80002c44:	078e                	slli	a5,a5,0x3
    80002c46:	97de                	add	a5,a5,s7
    80002c48:	6390                	ld	a2,0(a5)
    80002c4a:	f661                	bnez	a2,80002c12 <procdump+0x5a>
      state = "???";
    80002c4c:	864e                	mv	a2,s3
    80002c4e:	b7d1                	j	80002c12 <procdump+0x5a>
  }
}
    80002c50:	60a6                	ld	ra,72(sp)
    80002c52:	6406                	ld	s0,64(sp)
    80002c54:	74e2                	ld	s1,56(sp)
    80002c56:	7942                	ld	s2,48(sp)
    80002c58:	79a2                	ld	s3,40(sp)
    80002c5a:	7a02                	ld	s4,32(sp)
    80002c5c:	6ae2                	ld	s5,24(sp)
    80002c5e:	6b42                	ld	s6,16(sp)
    80002c60:	6ba2                	ld	s7,8(sp)
    80002c62:	6161                	addi	sp,sp,80
    80002c64:	8082                	ret

0000000080002c66 <set_cpu>:

int
set_cpu(int cpuID){
    80002c66:	7179                	addi	sp,sp,-48
    80002c68:	f406                	sd	ra,40(sp)
    80002c6a:	f022                	sd	s0,32(sp)
    80002c6c:	ec26                	sd	s1,24(sp)
    80002c6e:	e84a                	sd	s2,16(sp)
    80002c70:	e44e                	sd	s3,8(sp)
    80002c72:	e052                	sd	s4,0(sp)
    80002c74:	1800                	addi	s0,sp,48
    80002c76:	892a                	mv	s2,a0
  int curr_cpu;
  struct  proc *p = myproc();
    80002c78:	fffff097          	auipc	ra,0xfffff
    80002c7c:	036080e7          	jalr	54(ra) # 80001cae <myproc>
    80002c80:	84aa                	mv	s1,a0
  do{
    curr_cpu = p->cpu_num;
  } while(cas(&((proc + p->index)->cpu_num), curr_cpu, cpuID)) ;
    80002c82:	19000a13          	li	s4,400
    80002c86:	0000f997          	auipc	s3,0xf
    80002c8a:	aba98993          	addi	s3,s3,-1350 # 80011740 <proc>
    80002c8e:	48e8                	lw	a0,84(s1)
    80002c90:	03450533          	mul	a0,a0,s4
    80002c94:	954e                	add	a0,a0,s3
    80002c96:	864a                	mv	a2,s2
    80002c98:	48ac                	lw	a1,80(s1)
    80002c9a:	05050513          	addi	a0,a0,80
    80002c9e:	00004097          	auipc	ra,0x4
    80002ca2:	cd8080e7          	jalr	-808(ra) # 80006976 <cas>
    80002ca6:	f565                	bnez	a0,80002c8e <set_cpu+0x28>
  yield();
    80002ca8:	00000097          	auipc	ra,0x0
    80002cac:	938080e7          	jalr	-1736(ra) # 800025e0 <yield>
  return p->cpu_num;
}
    80002cb0:	48a8                	lw	a0,80(s1)
    80002cb2:	70a2                	ld	ra,40(sp)
    80002cb4:	7402                	ld	s0,32(sp)
    80002cb6:	64e2                	ld	s1,24(sp)
    80002cb8:	6942                	ld	s2,16(sp)
    80002cba:	69a2                	ld	s3,8(sp)
    80002cbc:	6a02                	ld	s4,0(sp)
    80002cbe:	6145                	addi	sp,sp,48
    80002cc0:	8082                	ret

0000000080002cc2 <get_cpu>:

int
get_cpu(void){
    80002cc2:	1141                	addi	sp,sp,-16
    80002cc4:	e422                	sd	s0,8(sp)
    80002cc6:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cc8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002ccc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cce:	10079073          	csrw	sstatus,a5
  asm volatile("mv %0, tp" : "=r" (x) );
    80002cd2:	8512                	mv	a0,tp
  intr_off();
  return cpuid();
}
    80002cd4:	2501                	sext.w	a0,a0
    80002cd6:	6422                	ld	s0,8(sp)
    80002cd8:	0141                	addi	sp,sp,16
    80002cda:	8082                	ret

0000000080002cdc <cpu_process_count>:

int
cpu_process_count(int cpuID){
    80002cdc:	1141                	addi	sp,sp,-16
    80002cde:	e422                	sd	s0,8(sp)
    80002ce0:	0800                	addi	s0,sp,16
  if(cpuID < NCPU)
    80002ce2:	479d                	li	a5,7
    80002ce4:	00a7cc63          	blt	a5,a0,80002cfc <cpu_process_count+0x20>
    return counters[cpuID];
    80002ce8:	050e                	slli	a0,a0,0x3
    80002cea:	0000e797          	auipc	a5,0xe
    80002cee:	5c678793          	addi	a5,a5,1478 # 800112b0 <pid_lock>
    80002cf2:	953e                	add	a0,a0,a5
    80002cf4:	5908                	lw	a0,48(a0)
  return -1;
    80002cf6:	6422                	ld	s0,8(sp)
    80002cf8:	0141                	addi	sp,sp,16
    80002cfa:	8082                	ret
  return -1;
    80002cfc:	557d                	li	a0,-1
    80002cfe:	bfe5                	j	80002cf6 <cpu_process_count+0x1a>

0000000080002d00 <swtch>:
    80002d00:	00153023          	sd	ra,0(a0)
    80002d04:	00253423          	sd	sp,8(a0)
    80002d08:	e900                	sd	s0,16(a0)
    80002d0a:	ed04                	sd	s1,24(a0)
    80002d0c:	03253023          	sd	s2,32(a0)
    80002d10:	03353423          	sd	s3,40(a0)
    80002d14:	03453823          	sd	s4,48(a0)
    80002d18:	03553c23          	sd	s5,56(a0)
    80002d1c:	05653023          	sd	s6,64(a0)
    80002d20:	05753423          	sd	s7,72(a0)
    80002d24:	05853823          	sd	s8,80(a0)
    80002d28:	05953c23          	sd	s9,88(a0)
    80002d2c:	07a53023          	sd	s10,96(a0)
    80002d30:	07b53423          	sd	s11,104(a0)
    80002d34:	0005b083          	ld	ra,0(a1)
    80002d38:	0085b103          	ld	sp,8(a1)
    80002d3c:	6980                	ld	s0,16(a1)
    80002d3e:	6d84                	ld	s1,24(a1)
    80002d40:	0205b903          	ld	s2,32(a1)
    80002d44:	0285b983          	ld	s3,40(a1)
    80002d48:	0305ba03          	ld	s4,48(a1)
    80002d4c:	0385ba83          	ld	s5,56(a1)
    80002d50:	0405bb03          	ld	s6,64(a1)
    80002d54:	0485bb83          	ld	s7,72(a1)
    80002d58:	0505bc03          	ld	s8,80(a1)
    80002d5c:	0585bc83          	ld	s9,88(a1)
    80002d60:	0605bd03          	ld	s10,96(a1)
    80002d64:	0685bd83          	ld	s11,104(a1)
    80002d68:	8082                	ret

0000000080002d6a <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002d6a:	1141                	addi	sp,sp,-16
    80002d6c:	e406                	sd	ra,8(sp)
    80002d6e:	e022                	sd	s0,0(sp)
    80002d70:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002d72:	00005597          	auipc	a1,0x5
    80002d76:	57e58593          	addi	a1,a1,1406 # 800082f0 <states.1835+0x30>
    80002d7a:	00015517          	auipc	a0,0x15
    80002d7e:	dc650513          	addi	a0,a0,-570 # 80017b40 <tickslock>
    80002d82:	ffffe097          	auipc	ra,0xffffe
    80002d86:	dd2080e7          	jalr	-558(ra) # 80000b54 <initlock>
}
    80002d8a:	60a2                	ld	ra,8(sp)
    80002d8c:	6402                	ld	s0,0(sp)
    80002d8e:	0141                	addi	sp,sp,16
    80002d90:	8082                	ret

0000000080002d92 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002d92:	1141                	addi	sp,sp,-16
    80002d94:	e422                	sd	s0,8(sp)
    80002d96:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d98:	00003797          	auipc	a5,0x3
    80002d9c:	50878793          	addi	a5,a5,1288 # 800062a0 <kernelvec>
    80002da0:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002da4:	6422                	ld	s0,8(sp)
    80002da6:	0141                	addi	sp,sp,16
    80002da8:	8082                	ret

0000000080002daa <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002daa:	1141                	addi	sp,sp,-16
    80002dac:	e406                	sd	ra,8(sp)
    80002dae:	e022                	sd	s0,0(sp)
    80002db0:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002db2:	fffff097          	auipc	ra,0xfffff
    80002db6:	efc080e7          	jalr	-260(ra) # 80001cae <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002dba:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002dbe:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002dc0:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002dc4:	00004617          	auipc	a2,0x4
    80002dc8:	23c60613          	addi	a2,a2,572 # 80007000 <_trampoline>
    80002dcc:	00004697          	auipc	a3,0x4
    80002dd0:	23468693          	addi	a3,a3,564 # 80007000 <_trampoline>
    80002dd4:	8e91                	sub	a3,a3,a2
    80002dd6:	040007b7          	lui	a5,0x4000
    80002dda:	17fd                	addi	a5,a5,-1
    80002ddc:	07b2                	slli	a5,a5,0xc
    80002dde:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002de0:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002de4:	6158                	ld	a4,128(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002de6:	180026f3          	csrr	a3,satp
    80002dea:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002dec:	6158                	ld	a4,128(a0)
    80002dee:	7534                	ld	a3,104(a0)
    80002df0:	6585                	lui	a1,0x1
    80002df2:	96ae                	add	a3,a3,a1
    80002df4:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002df6:	6158                	ld	a4,128(a0)
    80002df8:	00000697          	auipc	a3,0x0
    80002dfc:	13868693          	addi	a3,a3,312 # 80002f30 <usertrap>
    80002e00:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002e02:	6158                	ld	a4,128(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002e04:	8692                	mv	a3,tp
    80002e06:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e08:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002e0c:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002e10:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e14:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002e18:	6158                	ld	a4,128(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002e1a:	6f18                	ld	a4,24(a4)
    80002e1c:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002e20:	7d2c                	ld	a1,120(a0)
    80002e22:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002e24:	00004717          	auipc	a4,0x4
    80002e28:	26c70713          	addi	a4,a4,620 # 80007090 <userret>
    80002e2c:	8f11                	sub	a4,a4,a2
    80002e2e:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002e30:	577d                	li	a4,-1
    80002e32:	177e                	slli	a4,a4,0x3f
    80002e34:	8dd9                	or	a1,a1,a4
    80002e36:	02000537          	lui	a0,0x2000
    80002e3a:	157d                	addi	a0,a0,-1
    80002e3c:	0536                	slli	a0,a0,0xd
    80002e3e:	9782                	jalr	a5
}
    80002e40:	60a2                	ld	ra,8(sp)
    80002e42:	6402                	ld	s0,0(sp)
    80002e44:	0141                	addi	sp,sp,16
    80002e46:	8082                	ret

0000000080002e48 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002e48:	1101                	addi	sp,sp,-32
    80002e4a:	ec06                	sd	ra,24(sp)
    80002e4c:	e822                	sd	s0,16(sp)
    80002e4e:	e426                	sd	s1,8(sp)
    80002e50:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002e52:	00015497          	auipc	s1,0x15
    80002e56:	cee48493          	addi	s1,s1,-786 # 80017b40 <tickslock>
    80002e5a:	8526                	mv	a0,s1
    80002e5c:	ffffe097          	auipc	ra,0xffffe
    80002e60:	d88080e7          	jalr	-632(ra) # 80000be4 <acquire>
  ticks++;
    80002e64:	00006517          	auipc	a0,0x6
    80002e68:	1dc50513          	addi	a0,a0,476 # 80009040 <ticks>
    80002e6c:	411c                	lw	a5,0(a0)
    80002e6e:	2785                	addiw	a5,a5,1
    80002e70:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002e72:	00000097          	auipc	ra,0x0
    80002e76:	9c8080e7          	jalr	-1592(ra) # 8000283a <wakeup>
  release(&tickslock);
    80002e7a:	8526                	mv	a0,s1
    80002e7c:	ffffe097          	auipc	ra,0xffffe
    80002e80:	e1c080e7          	jalr	-484(ra) # 80000c98 <release>
}
    80002e84:	60e2                	ld	ra,24(sp)
    80002e86:	6442                	ld	s0,16(sp)
    80002e88:	64a2                	ld	s1,8(sp)
    80002e8a:	6105                	addi	sp,sp,32
    80002e8c:	8082                	ret

0000000080002e8e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002e8e:	1101                	addi	sp,sp,-32
    80002e90:	ec06                	sd	ra,24(sp)
    80002e92:	e822                	sd	s0,16(sp)
    80002e94:	e426                	sd	s1,8(sp)
    80002e96:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e98:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002e9c:	00074d63          	bltz	a4,80002eb6 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002ea0:	57fd                	li	a5,-1
    80002ea2:	17fe                	slli	a5,a5,0x3f
    80002ea4:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002ea6:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002ea8:	06f70363          	beq	a4,a5,80002f0e <devintr+0x80>
  }
}
    80002eac:	60e2                	ld	ra,24(sp)
    80002eae:	6442                	ld	s0,16(sp)
    80002eb0:	64a2                	ld	s1,8(sp)
    80002eb2:	6105                	addi	sp,sp,32
    80002eb4:	8082                	ret
     (scause & 0xff) == 9){
    80002eb6:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002eba:	46a5                	li	a3,9
    80002ebc:	fed792e3          	bne	a5,a3,80002ea0 <devintr+0x12>
    int irq = plic_claim();
    80002ec0:	00003097          	auipc	ra,0x3
    80002ec4:	4e8080e7          	jalr	1256(ra) # 800063a8 <plic_claim>
    80002ec8:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002eca:	47a9                	li	a5,10
    80002ecc:	02f50763          	beq	a0,a5,80002efa <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002ed0:	4785                	li	a5,1
    80002ed2:	02f50963          	beq	a0,a5,80002f04 <devintr+0x76>
    return 1;
    80002ed6:	4505                	li	a0,1
    } else if(irq){
    80002ed8:	d8f1                	beqz	s1,80002eac <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002eda:	85a6                	mv	a1,s1
    80002edc:	00005517          	auipc	a0,0x5
    80002ee0:	41c50513          	addi	a0,a0,1052 # 800082f8 <states.1835+0x38>
    80002ee4:	ffffd097          	auipc	ra,0xffffd
    80002ee8:	6a4080e7          	jalr	1700(ra) # 80000588 <printf>
      plic_complete(irq);
    80002eec:	8526                	mv	a0,s1
    80002eee:	00003097          	auipc	ra,0x3
    80002ef2:	4de080e7          	jalr	1246(ra) # 800063cc <plic_complete>
    return 1;
    80002ef6:	4505                	li	a0,1
    80002ef8:	bf55                	j	80002eac <devintr+0x1e>
      uartintr();
    80002efa:	ffffe097          	auipc	ra,0xffffe
    80002efe:	aae080e7          	jalr	-1362(ra) # 800009a8 <uartintr>
    80002f02:	b7ed                	j	80002eec <devintr+0x5e>
      virtio_disk_intr();
    80002f04:	00004097          	auipc	ra,0x4
    80002f08:	9a8080e7          	jalr	-1624(ra) # 800068ac <virtio_disk_intr>
    80002f0c:	b7c5                	j	80002eec <devintr+0x5e>
    if(cpuid() == 0){
    80002f0e:	fffff097          	auipc	ra,0xfffff
    80002f12:	d74080e7          	jalr	-652(ra) # 80001c82 <cpuid>
    80002f16:	c901                	beqz	a0,80002f26 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002f18:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002f1c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002f1e:	14479073          	csrw	sip,a5
    return 2;
    80002f22:	4509                	li	a0,2
    80002f24:	b761                	j	80002eac <devintr+0x1e>
      clockintr();
    80002f26:	00000097          	auipc	ra,0x0
    80002f2a:	f22080e7          	jalr	-222(ra) # 80002e48 <clockintr>
    80002f2e:	b7ed                	j	80002f18 <devintr+0x8a>

0000000080002f30 <usertrap>:
{
    80002f30:	1101                	addi	sp,sp,-32
    80002f32:	ec06                	sd	ra,24(sp)
    80002f34:	e822                	sd	s0,16(sp)
    80002f36:	e426                	sd	s1,8(sp)
    80002f38:	e04a                	sd	s2,0(sp)
    80002f3a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f3c:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002f40:	1007f793          	andi	a5,a5,256
    80002f44:	e3ad                	bnez	a5,80002fa6 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002f46:	00003797          	auipc	a5,0x3
    80002f4a:	35a78793          	addi	a5,a5,858 # 800062a0 <kernelvec>
    80002f4e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002f52:	fffff097          	auipc	ra,0xfffff
    80002f56:	d5c080e7          	jalr	-676(ra) # 80001cae <myproc>
    80002f5a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002f5c:	615c                	ld	a5,128(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f5e:	14102773          	csrr	a4,sepc
    80002f62:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f64:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002f68:	47a1                	li	a5,8
    80002f6a:	04f71c63          	bne	a4,a5,80002fc2 <usertrap+0x92>
    if(p->killed)
    80002f6e:	413c                	lw	a5,64(a0)
    80002f70:	e3b9                	bnez	a5,80002fb6 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002f72:	60d8                	ld	a4,128(s1)
    80002f74:	6f1c                	ld	a5,24(a4)
    80002f76:	0791                	addi	a5,a5,4
    80002f78:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f7a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002f7e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f82:	10079073          	csrw	sstatus,a5
    syscall();
    80002f86:	00000097          	auipc	ra,0x0
    80002f8a:	2e0080e7          	jalr	736(ra) # 80003266 <syscall>
  if(p->killed)
    80002f8e:	40bc                	lw	a5,64(s1)
    80002f90:	ebc1                	bnez	a5,80003020 <usertrap+0xf0>
  usertrapret();
    80002f92:	00000097          	auipc	ra,0x0
    80002f96:	e18080e7          	jalr	-488(ra) # 80002daa <usertrapret>
}
    80002f9a:	60e2                	ld	ra,24(sp)
    80002f9c:	6442                	ld	s0,16(sp)
    80002f9e:	64a2                	ld	s1,8(sp)
    80002fa0:	6902                	ld	s2,0(sp)
    80002fa2:	6105                	addi	sp,sp,32
    80002fa4:	8082                	ret
    panic("usertrap: not from user mode");
    80002fa6:	00005517          	auipc	a0,0x5
    80002faa:	37250513          	addi	a0,a0,882 # 80008318 <states.1835+0x58>
    80002fae:	ffffd097          	auipc	ra,0xffffd
    80002fb2:	590080e7          	jalr	1424(ra) # 8000053e <panic>
      exit(-1);
    80002fb6:	557d                	li	a0,-1
    80002fb8:	00000097          	auipc	ra,0x0
    80002fbc:	9c8080e7          	jalr	-1592(ra) # 80002980 <exit>
    80002fc0:	bf4d                	j	80002f72 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002fc2:	00000097          	auipc	ra,0x0
    80002fc6:	ecc080e7          	jalr	-308(ra) # 80002e8e <devintr>
    80002fca:	892a                	mv	s2,a0
    80002fcc:	c501                	beqz	a0,80002fd4 <usertrap+0xa4>
  if(p->killed)
    80002fce:	40bc                	lw	a5,64(s1)
    80002fd0:	c3a1                	beqz	a5,80003010 <usertrap+0xe0>
    80002fd2:	a815                	j	80003006 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002fd4:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002fd8:	44b0                	lw	a2,72(s1)
    80002fda:	00005517          	auipc	a0,0x5
    80002fde:	35e50513          	addi	a0,a0,862 # 80008338 <states.1835+0x78>
    80002fe2:	ffffd097          	auipc	ra,0xffffd
    80002fe6:	5a6080e7          	jalr	1446(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002fea:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002fee:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ff2:	00005517          	auipc	a0,0x5
    80002ff6:	37650513          	addi	a0,a0,886 # 80008368 <states.1835+0xa8>
    80002ffa:	ffffd097          	auipc	ra,0xffffd
    80002ffe:	58e080e7          	jalr	1422(ra) # 80000588 <printf>
    p->killed = 1;
    80003002:	4785                	li	a5,1
    80003004:	c0bc                	sw	a5,64(s1)
    exit(-1);
    80003006:	557d                	li	a0,-1
    80003008:	00000097          	auipc	ra,0x0
    8000300c:	978080e7          	jalr	-1672(ra) # 80002980 <exit>
  if(which_dev == 2)
    80003010:	4789                	li	a5,2
    80003012:	f8f910e3          	bne	s2,a5,80002f92 <usertrap+0x62>
    yield();
    80003016:	fffff097          	auipc	ra,0xfffff
    8000301a:	5ca080e7          	jalr	1482(ra) # 800025e0 <yield>
    8000301e:	bf95                	j	80002f92 <usertrap+0x62>
  int which_dev = 0;
    80003020:	4901                	li	s2,0
    80003022:	b7d5                	j	80003006 <usertrap+0xd6>

0000000080003024 <kerneltrap>:
{
    80003024:	7179                	addi	sp,sp,-48
    80003026:	f406                	sd	ra,40(sp)
    80003028:	f022                	sd	s0,32(sp)
    8000302a:	ec26                	sd	s1,24(sp)
    8000302c:	e84a                	sd	s2,16(sp)
    8000302e:	e44e                	sd	s3,8(sp)
    80003030:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003032:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003036:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000303a:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000303e:	1004f793          	andi	a5,s1,256
    80003042:	cb85                	beqz	a5,80003072 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003044:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80003048:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    8000304a:	ef85                	bnez	a5,80003082 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    8000304c:	00000097          	auipc	ra,0x0
    80003050:	e42080e7          	jalr	-446(ra) # 80002e8e <devintr>
    80003054:	cd1d                	beqz	a0,80003092 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003056:	4789                	li	a5,2
    80003058:	06f50a63          	beq	a0,a5,800030cc <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000305c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003060:	10049073          	csrw	sstatus,s1
}
    80003064:	70a2                	ld	ra,40(sp)
    80003066:	7402                	ld	s0,32(sp)
    80003068:	64e2                	ld	s1,24(sp)
    8000306a:	6942                	ld	s2,16(sp)
    8000306c:	69a2                	ld	s3,8(sp)
    8000306e:	6145                	addi	sp,sp,48
    80003070:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80003072:	00005517          	auipc	a0,0x5
    80003076:	31650513          	addi	a0,a0,790 # 80008388 <states.1835+0xc8>
    8000307a:	ffffd097          	auipc	ra,0xffffd
    8000307e:	4c4080e7          	jalr	1220(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80003082:	00005517          	auipc	a0,0x5
    80003086:	32e50513          	addi	a0,a0,814 # 800083b0 <states.1835+0xf0>
    8000308a:	ffffd097          	auipc	ra,0xffffd
    8000308e:	4b4080e7          	jalr	1204(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80003092:	85ce                	mv	a1,s3
    80003094:	00005517          	auipc	a0,0x5
    80003098:	33c50513          	addi	a0,a0,828 # 800083d0 <states.1835+0x110>
    8000309c:	ffffd097          	auipc	ra,0xffffd
    800030a0:	4ec080e7          	jalr	1260(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800030a4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800030a8:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800030ac:	00005517          	auipc	a0,0x5
    800030b0:	33450513          	addi	a0,a0,820 # 800083e0 <states.1835+0x120>
    800030b4:	ffffd097          	auipc	ra,0xffffd
    800030b8:	4d4080e7          	jalr	1236(ra) # 80000588 <printf>
    panic("kerneltrap");
    800030bc:	00005517          	auipc	a0,0x5
    800030c0:	33c50513          	addi	a0,a0,828 # 800083f8 <states.1835+0x138>
    800030c4:	ffffd097          	auipc	ra,0xffffd
    800030c8:	47a080e7          	jalr	1146(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800030cc:	fffff097          	auipc	ra,0xfffff
    800030d0:	be2080e7          	jalr	-1054(ra) # 80001cae <myproc>
    800030d4:	d541                	beqz	a0,8000305c <kerneltrap+0x38>
    800030d6:	fffff097          	auipc	ra,0xfffff
    800030da:	bd8080e7          	jalr	-1064(ra) # 80001cae <myproc>
    800030de:	5918                	lw	a4,48(a0)
    800030e0:	4791                	li	a5,4
    800030e2:	f6f71de3          	bne	a4,a5,8000305c <kerneltrap+0x38>
    yield();
    800030e6:	fffff097          	auipc	ra,0xfffff
    800030ea:	4fa080e7          	jalr	1274(ra) # 800025e0 <yield>
    800030ee:	b7bd                	j	8000305c <kerneltrap+0x38>

00000000800030f0 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800030f0:	1101                	addi	sp,sp,-32
    800030f2:	ec06                	sd	ra,24(sp)
    800030f4:	e822                	sd	s0,16(sp)
    800030f6:	e426                	sd	s1,8(sp)
    800030f8:	1000                	addi	s0,sp,32
    800030fa:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800030fc:	fffff097          	auipc	ra,0xfffff
    80003100:	bb2080e7          	jalr	-1102(ra) # 80001cae <myproc>
  switch (n) {
    80003104:	4795                	li	a5,5
    80003106:	0497e163          	bltu	a5,s1,80003148 <argraw+0x58>
    8000310a:	048a                	slli	s1,s1,0x2
    8000310c:	00005717          	auipc	a4,0x5
    80003110:	32470713          	addi	a4,a4,804 # 80008430 <states.1835+0x170>
    80003114:	94ba                	add	s1,s1,a4
    80003116:	409c                	lw	a5,0(s1)
    80003118:	97ba                	add	a5,a5,a4
    8000311a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    8000311c:	615c                	ld	a5,128(a0)
    8000311e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80003120:	60e2                	ld	ra,24(sp)
    80003122:	6442                	ld	s0,16(sp)
    80003124:	64a2                	ld	s1,8(sp)
    80003126:	6105                	addi	sp,sp,32
    80003128:	8082                	ret
    return p->trapframe->a1;
    8000312a:	615c                	ld	a5,128(a0)
    8000312c:	7fa8                	ld	a0,120(a5)
    8000312e:	bfcd                	j	80003120 <argraw+0x30>
    return p->trapframe->a2;
    80003130:	615c                	ld	a5,128(a0)
    80003132:	63c8                	ld	a0,128(a5)
    80003134:	b7f5                	j	80003120 <argraw+0x30>
    return p->trapframe->a3;
    80003136:	615c                	ld	a5,128(a0)
    80003138:	67c8                	ld	a0,136(a5)
    8000313a:	b7dd                	j	80003120 <argraw+0x30>
    return p->trapframe->a4;
    8000313c:	615c                	ld	a5,128(a0)
    8000313e:	6bc8                	ld	a0,144(a5)
    80003140:	b7c5                	j	80003120 <argraw+0x30>
    return p->trapframe->a5;
    80003142:	615c                	ld	a5,128(a0)
    80003144:	6fc8                	ld	a0,152(a5)
    80003146:	bfe9                	j	80003120 <argraw+0x30>
  panic("argraw");
    80003148:	00005517          	auipc	a0,0x5
    8000314c:	2c050513          	addi	a0,a0,704 # 80008408 <states.1835+0x148>
    80003150:	ffffd097          	auipc	ra,0xffffd
    80003154:	3ee080e7          	jalr	1006(ra) # 8000053e <panic>

0000000080003158 <fetchaddr>:
{
    80003158:	1101                	addi	sp,sp,-32
    8000315a:	ec06                	sd	ra,24(sp)
    8000315c:	e822                	sd	s0,16(sp)
    8000315e:	e426                	sd	s1,8(sp)
    80003160:	e04a                	sd	s2,0(sp)
    80003162:	1000                	addi	s0,sp,32
    80003164:	84aa                	mv	s1,a0
    80003166:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003168:	fffff097          	auipc	ra,0xfffff
    8000316c:	b46080e7          	jalr	-1210(ra) # 80001cae <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80003170:	793c                	ld	a5,112(a0)
    80003172:	02f4f863          	bgeu	s1,a5,800031a2 <fetchaddr+0x4a>
    80003176:	00848713          	addi	a4,s1,8
    8000317a:	02e7e663          	bltu	a5,a4,800031a6 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    8000317e:	46a1                	li	a3,8
    80003180:	8626                	mv	a2,s1
    80003182:	85ca                	mv	a1,s2
    80003184:	7d28                	ld	a0,120(a0)
    80003186:	ffffe097          	auipc	ra,0xffffe
    8000318a:	578080e7          	jalr	1400(ra) # 800016fe <copyin>
    8000318e:	00a03533          	snez	a0,a0
    80003192:	40a00533          	neg	a0,a0
}
    80003196:	60e2                	ld	ra,24(sp)
    80003198:	6442                	ld	s0,16(sp)
    8000319a:	64a2                	ld	s1,8(sp)
    8000319c:	6902                	ld	s2,0(sp)
    8000319e:	6105                	addi	sp,sp,32
    800031a0:	8082                	ret
    return -1;
    800031a2:	557d                	li	a0,-1
    800031a4:	bfcd                	j	80003196 <fetchaddr+0x3e>
    800031a6:	557d                	li	a0,-1
    800031a8:	b7fd                	j	80003196 <fetchaddr+0x3e>

00000000800031aa <fetchstr>:
{
    800031aa:	7179                	addi	sp,sp,-48
    800031ac:	f406                	sd	ra,40(sp)
    800031ae:	f022                	sd	s0,32(sp)
    800031b0:	ec26                	sd	s1,24(sp)
    800031b2:	e84a                	sd	s2,16(sp)
    800031b4:	e44e                	sd	s3,8(sp)
    800031b6:	1800                	addi	s0,sp,48
    800031b8:	892a                	mv	s2,a0
    800031ba:	84ae                	mv	s1,a1
    800031bc:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800031be:	fffff097          	auipc	ra,0xfffff
    800031c2:	af0080e7          	jalr	-1296(ra) # 80001cae <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    800031c6:	86ce                	mv	a3,s3
    800031c8:	864a                	mv	a2,s2
    800031ca:	85a6                	mv	a1,s1
    800031cc:	7d28                	ld	a0,120(a0)
    800031ce:	ffffe097          	auipc	ra,0xffffe
    800031d2:	5bc080e7          	jalr	1468(ra) # 8000178a <copyinstr>
  if(err < 0)
    800031d6:	00054763          	bltz	a0,800031e4 <fetchstr+0x3a>
  return strlen(buf);
    800031da:	8526                	mv	a0,s1
    800031dc:	ffffe097          	auipc	ra,0xffffe
    800031e0:	c88080e7          	jalr	-888(ra) # 80000e64 <strlen>
}
    800031e4:	70a2                	ld	ra,40(sp)
    800031e6:	7402                	ld	s0,32(sp)
    800031e8:	64e2                	ld	s1,24(sp)
    800031ea:	6942                	ld	s2,16(sp)
    800031ec:	69a2                	ld	s3,8(sp)
    800031ee:	6145                	addi	sp,sp,48
    800031f0:	8082                	ret

00000000800031f2 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    800031f2:	1101                	addi	sp,sp,-32
    800031f4:	ec06                	sd	ra,24(sp)
    800031f6:	e822                	sd	s0,16(sp)
    800031f8:	e426                	sd	s1,8(sp)
    800031fa:	1000                	addi	s0,sp,32
    800031fc:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800031fe:	00000097          	auipc	ra,0x0
    80003202:	ef2080e7          	jalr	-270(ra) # 800030f0 <argraw>
    80003206:	c088                	sw	a0,0(s1)
  return 0;
}
    80003208:	4501                	li	a0,0
    8000320a:	60e2                	ld	ra,24(sp)
    8000320c:	6442                	ld	s0,16(sp)
    8000320e:	64a2                	ld	s1,8(sp)
    80003210:	6105                	addi	sp,sp,32
    80003212:	8082                	ret

0000000080003214 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003214:	1101                	addi	sp,sp,-32
    80003216:	ec06                	sd	ra,24(sp)
    80003218:	e822                	sd	s0,16(sp)
    8000321a:	e426                	sd	s1,8(sp)
    8000321c:	1000                	addi	s0,sp,32
    8000321e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003220:	00000097          	auipc	ra,0x0
    80003224:	ed0080e7          	jalr	-304(ra) # 800030f0 <argraw>
    80003228:	e088                	sd	a0,0(s1)
  return 0;
}
    8000322a:	4501                	li	a0,0
    8000322c:	60e2                	ld	ra,24(sp)
    8000322e:	6442                	ld	s0,16(sp)
    80003230:	64a2                	ld	s1,8(sp)
    80003232:	6105                	addi	sp,sp,32
    80003234:	8082                	ret

0000000080003236 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003236:	1101                	addi	sp,sp,-32
    80003238:	ec06                	sd	ra,24(sp)
    8000323a:	e822                	sd	s0,16(sp)
    8000323c:	e426                	sd	s1,8(sp)
    8000323e:	e04a                	sd	s2,0(sp)
    80003240:	1000                	addi	s0,sp,32
    80003242:	84ae                	mv	s1,a1
    80003244:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003246:	00000097          	auipc	ra,0x0
    8000324a:	eaa080e7          	jalr	-342(ra) # 800030f0 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    8000324e:	864a                	mv	a2,s2
    80003250:	85a6                	mv	a1,s1
    80003252:	00000097          	auipc	ra,0x0
    80003256:	f58080e7          	jalr	-168(ra) # 800031aa <fetchstr>
}
    8000325a:	60e2                	ld	ra,24(sp)
    8000325c:	6442                	ld	s0,16(sp)
    8000325e:	64a2                	ld	s1,8(sp)
    80003260:	6902                	ld	s2,0(sp)
    80003262:	6105                	addi	sp,sp,32
    80003264:	8082                	ret

0000000080003266 <syscall>:

};

void
syscall(void)
{
    80003266:	1101                	addi	sp,sp,-32
    80003268:	ec06                	sd	ra,24(sp)
    8000326a:	e822                	sd	s0,16(sp)
    8000326c:	e426                	sd	s1,8(sp)
    8000326e:	e04a                	sd	s2,0(sp)
    80003270:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003272:	fffff097          	auipc	ra,0xfffff
    80003276:	a3c080e7          	jalr	-1476(ra) # 80001cae <myproc>
    8000327a:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    8000327c:	08053903          	ld	s2,128(a0)
    80003280:	0a893783          	ld	a5,168(s2)
    80003284:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003288:	37fd                	addiw	a5,a5,-1
    8000328a:	475d                	li	a4,23
    8000328c:	00f76f63          	bltu	a4,a5,800032aa <syscall+0x44>
    80003290:	00369713          	slli	a4,a3,0x3
    80003294:	00005797          	auipc	a5,0x5
    80003298:	1b478793          	addi	a5,a5,436 # 80008448 <syscalls>
    8000329c:	97ba                	add	a5,a5,a4
    8000329e:	639c                	ld	a5,0(a5)
    800032a0:	c789                	beqz	a5,800032aa <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    800032a2:	9782                	jalr	a5
    800032a4:	06a93823          	sd	a0,112(s2)
    800032a8:	a839                	j	800032c6 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800032aa:	18048613          	addi	a2,s1,384
    800032ae:	44ac                	lw	a1,72(s1)
    800032b0:	00005517          	auipc	a0,0x5
    800032b4:	16050513          	addi	a0,a0,352 # 80008410 <states.1835+0x150>
    800032b8:	ffffd097          	auipc	ra,0xffffd
    800032bc:	2d0080e7          	jalr	720(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800032c0:	60dc                	ld	a5,128(s1)
    800032c2:	577d                	li	a4,-1
    800032c4:	fbb8                	sd	a4,112(a5)
  }
}
    800032c6:	60e2                	ld	ra,24(sp)
    800032c8:	6442                	ld	s0,16(sp)
    800032ca:	64a2                	ld	s1,8(sp)
    800032cc:	6902                	ld	s2,0(sp)
    800032ce:	6105                	addi	sp,sp,32
    800032d0:	8082                	ret

00000000800032d2 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800032d2:	1101                	addi	sp,sp,-32
    800032d4:	ec06                	sd	ra,24(sp)
    800032d6:	e822                	sd	s0,16(sp)
    800032d8:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    800032da:	fec40593          	addi	a1,s0,-20
    800032de:	4501                	li	a0,0
    800032e0:	00000097          	auipc	ra,0x0
    800032e4:	f12080e7          	jalr	-238(ra) # 800031f2 <argint>
    return -1;
    800032e8:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800032ea:	00054963          	bltz	a0,800032fc <sys_exit+0x2a>
  exit(n);
    800032ee:	fec42503          	lw	a0,-20(s0)
    800032f2:	fffff097          	auipc	ra,0xfffff
    800032f6:	68e080e7          	jalr	1678(ra) # 80002980 <exit>
  return 0;  // not reached
    800032fa:	4781                	li	a5,0
}
    800032fc:	853e                	mv	a0,a5
    800032fe:	60e2                	ld	ra,24(sp)
    80003300:	6442                	ld	s0,16(sp)
    80003302:	6105                	addi	sp,sp,32
    80003304:	8082                	ret

0000000080003306 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003306:	1141                	addi	sp,sp,-16
    80003308:	e406                	sd	ra,8(sp)
    8000330a:	e022                	sd	s0,0(sp)
    8000330c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000330e:	fffff097          	auipc	ra,0xfffff
    80003312:	9a0080e7          	jalr	-1632(ra) # 80001cae <myproc>
}
    80003316:	4528                	lw	a0,72(a0)
    80003318:	60a2                	ld	ra,8(sp)
    8000331a:	6402                	ld	s0,0(sp)
    8000331c:	0141                	addi	sp,sp,16
    8000331e:	8082                	ret

0000000080003320 <sys_fork>:

uint64
sys_fork(void)
{
    80003320:	1141                	addi	sp,sp,-16
    80003322:	e406                	sd	ra,8(sp)
    80003324:	e022                	sd	s0,0(sp)
    80003326:	0800                	addi	s0,sp,16
  return fork();
    80003328:	fffff097          	auipc	ra,0xfffff
    8000332c:	e88080e7          	jalr	-376(ra) # 800021b0 <fork>
}
    80003330:	60a2                	ld	ra,8(sp)
    80003332:	6402                	ld	s0,0(sp)
    80003334:	0141                	addi	sp,sp,16
    80003336:	8082                	ret

0000000080003338 <sys_wait>:

uint64
sys_wait(void)
{
    80003338:	1101                	addi	sp,sp,-32
    8000333a:	ec06                	sd	ra,24(sp)
    8000333c:	e822                	sd	s0,16(sp)
    8000333e:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003340:	fe840593          	addi	a1,s0,-24
    80003344:	4501                	li	a0,0
    80003346:	00000097          	auipc	ra,0x0
    8000334a:	ece080e7          	jalr	-306(ra) # 80003214 <argaddr>
    8000334e:	87aa                	mv	a5,a0
    return -1;
    80003350:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003352:	0007c863          	bltz	a5,80003362 <sys_wait+0x2a>
  return wait(p);
    80003356:	fe843503          	ld	a0,-24(s0)
    8000335a:	fffff097          	auipc	ra,0xfffff
    8000335e:	3b8080e7          	jalr	952(ra) # 80002712 <wait>
}
    80003362:	60e2                	ld	ra,24(sp)
    80003364:	6442                	ld	s0,16(sp)
    80003366:	6105                	addi	sp,sp,32
    80003368:	8082                	ret

000000008000336a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000336a:	7179                	addi	sp,sp,-48
    8000336c:	f406                	sd	ra,40(sp)
    8000336e:	f022                	sd	s0,32(sp)
    80003370:	ec26                	sd	s1,24(sp)
    80003372:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003374:	fdc40593          	addi	a1,s0,-36
    80003378:	4501                	li	a0,0
    8000337a:	00000097          	auipc	ra,0x0
    8000337e:	e78080e7          	jalr	-392(ra) # 800031f2 <argint>
    80003382:	87aa                	mv	a5,a0
    return -1;
    80003384:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003386:	0207c063          	bltz	a5,800033a6 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    8000338a:	fffff097          	auipc	ra,0xfffff
    8000338e:	924080e7          	jalr	-1756(ra) # 80001cae <myproc>
    80003392:	5924                	lw	s1,112(a0)
  if(growproc(n) < 0)
    80003394:	fdc42503          	lw	a0,-36(s0)
    80003398:	fffff097          	auipc	ra,0xfffff
    8000339c:	d10080e7          	jalr	-752(ra) # 800020a8 <growproc>
    800033a0:	00054863          	bltz	a0,800033b0 <sys_sbrk+0x46>
    return -1;
  return addr;
    800033a4:	8526                	mv	a0,s1
}
    800033a6:	70a2                	ld	ra,40(sp)
    800033a8:	7402                	ld	s0,32(sp)
    800033aa:	64e2                	ld	s1,24(sp)
    800033ac:	6145                	addi	sp,sp,48
    800033ae:	8082                	ret
    return -1;
    800033b0:	557d                	li	a0,-1
    800033b2:	bfd5                	j	800033a6 <sys_sbrk+0x3c>

00000000800033b4 <sys_sleep>:

uint64
sys_sleep(void)
{
    800033b4:	7139                	addi	sp,sp,-64
    800033b6:	fc06                	sd	ra,56(sp)
    800033b8:	f822                	sd	s0,48(sp)
    800033ba:	f426                	sd	s1,40(sp)
    800033bc:	f04a                	sd	s2,32(sp)
    800033be:	ec4e                	sd	s3,24(sp)
    800033c0:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800033c2:	fcc40593          	addi	a1,s0,-52
    800033c6:	4501                	li	a0,0
    800033c8:	00000097          	auipc	ra,0x0
    800033cc:	e2a080e7          	jalr	-470(ra) # 800031f2 <argint>
    return -1;
    800033d0:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800033d2:	06054563          	bltz	a0,8000343c <sys_sleep+0x88>
  acquire(&tickslock);
    800033d6:	00014517          	auipc	a0,0x14
    800033da:	76a50513          	addi	a0,a0,1898 # 80017b40 <tickslock>
    800033de:	ffffe097          	auipc	ra,0xffffe
    800033e2:	806080e7          	jalr	-2042(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    800033e6:	00006917          	auipc	s2,0x6
    800033ea:	c5a92903          	lw	s2,-934(s2) # 80009040 <ticks>
  while(ticks - ticks0 < n){
    800033ee:	fcc42783          	lw	a5,-52(s0)
    800033f2:	cf85                	beqz	a5,8000342a <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800033f4:	00014997          	auipc	s3,0x14
    800033f8:	74c98993          	addi	s3,s3,1868 # 80017b40 <tickslock>
    800033fc:	00006497          	auipc	s1,0x6
    80003400:	c4448493          	addi	s1,s1,-956 # 80009040 <ticks>
    if(myproc()->killed){
    80003404:	fffff097          	auipc	ra,0xfffff
    80003408:	8aa080e7          	jalr	-1878(ra) # 80001cae <myproc>
    8000340c:	413c                	lw	a5,64(a0)
    8000340e:	ef9d                	bnez	a5,8000344c <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003410:	85ce                	mv	a1,s3
    80003412:	8526                	mv	a0,s1
    80003414:	fffff097          	auipc	ra,0xfffff
    80003418:	22a080e7          	jalr	554(ra) # 8000263e <sleep>
  while(ticks - ticks0 < n){
    8000341c:	409c                	lw	a5,0(s1)
    8000341e:	412787bb          	subw	a5,a5,s2
    80003422:	fcc42703          	lw	a4,-52(s0)
    80003426:	fce7efe3          	bltu	a5,a4,80003404 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000342a:	00014517          	auipc	a0,0x14
    8000342e:	71650513          	addi	a0,a0,1814 # 80017b40 <tickslock>
    80003432:	ffffe097          	auipc	ra,0xffffe
    80003436:	866080e7          	jalr	-1946(ra) # 80000c98 <release>
  return 0;
    8000343a:	4781                	li	a5,0
}
    8000343c:	853e                	mv	a0,a5
    8000343e:	70e2                	ld	ra,56(sp)
    80003440:	7442                	ld	s0,48(sp)
    80003442:	74a2                	ld	s1,40(sp)
    80003444:	7902                	ld	s2,32(sp)
    80003446:	69e2                	ld	s3,24(sp)
    80003448:	6121                	addi	sp,sp,64
    8000344a:	8082                	ret
      release(&tickslock);
    8000344c:	00014517          	auipc	a0,0x14
    80003450:	6f450513          	addi	a0,a0,1780 # 80017b40 <tickslock>
    80003454:	ffffe097          	auipc	ra,0xffffe
    80003458:	844080e7          	jalr	-1980(ra) # 80000c98 <release>
      return -1;
    8000345c:	57fd                	li	a5,-1
    8000345e:	bff9                	j	8000343c <sys_sleep+0x88>

0000000080003460 <sys_kill>:

uint64
sys_kill(void)
{
    80003460:	1101                	addi	sp,sp,-32
    80003462:	ec06                	sd	ra,24(sp)
    80003464:	e822                	sd	s0,16(sp)
    80003466:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003468:	fec40593          	addi	a1,s0,-20
    8000346c:	4501                	li	a0,0
    8000346e:	00000097          	auipc	ra,0x0
    80003472:	d84080e7          	jalr	-636(ra) # 800031f2 <argint>
    80003476:	87aa                	mv	a5,a0
    return -1;
    80003478:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    8000347a:	0007c863          	bltz	a5,8000348a <sys_kill+0x2a>
  return kill(pid);
    8000347e:	fec42503          	lw	a0,-20(s0)
    80003482:	fffff097          	auipc	ra,0xfffff
    80003486:	606080e7          	jalr	1542(ra) # 80002a88 <kill>
}
    8000348a:	60e2                	ld	ra,24(sp)
    8000348c:	6442                	ld	s0,16(sp)
    8000348e:	6105                	addi	sp,sp,32
    80003490:	8082                	ret

0000000080003492 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003492:	1101                	addi	sp,sp,-32
    80003494:	ec06                	sd	ra,24(sp)
    80003496:	e822                	sd	s0,16(sp)
    80003498:	e426                	sd	s1,8(sp)
    8000349a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000349c:	00014517          	auipc	a0,0x14
    800034a0:	6a450513          	addi	a0,a0,1700 # 80017b40 <tickslock>
    800034a4:	ffffd097          	auipc	ra,0xffffd
    800034a8:	740080e7          	jalr	1856(ra) # 80000be4 <acquire>
  xticks = ticks;
    800034ac:	00006497          	auipc	s1,0x6
    800034b0:	b944a483          	lw	s1,-1132(s1) # 80009040 <ticks>
  release(&tickslock);
    800034b4:	00014517          	auipc	a0,0x14
    800034b8:	68c50513          	addi	a0,a0,1676 # 80017b40 <tickslock>
    800034bc:	ffffd097          	auipc	ra,0xffffd
    800034c0:	7dc080e7          	jalr	2012(ra) # 80000c98 <release>
  return xticks;
}
    800034c4:	02049513          	slli	a0,s1,0x20
    800034c8:	9101                	srli	a0,a0,0x20
    800034ca:	60e2                	ld	ra,24(sp)
    800034cc:	6442                	ld	s0,16(sp)
    800034ce:	64a2                	ld	s1,8(sp)
    800034d0:	6105                	addi	sp,sp,32
    800034d2:	8082                	ret

00000000800034d4 <sys_set_cpu>:

uint64
sys_set_cpu(void){
    800034d4:	1101                	addi	sp,sp,-32
    800034d6:	ec06                	sd	ra,24(sp)
    800034d8:	e822                	sd	s0,16(sp)
    800034da:	1000                	addi	s0,sp,32
  int cid;
  if(argint(0, &cid)< 0)
    800034dc:	fec40593          	addi	a1,s0,-20
    800034e0:	4501                	li	a0,0
    800034e2:	00000097          	auipc	ra,0x0
    800034e6:	d10080e7          	jalr	-752(ra) # 800031f2 <argint>
    800034ea:	87aa                	mv	a5,a0
    return -1;
    800034ec:	557d                	li	a0,-1
  if(argint(0, &cid)< 0)
    800034ee:	0007c863          	bltz	a5,800034fe <sys_set_cpu+0x2a>
  return set_cpu(cid);
    800034f2:	fec42503          	lw	a0,-20(s0)
    800034f6:	fffff097          	auipc	ra,0xfffff
    800034fa:	770080e7          	jalr	1904(ra) # 80002c66 <set_cpu>
}
    800034fe:	60e2                	ld	ra,24(sp)
    80003500:	6442                	ld	s0,16(sp)
    80003502:	6105                	addi	sp,sp,32
    80003504:	8082                	ret

0000000080003506 <sys_get_cpu>:

uint64
sys_get_cpu(void){
    80003506:	1141                	addi	sp,sp,-16
    80003508:	e406                	sd	ra,8(sp)
    8000350a:	e022                	sd	s0,0(sp)
    8000350c:	0800                	addi	s0,sp,16
  return get_cpu();
    8000350e:	fffff097          	auipc	ra,0xfffff
    80003512:	7b4080e7          	jalr	1972(ra) # 80002cc2 <get_cpu>
}
    80003516:	60a2                	ld	ra,8(sp)
    80003518:	6402                	ld	s0,0(sp)
    8000351a:	0141                	addi	sp,sp,16
    8000351c:	8082                	ret

000000008000351e <sys_cpu_process_count>:

uint64
sys_cpu_process_count(void){
    8000351e:	1101                	addi	sp,sp,-32
    80003520:	ec06                	sd	ra,24(sp)
    80003522:	e822                	sd	s0,16(sp)
    80003524:	1000                	addi	s0,sp,32
  int cpu_index;
  if(argint(0, &cpu_index)){
    80003526:	fec40593          	addi	a1,s0,-20
    8000352a:	4501                	li	a0,0
    8000352c:	00000097          	auipc	ra,0x0
    80003530:	cc6080e7          	jalr	-826(ra) # 800031f2 <argint>
    80003534:	87aa                	mv	a5,a0
    return cpu_process_count(cpu_index);
  }
  return -1;
    80003536:	557d                	li	a0,-1
  if(argint(0, &cpu_index)){
    80003538:	e789                	bnez	a5,80003542 <sys_cpu_process_count+0x24>
    8000353a:	60e2                	ld	ra,24(sp)
    8000353c:	6442                	ld	s0,16(sp)
    8000353e:	6105                	addi	sp,sp,32
    80003540:	8082                	ret
    return cpu_process_count(cpu_index);
    80003542:	fec42503          	lw	a0,-20(s0)
    80003546:	fffff097          	auipc	ra,0xfffff
    8000354a:	796080e7          	jalr	1942(ra) # 80002cdc <cpu_process_count>
    8000354e:	b7f5                	j	8000353a <sys_cpu_process_count+0x1c>

0000000080003550 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003550:	7179                	addi	sp,sp,-48
    80003552:	f406                	sd	ra,40(sp)
    80003554:	f022                	sd	s0,32(sp)
    80003556:	ec26                	sd	s1,24(sp)
    80003558:	e84a                	sd	s2,16(sp)
    8000355a:	e44e                	sd	s3,8(sp)
    8000355c:	e052                	sd	s4,0(sp)
    8000355e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003560:	00005597          	auipc	a1,0x5
    80003564:	fb058593          	addi	a1,a1,-80 # 80008510 <syscalls+0xc8>
    80003568:	00014517          	auipc	a0,0x14
    8000356c:	5f050513          	addi	a0,a0,1520 # 80017b58 <bcache>
    80003570:	ffffd097          	auipc	ra,0xffffd
    80003574:	5e4080e7          	jalr	1508(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003578:	0001c797          	auipc	a5,0x1c
    8000357c:	5e078793          	addi	a5,a5,1504 # 8001fb58 <bcache+0x8000>
    80003580:	0001d717          	auipc	a4,0x1d
    80003584:	84070713          	addi	a4,a4,-1984 # 8001fdc0 <bcache+0x8268>
    80003588:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000358c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003590:	00014497          	auipc	s1,0x14
    80003594:	5e048493          	addi	s1,s1,1504 # 80017b70 <bcache+0x18>
    b->next = bcache.head.next;
    80003598:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000359a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000359c:	00005a17          	auipc	s4,0x5
    800035a0:	f7ca0a13          	addi	s4,s4,-132 # 80008518 <syscalls+0xd0>
    b->next = bcache.head.next;
    800035a4:	2b893783          	ld	a5,696(s2)
    800035a8:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800035aa:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800035ae:	85d2                	mv	a1,s4
    800035b0:	01048513          	addi	a0,s1,16
    800035b4:	00001097          	auipc	ra,0x1
    800035b8:	4bc080e7          	jalr	1212(ra) # 80004a70 <initsleeplock>
    bcache.head.next->prev = b;
    800035bc:	2b893783          	ld	a5,696(s2)
    800035c0:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800035c2:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800035c6:	45848493          	addi	s1,s1,1112
    800035ca:	fd349de3          	bne	s1,s3,800035a4 <binit+0x54>
  }
}
    800035ce:	70a2                	ld	ra,40(sp)
    800035d0:	7402                	ld	s0,32(sp)
    800035d2:	64e2                	ld	s1,24(sp)
    800035d4:	6942                	ld	s2,16(sp)
    800035d6:	69a2                	ld	s3,8(sp)
    800035d8:	6a02                	ld	s4,0(sp)
    800035da:	6145                	addi	sp,sp,48
    800035dc:	8082                	ret

00000000800035de <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800035de:	7179                	addi	sp,sp,-48
    800035e0:	f406                	sd	ra,40(sp)
    800035e2:	f022                	sd	s0,32(sp)
    800035e4:	ec26                	sd	s1,24(sp)
    800035e6:	e84a                	sd	s2,16(sp)
    800035e8:	e44e                	sd	s3,8(sp)
    800035ea:	1800                	addi	s0,sp,48
    800035ec:	89aa                	mv	s3,a0
    800035ee:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800035f0:	00014517          	auipc	a0,0x14
    800035f4:	56850513          	addi	a0,a0,1384 # 80017b58 <bcache>
    800035f8:	ffffd097          	auipc	ra,0xffffd
    800035fc:	5ec080e7          	jalr	1516(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003600:	0001d497          	auipc	s1,0x1d
    80003604:	8104b483          	ld	s1,-2032(s1) # 8001fe10 <bcache+0x82b8>
    80003608:	0001c797          	auipc	a5,0x1c
    8000360c:	7b878793          	addi	a5,a5,1976 # 8001fdc0 <bcache+0x8268>
    80003610:	02f48f63          	beq	s1,a5,8000364e <bread+0x70>
    80003614:	873e                	mv	a4,a5
    80003616:	a021                	j	8000361e <bread+0x40>
    80003618:	68a4                	ld	s1,80(s1)
    8000361a:	02e48a63          	beq	s1,a4,8000364e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000361e:	449c                	lw	a5,8(s1)
    80003620:	ff379ce3          	bne	a5,s3,80003618 <bread+0x3a>
    80003624:	44dc                	lw	a5,12(s1)
    80003626:	ff2799e3          	bne	a5,s2,80003618 <bread+0x3a>
      b->refcnt++;
    8000362a:	40bc                	lw	a5,64(s1)
    8000362c:	2785                	addiw	a5,a5,1
    8000362e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003630:	00014517          	auipc	a0,0x14
    80003634:	52850513          	addi	a0,a0,1320 # 80017b58 <bcache>
    80003638:	ffffd097          	auipc	ra,0xffffd
    8000363c:	660080e7          	jalr	1632(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003640:	01048513          	addi	a0,s1,16
    80003644:	00001097          	auipc	ra,0x1
    80003648:	466080e7          	jalr	1126(ra) # 80004aaa <acquiresleep>
      return b;
    8000364c:	a8b9                	j	800036aa <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000364e:	0001c497          	auipc	s1,0x1c
    80003652:	7ba4b483          	ld	s1,1978(s1) # 8001fe08 <bcache+0x82b0>
    80003656:	0001c797          	auipc	a5,0x1c
    8000365a:	76a78793          	addi	a5,a5,1898 # 8001fdc0 <bcache+0x8268>
    8000365e:	00f48863          	beq	s1,a5,8000366e <bread+0x90>
    80003662:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003664:	40bc                	lw	a5,64(s1)
    80003666:	cf81                	beqz	a5,8000367e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003668:	64a4                	ld	s1,72(s1)
    8000366a:	fee49de3          	bne	s1,a4,80003664 <bread+0x86>
  panic("bget: no buffers");
    8000366e:	00005517          	auipc	a0,0x5
    80003672:	eb250513          	addi	a0,a0,-334 # 80008520 <syscalls+0xd8>
    80003676:	ffffd097          	auipc	ra,0xffffd
    8000367a:	ec8080e7          	jalr	-312(ra) # 8000053e <panic>
      b->dev = dev;
    8000367e:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003682:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003686:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000368a:	4785                	li	a5,1
    8000368c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000368e:	00014517          	auipc	a0,0x14
    80003692:	4ca50513          	addi	a0,a0,1226 # 80017b58 <bcache>
    80003696:	ffffd097          	auipc	ra,0xffffd
    8000369a:	602080e7          	jalr	1538(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000369e:	01048513          	addi	a0,s1,16
    800036a2:	00001097          	auipc	ra,0x1
    800036a6:	408080e7          	jalr	1032(ra) # 80004aaa <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800036aa:	409c                	lw	a5,0(s1)
    800036ac:	cb89                	beqz	a5,800036be <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800036ae:	8526                	mv	a0,s1
    800036b0:	70a2                	ld	ra,40(sp)
    800036b2:	7402                	ld	s0,32(sp)
    800036b4:	64e2                	ld	s1,24(sp)
    800036b6:	6942                	ld	s2,16(sp)
    800036b8:	69a2                	ld	s3,8(sp)
    800036ba:	6145                	addi	sp,sp,48
    800036bc:	8082                	ret
    virtio_disk_rw(b, 0);
    800036be:	4581                	li	a1,0
    800036c0:	8526                	mv	a0,s1
    800036c2:	00003097          	auipc	ra,0x3
    800036c6:	f14080e7          	jalr	-236(ra) # 800065d6 <virtio_disk_rw>
    b->valid = 1;
    800036ca:	4785                	li	a5,1
    800036cc:	c09c                	sw	a5,0(s1)
  return b;
    800036ce:	b7c5                	j	800036ae <bread+0xd0>

00000000800036d0 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800036d0:	1101                	addi	sp,sp,-32
    800036d2:	ec06                	sd	ra,24(sp)
    800036d4:	e822                	sd	s0,16(sp)
    800036d6:	e426                	sd	s1,8(sp)
    800036d8:	1000                	addi	s0,sp,32
    800036da:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800036dc:	0541                	addi	a0,a0,16
    800036de:	00001097          	auipc	ra,0x1
    800036e2:	466080e7          	jalr	1126(ra) # 80004b44 <holdingsleep>
    800036e6:	cd01                	beqz	a0,800036fe <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800036e8:	4585                	li	a1,1
    800036ea:	8526                	mv	a0,s1
    800036ec:	00003097          	auipc	ra,0x3
    800036f0:	eea080e7          	jalr	-278(ra) # 800065d6 <virtio_disk_rw>
}
    800036f4:	60e2                	ld	ra,24(sp)
    800036f6:	6442                	ld	s0,16(sp)
    800036f8:	64a2                	ld	s1,8(sp)
    800036fa:	6105                	addi	sp,sp,32
    800036fc:	8082                	ret
    panic("bwrite");
    800036fe:	00005517          	auipc	a0,0x5
    80003702:	e3a50513          	addi	a0,a0,-454 # 80008538 <syscalls+0xf0>
    80003706:	ffffd097          	auipc	ra,0xffffd
    8000370a:	e38080e7          	jalr	-456(ra) # 8000053e <panic>

000000008000370e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000370e:	1101                	addi	sp,sp,-32
    80003710:	ec06                	sd	ra,24(sp)
    80003712:	e822                	sd	s0,16(sp)
    80003714:	e426                	sd	s1,8(sp)
    80003716:	e04a                	sd	s2,0(sp)
    80003718:	1000                	addi	s0,sp,32
    8000371a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000371c:	01050913          	addi	s2,a0,16
    80003720:	854a                	mv	a0,s2
    80003722:	00001097          	auipc	ra,0x1
    80003726:	422080e7          	jalr	1058(ra) # 80004b44 <holdingsleep>
    8000372a:	c92d                	beqz	a0,8000379c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000372c:	854a                	mv	a0,s2
    8000372e:	00001097          	auipc	ra,0x1
    80003732:	3d2080e7          	jalr	978(ra) # 80004b00 <releasesleep>

  acquire(&bcache.lock);
    80003736:	00014517          	auipc	a0,0x14
    8000373a:	42250513          	addi	a0,a0,1058 # 80017b58 <bcache>
    8000373e:	ffffd097          	auipc	ra,0xffffd
    80003742:	4a6080e7          	jalr	1190(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003746:	40bc                	lw	a5,64(s1)
    80003748:	37fd                	addiw	a5,a5,-1
    8000374a:	0007871b          	sext.w	a4,a5
    8000374e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003750:	eb05                	bnez	a4,80003780 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003752:	68bc                	ld	a5,80(s1)
    80003754:	64b8                	ld	a4,72(s1)
    80003756:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003758:	64bc                	ld	a5,72(s1)
    8000375a:	68b8                	ld	a4,80(s1)
    8000375c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000375e:	0001c797          	auipc	a5,0x1c
    80003762:	3fa78793          	addi	a5,a5,1018 # 8001fb58 <bcache+0x8000>
    80003766:	2b87b703          	ld	a4,696(a5)
    8000376a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000376c:	0001c717          	auipc	a4,0x1c
    80003770:	65470713          	addi	a4,a4,1620 # 8001fdc0 <bcache+0x8268>
    80003774:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003776:	2b87b703          	ld	a4,696(a5)
    8000377a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000377c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003780:	00014517          	auipc	a0,0x14
    80003784:	3d850513          	addi	a0,a0,984 # 80017b58 <bcache>
    80003788:	ffffd097          	auipc	ra,0xffffd
    8000378c:	510080e7          	jalr	1296(ra) # 80000c98 <release>
}
    80003790:	60e2                	ld	ra,24(sp)
    80003792:	6442                	ld	s0,16(sp)
    80003794:	64a2                	ld	s1,8(sp)
    80003796:	6902                	ld	s2,0(sp)
    80003798:	6105                	addi	sp,sp,32
    8000379a:	8082                	ret
    panic("brelse");
    8000379c:	00005517          	auipc	a0,0x5
    800037a0:	da450513          	addi	a0,a0,-604 # 80008540 <syscalls+0xf8>
    800037a4:	ffffd097          	auipc	ra,0xffffd
    800037a8:	d9a080e7          	jalr	-614(ra) # 8000053e <panic>

00000000800037ac <bpin>:

void
bpin(struct buf *b) {
    800037ac:	1101                	addi	sp,sp,-32
    800037ae:	ec06                	sd	ra,24(sp)
    800037b0:	e822                	sd	s0,16(sp)
    800037b2:	e426                	sd	s1,8(sp)
    800037b4:	1000                	addi	s0,sp,32
    800037b6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800037b8:	00014517          	auipc	a0,0x14
    800037bc:	3a050513          	addi	a0,a0,928 # 80017b58 <bcache>
    800037c0:	ffffd097          	auipc	ra,0xffffd
    800037c4:	424080e7          	jalr	1060(ra) # 80000be4 <acquire>
  b->refcnt++;
    800037c8:	40bc                	lw	a5,64(s1)
    800037ca:	2785                	addiw	a5,a5,1
    800037cc:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800037ce:	00014517          	auipc	a0,0x14
    800037d2:	38a50513          	addi	a0,a0,906 # 80017b58 <bcache>
    800037d6:	ffffd097          	auipc	ra,0xffffd
    800037da:	4c2080e7          	jalr	1218(ra) # 80000c98 <release>
}
    800037de:	60e2                	ld	ra,24(sp)
    800037e0:	6442                	ld	s0,16(sp)
    800037e2:	64a2                	ld	s1,8(sp)
    800037e4:	6105                	addi	sp,sp,32
    800037e6:	8082                	ret

00000000800037e8 <bunpin>:

void
bunpin(struct buf *b) {
    800037e8:	1101                	addi	sp,sp,-32
    800037ea:	ec06                	sd	ra,24(sp)
    800037ec:	e822                	sd	s0,16(sp)
    800037ee:	e426                	sd	s1,8(sp)
    800037f0:	1000                	addi	s0,sp,32
    800037f2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800037f4:	00014517          	auipc	a0,0x14
    800037f8:	36450513          	addi	a0,a0,868 # 80017b58 <bcache>
    800037fc:	ffffd097          	auipc	ra,0xffffd
    80003800:	3e8080e7          	jalr	1000(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003804:	40bc                	lw	a5,64(s1)
    80003806:	37fd                	addiw	a5,a5,-1
    80003808:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000380a:	00014517          	auipc	a0,0x14
    8000380e:	34e50513          	addi	a0,a0,846 # 80017b58 <bcache>
    80003812:	ffffd097          	auipc	ra,0xffffd
    80003816:	486080e7          	jalr	1158(ra) # 80000c98 <release>
}
    8000381a:	60e2                	ld	ra,24(sp)
    8000381c:	6442                	ld	s0,16(sp)
    8000381e:	64a2                	ld	s1,8(sp)
    80003820:	6105                	addi	sp,sp,32
    80003822:	8082                	ret

0000000080003824 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003824:	1101                	addi	sp,sp,-32
    80003826:	ec06                	sd	ra,24(sp)
    80003828:	e822                	sd	s0,16(sp)
    8000382a:	e426                	sd	s1,8(sp)
    8000382c:	e04a                	sd	s2,0(sp)
    8000382e:	1000                	addi	s0,sp,32
    80003830:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003832:	00d5d59b          	srliw	a1,a1,0xd
    80003836:	0001d797          	auipc	a5,0x1d
    8000383a:	9fe7a783          	lw	a5,-1538(a5) # 80020234 <sb+0x1c>
    8000383e:	9dbd                	addw	a1,a1,a5
    80003840:	00000097          	auipc	ra,0x0
    80003844:	d9e080e7          	jalr	-610(ra) # 800035de <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003848:	0074f713          	andi	a4,s1,7
    8000384c:	4785                	li	a5,1
    8000384e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003852:	14ce                	slli	s1,s1,0x33
    80003854:	90d9                	srli	s1,s1,0x36
    80003856:	00950733          	add	a4,a0,s1
    8000385a:	05874703          	lbu	a4,88(a4)
    8000385e:	00e7f6b3          	and	a3,a5,a4
    80003862:	c69d                	beqz	a3,80003890 <bfree+0x6c>
    80003864:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003866:	94aa                	add	s1,s1,a0
    80003868:	fff7c793          	not	a5,a5
    8000386c:	8ff9                	and	a5,a5,a4
    8000386e:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003872:	00001097          	auipc	ra,0x1
    80003876:	118080e7          	jalr	280(ra) # 8000498a <log_write>
  brelse(bp);
    8000387a:	854a                	mv	a0,s2
    8000387c:	00000097          	auipc	ra,0x0
    80003880:	e92080e7          	jalr	-366(ra) # 8000370e <brelse>
}
    80003884:	60e2                	ld	ra,24(sp)
    80003886:	6442                	ld	s0,16(sp)
    80003888:	64a2                	ld	s1,8(sp)
    8000388a:	6902                	ld	s2,0(sp)
    8000388c:	6105                	addi	sp,sp,32
    8000388e:	8082                	ret
    panic("freeing free block");
    80003890:	00005517          	auipc	a0,0x5
    80003894:	cb850513          	addi	a0,a0,-840 # 80008548 <syscalls+0x100>
    80003898:	ffffd097          	auipc	ra,0xffffd
    8000389c:	ca6080e7          	jalr	-858(ra) # 8000053e <panic>

00000000800038a0 <balloc>:
{
    800038a0:	711d                	addi	sp,sp,-96
    800038a2:	ec86                	sd	ra,88(sp)
    800038a4:	e8a2                	sd	s0,80(sp)
    800038a6:	e4a6                	sd	s1,72(sp)
    800038a8:	e0ca                	sd	s2,64(sp)
    800038aa:	fc4e                	sd	s3,56(sp)
    800038ac:	f852                	sd	s4,48(sp)
    800038ae:	f456                	sd	s5,40(sp)
    800038b0:	f05a                	sd	s6,32(sp)
    800038b2:	ec5e                	sd	s7,24(sp)
    800038b4:	e862                	sd	s8,16(sp)
    800038b6:	e466                	sd	s9,8(sp)
    800038b8:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800038ba:	0001d797          	auipc	a5,0x1d
    800038be:	9627a783          	lw	a5,-1694(a5) # 8002021c <sb+0x4>
    800038c2:	cbd1                	beqz	a5,80003956 <balloc+0xb6>
    800038c4:	8baa                	mv	s7,a0
    800038c6:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800038c8:	0001db17          	auipc	s6,0x1d
    800038cc:	950b0b13          	addi	s6,s6,-1712 # 80020218 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038d0:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800038d2:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038d4:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800038d6:	6c89                	lui	s9,0x2
    800038d8:	a831                	j	800038f4 <balloc+0x54>
    brelse(bp);
    800038da:	854a                	mv	a0,s2
    800038dc:	00000097          	auipc	ra,0x0
    800038e0:	e32080e7          	jalr	-462(ra) # 8000370e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800038e4:	015c87bb          	addw	a5,s9,s5
    800038e8:	00078a9b          	sext.w	s5,a5
    800038ec:	004b2703          	lw	a4,4(s6)
    800038f0:	06eaf363          	bgeu	s5,a4,80003956 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800038f4:	41fad79b          	sraiw	a5,s5,0x1f
    800038f8:	0137d79b          	srliw	a5,a5,0x13
    800038fc:	015787bb          	addw	a5,a5,s5
    80003900:	40d7d79b          	sraiw	a5,a5,0xd
    80003904:	01cb2583          	lw	a1,28(s6)
    80003908:	9dbd                	addw	a1,a1,a5
    8000390a:	855e                	mv	a0,s7
    8000390c:	00000097          	auipc	ra,0x0
    80003910:	cd2080e7          	jalr	-814(ra) # 800035de <bread>
    80003914:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003916:	004b2503          	lw	a0,4(s6)
    8000391a:	000a849b          	sext.w	s1,s5
    8000391e:	8662                	mv	a2,s8
    80003920:	faa4fde3          	bgeu	s1,a0,800038da <balloc+0x3a>
      m = 1 << (bi % 8);
    80003924:	41f6579b          	sraiw	a5,a2,0x1f
    80003928:	01d7d69b          	srliw	a3,a5,0x1d
    8000392c:	00c6873b          	addw	a4,a3,a2
    80003930:	00777793          	andi	a5,a4,7
    80003934:	9f95                	subw	a5,a5,a3
    80003936:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000393a:	4037571b          	sraiw	a4,a4,0x3
    8000393e:	00e906b3          	add	a3,s2,a4
    80003942:	0586c683          	lbu	a3,88(a3)
    80003946:	00d7f5b3          	and	a1,a5,a3
    8000394a:	cd91                	beqz	a1,80003966 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000394c:	2605                	addiw	a2,a2,1
    8000394e:	2485                	addiw	s1,s1,1
    80003950:	fd4618e3          	bne	a2,s4,80003920 <balloc+0x80>
    80003954:	b759                	j	800038da <balloc+0x3a>
  panic("balloc: out of blocks");
    80003956:	00005517          	auipc	a0,0x5
    8000395a:	c0a50513          	addi	a0,a0,-1014 # 80008560 <syscalls+0x118>
    8000395e:	ffffd097          	auipc	ra,0xffffd
    80003962:	be0080e7          	jalr	-1056(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003966:	974a                	add	a4,a4,s2
    80003968:	8fd5                	or	a5,a5,a3
    8000396a:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000396e:	854a                	mv	a0,s2
    80003970:	00001097          	auipc	ra,0x1
    80003974:	01a080e7          	jalr	26(ra) # 8000498a <log_write>
        brelse(bp);
    80003978:	854a                	mv	a0,s2
    8000397a:	00000097          	auipc	ra,0x0
    8000397e:	d94080e7          	jalr	-620(ra) # 8000370e <brelse>
  bp = bread(dev, bno);
    80003982:	85a6                	mv	a1,s1
    80003984:	855e                	mv	a0,s7
    80003986:	00000097          	auipc	ra,0x0
    8000398a:	c58080e7          	jalr	-936(ra) # 800035de <bread>
    8000398e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003990:	40000613          	li	a2,1024
    80003994:	4581                	li	a1,0
    80003996:	05850513          	addi	a0,a0,88
    8000399a:	ffffd097          	auipc	ra,0xffffd
    8000399e:	346080e7          	jalr	838(ra) # 80000ce0 <memset>
  log_write(bp);
    800039a2:	854a                	mv	a0,s2
    800039a4:	00001097          	auipc	ra,0x1
    800039a8:	fe6080e7          	jalr	-26(ra) # 8000498a <log_write>
  brelse(bp);
    800039ac:	854a                	mv	a0,s2
    800039ae:	00000097          	auipc	ra,0x0
    800039b2:	d60080e7          	jalr	-672(ra) # 8000370e <brelse>
}
    800039b6:	8526                	mv	a0,s1
    800039b8:	60e6                	ld	ra,88(sp)
    800039ba:	6446                	ld	s0,80(sp)
    800039bc:	64a6                	ld	s1,72(sp)
    800039be:	6906                	ld	s2,64(sp)
    800039c0:	79e2                	ld	s3,56(sp)
    800039c2:	7a42                	ld	s4,48(sp)
    800039c4:	7aa2                	ld	s5,40(sp)
    800039c6:	7b02                	ld	s6,32(sp)
    800039c8:	6be2                	ld	s7,24(sp)
    800039ca:	6c42                	ld	s8,16(sp)
    800039cc:	6ca2                	ld	s9,8(sp)
    800039ce:	6125                	addi	sp,sp,96
    800039d0:	8082                	ret

00000000800039d2 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800039d2:	7179                	addi	sp,sp,-48
    800039d4:	f406                	sd	ra,40(sp)
    800039d6:	f022                	sd	s0,32(sp)
    800039d8:	ec26                	sd	s1,24(sp)
    800039da:	e84a                	sd	s2,16(sp)
    800039dc:	e44e                	sd	s3,8(sp)
    800039de:	e052                	sd	s4,0(sp)
    800039e0:	1800                	addi	s0,sp,48
    800039e2:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800039e4:	47ad                	li	a5,11
    800039e6:	04b7fe63          	bgeu	a5,a1,80003a42 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800039ea:	ff45849b          	addiw	s1,a1,-12
    800039ee:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800039f2:	0ff00793          	li	a5,255
    800039f6:	0ae7e363          	bltu	a5,a4,80003a9c <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800039fa:	08052583          	lw	a1,128(a0)
    800039fe:	c5ad                	beqz	a1,80003a68 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003a00:	00092503          	lw	a0,0(s2)
    80003a04:	00000097          	auipc	ra,0x0
    80003a08:	bda080e7          	jalr	-1062(ra) # 800035de <bread>
    80003a0c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003a0e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003a12:	02049593          	slli	a1,s1,0x20
    80003a16:	9181                	srli	a1,a1,0x20
    80003a18:	058a                	slli	a1,a1,0x2
    80003a1a:	00b784b3          	add	s1,a5,a1
    80003a1e:	0004a983          	lw	s3,0(s1)
    80003a22:	04098d63          	beqz	s3,80003a7c <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003a26:	8552                	mv	a0,s4
    80003a28:	00000097          	auipc	ra,0x0
    80003a2c:	ce6080e7          	jalr	-794(ra) # 8000370e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003a30:	854e                	mv	a0,s3
    80003a32:	70a2                	ld	ra,40(sp)
    80003a34:	7402                	ld	s0,32(sp)
    80003a36:	64e2                	ld	s1,24(sp)
    80003a38:	6942                	ld	s2,16(sp)
    80003a3a:	69a2                	ld	s3,8(sp)
    80003a3c:	6a02                	ld	s4,0(sp)
    80003a3e:	6145                	addi	sp,sp,48
    80003a40:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003a42:	02059493          	slli	s1,a1,0x20
    80003a46:	9081                	srli	s1,s1,0x20
    80003a48:	048a                	slli	s1,s1,0x2
    80003a4a:	94aa                	add	s1,s1,a0
    80003a4c:	0504a983          	lw	s3,80(s1)
    80003a50:	fe0990e3          	bnez	s3,80003a30 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003a54:	4108                	lw	a0,0(a0)
    80003a56:	00000097          	auipc	ra,0x0
    80003a5a:	e4a080e7          	jalr	-438(ra) # 800038a0 <balloc>
    80003a5e:	0005099b          	sext.w	s3,a0
    80003a62:	0534a823          	sw	s3,80(s1)
    80003a66:	b7e9                	j	80003a30 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003a68:	4108                	lw	a0,0(a0)
    80003a6a:	00000097          	auipc	ra,0x0
    80003a6e:	e36080e7          	jalr	-458(ra) # 800038a0 <balloc>
    80003a72:	0005059b          	sext.w	a1,a0
    80003a76:	08b92023          	sw	a1,128(s2)
    80003a7a:	b759                	j	80003a00 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003a7c:	00092503          	lw	a0,0(s2)
    80003a80:	00000097          	auipc	ra,0x0
    80003a84:	e20080e7          	jalr	-480(ra) # 800038a0 <balloc>
    80003a88:	0005099b          	sext.w	s3,a0
    80003a8c:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003a90:	8552                	mv	a0,s4
    80003a92:	00001097          	auipc	ra,0x1
    80003a96:	ef8080e7          	jalr	-264(ra) # 8000498a <log_write>
    80003a9a:	b771                	j	80003a26 <bmap+0x54>
  panic("bmap: out of range");
    80003a9c:	00005517          	auipc	a0,0x5
    80003aa0:	adc50513          	addi	a0,a0,-1316 # 80008578 <syscalls+0x130>
    80003aa4:	ffffd097          	auipc	ra,0xffffd
    80003aa8:	a9a080e7          	jalr	-1382(ra) # 8000053e <panic>

0000000080003aac <iget>:
{
    80003aac:	7179                	addi	sp,sp,-48
    80003aae:	f406                	sd	ra,40(sp)
    80003ab0:	f022                	sd	s0,32(sp)
    80003ab2:	ec26                	sd	s1,24(sp)
    80003ab4:	e84a                	sd	s2,16(sp)
    80003ab6:	e44e                	sd	s3,8(sp)
    80003ab8:	e052                	sd	s4,0(sp)
    80003aba:	1800                	addi	s0,sp,48
    80003abc:	89aa                	mv	s3,a0
    80003abe:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003ac0:	0001c517          	auipc	a0,0x1c
    80003ac4:	77850513          	addi	a0,a0,1912 # 80020238 <itable>
    80003ac8:	ffffd097          	auipc	ra,0xffffd
    80003acc:	11c080e7          	jalr	284(ra) # 80000be4 <acquire>
  empty = 0;
    80003ad0:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003ad2:	0001c497          	auipc	s1,0x1c
    80003ad6:	77e48493          	addi	s1,s1,1918 # 80020250 <itable+0x18>
    80003ada:	0001e697          	auipc	a3,0x1e
    80003ade:	20668693          	addi	a3,a3,518 # 80021ce0 <log>
    80003ae2:	a039                	j	80003af0 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003ae4:	02090b63          	beqz	s2,80003b1a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003ae8:	08848493          	addi	s1,s1,136
    80003aec:	02d48a63          	beq	s1,a3,80003b20 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003af0:	449c                	lw	a5,8(s1)
    80003af2:	fef059e3          	blez	a5,80003ae4 <iget+0x38>
    80003af6:	4098                	lw	a4,0(s1)
    80003af8:	ff3716e3          	bne	a4,s3,80003ae4 <iget+0x38>
    80003afc:	40d8                	lw	a4,4(s1)
    80003afe:	ff4713e3          	bne	a4,s4,80003ae4 <iget+0x38>
      ip->ref++;
    80003b02:	2785                	addiw	a5,a5,1
    80003b04:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003b06:	0001c517          	auipc	a0,0x1c
    80003b0a:	73250513          	addi	a0,a0,1842 # 80020238 <itable>
    80003b0e:	ffffd097          	auipc	ra,0xffffd
    80003b12:	18a080e7          	jalr	394(ra) # 80000c98 <release>
      return ip;
    80003b16:	8926                	mv	s2,s1
    80003b18:	a03d                	j	80003b46 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b1a:	f7f9                	bnez	a5,80003ae8 <iget+0x3c>
    80003b1c:	8926                	mv	s2,s1
    80003b1e:	b7e9                	j	80003ae8 <iget+0x3c>
  if(empty == 0)
    80003b20:	02090c63          	beqz	s2,80003b58 <iget+0xac>
  ip->dev = dev;
    80003b24:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003b28:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003b2c:	4785                	li	a5,1
    80003b2e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003b32:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003b36:	0001c517          	auipc	a0,0x1c
    80003b3a:	70250513          	addi	a0,a0,1794 # 80020238 <itable>
    80003b3e:	ffffd097          	auipc	ra,0xffffd
    80003b42:	15a080e7          	jalr	346(ra) # 80000c98 <release>
}
    80003b46:	854a                	mv	a0,s2
    80003b48:	70a2                	ld	ra,40(sp)
    80003b4a:	7402                	ld	s0,32(sp)
    80003b4c:	64e2                	ld	s1,24(sp)
    80003b4e:	6942                	ld	s2,16(sp)
    80003b50:	69a2                	ld	s3,8(sp)
    80003b52:	6a02                	ld	s4,0(sp)
    80003b54:	6145                	addi	sp,sp,48
    80003b56:	8082                	ret
    panic("iget: no inodes");
    80003b58:	00005517          	auipc	a0,0x5
    80003b5c:	a3850513          	addi	a0,a0,-1480 # 80008590 <syscalls+0x148>
    80003b60:	ffffd097          	auipc	ra,0xffffd
    80003b64:	9de080e7          	jalr	-1570(ra) # 8000053e <panic>

0000000080003b68 <fsinit>:
fsinit(int dev) {
    80003b68:	7179                	addi	sp,sp,-48
    80003b6a:	f406                	sd	ra,40(sp)
    80003b6c:	f022                	sd	s0,32(sp)
    80003b6e:	ec26                	sd	s1,24(sp)
    80003b70:	e84a                	sd	s2,16(sp)
    80003b72:	e44e                	sd	s3,8(sp)
    80003b74:	1800                	addi	s0,sp,48
    80003b76:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003b78:	4585                	li	a1,1
    80003b7a:	00000097          	auipc	ra,0x0
    80003b7e:	a64080e7          	jalr	-1436(ra) # 800035de <bread>
    80003b82:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003b84:	0001c997          	auipc	s3,0x1c
    80003b88:	69498993          	addi	s3,s3,1684 # 80020218 <sb>
    80003b8c:	02000613          	li	a2,32
    80003b90:	05850593          	addi	a1,a0,88
    80003b94:	854e                	mv	a0,s3
    80003b96:	ffffd097          	auipc	ra,0xffffd
    80003b9a:	1aa080e7          	jalr	426(ra) # 80000d40 <memmove>
  brelse(bp);
    80003b9e:	8526                	mv	a0,s1
    80003ba0:	00000097          	auipc	ra,0x0
    80003ba4:	b6e080e7          	jalr	-1170(ra) # 8000370e <brelse>
  if(sb.magic != FSMAGIC)
    80003ba8:	0009a703          	lw	a4,0(s3)
    80003bac:	102037b7          	lui	a5,0x10203
    80003bb0:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003bb4:	02f71263          	bne	a4,a5,80003bd8 <fsinit+0x70>
  initlog(dev, &sb);
    80003bb8:	0001c597          	auipc	a1,0x1c
    80003bbc:	66058593          	addi	a1,a1,1632 # 80020218 <sb>
    80003bc0:	854a                	mv	a0,s2
    80003bc2:	00001097          	auipc	ra,0x1
    80003bc6:	b4c080e7          	jalr	-1204(ra) # 8000470e <initlog>
}
    80003bca:	70a2                	ld	ra,40(sp)
    80003bcc:	7402                	ld	s0,32(sp)
    80003bce:	64e2                	ld	s1,24(sp)
    80003bd0:	6942                	ld	s2,16(sp)
    80003bd2:	69a2                	ld	s3,8(sp)
    80003bd4:	6145                	addi	sp,sp,48
    80003bd6:	8082                	ret
    panic("invalid file system");
    80003bd8:	00005517          	auipc	a0,0x5
    80003bdc:	9c850513          	addi	a0,a0,-1592 # 800085a0 <syscalls+0x158>
    80003be0:	ffffd097          	auipc	ra,0xffffd
    80003be4:	95e080e7          	jalr	-1698(ra) # 8000053e <panic>

0000000080003be8 <iinit>:
{
    80003be8:	7179                	addi	sp,sp,-48
    80003bea:	f406                	sd	ra,40(sp)
    80003bec:	f022                	sd	s0,32(sp)
    80003bee:	ec26                	sd	s1,24(sp)
    80003bf0:	e84a                	sd	s2,16(sp)
    80003bf2:	e44e                	sd	s3,8(sp)
    80003bf4:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003bf6:	00005597          	auipc	a1,0x5
    80003bfa:	9c258593          	addi	a1,a1,-1598 # 800085b8 <syscalls+0x170>
    80003bfe:	0001c517          	auipc	a0,0x1c
    80003c02:	63a50513          	addi	a0,a0,1594 # 80020238 <itable>
    80003c06:	ffffd097          	auipc	ra,0xffffd
    80003c0a:	f4e080e7          	jalr	-178(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003c0e:	0001c497          	auipc	s1,0x1c
    80003c12:	65248493          	addi	s1,s1,1618 # 80020260 <itable+0x28>
    80003c16:	0001e997          	auipc	s3,0x1e
    80003c1a:	0da98993          	addi	s3,s3,218 # 80021cf0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003c1e:	00005917          	auipc	s2,0x5
    80003c22:	9a290913          	addi	s2,s2,-1630 # 800085c0 <syscalls+0x178>
    80003c26:	85ca                	mv	a1,s2
    80003c28:	8526                	mv	a0,s1
    80003c2a:	00001097          	auipc	ra,0x1
    80003c2e:	e46080e7          	jalr	-442(ra) # 80004a70 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003c32:	08848493          	addi	s1,s1,136
    80003c36:	ff3498e3          	bne	s1,s3,80003c26 <iinit+0x3e>
}
    80003c3a:	70a2                	ld	ra,40(sp)
    80003c3c:	7402                	ld	s0,32(sp)
    80003c3e:	64e2                	ld	s1,24(sp)
    80003c40:	6942                	ld	s2,16(sp)
    80003c42:	69a2                	ld	s3,8(sp)
    80003c44:	6145                	addi	sp,sp,48
    80003c46:	8082                	ret

0000000080003c48 <ialloc>:
{
    80003c48:	715d                	addi	sp,sp,-80
    80003c4a:	e486                	sd	ra,72(sp)
    80003c4c:	e0a2                	sd	s0,64(sp)
    80003c4e:	fc26                	sd	s1,56(sp)
    80003c50:	f84a                	sd	s2,48(sp)
    80003c52:	f44e                	sd	s3,40(sp)
    80003c54:	f052                	sd	s4,32(sp)
    80003c56:	ec56                	sd	s5,24(sp)
    80003c58:	e85a                	sd	s6,16(sp)
    80003c5a:	e45e                	sd	s7,8(sp)
    80003c5c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c5e:	0001c717          	auipc	a4,0x1c
    80003c62:	5c672703          	lw	a4,1478(a4) # 80020224 <sb+0xc>
    80003c66:	4785                	li	a5,1
    80003c68:	04e7fa63          	bgeu	a5,a4,80003cbc <ialloc+0x74>
    80003c6c:	8aaa                	mv	s5,a0
    80003c6e:	8bae                	mv	s7,a1
    80003c70:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003c72:	0001ca17          	auipc	s4,0x1c
    80003c76:	5a6a0a13          	addi	s4,s4,1446 # 80020218 <sb>
    80003c7a:	00048b1b          	sext.w	s6,s1
    80003c7e:	0044d593          	srli	a1,s1,0x4
    80003c82:	018a2783          	lw	a5,24(s4)
    80003c86:	9dbd                	addw	a1,a1,a5
    80003c88:	8556                	mv	a0,s5
    80003c8a:	00000097          	auipc	ra,0x0
    80003c8e:	954080e7          	jalr	-1708(ra) # 800035de <bread>
    80003c92:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003c94:	05850993          	addi	s3,a0,88
    80003c98:	00f4f793          	andi	a5,s1,15
    80003c9c:	079a                	slli	a5,a5,0x6
    80003c9e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003ca0:	00099783          	lh	a5,0(s3)
    80003ca4:	c785                	beqz	a5,80003ccc <ialloc+0x84>
    brelse(bp);
    80003ca6:	00000097          	auipc	ra,0x0
    80003caa:	a68080e7          	jalr	-1432(ra) # 8000370e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003cae:	0485                	addi	s1,s1,1
    80003cb0:	00ca2703          	lw	a4,12(s4)
    80003cb4:	0004879b          	sext.w	a5,s1
    80003cb8:	fce7e1e3          	bltu	a5,a4,80003c7a <ialloc+0x32>
  panic("ialloc: no inodes");
    80003cbc:	00005517          	auipc	a0,0x5
    80003cc0:	90c50513          	addi	a0,a0,-1780 # 800085c8 <syscalls+0x180>
    80003cc4:	ffffd097          	auipc	ra,0xffffd
    80003cc8:	87a080e7          	jalr	-1926(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003ccc:	04000613          	li	a2,64
    80003cd0:	4581                	li	a1,0
    80003cd2:	854e                	mv	a0,s3
    80003cd4:	ffffd097          	auipc	ra,0xffffd
    80003cd8:	00c080e7          	jalr	12(ra) # 80000ce0 <memset>
      dip->type = type;
    80003cdc:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003ce0:	854a                	mv	a0,s2
    80003ce2:	00001097          	auipc	ra,0x1
    80003ce6:	ca8080e7          	jalr	-856(ra) # 8000498a <log_write>
      brelse(bp);
    80003cea:	854a                	mv	a0,s2
    80003cec:	00000097          	auipc	ra,0x0
    80003cf0:	a22080e7          	jalr	-1502(ra) # 8000370e <brelse>
      return iget(dev, inum);
    80003cf4:	85da                	mv	a1,s6
    80003cf6:	8556                	mv	a0,s5
    80003cf8:	00000097          	auipc	ra,0x0
    80003cfc:	db4080e7          	jalr	-588(ra) # 80003aac <iget>
}
    80003d00:	60a6                	ld	ra,72(sp)
    80003d02:	6406                	ld	s0,64(sp)
    80003d04:	74e2                	ld	s1,56(sp)
    80003d06:	7942                	ld	s2,48(sp)
    80003d08:	79a2                	ld	s3,40(sp)
    80003d0a:	7a02                	ld	s4,32(sp)
    80003d0c:	6ae2                	ld	s5,24(sp)
    80003d0e:	6b42                	ld	s6,16(sp)
    80003d10:	6ba2                	ld	s7,8(sp)
    80003d12:	6161                	addi	sp,sp,80
    80003d14:	8082                	ret

0000000080003d16 <iupdate>:
{
    80003d16:	1101                	addi	sp,sp,-32
    80003d18:	ec06                	sd	ra,24(sp)
    80003d1a:	e822                	sd	s0,16(sp)
    80003d1c:	e426                	sd	s1,8(sp)
    80003d1e:	e04a                	sd	s2,0(sp)
    80003d20:	1000                	addi	s0,sp,32
    80003d22:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d24:	415c                	lw	a5,4(a0)
    80003d26:	0047d79b          	srliw	a5,a5,0x4
    80003d2a:	0001c597          	auipc	a1,0x1c
    80003d2e:	5065a583          	lw	a1,1286(a1) # 80020230 <sb+0x18>
    80003d32:	9dbd                	addw	a1,a1,a5
    80003d34:	4108                	lw	a0,0(a0)
    80003d36:	00000097          	auipc	ra,0x0
    80003d3a:	8a8080e7          	jalr	-1880(ra) # 800035de <bread>
    80003d3e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d40:	05850793          	addi	a5,a0,88
    80003d44:	40c8                	lw	a0,4(s1)
    80003d46:	893d                	andi	a0,a0,15
    80003d48:	051a                	slli	a0,a0,0x6
    80003d4a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003d4c:	04449703          	lh	a4,68(s1)
    80003d50:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003d54:	04649703          	lh	a4,70(s1)
    80003d58:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003d5c:	04849703          	lh	a4,72(s1)
    80003d60:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003d64:	04a49703          	lh	a4,74(s1)
    80003d68:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003d6c:	44f8                	lw	a4,76(s1)
    80003d6e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003d70:	03400613          	li	a2,52
    80003d74:	05048593          	addi	a1,s1,80
    80003d78:	0531                	addi	a0,a0,12
    80003d7a:	ffffd097          	auipc	ra,0xffffd
    80003d7e:	fc6080e7          	jalr	-58(ra) # 80000d40 <memmove>
  log_write(bp);
    80003d82:	854a                	mv	a0,s2
    80003d84:	00001097          	auipc	ra,0x1
    80003d88:	c06080e7          	jalr	-1018(ra) # 8000498a <log_write>
  brelse(bp);
    80003d8c:	854a                	mv	a0,s2
    80003d8e:	00000097          	auipc	ra,0x0
    80003d92:	980080e7          	jalr	-1664(ra) # 8000370e <brelse>
}
    80003d96:	60e2                	ld	ra,24(sp)
    80003d98:	6442                	ld	s0,16(sp)
    80003d9a:	64a2                	ld	s1,8(sp)
    80003d9c:	6902                	ld	s2,0(sp)
    80003d9e:	6105                	addi	sp,sp,32
    80003da0:	8082                	ret

0000000080003da2 <idup>:
{
    80003da2:	1101                	addi	sp,sp,-32
    80003da4:	ec06                	sd	ra,24(sp)
    80003da6:	e822                	sd	s0,16(sp)
    80003da8:	e426                	sd	s1,8(sp)
    80003daa:	1000                	addi	s0,sp,32
    80003dac:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003dae:	0001c517          	auipc	a0,0x1c
    80003db2:	48a50513          	addi	a0,a0,1162 # 80020238 <itable>
    80003db6:	ffffd097          	auipc	ra,0xffffd
    80003dba:	e2e080e7          	jalr	-466(ra) # 80000be4 <acquire>
  ip->ref++;
    80003dbe:	449c                	lw	a5,8(s1)
    80003dc0:	2785                	addiw	a5,a5,1
    80003dc2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003dc4:	0001c517          	auipc	a0,0x1c
    80003dc8:	47450513          	addi	a0,a0,1140 # 80020238 <itable>
    80003dcc:	ffffd097          	auipc	ra,0xffffd
    80003dd0:	ecc080e7          	jalr	-308(ra) # 80000c98 <release>
}
    80003dd4:	8526                	mv	a0,s1
    80003dd6:	60e2                	ld	ra,24(sp)
    80003dd8:	6442                	ld	s0,16(sp)
    80003dda:	64a2                	ld	s1,8(sp)
    80003ddc:	6105                	addi	sp,sp,32
    80003dde:	8082                	ret

0000000080003de0 <ilock>:
{
    80003de0:	1101                	addi	sp,sp,-32
    80003de2:	ec06                	sd	ra,24(sp)
    80003de4:	e822                	sd	s0,16(sp)
    80003de6:	e426                	sd	s1,8(sp)
    80003de8:	e04a                	sd	s2,0(sp)
    80003dea:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003dec:	c115                	beqz	a0,80003e10 <ilock+0x30>
    80003dee:	84aa                	mv	s1,a0
    80003df0:	451c                	lw	a5,8(a0)
    80003df2:	00f05f63          	blez	a5,80003e10 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003df6:	0541                	addi	a0,a0,16
    80003df8:	00001097          	auipc	ra,0x1
    80003dfc:	cb2080e7          	jalr	-846(ra) # 80004aaa <acquiresleep>
  if(ip->valid == 0){
    80003e00:	40bc                	lw	a5,64(s1)
    80003e02:	cf99                	beqz	a5,80003e20 <ilock+0x40>
}
    80003e04:	60e2                	ld	ra,24(sp)
    80003e06:	6442                	ld	s0,16(sp)
    80003e08:	64a2                	ld	s1,8(sp)
    80003e0a:	6902                	ld	s2,0(sp)
    80003e0c:	6105                	addi	sp,sp,32
    80003e0e:	8082                	ret
    panic("ilock");
    80003e10:	00004517          	auipc	a0,0x4
    80003e14:	7d050513          	addi	a0,a0,2000 # 800085e0 <syscalls+0x198>
    80003e18:	ffffc097          	auipc	ra,0xffffc
    80003e1c:	726080e7          	jalr	1830(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e20:	40dc                	lw	a5,4(s1)
    80003e22:	0047d79b          	srliw	a5,a5,0x4
    80003e26:	0001c597          	auipc	a1,0x1c
    80003e2a:	40a5a583          	lw	a1,1034(a1) # 80020230 <sb+0x18>
    80003e2e:	9dbd                	addw	a1,a1,a5
    80003e30:	4088                	lw	a0,0(s1)
    80003e32:	fffff097          	auipc	ra,0xfffff
    80003e36:	7ac080e7          	jalr	1964(ra) # 800035de <bread>
    80003e3a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e3c:	05850593          	addi	a1,a0,88
    80003e40:	40dc                	lw	a5,4(s1)
    80003e42:	8bbd                	andi	a5,a5,15
    80003e44:	079a                	slli	a5,a5,0x6
    80003e46:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003e48:	00059783          	lh	a5,0(a1)
    80003e4c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003e50:	00259783          	lh	a5,2(a1)
    80003e54:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003e58:	00459783          	lh	a5,4(a1)
    80003e5c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003e60:	00659783          	lh	a5,6(a1)
    80003e64:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003e68:	459c                	lw	a5,8(a1)
    80003e6a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003e6c:	03400613          	li	a2,52
    80003e70:	05b1                	addi	a1,a1,12
    80003e72:	05048513          	addi	a0,s1,80
    80003e76:	ffffd097          	auipc	ra,0xffffd
    80003e7a:	eca080e7          	jalr	-310(ra) # 80000d40 <memmove>
    brelse(bp);
    80003e7e:	854a                	mv	a0,s2
    80003e80:	00000097          	auipc	ra,0x0
    80003e84:	88e080e7          	jalr	-1906(ra) # 8000370e <brelse>
    ip->valid = 1;
    80003e88:	4785                	li	a5,1
    80003e8a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003e8c:	04449783          	lh	a5,68(s1)
    80003e90:	fbb5                	bnez	a5,80003e04 <ilock+0x24>
      panic("ilock: no type");
    80003e92:	00004517          	auipc	a0,0x4
    80003e96:	75650513          	addi	a0,a0,1878 # 800085e8 <syscalls+0x1a0>
    80003e9a:	ffffc097          	auipc	ra,0xffffc
    80003e9e:	6a4080e7          	jalr	1700(ra) # 8000053e <panic>

0000000080003ea2 <iunlock>:
{
    80003ea2:	1101                	addi	sp,sp,-32
    80003ea4:	ec06                	sd	ra,24(sp)
    80003ea6:	e822                	sd	s0,16(sp)
    80003ea8:	e426                	sd	s1,8(sp)
    80003eaa:	e04a                	sd	s2,0(sp)
    80003eac:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003eae:	c905                	beqz	a0,80003ede <iunlock+0x3c>
    80003eb0:	84aa                	mv	s1,a0
    80003eb2:	01050913          	addi	s2,a0,16
    80003eb6:	854a                	mv	a0,s2
    80003eb8:	00001097          	auipc	ra,0x1
    80003ebc:	c8c080e7          	jalr	-884(ra) # 80004b44 <holdingsleep>
    80003ec0:	cd19                	beqz	a0,80003ede <iunlock+0x3c>
    80003ec2:	449c                	lw	a5,8(s1)
    80003ec4:	00f05d63          	blez	a5,80003ede <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003ec8:	854a                	mv	a0,s2
    80003eca:	00001097          	auipc	ra,0x1
    80003ece:	c36080e7          	jalr	-970(ra) # 80004b00 <releasesleep>
}
    80003ed2:	60e2                	ld	ra,24(sp)
    80003ed4:	6442                	ld	s0,16(sp)
    80003ed6:	64a2                	ld	s1,8(sp)
    80003ed8:	6902                	ld	s2,0(sp)
    80003eda:	6105                	addi	sp,sp,32
    80003edc:	8082                	ret
    panic("iunlock");
    80003ede:	00004517          	auipc	a0,0x4
    80003ee2:	71a50513          	addi	a0,a0,1818 # 800085f8 <syscalls+0x1b0>
    80003ee6:	ffffc097          	auipc	ra,0xffffc
    80003eea:	658080e7          	jalr	1624(ra) # 8000053e <panic>

0000000080003eee <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003eee:	7179                	addi	sp,sp,-48
    80003ef0:	f406                	sd	ra,40(sp)
    80003ef2:	f022                	sd	s0,32(sp)
    80003ef4:	ec26                	sd	s1,24(sp)
    80003ef6:	e84a                	sd	s2,16(sp)
    80003ef8:	e44e                	sd	s3,8(sp)
    80003efa:	e052                	sd	s4,0(sp)
    80003efc:	1800                	addi	s0,sp,48
    80003efe:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003f00:	05050493          	addi	s1,a0,80
    80003f04:	08050913          	addi	s2,a0,128
    80003f08:	a021                	j	80003f10 <itrunc+0x22>
    80003f0a:	0491                	addi	s1,s1,4
    80003f0c:	01248d63          	beq	s1,s2,80003f26 <itrunc+0x38>
    if(ip->addrs[i]){
    80003f10:	408c                	lw	a1,0(s1)
    80003f12:	dde5                	beqz	a1,80003f0a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003f14:	0009a503          	lw	a0,0(s3)
    80003f18:	00000097          	auipc	ra,0x0
    80003f1c:	90c080e7          	jalr	-1780(ra) # 80003824 <bfree>
      ip->addrs[i] = 0;
    80003f20:	0004a023          	sw	zero,0(s1)
    80003f24:	b7dd                	j	80003f0a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003f26:	0809a583          	lw	a1,128(s3)
    80003f2a:	e185                	bnez	a1,80003f4a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003f2c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003f30:	854e                	mv	a0,s3
    80003f32:	00000097          	auipc	ra,0x0
    80003f36:	de4080e7          	jalr	-540(ra) # 80003d16 <iupdate>
}
    80003f3a:	70a2                	ld	ra,40(sp)
    80003f3c:	7402                	ld	s0,32(sp)
    80003f3e:	64e2                	ld	s1,24(sp)
    80003f40:	6942                	ld	s2,16(sp)
    80003f42:	69a2                	ld	s3,8(sp)
    80003f44:	6a02                	ld	s4,0(sp)
    80003f46:	6145                	addi	sp,sp,48
    80003f48:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003f4a:	0009a503          	lw	a0,0(s3)
    80003f4e:	fffff097          	auipc	ra,0xfffff
    80003f52:	690080e7          	jalr	1680(ra) # 800035de <bread>
    80003f56:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003f58:	05850493          	addi	s1,a0,88
    80003f5c:	45850913          	addi	s2,a0,1112
    80003f60:	a811                	j	80003f74 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003f62:	0009a503          	lw	a0,0(s3)
    80003f66:	00000097          	auipc	ra,0x0
    80003f6a:	8be080e7          	jalr	-1858(ra) # 80003824 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003f6e:	0491                	addi	s1,s1,4
    80003f70:	01248563          	beq	s1,s2,80003f7a <itrunc+0x8c>
      if(a[j])
    80003f74:	408c                	lw	a1,0(s1)
    80003f76:	dde5                	beqz	a1,80003f6e <itrunc+0x80>
    80003f78:	b7ed                	j	80003f62 <itrunc+0x74>
    brelse(bp);
    80003f7a:	8552                	mv	a0,s4
    80003f7c:	fffff097          	auipc	ra,0xfffff
    80003f80:	792080e7          	jalr	1938(ra) # 8000370e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003f84:	0809a583          	lw	a1,128(s3)
    80003f88:	0009a503          	lw	a0,0(s3)
    80003f8c:	00000097          	auipc	ra,0x0
    80003f90:	898080e7          	jalr	-1896(ra) # 80003824 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003f94:	0809a023          	sw	zero,128(s3)
    80003f98:	bf51                	j	80003f2c <itrunc+0x3e>

0000000080003f9a <iput>:
{
    80003f9a:	1101                	addi	sp,sp,-32
    80003f9c:	ec06                	sd	ra,24(sp)
    80003f9e:	e822                	sd	s0,16(sp)
    80003fa0:	e426                	sd	s1,8(sp)
    80003fa2:	e04a                	sd	s2,0(sp)
    80003fa4:	1000                	addi	s0,sp,32
    80003fa6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003fa8:	0001c517          	auipc	a0,0x1c
    80003fac:	29050513          	addi	a0,a0,656 # 80020238 <itable>
    80003fb0:	ffffd097          	auipc	ra,0xffffd
    80003fb4:	c34080e7          	jalr	-972(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003fb8:	4498                	lw	a4,8(s1)
    80003fba:	4785                	li	a5,1
    80003fbc:	02f70363          	beq	a4,a5,80003fe2 <iput+0x48>
  ip->ref--;
    80003fc0:	449c                	lw	a5,8(s1)
    80003fc2:	37fd                	addiw	a5,a5,-1
    80003fc4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003fc6:	0001c517          	auipc	a0,0x1c
    80003fca:	27250513          	addi	a0,a0,626 # 80020238 <itable>
    80003fce:	ffffd097          	auipc	ra,0xffffd
    80003fd2:	cca080e7          	jalr	-822(ra) # 80000c98 <release>
}
    80003fd6:	60e2                	ld	ra,24(sp)
    80003fd8:	6442                	ld	s0,16(sp)
    80003fda:	64a2                	ld	s1,8(sp)
    80003fdc:	6902                	ld	s2,0(sp)
    80003fde:	6105                	addi	sp,sp,32
    80003fe0:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003fe2:	40bc                	lw	a5,64(s1)
    80003fe4:	dff1                	beqz	a5,80003fc0 <iput+0x26>
    80003fe6:	04a49783          	lh	a5,74(s1)
    80003fea:	fbf9                	bnez	a5,80003fc0 <iput+0x26>
    acquiresleep(&ip->lock);
    80003fec:	01048913          	addi	s2,s1,16
    80003ff0:	854a                	mv	a0,s2
    80003ff2:	00001097          	auipc	ra,0x1
    80003ff6:	ab8080e7          	jalr	-1352(ra) # 80004aaa <acquiresleep>
    release(&itable.lock);
    80003ffa:	0001c517          	auipc	a0,0x1c
    80003ffe:	23e50513          	addi	a0,a0,574 # 80020238 <itable>
    80004002:	ffffd097          	auipc	ra,0xffffd
    80004006:	c96080e7          	jalr	-874(ra) # 80000c98 <release>
    itrunc(ip);
    8000400a:	8526                	mv	a0,s1
    8000400c:	00000097          	auipc	ra,0x0
    80004010:	ee2080e7          	jalr	-286(ra) # 80003eee <itrunc>
    ip->type = 0;
    80004014:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004018:	8526                	mv	a0,s1
    8000401a:	00000097          	auipc	ra,0x0
    8000401e:	cfc080e7          	jalr	-772(ra) # 80003d16 <iupdate>
    ip->valid = 0;
    80004022:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004026:	854a                	mv	a0,s2
    80004028:	00001097          	auipc	ra,0x1
    8000402c:	ad8080e7          	jalr	-1320(ra) # 80004b00 <releasesleep>
    acquire(&itable.lock);
    80004030:	0001c517          	auipc	a0,0x1c
    80004034:	20850513          	addi	a0,a0,520 # 80020238 <itable>
    80004038:	ffffd097          	auipc	ra,0xffffd
    8000403c:	bac080e7          	jalr	-1108(ra) # 80000be4 <acquire>
    80004040:	b741                	j	80003fc0 <iput+0x26>

0000000080004042 <iunlockput>:
{
    80004042:	1101                	addi	sp,sp,-32
    80004044:	ec06                	sd	ra,24(sp)
    80004046:	e822                	sd	s0,16(sp)
    80004048:	e426                	sd	s1,8(sp)
    8000404a:	1000                	addi	s0,sp,32
    8000404c:	84aa                	mv	s1,a0
  iunlock(ip);
    8000404e:	00000097          	auipc	ra,0x0
    80004052:	e54080e7          	jalr	-428(ra) # 80003ea2 <iunlock>
  iput(ip);
    80004056:	8526                	mv	a0,s1
    80004058:	00000097          	auipc	ra,0x0
    8000405c:	f42080e7          	jalr	-190(ra) # 80003f9a <iput>
}
    80004060:	60e2                	ld	ra,24(sp)
    80004062:	6442                	ld	s0,16(sp)
    80004064:	64a2                	ld	s1,8(sp)
    80004066:	6105                	addi	sp,sp,32
    80004068:	8082                	ret

000000008000406a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000406a:	1141                	addi	sp,sp,-16
    8000406c:	e422                	sd	s0,8(sp)
    8000406e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004070:	411c                	lw	a5,0(a0)
    80004072:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004074:	415c                	lw	a5,4(a0)
    80004076:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004078:	04451783          	lh	a5,68(a0)
    8000407c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004080:	04a51783          	lh	a5,74(a0)
    80004084:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004088:	04c56783          	lwu	a5,76(a0)
    8000408c:	e99c                	sd	a5,16(a1)
}
    8000408e:	6422                	ld	s0,8(sp)
    80004090:	0141                	addi	sp,sp,16
    80004092:	8082                	ret

0000000080004094 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004094:	457c                	lw	a5,76(a0)
    80004096:	0ed7e963          	bltu	a5,a3,80004188 <readi+0xf4>
{
    8000409a:	7159                	addi	sp,sp,-112
    8000409c:	f486                	sd	ra,104(sp)
    8000409e:	f0a2                	sd	s0,96(sp)
    800040a0:	eca6                	sd	s1,88(sp)
    800040a2:	e8ca                	sd	s2,80(sp)
    800040a4:	e4ce                	sd	s3,72(sp)
    800040a6:	e0d2                	sd	s4,64(sp)
    800040a8:	fc56                	sd	s5,56(sp)
    800040aa:	f85a                	sd	s6,48(sp)
    800040ac:	f45e                	sd	s7,40(sp)
    800040ae:	f062                	sd	s8,32(sp)
    800040b0:	ec66                	sd	s9,24(sp)
    800040b2:	e86a                	sd	s10,16(sp)
    800040b4:	e46e                	sd	s11,8(sp)
    800040b6:	1880                	addi	s0,sp,112
    800040b8:	8baa                	mv	s7,a0
    800040ba:	8c2e                	mv	s8,a1
    800040bc:	8ab2                	mv	s5,a2
    800040be:	84b6                	mv	s1,a3
    800040c0:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800040c2:	9f35                	addw	a4,a4,a3
    return 0;
    800040c4:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800040c6:	0ad76063          	bltu	a4,a3,80004166 <readi+0xd2>
  if(off + n > ip->size)
    800040ca:	00e7f463          	bgeu	a5,a4,800040d2 <readi+0x3e>
    n = ip->size - off;
    800040ce:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040d2:	0a0b0963          	beqz	s6,80004184 <readi+0xf0>
    800040d6:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800040d8:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800040dc:	5cfd                	li	s9,-1
    800040de:	a82d                	j	80004118 <readi+0x84>
    800040e0:	020a1d93          	slli	s11,s4,0x20
    800040e4:	020ddd93          	srli	s11,s11,0x20
    800040e8:	05890613          	addi	a2,s2,88
    800040ec:	86ee                	mv	a3,s11
    800040ee:	963a                	add	a2,a2,a4
    800040f0:	85d6                	mv	a1,s5
    800040f2:	8562                	mv	a0,s8
    800040f4:	fffff097          	auipc	ra,0xfffff
    800040f8:	a18080e7          	jalr	-1512(ra) # 80002b0c <either_copyout>
    800040fc:	05950d63          	beq	a0,s9,80004156 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004100:	854a                	mv	a0,s2
    80004102:	fffff097          	auipc	ra,0xfffff
    80004106:	60c080e7          	jalr	1548(ra) # 8000370e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000410a:	013a09bb          	addw	s3,s4,s3
    8000410e:	009a04bb          	addw	s1,s4,s1
    80004112:	9aee                	add	s5,s5,s11
    80004114:	0569f763          	bgeu	s3,s6,80004162 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004118:	000ba903          	lw	s2,0(s7)
    8000411c:	00a4d59b          	srliw	a1,s1,0xa
    80004120:	855e                	mv	a0,s7
    80004122:	00000097          	auipc	ra,0x0
    80004126:	8b0080e7          	jalr	-1872(ra) # 800039d2 <bmap>
    8000412a:	0005059b          	sext.w	a1,a0
    8000412e:	854a                	mv	a0,s2
    80004130:	fffff097          	auipc	ra,0xfffff
    80004134:	4ae080e7          	jalr	1198(ra) # 800035de <bread>
    80004138:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000413a:	3ff4f713          	andi	a4,s1,1023
    8000413e:	40ed07bb          	subw	a5,s10,a4
    80004142:	413b06bb          	subw	a3,s6,s3
    80004146:	8a3e                	mv	s4,a5
    80004148:	2781                	sext.w	a5,a5
    8000414a:	0006861b          	sext.w	a2,a3
    8000414e:	f8f679e3          	bgeu	a2,a5,800040e0 <readi+0x4c>
    80004152:	8a36                	mv	s4,a3
    80004154:	b771                	j	800040e0 <readi+0x4c>
      brelse(bp);
    80004156:	854a                	mv	a0,s2
    80004158:	fffff097          	auipc	ra,0xfffff
    8000415c:	5b6080e7          	jalr	1462(ra) # 8000370e <brelse>
      tot = -1;
    80004160:	59fd                	li	s3,-1
  }
  return tot;
    80004162:	0009851b          	sext.w	a0,s3
}
    80004166:	70a6                	ld	ra,104(sp)
    80004168:	7406                	ld	s0,96(sp)
    8000416a:	64e6                	ld	s1,88(sp)
    8000416c:	6946                	ld	s2,80(sp)
    8000416e:	69a6                	ld	s3,72(sp)
    80004170:	6a06                	ld	s4,64(sp)
    80004172:	7ae2                	ld	s5,56(sp)
    80004174:	7b42                	ld	s6,48(sp)
    80004176:	7ba2                	ld	s7,40(sp)
    80004178:	7c02                	ld	s8,32(sp)
    8000417a:	6ce2                	ld	s9,24(sp)
    8000417c:	6d42                	ld	s10,16(sp)
    8000417e:	6da2                	ld	s11,8(sp)
    80004180:	6165                	addi	sp,sp,112
    80004182:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004184:	89da                	mv	s3,s6
    80004186:	bff1                	j	80004162 <readi+0xce>
    return 0;
    80004188:	4501                	li	a0,0
}
    8000418a:	8082                	ret

000000008000418c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000418c:	457c                	lw	a5,76(a0)
    8000418e:	10d7e863          	bltu	a5,a3,8000429e <writei+0x112>
{
    80004192:	7159                	addi	sp,sp,-112
    80004194:	f486                	sd	ra,104(sp)
    80004196:	f0a2                	sd	s0,96(sp)
    80004198:	eca6                	sd	s1,88(sp)
    8000419a:	e8ca                	sd	s2,80(sp)
    8000419c:	e4ce                	sd	s3,72(sp)
    8000419e:	e0d2                	sd	s4,64(sp)
    800041a0:	fc56                	sd	s5,56(sp)
    800041a2:	f85a                	sd	s6,48(sp)
    800041a4:	f45e                	sd	s7,40(sp)
    800041a6:	f062                	sd	s8,32(sp)
    800041a8:	ec66                	sd	s9,24(sp)
    800041aa:	e86a                	sd	s10,16(sp)
    800041ac:	e46e                	sd	s11,8(sp)
    800041ae:	1880                	addi	s0,sp,112
    800041b0:	8b2a                	mv	s6,a0
    800041b2:	8c2e                	mv	s8,a1
    800041b4:	8ab2                	mv	s5,a2
    800041b6:	8936                	mv	s2,a3
    800041b8:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800041ba:	00e687bb          	addw	a5,a3,a4
    800041be:	0ed7e263          	bltu	a5,a3,800042a2 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800041c2:	00043737          	lui	a4,0x43
    800041c6:	0ef76063          	bltu	a4,a5,800042a6 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041ca:	0c0b8863          	beqz	s7,8000429a <writei+0x10e>
    800041ce:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800041d0:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800041d4:	5cfd                	li	s9,-1
    800041d6:	a091                	j	8000421a <writei+0x8e>
    800041d8:	02099d93          	slli	s11,s3,0x20
    800041dc:	020ddd93          	srli	s11,s11,0x20
    800041e0:	05848513          	addi	a0,s1,88
    800041e4:	86ee                	mv	a3,s11
    800041e6:	8656                	mv	a2,s5
    800041e8:	85e2                	mv	a1,s8
    800041ea:	953a                	add	a0,a0,a4
    800041ec:	fffff097          	auipc	ra,0xfffff
    800041f0:	976080e7          	jalr	-1674(ra) # 80002b62 <either_copyin>
    800041f4:	07950263          	beq	a0,s9,80004258 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800041f8:	8526                	mv	a0,s1
    800041fa:	00000097          	auipc	ra,0x0
    800041fe:	790080e7          	jalr	1936(ra) # 8000498a <log_write>
    brelse(bp);
    80004202:	8526                	mv	a0,s1
    80004204:	fffff097          	auipc	ra,0xfffff
    80004208:	50a080e7          	jalr	1290(ra) # 8000370e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000420c:	01498a3b          	addw	s4,s3,s4
    80004210:	0129893b          	addw	s2,s3,s2
    80004214:	9aee                	add	s5,s5,s11
    80004216:	057a7663          	bgeu	s4,s7,80004262 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000421a:	000b2483          	lw	s1,0(s6)
    8000421e:	00a9559b          	srliw	a1,s2,0xa
    80004222:	855a                	mv	a0,s6
    80004224:	fffff097          	auipc	ra,0xfffff
    80004228:	7ae080e7          	jalr	1966(ra) # 800039d2 <bmap>
    8000422c:	0005059b          	sext.w	a1,a0
    80004230:	8526                	mv	a0,s1
    80004232:	fffff097          	auipc	ra,0xfffff
    80004236:	3ac080e7          	jalr	940(ra) # 800035de <bread>
    8000423a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000423c:	3ff97713          	andi	a4,s2,1023
    80004240:	40ed07bb          	subw	a5,s10,a4
    80004244:	414b86bb          	subw	a3,s7,s4
    80004248:	89be                	mv	s3,a5
    8000424a:	2781                	sext.w	a5,a5
    8000424c:	0006861b          	sext.w	a2,a3
    80004250:	f8f674e3          	bgeu	a2,a5,800041d8 <writei+0x4c>
    80004254:	89b6                	mv	s3,a3
    80004256:	b749                	j	800041d8 <writei+0x4c>
      brelse(bp);
    80004258:	8526                	mv	a0,s1
    8000425a:	fffff097          	auipc	ra,0xfffff
    8000425e:	4b4080e7          	jalr	1204(ra) # 8000370e <brelse>
  }

  if(off > ip->size)
    80004262:	04cb2783          	lw	a5,76(s6)
    80004266:	0127f463          	bgeu	a5,s2,8000426e <writei+0xe2>
    ip->size = off;
    8000426a:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000426e:	855a                	mv	a0,s6
    80004270:	00000097          	auipc	ra,0x0
    80004274:	aa6080e7          	jalr	-1370(ra) # 80003d16 <iupdate>

  return tot;
    80004278:	000a051b          	sext.w	a0,s4
}
    8000427c:	70a6                	ld	ra,104(sp)
    8000427e:	7406                	ld	s0,96(sp)
    80004280:	64e6                	ld	s1,88(sp)
    80004282:	6946                	ld	s2,80(sp)
    80004284:	69a6                	ld	s3,72(sp)
    80004286:	6a06                	ld	s4,64(sp)
    80004288:	7ae2                	ld	s5,56(sp)
    8000428a:	7b42                	ld	s6,48(sp)
    8000428c:	7ba2                	ld	s7,40(sp)
    8000428e:	7c02                	ld	s8,32(sp)
    80004290:	6ce2                	ld	s9,24(sp)
    80004292:	6d42                	ld	s10,16(sp)
    80004294:	6da2                	ld	s11,8(sp)
    80004296:	6165                	addi	sp,sp,112
    80004298:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000429a:	8a5e                	mv	s4,s7
    8000429c:	bfc9                	j	8000426e <writei+0xe2>
    return -1;
    8000429e:	557d                	li	a0,-1
}
    800042a0:	8082                	ret
    return -1;
    800042a2:	557d                	li	a0,-1
    800042a4:	bfe1                	j	8000427c <writei+0xf0>
    return -1;
    800042a6:	557d                	li	a0,-1
    800042a8:	bfd1                	j	8000427c <writei+0xf0>

00000000800042aa <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800042aa:	1141                	addi	sp,sp,-16
    800042ac:	e406                	sd	ra,8(sp)
    800042ae:	e022                	sd	s0,0(sp)
    800042b0:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800042b2:	4639                	li	a2,14
    800042b4:	ffffd097          	auipc	ra,0xffffd
    800042b8:	b04080e7          	jalr	-1276(ra) # 80000db8 <strncmp>
}
    800042bc:	60a2                	ld	ra,8(sp)
    800042be:	6402                	ld	s0,0(sp)
    800042c0:	0141                	addi	sp,sp,16
    800042c2:	8082                	ret

00000000800042c4 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800042c4:	7139                	addi	sp,sp,-64
    800042c6:	fc06                	sd	ra,56(sp)
    800042c8:	f822                	sd	s0,48(sp)
    800042ca:	f426                	sd	s1,40(sp)
    800042cc:	f04a                	sd	s2,32(sp)
    800042ce:	ec4e                	sd	s3,24(sp)
    800042d0:	e852                	sd	s4,16(sp)
    800042d2:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800042d4:	04451703          	lh	a4,68(a0)
    800042d8:	4785                	li	a5,1
    800042da:	00f71a63          	bne	a4,a5,800042ee <dirlookup+0x2a>
    800042de:	892a                	mv	s2,a0
    800042e0:	89ae                	mv	s3,a1
    800042e2:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800042e4:	457c                	lw	a5,76(a0)
    800042e6:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800042e8:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042ea:	e79d                	bnez	a5,80004318 <dirlookup+0x54>
    800042ec:	a8a5                	j	80004364 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800042ee:	00004517          	auipc	a0,0x4
    800042f2:	31250513          	addi	a0,a0,786 # 80008600 <syscalls+0x1b8>
    800042f6:	ffffc097          	auipc	ra,0xffffc
    800042fa:	248080e7          	jalr	584(ra) # 8000053e <panic>
      panic("dirlookup read");
    800042fe:	00004517          	auipc	a0,0x4
    80004302:	31a50513          	addi	a0,a0,794 # 80008618 <syscalls+0x1d0>
    80004306:	ffffc097          	auipc	ra,0xffffc
    8000430a:	238080e7          	jalr	568(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000430e:	24c1                	addiw	s1,s1,16
    80004310:	04c92783          	lw	a5,76(s2)
    80004314:	04f4f763          	bgeu	s1,a5,80004362 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004318:	4741                	li	a4,16
    8000431a:	86a6                	mv	a3,s1
    8000431c:	fc040613          	addi	a2,s0,-64
    80004320:	4581                	li	a1,0
    80004322:	854a                	mv	a0,s2
    80004324:	00000097          	auipc	ra,0x0
    80004328:	d70080e7          	jalr	-656(ra) # 80004094 <readi>
    8000432c:	47c1                	li	a5,16
    8000432e:	fcf518e3          	bne	a0,a5,800042fe <dirlookup+0x3a>
    if(de.inum == 0)
    80004332:	fc045783          	lhu	a5,-64(s0)
    80004336:	dfe1                	beqz	a5,8000430e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004338:	fc240593          	addi	a1,s0,-62
    8000433c:	854e                	mv	a0,s3
    8000433e:	00000097          	auipc	ra,0x0
    80004342:	f6c080e7          	jalr	-148(ra) # 800042aa <namecmp>
    80004346:	f561                	bnez	a0,8000430e <dirlookup+0x4a>
      if(poff)
    80004348:	000a0463          	beqz	s4,80004350 <dirlookup+0x8c>
        *poff = off;
    8000434c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004350:	fc045583          	lhu	a1,-64(s0)
    80004354:	00092503          	lw	a0,0(s2)
    80004358:	fffff097          	auipc	ra,0xfffff
    8000435c:	754080e7          	jalr	1876(ra) # 80003aac <iget>
    80004360:	a011                	j	80004364 <dirlookup+0xa0>
  return 0;
    80004362:	4501                	li	a0,0
}
    80004364:	70e2                	ld	ra,56(sp)
    80004366:	7442                	ld	s0,48(sp)
    80004368:	74a2                	ld	s1,40(sp)
    8000436a:	7902                	ld	s2,32(sp)
    8000436c:	69e2                	ld	s3,24(sp)
    8000436e:	6a42                	ld	s4,16(sp)
    80004370:	6121                	addi	sp,sp,64
    80004372:	8082                	ret

0000000080004374 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004374:	711d                	addi	sp,sp,-96
    80004376:	ec86                	sd	ra,88(sp)
    80004378:	e8a2                	sd	s0,80(sp)
    8000437a:	e4a6                	sd	s1,72(sp)
    8000437c:	e0ca                	sd	s2,64(sp)
    8000437e:	fc4e                	sd	s3,56(sp)
    80004380:	f852                	sd	s4,48(sp)
    80004382:	f456                	sd	s5,40(sp)
    80004384:	f05a                	sd	s6,32(sp)
    80004386:	ec5e                	sd	s7,24(sp)
    80004388:	e862                	sd	s8,16(sp)
    8000438a:	e466                	sd	s9,8(sp)
    8000438c:	1080                	addi	s0,sp,96
    8000438e:	84aa                	mv	s1,a0
    80004390:	8b2e                	mv	s6,a1
    80004392:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004394:	00054703          	lbu	a4,0(a0)
    80004398:	02f00793          	li	a5,47
    8000439c:	02f70363          	beq	a4,a5,800043c2 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800043a0:	ffffe097          	auipc	ra,0xffffe
    800043a4:	90e080e7          	jalr	-1778(ra) # 80001cae <myproc>
    800043a8:	17853503          	ld	a0,376(a0)
    800043ac:	00000097          	auipc	ra,0x0
    800043b0:	9f6080e7          	jalr	-1546(ra) # 80003da2 <idup>
    800043b4:	89aa                	mv	s3,a0
  while(*path == '/')
    800043b6:	02f00913          	li	s2,47
  len = path - s;
    800043ba:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800043bc:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800043be:	4c05                	li	s8,1
    800043c0:	a865                	j	80004478 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800043c2:	4585                	li	a1,1
    800043c4:	4505                	li	a0,1
    800043c6:	fffff097          	auipc	ra,0xfffff
    800043ca:	6e6080e7          	jalr	1766(ra) # 80003aac <iget>
    800043ce:	89aa                	mv	s3,a0
    800043d0:	b7dd                	j	800043b6 <namex+0x42>
      iunlockput(ip);
    800043d2:	854e                	mv	a0,s3
    800043d4:	00000097          	auipc	ra,0x0
    800043d8:	c6e080e7          	jalr	-914(ra) # 80004042 <iunlockput>
      return 0;
    800043dc:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800043de:	854e                	mv	a0,s3
    800043e0:	60e6                	ld	ra,88(sp)
    800043e2:	6446                	ld	s0,80(sp)
    800043e4:	64a6                	ld	s1,72(sp)
    800043e6:	6906                	ld	s2,64(sp)
    800043e8:	79e2                	ld	s3,56(sp)
    800043ea:	7a42                	ld	s4,48(sp)
    800043ec:	7aa2                	ld	s5,40(sp)
    800043ee:	7b02                	ld	s6,32(sp)
    800043f0:	6be2                	ld	s7,24(sp)
    800043f2:	6c42                	ld	s8,16(sp)
    800043f4:	6ca2                	ld	s9,8(sp)
    800043f6:	6125                	addi	sp,sp,96
    800043f8:	8082                	ret
      iunlock(ip);
    800043fa:	854e                	mv	a0,s3
    800043fc:	00000097          	auipc	ra,0x0
    80004400:	aa6080e7          	jalr	-1370(ra) # 80003ea2 <iunlock>
      return ip;
    80004404:	bfe9                	j	800043de <namex+0x6a>
      iunlockput(ip);
    80004406:	854e                	mv	a0,s3
    80004408:	00000097          	auipc	ra,0x0
    8000440c:	c3a080e7          	jalr	-966(ra) # 80004042 <iunlockput>
      return 0;
    80004410:	89d2                	mv	s3,s4
    80004412:	b7f1                	j	800043de <namex+0x6a>
  len = path - s;
    80004414:	40b48633          	sub	a2,s1,a1
    80004418:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    8000441c:	094cd463          	bge	s9,s4,800044a4 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004420:	4639                	li	a2,14
    80004422:	8556                	mv	a0,s5
    80004424:	ffffd097          	auipc	ra,0xffffd
    80004428:	91c080e7          	jalr	-1764(ra) # 80000d40 <memmove>
  while(*path == '/')
    8000442c:	0004c783          	lbu	a5,0(s1)
    80004430:	01279763          	bne	a5,s2,8000443e <namex+0xca>
    path++;
    80004434:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004436:	0004c783          	lbu	a5,0(s1)
    8000443a:	ff278de3          	beq	a5,s2,80004434 <namex+0xc0>
    ilock(ip);
    8000443e:	854e                	mv	a0,s3
    80004440:	00000097          	auipc	ra,0x0
    80004444:	9a0080e7          	jalr	-1632(ra) # 80003de0 <ilock>
    if(ip->type != T_DIR){
    80004448:	04499783          	lh	a5,68(s3)
    8000444c:	f98793e3          	bne	a5,s8,800043d2 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004450:	000b0563          	beqz	s6,8000445a <namex+0xe6>
    80004454:	0004c783          	lbu	a5,0(s1)
    80004458:	d3cd                	beqz	a5,800043fa <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000445a:	865e                	mv	a2,s7
    8000445c:	85d6                	mv	a1,s5
    8000445e:	854e                	mv	a0,s3
    80004460:	00000097          	auipc	ra,0x0
    80004464:	e64080e7          	jalr	-412(ra) # 800042c4 <dirlookup>
    80004468:	8a2a                	mv	s4,a0
    8000446a:	dd51                	beqz	a0,80004406 <namex+0x92>
    iunlockput(ip);
    8000446c:	854e                	mv	a0,s3
    8000446e:	00000097          	auipc	ra,0x0
    80004472:	bd4080e7          	jalr	-1068(ra) # 80004042 <iunlockput>
    ip = next;
    80004476:	89d2                	mv	s3,s4
  while(*path == '/')
    80004478:	0004c783          	lbu	a5,0(s1)
    8000447c:	05279763          	bne	a5,s2,800044ca <namex+0x156>
    path++;
    80004480:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004482:	0004c783          	lbu	a5,0(s1)
    80004486:	ff278de3          	beq	a5,s2,80004480 <namex+0x10c>
  if(*path == 0)
    8000448a:	c79d                	beqz	a5,800044b8 <namex+0x144>
    path++;
    8000448c:	85a6                	mv	a1,s1
  len = path - s;
    8000448e:	8a5e                	mv	s4,s7
    80004490:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004492:	01278963          	beq	a5,s2,800044a4 <namex+0x130>
    80004496:	dfbd                	beqz	a5,80004414 <namex+0xa0>
    path++;
    80004498:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000449a:	0004c783          	lbu	a5,0(s1)
    8000449e:	ff279ce3          	bne	a5,s2,80004496 <namex+0x122>
    800044a2:	bf8d                	j	80004414 <namex+0xa0>
    memmove(name, s, len);
    800044a4:	2601                	sext.w	a2,a2
    800044a6:	8556                	mv	a0,s5
    800044a8:	ffffd097          	auipc	ra,0xffffd
    800044ac:	898080e7          	jalr	-1896(ra) # 80000d40 <memmove>
    name[len] = 0;
    800044b0:	9a56                	add	s4,s4,s5
    800044b2:	000a0023          	sb	zero,0(s4)
    800044b6:	bf9d                	j	8000442c <namex+0xb8>
  if(nameiparent){
    800044b8:	f20b03e3          	beqz	s6,800043de <namex+0x6a>
    iput(ip);
    800044bc:	854e                	mv	a0,s3
    800044be:	00000097          	auipc	ra,0x0
    800044c2:	adc080e7          	jalr	-1316(ra) # 80003f9a <iput>
    return 0;
    800044c6:	4981                	li	s3,0
    800044c8:	bf19                	j	800043de <namex+0x6a>
  if(*path == 0)
    800044ca:	d7fd                	beqz	a5,800044b8 <namex+0x144>
  while(*path != '/' && *path != 0)
    800044cc:	0004c783          	lbu	a5,0(s1)
    800044d0:	85a6                	mv	a1,s1
    800044d2:	b7d1                	j	80004496 <namex+0x122>

00000000800044d4 <dirlink>:
{
    800044d4:	7139                	addi	sp,sp,-64
    800044d6:	fc06                	sd	ra,56(sp)
    800044d8:	f822                	sd	s0,48(sp)
    800044da:	f426                	sd	s1,40(sp)
    800044dc:	f04a                	sd	s2,32(sp)
    800044de:	ec4e                	sd	s3,24(sp)
    800044e0:	e852                	sd	s4,16(sp)
    800044e2:	0080                	addi	s0,sp,64
    800044e4:	892a                	mv	s2,a0
    800044e6:	8a2e                	mv	s4,a1
    800044e8:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800044ea:	4601                	li	a2,0
    800044ec:	00000097          	auipc	ra,0x0
    800044f0:	dd8080e7          	jalr	-552(ra) # 800042c4 <dirlookup>
    800044f4:	e93d                	bnez	a0,8000456a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044f6:	04c92483          	lw	s1,76(s2)
    800044fa:	c49d                	beqz	s1,80004528 <dirlink+0x54>
    800044fc:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800044fe:	4741                	li	a4,16
    80004500:	86a6                	mv	a3,s1
    80004502:	fc040613          	addi	a2,s0,-64
    80004506:	4581                	li	a1,0
    80004508:	854a                	mv	a0,s2
    8000450a:	00000097          	auipc	ra,0x0
    8000450e:	b8a080e7          	jalr	-1142(ra) # 80004094 <readi>
    80004512:	47c1                	li	a5,16
    80004514:	06f51163          	bne	a0,a5,80004576 <dirlink+0xa2>
    if(de.inum == 0)
    80004518:	fc045783          	lhu	a5,-64(s0)
    8000451c:	c791                	beqz	a5,80004528 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000451e:	24c1                	addiw	s1,s1,16
    80004520:	04c92783          	lw	a5,76(s2)
    80004524:	fcf4ede3          	bltu	s1,a5,800044fe <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004528:	4639                	li	a2,14
    8000452a:	85d2                	mv	a1,s4
    8000452c:	fc240513          	addi	a0,s0,-62
    80004530:	ffffd097          	auipc	ra,0xffffd
    80004534:	8c4080e7          	jalr	-1852(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80004538:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000453c:	4741                	li	a4,16
    8000453e:	86a6                	mv	a3,s1
    80004540:	fc040613          	addi	a2,s0,-64
    80004544:	4581                	li	a1,0
    80004546:	854a                	mv	a0,s2
    80004548:	00000097          	auipc	ra,0x0
    8000454c:	c44080e7          	jalr	-956(ra) # 8000418c <writei>
    80004550:	872a                	mv	a4,a0
    80004552:	47c1                	li	a5,16
  return 0;
    80004554:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004556:	02f71863          	bne	a4,a5,80004586 <dirlink+0xb2>
}
    8000455a:	70e2                	ld	ra,56(sp)
    8000455c:	7442                	ld	s0,48(sp)
    8000455e:	74a2                	ld	s1,40(sp)
    80004560:	7902                	ld	s2,32(sp)
    80004562:	69e2                	ld	s3,24(sp)
    80004564:	6a42                	ld	s4,16(sp)
    80004566:	6121                	addi	sp,sp,64
    80004568:	8082                	ret
    iput(ip);
    8000456a:	00000097          	auipc	ra,0x0
    8000456e:	a30080e7          	jalr	-1488(ra) # 80003f9a <iput>
    return -1;
    80004572:	557d                	li	a0,-1
    80004574:	b7dd                	j	8000455a <dirlink+0x86>
      panic("dirlink read");
    80004576:	00004517          	auipc	a0,0x4
    8000457a:	0b250513          	addi	a0,a0,178 # 80008628 <syscalls+0x1e0>
    8000457e:	ffffc097          	auipc	ra,0xffffc
    80004582:	fc0080e7          	jalr	-64(ra) # 8000053e <panic>
    panic("dirlink");
    80004586:	00004517          	auipc	a0,0x4
    8000458a:	1b250513          	addi	a0,a0,434 # 80008738 <syscalls+0x2f0>
    8000458e:	ffffc097          	auipc	ra,0xffffc
    80004592:	fb0080e7          	jalr	-80(ra) # 8000053e <panic>

0000000080004596 <namei>:

struct inode*
namei(char *path)
{
    80004596:	1101                	addi	sp,sp,-32
    80004598:	ec06                	sd	ra,24(sp)
    8000459a:	e822                	sd	s0,16(sp)
    8000459c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000459e:	fe040613          	addi	a2,s0,-32
    800045a2:	4581                	li	a1,0
    800045a4:	00000097          	auipc	ra,0x0
    800045a8:	dd0080e7          	jalr	-560(ra) # 80004374 <namex>
}
    800045ac:	60e2                	ld	ra,24(sp)
    800045ae:	6442                	ld	s0,16(sp)
    800045b0:	6105                	addi	sp,sp,32
    800045b2:	8082                	ret

00000000800045b4 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800045b4:	1141                	addi	sp,sp,-16
    800045b6:	e406                	sd	ra,8(sp)
    800045b8:	e022                	sd	s0,0(sp)
    800045ba:	0800                	addi	s0,sp,16
    800045bc:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800045be:	4585                	li	a1,1
    800045c0:	00000097          	auipc	ra,0x0
    800045c4:	db4080e7          	jalr	-588(ra) # 80004374 <namex>
}
    800045c8:	60a2                	ld	ra,8(sp)
    800045ca:	6402                	ld	s0,0(sp)
    800045cc:	0141                	addi	sp,sp,16
    800045ce:	8082                	ret

00000000800045d0 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800045d0:	1101                	addi	sp,sp,-32
    800045d2:	ec06                	sd	ra,24(sp)
    800045d4:	e822                	sd	s0,16(sp)
    800045d6:	e426                	sd	s1,8(sp)
    800045d8:	e04a                	sd	s2,0(sp)
    800045da:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800045dc:	0001d917          	auipc	s2,0x1d
    800045e0:	70490913          	addi	s2,s2,1796 # 80021ce0 <log>
    800045e4:	01892583          	lw	a1,24(s2)
    800045e8:	02892503          	lw	a0,40(s2)
    800045ec:	fffff097          	auipc	ra,0xfffff
    800045f0:	ff2080e7          	jalr	-14(ra) # 800035de <bread>
    800045f4:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800045f6:	02c92683          	lw	a3,44(s2)
    800045fa:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800045fc:	02d05763          	blez	a3,8000462a <write_head+0x5a>
    80004600:	0001d797          	auipc	a5,0x1d
    80004604:	71078793          	addi	a5,a5,1808 # 80021d10 <log+0x30>
    80004608:	05c50713          	addi	a4,a0,92
    8000460c:	36fd                	addiw	a3,a3,-1
    8000460e:	1682                	slli	a3,a3,0x20
    80004610:	9281                	srli	a3,a3,0x20
    80004612:	068a                	slli	a3,a3,0x2
    80004614:	0001d617          	auipc	a2,0x1d
    80004618:	70060613          	addi	a2,a2,1792 # 80021d14 <log+0x34>
    8000461c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000461e:	4390                	lw	a2,0(a5)
    80004620:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004622:	0791                	addi	a5,a5,4
    80004624:	0711                	addi	a4,a4,4
    80004626:	fed79ce3          	bne	a5,a3,8000461e <write_head+0x4e>
  }
  bwrite(buf);
    8000462a:	8526                	mv	a0,s1
    8000462c:	fffff097          	auipc	ra,0xfffff
    80004630:	0a4080e7          	jalr	164(ra) # 800036d0 <bwrite>
  brelse(buf);
    80004634:	8526                	mv	a0,s1
    80004636:	fffff097          	auipc	ra,0xfffff
    8000463a:	0d8080e7          	jalr	216(ra) # 8000370e <brelse>
}
    8000463e:	60e2                	ld	ra,24(sp)
    80004640:	6442                	ld	s0,16(sp)
    80004642:	64a2                	ld	s1,8(sp)
    80004644:	6902                	ld	s2,0(sp)
    80004646:	6105                	addi	sp,sp,32
    80004648:	8082                	ret

000000008000464a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000464a:	0001d797          	auipc	a5,0x1d
    8000464e:	6c27a783          	lw	a5,1730(a5) # 80021d0c <log+0x2c>
    80004652:	0af05d63          	blez	a5,8000470c <install_trans+0xc2>
{
    80004656:	7139                	addi	sp,sp,-64
    80004658:	fc06                	sd	ra,56(sp)
    8000465a:	f822                	sd	s0,48(sp)
    8000465c:	f426                	sd	s1,40(sp)
    8000465e:	f04a                	sd	s2,32(sp)
    80004660:	ec4e                	sd	s3,24(sp)
    80004662:	e852                	sd	s4,16(sp)
    80004664:	e456                	sd	s5,8(sp)
    80004666:	e05a                	sd	s6,0(sp)
    80004668:	0080                	addi	s0,sp,64
    8000466a:	8b2a                	mv	s6,a0
    8000466c:	0001da97          	auipc	s5,0x1d
    80004670:	6a4a8a93          	addi	s5,s5,1700 # 80021d10 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004674:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004676:	0001d997          	auipc	s3,0x1d
    8000467a:	66a98993          	addi	s3,s3,1642 # 80021ce0 <log>
    8000467e:	a035                	j	800046aa <install_trans+0x60>
      bunpin(dbuf);
    80004680:	8526                	mv	a0,s1
    80004682:	fffff097          	auipc	ra,0xfffff
    80004686:	166080e7          	jalr	358(ra) # 800037e8 <bunpin>
    brelse(lbuf);
    8000468a:	854a                	mv	a0,s2
    8000468c:	fffff097          	auipc	ra,0xfffff
    80004690:	082080e7          	jalr	130(ra) # 8000370e <brelse>
    brelse(dbuf);
    80004694:	8526                	mv	a0,s1
    80004696:	fffff097          	auipc	ra,0xfffff
    8000469a:	078080e7          	jalr	120(ra) # 8000370e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000469e:	2a05                	addiw	s4,s4,1
    800046a0:	0a91                	addi	s5,s5,4
    800046a2:	02c9a783          	lw	a5,44(s3)
    800046a6:	04fa5963          	bge	s4,a5,800046f8 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800046aa:	0189a583          	lw	a1,24(s3)
    800046ae:	014585bb          	addw	a1,a1,s4
    800046b2:	2585                	addiw	a1,a1,1
    800046b4:	0289a503          	lw	a0,40(s3)
    800046b8:	fffff097          	auipc	ra,0xfffff
    800046bc:	f26080e7          	jalr	-218(ra) # 800035de <bread>
    800046c0:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800046c2:	000aa583          	lw	a1,0(s5)
    800046c6:	0289a503          	lw	a0,40(s3)
    800046ca:	fffff097          	auipc	ra,0xfffff
    800046ce:	f14080e7          	jalr	-236(ra) # 800035de <bread>
    800046d2:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800046d4:	40000613          	li	a2,1024
    800046d8:	05890593          	addi	a1,s2,88
    800046dc:	05850513          	addi	a0,a0,88
    800046e0:	ffffc097          	auipc	ra,0xffffc
    800046e4:	660080e7          	jalr	1632(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800046e8:	8526                	mv	a0,s1
    800046ea:	fffff097          	auipc	ra,0xfffff
    800046ee:	fe6080e7          	jalr	-26(ra) # 800036d0 <bwrite>
    if(recovering == 0)
    800046f2:	f80b1ce3          	bnez	s6,8000468a <install_trans+0x40>
    800046f6:	b769                	j	80004680 <install_trans+0x36>
}
    800046f8:	70e2                	ld	ra,56(sp)
    800046fa:	7442                	ld	s0,48(sp)
    800046fc:	74a2                	ld	s1,40(sp)
    800046fe:	7902                	ld	s2,32(sp)
    80004700:	69e2                	ld	s3,24(sp)
    80004702:	6a42                	ld	s4,16(sp)
    80004704:	6aa2                	ld	s5,8(sp)
    80004706:	6b02                	ld	s6,0(sp)
    80004708:	6121                	addi	sp,sp,64
    8000470a:	8082                	ret
    8000470c:	8082                	ret

000000008000470e <initlog>:
{
    8000470e:	7179                	addi	sp,sp,-48
    80004710:	f406                	sd	ra,40(sp)
    80004712:	f022                	sd	s0,32(sp)
    80004714:	ec26                	sd	s1,24(sp)
    80004716:	e84a                	sd	s2,16(sp)
    80004718:	e44e                	sd	s3,8(sp)
    8000471a:	1800                	addi	s0,sp,48
    8000471c:	892a                	mv	s2,a0
    8000471e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004720:	0001d497          	auipc	s1,0x1d
    80004724:	5c048493          	addi	s1,s1,1472 # 80021ce0 <log>
    80004728:	00004597          	auipc	a1,0x4
    8000472c:	f1058593          	addi	a1,a1,-240 # 80008638 <syscalls+0x1f0>
    80004730:	8526                	mv	a0,s1
    80004732:	ffffc097          	auipc	ra,0xffffc
    80004736:	422080e7          	jalr	1058(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    8000473a:	0149a583          	lw	a1,20(s3)
    8000473e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004740:	0109a783          	lw	a5,16(s3)
    80004744:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004746:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000474a:	854a                	mv	a0,s2
    8000474c:	fffff097          	auipc	ra,0xfffff
    80004750:	e92080e7          	jalr	-366(ra) # 800035de <bread>
  log.lh.n = lh->n;
    80004754:	4d3c                	lw	a5,88(a0)
    80004756:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004758:	02f05563          	blez	a5,80004782 <initlog+0x74>
    8000475c:	05c50713          	addi	a4,a0,92
    80004760:	0001d697          	auipc	a3,0x1d
    80004764:	5b068693          	addi	a3,a3,1456 # 80021d10 <log+0x30>
    80004768:	37fd                	addiw	a5,a5,-1
    8000476a:	1782                	slli	a5,a5,0x20
    8000476c:	9381                	srli	a5,a5,0x20
    8000476e:	078a                	slli	a5,a5,0x2
    80004770:	06050613          	addi	a2,a0,96
    80004774:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004776:	4310                	lw	a2,0(a4)
    80004778:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000477a:	0711                	addi	a4,a4,4
    8000477c:	0691                	addi	a3,a3,4
    8000477e:	fef71ce3          	bne	a4,a5,80004776 <initlog+0x68>
  brelse(buf);
    80004782:	fffff097          	auipc	ra,0xfffff
    80004786:	f8c080e7          	jalr	-116(ra) # 8000370e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000478a:	4505                	li	a0,1
    8000478c:	00000097          	auipc	ra,0x0
    80004790:	ebe080e7          	jalr	-322(ra) # 8000464a <install_trans>
  log.lh.n = 0;
    80004794:	0001d797          	auipc	a5,0x1d
    80004798:	5607ac23          	sw	zero,1400(a5) # 80021d0c <log+0x2c>
  write_head(); // clear the log
    8000479c:	00000097          	auipc	ra,0x0
    800047a0:	e34080e7          	jalr	-460(ra) # 800045d0 <write_head>
}
    800047a4:	70a2                	ld	ra,40(sp)
    800047a6:	7402                	ld	s0,32(sp)
    800047a8:	64e2                	ld	s1,24(sp)
    800047aa:	6942                	ld	s2,16(sp)
    800047ac:	69a2                	ld	s3,8(sp)
    800047ae:	6145                	addi	sp,sp,48
    800047b0:	8082                	ret

00000000800047b2 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800047b2:	1101                	addi	sp,sp,-32
    800047b4:	ec06                	sd	ra,24(sp)
    800047b6:	e822                	sd	s0,16(sp)
    800047b8:	e426                	sd	s1,8(sp)
    800047ba:	e04a                	sd	s2,0(sp)
    800047bc:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800047be:	0001d517          	auipc	a0,0x1d
    800047c2:	52250513          	addi	a0,a0,1314 # 80021ce0 <log>
    800047c6:	ffffc097          	auipc	ra,0xffffc
    800047ca:	41e080e7          	jalr	1054(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800047ce:	0001d497          	auipc	s1,0x1d
    800047d2:	51248493          	addi	s1,s1,1298 # 80021ce0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800047d6:	4979                	li	s2,30
    800047d8:	a039                	j	800047e6 <begin_op+0x34>
      sleep(&log, &log.lock);
    800047da:	85a6                	mv	a1,s1
    800047dc:	8526                	mv	a0,s1
    800047de:	ffffe097          	auipc	ra,0xffffe
    800047e2:	e60080e7          	jalr	-416(ra) # 8000263e <sleep>
    if(log.committing){
    800047e6:	50dc                	lw	a5,36(s1)
    800047e8:	fbed                	bnez	a5,800047da <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800047ea:	509c                	lw	a5,32(s1)
    800047ec:	0017871b          	addiw	a4,a5,1
    800047f0:	0007069b          	sext.w	a3,a4
    800047f4:	0027179b          	slliw	a5,a4,0x2
    800047f8:	9fb9                	addw	a5,a5,a4
    800047fa:	0017979b          	slliw	a5,a5,0x1
    800047fe:	54d8                	lw	a4,44(s1)
    80004800:	9fb9                	addw	a5,a5,a4
    80004802:	00f95963          	bge	s2,a5,80004814 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004806:	85a6                	mv	a1,s1
    80004808:	8526                	mv	a0,s1
    8000480a:	ffffe097          	auipc	ra,0xffffe
    8000480e:	e34080e7          	jalr	-460(ra) # 8000263e <sleep>
    80004812:	bfd1                	j	800047e6 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004814:	0001d517          	auipc	a0,0x1d
    80004818:	4cc50513          	addi	a0,a0,1228 # 80021ce0 <log>
    8000481c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000481e:	ffffc097          	auipc	ra,0xffffc
    80004822:	47a080e7          	jalr	1146(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004826:	60e2                	ld	ra,24(sp)
    80004828:	6442                	ld	s0,16(sp)
    8000482a:	64a2                	ld	s1,8(sp)
    8000482c:	6902                	ld	s2,0(sp)
    8000482e:	6105                	addi	sp,sp,32
    80004830:	8082                	ret

0000000080004832 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004832:	7139                	addi	sp,sp,-64
    80004834:	fc06                	sd	ra,56(sp)
    80004836:	f822                	sd	s0,48(sp)
    80004838:	f426                	sd	s1,40(sp)
    8000483a:	f04a                	sd	s2,32(sp)
    8000483c:	ec4e                	sd	s3,24(sp)
    8000483e:	e852                	sd	s4,16(sp)
    80004840:	e456                	sd	s5,8(sp)
    80004842:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004844:	0001d497          	auipc	s1,0x1d
    80004848:	49c48493          	addi	s1,s1,1180 # 80021ce0 <log>
    8000484c:	8526                	mv	a0,s1
    8000484e:	ffffc097          	auipc	ra,0xffffc
    80004852:	396080e7          	jalr	918(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004856:	509c                	lw	a5,32(s1)
    80004858:	37fd                	addiw	a5,a5,-1
    8000485a:	0007891b          	sext.w	s2,a5
    8000485e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004860:	50dc                	lw	a5,36(s1)
    80004862:	efb9                	bnez	a5,800048c0 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004864:	06091663          	bnez	s2,800048d0 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004868:	0001d497          	auipc	s1,0x1d
    8000486c:	47848493          	addi	s1,s1,1144 # 80021ce0 <log>
    80004870:	4785                	li	a5,1
    80004872:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004874:	8526                	mv	a0,s1
    80004876:	ffffc097          	auipc	ra,0xffffc
    8000487a:	422080e7          	jalr	1058(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000487e:	54dc                	lw	a5,44(s1)
    80004880:	06f04763          	bgtz	a5,800048ee <end_op+0xbc>
    acquire(&log.lock);
    80004884:	0001d497          	auipc	s1,0x1d
    80004888:	45c48493          	addi	s1,s1,1116 # 80021ce0 <log>
    8000488c:	8526                	mv	a0,s1
    8000488e:	ffffc097          	auipc	ra,0xffffc
    80004892:	356080e7          	jalr	854(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004896:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000489a:	8526                	mv	a0,s1
    8000489c:	ffffe097          	auipc	ra,0xffffe
    800048a0:	f9e080e7          	jalr	-98(ra) # 8000283a <wakeup>
    release(&log.lock);
    800048a4:	8526                	mv	a0,s1
    800048a6:	ffffc097          	auipc	ra,0xffffc
    800048aa:	3f2080e7          	jalr	1010(ra) # 80000c98 <release>
}
    800048ae:	70e2                	ld	ra,56(sp)
    800048b0:	7442                	ld	s0,48(sp)
    800048b2:	74a2                	ld	s1,40(sp)
    800048b4:	7902                	ld	s2,32(sp)
    800048b6:	69e2                	ld	s3,24(sp)
    800048b8:	6a42                	ld	s4,16(sp)
    800048ba:	6aa2                	ld	s5,8(sp)
    800048bc:	6121                	addi	sp,sp,64
    800048be:	8082                	ret
    panic("log.committing");
    800048c0:	00004517          	auipc	a0,0x4
    800048c4:	d8050513          	addi	a0,a0,-640 # 80008640 <syscalls+0x1f8>
    800048c8:	ffffc097          	auipc	ra,0xffffc
    800048cc:	c76080e7          	jalr	-906(ra) # 8000053e <panic>
    wakeup(&log);
    800048d0:	0001d497          	auipc	s1,0x1d
    800048d4:	41048493          	addi	s1,s1,1040 # 80021ce0 <log>
    800048d8:	8526                	mv	a0,s1
    800048da:	ffffe097          	auipc	ra,0xffffe
    800048de:	f60080e7          	jalr	-160(ra) # 8000283a <wakeup>
  release(&log.lock);
    800048e2:	8526                	mv	a0,s1
    800048e4:	ffffc097          	auipc	ra,0xffffc
    800048e8:	3b4080e7          	jalr	948(ra) # 80000c98 <release>
  if(do_commit){
    800048ec:	b7c9                	j	800048ae <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800048ee:	0001da97          	auipc	s5,0x1d
    800048f2:	422a8a93          	addi	s5,s5,1058 # 80021d10 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800048f6:	0001da17          	auipc	s4,0x1d
    800048fa:	3eaa0a13          	addi	s4,s4,1002 # 80021ce0 <log>
    800048fe:	018a2583          	lw	a1,24(s4)
    80004902:	012585bb          	addw	a1,a1,s2
    80004906:	2585                	addiw	a1,a1,1
    80004908:	028a2503          	lw	a0,40(s4)
    8000490c:	fffff097          	auipc	ra,0xfffff
    80004910:	cd2080e7          	jalr	-814(ra) # 800035de <bread>
    80004914:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004916:	000aa583          	lw	a1,0(s5)
    8000491a:	028a2503          	lw	a0,40(s4)
    8000491e:	fffff097          	auipc	ra,0xfffff
    80004922:	cc0080e7          	jalr	-832(ra) # 800035de <bread>
    80004926:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004928:	40000613          	li	a2,1024
    8000492c:	05850593          	addi	a1,a0,88
    80004930:	05848513          	addi	a0,s1,88
    80004934:	ffffc097          	auipc	ra,0xffffc
    80004938:	40c080e7          	jalr	1036(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    8000493c:	8526                	mv	a0,s1
    8000493e:	fffff097          	auipc	ra,0xfffff
    80004942:	d92080e7          	jalr	-622(ra) # 800036d0 <bwrite>
    brelse(from);
    80004946:	854e                	mv	a0,s3
    80004948:	fffff097          	auipc	ra,0xfffff
    8000494c:	dc6080e7          	jalr	-570(ra) # 8000370e <brelse>
    brelse(to);
    80004950:	8526                	mv	a0,s1
    80004952:	fffff097          	auipc	ra,0xfffff
    80004956:	dbc080e7          	jalr	-580(ra) # 8000370e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000495a:	2905                	addiw	s2,s2,1
    8000495c:	0a91                	addi	s5,s5,4
    8000495e:	02ca2783          	lw	a5,44(s4)
    80004962:	f8f94ee3          	blt	s2,a5,800048fe <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004966:	00000097          	auipc	ra,0x0
    8000496a:	c6a080e7          	jalr	-918(ra) # 800045d0 <write_head>
    install_trans(0); // Now install writes to home locations
    8000496e:	4501                	li	a0,0
    80004970:	00000097          	auipc	ra,0x0
    80004974:	cda080e7          	jalr	-806(ra) # 8000464a <install_trans>
    log.lh.n = 0;
    80004978:	0001d797          	auipc	a5,0x1d
    8000497c:	3807aa23          	sw	zero,916(a5) # 80021d0c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004980:	00000097          	auipc	ra,0x0
    80004984:	c50080e7          	jalr	-944(ra) # 800045d0 <write_head>
    80004988:	bdf5                	j	80004884 <end_op+0x52>

000000008000498a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000498a:	1101                	addi	sp,sp,-32
    8000498c:	ec06                	sd	ra,24(sp)
    8000498e:	e822                	sd	s0,16(sp)
    80004990:	e426                	sd	s1,8(sp)
    80004992:	e04a                	sd	s2,0(sp)
    80004994:	1000                	addi	s0,sp,32
    80004996:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004998:	0001d917          	auipc	s2,0x1d
    8000499c:	34890913          	addi	s2,s2,840 # 80021ce0 <log>
    800049a0:	854a                	mv	a0,s2
    800049a2:	ffffc097          	auipc	ra,0xffffc
    800049a6:	242080e7          	jalr	578(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800049aa:	02c92603          	lw	a2,44(s2)
    800049ae:	47f5                	li	a5,29
    800049b0:	06c7c563          	blt	a5,a2,80004a1a <log_write+0x90>
    800049b4:	0001d797          	auipc	a5,0x1d
    800049b8:	3487a783          	lw	a5,840(a5) # 80021cfc <log+0x1c>
    800049bc:	37fd                	addiw	a5,a5,-1
    800049be:	04f65e63          	bge	a2,a5,80004a1a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800049c2:	0001d797          	auipc	a5,0x1d
    800049c6:	33e7a783          	lw	a5,830(a5) # 80021d00 <log+0x20>
    800049ca:	06f05063          	blez	a5,80004a2a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800049ce:	4781                	li	a5,0
    800049d0:	06c05563          	blez	a2,80004a3a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800049d4:	44cc                	lw	a1,12(s1)
    800049d6:	0001d717          	auipc	a4,0x1d
    800049da:	33a70713          	addi	a4,a4,826 # 80021d10 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800049de:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800049e0:	4314                	lw	a3,0(a4)
    800049e2:	04b68c63          	beq	a3,a1,80004a3a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800049e6:	2785                	addiw	a5,a5,1
    800049e8:	0711                	addi	a4,a4,4
    800049ea:	fef61be3          	bne	a2,a5,800049e0 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800049ee:	0621                	addi	a2,a2,8
    800049f0:	060a                	slli	a2,a2,0x2
    800049f2:	0001d797          	auipc	a5,0x1d
    800049f6:	2ee78793          	addi	a5,a5,750 # 80021ce0 <log>
    800049fa:	963e                	add	a2,a2,a5
    800049fc:	44dc                	lw	a5,12(s1)
    800049fe:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004a00:	8526                	mv	a0,s1
    80004a02:	fffff097          	auipc	ra,0xfffff
    80004a06:	daa080e7          	jalr	-598(ra) # 800037ac <bpin>
    log.lh.n++;
    80004a0a:	0001d717          	auipc	a4,0x1d
    80004a0e:	2d670713          	addi	a4,a4,726 # 80021ce0 <log>
    80004a12:	575c                	lw	a5,44(a4)
    80004a14:	2785                	addiw	a5,a5,1
    80004a16:	d75c                	sw	a5,44(a4)
    80004a18:	a835                	j	80004a54 <log_write+0xca>
    panic("too big a transaction");
    80004a1a:	00004517          	auipc	a0,0x4
    80004a1e:	c3650513          	addi	a0,a0,-970 # 80008650 <syscalls+0x208>
    80004a22:	ffffc097          	auipc	ra,0xffffc
    80004a26:	b1c080e7          	jalr	-1252(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004a2a:	00004517          	auipc	a0,0x4
    80004a2e:	c3e50513          	addi	a0,a0,-962 # 80008668 <syscalls+0x220>
    80004a32:	ffffc097          	auipc	ra,0xffffc
    80004a36:	b0c080e7          	jalr	-1268(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004a3a:	00878713          	addi	a4,a5,8
    80004a3e:	00271693          	slli	a3,a4,0x2
    80004a42:	0001d717          	auipc	a4,0x1d
    80004a46:	29e70713          	addi	a4,a4,670 # 80021ce0 <log>
    80004a4a:	9736                	add	a4,a4,a3
    80004a4c:	44d4                	lw	a3,12(s1)
    80004a4e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004a50:	faf608e3          	beq	a2,a5,80004a00 <log_write+0x76>
  }
  release(&log.lock);
    80004a54:	0001d517          	auipc	a0,0x1d
    80004a58:	28c50513          	addi	a0,a0,652 # 80021ce0 <log>
    80004a5c:	ffffc097          	auipc	ra,0xffffc
    80004a60:	23c080e7          	jalr	572(ra) # 80000c98 <release>
}
    80004a64:	60e2                	ld	ra,24(sp)
    80004a66:	6442                	ld	s0,16(sp)
    80004a68:	64a2                	ld	s1,8(sp)
    80004a6a:	6902                	ld	s2,0(sp)
    80004a6c:	6105                	addi	sp,sp,32
    80004a6e:	8082                	ret

0000000080004a70 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004a70:	1101                	addi	sp,sp,-32
    80004a72:	ec06                	sd	ra,24(sp)
    80004a74:	e822                	sd	s0,16(sp)
    80004a76:	e426                	sd	s1,8(sp)
    80004a78:	e04a                	sd	s2,0(sp)
    80004a7a:	1000                	addi	s0,sp,32
    80004a7c:	84aa                	mv	s1,a0
    80004a7e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004a80:	00004597          	auipc	a1,0x4
    80004a84:	c0858593          	addi	a1,a1,-1016 # 80008688 <syscalls+0x240>
    80004a88:	0521                	addi	a0,a0,8
    80004a8a:	ffffc097          	auipc	ra,0xffffc
    80004a8e:	0ca080e7          	jalr	202(ra) # 80000b54 <initlock>
  lk->name = name;
    80004a92:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004a96:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a9a:	0204a423          	sw	zero,40(s1)
}
    80004a9e:	60e2                	ld	ra,24(sp)
    80004aa0:	6442                	ld	s0,16(sp)
    80004aa2:	64a2                	ld	s1,8(sp)
    80004aa4:	6902                	ld	s2,0(sp)
    80004aa6:	6105                	addi	sp,sp,32
    80004aa8:	8082                	ret

0000000080004aaa <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004aaa:	1101                	addi	sp,sp,-32
    80004aac:	ec06                	sd	ra,24(sp)
    80004aae:	e822                	sd	s0,16(sp)
    80004ab0:	e426                	sd	s1,8(sp)
    80004ab2:	e04a                	sd	s2,0(sp)
    80004ab4:	1000                	addi	s0,sp,32
    80004ab6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004ab8:	00850913          	addi	s2,a0,8
    80004abc:	854a                	mv	a0,s2
    80004abe:	ffffc097          	auipc	ra,0xffffc
    80004ac2:	126080e7          	jalr	294(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004ac6:	409c                	lw	a5,0(s1)
    80004ac8:	cb89                	beqz	a5,80004ada <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004aca:	85ca                	mv	a1,s2
    80004acc:	8526                	mv	a0,s1
    80004ace:	ffffe097          	auipc	ra,0xffffe
    80004ad2:	b70080e7          	jalr	-1168(ra) # 8000263e <sleep>
  while (lk->locked) {
    80004ad6:	409c                	lw	a5,0(s1)
    80004ad8:	fbed                	bnez	a5,80004aca <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004ada:	4785                	li	a5,1
    80004adc:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004ade:	ffffd097          	auipc	ra,0xffffd
    80004ae2:	1d0080e7          	jalr	464(ra) # 80001cae <myproc>
    80004ae6:	453c                	lw	a5,72(a0)
    80004ae8:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004aea:	854a                	mv	a0,s2
    80004aec:	ffffc097          	auipc	ra,0xffffc
    80004af0:	1ac080e7          	jalr	428(ra) # 80000c98 <release>
}
    80004af4:	60e2                	ld	ra,24(sp)
    80004af6:	6442                	ld	s0,16(sp)
    80004af8:	64a2                	ld	s1,8(sp)
    80004afa:	6902                	ld	s2,0(sp)
    80004afc:	6105                	addi	sp,sp,32
    80004afe:	8082                	ret

0000000080004b00 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004b00:	1101                	addi	sp,sp,-32
    80004b02:	ec06                	sd	ra,24(sp)
    80004b04:	e822                	sd	s0,16(sp)
    80004b06:	e426                	sd	s1,8(sp)
    80004b08:	e04a                	sd	s2,0(sp)
    80004b0a:	1000                	addi	s0,sp,32
    80004b0c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004b0e:	00850913          	addi	s2,a0,8
    80004b12:	854a                	mv	a0,s2
    80004b14:	ffffc097          	auipc	ra,0xffffc
    80004b18:	0d0080e7          	jalr	208(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004b1c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004b20:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004b24:	8526                	mv	a0,s1
    80004b26:	ffffe097          	auipc	ra,0xffffe
    80004b2a:	d14080e7          	jalr	-748(ra) # 8000283a <wakeup>
  release(&lk->lk);
    80004b2e:	854a                	mv	a0,s2
    80004b30:	ffffc097          	auipc	ra,0xffffc
    80004b34:	168080e7          	jalr	360(ra) # 80000c98 <release>
}
    80004b38:	60e2                	ld	ra,24(sp)
    80004b3a:	6442                	ld	s0,16(sp)
    80004b3c:	64a2                	ld	s1,8(sp)
    80004b3e:	6902                	ld	s2,0(sp)
    80004b40:	6105                	addi	sp,sp,32
    80004b42:	8082                	ret

0000000080004b44 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004b44:	7179                	addi	sp,sp,-48
    80004b46:	f406                	sd	ra,40(sp)
    80004b48:	f022                	sd	s0,32(sp)
    80004b4a:	ec26                	sd	s1,24(sp)
    80004b4c:	e84a                	sd	s2,16(sp)
    80004b4e:	e44e                	sd	s3,8(sp)
    80004b50:	1800                	addi	s0,sp,48
    80004b52:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004b54:	00850913          	addi	s2,a0,8
    80004b58:	854a                	mv	a0,s2
    80004b5a:	ffffc097          	auipc	ra,0xffffc
    80004b5e:	08a080e7          	jalr	138(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b62:	409c                	lw	a5,0(s1)
    80004b64:	ef99                	bnez	a5,80004b82 <holdingsleep+0x3e>
    80004b66:	4481                	li	s1,0
  release(&lk->lk);
    80004b68:	854a                	mv	a0,s2
    80004b6a:	ffffc097          	auipc	ra,0xffffc
    80004b6e:	12e080e7          	jalr	302(ra) # 80000c98 <release>
  return r;
}
    80004b72:	8526                	mv	a0,s1
    80004b74:	70a2                	ld	ra,40(sp)
    80004b76:	7402                	ld	s0,32(sp)
    80004b78:	64e2                	ld	s1,24(sp)
    80004b7a:	6942                	ld	s2,16(sp)
    80004b7c:	69a2                	ld	s3,8(sp)
    80004b7e:	6145                	addi	sp,sp,48
    80004b80:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b82:	0284a983          	lw	s3,40(s1)
    80004b86:	ffffd097          	auipc	ra,0xffffd
    80004b8a:	128080e7          	jalr	296(ra) # 80001cae <myproc>
    80004b8e:	4524                	lw	s1,72(a0)
    80004b90:	413484b3          	sub	s1,s1,s3
    80004b94:	0014b493          	seqz	s1,s1
    80004b98:	bfc1                	j	80004b68 <holdingsleep+0x24>

0000000080004b9a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004b9a:	1141                	addi	sp,sp,-16
    80004b9c:	e406                	sd	ra,8(sp)
    80004b9e:	e022                	sd	s0,0(sp)
    80004ba0:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004ba2:	00004597          	auipc	a1,0x4
    80004ba6:	af658593          	addi	a1,a1,-1290 # 80008698 <syscalls+0x250>
    80004baa:	0001d517          	auipc	a0,0x1d
    80004bae:	27e50513          	addi	a0,a0,638 # 80021e28 <ftable>
    80004bb2:	ffffc097          	auipc	ra,0xffffc
    80004bb6:	fa2080e7          	jalr	-94(ra) # 80000b54 <initlock>
}
    80004bba:	60a2                	ld	ra,8(sp)
    80004bbc:	6402                	ld	s0,0(sp)
    80004bbe:	0141                	addi	sp,sp,16
    80004bc0:	8082                	ret

0000000080004bc2 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004bc2:	1101                	addi	sp,sp,-32
    80004bc4:	ec06                	sd	ra,24(sp)
    80004bc6:	e822                	sd	s0,16(sp)
    80004bc8:	e426                	sd	s1,8(sp)
    80004bca:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004bcc:	0001d517          	auipc	a0,0x1d
    80004bd0:	25c50513          	addi	a0,a0,604 # 80021e28 <ftable>
    80004bd4:	ffffc097          	auipc	ra,0xffffc
    80004bd8:	010080e7          	jalr	16(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004bdc:	0001d497          	auipc	s1,0x1d
    80004be0:	26448493          	addi	s1,s1,612 # 80021e40 <ftable+0x18>
    80004be4:	0001e717          	auipc	a4,0x1e
    80004be8:	1fc70713          	addi	a4,a4,508 # 80022de0 <ftable+0xfb8>
    if(f->ref == 0){
    80004bec:	40dc                	lw	a5,4(s1)
    80004bee:	cf99                	beqz	a5,80004c0c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004bf0:	02848493          	addi	s1,s1,40
    80004bf4:	fee49ce3          	bne	s1,a4,80004bec <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004bf8:	0001d517          	auipc	a0,0x1d
    80004bfc:	23050513          	addi	a0,a0,560 # 80021e28 <ftable>
    80004c00:	ffffc097          	auipc	ra,0xffffc
    80004c04:	098080e7          	jalr	152(ra) # 80000c98 <release>
  return 0;
    80004c08:	4481                	li	s1,0
    80004c0a:	a819                	j	80004c20 <filealloc+0x5e>
      f->ref = 1;
    80004c0c:	4785                	li	a5,1
    80004c0e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004c10:	0001d517          	auipc	a0,0x1d
    80004c14:	21850513          	addi	a0,a0,536 # 80021e28 <ftable>
    80004c18:	ffffc097          	auipc	ra,0xffffc
    80004c1c:	080080e7          	jalr	128(ra) # 80000c98 <release>
}
    80004c20:	8526                	mv	a0,s1
    80004c22:	60e2                	ld	ra,24(sp)
    80004c24:	6442                	ld	s0,16(sp)
    80004c26:	64a2                	ld	s1,8(sp)
    80004c28:	6105                	addi	sp,sp,32
    80004c2a:	8082                	ret

0000000080004c2c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004c2c:	1101                	addi	sp,sp,-32
    80004c2e:	ec06                	sd	ra,24(sp)
    80004c30:	e822                	sd	s0,16(sp)
    80004c32:	e426                	sd	s1,8(sp)
    80004c34:	1000                	addi	s0,sp,32
    80004c36:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004c38:	0001d517          	auipc	a0,0x1d
    80004c3c:	1f050513          	addi	a0,a0,496 # 80021e28 <ftable>
    80004c40:	ffffc097          	auipc	ra,0xffffc
    80004c44:	fa4080e7          	jalr	-92(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004c48:	40dc                	lw	a5,4(s1)
    80004c4a:	02f05263          	blez	a5,80004c6e <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004c4e:	2785                	addiw	a5,a5,1
    80004c50:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004c52:	0001d517          	auipc	a0,0x1d
    80004c56:	1d650513          	addi	a0,a0,470 # 80021e28 <ftable>
    80004c5a:	ffffc097          	auipc	ra,0xffffc
    80004c5e:	03e080e7          	jalr	62(ra) # 80000c98 <release>
  return f;
}
    80004c62:	8526                	mv	a0,s1
    80004c64:	60e2                	ld	ra,24(sp)
    80004c66:	6442                	ld	s0,16(sp)
    80004c68:	64a2                	ld	s1,8(sp)
    80004c6a:	6105                	addi	sp,sp,32
    80004c6c:	8082                	ret
    panic("filedup");
    80004c6e:	00004517          	auipc	a0,0x4
    80004c72:	a3250513          	addi	a0,a0,-1486 # 800086a0 <syscalls+0x258>
    80004c76:	ffffc097          	auipc	ra,0xffffc
    80004c7a:	8c8080e7          	jalr	-1848(ra) # 8000053e <panic>

0000000080004c7e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004c7e:	7139                	addi	sp,sp,-64
    80004c80:	fc06                	sd	ra,56(sp)
    80004c82:	f822                	sd	s0,48(sp)
    80004c84:	f426                	sd	s1,40(sp)
    80004c86:	f04a                	sd	s2,32(sp)
    80004c88:	ec4e                	sd	s3,24(sp)
    80004c8a:	e852                	sd	s4,16(sp)
    80004c8c:	e456                	sd	s5,8(sp)
    80004c8e:	0080                	addi	s0,sp,64
    80004c90:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004c92:	0001d517          	auipc	a0,0x1d
    80004c96:	19650513          	addi	a0,a0,406 # 80021e28 <ftable>
    80004c9a:	ffffc097          	auipc	ra,0xffffc
    80004c9e:	f4a080e7          	jalr	-182(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004ca2:	40dc                	lw	a5,4(s1)
    80004ca4:	06f05163          	blez	a5,80004d06 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004ca8:	37fd                	addiw	a5,a5,-1
    80004caa:	0007871b          	sext.w	a4,a5
    80004cae:	c0dc                	sw	a5,4(s1)
    80004cb0:	06e04363          	bgtz	a4,80004d16 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004cb4:	0004a903          	lw	s2,0(s1)
    80004cb8:	0094ca83          	lbu	s5,9(s1)
    80004cbc:	0104ba03          	ld	s4,16(s1)
    80004cc0:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004cc4:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004cc8:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004ccc:	0001d517          	auipc	a0,0x1d
    80004cd0:	15c50513          	addi	a0,a0,348 # 80021e28 <ftable>
    80004cd4:	ffffc097          	auipc	ra,0xffffc
    80004cd8:	fc4080e7          	jalr	-60(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004cdc:	4785                	li	a5,1
    80004cde:	04f90d63          	beq	s2,a5,80004d38 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004ce2:	3979                	addiw	s2,s2,-2
    80004ce4:	4785                	li	a5,1
    80004ce6:	0527e063          	bltu	a5,s2,80004d26 <fileclose+0xa8>
    begin_op();
    80004cea:	00000097          	auipc	ra,0x0
    80004cee:	ac8080e7          	jalr	-1336(ra) # 800047b2 <begin_op>
    iput(ff.ip);
    80004cf2:	854e                	mv	a0,s3
    80004cf4:	fffff097          	auipc	ra,0xfffff
    80004cf8:	2a6080e7          	jalr	678(ra) # 80003f9a <iput>
    end_op();
    80004cfc:	00000097          	auipc	ra,0x0
    80004d00:	b36080e7          	jalr	-1226(ra) # 80004832 <end_op>
    80004d04:	a00d                	j	80004d26 <fileclose+0xa8>
    panic("fileclose");
    80004d06:	00004517          	auipc	a0,0x4
    80004d0a:	9a250513          	addi	a0,a0,-1630 # 800086a8 <syscalls+0x260>
    80004d0e:	ffffc097          	auipc	ra,0xffffc
    80004d12:	830080e7          	jalr	-2000(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004d16:	0001d517          	auipc	a0,0x1d
    80004d1a:	11250513          	addi	a0,a0,274 # 80021e28 <ftable>
    80004d1e:	ffffc097          	auipc	ra,0xffffc
    80004d22:	f7a080e7          	jalr	-134(ra) # 80000c98 <release>
  }
}
    80004d26:	70e2                	ld	ra,56(sp)
    80004d28:	7442                	ld	s0,48(sp)
    80004d2a:	74a2                	ld	s1,40(sp)
    80004d2c:	7902                	ld	s2,32(sp)
    80004d2e:	69e2                	ld	s3,24(sp)
    80004d30:	6a42                	ld	s4,16(sp)
    80004d32:	6aa2                	ld	s5,8(sp)
    80004d34:	6121                	addi	sp,sp,64
    80004d36:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004d38:	85d6                	mv	a1,s5
    80004d3a:	8552                	mv	a0,s4
    80004d3c:	00000097          	auipc	ra,0x0
    80004d40:	34c080e7          	jalr	844(ra) # 80005088 <pipeclose>
    80004d44:	b7cd                	j	80004d26 <fileclose+0xa8>

0000000080004d46 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004d46:	715d                	addi	sp,sp,-80
    80004d48:	e486                	sd	ra,72(sp)
    80004d4a:	e0a2                	sd	s0,64(sp)
    80004d4c:	fc26                	sd	s1,56(sp)
    80004d4e:	f84a                	sd	s2,48(sp)
    80004d50:	f44e                	sd	s3,40(sp)
    80004d52:	0880                	addi	s0,sp,80
    80004d54:	84aa                	mv	s1,a0
    80004d56:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004d58:	ffffd097          	auipc	ra,0xffffd
    80004d5c:	f56080e7          	jalr	-170(ra) # 80001cae <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004d60:	409c                	lw	a5,0(s1)
    80004d62:	37f9                	addiw	a5,a5,-2
    80004d64:	4705                	li	a4,1
    80004d66:	04f76763          	bltu	a4,a5,80004db4 <filestat+0x6e>
    80004d6a:	892a                	mv	s2,a0
    ilock(f->ip);
    80004d6c:	6c88                	ld	a0,24(s1)
    80004d6e:	fffff097          	auipc	ra,0xfffff
    80004d72:	072080e7          	jalr	114(ra) # 80003de0 <ilock>
    stati(f->ip, &st);
    80004d76:	fb840593          	addi	a1,s0,-72
    80004d7a:	6c88                	ld	a0,24(s1)
    80004d7c:	fffff097          	auipc	ra,0xfffff
    80004d80:	2ee080e7          	jalr	750(ra) # 8000406a <stati>
    iunlock(f->ip);
    80004d84:	6c88                	ld	a0,24(s1)
    80004d86:	fffff097          	auipc	ra,0xfffff
    80004d8a:	11c080e7          	jalr	284(ra) # 80003ea2 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004d8e:	46e1                	li	a3,24
    80004d90:	fb840613          	addi	a2,s0,-72
    80004d94:	85ce                	mv	a1,s3
    80004d96:	07893503          	ld	a0,120(s2)
    80004d9a:	ffffd097          	auipc	ra,0xffffd
    80004d9e:	8d8080e7          	jalr	-1832(ra) # 80001672 <copyout>
    80004da2:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004da6:	60a6                	ld	ra,72(sp)
    80004da8:	6406                	ld	s0,64(sp)
    80004daa:	74e2                	ld	s1,56(sp)
    80004dac:	7942                	ld	s2,48(sp)
    80004dae:	79a2                	ld	s3,40(sp)
    80004db0:	6161                	addi	sp,sp,80
    80004db2:	8082                	ret
  return -1;
    80004db4:	557d                	li	a0,-1
    80004db6:	bfc5                	j	80004da6 <filestat+0x60>

0000000080004db8 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004db8:	7179                	addi	sp,sp,-48
    80004dba:	f406                	sd	ra,40(sp)
    80004dbc:	f022                	sd	s0,32(sp)
    80004dbe:	ec26                	sd	s1,24(sp)
    80004dc0:	e84a                	sd	s2,16(sp)
    80004dc2:	e44e                	sd	s3,8(sp)
    80004dc4:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004dc6:	00854783          	lbu	a5,8(a0)
    80004dca:	c3d5                	beqz	a5,80004e6e <fileread+0xb6>
    80004dcc:	84aa                	mv	s1,a0
    80004dce:	89ae                	mv	s3,a1
    80004dd0:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004dd2:	411c                	lw	a5,0(a0)
    80004dd4:	4705                	li	a4,1
    80004dd6:	04e78963          	beq	a5,a4,80004e28 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004dda:	470d                	li	a4,3
    80004ddc:	04e78d63          	beq	a5,a4,80004e36 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004de0:	4709                	li	a4,2
    80004de2:	06e79e63          	bne	a5,a4,80004e5e <fileread+0xa6>
    ilock(f->ip);
    80004de6:	6d08                	ld	a0,24(a0)
    80004de8:	fffff097          	auipc	ra,0xfffff
    80004dec:	ff8080e7          	jalr	-8(ra) # 80003de0 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004df0:	874a                	mv	a4,s2
    80004df2:	5094                	lw	a3,32(s1)
    80004df4:	864e                	mv	a2,s3
    80004df6:	4585                	li	a1,1
    80004df8:	6c88                	ld	a0,24(s1)
    80004dfa:	fffff097          	auipc	ra,0xfffff
    80004dfe:	29a080e7          	jalr	666(ra) # 80004094 <readi>
    80004e02:	892a                	mv	s2,a0
    80004e04:	00a05563          	blez	a0,80004e0e <fileread+0x56>
      f->off += r;
    80004e08:	509c                	lw	a5,32(s1)
    80004e0a:	9fa9                	addw	a5,a5,a0
    80004e0c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004e0e:	6c88                	ld	a0,24(s1)
    80004e10:	fffff097          	auipc	ra,0xfffff
    80004e14:	092080e7          	jalr	146(ra) # 80003ea2 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004e18:	854a                	mv	a0,s2
    80004e1a:	70a2                	ld	ra,40(sp)
    80004e1c:	7402                	ld	s0,32(sp)
    80004e1e:	64e2                	ld	s1,24(sp)
    80004e20:	6942                	ld	s2,16(sp)
    80004e22:	69a2                	ld	s3,8(sp)
    80004e24:	6145                	addi	sp,sp,48
    80004e26:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004e28:	6908                	ld	a0,16(a0)
    80004e2a:	00000097          	auipc	ra,0x0
    80004e2e:	3c8080e7          	jalr	968(ra) # 800051f2 <piperead>
    80004e32:	892a                	mv	s2,a0
    80004e34:	b7d5                	j	80004e18 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004e36:	02451783          	lh	a5,36(a0)
    80004e3a:	03079693          	slli	a3,a5,0x30
    80004e3e:	92c1                	srli	a3,a3,0x30
    80004e40:	4725                	li	a4,9
    80004e42:	02d76863          	bltu	a4,a3,80004e72 <fileread+0xba>
    80004e46:	0792                	slli	a5,a5,0x4
    80004e48:	0001d717          	auipc	a4,0x1d
    80004e4c:	f4070713          	addi	a4,a4,-192 # 80021d88 <devsw>
    80004e50:	97ba                	add	a5,a5,a4
    80004e52:	639c                	ld	a5,0(a5)
    80004e54:	c38d                	beqz	a5,80004e76 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004e56:	4505                	li	a0,1
    80004e58:	9782                	jalr	a5
    80004e5a:	892a                	mv	s2,a0
    80004e5c:	bf75                	j	80004e18 <fileread+0x60>
    panic("fileread");
    80004e5e:	00004517          	auipc	a0,0x4
    80004e62:	85a50513          	addi	a0,a0,-1958 # 800086b8 <syscalls+0x270>
    80004e66:	ffffb097          	auipc	ra,0xffffb
    80004e6a:	6d8080e7          	jalr	1752(ra) # 8000053e <panic>
    return -1;
    80004e6e:	597d                	li	s2,-1
    80004e70:	b765                	j	80004e18 <fileread+0x60>
      return -1;
    80004e72:	597d                	li	s2,-1
    80004e74:	b755                	j	80004e18 <fileread+0x60>
    80004e76:	597d                	li	s2,-1
    80004e78:	b745                	j	80004e18 <fileread+0x60>

0000000080004e7a <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004e7a:	715d                	addi	sp,sp,-80
    80004e7c:	e486                	sd	ra,72(sp)
    80004e7e:	e0a2                	sd	s0,64(sp)
    80004e80:	fc26                	sd	s1,56(sp)
    80004e82:	f84a                	sd	s2,48(sp)
    80004e84:	f44e                	sd	s3,40(sp)
    80004e86:	f052                	sd	s4,32(sp)
    80004e88:	ec56                	sd	s5,24(sp)
    80004e8a:	e85a                	sd	s6,16(sp)
    80004e8c:	e45e                	sd	s7,8(sp)
    80004e8e:	e062                	sd	s8,0(sp)
    80004e90:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004e92:	00954783          	lbu	a5,9(a0)
    80004e96:	10078663          	beqz	a5,80004fa2 <filewrite+0x128>
    80004e9a:	892a                	mv	s2,a0
    80004e9c:	8aae                	mv	s5,a1
    80004e9e:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ea0:	411c                	lw	a5,0(a0)
    80004ea2:	4705                	li	a4,1
    80004ea4:	02e78263          	beq	a5,a4,80004ec8 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004ea8:	470d                	li	a4,3
    80004eaa:	02e78663          	beq	a5,a4,80004ed6 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004eae:	4709                	li	a4,2
    80004eb0:	0ee79163          	bne	a5,a4,80004f92 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004eb4:	0ac05d63          	blez	a2,80004f6e <filewrite+0xf4>
    int i = 0;
    80004eb8:	4981                	li	s3,0
    80004eba:	6b05                	lui	s6,0x1
    80004ebc:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004ec0:	6b85                	lui	s7,0x1
    80004ec2:	c00b8b9b          	addiw	s7,s7,-1024
    80004ec6:	a861                	j	80004f5e <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004ec8:	6908                	ld	a0,16(a0)
    80004eca:	00000097          	auipc	ra,0x0
    80004ece:	22e080e7          	jalr	558(ra) # 800050f8 <pipewrite>
    80004ed2:	8a2a                	mv	s4,a0
    80004ed4:	a045                	j	80004f74 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004ed6:	02451783          	lh	a5,36(a0)
    80004eda:	03079693          	slli	a3,a5,0x30
    80004ede:	92c1                	srli	a3,a3,0x30
    80004ee0:	4725                	li	a4,9
    80004ee2:	0cd76263          	bltu	a4,a3,80004fa6 <filewrite+0x12c>
    80004ee6:	0792                	slli	a5,a5,0x4
    80004ee8:	0001d717          	auipc	a4,0x1d
    80004eec:	ea070713          	addi	a4,a4,-352 # 80021d88 <devsw>
    80004ef0:	97ba                	add	a5,a5,a4
    80004ef2:	679c                	ld	a5,8(a5)
    80004ef4:	cbdd                	beqz	a5,80004faa <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004ef6:	4505                	li	a0,1
    80004ef8:	9782                	jalr	a5
    80004efa:	8a2a                	mv	s4,a0
    80004efc:	a8a5                	j	80004f74 <filewrite+0xfa>
    80004efe:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004f02:	00000097          	auipc	ra,0x0
    80004f06:	8b0080e7          	jalr	-1872(ra) # 800047b2 <begin_op>
      ilock(f->ip);
    80004f0a:	01893503          	ld	a0,24(s2)
    80004f0e:	fffff097          	auipc	ra,0xfffff
    80004f12:	ed2080e7          	jalr	-302(ra) # 80003de0 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004f16:	8762                	mv	a4,s8
    80004f18:	02092683          	lw	a3,32(s2)
    80004f1c:	01598633          	add	a2,s3,s5
    80004f20:	4585                	li	a1,1
    80004f22:	01893503          	ld	a0,24(s2)
    80004f26:	fffff097          	auipc	ra,0xfffff
    80004f2a:	266080e7          	jalr	614(ra) # 8000418c <writei>
    80004f2e:	84aa                	mv	s1,a0
    80004f30:	00a05763          	blez	a0,80004f3e <filewrite+0xc4>
        f->off += r;
    80004f34:	02092783          	lw	a5,32(s2)
    80004f38:	9fa9                	addw	a5,a5,a0
    80004f3a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004f3e:	01893503          	ld	a0,24(s2)
    80004f42:	fffff097          	auipc	ra,0xfffff
    80004f46:	f60080e7          	jalr	-160(ra) # 80003ea2 <iunlock>
      end_op();
    80004f4a:	00000097          	auipc	ra,0x0
    80004f4e:	8e8080e7          	jalr	-1816(ra) # 80004832 <end_op>

      if(r != n1){
    80004f52:	009c1f63          	bne	s8,s1,80004f70 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004f56:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004f5a:	0149db63          	bge	s3,s4,80004f70 <filewrite+0xf6>
      int n1 = n - i;
    80004f5e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004f62:	84be                	mv	s1,a5
    80004f64:	2781                	sext.w	a5,a5
    80004f66:	f8fb5ce3          	bge	s6,a5,80004efe <filewrite+0x84>
    80004f6a:	84de                	mv	s1,s7
    80004f6c:	bf49                	j	80004efe <filewrite+0x84>
    int i = 0;
    80004f6e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004f70:	013a1f63          	bne	s4,s3,80004f8e <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004f74:	8552                	mv	a0,s4
    80004f76:	60a6                	ld	ra,72(sp)
    80004f78:	6406                	ld	s0,64(sp)
    80004f7a:	74e2                	ld	s1,56(sp)
    80004f7c:	7942                	ld	s2,48(sp)
    80004f7e:	79a2                	ld	s3,40(sp)
    80004f80:	7a02                	ld	s4,32(sp)
    80004f82:	6ae2                	ld	s5,24(sp)
    80004f84:	6b42                	ld	s6,16(sp)
    80004f86:	6ba2                	ld	s7,8(sp)
    80004f88:	6c02                	ld	s8,0(sp)
    80004f8a:	6161                	addi	sp,sp,80
    80004f8c:	8082                	ret
    ret = (i == n ? n : -1);
    80004f8e:	5a7d                	li	s4,-1
    80004f90:	b7d5                	j	80004f74 <filewrite+0xfa>
    panic("filewrite");
    80004f92:	00003517          	auipc	a0,0x3
    80004f96:	73650513          	addi	a0,a0,1846 # 800086c8 <syscalls+0x280>
    80004f9a:	ffffb097          	auipc	ra,0xffffb
    80004f9e:	5a4080e7          	jalr	1444(ra) # 8000053e <panic>
    return -1;
    80004fa2:	5a7d                	li	s4,-1
    80004fa4:	bfc1                	j	80004f74 <filewrite+0xfa>
      return -1;
    80004fa6:	5a7d                	li	s4,-1
    80004fa8:	b7f1                	j	80004f74 <filewrite+0xfa>
    80004faa:	5a7d                	li	s4,-1
    80004fac:	b7e1                	j	80004f74 <filewrite+0xfa>

0000000080004fae <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004fae:	7179                	addi	sp,sp,-48
    80004fb0:	f406                	sd	ra,40(sp)
    80004fb2:	f022                	sd	s0,32(sp)
    80004fb4:	ec26                	sd	s1,24(sp)
    80004fb6:	e84a                	sd	s2,16(sp)
    80004fb8:	e44e                	sd	s3,8(sp)
    80004fba:	e052                	sd	s4,0(sp)
    80004fbc:	1800                	addi	s0,sp,48
    80004fbe:	84aa                	mv	s1,a0
    80004fc0:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004fc2:	0005b023          	sd	zero,0(a1)
    80004fc6:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004fca:	00000097          	auipc	ra,0x0
    80004fce:	bf8080e7          	jalr	-1032(ra) # 80004bc2 <filealloc>
    80004fd2:	e088                	sd	a0,0(s1)
    80004fd4:	c551                	beqz	a0,80005060 <pipealloc+0xb2>
    80004fd6:	00000097          	auipc	ra,0x0
    80004fda:	bec080e7          	jalr	-1044(ra) # 80004bc2 <filealloc>
    80004fde:	00aa3023          	sd	a0,0(s4)
    80004fe2:	c92d                	beqz	a0,80005054 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004fe4:	ffffc097          	auipc	ra,0xffffc
    80004fe8:	b10080e7          	jalr	-1264(ra) # 80000af4 <kalloc>
    80004fec:	892a                	mv	s2,a0
    80004fee:	c125                	beqz	a0,8000504e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004ff0:	4985                	li	s3,1
    80004ff2:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004ff6:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004ffa:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004ffe:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005002:	00003597          	auipc	a1,0x3
    80005006:	6d658593          	addi	a1,a1,1750 # 800086d8 <syscalls+0x290>
    8000500a:	ffffc097          	auipc	ra,0xffffc
    8000500e:	b4a080e7          	jalr	-1206(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80005012:	609c                	ld	a5,0(s1)
    80005014:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005018:	609c                	ld	a5,0(s1)
    8000501a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000501e:	609c                	ld	a5,0(s1)
    80005020:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005024:	609c                	ld	a5,0(s1)
    80005026:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000502a:	000a3783          	ld	a5,0(s4)
    8000502e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005032:	000a3783          	ld	a5,0(s4)
    80005036:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000503a:	000a3783          	ld	a5,0(s4)
    8000503e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005042:	000a3783          	ld	a5,0(s4)
    80005046:	0127b823          	sd	s2,16(a5)
  return 0;
    8000504a:	4501                	li	a0,0
    8000504c:	a025                	j	80005074 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000504e:	6088                	ld	a0,0(s1)
    80005050:	e501                	bnez	a0,80005058 <pipealloc+0xaa>
    80005052:	a039                	j	80005060 <pipealloc+0xb2>
    80005054:	6088                	ld	a0,0(s1)
    80005056:	c51d                	beqz	a0,80005084 <pipealloc+0xd6>
    fileclose(*f0);
    80005058:	00000097          	auipc	ra,0x0
    8000505c:	c26080e7          	jalr	-986(ra) # 80004c7e <fileclose>
  if(*f1)
    80005060:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005064:	557d                	li	a0,-1
  if(*f1)
    80005066:	c799                	beqz	a5,80005074 <pipealloc+0xc6>
    fileclose(*f1);
    80005068:	853e                	mv	a0,a5
    8000506a:	00000097          	auipc	ra,0x0
    8000506e:	c14080e7          	jalr	-1004(ra) # 80004c7e <fileclose>
  return -1;
    80005072:	557d                	li	a0,-1
}
    80005074:	70a2                	ld	ra,40(sp)
    80005076:	7402                	ld	s0,32(sp)
    80005078:	64e2                	ld	s1,24(sp)
    8000507a:	6942                	ld	s2,16(sp)
    8000507c:	69a2                	ld	s3,8(sp)
    8000507e:	6a02                	ld	s4,0(sp)
    80005080:	6145                	addi	sp,sp,48
    80005082:	8082                	ret
  return -1;
    80005084:	557d                	li	a0,-1
    80005086:	b7fd                	j	80005074 <pipealloc+0xc6>

0000000080005088 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005088:	1101                	addi	sp,sp,-32
    8000508a:	ec06                	sd	ra,24(sp)
    8000508c:	e822                	sd	s0,16(sp)
    8000508e:	e426                	sd	s1,8(sp)
    80005090:	e04a                	sd	s2,0(sp)
    80005092:	1000                	addi	s0,sp,32
    80005094:	84aa                	mv	s1,a0
    80005096:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005098:	ffffc097          	auipc	ra,0xffffc
    8000509c:	b4c080e7          	jalr	-1204(ra) # 80000be4 <acquire>
  if(writable){
    800050a0:	02090d63          	beqz	s2,800050da <pipeclose+0x52>
    pi->writeopen = 0;
    800050a4:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800050a8:	21848513          	addi	a0,s1,536
    800050ac:	ffffd097          	auipc	ra,0xffffd
    800050b0:	78e080e7          	jalr	1934(ra) # 8000283a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800050b4:	2204b783          	ld	a5,544(s1)
    800050b8:	eb95                	bnez	a5,800050ec <pipeclose+0x64>
    release(&pi->lock);
    800050ba:	8526                	mv	a0,s1
    800050bc:	ffffc097          	auipc	ra,0xffffc
    800050c0:	bdc080e7          	jalr	-1060(ra) # 80000c98 <release>
    kfree((char*)pi);
    800050c4:	8526                	mv	a0,s1
    800050c6:	ffffc097          	auipc	ra,0xffffc
    800050ca:	932080e7          	jalr	-1742(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    800050ce:	60e2                	ld	ra,24(sp)
    800050d0:	6442                	ld	s0,16(sp)
    800050d2:	64a2                	ld	s1,8(sp)
    800050d4:	6902                	ld	s2,0(sp)
    800050d6:	6105                	addi	sp,sp,32
    800050d8:	8082                	ret
    pi->readopen = 0;
    800050da:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800050de:	21c48513          	addi	a0,s1,540
    800050e2:	ffffd097          	auipc	ra,0xffffd
    800050e6:	758080e7          	jalr	1880(ra) # 8000283a <wakeup>
    800050ea:	b7e9                	j	800050b4 <pipeclose+0x2c>
    release(&pi->lock);
    800050ec:	8526                	mv	a0,s1
    800050ee:	ffffc097          	auipc	ra,0xffffc
    800050f2:	baa080e7          	jalr	-1110(ra) # 80000c98 <release>
}
    800050f6:	bfe1                	j	800050ce <pipeclose+0x46>

00000000800050f8 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800050f8:	7159                	addi	sp,sp,-112
    800050fa:	f486                	sd	ra,104(sp)
    800050fc:	f0a2                	sd	s0,96(sp)
    800050fe:	eca6                	sd	s1,88(sp)
    80005100:	e8ca                	sd	s2,80(sp)
    80005102:	e4ce                	sd	s3,72(sp)
    80005104:	e0d2                	sd	s4,64(sp)
    80005106:	fc56                	sd	s5,56(sp)
    80005108:	f85a                	sd	s6,48(sp)
    8000510a:	f45e                	sd	s7,40(sp)
    8000510c:	f062                	sd	s8,32(sp)
    8000510e:	ec66                	sd	s9,24(sp)
    80005110:	1880                	addi	s0,sp,112
    80005112:	84aa                	mv	s1,a0
    80005114:	8aae                	mv	s5,a1
    80005116:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005118:	ffffd097          	auipc	ra,0xffffd
    8000511c:	b96080e7          	jalr	-1130(ra) # 80001cae <myproc>
    80005120:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005122:	8526                	mv	a0,s1
    80005124:	ffffc097          	auipc	ra,0xffffc
    80005128:	ac0080e7          	jalr	-1344(ra) # 80000be4 <acquire>
  while(i < n){
    8000512c:	0d405163          	blez	s4,800051ee <pipewrite+0xf6>
    80005130:	8ba6                	mv	s7,s1
  int i = 0;
    80005132:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005134:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005136:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000513a:	21c48c13          	addi	s8,s1,540
    8000513e:	a08d                	j	800051a0 <pipewrite+0xa8>
      release(&pi->lock);
    80005140:	8526                	mv	a0,s1
    80005142:	ffffc097          	auipc	ra,0xffffc
    80005146:	b56080e7          	jalr	-1194(ra) # 80000c98 <release>
      return -1;
    8000514a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000514c:	854a                	mv	a0,s2
    8000514e:	70a6                	ld	ra,104(sp)
    80005150:	7406                	ld	s0,96(sp)
    80005152:	64e6                	ld	s1,88(sp)
    80005154:	6946                	ld	s2,80(sp)
    80005156:	69a6                	ld	s3,72(sp)
    80005158:	6a06                	ld	s4,64(sp)
    8000515a:	7ae2                	ld	s5,56(sp)
    8000515c:	7b42                	ld	s6,48(sp)
    8000515e:	7ba2                	ld	s7,40(sp)
    80005160:	7c02                	ld	s8,32(sp)
    80005162:	6ce2                	ld	s9,24(sp)
    80005164:	6165                	addi	sp,sp,112
    80005166:	8082                	ret
      wakeup(&pi->nread);
    80005168:	8566                	mv	a0,s9
    8000516a:	ffffd097          	auipc	ra,0xffffd
    8000516e:	6d0080e7          	jalr	1744(ra) # 8000283a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005172:	85de                	mv	a1,s7
    80005174:	8562                	mv	a0,s8
    80005176:	ffffd097          	auipc	ra,0xffffd
    8000517a:	4c8080e7          	jalr	1224(ra) # 8000263e <sleep>
    8000517e:	a839                	j	8000519c <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005180:	21c4a783          	lw	a5,540(s1)
    80005184:	0017871b          	addiw	a4,a5,1
    80005188:	20e4ae23          	sw	a4,540(s1)
    8000518c:	1ff7f793          	andi	a5,a5,511
    80005190:	97a6                	add	a5,a5,s1
    80005192:	f9f44703          	lbu	a4,-97(s0)
    80005196:	00e78c23          	sb	a4,24(a5)
      i++;
    8000519a:	2905                	addiw	s2,s2,1
  while(i < n){
    8000519c:	03495d63          	bge	s2,s4,800051d6 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    800051a0:	2204a783          	lw	a5,544(s1)
    800051a4:	dfd1                	beqz	a5,80005140 <pipewrite+0x48>
    800051a6:	0409a783          	lw	a5,64(s3)
    800051aa:	fbd9                	bnez	a5,80005140 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800051ac:	2184a783          	lw	a5,536(s1)
    800051b0:	21c4a703          	lw	a4,540(s1)
    800051b4:	2007879b          	addiw	a5,a5,512
    800051b8:	faf708e3          	beq	a4,a5,80005168 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800051bc:	4685                	li	a3,1
    800051be:	01590633          	add	a2,s2,s5
    800051c2:	f9f40593          	addi	a1,s0,-97
    800051c6:	0789b503          	ld	a0,120(s3)
    800051ca:	ffffc097          	auipc	ra,0xffffc
    800051ce:	534080e7          	jalr	1332(ra) # 800016fe <copyin>
    800051d2:	fb6517e3          	bne	a0,s6,80005180 <pipewrite+0x88>
  wakeup(&pi->nread);
    800051d6:	21848513          	addi	a0,s1,536
    800051da:	ffffd097          	auipc	ra,0xffffd
    800051de:	660080e7          	jalr	1632(ra) # 8000283a <wakeup>
  release(&pi->lock);
    800051e2:	8526                	mv	a0,s1
    800051e4:	ffffc097          	auipc	ra,0xffffc
    800051e8:	ab4080e7          	jalr	-1356(ra) # 80000c98 <release>
  return i;
    800051ec:	b785                	j	8000514c <pipewrite+0x54>
  int i = 0;
    800051ee:	4901                	li	s2,0
    800051f0:	b7dd                	j	800051d6 <pipewrite+0xde>

00000000800051f2 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800051f2:	715d                	addi	sp,sp,-80
    800051f4:	e486                	sd	ra,72(sp)
    800051f6:	e0a2                	sd	s0,64(sp)
    800051f8:	fc26                	sd	s1,56(sp)
    800051fa:	f84a                	sd	s2,48(sp)
    800051fc:	f44e                	sd	s3,40(sp)
    800051fe:	f052                	sd	s4,32(sp)
    80005200:	ec56                	sd	s5,24(sp)
    80005202:	e85a                	sd	s6,16(sp)
    80005204:	0880                	addi	s0,sp,80
    80005206:	84aa                	mv	s1,a0
    80005208:	892e                	mv	s2,a1
    8000520a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000520c:	ffffd097          	auipc	ra,0xffffd
    80005210:	aa2080e7          	jalr	-1374(ra) # 80001cae <myproc>
    80005214:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005216:	8b26                	mv	s6,s1
    80005218:	8526                	mv	a0,s1
    8000521a:	ffffc097          	auipc	ra,0xffffc
    8000521e:	9ca080e7          	jalr	-1590(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005222:	2184a703          	lw	a4,536(s1)
    80005226:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000522a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000522e:	02f71463          	bne	a4,a5,80005256 <piperead+0x64>
    80005232:	2244a783          	lw	a5,548(s1)
    80005236:	c385                	beqz	a5,80005256 <piperead+0x64>
    if(pr->killed){
    80005238:	040a2783          	lw	a5,64(s4)
    8000523c:	ebc1                	bnez	a5,800052cc <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000523e:	85da                	mv	a1,s6
    80005240:	854e                	mv	a0,s3
    80005242:	ffffd097          	auipc	ra,0xffffd
    80005246:	3fc080e7          	jalr	1020(ra) # 8000263e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000524a:	2184a703          	lw	a4,536(s1)
    8000524e:	21c4a783          	lw	a5,540(s1)
    80005252:	fef700e3          	beq	a4,a5,80005232 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005256:	09505263          	blez	s5,800052da <piperead+0xe8>
    8000525a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000525c:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    8000525e:	2184a783          	lw	a5,536(s1)
    80005262:	21c4a703          	lw	a4,540(s1)
    80005266:	02f70d63          	beq	a4,a5,800052a0 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000526a:	0017871b          	addiw	a4,a5,1
    8000526e:	20e4ac23          	sw	a4,536(s1)
    80005272:	1ff7f793          	andi	a5,a5,511
    80005276:	97a6                	add	a5,a5,s1
    80005278:	0187c783          	lbu	a5,24(a5)
    8000527c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005280:	4685                	li	a3,1
    80005282:	fbf40613          	addi	a2,s0,-65
    80005286:	85ca                	mv	a1,s2
    80005288:	078a3503          	ld	a0,120(s4)
    8000528c:	ffffc097          	auipc	ra,0xffffc
    80005290:	3e6080e7          	jalr	998(ra) # 80001672 <copyout>
    80005294:	01650663          	beq	a0,s6,800052a0 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005298:	2985                	addiw	s3,s3,1
    8000529a:	0905                	addi	s2,s2,1
    8000529c:	fd3a91e3          	bne	s5,s3,8000525e <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800052a0:	21c48513          	addi	a0,s1,540
    800052a4:	ffffd097          	auipc	ra,0xffffd
    800052a8:	596080e7          	jalr	1430(ra) # 8000283a <wakeup>
  release(&pi->lock);
    800052ac:	8526                	mv	a0,s1
    800052ae:	ffffc097          	auipc	ra,0xffffc
    800052b2:	9ea080e7          	jalr	-1558(ra) # 80000c98 <release>
  return i;
}
    800052b6:	854e                	mv	a0,s3
    800052b8:	60a6                	ld	ra,72(sp)
    800052ba:	6406                	ld	s0,64(sp)
    800052bc:	74e2                	ld	s1,56(sp)
    800052be:	7942                	ld	s2,48(sp)
    800052c0:	79a2                	ld	s3,40(sp)
    800052c2:	7a02                	ld	s4,32(sp)
    800052c4:	6ae2                	ld	s5,24(sp)
    800052c6:	6b42                	ld	s6,16(sp)
    800052c8:	6161                	addi	sp,sp,80
    800052ca:	8082                	ret
      release(&pi->lock);
    800052cc:	8526                	mv	a0,s1
    800052ce:	ffffc097          	auipc	ra,0xffffc
    800052d2:	9ca080e7          	jalr	-1590(ra) # 80000c98 <release>
      return -1;
    800052d6:	59fd                	li	s3,-1
    800052d8:	bff9                	j	800052b6 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800052da:	4981                	li	s3,0
    800052dc:	b7d1                	j	800052a0 <piperead+0xae>

00000000800052de <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800052de:	df010113          	addi	sp,sp,-528
    800052e2:	20113423          	sd	ra,520(sp)
    800052e6:	20813023          	sd	s0,512(sp)
    800052ea:	ffa6                	sd	s1,504(sp)
    800052ec:	fbca                	sd	s2,496(sp)
    800052ee:	f7ce                	sd	s3,488(sp)
    800052f0:	f3d2                	sd	s4,480(sp)
    800052f2:	efd6                	sd	s5,472(sp)
    800052f4:	ebda                	sd	s6,464(sp)
    800052f6:	e7de                	sd	s7,456(sp)
    800052f8:	e3e2                	sd	s8,448(sp)
    800052fa:	ff66                	sd	s9,440(sp)
    800052fc:	fb6a                	sd	s10,432(sp)
    800052fe:	f76e                	sd	s11,424(sp)
    80005300:	0c00                	addi	s0,sp,528
    80005302:	84aa                	mv	s1,a0
    80005304:	dea43c23          	sd	a0,-520(s0)
    80005308:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000530c:	ffffd097          	auipc	ra,0xffffd
    80005310:	9a2080e7          	jalr	-1630(ra) # 80001cae <myproc>
    80005314:	892a                	mv	s2,a0

  begin_op();
    80005316:	fffff097          	auipc	ra,0xfffff
    8000531a:	49c080e7          	jalr	1180(ra) # 800047b2 <begin_op>

  if((ip = namei(path)) == 0){
    8000531e:	8526                	mv	a0,s1
    80005320:	fffff097          	auipc	ra,0xfffff
    80005324:	276080e7          	jalr	630(ra) # 80004596 <namei>
    80005328:	c92d                	beqz	a0,8000539a <exec+0xbc>
    8000532a:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000532c:	fffff097          	auipc	ra,0xfffff
    80005330:	ab4080e7          	jalr	-1356(ra) # 80003de0 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005334:	04000713          	li	a4,64
    80005338:	4681                	li	a3,0
    8000533a:	e5040613          	addi	a2,s0,-432
    8000533e:	4581                	li	a1,0
    80005340:	8526                	mv	a0,s1
    80005342:	fffff097          	auipc	ra,0xfffff
    80005346:	d52080e7          	jalr	-686(ra) # 80004094 <readi>
    8000534a:	04000793          	li	a5,64
    8000534e:	00f51a63          	bne	a0,a5,80005362 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005352:	e5042703          	lw	a4,-432(s0)
    80005356:	464c47b7          	lui	a5,0x464c4
    8000535a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000535e:	04f70463          	beq	a4,a5,800053a6 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005362:	8526                	mv	a0,s1
    80005364:	fffff097          	auipc	ra,0xfffff
    80005368:	cde080e7          	jalr	-802(ra) # 80004042 <iunlockput>
    end_op();
    8000536c:	fffff097          	auipc	ra,0xfffff
    80005370:	4c6080e7          	jalr	1222(ra) # 80004832 <end_op>
  }
  return -1;
    80005374:	557d                	li	a0,-1
}
    80005376:	20813083          	ld	ra,520(sp)
    8000537a:	20013403          	ld	s0,512(sp)
    8000537e:	74fe                	ld	s1,504(sp)
    80005380:	795e                	ld	s2,496(sp)
    80005382:	79be                	ld	s3,488(sp)
    80005384:	7a1e                	ld	s4,480(sp)
    80005386:	6afe                	ld	s5,472(sp)
    80005388:	6b5e                	ld	s6,464(sp)
    8000538a:	6bbe                	ld	s7,456(sp)
    8000538c:	6c1e                	ld	s8,448(sp)
    8000538e:	7cfa                	ld	s9,440(sp)
    80005390:	7d5a                	ld	s10,432(sp)
    80005392:	7dba                	ld	s11,424(sp)
    80005394:	21010113          	addi	sp,sp,528
    80005398:	8082                	ret
    end_op();
    8000539a:	fffff097          	auipc	ra,0xfffff
    8000539e:	498080e7          	jalr	1176(ra) # 80004832 <end_op>
    return -1;
    800053a2:	557d                	li	a0,-1
    800053a4:	bfc9                	j	80005376 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800053a6:	854a                	mv	a0,s2
    800053a8:	ffffd097          	auipc	ra,0xffffd
    800053ac:	9cc080e7          	jalr	-1588(ra) # 80001d74 <proc_pagetable>
    800053b0:	8baa                	mv	s7,a0
    800053b2:	d945                	beqz	a0,80005362 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053b4:	e7042983          	lw	s3,-400(s0)
    800053b8:	e8845783          	lhu	a5,-376(s0)
    800053bc:	c7ad                	beqz	a5,80005426 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800053be:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053c0:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800053c2:	6c85                	lui	s9,0x1
    800053c4:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800053c8:	def43823          	sd	a5,-528(s0)
    800053cc:	a42d                	j	800055f6 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800053ce:	00003517          	auipc	a0,0x3
    800053d2:	31250513          	addi	a0,a0,786 # 800086e0 <syscalls+0x298>
    800053d6:	ffffb097          	auipc	ra,0xffffb
    800053da:	168080e7          	jalr	360(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800053de:	8756                	mv	a4,s5
    800053e0:	012d86bb          	addw	a3,s11,s2
    800053e4:	4581                	li	a1,0
    800053e6:	8526                	mv	a0,s1
    800053e8:	fffff097          	auipc	ra,0xfffff
    800053ec:	cac080e7          	jalr	-852(ra) # 80004094 <readi>
    800053f0:	2501                	sext.w	a0,a0
    800053f2:	1aaa9963          	bne	s5,a0,800055a4 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    800053f6:	6785                	lui	a5,0x1
    800053f8:	0127893b          	addw	s2,a5,s2
    800053fc:	77fd                	lui	a5,0xfffff
    800053fe:	01478a3b          	addw	s4,a5,s4
    80005402:	1f897163          	bgeu	s2,s8,800055e4 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80005406:	02091593          	slli	a1,s2,0x20
    8000540a:	9181                	srli	a1,a1,0x20
    8000540c:	95ea                	add	a1,a1,s10
    8000540e:	855e                	mv	a0,s7
    80005410:	ffffc097          	auipc	ra,0xffffc
    80005414:	c5e080e7          	jalr	-930(ra) # 8000106e <walkaddr>
    80005418:	862a                	mv	a2,a0
    if(pa == 0)
    8000541a:	d955                	beqz	a0,800053ce <exec+0xf0>
      n = PGSIZE;
    8000541c:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    8000541e:	fd9a70e3          	bgeu	s4,s9,800053de <exec+0x100>
      n = sz - i;
    80005422:	8ad2                	mv	s5,s4
    80005424:	bf6d                	j	800053de <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005426:	4901                	li	s2,0
  iunlockput(ip);
    80005428:	8526                	mv	a0,s1
    8000542a:	fffff097          	auipc	ra,0xfffff
    8000542e:	c18080e7          	jalr	-1000(ra) # 80004042 <iunlockput>
  end_op();
    80005432:	fffff097          	auipc	ra,0xfffff
    80005436:	400080e7          	jalr	1024(ra) # 80004832 <end_op>
  p = myproc();
    8000543a:	ffffd097          	auipc	ra,0xffffd
    8000543e:	874080e7          	jalr	-1932(ra) # 80001cae <myproc>
    80005442:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005444:	07053d03          	ld	s10,112(a0)
  sz = PGROUNDUP(sz);
    80005448:	6785                	lui	a5,0x1
    8000544a:	17fd                	addi	a5,a5,-1
    8000544c:	993e                	add	s2,s2,a5
    8000544e:	757d                	lui	a0,0xfffff
    80005450:	00a977b3          	and	a5,s2,a0
    80005454:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005458:	6609                	lui	a2,0x2
    8000545a:	963e                	add	a2,a2,a5
    8000545c:	85be                	mv	a1,a5
    8000545e:	855e                	mv	a0,s7
    80005460:	ffffc097          	auipc	ra,0xffffc
    80005464:	fc2080e7          	jalr	-62(ra) # 80001422 <uvmalloc>
    80005468:	8b2a                	mv	s6,a0
  ip = 0;
    8000546a:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000546c:	12050c63          	beqz	a0,800055a4 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005470:	75f9                	lui	a1,0xffffe
    80005472:	95aa                	add	a1,a1,a0
    80005474:	855e                	mv	a0,s7
    80005476:	ffffc097          	auipc	ra,0xffffc
    8000547a:	1ca080e7          	jalr	458(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    8000547e:	7c7d                	lui	s8,0xfffff
    80005480:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005482:	e0043783          	ld	a5,-512(s0)
    80005486:	6388                	ld	a0,0(a5)
    80005488:	c535                	beqz	a0,800054f4 <exec+0x216>
    8000548a:	e9040993          	addi	s3,s0,-368
    8000548e:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005492:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005494:	ffffc097          	auipc	ra,0xffffc
    80005498:	9d0080e7          	jalr	-1584(ra) # 80000e64 <strlen>
    8000549c:	2505                	addiw	a0,a0,1
    8000549e:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800054a2:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800054a6:	13896363          	bltu	s2,s8,800055cc <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800054aa:	e0043d83          	ld	s11,-512(s0)
    800054ae:	000dba03          	ld	s4,0(s11)
    800054b2:	8552                	mv	a0,s4
    800054b4:	ffffc097          	auipc	ra,0xffffc
    800054b8:	9b0080e7          	jalr	-1616(ra) # 80000e64 <strlen>
    800054bc:	0015069b          	addiw	a3,a0,1
    800054c0:	8652                	mv	a2,s4
    800054c2:	85ca                	mv	a1,s2
    800054c4:	855e                	mv	a0,s7
    800054c6:	ffffc097          	auipc	ra,0xffffc
    800054ca:	1ac080e7          	jalr	428(ra) # 80001672 <copyout>
    800054ce:	10054363          	bltz	a0,800055d4 <exec+0x2f6>
    ustack[argc] = sp;
    800054d2:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800054d6:	0485                	addi	s1,s1,1
    800054d8:	008d8793          	addi	a5,s11,8
    800054dc:	e0f43023          	sd	a5,-512(s0)
    800054e0:	008db503          	ld	a0,8(s11)
    800054e4:	c911                	beqz	a0,800054f8 <exec+0x21a>
    if(argc >= MAXARG)
    800054e6:	09a1                	addi	s3,s3,8
    800054e8:	fb3c96e3          	bne	s9,s3,80005494 <exec+0x1b6>
  sz = sz1;
    800054ec:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800054f0:	4481                	li	s1,0
    800054f2:	a84d                	j	800055a4 <exec+0x2c6>
  sp = sz;
    800054f4:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800054f6:	4481                	li	s1,0
  ustack[argc] = 0;
    800054f8:	00349793          	slli	a5,s1,0x3
    800054fc:	f9040713          	addi	a4,s0,-112
    80005500:	97ba                	add	a5,a5,a4
    80005502:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005506:	00148693          	addi	a3,s1,1
    8000550a:	068e                	slli	a3,a3,0x3
    8000550c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005510:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005514:	01897663          	bgeu	s2,s8,80005520 <exec+0x242>
  sz = sz1;
    80005518:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000551c:	4481                	li	s1,0
    8000551e:	a059                	j	800055a4 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005520:	e9040613          	addi	a2,s0,-368
    80005524:	85ca                	mv	a1,s2
    80005526:	855e                	mv	a0,s7
    80005528:	ffffc097          	auipc	ra,0xffffc
    8000552c:	14a080e7          	jalr	330(ra) # 80001672 <copyout>
    80005530:	0a054663          	bltz	a0,800055dc <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005534:	080ab783          	ld	a5,128(s5)
    80005538:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000553c:	df843783          	ld	a5,-520(s0)
    80005540:	0007c703          	lbu	a4,0(a5)
    80005544:	cf11                	beqz	a4,80005560 <exec+0x282>
    80005546:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005548:	02f00693          	li	a3,47
    8000554c:	a039                	j	8000555a <exec+0x27c>
      last = s+1;
    8000554e:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005552:	0785                	addi	a5,a5,1
    80005554:	fff7c703          	lbu	a4,-1(a5)
    80005558:	c701                	beqz	a4,80005560 <exec+0x282>
    if(*s == '/')
    8000555a:	fed71ce3          	bne	a4,a3,80005552 <exec+0x274>
    8000555e:	bfc5                	j	8000554e <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005560:	4641                	li	a2,16
    80005562:	df843583          	ld	a1,-520(s0)
    80005566:	180a8513          	addi	a0,s5,384
    8000556a:	ffffc097          	auipc	ra,0xffffc
    8000556e:	8c8080e7          	jalr	-1848(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005572:	078ab503          	ld	a0,120(s5)
  p->pagetable = pagetable;
    80005576:	077abc23          	sd	s7,120(s5)
  p->sz = sz;
    8000557a:	076ab823          	sd	s6,112(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000557e:	080ab783          	ld	a5,128(s5)
    80005582:	e6843703          	ld	a4,-408(s0)
    80005586:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005588:	080ab783          	ld	a5,128(s5)
    8000558c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005590:	85ea                	mv	a1,s10
    80005592:	ffffd097          	auipc	ra,0xffffd
    80005596:	87e080e7          	jalr	-1922(ra) # 80001e10 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000559a:	0004851b          	sext.w	a0,s1
    8000559e:	bbe1                	j	80005376 <exec+0x98>
    800055a0:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800055a4:	e0843583          	ld	a1,-504(s0)
    800055a8:	855e                	mv	a0,s7
    800055aa:	ffffd097          	auipc	ra,0xffffd
    800055ae:	866080e7          	jalr	-1946(ra) # 80001e10 <proc_freepagetable>
  if(ip){
    800055b2:	da0498e3          	bnez	s1,80005362 <exec+0x84>
  return -1;
    800055b6:	557d                	li	a0,-1
    800055b8:	bb7d                	j	80005376 <exec+0x98>
    800055ba:	e1243423          	sd	s2,-504(s0)
    800055be:	b7dd                	j	800055a4 <exec+0x2c6>
    800055c0:	e1243423          	sd	s2,-504(s0)
    800055c4:	b7c5                	j	800055a4 <exec+0x2c6>
    800055c6:	e1243423          	sd	s2,-504(s0)
    800055ca:	bfe9                	j	800055a4 <exec+0x2c6>
  sz = sz1;
    800055cc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800055d0:	4481                	li	s1,0
    800055d2:	bfc9                	j	800055a4 <exec+0x2c6>
  sz = sz1;
    800055d4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800055d8:	4481                	li	s1,0
    800055da:	b7e9                	j	800055a4 <exec+0x2c6>
  sz = sz1;
    800055dc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800055e0:	4481                	li	s1,0
    800055e2:	b7c9                	j	800055a4 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800055e4:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800055e8:	2b05                	addiw	s6,s6,1
    800055ea:	0389899b          	addiw	s3,s3,56
    800055ee:	e8845783          	lhu	a5,-376(s0)
    800055f2:	e2fb5be3          	bge	s6,a5,80005428 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800055f6:	2981                	sext.w	s3,s3
    800055f8:	03800713          	li	a4,56
    800055fc:	86ce                	mv	a3,s3
    800055fe:	e1840613          	addi	a2,s0,-488
    80005602:	4581                	li	a1,0
    80005604:	8526                	mv	a0,s1
    80005606:	fffff097          	auipc	ra,0xfffff
    8000560a:	a8e080e7          	jalr	-1394(ra) # 80004094 <readi>
    8000560e:	03800793          	li	a5,56
    80005612:	f8f517e3          	bne	a0,a5,800055a0 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005616:	e1842783          	lw	a5,-488(s0)
    8000561a:	4705                	li	a4,1
    8000561c:	fce796e3          	bne	a5,a4,800055e8 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005620:	e4043603          	ld	a2,-448(s0)
    80005624:	e3843783          	ld	a5,-456(s0)
    80005628:	f8f669e3          	bltu	a2,a5,800055ba <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000562c:	e2843783          	ld	a5,-472(s0)
    80005630:	963e                	add	a2,a2,a5
    80005632:	f8f667e3          	bltu	a2,a5,800055c0 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005636:	85ca                	mv	a1,s2
    80005638:	855e                	mv	a0,s7
    8000563a:	ffffc097          	auipc	ra,0xffffc
    8000563e:	de8080e7          	jalr	-536(ra) # 80001422 <uvmalloc>
    80005642:	e0a43423          	sd	a0,-504(s0)
    80005646:	d141                	beqz	a0,800055c6 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005648:	e2843d03          	ld	s10,-472(s0)
    8000564c:	df043783          	ld	a5,-528(s0)
    80005650:	00fd77b3          	and	a5,s10,a5
    80005654:	fba1                	bnez	a5,800055a4 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005656:	e2042d83          	lw	s11,-480(s0)
    8000565a:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000565e:	f80c03e3          	beqz	s8,800055e4 <exec+0x306>
    80005662:	8a62                	mv	s4,s8
    80005664:	4901                	li	s2,0
    80005666:	b345                	j	80005406 <exec+0x128>

0000000080005668 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005668:	7179                	addi	sp,sp,-48
    8000566a:	f406                	sd	ra,40(sp)
    8000566c:	f022                	sd	s0,32(sp)
    8000566e:	ec26                	sd	s1,24(sp)
    80005670:	e84a                	sd	s2,16(sp)
    80005672:	1800                	addi	s0,sp,48
    80005674:	892e                	mv	s2,a1
    80005676:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005678:	fdc40593          	addi	a1,s0,-36
    8000567c:	ffffe097          	auipc	ra,0xffffe
    80005680:	b76080e7          	jalr	-1162(ra) # 800031f2 <argint>
    80005684:	04054063          	bltz	a0,800056c4 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005688:	fdc42703          	lw	a4,-36(s0)
    8000568c:	47bd                	li	a5,15
    8000568e:	02e7ed63          	bltu	a5,a4,800056c8 <argfd+0x60>
    80005692:	ffffc097          	auipc	ra,0xffffc
    80005696:	61c080e7          	jalr	1564(ra) # 80001cae <myproc>
    8000569a:	fdc42703          	lw	a4,-36(s0)
    8000569e:	01e70793          	addi	a5,a4,30
    800056a2:	078e                	slli	a5,a5,0x3
    800056a4:	953e                	add	a0,a0,a5
    800056a6:	651c                	ld	a5,8(a0)
    800056a8:	c395                	beqz	a5,800056cc <argfd+0x64>
    return -1;
  if(pfd)
    800056aa:	00090463          	beqz	s2,800056b2 <argfd+0x4a>
    *pfd = fd;
    800056ae:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800056b2:	4501                	li	a0,0
  if(pf)
    800056b4:	c091                	beqz	s1,800056b8 <argfd+0x50>
    *pf = f;
    800056b6:	e09c                	sd	a5,0(s1)
}
    800056b8:	70a2                	ld	ra,40(sp)
    800056ba:	7402                	ld	s0,32(sp)
    800056bc:	64e2                	ld	s1,24(sp)
    800056be:	6942                	ld	s2,16(sp)
    800056c0:	6145                	addi	sp,sp,48
    800056c2:	8082                	ret
    return -1;
    800056c4:	557d                	li	a0,-1
    800056c6:	bfcd                	j	800056b8 <argfd+0x50>
    return -1;
    800056c8:	557d                	li	a0,-1
    800056ca:	b7fd                	j	800056b8 <argfd+0x50>
    800056cc:	557d                	li	a0,-1
    800056ce:	b7ed                	j	800056b8 <argfd+0x50>

00000000800056d0 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800056d0:	1101                	addi	sp,sp,-32
    800056d2:	ec06                	sd	ra,24(sp)
    800056d4:	e822                	sd	s0,16(sp)
    800056d6:	e426                	sd	s1,8(sp)
    800056d8:	1000                	addi	s0,sp,32
    800056da:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800056dc:	ffffc097          	auipc	ra,0xffffc
    800056e0:	5d2080e7          	jalr	1490(ra) # 80001cae <myproc>
    800056e4:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800056e6:	0f850793          	addi	a5,a0,248 # fffffffffffff0f8 <end+0xffffffff7ffd90f8>
    800056ea:	4501                	li	a0,0
    800056ec:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800056ee:	6398                	ld	a4,0(a5)
    800056f0:	cb19                	beqz	a4,80005706 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800056f2:	2505                	addiw	a0,a0,1
    800056f4:	07a1                	addi	a5,a5,8
    800056f6:	fed51ce3          	bne	a0,a3,800056ee <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800056fa:	557d                	li	a0,-1
}
    800056fc:	60e2                	ld	ra,24(sp)
    800056fe:	6442                	ld	s0,16(sp)
    80005700:	64a2                	ld	s1,8(sp)
    80005702:	6105                	addi	sp,sp,32
    80005704:	8082                	ret
      p->ofile[fd] = f;
    80005706:	01e50793          	addi	a5,a0,30
    8000570a:	078e                	slli	a5,a5,0x3
    8000570c:	963e                	add	a2,a2,a5
    8000570e:	e604                	sd	s1,8(a2)
      return fd;
    80005710:	b7f5                	j	800056fc <fdalloc+0x2c>

0000000080005712 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005712:	715d                	addi	sp,sp,-80
    80005714:	e486                	sd	ra,72(sp)
    80005716:	e0a2                	sd	s0,64(sp)
    80005718:	fc26                	sd	s1,56(sp)
    8000571a:	f84a                	sd	s2,48(sp)
    8000571c:	f44e                	sd	s3,40(sp)
    8000571e:	f052                	sd	s4,32(sp)
    80005720:	ec56                	sd	s5,24(sp)
    80005722:	0880                	addi	s0,sp,80
    80005724:	89ae                	mv	s3,a1
    80005726:	8ab2                	mv	s5,a2
    80005728:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000572a:	fb040593          	addi	a1,s0,-80
    8000572e:	fffff097          	auipc	ra,0xfffff
    80005732:	e86080e7          	jalr	-378(ra) # 800045b4 <nameiparent>
    80005736:	892a                	mv	s2,a0
    80005738:	12050f63          	beqz	a0,80005876 <create+0x164>
    return 0;

  ilock(dp);
    8000573c:	ffffe097          	auipc	ra,0xffffe
    80005740:	6a4080e7          	jalr	1700(ra) # 80003de0 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005744:	4601                	li	a2,0
    80005746:	fb040593          	addi	a1,s0,-80
    8000574a:	854a                	mv	a0,s2
    8000574c:	fffff097          	auipc	ra,0xfffff
    80005750:	b78080e7          	jalr	-1160(ra) # 800042c4 <dirlookup>
    80005754:	84aa                	mv	s1,a0
    80005756:	c921                	beqz	a0,800057a6 <create+0x94>
    iunlockput(dp);
    80005758:	854a                	mv	a0,s2
    8000575a:	fffff097          	auipc	ra,0xfffff
    8000575e:	8e8080e7          	jalr	-1816(ra) # 80004042 <iunlockput>
    ilock(ip);
    80005762:	8526                	mv	a0,s1
    80005764:	ffffe097          	auipc	ra,0xffffe
    80005768:	67c080e7          	jalr	1660(ra) # 80003de0 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000576c:	2981                	sext.w	s3,s3
    8000576e:	4789                	li	a5,2
    80005770:	02f99463          	bne	s3,a5,80005798 <create+0x86>
    80005774:	0444d783          	lhu	a5,68(s1)
    80005778:	37f9                	addiw	a5,a5,-2
    8000577a:	17c2                	slli	a5,a5,0x30
    8000577c:	93c1                	srli	a5,a5,0x30
    8000577e:	4705                	li	a4,1
    80005780:	00f76c63          	bltu	a4,a5,80005798 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005784:	8526                	mv	a0,s1
    80005786:	60a6                	ld	ra,72(sp)
    80005788:	6406                	ld	s0,64(sp)
    8000578a:	74e2                	ld	s1,56(sp)
    8000578c:	7942                	ld	s2,48(sp)
    8000578e:	79a2                	ld	s3,40(sp)
    80005790:	7a02                	ld	s4,32(sp)
    80005792:	6ae2                	ld	s5,24(sp)
    80005794:	6161                	addi	sp,sp,80
    80005796:	8082                	ret
    iunlockput(ip);
    80005798:	8526                	mv	a0,s1
    8000579a:	fffff097          	auipc	ra,0xfffff
    8000579e:	8a8080e7          	jalr	-1880(ra) # 80004042 <iunlockput>
    return 0;
    800057a2:	4481                	li	s1,0
    800057a4:	b7c5                	j	80005784 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800057a6:	85ce                	mv	a1,s3
    800057a8:	00092503          	lw	a0,0(s2)
    800057ac:	ffffe097          	auipc	ra,0xffffe
    800057b0:	49c080e7          	jalr	1180(ra) # 80003c48 <ialloc>
    800057b4:	84aa                	mv	s1,a0
    800057b6:	c529                	beqz	a0,80005800 <create+0xee>
  ilock(ip);
    800057b8:	ffffe097          	auipc	ra,0xffffe
    800057bc:	628080e7          	jalr	1576(ra) # 80003de0 <ilock>
  ip->major = major;
    800057c0:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800057c4:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800057c8:	4785                	li	a5,1
    800057ca:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800057ce:	8526                	mv	a0,s1
    800057d0:	ffffe097          	auipc	ra,0xffffe
    800057d4:	546080e7          	jalr	1350(ra) # 80003d16 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800057d8:	2981                	sext.w	s3,s3
    800057da:	4785                	li	a5,1
    800057dc:	02f98a63          	beq	s3,a5,80005810 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800057e0:	40d0                	lw	a2,4(s1)
    800057e2:	fb040593          	addi	a1,s0,-80
    800057e6:	854a                	mv	a0,s2
    800057e8:	fffff097          	auipc	ra,0xfffff
    800057ec:	cec080e7          	jalr	-788(ra) # 800044d4 <dirlink>
    800057f0:	06054b63          	bltz	a0,80005866 <create+0x154>
  iunlockput(dp);
    800057f4:	854a                	mv	a0,s2
    800057f6:	fffff097          	auipc	ra,0xfffff
    800057fa:	84c080e7          	jalr	-1972(ra) # 80004042 <iunlockput>
  return ip;
    800057fe:	b759                	j	80005784 <create+0x72>
    panic("create: ialloc");
    80005800:	00003517          	auipc	a0,0x3
    80005804:	f0050513          	addi	a0,a0,-256 # 80008700 <syscalls+0x2b8>
    80005808:	ffffb097          	auipc	ra,0xffffb
    8000580c:	d36080e7          	jalr	-714(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005810:	04a95783          	lhu	a5,74(s2)
    80005814:	2785                	addiw	a5,a5,1
    80005816:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000581a:	854a                	mv	a0,s2
    8000581c:	ffffe097          	auipc	ra,0xffffe
    80005820:	4fa080e7          	jalr	1274(ra) # 80003d16 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005824:	40d0                	lw	a2,4(s1)
    80005826:	00003597          	auipc	a1,0x3
    8000582a:	eea58593          	addi	a1,a1,-278 # 80008710 <syscalls+0x2c8>
    8000582e:	8526                	mv	a0,s1
    80005830:	fffff097          	auipc	ra,0xfffff
    80005834:	ca4080e7          	jalr	-860(ra) # 800044d4 <dirlink>
    80005838:	00054f63          	bltz	a0,80005856 <create+0x144>
    8000583c:	00492603          	lw	a2,4(s2)
    80005840:	00003597          	auipc	a1,0x3
    80005844:	ed858593          	addi	a1,a1,-296 # 80008718 <syscalls+0x2d0>
    80005848:	8526                	mv	a0,s1
    8000584a:	fffff097          	auipc	ra,0xfffff
    8000584e:	c8a080e7          	jalr	-886(ra) # 800044d4 <dirlink>
    80005852:	f80557e3          	bgez	a0,800057e0 <create+0xce>
      panic("create dots");
    80005856:	00003517          	auipc	a0,0x3
    8000585a:	eca50513          	addi	a0,a0,-310 # 80008720 <syscalls+0x2d8>
    8000585e:	ffffb097          	auipc	ra,0xffffb
    80005862:	ce0080e7          	jalr	-800(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005866:	00003517          	auipc	a0,0x3
    8000586a:	eca50513          	addi	a0,a0,-310 # 80008730 <syscalls+0x2e8>
    8000586e:	ffffb097          	auipc	ra,0xffffb
    80005872:	cd0080e7          	jalr	-816(ra) # 8000053e <panic>
    return 0;
    80005876:	84aa                	mv	s1,a0
    80005878:	b731                	j	80005784 <create+0x72>

000000008000587a <sys_dup>:
{
    8000587a:	7179                	addi	sp,sp,-48
    8000587c:	f406                	sd	ra,40(sp)
    8000587e:	f022                	sd	s0,32(sp)
    80005880:	ec26                	sd	s1,24(sp)
    80005882:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005884:	fd840613          	addi	a2,s0,-40
    80005888:	4581                	li	a1,0
    8000588a:	4501                	li	a0,0
    8000588c:	00000097          	auipc	ra,0x0
    80005890:	ddc080e7          	jalr	-548(ra) # 80005668 <argfd>
    return -1;
    80005894:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005896:	02054363          	bltz	a0,800058bc <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000589a:	fd843503          	ld	a0,-40(s0)
    8000589e:	00000097          	auipc	ra,0x0
    800058a2:	e32080e7          	jalr	-462(ra) # 800056d0 <fdalloc>
    800058a6:	84aa                	mv	s1,a0
    return -1;
    800058a8:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800058aa:	00054963          	bltz	a0,800058bc <sys_dup+0x42>
  filedup(f);
    800058ae:	fd843503          	ld	a0,-40(s0)
    800058b2:	fffff097          	auipc	ra,0xfffff
    800058b6:	37a080e7          	jalr	890(ra) # 80004c2c <filedup>
  return fd;
    800058ba:	87a6                	mv	a5,s1
}
    800058bc:	853e                	mv	a0,a5
    800058be:	70a2                	ld	ra,40(sp)
    800058c0:	7402                	ld	s0,32(sp)
    800058c2:	64e2                	ld	s1,24(sp)
    800058c4:	6145                	addi	sp,sp,48
    800058c6:	8082                	ret

00000000800058c8 <sys_read>:
{
    800058c8:	7179                	addi	sp,sp,-48
    800058ca:	f406                	sd	ra,40(sp)
    800058cc:	f022                	sd	s0,32(sp)
    800058ce:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058d0:	fe840613          	addi	a2,s0,-24
    800058d4:	4581                	li	a1,0
    800058d6:	4501                	li	a0,0
    800058d8:	00000097          	auipc	ra,0x0
    800058dc:	d90080e7          	jalr	-624(ra) # 80005668 <argfd>
    return -1;
    800058e0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058e2:	04054163          	bltz	a0,80005924 <sys_read+0x5c>
    800058e6:	fe440593          	addi	a1,s0,-28
    800058ea:	4509                	li	a0,2
    800058ec:	ffffe097          	auipc	ra,0xffffe
    800058f0:	906080e7          	jalr	-1786(ra) # 800031f2 <argint>
    return -1;
    800058f4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058f6:	02054763          	bltz	a0,80005924 <sys_read+0x5c>
    800058fa:	fd840593          	addi	a1,s0,-40
    800058fe:	4505                	li	a0,1
    80005900:	ffffe097          	auipc	ra,0xffffe
    80005904:	914080e7          	jalr	-1772(ra) # 80003214 <argaddr>
    return -1;
    80005908:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000590a:	00054d63          	bltz	a0,80005924 <sys_read+0x5c>
  return fileread(f, p, n);
    8000590e:	fe442603          	lw	a2,-28(s0)
    80005912:	fd843583          	ld	a1,-40(s0)
    80005916:	fe843503          	ld	a0,-24(s0)
    8000591a:	fffff097          	auipc	ra,0xfffff
    8000591e:	49e080e7          	jalr	1182(ra) # 80004db8 <fileread>
    80005922:	87aa                	mv	a5,a0
}
    80005924:	853e                	mv	a0,a5
    80005926:	70a2                	ld	ra,40(sp)
    80005928:	7402                	ld	s0,32(sp)
    8000592a:	6145                	addi	sp,sp,48
    8000592c:	8082                	ret

000000008000592e <sys_write>:
{
    8000592e:	7179                	addi	sp,sp,-48
    80005930:	f406                	sd	ra,40(sp)
    80005932:	f022                	sd	s0,32(sp)
    80005934:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005936:	fe840613          	addi	a2,s0,-24
    8000593a:	4581                	li	a1,0
    8000593c:	4501                	li	a0,0
    8000593e:	00000097          	auipc	ra,0x0
    80005942:	d2a080e7          	jalr	-726(ra) # 80005668 <argfd>
    return -1;
    80005946:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005948:	04054163          	bltz	a0,8000598a <sys_write+0x5c>
    8000594c:	fe440593          	addi	a1,s0,-28
    80005950:	4509                	li	a0,2
    80005952:	ffffe097          	auipc	ra,0xffffe
    80005956:	8a0080e7          	jalr	-1888(ra) # 800031f2 <argint>
    return -1;
    8000595a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000595c:	02054763          	bltz	a0,8000598a <sys_write+0x5c>
    80005960:	fd840593          	addi	a1,s0,-40
    80005964:	4505                	li	a0,1
    80005966:	ffffe097          	auipc	ra,0xffffe
    8000596a:	8ae080e7          	jalr	-1874(ra) # 80003214 <argaddr>
    return -1;
    8000596e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005970:	00054d63          	bltz	a0,8000598a <sys_write+0x5c>
  return filewrite(f, p, n);
    80005974:	fe442603          	lw	a2,-28(s0)
    80005978:	fd843583          	ld	a1,-40(s0)
    8000597c:	fe843503          	ld	a0,-24(s0)
    80005980:	fffff097          	auipc	ra,0xfffff
    80005984:	4fa080e7          	jalr	1274(ra) # 80004e7a <filewrite>
    80005988:	87aa                	mv	a5,a0
}
    8000598a:	853e                	mv	a0,a5
    8000598c:	70a2                	ld	ra,40(sp)
    8000598e:	7402                	ld	s0,32(sp)
    80005990:	6145                	addi	sp,sp,48
    80005992:	8082                	ret

0000000080005994 <sys_close>:
{
    80005994:	1101                	addi	sp,sp,-32
    80005996:	ec06                	sd	ra,24(sp)
    80005998:	e822                	sd	s0,16(sp)
    8000599a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000599c:	fe040613          	addi	a2,s0,-32
    800059a0:	fec40593          	addi	a1,s0,-20
    800059a4:	4501                	li	a0,0
    800059a6:	00000097          	auipc	ra,0x0
    800059aa:	cc2080e7          	jalr	-830(ra) # 80005668 <argfd>
    return -1;
    800059ae:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800059b0:	02054463          	bltz	a0,800059d8 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800059b4:	ffffc097          	auipc	ra,0xffffc
    800059b8:	2fa080e7          	jalr	762(ra) # 80001cae <myproc>
    800059bc:	fec42783          	lw	a5,-20(s0)
    800059c0:	07f9                	addi	a5,a5,30
    800059c2:	078e                	slli	a5,a5,0x3
    800059c4:	97aa                	add	a5,a5,a0
    800059c6:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    800059ca:	fe043503          	ld	a0,-32(s0)
    800059ce:	fffff097          	auipc	ra,0xfffff
    800059d2:	2b0080e7          	jalr	688(ra) # 80004c7e <fileclose>
  return 0;
    800059d6:	4781                	li	a5,0
}
    800059d8:	853e                	mv	a0,a5
    800059da:	60e2                	ld	ra,24(sp)
    800059dc:	6442                	ld	s0,16(sp)
    800059de:	6105                	addi	sp,sp,32
    800059e0:	8082                	ret

00000000800059e2 <sys_fstat>:
{
    800059e2:	1101                	addi	sp,sp,-32
    800059e4:	ec06                	sd	ra,24(sp)
    800059e6:	e822                	sd	s0,16(sp)
    800059e8:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800059ea:	fe840613          	addi	a2,s0,-24
    800059ee:	4581                	li	a1,0
    800059f0:	4501                	li	a0,0
    800059f2:	00000097          	auipc	ra,0x0
    800059f6:	c76080e7          	jalr	-906(ra) # 80005668 <argfd>
    return -1;
    800059fa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800059fc:	02054563          	bltz	a0,80005a26 <sys_fstat+0x44>
    80005a00:	fe040593          	addi	a1,s0,-32
    80005a04:	4505                	li	a0,1
    80005a06:	ffffe097          	auipc	ra,0xffffe
    80005a0a:	80e080e7          	jalr	-2034(ra) # 80003214 <argaddr>
    return -1;
    80005a0e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a10:	00054b63          	bltz	a0,80005a26 <sys_fstat+0x44>
  return filestat(f, st);
    80005a14:	fe043583          	ld	a1,-32(s0)
    80005a18:	fe843503          	ld	a0,-24(s0)
    80005a1c:	fffff097          	auipc	ra,0xfffff
    80005a20:	32a080e7          	jalr	810(ra) # 80004d46 <filestat>
    80005a24:	87aa                	mv	a5,a0
}
    80005a26:	853e                	mv	a0,a5
    80005a28:	60e2                	ld	ra,24(sp)
    80005a2a:	6442                	ld	s0,16(sp)
    80005a2c:	6105                	addi	sp,sp,32
    80005a2e:	8082                	ret

0000000080005a30 <sys_link>:
{
    80005a30:	7169                	addi	sp,sp,-304
    80005a32:	f606                	sd	ra,296(sp)
    80005a34:	f222                	sd	s0,288(sp)
    80005a36:	ee26                	sd	s1,280(sp)
    80005a38:	ea4a                	sd	s2,272(sp)
    80005a3a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a3c:	08000613          	li	a2,128
    80005a40:	ed040593          	addi	a1,s0,-304
    80005a44:	4501                	li	a0,0
    80005a46:	ffffd097          	auipc	ra,0xffffd
    80005a4a:	7f0080e7          	jalr	2032(ra) # 80003236 <argstr>
    return -1;
    80005a4e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a50:	10054e63          	bltz	a0,80005b6c <sys_link+0x13c>
    80005a54:	08000613          	li	a2,128
    80005a58:	f5040593          	addi	a1,s0,-176
    80005a5c:	4505                	li	a0,1
    80005a5e:	ffffd097          	auipc	ra,0xffffd
    80005a62:	7d8080e7          	jalr	2008(ra) # 80003236 <argstr>
    return -1;
    80005a66:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a68:	10054263          	bltz	a0,80005b6c <sys_link+0x13c>
  begin_op();
    80005a6c:	fffff097          	auipc	ra,0xfffff
    80005a70:	d46080e7          	jalr	-698(ra) # 800047b2 <begin_op>
  if((ip = namei(old)) == 0){
    80005a74:	ed040513          	addi	a0,s0,-304
    80005a78:	fffff097          	auipc	ra,0xfffff
    80005a7c:	b1e080e7          	jalr	-1250(ra) # 80004596 <namei>
    80005a80:	84aa                	mv	s1,a0
    80005a82:	c551                	beqz	a0,80005b0e <sys_link+0xde>
  ilock(ip);
    80005a84:	ffffe097          	auipc	ra,0xffffe
    80005a88:	35c080e7          	jalr	860(ra) # 80003de0 <ilock>
  if(ip->type == T_DIR){
    80005a8c:	04449703          	lh	a4,68(s1)
    80005a90:	4785                	li	a5,1
    80005a92:	08f70463          	beq	a4,a5,80005b1a <sys_link+0xea>
  ip->nlink++;
    80005a96:	04a4d783          	lhu	a5,74(s1)
    80005a9a:	2785                	addiw	a5,a5,1
    80005a9c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005aa0:	8526                	mv	a0,s1
    80005aa2:	ffffe097          	auipc	ra,0xffffe
    80005aa6:	274080e7          	jalr	628(ra) # 80003d16 <iupdate>
  iunlock(ip);
    80005aaa:	8526                	mv	a0,s1
    80005aac:	ffffe097          	auipc	ra,0xffffe
    80005ab0:	3f6080e7          	jalr	1014(ra) # 80003ea2 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005ab4:	fd040593          	addi	a1,s0,-48
    80005ab8:	f5040513          	addi	a0,s0,-176
    80005abc:	fffff097          	auipc	ra,0xfffff
    80005ac0:	af8080e7          	jalr	-1288(ra) # 800045b4 <nameiparent>
    80005ac4:	892a                	mv	s2,a0
    80005ac6:	c935                	beqz	a0,80005b3a <sys_link+0x10a>
  ilock(dp);
    80005ac8:	ffffe097          	auipc	ra,0xffffe
    80005acc:	318080e7          	jalr	792(ra) # 80003de0 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005ad0:	00092703          	lw	a4,0(s2)
    80005ad4:	409c                	lw	a5,0(s1)
    80005ad6:	04f71d63          	bne	a4,a5,80005b30 <sys_link+0x100>
    80005ada:	40d0                	lw	a2,4(s1)
    80005adc:	fd040593          	addi	a1,s0,-48
    80005ae0:	854a                	mv	a0,s2
    80005ae2:	fffff097          	auipc	ra,0xfffff
    80005ae6:	9f2080e7          	jalr	-1550(ra) # 800044d4 <dirlink>
    80005aea:	04054363          	bltz	a0,80005b30 <sys_link+0x100>
  iunlockput(dp);
    80005aee:	854a                	mv	a0,s2
    80005af0:	ffffe097          	auipc	ra,0xffffe
    80005af4:	552080e7          	jalr	1362(ra) # 80004042 <iunlockput>
  iput(ip);
    80005af8:	8526                	mv	a0,s1
    80005afa:	ffffe097          	auipc	ra,0xffffe
    80005afe:	4a0080e7          	jalr	1184(ra) # 80003f9a <iput>
  end_op();
    80005b02:	fffff097          	auipc	ra,0xfffff
    80005b06:	d30080e7          	jalr	-720(ra) # 80004832 <end_op>
  return 0;
    80005b0a:	4781                	li	a5,0
    80005b0c:	a085                	j	80005b6c <sys_link+0x13c>
    end_op();
    80005b0e:	fffff097          	auipc	ra,0xfffff
    80005b12:	d24080e7          	jalr	-732(ra) # 80004832 <end_op>
    return -1;
    80005b16:	57fd                	li	a5,-1
    80005b18:	a891                	j	80005b6c <sys_link+0x13c>
    iunlockput(ip);
    80005b1a:	8526                	mv	a0,s1
    80005b1c:	ffffe097          	auipc	ra,0xffffe
    80005b20:	526080e7          	jalr	1318(ra) # 80004042 <iunlockput>
    end_op();
    80005b24:	fffff097          	auipc	ra,0xfffff
    80005b28:	d0e080e7          	jalr	-754(ra) # 80004832 <end_op>
    return -1;
    80005b2c:	57fd                	li	a5,-1
    80005b2e:	a83d                	j	80005b6c <sys_link+0x13c>
    iunlockput(dp);
    80005b30:	854a                	mv	a0,s2
    80005b32:	ffffe097          	auipc	ra,0xffffe
    80005b36:	510080e7          	jalr	1296(ra) # 80004042 <iunlockput>
  ilock(ip);
    80005b3a:	8526                	mv	a0,s1
    80005b3c:	ffffe097          	auipc	ra,0xffffe
    80005b40:	2a4080e7          	jalr	676(ra) # 80003de0 <ilock>
  ip->nlink--;
    80005b44:	04a4d783          	lhu	a5,74(s1)
    80005b48:	37fd                	addiw	a5,a5,-1
    80005b4a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005b4e:	8526                	mv	a0,s1
    80005b50:	ffffe097          	auipc	ra,0xffffe
    80005b54:	1c6080e7          	jalr	454(ra) # 80003d16 <iupdate>
  iunlockput(ip);
    80005b58:	8526                	mv	a0,s1
    80005b5a:	ffffe097          	auipc	ra,0xffffe
    80005b5e:	4e8080e7          	jalr	1256(ra) # 80004042 <iunlockput>
  end_op();
    80005b62:	fffff097          	auipc	ra,0xfffff
    80005b66:	cd0080e7          	jalr	-816(ra) # 80004832 <end_op>
  return -1;
    80005b6a:	57fd                	li	a5,-1
}
    80005b6c:	853e                	mv	a0,a5
    80005b6e:	70b2                	ld	ra,296(sp)
    80005b70:	7412                	ld	s0,288(sp)
    80005b72:	64f2                	ld	s1,280(sp)
    80005b74:	6952                	ld	s2,272(sp)
    80005b76:	6155                	addi	sp,sp,304
    80005b78:	8082                	ret

0000000080005b7a <sys_unlink>:
{
    80005b7a:	7151                	addi	sp,sp,-240
    80005b7c:	f586                	sd	ra,232(sp)
    80005b7e:	f1a2                	sd	s0,224(sp)
    80005b80:	eda6                	sd	s1,216(sp)
    80005b82:	e9ca                	sd	s2,208(sp)
    80005b84:	e5ce                	sd	s3,200(sp)
    80005b86:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005b88:	08000613          	li	a2,128
    80005b8c:	f3040593          	addi	a1,s0,-208
    80005b90:	4501                	li	a0,0
    80005b92:	ffffd097          	auipc	ra,0xffffd
    80005b96:	6a4080e7          	jalr	1700(ra) # 80003236 <argstr>
    80005b9a:	18054163          	bltz	a0,80005d1c <sys_unlink+0x1a2>
  begin_op();
    80005b9e:	fffff097          	auipc	ra,0xfffff
    80005ba2:	c14080e7          	jalr	-1004(ra) # 800047b2 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005ba6:	fb040593          	addi	a1,s0,-80
    80005baa:	f3040513          	addi	a0,s0,-208
    80005bae:	fffff097          	auipc	ra,0xfffff
    80005bb2:	a06080e7          	jalr	-1530(ra) # 800045b4 <nameiparent>
    80005bb6:	84aa                	mv	s1,a0
    80005bb8:	c979                	beqz	a0,80005c8e <sys_unlink+0x114>
  ilock(dp);
    80005bba:	ffffe097          	auipc	ra,0xffffe
    80005bbe:	226080e7          	jalr	550(ra) # 80003de0 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005bc2:	00003597          	auipc	a1,0x3
    80005bc6:	b4e58593          	addi	a1,a1,-1202 # 80008710 <syscalls+0x2c8>
    80005bca:	fb040513          	addi	a0,s0,-80
    80005bce:	ffffe097          	auipc	ra,0xffffe
    80005bd2:	6dc080e7          	jalr	1756(ra) # 800042aa <namecmp>
    80005bd6:	14050a63          	beqz	a0,80005d2a <sys_unlink+0x1b0>
    80005bda:	00003597          	auipc	a1,0x3
    80005bde:	b3e58593          	addi	a1,a1,-1218 # 80008718 <syscalls+0x2d0>
    80005be2:	fb040513          	addi	a0,s0,-80
    80005be6:	ffffe097          	auipc	ra,0xffffe
    80005bea:	6c4080e7          	jalr	1732(ra) # 800042aa <namecmp>
    80005bee:	12050e63          	beqz	a0,80005d2a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005bf2:	f2c40613          	addi	a2,s0,-212
    80005bf6:	fb040593          	addi	a1,s0,-80
    80005bfa:	8526                	mv	a0,s1
    80005bfc:	ffffe097          	auipc	ra,0xffffe
    80005c00:	6c8080e7          	jalr	1736(ra) # 800042c4 <dirlookup>
    80005c04:	892a                	mv	s2,a0
    80005c06:	12050263          	beqz	a0,80005d2a <sys_unlink+0x1b0>
  ilock(ip);
    80005c0a:	ffffe097          	auipc	ra,0xffffe
    80005c0e:	1d6080e7          	jalr	470(ra) # 80003de0 <ilock>
  if(ip->nlink < 1)
    80005c12:	04a91783          	lh	a5,74(s2)
    80005c16:	08f05263          	blez	a5,80005c9a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005c1a:	04491703          	lh	a4,68(s2)
    80005c1e:	4785                	li	a5,1
    80005c20:	08f70563          	beq	a4,a5,80005caa <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005c24:	4641                	li	a2,16
    80005c26:	4581                	li	a1,0
    80005c28:	fc040513          	addi	a0,s0,-64
    80005c2c:	ffffb097          	auipc	ra,0xffffb
    80005c30:	0b4080e7          	jalr	180(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c34:	4741                	li	a4,16
    80005c36:	f2c42683          	lw	a3,-212(s0)
    80005c3a:	fc040613          	addi	a2,s0,-64
    80005c3e:	4581                	li	a1,0
    80005c40:	8526                	mv	a0,s1
    80005c42:	ffffe097          	auipc	ra,0xffffe
    80005c46:	54a080e7          	jalr	1354(ra) # 8000418c <writei>
    80005c4a:	47c1                	li	a5,16
    80005c4c:	0af51563          	bne	a0,a5,80005cf6 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005c50:	04491703          	lh	a4,68(s2)
    80005c54:	4785                	li	a5,1
    80005c56:	0af70863          	beq	a4,a5,80005d06 <sys_unlink+0x18c>
  iunlockput(dp);
    80005c5a:	8526                	mv	a0,s1
    80005c5c:	ffffe097          	auipc	ra,0xffffe
    80005c60:	3e6080e7          	jalr	998(ra) # 80004042 <iunlockput>
  ip->nlink--;
    80005c64:	04a95783          	lhu	a5,74(s2)
    80005c68:	37fd                	addiw	a5,a5,-1
    80005c6a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005c6e:	854a                	mv	a0,s2
    80005c70:	ffffe097          	auipc	ra,0xffffe
    80005c74:	0a6080e7          	jalr	166(ra) # 80003d16 <iupdate>
  iunlockput(ip);
    80005c78:	854a                	mv	a0,s2
    80005c7a:	ffffe097          	auipc	ra,0xffffe
    80005c7e:	3c8080e7          	jalr	968(ra) # 80004042 <iunlockput>
  end_op();
    80005c82:	fffff097          	auipc	ra,0xfffff
    80005c86:	bb0080e7          	jalr	-1104(ra) # 80004832 <end_op>
  return 0;
    80005c8a:	4501                	li	a0,0
    80005c8c:	a84d                	j	80005d3e <sys_unlink+0x1c4>
    end_op();
    80005c8e:	fffff097          	auipc	ra,0xfffff
    80005c92:	ba4080e7          	jalr	-1116(ra) # 80004832 <end_op>
    return -1;
    80005c96:	557d                	li	a0,-1
    80005c98:	a05d                	j	80005d3e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005c9a:	00003517          	auipc	a0,0x3
    80005c9e:	aa650513          	addi	a0,a0,-1370 # 80008740 <syscalls+0x2f8>
    80005ca2:	ffffb097          	auipc	ra,0xffffb
    80005ca6:	89c080e7          	jalr	-1892(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005caa:	04c92703          	lw	a4,76(s2)
    80005cae:	02000793          	li	a5,32
    80005cb2:	f6e7f9e3          	bgeu	a5,a4,80005c24 <sys_unlink+0xaa>
    80005cb6:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005cba:	4741                	li	a4,16
    80005cbc:	86ce                	mv	a3,s3
    80005cbe:	f1840613          	addi	a2,s0,-232
    80005cc2:	4581                	li	a1,0
    80005cc4:	854a                	mv	a0,s2
    80005cc6:	ffffe097          	auipc	ra,0xffffe
    80005cca:	3ce080e7          	jalr	974(ra) # 80004094 <readi>
    80005cce:	47c1                	li	a5,16
    80005cd0:	00f51b63          	bne	a0,a5,80005ce6 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005cd4:	f1845783          	lhu	a5,-232(s0)
    80005cd8:	e7a1                	bnez	a5,80005d20 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005cda:	29c1                	addiw	s3,s3,16
    80005cdc:	04c92783          	lw	a5,76(s2)
    80005ce0:	fcf9ede3          	bltu	s3,a5,80005cba <sys_unlink+0x140>
    80005ce4:	b781                	j	80005c24 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005ce6:	00003517          	auipc	a0,0x3
    80005cea:	a7250513          	addi	a0,a0,-1422 # 80008758 <syscalls+0x310>
    80005cee:	ffffb097          	auipc	ra,0xffffb
    80005cf2:	850080e7          	jalr	-1968(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005cf6:	00003517          	auipc	a0,0x3
    80005cfa:	a7a50513          	addi	a0,a0,-1414 # 80008770 <syscalls+0x328>
    80005cfe:	ffffb097          	auipc	ra,0xffffb
    80005d02:	840080e7          	jalr	-1984(ra) # 8000053e <panic>
    dp->nlink--;
    80005d06:	04a4d783          	lhu	a5,74(s1)
    80005d0a:	37fd                	addiw	a5,a5,-1
    80005d0c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005d10:	8526                	mv	a0,s1
    80005d12:	ffffe097          	auipc	ra,0xffffe
    80005d16:	004080e7          	jalr	4(ra) # 80003d16 <iupdate>
    80005d1a:	b781                	j	80005c5a <sys_unlink+0xe0>
    return -1;
    80005d1c:	557d                	li	a0,-1
    80005d1e:	a005                	j	80005d3e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005d20:	854a                	mv	a0,s2
    80005d22:	ffffe097          	auipc	ra,0xffffe
    80005d26:	320080e7          	jalr	800(ra) # 80004042 <iunlockput>
  iunlockput(dp);
    80005d2a:	8526                	mv	a0,s1
    80005d2c:	ffffe097          	auipc	ra,0xffffe
    80005d30:	316080e7          	jalr	790(ra) # 80004042 <iunlockput>
  end_op();
    80005d34:	fffff097          	auipc	ra,0xfffff
    80005d38:	afe080e7          	jalr	-1282(ra) # 80004832 <end_op>
  return -1;
    80005d3c:	557d                	li	a0,-1
}
    80005d3e:	70ae                	ld	ra,232(sp)
    80005d40:	740e                	ld	s0,224(sp)
    80005d42:	64ee                	ld	s1,216(sp)
    80005d44:	694e                	ld	s2,208(sp)
    80005d46:	69ae                	ld	s3,200(sp)
    80005d48:	616d                	addi	sp,sp,240
    80005d4a:	8082                	ret

0000000080005d4c <sys_open>:

uint64
sys_open(void)
{
    80005d4c:	7131                	addi	sp,sp,-192
    80005d4e:	fd06                	sd	ra,184(sp)
    80005d50:	f922                	sd	s0,176(sp)
    80005d52:	f526                	sd	s1,168(sp)
    80005d54:	f14a                	sd	s2,160(sp)
    80005d56:	ed4e                	sd	s3,152(sp)
    80005d58:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005d5a:	08000613          	li	a2,128
    80005d5e:	f5040593          	addi	a1,s0,-176
    80005d62:	4501                	li	a0,0
    80005d64:	ffffd097          	auipc	ra,0xffffd
    80005d68:	4d2080e7          	jalr	1234(ra) # 80003236 <argstr>
    return -1;
    80005d6c:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005d6e:	0c054163          	bltz	a0,80005e30 <sys_open+0xe4>
    80005d72:	f4c40593          	addi	a1,s0,-180
    80005d76:	4505                	li	a0,1
    80005d78:	ffffd097          	auipc	ra,0xffffd
    80005d7c:	47a080e7          	jalr	1146(ra) # 800031f2 <argint>
    80005d80:	0a054863          	bltz	a0,80005e30 <sys_open+0xe4>

  begin_op();
    80005d84:	fffff097          	auipc	ra,0xfffff
    80005d88:	a2e080e7          	jalr	-1490(ra) # 800047b2 <begin_op>

  if(omode & O_CREATE){
    80005d8c:	f4c42783          	lw	a5,-180(s0)
    80005d90:	2007f793          	andi	a5,a5,512
    80005d94:	cbdd                	beqz	a5,80005e4a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005d96:	4681                	li	a3,0
    80005d98:	4601                	li	a2,0
    80005d9a:	4589                	li	a1,2
    80005d9c:	f5040513          	addi	a0,s0,-176
    80005da0:	00000097          	auipc	ra,0x0
    80005da4:	972080e7          	jalr	-1678(ra) # 80005712 <create>
    80005da8:	892a                	mv	s2,a0
    if(ip == 0){
    80005daa:	c959                	beqz	a0,80005e40 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005dac:	04491703          	lh	a4,68(s2)
    80005db0:	478d                	li	a5,3
    80005db2:	00f71763          	bne	a4,a5,80005dc0 <sys_open+0x74>
    80005db6:	04695703          	lhu	a4,70(s2)
    80005dba:	47a5                	li	a5,9
    80005dbc:	0ce7ec63          	bltu	a5,a4,80005e94 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005dc0:	fffff097          	auipc	ra,0xfffff
    80005dc4:	e02080e7          	jalr	-510(ra) # 80004bc2 <filealloc>
    80005dc8:	89aa                	mv	s3,a0
    80005dca:	10050263          	beqz	a0,80005ece <sys_open+0x182>
    80005dce:	00000097          	auipc	ra,0x0
    80005dd2:	902080e7          	jalr	-1790(ra) # 800056d0 <fdalloc>
    80005dd6:	84aa                	mv	s1,a0
    80005dd8:	0e054663          	bltz	a0,80005ec4 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005ddc:	04491703          	lh	a4,68(s2)
    80005de0:	478d                	li	a5,3
    80005de2:	0cf70463          	beq	a4,a5,80005eaa <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005de6:	4789                	li	a5,2
    80005de8:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005dec:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005df0:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005df4:	f4c42783          	lw	a5,-180(s0)
    80005df8:	0017c713          	xori	a4,a5,1
    80005dfc:	8b05                	andi	a4,a4,1
    80005dfe:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005e02:	0037f713          	andi	a4,a5,3
    80005e06:	00e03733          	snez	a4,a4
    80005e0a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005e0e:	4007f793          	andi	a5,a5,1024
    80005e12:	c791                	beqz	a5,80005e1e <sys_open+0xd2>
    80005e14:	04491703          	lh	a4,68(s2)
    80005e18:	4789                	li	a5,2
    80005e1a:	08f70f63          	beq	a4,a5,80005eb8 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005e1e:	854a                	mv	a0,s2
    80005e20:	ffffe097          	auipc	ra,0xffffe
    80005e24:	082080e7          	jalr	130(ra) # 80003ea2 <iunlock>
  end_op();
    80005e28:	fffff097          	auipc	ra,0xfffff
    80005e2c:	a0a080e7          	jalr	-1526(ra) # 80004832 <end_op>

  return fd;
}
    80005e30:	8526                	mv	a0,s1
    80005e32:	70ea                	ld	ra,184(sp)
    80005e34:	744a                	ld	s0,176(sp)
    80005e36:	74aa                	ld	s1,168(sp)
    80005e38:	790a                	ld	s2,160(sp)
    80005e3a:	69ea                	ld	s3,152(sp)
    80005e3c:	6129                	addi	sp,sp,192
    80005e3e:	8082                	ret
      end_op();
    80005e40:	fffff097          	auipc	ra,0xfffff
    80005e44:	9f2080e7          	jalr	-1550(ra) # 80004832 <end_op>
      return -1;
    80005e48:	b7e5                	j	80005e30 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005e4a:	f5040513          	addi	a0,s0,-176
    80005e4e:	ffffe097          	auipc	ra,0xffffe
    80005e52:	748080e7          	jalr	1864(ra) # 80004596 <namei>
    80005e56:	892a                	mv	s2,a0
    80005e58:	c905                	beqz	a0,80005e88 <sys_open+0x13c>
    ilock(ip);
    80005e5a:	ffffe097          	auipc	ra,0xffffe
    80005e5e:	f86080e7          	jalr	-122(ra) # 80003de0 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005e62:	04491703          	lh	a4,68(s2)
    80005e66:	4785                	li	a5,1
    80005e68:	f4f712e3          	bne	a4,a5,80005dac <sys_open+0x60>
    80005e6c:	f4c42783          	lw	a5,-180(s0)
    80005e70:	dba1                	beqz	a5,80005dc0 <sys_open+0x74>
      iunlockput(ip);
    80005e72:	854a                	mv	a0,s2
    80005e74:	ffffe097          	auipc	ra,0xffffe
    80005e78:	1ce080e7          	jalr	462(ra) # 80004042 <iunlockput>
      end_op();
    80005e7c:	fffff097          	auipc	ra,0xfffff
    80005e80:	9b6080e7          	jalr	-1610(ra) # 80004832 <end_op>
      return -1;
    80005e84:	54fd                	li	s1,-1
    80005e86:	b76d                	j	80005e30 <sys_open+0xe4>
      end_op();
    80005e88:	fffff097          	auipc	ra,0xfffff
    80005e8c:	9aa080e7          	jalr	-1622(ra) # 80004832 <end_op>
      return -1;
    80005e90:	54fd                	li	s1,-1
    80005e92:	bf79                	j	80005e30 <sys_open+0xe4>
    iunlockput(ip);
    80005e94:	854a                	mv	a0,s2
    80005e96:	ffffe097          	auipc	ra,0xffffe
    80005e9a:	1ac080e7          	jalr	428(ra) # 80004042 <iunlockput>
    end_op();
    80005e9e:	fffff097          	auipc	ra,0xfffff
    80005ea2:	994080e7          	jalr	-1644(ra) # 80004832 <end_op>
    return -1;
    80005ea6:	54fd                	li	s1,-1
    80005ea8:	b761                	j	80005e30 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005eaa:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005eae:	04691783          	lh	a5,70(s2)
    80005eb2:	02f99223          	sh	a5,36(s3)
    80005eb6:	bf2d                	j	80005df0 <sys_open+0xa4>
    itrunc(ip);
    80005eb8:	854a                	mv	a0,s2
    80005eba:	ffffe097          	auipc	ra,0xffffe
    80005ebe:	034080e7          	jalr	52(ra) # 80003eee <itrunc>
    80005ec2:	bfb1                	j	80005e1e <sys_open+0xd2>
      fileclose(f);
    80005ec4:	854e                	mv	a0,s3
    80005ec6:	fffff097          	auipc	ra,0xfffff
    80005eca:	db8080e7          	jalr	-584(ra) # 80004c7e <fileclose>
    iunlockput(ip);
    80005ece:	854a                	mv	a0,s2
    80005ed0:	ffffe097          	auipc	ra,0xffffe
    80005ed4:	172080e7          	jalr	370(ra) # 80004042 <iunlockput>
    end_op();
    80005ed8:	fffff097          	auipc	ra,0xfffff
    80005edc:	95a080e7          	jalr	-1702(ra) # 80004832 <end_op>
    return -1;
    80005ee0:	54fd                	li	s1,-1
    80005ee2:	b7b9                	j	80005e30 <sys_open+0xe4>

0000000080005ee4 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005ee4:	7175                	addi	sp,sp,-144
    80005ee6:	e506                	sd	ra,136(sp)
    80005ee8:	e122                	sd	s0,128(sp)
    80005eea:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005eec:	fffff097          	auipc	ra,0xfffff
    80005ef0:	8c6080e7          	jalr	-1850(ra) # 800047b2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005ef4:	08000613          	li	a2,128
    80005ef8:	f7040593          	addi	a1,s0,-144
    80005efc:	4501                	li	a0,0
    80005efe:	ffffd097          	auipc	ra,0xffffd
    80005f02:	338080e7          	jalr	824(ra) # 80003236 <argstr>
    80005f06:	02054963          	bltz	a0,80005f38 <sys_mkdir+0x54>
    80005f0a:	4681                	li	a3,0
    80005f0c:	4601                	li	a2,0
    80005f0e:	4585                	li	a1,1
    80005f10:	f7040513          	addi	a0,s0,-144
    80005f14:	fffff097          	auipc	ra,0xfffff
    80005f18:	7fe080e7          	jalr	2046(ra) # 80005712 <create>
    80005f1c:	cd11                	beqz	a0,80005f38 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f1e:	ffffe097          	auipc	ra,0xffffe
    80005f22:	124080e7          	jalr	292(ra) # 80004042 <iunlockput>
  end_op();
    80005f26:	fffff097          	auipc	ra,0xfffff
    80005f2a:	90c080e7          	jalr	-1780(ra) # 80004832 <end_op>
  return 0;
    80005f2e:	4501                	li	a0,0
}
    80005f30:	60aa                	ld	ra,136(sp)
    80005f32:	640a                	ld	s0,128(sp)
    80005f34:	6149                	addi	sp,sp,144
    80005f36:	8082                	ret
    end_op();
    80005f38:	fffff097          	auipc	ra,0xfffff
    80005f3c:	8fa080e7          	jalr	-1798(ra) # 80004832 <end_op>
    return -1;
    80005f40:	557d                	li	a0,-1
    80005f42:	b7fd                	j	80005f30 <sys_mkdir+0x4c>

0000000080005f44 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005f44:	7135                	addi	sp,sp,-160
    80005f46:	ed06                	sd	ra,152(sp)
    80005f48:	e922                	sd	s0,144(sp)
    80005f4a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005f4c:	fffff097          	auipc	ra,0xfffff
    80005f50:	866080e7          	jalr	-1946(ra) # 800047b2 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f54:	08000613          	li	a2,128
    80005f58:	f7040593          	addi	a1,s0,-144
    80005f5c:	4501                	li	a0,0
    80005f5e:	ffffd097          	auipc	ra,0xffffd
    80005f62:	2d8080e7          	jalr	728(ra) # 80003236 <argstr>
    80005f66:	04054a63          	bltz	a0,80005fba <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005f6a:	f6c40593          	addi	a1,s0,-148
    80005f6e:	4505                	li	a0,1
    80005f70:	ffffd097          	auipc	ra,0xffffd
    80005f74:	282080e7          	jalr	642(ra) # 800031f2 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f78:	04054163          	bltz	a0,80005fba <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005f7c:	f6840593          	addi	a1,s0,-152
    80005f80:	4509                	li	a0,2
    80005f82:	ffffd097          	auipc	ra,0xffffd
    80005f86:	270080e7          	jalr	624(ra) # 800031f2 <argint>
     argint(1, &major) < 0 ||
    80005f8a:	02054863          	bltz	a0,80005fba <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005f8e:	f6841683          	lh	a3,-152(s0)
    80005f92:	f6c41603          	lh	a2,-148(s0)
    80005f96:	458d                	li	a1,3
    80005f98:	f7040513          	addi	a0,s0,-144
    80005f9c:	fffff097          	auipc	ra,0xfffff
    80005fa0:	776080e7          	jalr	1910(ra) # 80005712 <create>
     argint(2, &minor) < 0 ||
    80005fa4:	c919                	beqz	a0,80005fba <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005fa6:	ffffe097          	auipc	ra,0xffffe
    80005faa:	09c080e7          	jalr	156(ra) # 80004042 <iunlockput>
  end_op();
    80005fae:	fffff097          	auipc	ra,0xfffff
    80005fb2:	884080e7          	jalr	-1916(ra) # 80004832 <end_op>
  return 0;
    80005fb6:	4501                	li	a0,0
    80005fb8:	a031                	j	80005fc4 <sys_mknod+0x80>
    end_op();
    80005fba:	fffff097          	auipc	ra,0xfffff
    80005fbe:	878080e7          	jalr	-1928(ra) # 80004832 <end_op>
    return -1;
    80005fc2:	557d                	li	a0,-1
}
    80005fc4:	60ea                	ld	ra,152(sp)
    80005fc6:	644a                	ld	s0,144(sp)
    80005fc8:	610d                	addi	sp,sp,160
    80005fca:	8082                	ret

0000000080005fcc <sys_chdir>:

uint64
sys_chdir(void)
{
    80005fcc:	7135                	addi	sp,sp,-160
    80005fce:	ed06                	sd	ra,152(sp)
    80005fd0:	e922                	sd	s0,144(sp)
    80005fd2:	e526                	sd	s1,136(sp)
    80005fd4:	e14a                	sd	s2,128(sp)
    80005fd6:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005fd8:	ffffc097          	auipc	ra,0xffffc
    80005fdc:	cd6080e7          	jalr	-810(ra) # 80001cae <myproc>
    80005fe0:	892a                	mv	s2,a0
  
  begin_op();
    80005fe2:	ffffe097          	auipc	ra,0xffffe
    80005fe6:	7d0080e7          	jalr	2000(ra) # 800047b2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005fea:	08000613          	li	a2,128
    80005fee:	f6040593          	addi	a1,s0,-160
    80005ff2:	4501                	li	a0,0
    80005ff4:	ffffd097          	auipc	ra,0xffffd
    80005ff8:	242080e7          	jalr	578(ra) # 80003236 <argstr>
    80005ffc:	04054b63          	bltz	a0,80006052 <sys_chdir+0x86>
    80006000:	f6040513          	addi	a0,s0,-160
    80006004:	ffffe097          	auipc	ra,0xffffe
    80006008:	592080e7          	jalr	1426(ra) # 80004596 <namei>
    8000600c:	84aa                	mv	s1,a0
    8000600e:	c131                	beqz	a0,80006052 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006010:	ffffe097          	auipc	ra,0xffffe
    80006014:	dd0080e7          	jalr	-560(ra) # 80003de0 <ilock>
  if(ip->type != T_DIR){
    80006018:	04449703          	lh	a4,68(s1)
    8000601c:	4785                	li	a5,1
    8000601e:	04f71063          	bne	a4,a5,8000605e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006022:	8526                	mv	a0,s1
    80006024:	ffffe097          	auipc	ra,0xffffe
    80006028:	e7e080e7          	jalr	-386(ra) # 80003ea2 <iunlock>
  iput(p->cwd);
    8000602c:	17893503          	ld	a0,376(s2)
    80006030:	ffffe097          	auipc	ra,0xffffe
    80006034:	f6a080e7          	jalr	-150(ra) # 80003f9a <iput>
  end_op();
    80006038:	ffffe097          	auipc	ra,0xffffe
    8000603c:	7fa080e7          	jalr	2042(ra) # 80004832 <end_op>
  p->cwd = ip;
    80006040:	16993c23          	sd	s1,376(s2)
  return 0;
    80006044:	4501                	li	a0,0
}
    80006046:	60ea                	ld	ra,152(sp)
    80006048:	644a                	ld	s0,144(sp)
    8000604a:	64aa                	ld	s1,136(sp)
    8000604c:	690a                	ld	s2,128(sp)
    8000604e:	610d                	addi	sp,sp,160
    80006050:	8082                	ret
    end_op();
    80006052:	ffffe097          	auipc	ra,0xffffe
    80006056:	7e0080e7          	jalr	2016(ra) # 80004832 <end_op>
    return -1;
    8000605a:	557d                	li	a0,-1
    8000605c:	b7ed                	j	80006046 <sys_chdir+0x7a>
    iunlockput(ip);
    8000605e:	8526                	mv	a0,s1
    80006060:	ffffe097          	auipc	ra,0xffffe
    80006064:	fe2080e7          	jalr	-30(ra) # 80004042 <iunlockput>
    end_op();
    80006068:	ffffe097          	auipc	ra,0xffffe
    8000606c:	7ca080e7          	jalr	1994(ra) # 80004832 <end_op>
    return -1;
    80006070:	557d                	li	a0,-1
    80006072:	bfd1                	j	80006046 <sys_chdir+0x7a>

0000000080006074 <sys_exec>:

uint64
sys_exec(void)
{
    80006074:	7145                	addi	sp,sp,-464
    80006076:	e786                	sd	ra,456(sp)
    80006078:	e3a2                	sd	s0,448(sp)
    8000607a:	ff26                	sd	s1,440(sp)
    8000607c:	fb4a                	sd	s2,432(sp)
    8000607e:	f74e                	sd	s3,424(sp)
    80006080:	f352                	sd	s4,416(sp)
    80006082:	ef56                	sd	s5,408(sp)
    80006084:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006086:	08000613          	li	a2,128
    8000608a:	f4040593          	addi	a1,s0,-192
    8000608e:	4501                	li	a0,0
    80006090:	ffffd097          	auipc	ra,0xffffd
    80006094:	1a6080e7          	jalr	422(ra) # 80003236 <argstr>
    return -1;
    80006098:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000609a:	0c054a63          	bltz	a0,8000616e <sys_exec+0xfa>
    8000609e:	e3840593          	addi	a1,s0,-456
    800060a2:	4505                	li	a0,1
    800060a4:	ffffd097          	auipc	ra,0xffffd
    800060a8:	170080e7          	jalr	368(ra) # 80003214 <argaddr>
    800060ac:	0c054163          	bltz	a0,8000616e <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800060b0:	10000613          	li	a2,256
    800060b4:	4581                	li	a1,0
    800060b6:	e4040513          	addi	a0,s0,-448
    800060ba:	ffffb097          	auipc	ra,0xffffb
    800060be:	c26080e7          	jalr	-986(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800060c2:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800060c6:	89a6                	mv	s3,s1
    800060c8:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800060ca:	02000a13          	li	s4,32
    800060ce:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800060d2:	00391513          	slli	a0,s2,0x3
    800060d6:	e3040593          	addi	a1,s0,-464
    800060da:	e3843783          	ld	a5,-456(s0)
    800060de:	953e                	add	a0,a0,a5
    800060e0:	ffffd097          	auipc	ra,0xffffd
    800060e4:	078080e7          	jalr	120(ra) # 80003158 <fetchaddr>
    800060e8:	02054a63          	bltz	a0,8000611c <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800060ec:	e3043783          	ld	a5,-464(s0)
    800060f0:	c3b9                	beqz	a5,80006136 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800060f2:	ffffb097          	auipc	ra,0xffffb
    800060f6:	a02080e7          	jalr	-1534(ra) # 80000af4 <kalloc>
    800060fa:	85aa                	mv	a1,a0
    800060fc:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006100:	cd11                	beqz	a0,8000611c <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006102:	6605                	lui	a2,0x1
    80006104:	e3043503          	ld	a0,-464(s0)
    80006108:	ffffd097          	auipc	ra,0xffffd
    8000610c:	0a2080e7          	jalr	162(ra) # 800031aa <fetchstr>
    80006110:	00054663          	bltz	a0,8000611c <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006114:	0905                	addi	s2,s2,1
    80006116:	09a1                	addi	s3,s3,8
    80006118:	fb491be3          	bne	s2,s4,800060ce <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000611c:	10048913          	addi	s2,s1,256
    80006120:	6088                	ld	a0,0(s1)
    80006122:	c529                	beqz	a0,8000616c <sys_exec+0xf8>
    kfree(argv[i]);
    80006124:	ffffb097          	auipc	ra,0xffffb
    80006128:	8d4080e7          	jalr	-1836(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000612c:	04a1                	addi	s1,s1,8
    8000612e:	ff2499e3          	bne	s1,s2,80006120 <sys_exec+0xac>
  return -1;
    80006132:	597d                	li	s2,-1
    80006134:	a82d                	j	8000616e <sys_exec+0xfa>
      argv[i] = 0;
    80006136:	0a8e                	slli	s5,s5,0x3
    80006138:	fc040793          	addi	a5,s0,-64
    8000613c:	9abe                	add	s5,s5,a5
    8000613e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006142:	e4040593          	addi	a1,s0,-448
    80006146:	f4040513          	addi	a0,s0,-192
    8000614a:	fffff097          	auipc	ra,0xfffff
    8000614e:	194080e7          	jalr	404(ra) # 800052de <exec>
    80006152:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006154:	10048993          	addi	s3,s1,256
    80006158:	6088                	ld	a0,0(s1)
    8000615a:	c911                	beqz	a0,8000616e <sys_exec+0xfa>
    kfree(argv[i]);
    8000615c:	ffffb097          	auipc	ra,0xffffb
    80006160:	89c080e7          	jalr	-1892(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006164:	04a1                	addi	s1,s1,8
    80006166:	ff3499e3          	bne	s1,s3,80006158 <sys_exec+0xe4>
    8000616a:	a011                	j	8000616e <sys_exec+0xfa>
  return -1;
    8000616c:	597d                	li	s2,-1
}
    8000616e:	854a                	mv	a0,s2
    80006170:	60be                	ld	ra,456(sp)
    80006172:	641e                	ld	s0,448(sp)
    80006174:	74fa                	ld	s1,440(sp)
    80006176:	795a                	ld	s2,432(sp)
    80006178:	79ba                	ld	s3,424(sp)
    8000617a:	7a1a                	ld	s4,416(sp)
    8000617c:	6afa                	ld	s5,408(sp)
    8000617e:	6179                	addi	sp,sp,464
    80006180:	8082                	ret

0000000080006182 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006182:	7139                	addi	sp,sp,-64
    80006184:	fc06                	sd	ra,56(sp)
    80006186:	f822                	sd	s0,48(sp)
    80006188:	f426                	sd	s1,40(sp)
    8000618a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000618c:	ffffc097          	auipc	ra,0xffffc
    80006190:	b22080e7          	jalr	-1246(ra) # 80001cae <myproc>
    80006194:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80006196:	fd840593          	addi	a1,s0,-40
    8000619a:	4501                	li	a0,0
    8000619c:	ffffd097          	auipc	ra,0xffffd
    800061a0:	078080e7          	jalr	120(ra) # 80003214 <argaddr>
    return -1;
    800061a4:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800061a6:	0e054063          	bltz	a0,80006286 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800061aa:	fc840593          	addi	a1,s0,-56
    800061ae:	fd040513          	addi	a0,s0,-48
    800061b2:	fffff097          	auipc	ra,0xfffff
    800061b6:	dfc080e7          	jalr	-516(ra) # 80004fae <pipealloc>
    return -1;
    800061ba:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800061bc:	0c054563          	bltz	a0,80006286 <sys_pipe+0x104>
  fd0 = -1;
    800061c0:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800061c4:	fd043503          	ld	a0,-48(s0)
    800061c8:	fffff097          	auipc	ra,0xfffff
    800061cc:	508080e7          	jalr	1288(ra) # 800056d0 <fdalloc>
    800061d0:	fca42223          	sw	a0,-60(s0)
    800061d4:	08054c63          	bltz	a0,8000626c <sys_pipe+0xea>
    800061d8:	fc843503          	ld	a0,-56(s0)
    800061dc:	fffff097          	auipc	ra,0xfffff
    800061e0:	4f4080e7          	jalr	1268(ra) # 800056d0 <fdalloc>
    800061e4:	fca42023          	sw	a0,-64(s0)
    800061e8:	06054863          	bltz	a0,80006258 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800061ec:	4691                	li	a3,4
    800061ee:	fc440613          	addi	a2,s0,-60
    800061f2:	fd843583          	ld	a1,-40(s0)
    800061f6:	7ca8                	ld	a0,120(s1)
    800061f8:	ffffb097          	auipc	ra,0xffffb
    800061fc:	47a080e7          	jalr	1146(ra) # 80001672 <copyout>
    80006200:	02054063          	bltz	a0,80006220 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006204:	4691                	li	a3,4
    80006206:	fc040613          	addi	a2,s0,-64
    8000620a:	fd843583          	ld	a1,-40(s0)
    8000620e:	0591                	addi	a1,a1,4
    80006210:	7ca8                	ld	a0,120(s1)
    80006212:	ffffb097          	auipc	ra,0xffffb
    80006216:	460080e7          	jalr	1120(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000621a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000621c:	06055563          	bgez	a0,80006286 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006220:	fc442783          	lw	a5,-60(s0)
    80006224:	07f9                	addi	a5,a5,30
    80006226:	078e                	slli	a5,a5,0x3
    80006228:	97a6                	add	a5,a5,s1
    8000622a:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    8000622e:	fc042503          	lw	a0,-64(s0)
    80006232:	0579                	addi	a0,a0,30
    80006234:	050e                	slli	a0,a0,0x3
    80006236:	9526                	add	a0,a0,s1
    80006238:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    8000623c:	fd043503          	ld	a0,-48(s0)
    80006240:	fffff097          	auipc	ra,0xfffff
    80006244:	a3e080e7          	jalr	-1474(ra) # 80004c7e <fileclose>
    fileclose(wf);
    80006248:	fc843503          	ld	a0,-56(s0)
    8000624c:	fffff097          	auipc	ra,0xfffff
    80006250:	a32080e7          	jalr	-1486(ra) # 80004c7e <fileclose>
    return -1;
    80006254:	57fd                	li	a5,-1
    80006256:	a805                	j	80006286 <sys_pipe+0x104>
    if(fd0 >= 0)
    80006258:	fc442783          	lw	a5,-60(s0)
    8000625c:	0007c863          	bltz	a5,8000626c <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006260:	01e78513          	addi	a0,a5,30
    80006264:	050e                	slli	a0,a0,0x3
    80006266:	9526                	add	a0,a0,s1
    80006268:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    8000626c:	fd043503          	ld	a0,-48(s0)
    80006270:	fffff097          	auipc	ra,0xfffff
    80006274:	a0e080e7          	jalr	-1522(ra) # 80004c7e <fileclose>
    fileclose(wf);
    80006278:	fc843503          	ld	a0,-56(s0)
    8000627c:	fffff097          	auipc	ra,0xfffff
    80006280:	a02080e7          	jalr	-1534(ra) # 80004c7e <fileclose>
    return -1;
    80006284:	57fd                	li	a5,-1
}
    80006286:	853e                	mv	a0,a5
    80006288:	70e2                	ld	ra,56(sp)
    8000628a:	7442                	ld	s0,48(sp)
    8000628c:	74a2                	ld	s1,40(sp)
    8000628e:	6121                	addi	sp,sp,64
    80006290:	8082                	ret
	...

00000000800062a0 <kernelvec>:
    800062a0:	7111                	addi	sp,sp,-256
    800062a2:	e006                	sd	ra,0(sp)
    800062a4:	e40a                	sd	sp,8(sp)
    800062a6:	e80e                	sd	gp,16(sp)
    800062a8:	ec12                	sd	tp,24(sp)
    800062aa:	f016                	sd	t0,32(sp)
    800062ac:	f41a                	sd	t1,40(sp)
    800062ae:	f81e                	sd	t2,48(sp)
    800062b0:	fc22                	sd	s0,56(sp)
    800062b2:	e0a6                	sd	s1,64(sp)
    800062b4:	e4aa                	sd	a0,72(sp)
    800062b6:	e8ae                	sd	a1,80(sp)
    800062b8:	ecb2                	sd	a2,88(sp)
    800062ba:	f0b6                	sd	a3,96(sp)
    800062bc:	f4ba                	sd	a4,104(sp)
    800062be:	f8be                	sd	a5,112(sp)
    800062c0:	fcc2                	sd	a6,120(sp)
    800062c2:	e146                	sd	a7,128(sp)
    800062c4:	e54a                	sd	s2,136(sp)
    800062c6:	e94e                	sd	s3,144(sp)
    800062c8:	ed52                	sd	s4,152(sp)
    800062ca:	f156                	sd	s5,160(sp)
    800062cc:	f55a                	sd	s6,168(sp)
    800062ce:	f95e                	sd	s7,176(sp)
    800062d0:	fd62                	sd	s8,184(sp)
    800062d2:	e1e6                	sd	s9,192(sp)
    800062d4:	e5ea                	sd	s10,200(sp)
    800062d6:	e9ee                	sd	s11,208(sp)
    800062d8:	edf2                	sd	t3,216(sp)
    800062da:	f1f6                	sd	t4,224(sp)
    800062dc:	f5fa                	sd	t5,232(sp)
    800062de:	f9fe                	sd	t6,240(sp)
    800062e0:	d45fc0ef          	jal	ra,80003024 <kerneltrap>
    800062e4:	6082                	ld	ra,0(sp)
    800062e6:	6122                	ld	sp,8(sp)
    800062e8:	61c2                	ld	gp,16(sp)
    800062ea:	7282                	ld	t0,32(sp)
    800062ec:	7322                	ld	t1,40(sp)
    800062ee:	73c2                	ld	t2,48(sp)
    800062f0:	7462                	ld	s0,56(sp)
    800062f2:	6486                	ld	s1,64(sp)
    800062f4:	6526                	ld	a0,72(sp)
    800062f6:	65c6                	ld	a1,80(sp)
    800062f8:	6666                	ld	a2,88(sp)
    800062fa:	7686                	ld	a3,96(sp)
    800062fc:	7726                	ld	a4,104(sp)
    800062fe:	77c6                	ld	a5,112(sp)
    80006300:	7866                	ld	a6,120(sp)
    80006302:	688a                	ld	a7,128(sp)
    80006304:	692a                	ld	s2,136(sp)
    80006306:	69ca                	ld	s3,144(sp)
    80006308:	6a6a                	ld	s4,152(sp)
    8000630a:	7a8a                	ld	s5,160(sp)
    8000630c:	7b2a                	ld	s6,168(sp)
    8000630e:	7bca                	ld	s7,176(sp)
    80006310:	7c6a                	ld	s8,184(sp)
    80006312:	6c8e                	ld	s9,192(sp)
    80006314:	6d2e                	ld	s10,200(sp)
    80006316:	6dce                	ld	s11,208(sp)
    80006318:	6e6e                	ld	t3,216(sp)
    8000631a:	7e8e                	ld	t4,224(sp)
    8000631c:	7f2e                	ld	t5,232(sp)
    8000631e:	7fce                	ld	t6,240(sp)
    80006320:	6111                	addi	sp,sp,256
    80006322:	10200073          	sret
    80006326:	00000013          	nop
    8000632a:	00000013          	nop
    8000632e:	0001                	nop

0000000080006330 <timervec>:
    80006330:	34051573          	csrrw	a0,mscratch,a0
    80006334:	e10c                	sd	a1,0(a0)
    80006336:	e510                	sd	a2,8(a0)
    80006338:	e914                	sd	a3,16(a0)
    8000633a:	6d0c                	ld	a1,24(a0)
    8000633c:	7110                	ld	a2,32(a0)
    8000633e:	6194                	ld	a3,0(a1)
    80006340:	96b2                	add	a3,a3,a2
    80006342:	e194                	sd	a3,0(a1)
    80006344:	4589                	li	a1,2
    80006346:	14459073          	csrw	sip,a1
    8000634a:	6914                	ld	a3,16(a0)
    8000634c:	6510                	ld	a2,8(a0)
    8000634e:	610c                	ld	a1,0(a0)
    80006350:	34051573          	csrrw	a0,mscratch,a0
    80006354:	30200073          	mret
	...

000000008000635a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000635a:	1141                	addi	sp,sp,-16
    8000635c:	e422                	sd	s0,8(sp)
    8000635e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006360:	0c0007b7          	lui	a5,0xc000
    80006364:	4705                	li	a4,1
    80006366:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006368:	c3d8                	sw	a4,4(a5)
}
    8000636a:	6422                	ld	s0,8(sp)
    8000636c:	0141                	addi	sp,sp,16
    8000636e:	8082                	ret

0000000080006370 <plicinithart>:

void
plicinithart(void)
{
    80006370:	1141                	addi	sp,sp,-16
    80006372:	e406                	sd	ra,8(sp)
    80006374:	e022                	sd	s0,0(sp)
    80006376:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006378:	ffffc097          	auipc	ra,0xffffc
    8000637c:	90a080e7          	jalr	-1782(ra) # 80001c82 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006380:	0085171b          	slliw	a4,a0,0x8
    80006384:	0c0027b7          	lui	a5,0xc002
    80006388:	97ba                	add	a5,a5,a4
    8000638a:	40200713          	li	a4,1026
    8000638e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006392:	00d5151b          	slliw	a0,a0,0xd
    80006396:	0c2017b7          	lui	a5,0xc201
    8000639a:	953e                	add	a0,a0,a5
    8000639c:	00052023          	sw	zero,0(a0)
}
    800063a0:	60a2                	ld	ra,8(sp)
    800063a2:	6402                	ld	s0,0(sp)
    800063a4:	0141                	addi	sp,sp,16
    800063a6:	8082                	ret

00000000800063a8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800063a8:	1141                	addi	sp,sp,-16
    800063aa:	e406                	sd	ra,8(sp)
    800063ac:	e022                	sd	s0,0(sp)
    800063ae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800063b0:	ffffc097          	auipc	ra,0xffffc
    800063b4:	8d2080e7          	jalr	-1838(ra) # 80001c82 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800063b8:	00d5179b          	slliw	a5,a0,0xd
    800063bc:	0c201537          	lui	a0,0xc201
    800063c0:	953e                	add	a0,a0,a5
  return irq;
}
    800063c2:	4148                	lw	a0,4(a0)
    800063c4:	60a2                	ld	ra,8(sp)
    800063c6:	6402                	ld	s0,0(sp)
    800063c8:	0141                	addi	sp,sp,16
    800063ca:	8082                	ret

00000000800063cc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800063cc:	1101                	addi	sp,sp,-32
    800063ce:	ec06                	sd	ra,24(sp)
    800063d0:	e822                	sd	s0,16(sp)
    800063d2:	e426                	sd	s1,8(sp)
    800063d4:	1000                	addi	s0,sp,32
    800063d6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800063d8:	ffffc097          	auipc	ra,0xffffc
    800063dc:	8aa080e7          	jalr	-1878(ra) # 80001c82 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800063e0:	00d5151b          	slliw	a0,a0,0xd
    800063e4:	0c2017b7          	lui	a5,0xc201
    800063e8:	97aa                	add	a5,a5,a0
    800063ea:	c3c4                	sw	s1,4(a5)
}
    800063ec:	60e2                	ld	ra,24(sp)
    800063ee:	6442                	ld	s0,16(sp)
    800063f0:	64a2                	ld	s1,8(sp)
    800063f2:	6105                	addi	sp,sp,32
    800063f4:	8082                	ret

00000000800063f6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800063f6:	1141                	addi	sp,sp,-16
    800063f8:	e406                	sd	ra,8(sp)
    800063fa:	e022                	sd	s0,0(sp)
    800063fc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800063fe:	479d                	li	a5,7
    80006400:	06a7c963          	blt	a5,a0,80006472 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006404:	0001d797          	auipc	a5,0x1d
    80006408:	bfc78793          	addi	a5,a5,-1028 # 80023000 <disk>
    8000640c:	00a78733          	add	a4,a5,a0
    80006410:	6789                	lui	a5,0x2
    80006412:	97ba                	add	a5,a5,a4
    80006414:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006418:	e7ad                	bnez	a5,80006482 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000641a:	00451793          	slli	a5,a0,0x4
    8000641e:	0001f717          	auipc	a4,0x1f
    80006422:	be270713          	addi	a4,a4,-1054 # 80025000 <disk+0x2000>
    80006426:	6314                	ld	a3,0(a4)
    80006428:	96be                	add	a3,a3,a5
    8000642a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000642e:	6314                	ld	a3,0(a4)
    80006430:	96be                	add	a3,a3,a5
    80006432:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006436:	6314                	ld	a3,0(a4)
    80006438:	96be                	add	a3,a3,a5
    8000643a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000643e:	6318                	ld	a4,0(a4)
    80006440:	97ba                	add	a5,a5,a4
    80006442:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006446:	0001d797          	auipc	a5,0x1d
    8000644a:	bba78793          	addi	a5,a5,-1094 # 80023000 <disk>
    8000644e:	97aa                	add	a5,a5,a0
    80006450:	6509                	lui	a0,0x2
    80006452:	953e                	add	a0,a0,a5
    80006454:	4785                	li	a5,1
    80006456:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000645a:	0001f517          	auipc	a0,0x1f
    8000645e:	bbe50513          	addi	a0,a0,-1090 # 80025018 <disk+0x2018>
    80006462:	ffffc097          	auipc	ra,0xffffc
    80006466:	3d8080e7          	jalr	984(ra) # 8000283a <wakeup>
}
    8000646a:	60a2                	ld	ra,8(sp)
    8000646c:	6402                	ld	s0,0(sp)
    8000646e:	0141                	addi	sp,sp,16
    80006470:	8082                	ret
    panic("free_desc 1");
    80006472:	00002517          	auipc	a0,0x2
    80006476:	30e50513          	addi	a0,a0,782 # 80008780 <syscalls+0x338>
    8000647a:	ffffa097          	auipc	ra,0xffffa
    8000647e:	0c4080e7          	jalr	196(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006482:	00002517          	auipc	a0,0x2
    80006486:	30e50513          	addi	a0,a0,782 # 80008790 <syscalls+0x348>
    8000648a:	ffffa097          	auipc	ra,0xffffa
    8000648e:	0b4080e7          	jalr	180(ra) # 8000053e <panic>

0000000080006492 <virtio_disk_init>:
{
    80006492:	1101                	addi	sp,sp,-32
    80006494:	ec06                	sd	ra,24(sp)
    80006496:	e822                	sd	s0,16(sp)
    80006498:	e426                	sd	s1,8(sp)
    8000649a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000649c:	00002597          	auipc	a1,0x2
    800064a0:	30458593          	addi	a1,a1,772 # 800087a0 <syscalls+0x358>
    800064a4:	0001f517          	auipc	a0,0x1f
    800064a8:	c8450513          	addi	a0,a0,-892 # 80025128 <disk+0x2128>
    800064ac:	ffffa097          	auipc	ra,0xffffa
    800064b0:	6a8080e7          	jalr	1704(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800064b4:	100017b7          	lui	a5,0x10001
    800064b8:	4398                	lw	a4,0(a5)
    800064ba:	2701                	sext.w	a4,a4
    800064bc:	747277b7          	lui	a5,0x74727
    800064c0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800064c4:	0ef71163          	bne	a4,a5,800065a6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800064c8:	100017b7          	lui	a5,0x10001
    800064cc:	43dc                	lw	a5,4(a5)
    800064ce:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800064d0:	4705                	li	a4,1
    800064d2:	0ce79a63          	bne	a5,a4,800065a6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800064d6:	100017b7          	lui	a5,0x10001
    800064da:	479c                	lw	a5,8(a5)
    800064dc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800064de:	4709                	li	a4,2
    800064e0:	0ce79363          	bne	a5,a4,800065a6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800064e4:	100017b7          	lui	a5,0x10001
    800064e8:	47d8                	lw	a4,12(a5)
    800064ea:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800064ec:	554d47b7          	lui	a5,0x554d4
    800064f0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800064f4:	0af71963          	bne	a4,a5,800065a6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800064f8:	100017b7          	lui	a5,0x10001
    800064fc:	4705                	li	a4,1
    800064fe:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006500:	470d                	li	a4,3
    80006502:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006504:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006506:	c7ffe737          	lui	a4,0xc7ffe
    8000650a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000650e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006510:	2701                	sext.w	a4,a4
    80006512:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006514:	472d                	li	a4,11
    80006516:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006518:	473d                	li	a4,15
    8000651a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000651c:	6705                	lui	a4,0x1
    8000651e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006520:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006524:	5bdc                	lw	a5,52(a5)
    80006526:	2781                	sext.w	a5,a5
  if(max == 0)
    80006528:	c7d9                	beqz	a5,800065b6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000652a:	471d                	li	a4,7
    8000652c:	08f77d63          	bgeu	a4,a5,800065c6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006530:	100014b7          	lui	s1,0x10001
    80006534:	47a1                	li	a5,8
    80006536:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006538:	6609                	lui	a2,0x2
    8000653a:	4581                	li	a1,0
    8000653c:	0001d517          	auipc	a0,0x1d
    80006540:	ac450513          	addi	a0,a0,-1340 # 80023000 <disk>
    80006544:	ffffa097          	auipc	ra,0xffffa
    80006548:	79c080e7          	jalr	1948(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000654c:	0001d717          	auipc	a4,0x1d
    80006550:	ab470713          	addi	a4,a4,-1356 # 80023000 <disk>
    80006554:	00c75793          	srli	a5,a4,0xc
    80006558:	2781                	sext.w	a5,a5
    8000655a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000655c:	0001f797          	auipc	a5,0x1f
    80006560:	aa478793          	addi	a5,a5,-1372 # 80025000 <disk+0x2000>
    80006564:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006566:	0001d717          	auipc	a4,0x1d
    8000656a:	b1a70713          	addi	a4,a4,-1254 # 80023080 <disk+0x80>
    8000656e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006570:	0001e717          	auipc	a4,0x1e
    80006574:	a9070713          	addi	a4,a4,-1392 # 80024000 <disk+0x1000>
    80006578:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000657a:	4705                	li	a4,1
    8000657c:	00e78c23          	sb	a4,24(a5)
    80006580:	00e78ca3          	sb	a4,25(a5)
    80006584:	00e78d23          	sb	a4,26(a5)
    80006588:	00e78da3          	sb	a4,27(a5)
    8000658c:	00e78e23          	sb	a4,28(a5)
    80006590:	00e78ea3          	sb	a4,29(a5)
    80006594:	00e78f23          	sb	a4,30(a5)
    80006598:	00e78fa3          	sb	a4,31(a5)
}
    8000659c:	60e2                	ld	ra,24(sp)
    8000659e:	6442                	ld	s0,16(sp)
    800065a0:	64a2                	ld	s1,8(sp)
    800065a2:	6105                	addi	sp,sp,32
    800065a4:	8082                	ret
    panic("could not find virtio disk");
    800065a6:	00002517          	auipc	a0,0x2
    800065aa:	20a50513          	addi	a0,a0,522 # 800087b0 <syscalls+0x368>
    800065ae:	ffffa097          	auipc	ra,0xffffa
    800065b2:	f90080e7          	jalr	-112(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800065b6:	00002517          	auipc	a0,0x2
    800065ba:	21a50513          	addi	a0,a0,538 # 800087d0 <syscalls+0x388>
    800065be:	ffffa097          	auipc	ra,0xffffa
    800065c2:	f80080e7          	jalr	-128(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800065c6:	00002517          	auipc	a0,0x2
    800065ca:	22a50513          	addi	a0,a0,554 # 800087f0 <syscalls+0x3a8>
    800065ce:	ffffa097          	auipc	ra,0xffffa
    800065d2:	f70080e7          	jalr	-144(ra) # 8000053e <panic>

00000000800065d6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800065d6:	7159                	addi	sp,sp,-112
    800065d8:	f486                	sd	ra,104(sp)
    800065da:	f0a2                	sd	s0,96(sp)
    800065dc:	eca6                	sd	s1,88(sp)
    800065de:	e8ca                	sd	s2,80(sp)
    800065e0:	e4ce                	sd	s3,72(sp)
    800065e2:	e0d2                	sd	s4,64(sp)
    800065e4:	fc56                	sd	s5,56(sp)
    800065e6:	f85a                	sd	s6,48(sp)
    800065e8:	f45e                	sd	s7,40(sp)
    800065ea:	f062                	sd	s8,32(sp)
    800065ec:	ec66                	sd	s9,24(sp)
    800065ee:	e86a                	sd	s10,16(sp)
    800065f0:	1880                	addi	s0,sp,112
    800065f2:	892a                	mv	s2,a0
    800065f4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800065f6:	00c52c83          	lw	s9,12(a0)
    800065fa:	001c9c9b          	slliw	s9,s9,0x1
    800065fe:	1c82                	slli	s9,s9,0x20
    80006600:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006604:	0001f517          	auipc	a0,0x1f
    80006608:	b2450513          	addi	a0,a0,-1244 # 80025128 <disk+0x2128>
    8000660c:	ffffa097          	auipc	ra,0xffffa
    80006610:	5d8080e7          	jalr	1496(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006614:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006616:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006618:	0001db97          	auipc	s7,0x1d
    8000661c:	9e8b8b93          	addi	s7,s7,-1560 # 80023000 <disk>
    80006620:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006622:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006624:	8a4e                	mv	s4,s3
    80006626:	a051                	j	800066aa <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006628:	00fb86b3          	add	a3,s7,a5
    8000662c:	96da                	add	a3,a3,s6
    8000662e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006632:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006634:	0207c563          	bltz	a5,8000665e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006638:	2485                	addiw	s1,s1,1
    8000663a:	0711                	addi	a4,a4,4
    8000663c:	25548063          	beq	s1,s5,8000687c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006640:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006642:	0001f697          	auipc	a3,0x1f
    80006646:	9d668693          	addi	a3,a3,-1578 # 80025018 <disk+0x2018>
    8000664a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000664c:	0006c583          	lbu	a1,0(a3)
    80006650:	fde1                	bnez	a1,80006628 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006652:	2785                	addiw	a5,a5,1
    80006654:	0685                	addi	a3,a3,1
    80006656:	ff879be3          	bne	a5,s8,8000664c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000665a:	57fd                	li	a5,-1
    8000665c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000665e:	02905a63          	blez	s1,80006692 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006662:	f9042503          	lw	a0,-112(s0)
    80006666:	00000097          	auipc	ra,0x0
    8000666a:	d90080e7          	jalr	-624(ra) # 800063f6 <free_desc>
      for(int j = 0; j < i; j++)
    8000666e:	4785                	li	a5,1
    80006670:	0297d163          	bge	a5,s1,80006692 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006674:	f9442503          	lw	a0,-108(s0)
    80006678:	00000097          	auipc	ra,0x0
    8000667c:	d7e080e7          	jalr	-642(ra) # 800063f6 <free_desc>
      for(int j = 0; j < i; j++)
    80006680:	4789                	li	a5,2
    80006682:	0097d863          	bge	a5,s1,80006692 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006686:	f9842503          	lw	a0,-104(s0)
    8000668a:	00000097          	auipc	ra,0x0
    8000668e:	d6c080e7          	jalr	-660(ra) # 800063f6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006692:	0001f597          	auipc	a1,0x1f
    80006696:	a9658593          	addi	a1,a1,-1386 # 80025128 <disk+0x2128>
    8000669a:	0001f517          	auipc	a0,0x1f
    8000669e:	97e50513          	addi	a0,a0,-1666 # 80025018 <disk+0x2018>
    800066a2:	ffffc097          	auipc	ra,0xffffc
    800066a6:	f9c080e7          	jalr	-100(ra) # 8000263e <sleep>
  for(int i = 0; i < 3; i++){
    800066aa:	f9040713          	addi	a4,s0,-112
    800066ae:	84ce                	mv	s1,s3
    800066b0:	bf41                	j	80006640 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800066b2:	20058713          	addi	a4,a1,512
    800066b6:	00471693          	slli	a3,a4,0x4
    800066ba:	0001d717          	auipc	a4,0x1d
    800066be:	94670713          	addi	a4,a4,-1722 # 80023000 <disk>
    800066c2:	9736                	add	a4,a4,a3
    800066c4:	4685                	li	a3,1
    800066c6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800066ca:	20058713          	addi	a4,a1,512
    800066ce:	00471693          	slli	a3,a4,0x4
    800066d2:	0001d717          	auipc	a4,0x1d
    800066d6:	92e70713          	addi	a4,a4,-1746 # 80023000 <disk>
    800066da:	9736                	add	a4,a4,a3
    800066dc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800066e0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800066e4:	7679                	lui	a2,0xffffe
    800066e6:	963e                	add	a2,a2,a5
    800066e8:	0001f697          	auipc	a3,0x1f
    800066ec:	91868693          	addi	a3,a3,-1768 # 80025000 <disk+0x2000>
    800066f0:	6298                	ld	a4,0(a3)
    800066f2:	9732                	add	a4,a4,a2
    800066f4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800066f6:	6298                	ld	a4,0(a3)
    800066f8:	9732                	add	a4,a4,a2
    800066fa:	4541                	li	a0,16
    800066fc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800066fe:	6298                	ld	a4,0(a3)
    80006700:	9732                	add	a4,a4,a2
    80006702:	4505                	li	a0,1
    80006704:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006708:	f9442703          	lw	a4,-108(s0)
    8000670c:	6288                	ld	a0,0(a3)
    8000670e:	962a                	add	a2,a2,a0
    80006710:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006714:	0712                	slli	a4,a4,0x4
    80006716:	6290                	ld	a2,0(a3)
    80006718:	963a                	add	a2,a2,a4
    8000671a:	05890513          	addi	a0,s2,88
    8000671e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006720:	6294                	ld	a3,0(a3)
    80006722:	96ba                	add	a3,a3,a4
    80006724:	40000613          	li	a2,1024
    80006728:	c690                	sw	a2,8(a3)
  if(write)
    8000672a:	140d0063          	beqz	s10,8000686a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000672e:	0001f697          	auipc	a3,0x1f
    80006732:	8d26b683          	ld	a3,-1838(a3) # 80025000 <disk+0x2000>
    80006736:	96ba                	add	a3,a3,a4
    80006738:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000673c:	0001d817          	auipc	a6,0x1d
    80006740:	8c480813          	addi	a6,a6,-1852 # 80023000 <disk>
    80006744:	0001f517          	auipc	a0,0x1f
    80006748:	8bc50513          	addi	a0,a0,-1860 # 80025000 <disk+0x2000>
    8000674c:	6114                	ld	a3,0(a0)
    8000674e:	96ba                	add	a3,a3,a4
    80006750:	00c6d603          	lhu	a2,12(a3)
    80006754:	00166613          	ori	a2,a2,1
    80006758:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000675c:	f9842683          	lw	a3,-104(s0)
    80006760:	6110                	ld	a2,0(a0)
    80006762:	9732                	add	a4,a4,a2
    80006764:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006768:	20058613          	addi	a2,a1,512
    8000676c:	0612                	slli	a2,a2,0x4
    8000676e:	9642                	add	a2,a2,a6
    80006770:	577d                	li	a4,-1
    80006772:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006776:	00469713          	slli	a4,a3,0x4
    8000677a:	6114                	ld	a3,0(a0)
    8000677c:	96ba                	add	a3,a3,a4
    8000677e:	03078793          	addi	a5,a5,48
    80006782:	97c2                	add	a5,a5,a6
    80006784:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006786:	611c                	ld	a5,0(a0)
    80006788:	97ba                	add	a5,a5,a4
    8000678a:	4685                	li	a3,1
    8000678c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000678e:	611c                	ld	a5,0(a0)
    80006790:	97ba                	add	a5,a5,a4
    80006792:	4809                	li	a6,2
    80006794:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006798:	611c                	ld	a5,0(a0)
    8000679a:	973e                	add	a4,a4,a5
    8000679c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800067a0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800067a4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800067a8:	6518                	ld	a4,8(a0)
    800067aa:	00275783          	lhu	a5,2(a4)
    800067ae:	8b9d                	andi	a5,a5,7
    800067b0:	0786                	slli	a5,a5,0x1
    800067b2:	97ba                	add	a5,a5,a4
    800067b4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800067b8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800067bc:	6518                	ld	a4,8(a0)
    800067be:	00275783          	lhu	a5,2(a4)
    800067c2:	2785                	addiw	a5,a5,1
    800067c4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800067c8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800067cc:	100017b7          	lui	a5,0x10001
    800067d0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800067d4:	00492703          	lw	a4,4(s2)
    800067d8:	4785                	li	a5,1
    800067da:	02f71163          	bne	a4,a5,800067fc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800067de:	0001f997          	auipc	s3,0x1f
    800067e2:	94a98993          	addi	s3,s3,-1718 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800067e6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800067e8:	85ce                	mv	a1,s3
    800067ea:	854a                	mv	a0,s2
    800067ec:	ffffc097          	auipc	ra,0xffffc
    800067f0:	e52080e7          	jalr	-430(ra) # 8000263e <sleep>
  while(b->disk == 1) {
    800067f4:	00492783          	lw	a5,4(s2)
    800067f8:	fe9788e3          	beq	a5,s1,800067e8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800067fc:	f9042903          	lw	s2,-112(s0)
    80006800:	20090793          	addi	a5,s2,512
    80006804:	00479713          	slli	a4,a5,0x4
    80006808:	0001c797          	auipc	a5,0x1c
    8000680c:	7f878793          	addi	a5,a5,2040 # 80023000 <disk>
    80006810:	97ba                	add	a5,a5,a4
    80006812:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006816:	0001e997          	auipc	s3,0x1e
    8000681a:	7ea98993          	addi	s3,s3,2026 # 80025000 <disk+0x2000>
    8000681e:	00491713          	slli	a4,s2,0x4
    80006822:	0009b783          	ld	a5,0(s3)
    80006826:	97ba                	add	a5,a5,a4
    80006828:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000682c:	854a                	mv	a0,s2
    8000682e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006832:	00000097          	auipc	ra,0x0
    80006836:	bc4080e7          	jalr	-1084(ra) # 800063f6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000683a:	8885                	andi	s1,s1,1
    8000683c:	f0ed                	bnez	s1,8000681e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000683e:	0001f517          	auipc	a0,0x1f
    80006842:	8ea50513          	addi	a0,a0,-1814 # 80025128 <disk+0x2128>
    80006846:	ffffa097          	auipc	ra,0xffffa
    8000684a:	452080e7          	jalr	1106(ra) # 80000c98 <release>
}
    8000684e:	70a6                	ld	ra,104(sp)
    80006850:	7406                	ld	s0,96(sp)
    80006852:	64e6                	ld	s1,88(sp)
    80006854:	6946                	ld	s2,80(sp)
    80006856:	69a6                	ld	s3,72(sp)
    80006858:	6a06                	ld	s4,64(sp)
    8000685a:	7ae2                	ld	s5,56(sp)
    8000685c:	7b42                	ld	s6,48(sp)
    8000685e:	7ba2                	ld	s7,40(sp)
    80006860:	7c02                	ld	s8,32(sp)
    80006862:	6ce2                	ld	s9,24(sp)
    80006864:	6d42                	ld	s10,16(sp)
    80006866:	6165                	addi	sp,sp,112
    80006868:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000686a:	0001e697          	auipc	a3,0x1e
    8000686e:	7966b683          	ld	a3,1942(a3) # 80025000 <disk+0x2000>
    80006872:	96ba                	add	a3,a3,a4
    80006874:	4609                	li	a2,2
    80006876:	00c69623          	sh	a2,12(a3)
    8000687a:	b5c9                	j	8000673c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000687c:	f9042583          	lw	a1,-112(s0)
    80006880:	20058793          	addi	a5,a1,512
    80006884:	0792                	slli	a5,a5,0x4
    80006886:	0001d517          	auipc	a0,0x1d
    8000688a:	82250513          	addi	a0,a0,-2014 # 800230a8 <disk+0xa8>
    8000688e:	953e                	add	a0,a0,a5
  if(write)
    80006890:	e20d11e3          	bnez	s10,800066b2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006894:	20058713          	addi	a4,a1,512
    80006898:	00471693          	slli	a3,a4,0x4
    8000689c:	0001c717          	auipc	a4,0x1c
    800068a0:	76470713          	addi	a4,a4,1892 # 80023000 <disk>
    800068a4:	9736                	add	a4,a4,a3
    800068a6:	0a072423          	sw	zero,168(a4)
    800068aa:	b505                	j	800066ca <virtio_disk_rw+0xf4>

00000000800068ac <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800068ac:	1101                	addi	sp,sp,-32
    800068ae:	ec06                	sd	ra,24(sp)
    800068b0:	e822                	sd	s0,16(sp)
    800068b2:	e426                	sd	s1,8(sp)
    800068b4:	e04a                	sd	s2,0(sp)
    800068b6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800068b8:	0001f517          	auipc	a0,0x1f
    800068bc:	87050513          	addi	a0,a0,-1936 # 80025128 <disk+0x2128>
    800068c0:	ffffa097          	auipc	ra,0xffffa
    800068c4:	324080e7          	jalr	804(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800068c8:	10001737          	lui	a4,0x10001
    800068cc:	533c                	lw	a5,96(a4)
    800068ce:	8b8d                	andi	a5,a5,3
    800068d0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800068d2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800068d6:	0001e797          	auipc	a5,0x1e
    800068da:	72a78793          	addi	a5,a5,1834 # 80025000 <disk+0x2000>
    800068de:	6b94                	ld	a3,16(a5)
    800068e0:	0207d703          	lhu	a4,32(a5)
    800068e4:	0026d783          	lhu	a5,2(a3)
    800068e8:	06f70163          	beq	a4,a5,8000694a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800068ec:	0001c917          	auipc	s2,0x1c
    800068f0:	71490913          	addi	s2,s2,1812 # 80023000 <disk>
    800068f4:	0001e497          	auipc	s1,0x1e
    800068f8:	70c48493          	addi	s1,s1,1804 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800068fc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006900:	6898                	ld	a4,16(s1)
    80006902:	0204d783          	lhu	a5,32(s1)
    80006906:	8b9d                	andi	a5,a5,7
    80006908:	078e                	slli	a5,a5,0x3
    8000690a:	97ba                	add	a5,a5,a4
    8000690c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000690e:	20078713          	addi	a4,a5,512
    80006912:	0712                	slli	a4,a4,0x4
    80006914:	974a                	add	a4,a4,s2
    80006916:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000691a:	e731                	bnez	a4,80006966 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000691c:	20078793          	addi	a5,a5,512
    80006920:	0792                	slli	a5,a5,0x4
    80006922:	97ca                	add	a5,a5,s2
    80006924:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006926:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000692a:	ffffc097          	auipc	ra,0xffffc
    8000692e:	f10080e7          	jalr	-240(ra) # 8000283a <wakeup>

    disk.used_idx += 1;
    80006932:	0204d783          	lhu	a5,32(s1)
    80006936:	2785                	addiw	a5,a5,1
    80006938:	17c2                	slli	a5,a5,0x30
    8000693a:	93c1                	srli	a5,a5,0x30
    8000693c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006940:	6898                	ld	a4,16(s1)
    80006942:	00275703          	lhu	a4,2(a4)
    80006946:	faf71be3          	bne	a4,a5,800068fc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000694a:	0001e517          	auipc	a0,0x1e
    8000694e:	7de50513          	addi	a0,a0,2014 # 80025128 <disk+0x2128>
    80006952:	ffffa097          	auipc	ra,0xffffa
    80006956:	346080e7          	jalr	838(ra) # 80000c98 <release>
}
    8000695a:	60e2                	ld	ra,24(sp)
    8000695c:	6442                	ld	s0,16(sp)
    8000695e:	64a2                	ld	s1,8(sp)
    80006960:	6902                	ld	s2,0(sp)
    80006962:	6105                	addi	sp,sp,32
    80006964:	8082                	ret
      panic("virtio_disk_intr status");
    80006966:	00002517          	auipc	a0,0x2
    8000696a:	eaa50513          	addi	a0,a0,-342 # 80008810 <syscalls+0x3c8>
    8000696e:	ffffa097          	auipc	ra,0xffffa
    80006972:	bd0080e7          	jalr	-1072(ra) # 8000053e <panic>

0000000080006976 <cas>:
    80006976:	100522af          	lr.w	t0,(a0)
    8000697a:	00b29563          	bne	t0,a1,80006984 <fail>
    8000697e:	18c5252f          	sc.w	a0,a2,(a0)
    80006982:	8082                	ret

0000000080006984 <fail>:
    80006984:	4505                	li	a0,1
    80006986:	8082                	ret
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
