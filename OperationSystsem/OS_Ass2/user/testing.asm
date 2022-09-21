
user/_testing:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <part2>:
#include "kernel/riscv.h"



void
part2(int loop_size){
   0:	1141                	addi	sp,sp,-16
   2:	e422                	sd	s0,8(sp)
   4:	0800                	addi	s0,sp,16
    int pid = loop_size + 2;
    if(pid > 0){
        pid++;
    }
}
   6:	6422                	ld	s0,8(sp)
   8:	0141                	addi	sp,sp,16
   a:	8082                	ret

000000000000000c <linked_list>:

void
linked_list (int loop_size){}
   c:	1141                	addi	sp,sp,-16
   e:	e422                	sd	s0,8(sp)
  10:	0800                	addi	s0,sp,16
  12:	6422                	ld	s0,8(sp)
  14:	0141                	addi	sp,sp,16
  16:	8082                	ret

0000000000000018 <part3>:

void
part3 (int loop_size){
    int pid = -3;
    for(int i = 0; i < loop_size; i++){
  18:	0aa05363          	blez	a0,be <part3+0xa6>
part3 (int loop_size){
  1c:	7139                	addi	sp,sp,-64
  1e:	fc06                	sd	ra,56(sp)
  20:	f822                	sd	s0,48(sp)
  22:	f426                	sd	s1,40(sp)
  24:	f04a                	sd	s2,32(sp)
  26:	ec4e                	sd	s3,24(sp)
  28:	e852                	sd	s4,16(sp)
  2a:	e456                	sd	s5,8(sp)
  2c:	0080                	addi	s0,sp,64
  2e:	89aa                	mv	s3,a0
    for(int i = 0; i < loop_size; i++){
  30:	4901                	li	s2,0
            printf("Child's process\n");
            exit(0);
        }

        if(pid > 0){ // Parent
            printf("before wait\n");
  32:	00001a97          	auipc	s5,0x1
  36:	8f6a8a93          	addi	s5,s5,-1802 # 928 <malloc+0x114>
            wait(0);
            printf("Parent's process pid = %d\n", pid);
  3a:	00001a17          	auipc	s4,0x1
  3e:	8fea0a13          	addi	s4,s4,-1794 # 938 <malloc+0x124>
        pid = fork();
  42:	00000097          	auipc	ra,0x0
  46:	37c080e7          	jalr	892(ra) # 3be <fork>
  4a:	84aa                	mv	s1,a0
        if(pid < 0){
  4c:	02054f63          	bltz	a0,8a <part3+0x72>
        if(pid == 0 ){ // Child
  50:	c931                	beqz	a0,a4 <part3+0x8c>
            printf("before wait\n");
  52:	8556                	mv	a0,s5
  54:	00000097          	auipc	ra,0x0
  58:	702080e7          	jalr	1794(ra) # 756 <printf>
            wait(0);
  5c:	4501                	li	a0,0
  5e:	00000097          	auipc	ra,0x0
  62:	370080e7          	jalr	880(ra) # 3ce <wait>
            printf("Parent's process pid = %d\n", pid);
  66:	85a6                	mv	a1,s1
  68:	8552                	mv	a0,s4
  6a:	00000097          	auipc	ra,0x0
  6e:	6ec080e7          	jalr	1772(ra) # 756 <printf>
    for(int i = 0; i < loop_size; i++){
  72:	2905                	addiw	s2,s2,1
  74:	fd2997e3          	bne	s3,s2,42 <part3+0x2a>
        }
    }    
}
  78:	70e2                	ld	ra,56(sp)
  7a:	7442                	ld	s0,48(sp)
  7c:	74a2                	ld	s1,40(sp)
  7e:	7902                	ld	s2,32(sp)
  80:	69e2                	ld	s3,24(sp)
  82:	6a42                	ld	s4,16(sp)
  84:	6aa2                	ld	s5,8(sp)
  86:	6121                	addi	sp,sp,64
  88:	8082                	ret
            printf("part3: fork faild\n");
  8a:	00001517          	auipc	a0,0x1
  8e:	86e50513          	addi	a0,a0,-1938 # 8f8 <malloc+0xe4>
  92:	00000097          	auipc	ra,0x0
  96:	6c4080e7          	jalr	1732(ra) # 756 <printf>
            exit(1);
  9a:	4505                	li	a0,1
  9c:	00000097          	auipc	ra,0x0
  a0:	32a080e7          	jalr	810(ra) # 3c6 <exit>
            printf("Child's process\n");
  a4:	00001517          	auipc	a0,0x1
  a8:	86c50513          	addi	a0,a0,-1940 # 910 <malloc+0xfc>
  ac:	00000097          	auipc	ra,0x0
  b0:	6aa080e7          	jalr	1706(ra) # 756 <printf>
            exit(0);
  b4:	4501                	li	a0,0
  b6:	00000097          	auipc	ra,0x0
  ba:	310080e7          	jalr	784(ra) # 3c6 <exit>
  be:	8082                	ret

00000000000000c0 <main>:
    

int
main(int argc, char* argv[]){
  c0:	7179                	addi	sp,sp,-48
  c2:	f406                	sd	ra,40(sp)
  c4:	f022                	sd	s0,32(sp)
  c6:	ec26                	sd	s1,24(sp)
  c8:	e84a                	sd	s2,16(sp)
  ca:	e44e                	sd	s3,8(sp)
  cc:	1800                	addi	s0,sp,48
  ce:	84aa                	mv	s1,a0
  d0:	892e                	mv	s2,a1
    int loop_size = 1;
    if(argc > 0) printf("%s:\n", argv[0]);
  d2:	04a04463          	bgtz	a0,11a <main+0x5a>
    printf("Number of arguments passed : %d\n", argc);
  d6:	85a6                	mv	a1,s1
  d8:	00001517          	auipc	a0,0x1
  dc:	88850513          	addi	a0,a0,-1912 # 960 <malloc+0x14c>
  e0:	00000097          	auipc	ra,0x0
  e4:	676080e7          	jalr	1654(ra) # 756 <printf>
    if(argc == 2) {
  e8:	4789                	li	a5,2
    int loop_size = 1;
  ea:	4985                	li	s3,1
    if(argc == 2) {
  ec:	04f48163          	beq	s1,a5,12e <main+0x6e>
        loop_size = atoi(argv[1]);
        printf("argv = %d\n", loop_size);
    }
    part3(loop_size);
  f0:	854e                	mv	a0,s3
  f2:	00000097          	auipc	ra,0x0
  f6:	f26080e7          	jalr	-218(ra) # 18 <part3>
    printf("After part3\n");
  fa:	00001517          	auipc	a0,0x1
  fe:	89e50513          	addi	a0,a0,-1890 # 998 <malloc+0x184>
 102:	00000097          	auipc	ra,0x0
 106:	654080e7          	jalr	1620(ra) # 756 <printf>
    return 1;
 10a:	4505                	li	a0,1
 10c:	70a2                	ld	ra,40(sp)
 10e:	7402                	ld	s0,32(sp)
 110:	64e2                	ld	s1,24(sp)
 112:	6942                	ld	s2,16(sp)
 114:	69a2                	ld	s3,8(sp)
 116:	6145                	addi	sp,sp,48
 118:	8082                	ret
    if(argc > 0) printf("%s:\n", argv[0]);
 11a:	618c                	ld	a1,0(a1)
 11c:	00001517          	auipc	a0,0x1
 120:	83c50513          	addi	a0,a0,-1988 # 958 <malloc+0x144>
 124:	00000097          	auipc	ra,0x0
 128:	632080e7          	jalr	1586(ra) # 756 <printf>
 12c:	b76d                	j	d6 <main+0x16>
        loop_size = atoi(argv[1]);
 12e:	00893503          	ld	a0,8(s2)
 132:	00000097          	auipc	ra,0x0
 136:	194080e7          	jalr	404(ra) # 2c6 <atoi>
 13a:	89aa                	mv	s3,a0
        printf("argv = %d\n", loop_size);
 13c:	85aa                	mv	a1,a0
 13e:	00001517          	auipc	a0,0x1
 142:	84a50513          	addi	a0,a0,-1974 # 988 <malloc+0x174>
 146:	00000097          	auipc	ra,0x0
 14a:	610080e7          	jalr	1552(ra) # 756 <printf>
 14e:	b74d                	j	f0 <main+0x30>

0000000000000150 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 150:	1141                	addi	sp,sp,-16
 152:	e422                	sd	s0,8(sp)
 154:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 156:	87aa                	mv	a5,a0
 158:	0585                	addi	a1,a1,1
 15a:	0785                	addi	a5,a5,1
 15c:	fff5c703          	lbu	a4,-1(a1)
 160:	fee78fa3          	sb	a4,-1(a5)
 164:	fb75                	bnez	a4,158 <strcpy+0x8>
    ;
  return os;
}
 166:	6422                	ld	s0,8(sp)
 168:	0141                	addi	sp,sp,16
 16a:	8082                	ret

000000000000016c <strcmp>:

int
strcmp(const char *p, const char *q)
{
 16c:	1141                	addi	sp,sp,-16
 16e:	e422                	sd	s0,8(sp)
 170:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 172:	00054783          	lbu	a5,0(a0)
 176:	cb91                	beqz	a5,18a <strcmp+0x1e>
 178:	0005c703          	lbu	a4,0(a1)
 17c:	00f71763          	bne	a4,a5,18a <strcmp+0x1e>
    p++, q++;
 180:	0505                	addi	a0,a0,1
 182:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 184:	00054783          	lbu	a5,0(a0)
 188:	fbe5                	bnez	a5,178 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 18a:	0005c503          	lbu	a0,0(a1)
}
 18e:	40a7853b          	subw	a0,a5,a0
 192:	6422                	ld	s0,8(sp)
 194:	0141                	addi	sp,sp,16
 196:	8082                	ret

0000000000000198 <strlen>:

uint
strlen(const char *s)
{
 198:	1141                	addi	sp,sp,-16
 19a:	e422                	sd	s0,8(sp)
 19c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 19e:	00054783          	lbu	a5,0(a0)
 1a2:	cf91                	beqz	a5,1be <strlen+0x26>
 1a4:	0505                	addi	a0,a0,1
 1a6:	87aa                	mv	a5,a0
 1a8:	4685                	li	a3,1
 1aa:	9e89                	subw	a3,a3,a0
 1ac:	00f6853b          	addw	a0,a3,a5
 1b0:	0785                	addi	a5,a5,1
 1b2:	fff7c703          	lbu	a4,-1(a5)
 1b6:	fb7d                	bnez	a4,1ac <strlen+0x14>
    ;
  return n;
}
 1b8:	6422                	ld	s0,8(sp)
 1ba:	0141                	addi	sp,sp,16
 1bc:	8082                	ret
  for(n = 0; s[n]; n++)
 1be:	4501                	li	a0,0
 1c0:	bfe5                	j	1b8 <strlen+0x20>

00000000000001c2 <memset>:

void*
memset(void *dst, int c, uint n)
{
 1c2:	1141                	addi	sp,sp,-16
 1c4:	e422                	sd	s0,8(sp)
 1c6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 1c8:	ce09                	beqz	a2,1e2 <memset+0x20>
 1ca:	87aa                	mv	a5,a0
 1cc:	fff6071b          	addiw	a4,a2,-1
 1d0:	1702                	slli	a4,a4,0x20
 1d2:	9301                	srli	a4,a4,0x20
 1d4:	0705                	addi	a4,a4,1
 1d6:	972a                	add	a4,a4,a0
    cdst[i] = c;
 1d8:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 1dc:	0785                	addi	a5,a5,1
 1de:	fee79de3          	bne	a5,a4,1d8 <memset+0x16>
  }
  return dst;
}
 1e2:	6422                	ld	s0,8(sp)
 1e4:	0141                	addi	sp,sp,16
 1e6:	8082                	ret

00000000000001e8 <strchr>:

char*
strchr(const char *s, char c)
{
 1e8:	1141                	addi	sp,sp,-16
 1ea:	e422                	sd	s0,8(sp)
 1ec:	0800                	addi	s0,sp,16
  for(; *s; s++)
 1ee:	00054783          	lbu	a5,0(a0)
 1f2:	cb99                	beqz	a5,208 <strchr+0x20>
    if(*s == c)
 1f4:	00f58763          	beq	a1,a5,202 <strchr+0x1a>
  for(; *s; s++)
 1f8:	0505                	addi	a0,a0,1
 1fa:	00054783          	lbu	a5,0(a0)
 1fe:	fbfd                	bnez	a5,1f4 <strchr+0xc>
      return (char*)s;
  return 0;
 200:	4501                	li	a0,0
}
 202:	6422                	ld	s0,8(sp)
 204:	0141                	addi	sp,sp,16
 206:	8082                	ret
  return 0;
 208:	4501                	li	a0,0
 20a:	bfe5                	j	202 <strchr+0x1a>

000000000000020c <gets>:

char*
gets(char *buf, int max)
{
 20c:	711d                	addi	sp,sp,-96
 20e:	ec86                	sd	ra,88(sp)
 210:	e8a2                	sd	s0,80(sp)
 212:	e4a6                	sd	s1,72(sp)
 214:	e0ca                	sd	s2,64(sp)
 216:	fc4e                	sd	s3,56(sp)
 218:	f852                	sd	s4,48(sp)
 21a:	f456                	sd	s5,40(sp)
 21c:	f05a                	sd	s6,32(sp)
 21e:	ec5e                	sd	s7,24(sp)
 220:	1080                	addi	s0,sp,96
 222:	8baa                	mv	s7,a0
 224:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 226:	892a                	mv	s2,a0
 228:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 22a:	4aa9                	li	s5,10
 22c:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 22e:	89a6                	mv	s3,s1
 230:	2485                	addiw	s1,s1,1
 232:	0344d863          	bge	s1,s4,262 <gets+0x56>
    cc = read(0, &c, 1);
 236:	4605                	li	a2,1
 238:	faf40593          	addi	a1,s0,-81
 23c:	4501                	li	a0,0
 23e:	00000097          	auipc	ra,0x0
 242:	1a0080e7          	jalr	416(ra) # 3de <read>
    if(cc < 1)
 246:	00a05e63          	blez	a0,262 <gets+0x56>
    buf[i++] = c;
 24a:	faf44783          	lbu	a5,-81(s0)
 24e:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 252:	01578763          	beq	a5,s5,260 <gets+0x54>
 256:	0905                	addi	s2,s2,1
 258:	fd679be3          	bne	a5,s6,22e <gets+0x22>
  for(i=0; i+1 < max; ){
 25c:	89a6                	mv	s3,s1
 25e:	a011                	j	262 <gets+0x56>
 260:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 262:	99de                	add	s3,s3,s7
 264:	00098023          	sb	zero,0(s3)
  return buf;
}
 268:	855e                	mv	a0,s7
 26a:	60e6                	ld	ra,88(sp)
 26c:	6446                	ld	s0,80(sp)
 26e:	64a6                	ld	s1,72(sp)
 270:	6906                	ld	s2,64(sp)
 272:	79e2                	ld	s3,56(sp)
 274:	7a42                	ld	s4,48(sp)
 276:	7aa2                	ld	s5,40(sp)
 278:	7b02                	ld	s6,32(sp)
 27a:	6be2                	ld	s7,24(sp)
 27c:	6125                	addi	sp,sp,96
 27e:	8082                	ret

0000000000000280 <stat>:

int
stat(const char *n, struct stat *st)
{
 280:	1101                	addi	sp,sp,-32
 282:	ec06                	sd	ra,24(sp)
 284:	e822                	sd	s0,16(sp)
 286:	e426                	sd	s1,8(sp)
 288:	e04a                	sd	s2,0(sp)
 28a:	1000                	addi	s0,sp,32
 28c:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 28e:	4581                	li	a1,0
 290:	00000097          	auipc	ra,0x0
 294:	176080e7          	jalr	374(ra) # 406 <open>
  if(fd < 0)
 298:	02054563          	bltz	a0,2c2 <stat+0x42>
 29c:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 29e:	85ca                	mv	a1,s2
 2a0:	00000097          	auipc	ra,0x0
 2a4:	17e080e7          	jalr	382(ra) # 41e <fstat>
 2a8:	892a                	mv	s2,a0
  close(fd);
 2aa:	8526                	mv	a0,s1
 2ac:	00000097          	auipc	ra,0x0
 2b0:	142080e7          	jalr	322(ra) # 3ee <close>
  return r;
}
 2b4:	854a                	mv	a0,s2
 2b6:	60e2                	ld	ra,24(sp)
 2b8:	6442                	ld	s0,16(sp)
 2ba:	64a2                	ld	s1,8(sp)
 2bc:	6902                	ld	s2,0(sp)
 2be:	6105                	addi	sp,sp,32
 2c0:	8082                	ret
    return -1;
 2c2:	597d                	li	s2,-1
 2c4:	bfc5                	j	2b4 <stat+0x34>

00000000000002c6 <atoi>:

int
atoi(const char *s)
{
 2c6:	1141                	addi	sp,sp,-16
 2c8:	e422                	sd	s0,8(sp)
 2ca:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 2cc:	00054603          	lbu	a2,0(a0)
 2d0:	fd06079b          	addiw	a5,a2,-48
 2d4:	0ff7f793          	andi	a5,a5,255
 2d8:	4725                	li	a4,9
 2da:	02f76963          	bltu	a4,a5,30c <atoi+0x46>
 2de:	86aa                	mv	a3,a0
  n = 0;
 2e0:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 2e2:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 2e4:	0685                	addi	a3,a3,1
 2e6:	0025179b          	slliw	a5,a0,0x2
 2ea:	9fa9                	addw	a5,a5,a0
 2ec:	0017979b          	slliw	a5,a5,0x1
 2f0:	9fb1                	addw	a5,a5,a2
 2f2:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 2f6:	0006c603          	lbu	a2,0(a3)
 2fa:	fd06071b          	addiw	a4,a2,-48
 2fe:	0ff77713          	andi	a4,a4,255
 302:	fee5f1e3          	bgeu	a1,a4,2e4 <atoi+0x1e>
  return n;
}
 306:	6422                	ld	s0,8(sp)
 308:	0141                	addi	sp,sp,16
 30a:	8082                	ret
  n = 0;
 30c:	4501                	li	a0,0
 30e:	bfe5                	j	306 <atoi+0x40>

0000000000000310 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 310:	1141                	addi	sp,sp,-16
 312:	e422                	sd	s0,8(sp)
 314:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 316:	02b57663          	bgeu	a0,a1,342 <memmove+0x32>
    while(n-- > 0)
 31a:	02c05163          	blez	a2,33c <memmove+0x2c>
 31e:	fff6079b          	addiw	a5,a2,-1
 322:	1782                	slli	a5,a5,0x20
 324:	9381                	srli	a5,a5,0x20
 326:	0785                	addi	a5,a5,1
 328:	97aa                	add	a5,a5,a0
  dst = vdst;
 32a:	872a                	mv	a4,a0
      *dst++ = *src++;
 32c:	0585                	addi	a1,a1,1
 32e:	0705                	addi	a4,a4,1
 330:	fff5c683          	lbu	a3,-1(a1)
 334:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 338:	fee79ae3          	bne	a5,a4,32c <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 33c:	6422                	ld	s0,8(sp)
 33e:	0141                	addi	sp,sp,16
 340:	8082                	ret
    dst += n;
 342:	00c50733          	add	a4,a0,a2
    src += n;
 346:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 348:	fec05ae3          	blez	a2,33c <memmove+0x2c>
 34c:	fff6079b          	addiw	a5,a2,-1
 350:	1782                	slli	a5,a5,0x20
 352:	9381                	srli	a5,a5,0x20
 354:	fff7c793          	not	a5,a5
 358:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 35a:	15fd                	addi	a1,a1,-1
 35c:	177d                	addi	a4,a4,-1
 35e:	0005c683          	lbu	a3,0(a1)
 362:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 366:	fee79ae3          	bne	a5,a4,35a <memmove+0x4a>
 36a:	bfc9                	j	33c <memmove+0x2c>

000000000000036c <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 36c:	1141                	addi	sp,sp,-16
 36e:	e422                	sd	s0,8(sp)
 370:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 372:	ca05                	beqz	a2,3a2 <memcmp+0x36>
 374:	fff6069b          	addiw	a3,a2,-1
 378:	1682                	slli	a3,a3,0x20
 37a:	9281                	srli	a3,a3,0x20
 37c:	0685                	addi	a3,a3,1
 37e:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 380:	00054783          	lbu	a5,0(a0)
 384:	0005c703          	lbu	a4,0(a1)
 388:	00e79863          	bne	a5,a4,398 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 38c:	0505                	addi	a0,a0,1
    p2++;
 38e:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 390:	fed518e3          	bne	a0,a3,380 <memcmp+0x14>
  }
  return 0;
 394:	4501                	li	a0,0
 396:	a019                	j	39c <memcmp+0x30>
      return *p1 - *p2;
 398:	40e7853b          	subw	a0,a5,a4
}
 39c:	6422                	ld	s0,8(sp)
 39e:	0141                	addi	sp,sp,16
 3a0:	8082                	ret
  return 0;
 3a2:	4501                	li	a0,0
 3a4:	bfe5                	j	39c <memcmp+0x30>

00000000000003a6 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 3a6:	1141                	addi	sp,sp,-16
 3a8:	e406                	sd	ra,8(sp)
 3aa:	e022                	sd	s0,0(sp)
 3ac:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 3ae:	00000097          	auipc	ra,0x0
 3b2:	f62080e7          	jalr	-158(ra) # 310 <memmove>
}
 3b6:	60a2                	ld	ra,8(sp)
 3b8:	6402                	ld	s0,0(sp)
 3ba:	0141                	addi	sp,sp,16
 3bc:	8082                	ret

00000000000003be <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 3be:	4885                	li	a7,1
 ecall
 3c0:	00000073          	ecall
 ret
 3c4:	8082                	ret

00000000000003c6 <exit>:
.global exit
exit:
 li a7, SYS_exit
 3c6:	4889                	li	a7,2
 ecall
 3c8:	00000073          	ecall
 ret
 3cc:	8082                	ret

00000000000003ce <wait>:
.global wait
wait:
 li a7, SYS_wait
 3ce:	488d                	li	a7,3
 ecall
 3d0:	00000073          	ecall
 ret
 3d4:	8082                	ret

00000000000003d6 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 3d6:	4891                	li	a7,4
 ecall
 3d8:	00000073          	ecall
 ret
 3dc:	8082                	ret

00000000000003de <read>:
.global read
read:
 li a7, SYS_read
 3de:	4895                	li	a7,5
 ecall
 3e0:	00000073          	ecall
 ret
 3e4:	8082                	ret

00000000000003e6 <write>:
.global write
write:
 li a7, SYS_write
 3e6:	48c1                	li	a7,16
 ecall
 3e8:	00000073          	ecall
 ret
 3ec:	8082                	ret

00000000000003ee <close>:
.global close
close:
 li a7, SYS_close
 3ee:	48d5                	li	a7,21
 ecall
 3f0:	00000073          	ecall
 ret
 3f4:	8082                	ret

00000000000003f6 <kill>:
.global kill
kill:
 li a7, SYS_kill
 3f6:	4899                	li	a7,6
 ecall
 3f8:	00000073          	ecall
 ret
 3fc:	8082                	ret

00000000000003fe <exec>:
.global exec
exec:
 li a7, SYS_exec
 3fe:	489d                	li	a7,7
 ecall
 400:	00000073          	ecall
 ret
 404:	8082                	ret

0000000000000406 <open>:
.global open
open:
 li a7, SYS_open
 406:	48bd                	li	a7,15
 ecall
 408:	00000073          	ecall
 ret
 40c:	8082                	ret

000000000000040e <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 40e:	48c5                	li	a7,17
 ecall
 410:	00000073          	ecall
 ret
 414:	8082                	ret

0000000000000416 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 416:	48c9                	li	a7,18
 ecall
 418:	00000073          	ecall
 ret
 41c:	8082                	ret

000000000000041e <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 41e:	48a1                	li	a7,8
 ecall
 420:	00000073          	ecall
 ret
 424:	8082                	ret

0000000000000426 <link>:
.global link
link:
 li a7, SYS_link
 426:	48cd                	li	a7,19
 ecall
 428:	00000073          	ecall
 ret
 42c:	8082                	ret

000000000000042e <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 42e:	48d1                	li	a7,20
 ecall
 430:	00000073          	ecall
 ret
 434:	8082                	ret

0000000000000436 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 436:	48a5                	li	a7,9
 ecall
 438:	00000073          	ecall
 ret
 43c:	8082                	ret

000000000000043e <dup>:
.global dup
dup:
 li a7, SYS_dup
 43e:	48a9                	li	a7,10
 ecall
 440:	00000073          	ecall
 ret
 444:	8082                	ret

0000000000000446 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 446:	48ad                	li	a7,11
 ecall
 448:	00000073          	ecall
 ret
 44c:	8082                	ret

000000000000044e <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 44e:	48b1                	li	a7,12
 ecall
 450:	00000073          	ecall
 ret
 454:	8082                	ret

0000000000000456 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 456:	48b5                	li	a7,13
 ecall
 458:	00000073          	ecall
 ret
 45c:	8082                	ret

000000000000045e <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 45e:	48b9                	li	a7,14
 ecall
 460:	00000073          	ecall
 ret
 464:	8082                	ret

0000000000000466 <set_cpu>:
.global set_cpu
set_cpu:
 li a7, SYS_set_cpu
 466:	48d9                	li	a7,22
 ecall
 468:	00000073          	ecall
 ret
 46c:	8082                	ret

000000000000046e <get_cpu>:
.global get_cpu
get_cpu:
 li a7, SYS_get_cpu
 46e:	48dd                	li	a7,23
 ecall
 470:	00000073          	ecall
 ret
 474:	8082                	ret

0000000000000476 <cpu_process_count>:
.global cpu_process_count
cpu_process_count:
 li a7, SYS_cpu_process_count
 476:	48e1                	li	a7,24
 ecall
 478:	00000073          	ecall
 ret
 47c:	8082                	ret

000000000000047e <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 47e:	1101                	addi	sp,sp,-32
 480:	ec06                	sd	ra,24(sp)
 482:	e822                	sd	s0,16(sp)
 484:	1000                	addi	s0,sp,32
 486:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 48a:	4605                	li	a2,1
 48c:	fef40593          	addi	a1,s0,-17
 490:	00000097          	auipc	ra,0x0
 494:	f56080e7          	jalr	-170(ra) # 3e6 <write>
}
 498:	60e2                	ld	ra,24(sp)
 49a:	6442                	ld	s0,16(sp)
 49c:	6105                	addi	sp,sp,32
 49e:	8082                	ret

00000000000004a0 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 4a0:	7139                	addi	sp,sp,-64
 4a2:	fc06                	sd	ra,56(sp)
 4a4:	f822                	sd	s0,48(sp)
 4a6:	f426                	sd	s1,40(sp)
 4a8:	f04a                	sd	s2,32(sp)
 4aa:	ec4e                	sd	s3,24(sp)
 4ac:	0080                	addi	s0,sp,64
 4ae:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 4b0:	c299                	beqz	a3,4b6 <printint+0x16>
 4b2:	0805c863          	bltz	a1,542 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 4b6:	2581                	sext.w	a1,a1
  neg = 0;
 4b8:	4881                	li	a7,0
 4ba:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 4be:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 4c0:	2601                	sext.w	a2,a2
 4c2:	00000517          	auipc	a0,0x0
 4c6:	4ee50513          	addi	a0,a0,1262 # 9b0 <digits>
 4ca:	883a                	mv	a6,a4
 4cc:	2705                	addiw	a4,a4,1
 4ce:	02c5f7bb          	remuw	a5,a1,a2
 4d2:	1782                	slli	a5,a5,0x20
 4d4:	9381                	srli	a5,a5,0x20
 4d6:	97aa                	add	a5,a5,a0
 4d8:	0007c783          	lbu	a5,0(a5)
 4dc:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 4e0:	0005879b          	sext.w	a5,a1
 4e4:	02c5d5bb          	divuw	a1,a1,a2
 4e8:	0685                	addi	a3,a3,1
 4ea:	fec7f0e3          	bgeu	a5,a2,4ca <printint+0x2a>
  if(neg)
 4ee:	00088b63          	beqz	a7,504 <printint+0x64>
    buf[i++] = '-';
 4f2:	fd040793          	addi	a5,s0,-48
 4f6:	973e                	add	a4,a4,a5
 4f8:	02d00793          	li	a5,45
 4fc:	fef70823          	sb	a5,-16(a4)
 500:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 504:	02e05863          	blez	a4,534 <printint+0x94>
 508:	fc040793          	addi	a5,s0,-64
 50c:	00e78933          	add	s2,a5,a4
 510:	fff78993          	addi	s3,a5,-1
 514:	99ba                	add	s3,s3,a4
 516:	377d                	addiw	a4,a4,-1
 518:	1702                	slli	a4,a4,0x20
 51a:	9301                	srli	a4,a4,0x20
 51c:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 520:	fff94583          	lbu	a1,-1(s2)
 524:	8526                	mv	a0,s1
 526:	00000097          	auipc	ra,0x0
 52a:	f58080e7          	jalr	-168(ra) # 47e <putc>
  while(--i >= 0)
 52e:	197d                	addi	s2,s2,-1
 530:	ff3918e3          	bne	s2,s3,520 <printint+0x80>
}
 534:	70e2                	ld	ra,56(sp)
 536:	7442                	ld	s0,48(sp)
 538:	74a2                	ld	s1,40(sp)
 53a:	7902                	ld	s2,32(sp)
 53c:	69e2                	ld	s3,24(sp)
 53e:	6121                	addi	sp,sp,64
 540:	8082                	ret
    x = -xx;
 542:	40b005bb          	negw	a1,a1
    neg = 1;
 546:	4885                	li	a7,1
    x = -xx;
 548:	bf8d                	j	4ba <printint+0x1a>

000000000000054a <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 54a:	7119                	addi	sp,sp,-128
 54c:	fc86                	sd	ra,120(sp)
 54e:	f8a2                	sd	s0,112(sp)
 550:	f4a6                	sd	s1,104(sp)
 552:	f0ca                	sd	s2,96(sp)
 554:	ecce                	sd	s3,88(sp)
 556:	e8d2                	sd	s4,80(sp)
 558:	e4d6                	sd	s5,72(sp)
 55a:	e0da                	sd	s6,64(sp)
 55c:	fc5e                	sd	s7,56(sp)
 55e:	f862                	sd	s8,48(sp)
 560:	f466                	sd	s9,40(sp)
 562:	f06a                	sd	s10,32(sp)
 564:	ec6e                	sd	s11,24(sp)
 566:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 568:	0005c903          	lbu	s2,0(a1)
 56c:	18090f63          	beqz	s2,70a <vprintf+0x1c0>
 570:	8aaa                	mv	s5,a0
 572:	8b32                	mv	s6,a2
 574:	00158493          	addi	s1,a1,1
  state = 0;
 578:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 57a:	02500a13          	li	s4,37
      if(c == 'd'){
 57e:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 582:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 586:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 58a:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 58e:	00000b97          	auipc	s7,0x0
 592:	422b8b93          	addi	s7,s7,1058 # 9b0 <digits>
 596:	a839                	j	5b4 <vprintf+0x6a>
        putc(fd, c);
 598:	85ca                	mv	a1,s2
 59a:	8556                	mv	a0,s5
 59c:	00000097          	auipc	ra,0x0
 5a0:	ee2080e7          	jalr	-286(ra) # 47e <putc>
 5a4:	a019                	j	5aa <vprintf+0x60>
    } else if(state == '%'){
 5a6:	01498f63          	beq	s3,s4,5c4 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 5aa:	0485                	addi	s1,s1,1
 5ac:	fff4c903          	lbu	s2,-1(s1)
 5b0:	14090d63          	beqz	s2,70a <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 5b4:	0009079b          	sext.w	a5,s2
    if(state == 0){
 5b8:	fe0997e3          	bnez	s3,5a6 <vprintf+0x5c>
      if(c == '%'){
 5bc:	fd479ee3          	bne	a5,s4,598 <vprintf+0x4e>
        state = '%';
 5c0:	89be                	mv	s3,a5
 5c2:	b7e5                	j	5aa <vprintf+0x60>
      if(c == 'd'){
 5c4:	05878063          	beq	a5,s8,604 <vprintf+0xba>
      } else if(c == 'l') {
 5c8:	05978c63          	beq	a5,s9,620 <vprintf+0xd6>
      } else if(c == 'x') {
 5cc:	07a78863          	beq	a5,s10,63c <vprintf+0xf2>
      } else if(c == 'p') {
 5d0:	09b78463          	beq	a5,s11,658 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 5d4:	07300713          	li	a4,115
 5d8:	0ce78663          	beq	a5,a4,6a4 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 5dc:	06300713          	li	a4,99
 5e0:	0ee78e63          	beq	a5,a4,6dc <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 5e4:	11478863          	beq	a5,s4,6f4 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 5e8:	85d2                	mv	a1,s4
 5ea:	8556                	mv	a0,s5
 5ec:	00000097          	auipc	ra,0x0
 5f0:	e92080e7          	jalr	-366(ra) # 47e <putc>
        putc(fd, c);
 5f4:	85ca                	mv	a1,s2
 5f6:	8556                	mv	a0,s5
 5f8:	00000097          	auipc	ra,0x0
 5fc:	e86080e7          	jalr	-378(ra) # 47e <putc>
      }
      state = 0;
 600:	4981                	li	s3,0
 602:	b765                	j	5aa <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 604:	008b0913          	addi	s2,s6,8
 608:	4685                	li	a3,1
 60a:	4629                	li	a2,10
 60c:	000b2583          	lw	a1,0(s6)
 610:	8556                	mv	a0,s5
 612:	00000097          	auipc	ra,0x0
 616:	e8e080e7          	jalr	-370(ra) # 4a0 <printint>
 61a:	8b4a                	mv	s6,s2
      state = 0;
 61c:	4981                	li	s3,0
 61e:	b771                	j	5aa <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 620:	008b0913          	addi	s2,s6,8
 624:	4681                	li	a3,0
 626:	4629                	li	a2,10
 628:	000b2583          	lw	a1,0(s6)
 62c:	8556                	mv	a0,s5
 62e:	00000097          	auipc	ra,0x0
 632:	e72080e7          	jalr	-398(ra) # 4a0 <printint>
 636:	8b4a                	mv	s6,s2
      state = 0;
 638:	4981                	li	s3,0
 63a:	bf85                	j	5aa <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 63c:	008b0913          	addi	s2,s6,8
 640:	4681                	li	a3,0
 642:	4641                	li	a2,16
 644:	000b2583          	lw	a1,0(s6)
 648:	8556                	mv	a0,s5
 64a:	00000097          	auipc	ra,0x0
 64e:	e56080e7          	jalr	-426(ra) # 4a0 <printint>
 652:	8b4a                	mv	s6,s2
      state = 0;
 654:	4981                	li	s3,0
 656:	bf91                	j	5aa <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 658:	008b0793          	addi	a5,s6,8
 65c:	f8f43423          	sd	a5,-120(s0)
 660:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 664:	03000593          	li	a1,48
 668:	8556                	mv	a0,s5
 66a:	00000097          	auipc	ra,0x0
 66e:	e14080e7          	jalr	-492(ra) # 47e <putc>
  putc(fd, 'x');
 672:	85ea                	mv	a1,s10
 674:	8556                	mv	a0,s5
 676:	00000097          	auipc	ra,0x0
 67a:	e08080e7          	jalr	-504(ra) # 47e <putc>
 67e:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 680:	03c9d793          	srli	a5,s3,0x3c
 684:	97de                	add	a5,a5,s7
 686:	0007c583          	lbu	a1,0(a5)
 68a:	8556                	mv	a0,s5
 68c:	00000097          	auipc	ra,0x0
 690:	df2080e7          	jalr	-526(ra) # 47e <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 694:	0992                	slli	s3,s3,0x4
 696:	397d                	addiw	s2,s2,-1
 698:	fe0914e3          	bnez	s2,680 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 69c:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 6a0:	4981                	li	s3,0
 6a2:	b721                	j	5aa <vprintf+0x60>
        s = va_arg(ap, char*);
 6a4:	008b0993          	addi	s3,s6,8
 6a8:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 6ac:	02090163          	beqz	s2,6ce <vprintf+0x184>
        while(*s != 0){
 6b0:	00094583          	lbu	a1,0(s2)
 6b4:	c9a1                	beqz	a1,704 <vprintf+0x1ba>
          putc(fd, *s);
 6b6:	8556                	mv	a0,s5
 6b8:	00000097          	auipc	ra,0x0
 6bc:	dc6080e7          	jalr	-570(ra) # 47e <putc>
          s++;
 6c0:	0905                	addi	s2,s2,1
        while(*s != 0){
 6c2:	00094583          	lbu	a1,0(s2)
 6c6:	f9e5                	bnez	a1,6b6 <vprintf+0x16c>
        s = va_arg(ap, char*);
 6c8:	8b4e                	mv	s6,s3
      state = 0;
 6ca:	4981                	li	s3,0
 6cc:	bdf9                	j	5aa <vprintf+0x60>
          s = "(null)";
 6ce:	00000917          	auipc	s2,0x0
 6d2:	2da90913          	addi	s2,s2,730 # 9a8 <malloc+0x194>
        while(*s != 0){
 6d6:	02800593          	li	a1,40
 6da:	bff1                	j	6b6 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 6dc:	008b0913          	addi	s2,s6,8
 6e0:	000b4583          	lbu	a1,0(s6)
 6e4:	8556                	mv	a0,s5
 6e6:	00000097          	auipc	ra,0x0
 6ea:	d98080e7          	jalr	-616(ra) # 47e <putc>
 6ee:	8b4a                	mv	s6,s2
      state = 0;
 6f0:	4981                	li	s3,0
 6f2:	bd65                	j	5aa <vprintf+0x60>
        putc(fd, c);
 6f4:	85d2                	mv	a1,s4
 6f6:	8556                	mv	a0,s5
 6f8:	00000097          	auipc	ra,0x0
 6fc:	d86080e7          	jalr	-634(ra) # 47e <putc>
      state = 0;
 700:	4981                	li	s3,0
 702:	b565                	j	5aa <vprintf+0x60>
        s = va_arg(ap, char*);
 704:	8b4e                	mv	s6,s3
      state = 0;
 706:	4981                	li	s3,0
 708:	b54d                	j	5aa <vprintf+0x60>
    }
  }
}
 70a:	70e6                	ld	ra,120(sp)
 70c:	7446                	ld	s0,112(sp)
 70e:	74a6                	ld	s1,104(sp)
 710:	7906                	ld	s2,96(sp)
 712:	69e6                	ld	s3,88(sp)
 714:	6a46                	ld	s4,80(sp)
 716:	6aa6                	ld	s5,72(sp)
 718:	6b06                	ld	s6,64(sp)
 71a:	7be2                	ld	s7,56(sp)
 71c:	7c42                	ld	s8,48(sp)
 71e:	7ca2                	ld	s9,40(sp)
 720:	7d02                	ld	s10,32(sp)
 722:	6de2                	ld	s11,24(sp)
 724:	6109                	addi	sp,sp,128
 726:	8082                	ret

0000000000000728 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 728:	715d                	addi	sp,sp,-80
 72a:	ec06                	sd	ra,24(sp)
 72c:	e822                	sd	s0,16(sp)
 72e:	1000                	addi	s0,sp,32
 730:	e010                	sd	a2,0(s0)
 732:	e414                	sd	a3,8(s0)
 734:	e818                	sd	a4,16(s0)
 736:	ec1c                	sd	a5,24(s0)
 738:	03043023          	sd	a6,32(s0)
 73c:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 740:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 744:	8622                	mv	a2,s0
 746:	00000097          	auipc	ra,0x0
 74a:	e04080e7          	jalr	-508(ra) # 54a <vprintf>
}
 74e:	60e2                	ld	ra,24(sp)
 750:	6442                	ld	s0,16(sp)
 752:	6161                	addi	sp,sp,80
 754:	8082                	ret

0000000000000756 <printf>:

void
printf(const char *fmt, ...)
{
 756:	711d                	addi	sp,sp,-96
 758:	ec06                	sd	ra,24(sp)
 75a:	e822                	sd	s0,16(sp)
 75c:	1000                	addi	s0,sp,32
 75e:	e40c                	sd	a1,8(s0)
 760:	e810                	sd	a2,16(s0)
 762:	ec14                	sd	a3,24(s0)
 764:	f018                	sd	a4,32(s0)
 766:	f41c                	sd	a5,40(s0)
 768:	03043823          	sd	a6,48(s0)
 76c:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 770:	00840613          	addi	a2,s0,8
 774:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 778:	85aa                	mv	a1,a0
 77a:	4505                	li	a0,1
 77c:	00000097          	auipc	ra,0x0
 780:	dce080e7          	jalr	-562(ra) # 54a <vprintf>
}
 784:	60e2                	ld	ra,24(sp)
 786:	6442                	ld	s0,16(sp)
 788:	6125                	addi	sp,sp,96
 78a:	8082                	ret

000000000000078c <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 78c:	1141                	addi	sp,sp,-16
 78e:	e422                	sd	s0,8(sp)
 790:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 792:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 796:	00000797          	auipc	a5,0x0
 79a:	2327b783          	ld	a5,562(a5) # 9c8 <freep>
 79e:	a805                	j	7ce <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 7a0:	4618                	lw	a4,8(a2)
 7a2:	9db9                	addw	a1,a1,a4
 7a4:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 7a8:	6398                	ld	a4,0(a5)
 7aa:	6318                	ld	a4,0(a4)
 7ac:	fee53823          	sd	a4,-16(a0)
 7b0:	a091                	j	7f4 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 7b2:	ff852703          	lw	a4,-8(a0)
 7b6:	9e39                	addw	a2,a2,a4
 7b8:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 7ba:	ff053703          	ld	a4,-16(a0)
 7be:	e398                	sd	a4,0(a5)
 7c0:	a099                	j	806 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 7c2:	6398                	ld	a4,0(a5)
 7c4:	00e7e463          	bltu	a5,a4,7cc <free+0x40>
 7c8:	00e6ea63          	bltu	a3,a4,7dc <free+0x50>
{
 7cc:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 7ce:	fed7fae3          	bgeu	a5,a3,7c2 <free+0x36>
 7d2:	6398                	ld	a4,0(a5)
 7d4:	00e6e463          	bltu	a3,a4,7dc <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 7d8:	fee7eae3          	bltu	a5,a4,7cc <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 7dc:	ff852583          	lw	a1,-8(a0)
 7e0:	6390                	ld	a2,0(a5)
 7e2:	02059713          	slli	a4,a1,0x20
 7e6:	9301                	srli	a4,a4,0x20
 7e8:	0712                	slli	a4,a4,0x4
 7ea:	9736                	add	a4,a4,a3
 7ec:	fae60ae3          	beq	a2,a4,7a0 <free+0x14>
    bp->s.ptr = p->s.ptr;
 7f0:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 7f4:	4790                	lw	a2,8(a5)
 7f6:	02061713          	slli	a4,a2,0x20
 7fa:	9301                	srli	a4,a4,0x20
 7fc:	0712                	slli	a4,a4,0x4
 7fe:	973e                	add	a4,a4,a5
 800:	fae689e3          	beq	a3,a4,7b2 <free+0x26>
  } else
    p->s.ptr = bp;
 804:	e394                	sd	a3,0(a5)
  freep = p;
 806:	00000717          	auipc	a4,0x0
 80a:	1cf73123          	sd	a5,450(a4) # 9c8 <freep>
}
 80e:	6422                	ld	s0,8(sp)
 810:	0141                	addi	sp,sp,16
 812:	8082                	ret

0000000000000814 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 814:	7139                	addi	sp,sp,-64
 816:	fc06                	sd	ra,56(sp)
 818:	f822                	sd	s0,48(sp)
 81a:	f426                	sd	s1,40(sp)
 81c:	f04a                	sd	s2,32(sp)
 81e:	ec4e                	sd	s3,24(sp)
 820:	e852                	sd	s4,16(sp)
 822:	e456                	sd	s5,8(sp)
 824:	e05a                	sd	s6,0(sp)
 826:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 828:	02051493          	slli	s1,a0,0x20
 82c:	9081                	srli	s1,s1,0x20
 82e:	04bd                	addi	s1,s1,15
 830:	8091                	srli	s1,s1,0x4
 832:	0014899b          	addiw	s3,s1,1
 836:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 838:	00000517          	auipc	a0,0x0
 83c:	19053503          	ld	a0,400(a0) # 9c8 <freep>
 840:	c515                	beqz	a0,86c <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 842:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 844:	4798                	lw	a4,8(a5)
 846:	02977f63          	bgeu	a4,s1,884 <malloc+0x70>
 84a:	8a4e                	mv	s4,s3
 84c:	0009871b          	sext.w	a4,s3
 850:	6685                	lui	a3,0x1
 852:	00d77363          	bgeu	a4,a3,858 <malloc+0x44>
 856:	6a05                	lui	s4,0x1
 858:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 85c:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 860:	00000917          	auipc	s2,0x0
 864:	16890913          	addi	s2,s2,360 # 9c8 <freep>
  if(p == (char*)-1)
 868:	5afd                	li	s5,-1
 86a:	a88d                	j	8dc <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 86c:	00000797          	auipc	a5,0x0
 870:	16478793          	addi	a5,a5,356 # 9d0 <base>
 874:	00000717          	auipc	a4,0x0
 878:	14f73a23          	sd	a5,340(a4) # 9c8 <freep>
 87c:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 87e:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 882:	b7e1                	j	84a <malloc+0x36>
      if(p->s.size == nunits)
 884:	02e48b63          	beq	s1,a4,8ba <malloc+0xa6>
        p->s.size -= nunits;
 888:	4137073b          	subw	a4,a4,s3
 88c:	c798                	sw	a4,8(a5)
        p += p->s.size;
 88e:	1702                	slli	a4,a4,0x20
 890:	9301                	srli	a4,a4,0x20
 892:	0712                	slli	a4,a4,0x4
 894:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 896:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 89a:	00000717          	auipc	a4,0x0
 89e:	12a73723          	sd	a0,302(a4) # 9c8 <freep>
      return (void*)(p + 1);
 8a2:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 8a6:	70e2                	ld	ra,56(sp)
 8a8:	7442                	ld	s0,48(sp)
 8aa:	74a2                	ld	s1,40(sp)
 8ac:	7902                	ld	s2,32(sp)
 8ae:	69e2                	ld	s3,24(sp)
 8b0:	6a42                	ld	s4,16(sp)
 8b2:	6aa2                	ld	s5,8(sp)
 8b4:	6b02                	ld	s6,0(sp)
 8b6:	6121                	addi	sp,sp,64
 8b8:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 8ba:	6398                	ld	a4,0(a5)
 8bc:	e118                	sd	a4,0(a0)
 8be:	bff1                	j	89a <malloc+0x86>
  hp->s.size = nu;
 8c0:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 8c4:	0541                	addi	a0,a0,16
 8c6:	00000097          	auipc	ra,0x0
 8ca:	ec6080e7          	jalr	-314(ra) # 78c <free>
  return freep;
 8ce:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 8d2:	d971                	beqz	a0,8a6 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 8d4:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 8d6:	4798                	lw	a4,8(a5)
 8d8:	fa9776e3          	bgeu	a4,s1,884 <malloc+0x70>
    if(p == freep)
 8dc:	00093703          	ld	a4,0(s2)
 8e0:	853e                	mv	a0,a5
 8e2:	fef719e3          	bne	a4,a5,8d4 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 8e6:	8552                	mv	a0,s4
 8e8:	00000097          	auipc	ra,0x0
 8ec:	b66080e7          	jalr	-1178(ra) # 44e <sbrk>
  if(p == (char*)-1)
 8f0:	fd5518e3          	bne	a0,s5,8c0 <malloc+0xac>
        return 0;
 8f4:	4501                	li	a0,0
 8f6:	bf45                	j	8a6 <malloc+0x92>
