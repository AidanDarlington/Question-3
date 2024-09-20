
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	18010113          	addi	sp,sp,384 # 80009180 <stack0>
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
    80000068:	c5c78793          	addi	a5,a5,-932 # 80005cc0 <timervec>
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
    800000b2:	dc478793          	addi	a5,a5,-572 # 80000e72 <main>
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
    80000130:	324080e7          	jalr	804(ra) # 80002450 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	77a080e7          	jalr	1914(ra) # 800008b6 <uartputc>
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
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	ff650513          	addi	a0,a0,-10 # 80011180 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a3e080e7          	jalr	-1474(ra) # 80000bd0 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	fe648493          	addi	s1,s1,-26 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	07690913          	addi	s2,s2,118 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305863          	blez	s3,80000220 <consoleread+0xbc>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71463          	bne	a4,a5,800001e4 <consoleread+0x80>
      if(myproc()->killed){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7d6080e7          	jalr	2006(ra) # 80001996 <myproc>
    800001c8:	551c                	lw	a5,40(a0)
    800001ca:	e7b5                	bnez	a5,80000236 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001cc:	85a6                	mv	a1,s1
    800001ce:	854a                	mv	a0,s2
    800001d0:	00002097          	auipc	ra,0x2
    800001d4:	e86080e7          	jalr	-378(ra) # 80002056 <sleep>
    while(cons.r == cons.w){
    800001d8:	0984a783          	lw	a5,152(s1)
    800001dc:	09c4a703          	lw	a4,156(s1)
    800001e0:	fef700e3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e4:	0017871b          	addiw	a4,a5,1
    800001e8:	08e4ac23          	sw	a4,152(s1)
    800001ec:	07f7f713          	andi	a4,a5,127
    800001f0:	9726                	add	a4,a4,s1
    800001f2:	01874703          	lbu	a4,24(a4)
    800001f6:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    800001fa:	077d0563          	beq	s10,s7,80000264 <consoleread+0x100>
    cbuf = c;
    800001fe:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000202:	4685                	li	a3,1
    80000204:	f9f40613          	addi	a2,s0,-97
    80000208:	85d2                	mv	a1,s4
    8000020a:	8556                	mv	a0,s5
    8000020c:	00002097          	auipc	ra,0x2
    80000210:	1ee080e7          	jalr	494(ra) # 800023fa <either_copyout>
    80000214:	01850663          	beq	a0,s8,80000220 <consoleread+0xbc>
    dst++;
    80000218:	0a05                	addi	s4,s4,1
    --n;
    8000021a:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    8000021c:	f99d1ae3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000220:	00011517          	auipc	a0,0x11
    80000224:	f6050513          	addi	a0,a0,-160 # 80011180 <cons>
    80000228:	00001097          	auipc	ra,0x1
    8000022c:	a5c080e7          	jalr	-1444(ra) # 80000c84 <release>

  return target - n;
    80000230:	413b053b          	subw	a0,s6,s3
    80000234:	a811                	j	80000248 <consoleread+0xe4>
        release(&cons.lock);
    80000236:	00011517          	auipc	a0,0x11
    8000023a:	f4a50513          	addi	a0,a0,-182 # 80011180 <cons>
    8000023e:	00001097          	auipc	ra,0x1
    80000242:	a46080e7          	jalr	-1466(ra) # 80000c84 <release>
        return -1;
    80000246:	557d                	li	a0,-1
}
    80000248:	70a6                	ld	ra,104(sp)
    8000024a:	7406                	ld	s0,96(sp)
    8000024c:	64e6                	ld	s1,88(sp)
    8000024e:	6946                	ld	s2,80(sp)
    80000250:	69a6                	ld	s3,72(sp)
    80000252:	6a06                	ld	s4,64(sp)
    80000254:	7ae2                	ld	s5,56(sp)
    80000256:	7b42                	ld	s6,48(sp)
    80000258:	7ba2                	ld	s7,40(sp)
    8000025a:	7c02                	ld	s8,32(sp)
    8000025c:	6ce2                	ld	s9,24(sp)
    8000025e:	6d42                	ld	s10,16(sp)
    80000260:	6165                	addi	sp,sp,112
    80000262:	8082                	ret
      if(n < target){
    80000264:	0009871b          	sext.w	a4,s3
    80000268:	fb677ce3          	bgeu	a4,s6,80000220 <consoleread+0xbc>
        cons.r--;
    8000026c:	00011717          	auipc	a4,0x11
    80000270:	faf72623          	sw	a5,-84(a4) # 80011218 <cons+0x98>
    80000274:	b775                	j	80000220 <consoleread+0xbc>

0000000080000276 <consputc>:
{
    80000276:	1141                	addi	sp,sp,-16
    80000278:	e406                	sd	ra,8(sp)
    8000027a:	e022                	sd	s0,0(sp)
    8000027c:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000027e:	10000793          	li	a5,256
    80000282:	00f50a63          	beq	a0,a5,80000296 <consputc+0x20>
    uartputc_sync(c);
    80000286:	00000097          	auipc	ra,0x0
    8000028a:	55e080e7          	jalr	1374(ra) # 800007e4 <uartputc_sync>
}
    8000028e:	60a2                	ld	ra,8(sp)
    80000290:	6402                	ld	s0,0(sp)
    80000292:	0141                	addi	sp,sp,16
    80000294:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000296:	4521                	li	a0,8
    80000298:	00000097          	auipc	ra,0x0
    8000029c:	54c080e7          	jalr	1356(ra) # 800007e4 <uartputc_sync>
    800002a0:	02000513          	li	a0,32
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	540080e7          	jalr	1344(ra) # 800007e4 <uartputc_sync>
    800002ac:	4521                	li	a0,8
    800002ae:	00000097          	auipc	ra,0x0
    800002b2:	536080e7          	jalr	1334(ra) # 800007e4 <uartputc_sync>
    800002b6:	bfe1                	j	8000028e <consputc+0x18>

00000000800002b8 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002b8:	1101                	addi	sp,sp,-32
    800002ba:	ec06                	sd	ra,24(sp)
    800002bc:	e822                	sd	s0,16(sp)
    800002be:	e426                	sd	s1,8(sp)
    800002c0:	e04a                	sd	s2,0(sp)
    800002c2:	1000                	addi	s0,sp,32
    800002c4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002c6:	00011517          	auipc	a0,0x11
    800002ca:	eba50513          	addi	a0,a0,-326 # 80011180 <cons>
    800002ce:	00001097          	auipc	ra,0x1
    800002d2:	902080e7          	jalr	-1790(ra) # 80000bd0 <acquire>

  switch(c){
    800002d6:	47d5                	li	a5,21
    800002d8:	0af48663          	beq	s1,a5,80000384 <consoleintr+0xcc>
    800002dc:	0297ca63          	blt	a5,s1,80000310 <consoleintr+0x58>
    800002e0:	47a1                	li	a5,8
    800002e2:	0ef48763          	beq	s1,a5,800003d0 <consoleintr+0x118>
    800002e6:	47c1                	li	a5,16
    800002e8:	10f49a63          	bne	s1,a5,800003fc <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002ec:	00002097          	auipc	ra,0x2
    800002f0:	1ba080e7          	jalr	442(ra) # 800024a6 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f4:	00011517          	auipc	a0,0x11
    800002f8:	e8c50513          	addi	a0,a0,-372 # 80011180 <cons>
    800002fc:	00001097          	auipc	ra,0x1
    80000300:	988080e7          	jalr	-1656(ra) # 80000c84 <release>
}
    80000304:	60e2                	ld	ra,24(sp)
    80000306:	6442                	ld	s0,16(sp)
    80000308:	64a2                	ld	s1,8(sp)
    8000030a:	6902                	ld	s2,0(sp)
    8000030c:	6105                	addi	sp,sp,32
    8000030e:	8082                	ret
  switch(c){
    80000310:	07f00793          	li	a5,127
    80000314:	0af48e63          	beq	s1,a5,800003d0 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000318:	00011717          	auipc	a4,0x11
    8000031c:	e6870713          	addi	a4,a4,-408 # 80011180 <cons>
    80000320:	0a072783          	lw	a5,160(a4)
    80000324:	09872703          	lw	a4,152(a4)
    80000328:	9f99                	subw	a5,a5,a4
    8000032a:	07f00713          	li	a4,127
    8000032e:	fcf763e3          	bltu	a4,a5,800002f4 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000332:	47b5                	li	a5,13
    80000334:	0cf48763          	beq	s1,a5,80000402 <consoleintr+0x14a>
      consputc(c);
    80000338:	8526                	mv	a0,s1
    8000033a:	00000097          	auipc	ra,0x0
    8000033e:	f3c080e7          	jalr	-196(ra) # 80000276 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000342:	00011797          	auipc	a5,0x11
    80000346:	e3e78793          	addi	a5,a5,-450 # 80011180 <cons>
    8000034a:	0a07a703          	lw	a4,160(a5)
    8000034e:	0017069b          	addiw	a3,a4,1
    80000352:	0006861b          	sext.w	a2,a3
    80000356:	0ad7a023          	sw	a3,160(a5)
    8000035a:	07f77713          	andi	a4,a4,127
    8000035e:	97ba                	add	a5,a5,a4
    80000360:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000364:	47a9                	li	a5,10
    80000366:	0cf48563          	beq	s1,a5,80000430 <consoleintr+0x178>
    8000036a:	4791                	li	a5,4
    8000036c:	0cf48263          	beq	s1,a5,80000430 <consoleintr+0x178>
    80000370:	00011797          	auipc	a5,0x11
    80000374:	ea87a783          	lw	a5,-344(a5) # 80011218 <cons+0x98>
    80000378:	0807879b          	addiw	a5,a5,128
    8000037c:	f6f61ce3          	bne	a2,a5,800002f4 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000380:	863e                	mv	a2,a5
    80000382:	a07d                	j	80000430 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000384:	00011717          	auipc	a4,0x11
    80000388:	dfc70713          	addi	a4,a4,-516 # 80011180 <cons>
    8000038c:	0a072783          	lw	a5,160(a4)
    80000390:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000394:	00011497          	auipc	s1,0x11
    80000398:	dec48493          	addi	s1,s1,-532 # 80011180 <cons>
    while(cons.e != cons.w &&
    8000039c:	4929                	li	s2,10
    8000039e:	f4f70be3          	beq	a4,a5,800002f4 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a2:	37fd                	addiw	a5,a5,-1
    800003a4:	07f7f713          	andi	a4,a5,127
    800003a8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003aa:	01874703          	lbu	a4,24(a4)
    800003ae:	f52703e3          	beq	a4,s2,800002f4 <consoleintr+0x3c>
      cons.e--;
    800003b2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003b6:	10000513          	li	a0,256
    800003ba:	00000097          	auipc	ra,0x0
    800003be:	ebc080e7          	jalr	-324(ra) # 80000276 <consputc>
    while(cons.e != cons.w &&
    800003c2:	0a04a783          	lw	a5,160(s1)
    800003c6:	09c4a703          	lw	a4,156(s1)
    800003ca:	fcf71ce3          	bne	a4,a5,800003a2 <consoleintr+0xea>
    800003ce:	b71d                	j	800002f4 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d0:	00011717          	auipc	a4,0x11
    800003d4:	db070713          	addi	a4,a4,-592 # 80011180 <cons>
    800003d8:	0a072783          	lw	a5,160(a4)
    800003dc:	09c72703          	lw	a4,156(a4)
    800003e0:	f0f70ae3          	beq	a4,a5,800002f4 <consoleintr+0x3c>
      cons.e--;
    800003e4:	37fd                	addiw	a5,a5,-1
    800003e6:	00011717          	auipc	a4,0x11
    800003ea:	e2f72d23          	sw	a5,-454(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003ee:	10000513          	li	a0,256
    800003f2:	00000097          	auipc	ra,0x0
    800003f6:	e84080e7          	jalr	-380(ra) # 80000276 <consputc>
    800003fa:	bded                	j	800002f4 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003fc:	ee048ce3          	beqz	s1,800002f4 <consoleintr+0x3c>
    80000400:	bf21                	j	80000318 <consoleintr+0x60>
      consputc(c);
    80000402:	4529                	li	a0,10
    80000404:	00000097          	auipc	ra,0x0
    80000408:	e72080e7          	jalr	-398(ra) # 80000276 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000040c:	00011797          	auipc	a5,0x11
    80000410:	d7478793          	addi	a5,a5,-652 # 80011180 <cons>
    80000414:	0a07a703          	lw	a4,160(a5)
    80000418:	0017069b          	addiw	a3,a4,1
    8000041c:	0006861b          	sext.w	a2,a3
    80000420:	0ad7a023          	sw	a3,160(a5)
    80000424:	07f77713          	andi	a4,a4,127
    80000428:	97ba                	add	a5,a5,a4
    8000042a:	4729                	li	a4,10
    8000042c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000430:	00011797          	auipc	a5,0x11
    80000434:	dec7a623          	sw	a2,-532(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    80000438:	00011517          	auipc	a0,0x11
    8000043c:	de050513          	addi	a0,a0,-544 # 80011218 <cons+0x98>
    80000440:	00002097          	auipc	ra,0x2
    80000444:	da2080e7          	jalr	-606(ra) # 800021e2 <wakeup>
    80000448:	b575                	j	800002f4 <consoleintr+0x3c>

000000008000044a <consoleinit>:

void
consoleinit(void)
{
    8000044a:	1141                	addi	sp,sp,-16
    8000044c:	e406                	sd	ra,8(sp)
    8000044e:	e022                	sd	s0,0(sp)
    80000450:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000452:	00008597          	auipc	a1,0x8
    80000456:	bbe58593          	addi	a1,a1,-1090 # 80008010 <etext+0x10>
    8000045a:	00011517          	auipc	a0,0x11
    8000045e:	d2650513          	addi	a0,a0,-730 # 80011180 <cons>
    80000462:	00000097          	auipc	ra,0x0
    80000466:	6de080e7          	jalr	1758(ra) # 80000b40 <initlock>

  uartinit();
    8000046a:	00000097          	auipc	ra,0x0
    8000046e:	32a080e7          	jalr	810(ra) # 80000794 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000472:	00021797          	auipc	a5,0x21
    80000476:	ea678793          	addi	a5,a5,-346 # 80021318 <devsw>
    8000047a:	00000717          	auipc	a4,0x0
    8000047e:	cea70713          	addi	a4,a4,-790 # 80000164 <consoleread>
    80000482:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000484:	00000717          	auipc	a4,0x0
    80000488:	c7e70713          	addi	a4,a4,-898 # 80000102 <consolewrite>
    8000048c:	ef98                	sd	a4,24(a5)
}
    8000048e:	60a2                	ld	ra,8(sp)
    80000490:	6402                	ld	s0,0(sp)
    80000492:	0141                	addi	sp,sp,16
    80000494:	8082                	ret

0000000080000496 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000496:	7179                	addi	sp,sp,-48
    80000498:	f406                	sd	ra,40(sp)
    8000049a:	f022                	sd	s0,32(sp)
    8000049c:	ec26                	sd	s1,24(sp)
    8000049e:	e84a                	sd	s2,16(sp)
    800004a0:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a2:	c219                	beqz	a2,800004a8 <printint+0x12>
    800004a4:	08054663          	bltz	a0,80000530 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004a8:	2501                	sext.w	a0,a0
    800004aa:	4881                	li	a7,0
    800004ac:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b2:	2581                	sext.w	a1,a1
    800004b4:	00008617          	auipc	a2,0x8
    800004b8:	b8c60613          	addi	a2,a2,-1140 # 80008040 <digits>
    800004bc:	883a                	mv	a6,a4
    800004be:	2705                	addiw	a4,a4,1
    800004c0:	02b577bb          	remuw	a5,a0,a1
    800004c4:	1782                	slli	a5,a5,0x20
    800004c6:	9381                	srli	a5,a5,0x20
    800004c8:	97b2                	add	a5,a5,a2
    800004ca:	0007c783          	lbu	a5,0(a5)
    800004ce:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d2:	0005079b          	sext.w	a5,a0
    800004d6:	02b5553b          	divuw	a0,a0,a1
    800004da:	0685                	addi	a3,a3,1
    800004dc:	feb7f0e3          	bgeu	a5,a1,800004bc <printint+0x26>

  if(sign)
    800004e0:	00088b63          	beqz	a7,800004f6 <printint+0x60>
    buf[i++] = '-';
    800004e4:	fe040793          	addi	a5,s0,-32
    800004e8:	973e                	add	a4,a4,a5
    800004ea:	02d00793          	li	a5,45
    800004ee:	fef70823          	sb	a5,-16(a4)
    800004f2:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004f6:	02e05763          	blez	a4,80000524 <printint+0x8e>
    800004fa:	fd040793          	addi	a5,s0,-48
    800004fe:	00e784b3          	add	s1,a5,a4
    80000502:	fff78913          	addi	s2,a5,-1
    80000506:	993a                	add	s2,s2,a4
    80000508:	377d                	addiw	a4,a4,-1
    8000050a:	1702                	slli	a4,a4,0x20
    8000050c:	9301                	srli	a4,a4,0x20
    8000050e:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000512:	fff4c503          	lbu	a0,-1(s1)
    80000516:	00000097          	auipc	ra,0x0
    8000051a:	d60080e7          	jalr	-672(ra) # 80000276 <consputc>
  while(--i >= 0)
    8000051e:	14fd                	addi	s1,s1,-1
    80000520:	ff2499e3          	bne	s1,s2,80000512 <printint+0x7c>
}
    80000524:	70a2                	ld	ra,40(sp)
    80000526:	7402                	ld	s0,32(sp)
    80000528:	64e2                	ld	s1,24(sp)
    8000052a:	6942                	ld	s2,16(sp)
    8000052c:	6145                	addi	sp,sp,48
    8000052e:	8082                	ret
    x = -xx;
    80000530:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000534:	4885                	li	a7,1
    x = -xx;
    80000536:	bf9d                	j	800004ac <printint+0x16>

0000000080000538 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000538:	1101                	addi	sp,sp,-32
    8000053a:	ec06                	sd	ra,24(sp)
    8000053c:	e822                	sd	s0,16(sp)
    8000053e:	e426                	sd	s1,8(sp)
    80000540:	1000                	addi	s0,sp,32
    80000542:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000544:	00011797          	auipc	a5,0x11
    80000548:	ce07ae23          	sw	zero,-772(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    8000054c:	00008517          	auipc	a0,0x8
    80000550:	acc50513          	addi	a0,a0,-1332 # 80008018 <etext+0x18>
    80000554:	00000097          	auipc	ra,0x0
    80000558:	02e080e7          	jalr	46(ra) # 80000582 <printf>
  printf(s);
    8000055c:	8526                	mv	a0,s1
    8000055e:	00000097          	auipc	ra,0x0
    80000562:	024080e7          	jalr	36(ra) # 80000582 <printf>
  printf("\n");
    80000566:	00008517          	auipc	a0,0x8
    8000056a:	b6250513          	addi	a0,a0,-1182 # 800080c8 <digits+0x88>
    8000056e:	00000097          	auipc	ra,0x0
    80000572:	014080e7          	jalr	20(ra) # 80000582 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000576:	4785                	li	a5,1
    80000578:	00009717          	auipc	a4,0x9
    8000057c:	a8f72423          	sw	a5,-1400(a4) # 80009000 <panicked>
  for(;;)
    80000580:	a001                	j	80000580 <panic+0x48>

0000000080000582 <printf>:
{
    80000582:	7131                	addi	sp,sp,-192
    80000584:	fc86                	sd	ra,120(sp)
    80000586:	f8a2                	sd	s0,112(sp)
    80000588:	f4a6                	sd	s1,104(sp)
    8000058a:	f0ca                	sd	s2,96(sp)
    8000058c:	ecce                	sd	s3,88(sp)
    8000058e:	e8d2                	sd	s4,80(sp)
    80000590:	e4d6                	sd	s5,72(sp)
    80000592:	e0da                	sd	s6,64(sp)
    80000594:	fc5e                	sd	s7,56(sp)
    80000596:	f862                	sd	s8,48(sp)
    80000598:	f466                	sd	s9,40(sp)
    8000059a:	f06a                	sd	s10,32(sp)
    8000059c:	ec6e                	sd	s11,24(sp)
    8000059e:	0100                	addi	s0,sp,128
    800005a0:	8a2a                	mv	s4,a0
    800005a2:	e40c                	sd	a1,8(s0)
    800005a4:	e810                	sd	a2,16(s0)
    800005a6:	ec14                	sd	a3,24(s0)
    800005a8:	f018                	sd	a4,32(s0)
    800005aa:	f41c                	sd	a5,40(s0)
    800005ac:	03043823          	sd	a6,48(s0)
    800005b0:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005b4:	00011d97          	auipc	s11,0x11
    800005b8:	c8cdad83          	lw	s11,-884(s11) # 80011240 <pr+0x18>
  if(locking)
    800005bc:	020d9b63          	bnez	s11,800005f2 <printf+0x70>
  if (fmt == 0)
    800005c0:	040a0263          	beqz	s4,80000604 <printf+0x82>
  va_start(ap, fmt);
    800005c4:	00840793          	addi	a5,s0,8
    800005c8:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005cc:	000a4503          	lbu	a0,0(s4)
    800005d0:	14050f63          	beqz	a0,8000072e <printf+0x1ac>
    800005d4:	4981                	li	s3,0
    if(c != '%'){
    800005d6:	02500a93          	li	s5,37
    switch(c){
    800005da:	07000b93          	li	s7,112
  consputc('x');
    800005de:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e0:	00008b17          	auipc	s6,0x8
    800005e4:	a60b0b13          	addi	s6,s6,-1440 # 80008040 <digits>
    switch(c){
    800005e8:	07300c93          	li	s9,115
    800005ec:	06400c13          	li	s8,100
    800005f0:	a82d                	j	8000062a <printf+0xa8>
    acquire(&pr.lock);
    800005f2:	00011517          	auipc	a0,0x11
    800005f6:	c3650513          	addi	a0,a0,-970 # 80011228 <pr>
    800005fa:	00000097          	auipc	ra,0x0
    800005fe:	5d6080e7          	jalr	1494(ra) # 80000bd0 <acquire>
    80000602:	bf7d                	j	800005c0 <printf+0x3e>
    panic("null fmt");
    80000604:	00008517          	auipc	a0,0x8
    80000608:	a2450513          	addi	a0,a0,-1500 # 80008028 <etext+0x28>
    8000060c:	00000097          	auipc	ra,0x0
    80000610:	f2c080e7          	jalr	-212(ra) # 80000538 <panic>
      consputc(c);
    80000614:	00000097          	auipc	ra,0x0
    80000618:	c62080e7          	jalr	-926(ra) # 80000276 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000061c:	2985                	addiw	s3,s3,1
    8000061e:	013a07b3          	add	a5,s4,s3
    80000622:	0007c503          	lbu	a0,0(a5)
    80000626:	10050463          	beqz	a0,8000072e <printf+0x1ac>
    if(c != '%'){
    8000062a:	ff5515e3          	bne	a0,s5,80000614 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000062e:	2985                	addiw	s3,s3,1
    80000630:	013a07b3          	add	a5,s4,s3
    80000634:	0007c783          	lbu	a5,0(a5)
    80000638:	0007849b          	sext.w	s1,a5
    if(c == 0)
    8000063c:	cbed                	beqz	a5,8000072e <printf+0x1ac>
    switch(c){
    8000063e:	05778a63          	beq	a5,s7,80000692 <printf+0x110>
    80000642:	02fbf663          	bgeu	s7,a5,8000066e <printf+0xec>
    80000646:	09978863          	beq	a5,s9,800006d6 <printf+0x154>
    8000064a:	07800713          	li	a4,120
    8000064e:	0ce79563          	bne	a5,a4,80000718 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000652:	f8843783          	ld	a5,-120(s0)
    80000656:	00878713          	addi	a4,a5,8
    8000065a:	f8e43423          	sd	a4,-120(s0)
    8000065e:	4605                	li	a2,1
    80000660:	85ea                	mv	a1,s10
    80000662:	4388                	lw	a0,0(a5)
    80000664:	00000097          	auipc	ra,0x0
    80000668:	e32080e7          	jalr	-462(ra) # 80000496 <printint>
      break;
    8000066c:	bf45                	j	8000061c <printf+0x9a>
    switch(c){
    8000066e:	09578f63          	beq	a5,s5,8000070c <printf+0x18a>
    80000672:	0b879363          	bne	a5,s8,80000718 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000676:	f8843783          	ld	a5,-120(s0)
    8000067a:	00878713          	addi	a4,a5,8
    8000067e:	f8e43423          	sd	a4,-120(s0)
    80000682:	4605                	li	a2,1
    80000684:	45a9                	li	a1,10
    80000686:	4388                	lw	a0,0(a5)
    80000688:	00000097          	auipc	ra,0x0
    8000068c:	e0e080e7          	jalr	-498(ra) # 80000496 <printint>
      break;
    80000690:	b771                	j	8000061c <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000692:	f8843783          	ld	a5,-120(s0)
    80000696:	00878713          	addi	a4,a5,8
    8000069a:	f8e43423          	sd	a4,-120(s0)
    8000069e:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a2:	03000513          	li	a0,48
    800006a6:	00000097          	auipc	ra,0x0
    800006aa:	bd0080e7          	jalr	-1072(ra) # 80000276 <consputc>
  consputc('x');
    800006ae:	07800513          	li	a0,120
    800006b2:	00000097          	auipc	ra,0x0
    800006b6:	bc4080e7          	jalr	-1084(ra) # 80000276 <consputc>
    800006ba:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006bc:	03c95793          	srli	a5,s2,0x3c
    800006c0:	97da                	add	a5,a5,s6
    800006c2:	0007c503          	lbu	a0,0(a5)
    800006c6:	00000097          	auipc	ra,0x0
    800006ca:	bb0080e7          	jalr	-1104(ra) # 80000276 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006ce:	0912                	slli	s2,s2,0x4
    800006d0:	34fd                	addiw	s1,s1,-1
    800006d2:	f4ed                	bnez	s1,800006bc <printf+0x13a>
    800006d4:	b7a1                	j	8000061c <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006d6:	f8843783          	ld	a5,-120(s0)
    800006da:	00878713          	addi	a4,a5,8
    800006de:	f8e43423          	sd	a4,-120(s0)
    800006e2:	6384                	ld	s1,0(a5)
    800006e4:	cc89                	beqz	s1,800006fe <printf+0x17c>
      for(; *s; s++)
    800006e6:	0004c503          	lbu	a0,0(s1)
    800006ea:	d90d                	beqz	a0,8000061c <printf+0x9a>
        consputc(*s);
    800006ec:	00000097          	auipc	ra,0x0
    800006f0:	b8a080e7          	jalr	-1142(ra) # 80000276 <consputc>
      for(; *s; s++)
    800006f4:	0485                	addi	s1,s1,1
    800006f6:	0004c503          	lbu	a0,0(s1)
    800006fa:	f96d                	bnez	a0,800006ec <printf+0x16a>
    800006fc:	b705                	j	8000061c <printf+0x9a>
        s = "(null)";
    800006fe:	00008497          	auipc	s1,0x8
    80000702:	92248493          	addi	s1,s1,-1758 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000706:	02800513          	li	a0,40
    8000070a:	b7cd                	j	800006ec <printf+0x16a>
      consputc('%');
    8000070c:	8556                	mv	a0,s5
    8000070e:	00000097          	auipc	ra,0x0
    80000712:	b68080e7          	jalr	-1176(ra) # 80000276 <consputc>
      break;
    80000716:	b719                	j	8000061c <printf+0x9a>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b5c080e7          	jalr	-1188(ra) # 80000276 <consputc>
      consputc(c);
    80000722:	8526                	mv	a0,s1
    80000724:	00000097          	auipc	ra,0x0
    80000728:	b52080e7          	jalr	-1198(ra) # 80000276 <consputc>
      break;
    8000072c:	bdc5                	j	8000061c <printf+0x9a>
  if(locking)
    8000072e:	020d9163          	bnez	s11,80000750 <printf+0x1ce>
}
    80000732:	70e6                	ld	ra,120(sp)
    80000734:	7446                	ld	s0,112(sp)
    80000736:	74a6                	ld	s1,104(sp)
    80000738:	7906                	ld	s2,96(sp)
    8000073a:	69e6                	ld	s3,88(sp)
    8000073c:	6a46                	ld	s4,80(sp)
    8000073e:	6aa6                	ld	s5,72(sp)
    80000740:	6b06                	ld	s6,64(sp)
    80000742:	7be2                	ld	s7,56(sp)
    80000744:	7c42                	ld	s8,48(sp)
    80000746:	7ca2                	ld	s9,40(sp)
    80000748:	7d02                	ld	s10,32(sp)
    8000074a:	6de2                	ld	s11,24(sp)
    8000074c:	6129                	addi	sp,sp,192
    8000074e:	8082                	ret
    release(&pr.lock);
    80000750:	00011517          	auipc	a0,0x11
    80000754:	ad850513          	addi	a0,a0,-1320 # 80011228 <pr>
    80000758:	00000097          	auipc	ra,0x0
    8000075c:	52c080e7          	jalr	1324(ra) # 80000c84 <release>
}
    80000760:	bfc9                	j	80000732 <printf+0x1b0>

0000000080000762 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000762:	1101                	addi	sp,sp,-32
    80000764:	ec06                	sd	ra,24(sp)
    80000766:	e822                	sd	s0,16(sp)
    80000768:	e426                	sd	s1,8(sp)
    8000076a:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000076c:	00011497          	auipc	s1,0x11
    80000770:	abc48493          	addi	s1,s1,-1348 # 80011228 <pr>
    80000774:	00008597          	auipc	a1,0x8
    80000778:	8c458593          	addi	a1,a1,-1852 # 80008038 <etext+0x38>
    8000077c:	8526                	mv	a0,s1
    8000077e:	00000097          	auipc	ra,0x0
    80000782:	3c2080e7          	jalr	962(ra) # 80000b40 <initlock>
  pr.locking = 1;
    80000786:	4785                	li	a5,1
    80000788:	cc9c                	sw	a5,24(s1)
}
    8000078a:	60e2                	ld	ra,24(sp)
    8000078c:	6442                	ld	s0,16(sp)
    8000078e:	64a2                	ld	s1,8(sp)
    80000790:	6105                	addi	sp,sp,32
    80000792:	8082                	ret

0000000080000794 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000794:	1141                	addi	sp,sp,-16
    80000796:	e406                	sd	ra,8(sp)
    80000798:	e022                	sd	s0,0(sp)
    8000079a:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000079c:	100007b7          	lui	a5,0x10000
    800007a0:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007a4:	f8000713          	li	a4,-128
    800007a8:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007ac:	470d                	li	a4,3
    800007ae:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b2:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007b6:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007ba:	469d                	li	a3,7
    800007bc:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c0:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007c4:	00008597          	auipc	a1,0x8
    800007c8:	89458593          	addi	a1,a1,-1900 # 80008058 <digits+0x18>
    800007cc:	00011517          	auipc	a0,0x11
    800007d0:	a7c50513          	addi	a0,a0,-1412 # 80011248 <uart_tx_lock>
    800007d4:	00000097          	auipc	ra,0x0
    800007d8:	36c080e7          	jalr	876(ra) # 80000b40 <initlock>
}
    800007dc:	60a2                	ld	ra,8(sp)
    800007de:	6402                	ld	s0,0(sp)
    800007e0:	0141                	addi	sp,sp,16
    800007e2:	8082                	ret

00000000800007e4 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007e4:	1101                	addi	sp,sp,-32
    800007e6:	ec06                	sd	ra,24(sp)
    800007e8:	e822                	sd	s0,16(sp)
    800007ea:	e426                	sd	s1,8(sp)
    800007ec:	1000                	addi	s0,sp,32
    800007ee:	84aa                	mv	s1,a0
  push_off();
    800007f0:	00000097          	auipc	ra,0x0
    800007f4:	394080e7          	jalr	916(ra) # 80000b84 <push_off>

  if(panicked){
    800007f8:	00009797          	auipc	a5,0x9
    800007fc:	8087a783          	lw	a5,-2040(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000800:	10000737          	lui	a4,0x10000
  if(panicked){
    80000804:	c391                	beqz	a5,80000808 <uartputc_sync+0x24>
    for(;;)
    80000806:	a001                	j	80000806 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000080c:	0207f793          	andi	a5,a5,32
    80000810:	dfe5                	beqz	a5,80000808 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000812:	0ff4f513          	andi	a0,s1,255
    80000816:	100007b7          	lui	a5,0x10000
    8000081a:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    8000081e:	00000097          	auipc	ra,0x0
    80000822:	406080e7          	jalr	1030(ra) # 80000c24 <pop_off>
}
    80000826:	60e2                	ld	ra,24(sp)
    80000828:	6442                	ld	s0,16(sp)
    8000082a:	64a2                	ld	s1,8(sp)
    8000082c:	6105                	addi	sp,sp,32
    8000082e:	8082                	ret

0000000080000830 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000830:	00008797          	auipc	a5,0x8
    80000834:	7d87b783          	ld	a5,2008(a5) # 80009008 <uart_tx_r>
    80000838:	00008717          	auipc	a4,0x8
    8000083c:	7d873703          	ld	a4,2008(a4) # 80009010 <uart_tx_w>
    80000840:	06f70a63          	beq	a4,a5,800008b4 <uartstart+0x84>
{
    80000844:	7139                	addi	sp,sp,-64
    80000846:	fc06                	sd	ra,56(sp)
    80000848:	f822                	sd	s0,48(sp)
    8000084a:	f426                	sd	s1,40(sp)
    8000084c:	f04a                	sd	s2,32(sp)
    8000084e:	ec4e                	sd	s3,24(sp)
    80000850:	e852                	sd	s4,16(sp)
    80000852:	e456                	sd	s5,8(sp)
    80000854:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000856:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000085a:	00011a17          	auipc	s4,0x11
    8000085e:	9eea0a13          	addi	s4,s4,-1554 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000862:	00008497          	auipc	s1,0x8
    80000866:	7a648493          	addi	s1,s1,1958 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086a:	00008997          	auipc	s3,0x8
    8000086e:	7a698993          	addi	s3,s3,1958 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000872:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000876:	02077713          	andi	a4,a4,32
    8000087a:	c705                	beqz	a4,800008a2 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000087c:	01f7f713          	andi	a4,a5,31
    80000880:	9752                	add	a4,a4,s4
    80000882:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    80000886:	0785                	addi	a5,a5,1
    80000888:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000088a:	8526                	mv	a0,s1
    8000088c:	00002097          	auipc	ra,0x2
    80000890:	956080e7          	jalr	-1706(ra) # 800021e2 <wakeup>
    
    WriteReg(THR, c);
    80000894:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    80000898:	609c                	ld	a5,0(s1)
    8000089a:	0009b703          	ld	a4,0(s3)
    8000089e:	fcf71ae3          	bne	a4,a5,80000872 <uartstart+0x42>
  }
}
    800008a2:	70e2                	ld	ra,56(sp)
    800008a4:	7442                	ld	s0,48(sp)
    800008a6:	74a2                	ld	s1,40(sp)
    800008a8:	7902                	ld	s2,32(sp)
    800008aa:	69e2                	ld	s3,24(sp)
    800008ac:	6a42                	ld	s4,16(sp)
    800008ae:	6aa2                	ld	s5,8(sp)
    800008b0:	6121                	addi	sp,sp,64
    800008b2:	8082                	ret
    800008b4:	8082                	ret

00000000800008b6 <uartputc>:
{
    800008b6:	7179                	addi	sp,sp,-48
    800008b8:	f406                	sd	ra,40(sp)
    800008ba:	f022                	sd	s0,32(sp)
    800008bc:	ec26                	sd	s1,24(sp)
    800008be:	e84a                	sd	s2,16(sp)
    800008c0:	e44e                	sd	s3,8(sp)
    800008c2:	e052                	sd	s4,0(sp)
    800008c4:	1800                	addi	s0,sp,48
    800008c6:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008c8:	00011517          	auipc	a0,0x11
    800008cc:	98050513          	addi	a0,a0,-1664 # 80011248 <uart_tx_lock>
    800008d0:	00000097          	auipc	ra,0x0
    800008d4:	300080e7          	jalr	768(ra) # 80000bd0 <acquire>
  if(panicked){
    800008d8:	00008797          	auipc	a5,0x8
    800008dc:	7287a783          	lw	a5,1832(a5) # 80009000 <panicked>
    800008e0:	c391                	beqz	a5,800008e4 <uartputc+0x2e>
    for(;;)
    800008e2:	a001                	j	800008e2 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e4:	00008717          	auipc	a4,0x8
    800008e8:	72c73703          	ld	a4,1836(a4) # 80009010 <uart_tx_w>
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	71c7b783          	ld	a5,1820(a5) # 80009008 <uart_tx_r>
    800008f4:	02078793          	addi	a5,a5,32
    800008f8:	02e79b63          	bne	a5,a4,8000092e <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00011997          	auipc	s3,0x11
    80000900:	94c98993          	addi	s3,s3,-1716 # 80011248 <uart_tx_lock>
    80000904:	00008497          	auipc	s1,0x8
    80000908:	70448493          	addi	s1,s1,1796 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00008917          	auipc	s2,0x8
    80000910:	70490913          	addi	s2,s2,1796 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000914:	85ce                	mv	a1,s3
    80000916:	8526                	mv	a0,s1
    80000918:	00001097          	auipc	ra,0x1
    8000091c:	73e080e7          	jalr	1854(ra) # 80002056 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00093703          	ld	a4,0(s2)
    80000924:	609c                	ld	a5,0(s1)
    80000926:	02078793          	addi	a5,a5,32
    8000092a:	fee785e3          	beq	a5,a4,80000914 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    8000092e:	00011497          	auipc	s1,0x11
    80000932:	91a48493          	addi	s1,s1,-1766 # 80011248 <uart_tx_lock>
    80000936:	01f77793          	andi	a5,a4,31
    8000093a:	97a6                	add	a5,a5,s1
    8000093c:	01478c23          	sb	s4,24(a5)
      uart_tx_w += 1;
    80000940:	0705                	addi	a4,a4,1
    80000942:	00008797          	auipc	a5,0x8
    80000946:	6ce7b723          	sd	a4,1742(a5) # 80009010 <uart_tx_w>
      uartstart();
    8000094a:	00000097          	auipc	ra,0x0
    8000094e:	ee6080e7          	jalr	-282(ra) # 80000830 <uartstart>
      release(&uart_tx_lock);
    80000952:	8526                	mv	a0,s1
    80000954:	00000097          	auipc	ra,0x0
    80000958:	330080e7          	jalr	816(ra) # 80000c84 <release>
}
    8000095c:	70a2                	ld	ra,40(sp)
    8000095e:	7402                	ld	s0,32(sp)
    80000960:	64e2                	ld	s1,24(sp)
    80000962:	6942                	ld	s2,16(sp)
    80000964:	69a2                	ld	s3,8(sp)
    80000966:	6a02                	ld	s4,0(sp)
    80000968:	6145                	addi	sp,sp,48
    8000096a:	8082                	ret

000000008000096c <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000096c:	1141                	addi	sp,sp,-16
    8000096e:	e422                	sd	s0,8(sp)
    80000970:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000972:	100007b7          	lui	a5,0x10000
    80000976:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000097a:	8b85                	andi	a5,a5,1
    8000097c:	cb91                	beqz	a5,80000990 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    8000097e:	100007b7          	lui	a5,0x10000
    80000982:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    80000986:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000098a:	6422                	ld	s0,8(sp)
    8000098c:	0141                	addi	sp,sp,16
    8000098e:	8082                	ret
    return -1;
    80000990:	557d                	li	a0,-1
    80000992:	bfe5                	j	8000098a <uartgetc+0x1e>

0000000080000994 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000994:	1101                	addi	sp,sp,-32
    80000996:	ec06                	sd	ra,24(sp)
    80000998:	e822                	sd	s0,16(sp)
    8000099a:	e426                	sd	s1,8(sp)
    8000099c:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    8000099e:	54fd                	li	s1,-1
    800009a0:	a029                	j	800009aa <uartintr+0x16>
      break;
    consoleintr(c);
    800009a2:	00000097          	auipc	ra,0x0
    800009a6:	916080e7          	jalr	-1770(ra) # 800002b8 <consoleintr>
    int c = uartgetc();
    800009aa:	00000097          	auipc	ra,0x0
    800009ae:	fc2080e7          	jalr	-62(ra) # 8000096c <uartgetc>
    if(c == -1)
    800009b2:	fe9518e3          	bne	a0,s1,800009a2 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009b6:	00011497          	auipc	s1,0x11
    800009ba:	89248493          	addi	s1,s1,-1902 # 80011248 <uart_tx_lock>
    800009be:	8526                	mv	a0,s1
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	210080e7          	jalr	528(ra) # 80000bd0 <acquire>
  uartstart();
    800009c8:	00000097          	auipc	ra,0x0
    800009cc:	e68080e7          	jalr	-408(ra) # 80000830 <uartstart>
  release(&uart_tx_lock);
    800009d0:	8526                	mv	a0,s1
    800009d2:	00000097          	auipc	ra,0x0
    800009d6:	2b2080e7          	jalr	690(ra) # 80000c84 <release>
}
    800009da:	60e2                	ld	ra,24(sp)
    800009dc:	6442                	ld	s0,16(sp)
    800009de:	64a2                	ld	s1,8(sp)
    800009e0:	6105                	addi	sp,sp,32
    800009e2:	8082                	ret

00000000800009e4 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e4:	1101                	addi	sp,sp,-32
    800009e6:	ec06                	sd	ra,24(sp)
    800009e8:	e822                	sd	s0,16(sp)
    800009ea:	e426                	sd	s1,8(sp)
    800009ec:	e04a                	sd	s2,0(sp)
    800009ee:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f0:	03451793          	slli	a5,a0,0x34
    800009f4:	ebb9                	bnez	a5,80000a4a <kfree+0x66>
    800009f6:	84aa                	mv	s1,a0
    800009f8:	00025797          	auipc	a5,0x25
    800009fc:	60878793          	addi	a5,a5,1544 # 80026000 <end>
    80000a00:	04f56563          	bltu	a0,a5,80000a4a <kfree+0x66>
    80000a04:	47c5                	li	a5,17
    80000a06:	07ee                	slli	a5,a5,0x1b
    80000a08:	04f57163          	bgeu	a0,a5,80000a4a <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a0c:	6605                	lui	a2,0x1
    80000a0e:	4585                	li	a1,1
    80000a10:	00000097          	auipc	ra,0x0
    80000a14:	2bc080e7          	jalr	700(ra) # 80000ccc <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a18:	00011917          	auipc	s2,0x11
    80000a1c:	86890913          	addi	s2,s2,-1944 # 80011280 <kmem>
    80000a20:	854a                	mv	a0,s2
    80000a22:	00000097          	auipc	ra,0x0
    80000a26:	1ae080e7          	jalr	430(ra) # 80000bd0 <acquire>
  r->next = kmem.freelist;
    80000a2a:	01893783          	ld	a5,24(s2)
    80000a2e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a30:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	24e080e7          	jalr	590(ra) # 80000c84 <release>
}
    80000a3e:	60e2                	ld	ra,24(sp)
    80000a40:	6442                	ld	s0,16(sp)
    80000a42:	64a2                	ld	s1,8(sp)
    80000a44:	6902                	ld	s2,0(sp)
    80000a46:	6105                	addi	sp,sp,32
    80000a48:	8082                	ret
    panic("kfree");
    80000a4a:	00007517          	auipc	a0,0x7
    80000a4e:	61650513          	addi	a0,a0,1558 # 80008060 <digits+0x20>
    80000a52:	00000097          	auipc	ra,0x0
    80000a56:	ae6080e7          	jalr	-1306(ra) # 80000538 <panic>

0000000080000a5a <freerange>:
{
    80000a5a:	7179                	addi	sp,sp,-48
    80000a5c:	f406                	sd	ra,40(sp)
    80000a5e:	f022                	sd	s0,32(sp)
    80000a60:	ec26                	sd	s1,24(sp)
    80000a62:	e84a                	sd	s2,16(sp)
    80000a64:	e44e                	sd	s3,8(sp)
    80000a66:	e052                	sd	s4,0(sp)
    80000a68:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6a:	6785                	lui	a5,0x1
    80000a6c:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a70:	94aa                	add	s1,s1,a0
    80000a72:	757d                	lui	a0,0xfffff
    80000a74:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a76:	94be                	add	s1,s1,a5
    80000a78:	0095ee63          	bltu	a1,s1,80000a94 <freerange+0x3a>
    80000a7c:	892e                	mv	s2,a1
    kfree(p);
    80000a7e:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a80:	6985                	lui	s3,0x1
    kfree(p);
    80000a82:	01448533          	add	a0,s1,s4
    80000a86:	00000097          	auipc	ra,0x0
    80000a8a:	f5e080e7          	jalr	-162(ra) # 800009e4 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8e:	94ce                	add	s1,s1,s3
    80000a90:	fe9979e3          	bgeu	s2,s1,80000a82 <freerange+0x28>
}
    80000a94:	70a2                	ld	ra,40(sp)
    80000a96:	7402                	ld	s0,32(sp)
    80000a98:	64e2                	ld	s1,24(sp)
    80000a9a:	6942                	ld	s2,16(sp)
    80000a9c:	69a2                	ld	s3,8(sp)
    80000a9e:	6a02                	ld	s4,0(sp)
    80000aa0:	6145                	addi	sp,sp,48
    80000aa2:	8082                	ret

0000000080000aa4 <kinit>:
{
    80000aa4:	1141                	addi	sp,sp,-16
    80000aa6:	e406                	sd	ra,8(sp)
    80000aa8:	e022                	sd	s0,0(sp)
    80000aaa:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aac:	00007597          	auipc	a1,0x7
    80000ab0:	5bc58593          	addi	a1,a1,1468 # 80008068 <digits+0x28>
    80000ab4:	00010517          	auipc	a0,0x10
    80000ab8:	7cc50513          	addi	a0,a0,1996 # 80011280 <kmem>
    80000abc:	00000097          	auipc	ra,0x0
    80000ac0:	084080e7          	jalr	132(ra) # 80000b40 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ac4:	45c5                	li	a1,17
    80000ac6:	05ee                	slli	a1,a1,0x1b
    80000ac8:	00025517          	auipc	a0,0x25
    80000acc:	53850513          	addi	a0,a0,1336 # 80026000 <end>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	f8a080e7          	jalr	-118(ra) # 80000a5a <freerange>
}
    80000ad8:	60a2                	ld	ra,8(sp)
    80000ada:	6402                	ld	s0,0(sp)
    80000adc:	0141                	addi	sp,sp,16
    80000ade:	8082                	ret

0000000080000ae0 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae0:	1101                	addi	sp,sp,-32
    80000ae2:	ec06                	sd	ra,24(sp)
    80000ae4:	e822                	sd	s0,16(sp)
    80000ae6:	e426                	sd	s1,8(sp)
    80000ae8:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000aea:	00010497          	auipc	s1,0x10
    80000aee:	79648493          	addi	s1,s1,1942 # 80011280 <kmem>
    80000af2:	8526                	mv	a0,s1
    80000af4:	00000097          	auipc	ra,0x0
    80000af8:	0dc080e7          	jalr	220(ra) # 80000bd0 <acquire>
  r = kmem.freelist;
    80000afc:	6c84                	ld	s1,24(s1)
  if(r)
    80000afe:	c885                	beqz	s1,80000b2e <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b00:	609c                	ld	a5,0(s1)
    80000b02:	00010517          	auipc	a0,0x10
    80000b06:	77e50513          	addi	a0,a0,1918 # 80011280 <kmem>
    80000b0a:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b0c:	00000097          	auipc	ra,0x0
    80000b10:	178080e7          	jalr	376(ra) # 80000c84 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b14:	6605                	lui	a2,0x1
    80000b16:	4595                	li	a1,5
    80000b18:	8526                	mv	a0,s1
    80000b1a:	00000097          	auipc	ra,0x0
    80000b1e:	1b2080e7          	jalr	434(ra) # 80000ccc <memset>
  return (void*)r;
}
    80000b22:	8526                	mv	a0,s1
    80000b24:	60e2                	ld	ra,24(sp)
    80000b26:	6442                	ld	s0,16(sp)
    80000b28:	64a2                	ld	s1,8(sp)
    80000b2a:	6105                	addi	sp,sp,32
    80000b2c:	8082                	ret
  release(&kmem.lock);
    80000b2e:	00010517          	auipc	a0,0x10
    80000b32:	75250513          	addi	a0,a0,1874 # 80011280 <kmem>
    80000b36:	00000097          	auipc	ra,0x0
    80000b3a:	14e080e7          	jalr	334(ra) # 80000c84 <release>
  if(r)
    80000b3e:	b7d5                	j	80000b22 <kalloc+0x42>

0000000080000b40 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b40:	1141                	addi	sp,sp,-16
    80000b42:	e422                	sd	s0,8(sp)
    80000b44:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b46:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b48:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b4c:	00053823          	sd	zero,16(a0)
}
    80000b50:	6422                	ld	s0,8(sp)
    80000b52:	0141                	addi	sp,sp,16
    80000b54:	8082                	ret

0000000080000b56 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b56:	411c                	lw	a5,0(a0)
    80000b58:	e399                	bnez	a5,80000b5e <holding+0x8>
    80000b5a:	4501                	li	a0,0
  return r;
}
    80000b5c:	8082                	ret
{
    80000b5e:	1101                	addi	sp,sp,-32
    80000b60:	ec06                	sd	ra,24(sp)
    80000b62:	e822                	sd	s0,16(sp)
    80000b64:	e426                	sd	s1,8(sp)
    80000b66:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b68:	6904                	ld	s1,16(a0)
    80000b6a:	00001097          	auipc	ra,0x1
    80000b6e:	e10080e7          	jalr	-496(ra) # 8000197a <mycpu>
    80000b72:	40a48533          	sub	a0,s1,a0
    80000b76:	00153513          	seqz	a0,a0
}
    80000b7a:	60e2                	ld	ra,24(sp)
    80000b7c:	6442                	ld	s0,16(sp)
    80000b7e:	64a2                	ld	s1,8(sp)
    80000b80:	6105                	addi	sp,sp,32
    80000b82:	8082                	ret

0000000080000b84 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b84:	1101                	addi	sp,sp,-32
    80000b86:	ec06                	sd	ra,24(sp)
    80000b88:	e822                	sd	s0,16(sp)
    80000b8a:	e426                	sd	s1,8(sp)
    80000b8c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b8e:	100024f3          	csrr	s1,sstatus
    80000b92:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b96:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b98:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b9c:	00001097          	auipc	ra,0x1
    80000ba0:	dde080e7          	jalr	-546(ra) # 8000197a <mycpu>
    80000ba4:	5d3c                	lw	a5,120(a0)
    80000ba6:	cf89                	beqz	a5,80000bc0 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000ba8:	00001097          	auipc	ra,0x1
    80000bac:	dd2080e7          	jalr	-558(ra) # 8000197a <mycpu>
    80000bb0:	5d3c                	lw	a5,120(a0)
    80000bb2:	2785                	addiw	a5,a5,1
    80000bb4:	dd3c                	sw	a5,120(a0)
}
    80000bb6:	60e2                	ld	ra,24(sp)
    80000bb8:	6442                	ld	s0,16(sp)
    80000bba:	64a2                	ld	s1,8(sp)
    80000bbc:	6105                	addi	sp,sp,32
    80000bbe:	8082                	ret
    mycpu()->intena = old;
    80000bc0:	00001097          	auipc	ra,0x1
    80000bc4:	dba080e7          	jalr	-582(ra) # 8000197a <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bc8:	8085                	srli	s1,s1,0x1
    80000bca:	8885                	andi	s1,s1,1
    80000bcc:	dd64                	sw	s1,124(a0)
    80000bce:	bfe9                	j	80000ba8 <push_off+0x24>

0000000080000bd0 <acquire>:
{
    80000bd0:	1101                	addi	sp,sp,-32
    80000bd2:	ec06                	sd	ra,24(sp)
    80000bd4:	e822                	sd	s0,16(sp)
    80000bd6:	e426                	sd	s1,8(sp)
    80000bd8:	1000                	addi	s0,sp,32
    80000bda:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bdc:	00000097          	auipc	ra,0x0
    80000be0:	fa8080e7          	jalr	-88(ra) # 80000b84 <push_off>
  if(holding(lk))
    80000be4:	8526                	mv	a0,s1
    80000be6:	00000097          	auipc	ra,0x0
    80000bea:	f70080e7          	jalr	-144(ra) # 80000b56 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bee:	4705                	li	a4,1
  if(holding(lk))
    80000bf0:	e115                	bnez	a0,80000c14 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf2:	87ba                	mv	a5,a4
    80000bf4:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bf8:	2781                	sext.w	a5,a5
    80000bfa:	ffe5                	bnez	a5,80000bf2 <acquire+0x22>
  __sync_synchronize();
    80000bfc:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c00:	00001097          	auipc	ra,0x1
    80000c04:	d7a080e7          	jalr	-646(ra) # 8000197a <mycpu>
    80000c08:	e888                	sd	a0,16(s1)
}
    80000c0a:	60e2                	ld	ra,24(sp)
    80000c0c:	6442                	ld	s0,16(sp)
    80000c0e:	64a2                	ld	s1,8(sp)
    80000c10:	6105                	addi	sp,sp,32
    80000c12:	8082                	ret
    panic("acquire");
    80000c14:	00007517          	auipc	a0,0x7
    80000c18:	45c50513          	addi	a0,a0,1116 # 80008070 <digits+0x30>
    80000c1c:	00000097          	auipc	ra,0x0
    80000c20:	91c080e7          	jalr	-1764(ra) # 80000538 <panic>

0000000080000c24 <pop_off>:

void
pop_off(void)
{
    80000c24:	1141                	addi	sp,sp,-16
    80000c26:	e406                	sd	ra,8(sp)
    80000c28:	e022                	sd	s0,0(sp)
    80000c2a:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c2c:	00001097          	auipc	ra,0x1
    80000c30:	d4e080e7          	jalr	-690(ra) # 8000197a <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c34:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c38:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c3a:	e78d                	bnez	a5,80000c64 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c3c:	5d3c                	lw	a5,120(a0)
    80000c3e:	02f05b63          	blez	a5,80000c74 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c42:	37fd                	addiw	a5,a5,-1
    80000c44:	0007871b          	sext.w	a4,a5
    80000c48:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c4a:	eb09                	bnez	a4,80000c5c <pop_off+0x38>
    80000c4c:	5d7c                	lw	a5,124(a0)
    80000c4e:	c799                	beqz	a5,80000c5c <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c50:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c54:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c58:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c5c:	60a2                	ld	ra,8(sp)
    80000c5e:	6402                	ld	s0,0(sp)
    80000c60:	0141                	addi	sp,sp,16
    80000c62:	8082                	ret
    panic("pop_off - interruptible");
    80000c64:	00007517          	auipc	a0,0x7
    80000c68:	41450513          	addi	a0,a0,1044 # 80008078 <digits+0x38>
    80000c6c:	00000097          	auipc	ra,0x0
    80000c70:	8cc080e7          	jalr	-1844(ra) # 80000538 <panic>
    panic("pop_off");
    80000c74:	00007517          	auipc	a0,0x7
    80000c78:	41c50513          	addi	a0,a0,1052 # 80008090 <digits+0x50>
    80000c7c:	00000097          	auipc	ra,0x0
    80000c80:	8bc080e7          	jalr	-1860(ra) # 80000538 <panic>

0000000080000c84 <release>:
{
    80000c84:	1101                	addi	sp,sp,-32
    80000c86:	ec06                	sd	ra,24(sp)
    80000c88:	e822                	sd	s0,16(sp)
    80000c8a:	e426                	sd	s1,8(sp)
    80000c8c:	1000                	addi	s0,sp,32
    80000c8e:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	ec6080e7          	jalr	-314(ra) # 80000b56 <holding>
    80000c98:	c115                	beqz	a0,80000cbc <release+0x38>
  lk->cpu = 0;
    80000c9a:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000c9e:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca2:	0f50000f          	fence	iorw,ow
    80000ca6:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	f7a080e7          	jalr	-134(ra) # 80000c24 <pop_off>
}
    80000cb2:	60e2                	ld	ra,24(sp)
    80000cb4:	6442                	ld	s0,16(sp)
    80000cb6:	64a2                	ld	s1,8(sp)
    80000cb8:	6105                	addi	sp,sp,32
    80000cba:	8082                	ret
    panic("release");
    80000cbc:	00007517          	auipc	a0,0x7
    80000cc0:	3dc50513          	addi	a0,a0,988 # 80008098 <digits+0x58>
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	874080e7          	jalr	-1932(ra) # 80000538 <panic>

0000000080000ccc <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ccc:	1141                	addi	sp,sp,-16
    80000cce:	e422                	sd	s0,8(sp)
    80000cd0:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd2:	ca19                	beqz	a2,80000ce8 <memset+0x1c>
    80000cd4:	87aa                	mv	a5,a0
    80000cd6:	1602                	slli	a2,a2,0x20
    80000cd8:	9201                	srli	a2,a2,0x20
    80000cda:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cde:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce2:	0785                	addi	a5,a5,1
    80000ce4:	fee79de3          	bne	a5,a4,80000cde <memset+0x12>
  }
  return dst;
}
    80000ce8:	6422                	ld	s0,8(sp)
    80000cea:	0141                	addi	sp,sp,16
    80000cec:	8082                	ret

0000000080000cee <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cee:	1141                	addi	sp,sp,-16
    80000cf0:	e422                	sd	s0,8(sp)
    80000cf2:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cf4:	ca05                	beqz	a2,80000d24 <memcmp+0x36>
    80000cf6:	fff6069b          	addiw	a3,a2,-1
    80000cfa:	1682                	slli	a3,a3,0x20
    80000cfc:	9281                	srli	a3,a3,0x20
    80000cfe:	0685                	addi	a3,a3,1
    80000d00:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d02:	00054783          	lbu	a5,0(a0)
    80000d06:	0005c703          	lbu	a4,0(a1)
    80000d0a:	00e79863          	bne	a5,a4,80000d1a <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d0e:	0505                	addi	a0,a0,1
    80000d10:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d12:	fed518e3          	bne	a0,a3,80000d02 <memcmp+0x14>
  }

  return 0;
    80000d16:	4501                	li	a0,0
    80000d18:	a019                	j	80000d1e <memcmp+0x30>
      return *s1 - *s2;
    80000d1a:	40e7853b          	subw	a0,a5,a4
}
    80000d1e:	6422                	ld	s0,8(sp)
    80000d20:	0141                	addi	sp,sp,16
    80000d22:	8082                	ret
  return 0;
    80000d24:	4501                	li	a0,0
    80000d26:	bfe5                	j	80000d1e <memcmp+0x30>

0000000080000d28 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d28:	1141                	addi	sp,sp,-16
    80000d2a:	e422                	sd	s0,8(sp)
    80000d2c:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d2e:	c205                	beqz	a2,80000d4e <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d30:	02a5e263          	bltu	a1,a0,80000d54 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d34:	1602                	slli	a2,a2,0x20
    80000d36:	9201                	srli	a2,a2,0x20
    80000d38:	00c587b3          	add	a5,a1,a2
{
    80000d3c:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d3e:	0585                	addi	a1,a1,1
    80000d40:	0705                	addi	a4,a4,1
    80000d42:	fff5c683          	lbu	a3,-1(a1)
    80000d46:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d4a:	fef59ae3          	bne	a1,a5,80000d3e <memmove+0x16>

  return dst;
}
    80000d4e:	6422                	ld	s0,8(sp)
    80000d50:	0141                	addi	sp,sp,16
    80000d52:	8082                	ret
  if(s < d && s + n > d){
    80000d54:	02061693          	slli	a3,a2,0x20
    80000d58:	9281                	srli	a3,a3,0x20
    80000d5a:	00d58733          	add	a4,a1,a3
    80000d5e:	fce57be3          	bgeu	a0,a4,80000d34 <memmove+0xc>
    d += n;
    80000d62:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d64:	fff6079b          	addiw	a5,a2,-1
    80000d68:	1782                	slli	a5,a5,0x20
    80000d6a:	9381                	srli	a5,a5,0x20
    80000d6c:	fff7c793          	not	a5,a5
    80000d70:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d72:	177d                	addi	a4,a4,-1
    80000d74:	16fd                	addi	a3,a3,-1
    80000d76:	00074603          	lbu	a2,0(a4)
    80000d7a:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d7e:	fee79ae3          	bne	a5,a4,80000d72 <memmove+0x4a>
    80000d82:	b7f1                	j	80000d4e <memmove+0x26>

0000000080000d84 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d84:	1141                	addi	sp,sp,-16
    80000d86:	e406                	sd	ra,8(sp)
    80000d88:	e022                	sd	s0,0(sp)
    80000d8a:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d8c:	00000097          	auipc	ra,0x0
    80000d90:	f9c080e7          	jalr	-100(ra) # 80000d28 <memmove>
}
    80000d94:	60a2                	ld	ra,8(sp)
    80000d96:	6402                	ld	s0,0(sp)
    80000d98:	0141                	addi	sp,sp,16
    80000d9a:	8082                	ret

0000000080000d9c <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d9c:	1141                	addi	sp,sp,-16
    80000d9e:	e422                	sd	s0,8(sp)
    80000da0:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da2:	ce11                	beqz	a2,80000dbe <strncmp+0x22>
    80000da4:	00054783          	lbu	a5,0(a0)
    80000da8:	cf89                	beqz	a5,80000dc2 <strncmp+0x26>
    80000daa:	0005c703          	lbu	a4,0(a1)
    80000dae:	00f71a63          	bne	a4,a5,80000dc2 <strncmp+0x26>
    n--, p++, q++;
    80000db2:	367d                	addiw	a2,a2,-1
    80000db4:	0505                	addi	a0,a0,1
    80000db6:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000db8:	f675                	bnez	a2,80000da4 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dba:	4501                	li	a0,0
    80000dbc:	a809                	j	80000dce <strncmp+0x32>
    80000dbe:	4501                	li	a0,0
    80000dc0:	a039                	j	80000dce <strncmp+0x32>
  if(n == 0)
    80000dc2:	ca09                	beqz	a2,80000dd4 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dc4:	00054503          	lbu	a0,0(a0)
    80000dc8:	0005c783          	lbu	a5,0(a1)
    80000dcc:	9d1d                	subw	a0,a0,a5
}
    80000dce:	6422                	ld	s0,8(sp)
    80000dd0:	0141                	addi	sp,sp,16
    80000dd2:	8082                	ret
    return 0;
    80000dd4:	4501                	li	a0,0
    80000dd6:	bfe5                	j	80000dce <strncmp+0x32>

0000000080000dd8 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dd8:	1141                	addi	sp,sp,-16
    80000dda:	e422                	sd	s0,8(sp)
    80000ddc:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dde:	872a                	mv	a4,a0
    80000de0:	8832                	mv	a6,a2
    80000de2:	367d                	addiw	a2,a2,-1
    80000de4:	01005963          	blez	a6,80000df6 <strncpy+0x1e>
    80000de8:	0705                	addi	a4,a4,1
    80000dea:	0005c783          	lbu	a5,0(a1)
    80000dee:	fef70fa3          	sb	a5,-1(a4)
    80000df2:	0585                	addi	a1,a1,1
    80000df4:	f7f5                	bnez	a5,80000de0 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000df6:	86ba                	mv	a3,a4
    80000df8:	00c05c63          	blez	a2,80000e10 <strncpy+0x38>
    *s++ = 0;
    80000dfc:	0685                	addi	a3,a3,1
    80000dfe:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e02:	fff6c793          	not	a5,a3
    80000e06:	9fb9                	addw	a5,a5,a4
    80000e08:	010787bb          	addw	a5,a5,a6
    80000e0c:	fef048e3          	bgtz	a5,80000dfc <strncpy+0x24>
  return os;
}
    80000e10:	6422                	ld	s0,8(sp)
    80000e12:	0141                	addi	sp,sp,16
    80000e14:	8082                	ret

0000000080000e16 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e16:	1141                	addi	sp,sp,-16
    80000e18:	e422                	sd	s0,8(sp)
    80000e1a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e1c:	02c05363          	blez	a2,80000e42 <safestrcpy+0x2c>
    80000e20:	fff6069b          	addiw	a3,a2,-1
    80000e24:	1682                	slli	a3,a3,0x20
    80000e26:	9281                	srli	a3,a3,0x20
    80000e28:	96ae                	add	a3,a3,a1
    80000e2a:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e2c:	00d58963          	beq	a1,a3,80000e3e <safestrcpy+0x28>
    80000e30:	0585                	addi	a1,a1,1
    80000e32:	0785                	addi	a5,a5,1
    80000e34:	fff5c703          	lbu	a4,-1(a1)
    80000e38:	fee78fa3          	sb	a4,-1(a5)
    80000e3c:	fb65                	bnez	a4,80000e2c <safestrcpy+0x16>
    ;
  *s = 0;
    80000e3e:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e42:	6422                	ld	s0,8(sp)
    80000e44:	0141                	addi	sp,sp,16
    80000e46:	8082                	ret

0000000080000e48 <strlen>:

int
strlen(const char *s)
{
    80000e48:	1141                	addi	sp,sp,-16
    80000e4a:	e422                	sd	s0,8(sp)
    80000e4c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e4e:	00054783          	lbu	a5,0(a0)
    80000e52:	cf91                	beqz	a5,80000e6e <strlen+0x26>
    80000e54:	0505                	addi	a0,a0,1
    80000e56:	87aa                	mv	a5,a0
    80000e58:	4685                	li	a3,1
    80000e5a:	9e89                	subw	a3,a3,a0
    80000e5c:	00f6853b          	addw	a0,a3,a5
    80000e60:	0785                	addi	a5,a5,1
    80000e62:	fff7c703          	lbu	a4,-1(a5)
    80000e66:	fb7d                	bnez	a4,80000e5c <strlen+0x14>
    ;
  return n;
}
    80000e68:	6422                	ld	s0,8(sp)
    80000e6a:	0141                	addi	sp,sp,16
    80000e6c:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e6e:	4501                	li	a0,0
    80000e70:	bfe5                	j	80000e68 <strlen+0x20>

0000000080000e72 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e72:	1141                	addi	sp,sp,-16
    80000e74:	e406                	sd	ra,8(sp)
    80000e76:	e022                	sd	s0,0(sp)
    80000e78:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e7a:	00001097          	auipc	ra,0x1
    80000e7e:	af0080e7          	jalr	-1296(ra) # 8000196a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e82:	00008717          	auipc	a4,0x8
    80000e86:	19670713          	addi	a4,a4,406 # 80009018 <started>
  if(cpuid() == 0){
    80000e8a:	c139                	beqz	a0,80000ed0 <main+0x5e>
    while(started == 0)
    80000e8c:	431c                	lw	a5,0(a4)
    80000e8e:	2781                	sext.w	a5,a5
    80000e90:	dff5                	beqz	a5,80000e8c <main+0x1a>
      ;
    __sync_synchronize();
    80000e92:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	ad4080e7          	jalr	-1324(ra) # 8000196a <cpuid>
    80000e9e:	85aa                	mv	a1,a0
    80000ea0:	00007517          	auipc	a0,0x7
    80000ea4:	21850513          	addi	a0,a0,536 # 800080b8 <digits+0x78>
    80000ea8:	fffff097          	auipc	ra,0xfffff
    80000eac:	6da080e7          	jalr	1754(ra) # 80000582 <printf>
    kvminithart();    // turn on paging
    80000eb0:	00000097          	auipc	ra,0x0
    80000eb4:	0d8080e7          	jalr	216(ra) # 80000f88 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb8:	00001097          	auipc	ra,0x1
    80000ebc:	7f4080e7          	jalr	2036(ra) # 800026ac <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	e40080e7          	jalr	-448(ra) # 80005d00 <plicinithart>
  }

  scheduler();        
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	fdc080e7          	jalr	-36(ra) # 80001ea4 <scheduler>
    consoleinit();
    80000ed0:	fffff097          	auipc	ra,0xfffff
    80000ed4:	57a080e7          	jalr	1402(ra) # 8000044a <consoleinit>
    printfinit();
    80000ed8:	00000097          	auipc	ra,0x0
    80000edc:	88a080e7          	jalr	-1910(ra) # 80000762 <printfinit>
    printf("\n");
    80000ee0:	00007517          	auipc	a0,0x7
    80000ee4:	1e850513          	addi	a0,a0,488 # 800080c8 <digits+0x88>
    80000ee8:	fffff097          	auipc	ra,0xfffff
    80000eec:	69a080e7          	jalr	1690(ra) # 80000582 <printf>
    printf("xv6 kernel is booting\n");
    80000ef0:	00007517          	auipc	a0,0x7
    80000ef4:	1b050513          	addi	a0,a0,432 # 800080a0 <digits+0x60>
    80000ef8:	fffff097          	auipc	ra,0xfffff
    80000efc:	68a080e7          	jalr	1674(ra) # 80000582 <printf>
    printf("\n");
    80000f00:	00007517          	auipc	a0,0x7
    80000f04:	1c850513          	addi	a0,a0,456 # 800080c8 <digits+0x88>
    80000f08:	fffff097          	auipc	ra,0xfffff
    80000f0c:	67a080e7          	jalr	1658(ra) # 80000582 <printf>
    kinit();         // physical page allocator
    80000f10:	00000097          	auipc	ra,0x0
    80000f14:	b94080e7          	jalr	-1132(ra) # 80000aa4 <kinit>
    kvminit();       // create kernel page table
    80000f18:	00000097          	auipc	ra,0x0
    80000f1c:	322080e7          	jalr	802(ra) # 8000123a <kvminit>
    kvminithart();   // turn on paging
    80000f20:	00000097          	auipc	ra,0x0
    80000f24:	068080e7          	jalr	104(ra) # 80000f88 <kvminithart>
    procinit();      // process table
    80000f28:	00001097          	auipc	ra,0x1
    80000f2c:	992080e7          	jalr	-1646(ra) # 800018ba <procinit>
    trapinit();      // trap vectors
    80000f30:	00001097          	auipc	ra,0x1
    80000f34:	754080e7          	jalr	1876(ra) # 80002684 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00001097          	auipc	ra,0x1
    80000f3c:	774080e7          	jalr	1908(ra) # 800026ac <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	daa080e7          	jalr	-598(ra) # 80005cea <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	db8080e7          	jalr	-584(ra) # 80005d00 <plicinithart>
    binit();         // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	f8e080e7          	jalr	-114(ra) # 80002ede <binit>
    iinit();         // inode table
    80000f58:	00002097          	auipc	ra,0x2
    80000f5c:	61e080e7          	jalr	1566(ra) # 80003576 <iinit>
    fileinit();      // file table
    80000f60:	00003097          	auipc	ra,0x3
    80000f64:	5c8080e7          	jalr	1480(ra) # 80004528 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	eba080e7          	jalr	-326(ra) # 80005e22 <virtio_disk_init>
    userinit();      // first user process
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	cfe080e7          	jalr	-770(ra) # 80001c6e <userinit>
    __sync_synchronize();
    80000f78:	0ff0000f          	fence
    started = 1;
    80000f7c:	4785                	li	a5,1
    80000f7e:	00008717          	auipc	a4,0x8
    80000f82:	08f72d23          	sw	a5,154(a4) # 80009018 <started>
    80000f86:	b789                	j	80000ec8 <main+0x56>

0000000080000f88 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f88:	1141                	addi	sp,sp,-16
    80000f8a:	e422                	sd	s0,8(sp)
    80000f8c:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000f8e:	00008797          	auipc	a5,0x8
    80000f92:	0927b783          	ld	a5,146(a5) # 80009020 <kernel_pagetable>
    80000f96:	83b1                	srli	a5,a5,0xc
    80000f98:	577d                	li	a4,-1
    80000f9a:	177e                	slli	a4,a4,0x3f
    80000f9c:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f9e:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fa2:	12000073          	sfence.vma
  sfence_vma();
}
    80000fa6:	6422                	ld	s0,8(sp)
    80000fa8:	0141                	addi	sp,sp,16
    80000faa:	8082                	ret

0000000080000fac <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fac:	7139                	addi	sp,sp,-64
    80000fae:	fc06                	sd	ra,56(sp)
    80000fb0:	f822                	sd	s0,48(sp)
    80000fb2:	f426                	sd	s1,40(sp)
    80000fb4:	f04a                	sd	s2,32(sp)
    80000fb6:	ec4e                	sd	s3,24(sp)
    80000fb8:	e852                	sd	s4,16(sp)
    80000fba:	e456                	sd	s5,8(sp)
    80000fbc:	e05a                	sd	s6,0(sp)
    80000fbe:	0080                	addi	s0,sp,64
    80000fc0:	84aa                	mv	s1,a0
    80000fc2:	89ae                	mv	s3,a1
    80000fc4:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fc6:	57fd                	li	a5,-1
    80000fc8:	83e9                	srli	a5,a5,0x1a
    80000fca:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fcc:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fce:	04b7f263          	bgeu	a5,a1,80001012 <walk+0x66>
    panic("walk");
    80000fd2:	00007517          	auipc	a0,0x7
    80000fd6:	0fe50513          	addi	a0,a0,254 # 800080d0 <digits+0x90>
    80000fda:	fffff097          	auipc	ra,0xfffff
    80000fde:	55e080e7          	jalr	1374(ra) # 80000538 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fe2:	060a8663          	beqz	s5,8000104e <walk+0xa2>
    80000fe6:	00000097          	auipc	ra,0x0
    80000fea:	afa080e7          	jalr	-1286(ra) # 80000ae0 <kalloc>
    80000fee:	84aa                	mv	s1,a0
    80000ff0:	c529                	beqz	a0,8000103a <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ff2:	6605                	lui	a2,0x1
    80000ff4:	4581                	li	a1,0
    80000ff6:	00000097          	auipc	ra,0x0
    80000ffa:	cd6080e7          	jalr	-810(ra) # 80000ccc <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000ffe:	00c4d793          	srli	a5,s1,0xc
    80001002:	07aa                	slli	a5,a5,0xa
    80001004:	0017e793          	ori	a5,a5,1
    80001008:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000100c:	3a5d                	addiw	s4,s4,-9
    8000100e:	036a0063          	beq	s4,s6,8000102e <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001012:	0149d933          	srl	s2,s3,s4
    80001016:	1ff97913          	andi	s2,s2,511
    8000101a:	090e                	slli	s2,s2,0x3
    8000101c:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000101e:	00093483          	ld	s1,0(s2)
    80001022:	0014f793          	andi	a5,s1,1
    80001026:	dfd5                	beqz	a5,80000fe2 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001028:	80a9                	srli	s1,s1,0xa
    8000102a:	04b2                	slli	s1,s1,0xc
    8000102c:	b7c5                	j	8000100c <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000102e:	00c9d513          	srli	a0,s3,0xc
    80001032:	1ff57513          	andi	a0,a0,511
    80001036:	050e                	slli	a0,a0,0x3
    80001038:	9526                	add	a0,a0,s1
}
    8000103a:	70e2                	ld	ra,56(sp)
    8000103c:	7442                	ld	s0,48(sp)
    8000103e:	74a2                	ld	s1,40(sp)
    80001040:	7902                	ld	s2,32(sp)
    80001042:	69e2                	ld	s3,24(sp)
    80001044:	6a42                	ld	s4,16(sp)
    80001046:	6aa2                	ld	s5,8(sp)
    80001048:	6b02                	ld	s6,0(sp)
    8000104a:	6121                	addi	sp,sp,64
    8000104c:	8082                	ret
        return 0;
    8000104e:	4501                	li	a0,0
    80001050:	b7ed                	j	8000103a <walk+0x8e>

0000000080001052 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001052:	57fd                	li	a5,-1
    80001054:	83e9                	srli	a5,a5,0x1a
    80001056:	00b7f463          	bgeu	a5,a1,8000105e <walkaddr+0xc>
    return 0;
    8000105a:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000105c:	8082                	ret
{
    8000105e:	1141                	addi	sp,sp,-16
    80001060:	e406                	sd	ra,8(sp)
    80001062:	e022                	sd	s0,0(sp)
    80001064:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001066:	4601                	li	a2,0
    80001068:	00000097          	auipc	ra,0x0
    8000106c:	f44080e7          	jalr	-188(ra) # 80000fac <walk>
  if(pte == 0)
    80001070:	c105                	beqz	a0,80001090 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001072:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001074:	0117f693          	andi	a3,a5,17
    80001078:	4745                	li	a4,17
    return 0;
    8000107a:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000107c:	00e68663          	beq	a3,a4,80001088 <walkaddr+0x36>
}
    80001080:	60a2                	ld	ra,8(sp)
    80001082:	6402                	ld	s0,0(sp)
    80001084:	0141                	addi	sp,sp,16
    80001086:	8082                	ret
  pa = PTE2PA(*pte);
    80001088:	00a7d513          	srli	a0,a5,0xa
    8000108c:	0532                	slli	a0,a0,0xc
  return pa;
    8000108e:	bfcd                	j	80001080 <walkaddr+0x2e>
    return 0;
    80001090:	4501                	li	a0,0
    80001092:	b7fd                	j	80001080 <walkaddr+0x2e>

0000000080001094 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001094:	715d                	addi	sp,sp,-80
    80001096:	e486                	sd	ra,72(sp)
    80001098:	e0a2                	sd	s0,64(sp)
    8000109a:	fc26                	sd	s1,56(sp)
    8000109c:	f84a                	sd	s2,48(sp)
    8000109e:	f44e                	sd	s3,40(sp)
    800010a0:	f052                	sd	s4,32(sp)
    800010a2:	ec56                	sd	s5,24(sp)
    800010a4:	e85a                	sd	s6,16(sp)
    800010a6:	e45e                	sd	s7,8(sp)
    800010a8:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010aa:	c639                	beqz	a2,800010f8 <mappages+0x64>
    800010ac:	8aaa                	mv	s5,a0
    800010ae:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010b0:	77fd                	lui	a5,0xfffff
    800010b2:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010b6:	15fd                	addi	a1,a1,-1
    800010b8:	00c589b3          	add	s3,a1,a2
    800010bc:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010c0:	8952                	mv	s2,s4
    800010c2:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010c6:	6b85                	lui	s7,0x1
    800010c8:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010cc:	4605                	li	a2,1
    800010ce:	85ca                	mv	a1,s2
    800010d0:	8556                	mv	a0,s5
    800010d2:	00000097          	auipc	ra,0x0
    800010d6:	eda080e7          	jalr	-294(ra) # 80000fac <walk>
    800010da:	cd1d                	beqz	a0,80001118 <mappages+0x84>
    if(*pte & PTE_V)
    800010dc:	611c                	ld	a5,0(a0)
    800010de:	8b85                	andi	a5,a5,1
    800010e0:	e785                	bnez	a5,80001108 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010e2:	80b1                	srli	s1,s1,0xc
    800010e4:	04aa                	slli	s1,s1,0xa
    800010e6:	0164e4b3          	or	s1,s1,s6
    800010ea:	0014e493          	ori	s1,s1,1
    800010ee:	e104                	sd	s1,0(a0)
    if(a == last)
    800010f0:	05390063          	beq	s2,s3,80001130 <mappages+0x9c>
    a += PGSIZE;
    800010f4:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800010f6:	bfc9                	j	800010c8 <mappages+0x34>
    panic("mappages: size");
    800010f8:	00007517          	auipc	a0,0x7
    800010fc:	fe050513          	addi	a0,a0,-32 # 800080d8 <digits+0x98>
    80001100:	fffff097          	auipc	ra,0xfffff
    80001104:	438080e7          	jalr	1080(ra) # 80000538 <panic>
      panic("mappages: remap");
    80001108:	00007517          	auipc	a0,0x7
    8000110c:	fe050513          	addi	a0,a0,-32 # 800080e8 <digits+0xa8>
    80001110:	fffff097          	auipc	ra,0xfffff
    80001114:	428080e7          	jalr	1064(ra) # 80000538 <panic>
      return -1;
    80001118:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000111a:	60a6                	ld	ra,72(sp)
    8000111c:	6406                	ld	s0,64(sp)
    8000111e:	74e2                	ld	s1,56(sp)
    80001120:	7942                	ld	s2,48(sp)
    80001122:	79a2                	ld	s3,40(sp)
    80001124:	7a02                	ld	s4,32(sp)
    80001126:	6ae2                	ld	s5,24(sp)
    80001128:	6b42                	ld	s6,16(sp)
    8000112a:	6ba2                	ld	s7,8(sp)
    8000112c:	6161                	addi	sp,sp,80
    8000112e:	8082                	ret
  return 0;
    80001130:	4501                	li	a0,0
    80001132:	b7e5                	j	8000111a <mappages+0x86>

0000000080001134 <kvmmap>:
{
    80001134:	1141                	addi	sp,sp,-16
    80001136:	e406                	sd	ra,8(sp)
    80001138:	e022                	sd	s0,0(sp)
    8000113a:	0800                	addi	s0,sp,16
    8000113c:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000113e:	86b2                	mv	a3,a2
    80001140:	863e                	mv	a2,a5
    80001142:	00000097          	auipc	ra,0x0
    80001146:	f52080e7          	jalr	-174(ra) # 80001094 <mappages>
    8000114a:	e509                	bnez	a0,80001154 <kvmmap+0x20>
}
    8000114c:	60a2                	ld	ra,8(sp)
    8000114e:	6402                	ld	s0,0(sp)
    80001150:	0141                	addi	sp,sp,16
    80001152:	8082                	ret
    panic("kvmmap");
    80001154:	00007517          	auipc	a0,0x7
    80001158:	fa450513          	addi	a0,a0,-92 # 800080f8 <digits+0xb8>
    8000115c:	fffff097          	auipc	ra,0xfffff
    80001160:	3dc080e7          	jalr	988(ra) # 80000538 <panic>

0000000080001164 <kvmmake>:
{
    80001164:	1101                	addi	sp,sp,-32
    80001166:	ec06                	sd	ra,24(sp)
    80001168:	e822                	sd	s0,16(sp)
    8000116a:	e426                	sd	s1,8(sp)
    8000116c:	e04a                	sd	s2,0(sp)
    8000116e:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001170:	00000097          	auipc	ra,0x0
    80001174:	970080e7          	jalr	-1680(ra) # 80000ae0 <kalloc>
    80001178:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000117a:	6605                	lui	a2,0x1
    8000117c:	4581                	li	a1,0
    8000117e:	00000097          	auipc	ra,0x0
    80001182:	b4e080e7          	jalr	-1202(ra) # 80000ccc <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001186:	4719                	li	a4,6
    80001188:	6685                	lui	a3,0x1
    8000118a:	10000637          	lui	a2,0x10000
    8000118e:	100005b7          	lui	a1,0x10000
    80001192:	8526                	mv	a0,s1
    80001194:	00000097          	auipc	ra,0x0
    80001198:	fa0080e7          	jalr	-96(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000119c:	4719                	li	a4,6
    8000119e:	6685                	lui	a3,0x1
    800011a0:	10001637          	lui	a2,0x10001
    800011a4:	100015b7          	lui	a1,0x10001
    800011a8:	8526                	mv	a0,s1
    800011aa:	00000097          	auipc	ra,0x0
    800011ae:	f8a080e7          	jalr	-118(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011b2:	4719                	li	a4,6
    800011b4:	004006b7          	lui	a3,0x400
    800011b8:	0c000637          	lui	a2,0xc000
    800011bc:	0c0005b7          	lui	a1,0xc000
    800011c0:	8526                	mv	a0,s1
    800011c2:	00000097          	auipc	ra,0x0
    800011c6:	f72080e7          	jalr	-142(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ca:	00007917          	auipc	s2,0x7
    800011ce:	e3690913          	addi	s2,s2,-458 # 80008000 <etext>
    800011d2:	4729                	li	a4,10
    800011d4:	80007697          	auipc	a3,0x80007
    800011d8:	e2c68693          	addi	a3,a3,-468 # 8000 <_entry-0x7fff8000>
    800011dc:	4605                	li	a2,1
    800011de:	067e                	slli	a2,a2,0x1f
    800011e0:	85b2                	mv	a1,a2
    800011e2:	8526                	mv	a0,s1
    800011e4:	00000097          	auipc	ra,0x0
    800011e8:	f50080e7          	jalr	-176(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011ec:	4719                	li	a4,6
    800011ee:	46c5                	li	a3,17
    800011f0:	06ee                	slli	a3,a3,0x1b
    800011f2:	412686b3          	sub	a3,a3,s2
    800011f6:	864a                	mv	a2,s2
    800011f8:	85ca                	mv	a1,s2
    800011fa:	8526                	mv	a0,s1
    800011fc:	00000097          	auipc	ra,0x0
    80001200:	f38080e7          	jalr	-200(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001204:	4729                	li	a4,10
    80001206:	6685                	lui	a3,0x1
    80001208:	00006617          	auipc	a2,0x6
    8000120c:	df860613          	addi	a2,a2,-520 # 80007000 <_trampoline>
    80001210:	040005b7          	lui	a1,0x4000
    80001214:	15fd                	addi	a1,a1,-1
    80001216:	05b2                	slli	a1,a1,0xc
    80001218:	8526                	mv	a0,s1
    8000121a:	00000097          	auipc	ra,0x0
    8000121e:	f1a080e7          	jalr	-230(ra) # 80001134 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	600080e7          	jalr	1536(ra) # 80001824 <proc_mapstacks>
}
    8000122c:	8526                	mv	a0,s1
    8000122e:	60e2                	ld	ra,24(sp)
    80001230:	6442                	ld	s0,16(sp)
    80001232:	64a2                	ld	s1,8(sp)
    80001234:	6902                	ld	s2,0(sp)
    80001236:	6105                	addi	sp,sp,32
    80001238:	8082                	ret

000000008000123a <kvminit>:
{
    8000123a:	1141                	addi	sp,sp,-16
    8000123c:	e406                	sd	ra,8(sp)
    8000123e:	e022                	sd	s0,0(sp)
    80001240:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001242:	00000097          	auipc	ra,0x0
    80001246:	f22080e7          	jalr	-222(ra) # 80001164 <kvmmake>
    8000124a:	00008797          	auipc	a5,0x8
    8000124e:	dca7bb23          	sd	a0,-554(a5) # 80009020 <kernel_pagetable>
}
    80001252:	60a2                	ld	ra,8(sp)
    80001254:	6402                	ld	s0,0(sp)
    80001256:	0141                	addi	sp,sp,16
    80001258:	8082                	ret

000000008000125a <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000125a:	715d                	addi	sp,sp,-80
    8000125c:	e486                	sd	ra,72(sp)
    8000125e:	e0a2                	sd	s0,64(sp)
    80001260:	fc26                	sd	s1,56(sp)
    80001262:	f84a                	sd	s2,48(sp)
    80001264:	f44e                	sd	s3,40(sp)
    80001266:	f052                	sd	s4,32(sp)
    80001268:	ec56                	sd	s5,24(sp)
    8000126a:	e85a                	sd	s6,16(sp)
    8000126c:	e45e                	sd	s7,8(sp)
    8000126e:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001270:	03459793          	slli	a5,a1,0x34
    80001274:	e795                	bnez	a5,800012a0 <uvmunmap+0x46>
    80001276:	8a2a                	mv	s4,a0
    80001278:	892e                	mv	s2,a1
    8000127a:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000127c:	0632                	slli	a2,a2,0xc
    8000127e:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001282:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001284:	6b05                	lui	s6,0x1
    80001286:	0735e263          	bltu	a1,s3,800012ea <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000128a:	60a6                	ld	ra,72(sp)
    8000128c:	6406                	ld	s0,64(sp)
    8000128e:	74e2                	ld	s1,56(sp)
    80001290:	7942                	ld	s2,48(sp)
    80001292:	79a2                	ld	s3,40(sp)
    80001294:	7a02                	ld	s4,32(sp)
    80001296:	6ae2                	ld	s5,24(sp)
    80001298:	6b42                	ld	s6,16(sp)
    8000129a:	6ba2                	ld	s7,8(sp)
    8000129c:	6161                	addi	sp,sp,80
    8000129e:	8082                	ret
    panic("uvmunmap: not aligned");
    800012a0:	00007517          	auipc	a0,0x7
    800012a4:	e6050513          	addi	a0,a0,-416 # 80008100 <digits+0xc0>
    800012a8:	fffff097          	auipc	ra,0xfffff
    800012ac:	290080e7          	jalr	656(ra) # 80000538 <panic>
      panic("uvmunmap: walk");
    800012b0:	00007517          	auipc	a0,0x7
    800012b4:	e6850513          	addi	a0,a0,-408 # 80008118 <digits+0xd8>
    800012b8:	fffff097          	auipc	ra,0xfffff
    800012bc:	280080e7          	jalr	640(ra) # 80000538 <panic>
      panic("uvmunmap: not mapped");
    800012c0:	00007517          	auipc	a0,0x7
    800012c4:	e6850513          	addi	a0,a0,-408 # 80008128 <digits+0xe8>
    800012c8:	fffff097          	auipc	ra,0xfffff
    800012cc:	270080e7          	jalr	624(ra) # 80000538 <panic>
      panic("uvmunmap: not a leaf");
    800012d0:	00007517          	auipc	a0,0x7
    800012d4:	e7050513          	addi	a0,a0,-400 # 80008140 <digits+0x100>
    800012d8:	fffff097          	auipc	ra,0xfffff
    800012dc:	260080e7          	jalr	608(ra) # 80000538 <panic>
    *pte = 0;
    800012e0:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012e4:	995a                	add	s2,s2,s6
    800012e6:	fb3972e3          	bgeu	s2,s3,8000128a <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012ea:	4601                	li	a2,0
    800012ec:	85ca                	mv	a1,s2
    800012ee:	8552                	mv	a0,s4
    800012f0:	00000097          	auipc	ra,0x0
    800012f4:	cbc080e7          	jalr	-836(ra) # 80000fac <walk>
    800012f8:	84aa                	mv	s1,a0
    800012fa:	d95d                	beqz	a0,800012b0 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800012fc:	6108                	ld	a0,0(a0)
    800012fe:	00157793          	andi	a5,a0,1
    80001302:	dfdd                	beqz	a5,800012c0 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001304:	3ff57793          	andi	a5,a0,1023
    80001308:	fd7784e3          	beq	a5,s7,800012d0 <uvmunmap+0x76>
    if(do_free){
    8000130c:	fc0a8ae3          	beqz	s5,800012e0 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001310:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001312:	0532                	slli	a0,a0,0xc
    80001314:	fffff097          	auipc	ra,0xfffff
    80001318:	6d0080e7          	jalr	1744(ra) # 800009e4 <kfree>
    8000131c:	b7d1                	j	800012e0 <uvmunmap+0x86>

000000008000131e <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000131e:	1101                	addi	sp,sp,-32
    80001320:	ec06                	sd	ra,24(sp)
    80001322:	e822                	sd	s0,16(sp)
    80001324:	e426                	sd	s1,8(sp)
    80001326:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001328:	fffff097          	auipc	ra,0xfffff
    8000132c:	7b8080e7          	jalr	1976(ra) # 80000ae0 <kalloc>
    80001330:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001332:	c519                	beqz	a0,80001340 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001334:	6605                	lui	a2,0x1
    80001336:	4581                	li	a1,0
    80001338:	00000097          	auipc	ra,0x0
    8000133c:	994080e7          	jalr	-1644(ra) # 80000ccc <memset>
  return pagetable;
}
    80001340:	8526                	mv	a0,s1
    80001342:	60e2                	ld	ra,24(sp)
    80001344:	6442                	ld	s0,16(sp)
    80001346:	64a2                	ld	s1,8(sp)
    80001348:	6105                	addi	sp,sp,32
    8000134a:	8082                	ret

000000008000134c <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000134c:	7179                	addi	sp,sp,-48
    8000134e:	f406                	sd	ra,40(sp)
    80001350:	f022                	sd	s0,32(sp)
    80001352:	ec26                	sd	s1,24(sp)
    80001354:	e84a                	sd	s2,16(sp)
    80001356:	e44e                	sd	s3,8(sp)
    80001358:	e052                	sd	s4,0(sp)
    8000135a:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000135c:	6785                	lui	a5,0x1
    8000135e:	04f67863          	bgeu	a2,a5,800013ae <uvminit+0x62>
    80001362:	8a2a                	mv	s4,a0
    80001364:	89ae                	mv	s3,a1
    80001366:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001368:	fffff097          	auipc	ra,0xfffff
    8000136c:	778080e7          	jalr	1912(ra) # 80000ae0 <kalloc>
    80001370:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001372:	6605                	lui	a2,0x1
    80001374:	4581                	li	a1,0
    80001376:	00000097          	auipc	ra,0x0
    8000137a:	956080e7          	jalr	-1706(ra) # 80000ccc <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000137e:	4779                	li	a4,30
    80001380:	86ca                	mv	a3,s2
    80001382:	6605                	lui	a2,0x1
    80001384:	4581                	li	a1,0
    80001386:	8552                	mv	a0,s4
    80001388:	00000097          	auipc	ra,0x0
    8000138c:	d0c080e7          	jalr	-756(ra) # 80001094 <mappages>
  memmove(mem, src, sz);
    80001390:	8626                	mv	a2,s1
    80001392:	85ce                	mv	a1,s3
    80001394:	854a                	mv	a0,s2
    80001396:	00000097          	auipc	ra,0x0
    8000139a:	992080e7          	jalr	-1646(ra) # 80000d28 <memmove>
}
    8000139e:	70a2                	ld	ra,40(sp)
    800013a0:	7402                	ld	s0,32(sp)
    800013a2:	64e2                	ld	s1,24(sp)
    800013a4:	6942                	ld	s2,16(sp)
    800013a6:	69a2                	ld	s3,8(sp)
    800013a8:	6a02                	ld	s4,0(sp)
    800013aa:	6145                	addi	sp,sp,48
    800013ac:	8082                	ret
    panic("inituvm: more than a page");
    800013ae:	00007517          	auipc	a0,0x7
    800013b2:	daa50513          	addi	a0,a0,-598 # 80008158 <digits+0x118>
    800013b6:	fffff097          	auipc	ra,0xfffff
    800013ba:	182080e7          	jalr	386(ra) # 80000538 <panic>

00000000800013be <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013be:	1101                	addi	sp,sp,-32
    800013c0:	ec06                	sd	ra,24(sp)
    800013c2:	e822                	sd	s0,16(sp)
    800013c4:	e426                	sd	s1,8(sp)
    800013c6:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013c8:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013ca:	00b67d63          	bgeu	a2,a1,800013e4 <uvmdealloc+0x26>
    800013ce:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013d0:	6785                	lui	a5,0x1
    800013d2:	17fd                	addi	a5,a5,-1
    800013d4:	00f60733          	add	a4,a2,a5
    800013d8:	767d                	lui	a2,0xfffff
    800013da:	8f71                	and	a4,a4,a2
    800013dc:	97ae                	add	a5,a5,a1
    800013de:	8ff1                	and	a5,a5,a2
    800013e0:	00f76863          	bltu	a4,a5,800013f0 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013e4:	8526                	mv	a0,s1
    800013e6:	60e2                	ld	ra,24(sp)
    800013e8:	6442                	ld	s0,16(sp)
    800013ea:	64a2                	ld	s1,8(sp)
    800013ec:	6105                	addi	sp,sp,32
    800013ee:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013f0:	8f99                	sub	a5,a5,a4
    800013f2:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013f4:	4685                	li	a3,1
    800013f6:	0007861b          	sext.w	a2,a5
    800013fa:	85ba                	mv	a1,a4
    800013fc:	00000097          	auipc	ra,0x0
    80001400:	e5e080e7          	jalr	-418(ra) # 8000125a <uvmunmap>
    80001404:	b7c5                	j	800013e4 <uvmdealloc+0x26>

0000000080001406 <uvmalloc>:
  if(newsz < oldsz)
    80001406:	0ab66163          	bltu	a2,a1,800014a8 <uvmalloc+0xa2>
{
    8000140a:	7139                	addi	sp,sp,-64
    8000140c:	fc06                	sd	ra,56(sp)
    8000140e:	f822                	sd	s0,48(sp)
    80001410:	f426                	sd	s1,40(sp)
    80001412:	f04a                	sd	s2,32(sp)
    80001414:	ec4e                	sd	s3,24(sp)
    80001416:	e852                	sd	s4,16(sp)
    80001418:	e456                	sd	s5,8(sp)
    8000141a:	0080                	addi	s0,sp,64
    8000141c:	8aaa                	mv	s5,a0
    8000141e:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001420:	6985                	lui	s3,0x1
    80001422:	19fd                	addi	s3,s3,-1
    80001424:	95ce                	add	a1,a1,s3
    80001426:	79fd                	lui	s3,0xfffff
    80001428:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000142c:	08c9f063          	bgeu	s3,a2,800014ac <uvmalloc+0xa6>
    80001430:	894e                	mv	s2,s3
    mem = kalloc();
    80001432:	fffff097          	auipc	ra,0xfffff
    80001436:	6ae080e7          	jalr	1710(ra) # 80000ae0 <kalloc>
    8000143a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000143c:	c51d                	beqz	a0,8000146a <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000143e:	6605                	lui	a2,0x1
    80001440:	4581                	li	a1,0
    80001442:	00000097          	auipc	ra,0x0
    80001446:	88a080e7          	jalr	-1910(ra) # 80000ccc <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000144a:	4779                	li	a4,30
    8000144c:	86a6                	mv	a3,s1
    8000144e:	6605                	lui	a2,0x1
    80001450:	85ca                	mv	a1,s2
    80001452:	8556                	mv	a0,s5
    80001454:	00000097          	auipc	ra,0x0
    80001458:	c40080e7          	jalr	-960(ra) # 80001094 <mappages>
    8000145c:	e905                	bnez	a0,8000148c <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000145e:	6785                	lui	a5,0x1
    80001460:	993e                	add	s2,s2,a5
    80001462:	fd4968e3          	bltu	s2,s4,80001432 <uvmalloc+0x2c>
  return newsz;
    80001466:	8552                	mv	a0,s4
    80001468:	a809                	j	8000147a <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000146a:	864e                	mv	a2,s3
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	f4e080e7          	jalr	-178(ra) # 800013be <uvmdealloc>
      return 0;
    80001478:	4501                	li	a0,0
}
    8000147a:	70e2                	ld	ra,56(sp)
    8000147c:	7442                	ld	s0,48(sp)
    8000147e:	74a2                	ld	s1,40(sp)
    80001480:	7902                	ld	s2,32(sp)
    80001482:	69e2                	ld	s3,24(sp)
    80001484:	6a42                	ld	s4,16(sp)
    80001486:	6aa2                	ld	s5,8(sp)
    80001488:	6121                	addi	sp,sp,64
    8000148a:	8082                	ret
      kfree(mem);
    8000148c:	8526                	mv	a0,s1
    8000148e:	fffff097          	auipc	ra,0xfffff
    80001492:	556080e7          	jalr	1366(ra) # 800009e4 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001496:	864e                	mv	a2,s3
    80001498:	85ca                	mv	a1,s2
    8000149a:	8556                	mv	a0,s5
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	f22080e7          	jalr	-222(ra) # 800013be <uvmdealloc>
      return 0;
    800014a4:	4501                	li	a0,0
    800014a6:	bfd1                	j	8000147a <uvmalloc+0x74>
    return oldsz;
    800014a8:	852e                	mv	a0,a1
}
    800014aa:	8082                	ret
  return newsz;
    800014ac:	8532                	mv	a0,a2
    800014ae:	b7f1                	j	8000147a <uvmalloc+0x74>

00000000800014b0 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014b0:	7179                	addi	sp,sp,-48
    800014b2:	f406                	sd	ra,40(sp)
    800014b4:	f022                	sd	s0,32(sp)
    800014b6:	ec26                	sd	s1,24(sp)
    800014b8:	e84a                	sd	s2,16(sp)
    800014ba:	e44e                	sd	s3,8(sp)
    800014bc:	e052                	sd	s4,0(sp)
    800014be:	1800                	addi	s0,sp,48
    800014c0:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014c2:	84aa                	mv	s1,a0
    800014c4:	6905                	lui	s2,0x1
    800014c6:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014c8:	4985                	li	s3,1
    800014ca:	a821                	j	800014e2 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014cc:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ce:	0532                	slli	a0,a0,0xc
    800014d0:	00000097          	auipc	ra,0x0
    800014d4:	fe0080e7          	jalr	-32(ra) # 800014b0 <freewalk>
      pagetable[i] = 0;
    800014d8:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014dc:	04a1                	addi	s1,s1,8
    800014de:	03248163          	beq	s1,s2,80001500 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014e2:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	00f57793          	andi	a5,a0,15
    800014e8:	ff3782e3          	beq	a5,s3,800014cc <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014ec:	8905                	andi	a0,a0,1
    800014ee:	d57d                	beqz	a0,800014dc <freewalk+0x2c>
      panic("freewalk: leaf");
    800014f0:	00007517          	auipc	a0,0x7
    800014f4:	c8850513          	addi	a0,a0,-888 # 80008178 <digits+0x138>
    800014f8:	fffff097          	auipc	ra,0xfffff
    800014fc:	040080e7          	jalr	64(ra) # 80000538 <panic>
    }
  }
  kfree((void*)pagetable);
    80001500:	8552                	mv	a0,s4
    80001502:	fffff097          	auipc	ra,0xfffff
    80001506:	4e2080e7          	jalr	1250(ra) # 800009e4 <kfree>
}
    8000150a:	70a2                	ld	ra,40(sp)
    8000150c:	7402                	ld	s0,32(sp)
    8000150e:	64e2                	ld	s1,24(sp)
    80001510:	6942                	ld	s2,16(sp)
    80001512:	69a2                	ld	s3,8(sp)
    80001514:	6a02                	ld	s4,0(sp)
    80001516:	6145                	addi	sp,sp,48
    80001518:	8082                	ret

000000008000151a <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000151a:	1101                	addi	sp,sp,-32
    8000151c:	ec06                	sd	ra,24(sp)
    8000151e:	e822                	sd	s0,16(sp)
    80001520:	e426                	sd	s1,8(sp)
    80001522:	1000                	addi	s0,sp,32
    80001524:	84aa                	mv	s1,a0
  if(sz > 0)
    80001526:	e999                	bnez	a1,8000153c <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001528:	8526                	mv	a0,s1
    8000152a:	00000097          	auipc	ra,0x0
    8000152e:	f86080e7          	jalr	-122(ra) # 800014b0 <freewalk>
}
    80001532:	60e2                	ld	ra,24(sp)
    80001534:	6442                	ld	s0,16(sp)
    80001536:	64a2                	ld	s1,8(sp)
    80001538:	6105                	addi	sp,sp,32
    8000153a:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000153c:	6605                	lui	a2,0x1
    8000153e:	167d                	addi	a2,a2,-1
    80001540:	962e                	add	a2,a2,a1
    80001542:	4685                	li	a3,1
    80001544:	8231                	srli	a2,a2,0xc
    80001546:	4581                	li	a1,0
    80001548:	00000097          	auipc	ra,0x0
    8000154c:	d12080e7          	jalr	-750(ra) # 8000125a <uvmunmap>
    80001550:	bfe1                	j	80001528 <uvmfree+0xe>

0000000080001552 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001552:	c679                	beqz	a2,80001620 <uvmcopy+0xce>
{
    80001554:	715d                	addi	sp,sp,-80
    80001556:	e486                	sd	ra,72(sp)
    80001558:	e0a2                	sd	s0,64(sp)
    8000155a:	fc26                	sd	s1,56(sp)
    8000155c:	f84a                	sd	s2,48(sp)
    8000155e:	f44e                	sd	s3,40(sp)
    80001560:	f052                	sd	s4,32(sp)
    80001562:	ec56                	sd	s5,24(sp)
    80001564:	e85a                	sd	s6,16(sp)
    80001566:	e45e                	sd	s7,8(sp)
    80001568:	0880                	addi	s0,sp,80
    8000156a:	8b2a                	mv	s6,a0
    8000156c:	8aae                	mv	s5,a1
    8000156e:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001570:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001572:	4601                	li	a2,0
    80001574:	85ce                	mv	a1,s3
    80001576:	855a                	mv	a0,s6
    80001578:	00000097          	auipc	ra,0x0
    8000157c:	a34080e7          	jalr	-1484(ra) # 80000fac <walk>
    80001580:	c531                	beqz	a0,800015cc <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001582:	6118                	ld	a4,0(a0)
    80001584:	00177793          	andi	a5,a4,1
    80001588:	cbb1                	beqz	a5,800015dc <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000158a:	00a75593          	srli	a1,a4,0xa
    8000158e:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001592:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001596:	fffff097          	auipc	ra,0xfffff
    8000159a:	54a080e7          	jalr	1354(ra) # 80000ae0 <kalloc>
    8000159e:	892a                	mv	s2,a0
    800015a0:	c939                	beqz	a0,800015f6 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015a2:	6605                	lui	a2,0x1
    800015a4:	85de                	mv	a1,s7
    800015a6:	fffff097          	auipc	ra,0xfffff
    800015aa:	782080e7          	jalr	1922(ra) # 80000d28 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ae:	8726                	mv	a4,s1
    800015b0:	86ca                	mv	a3,s2
    800015b2:	6605                	lui	a2,0x1
    800015b4:	85ce                	mv	a1,s3
    800015b6:	8556                	mv	a0,s5
    800015b8:	00000097          	auipc	ra,0x0
    800015bc:	adc080e7          	jalr	-1316(ra) # 80001094 <mappages>
    800015c0:	e515                	bnez	a0,800015ec <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015c2:	6785                	lui	a5,0x1
    800015c4:	99be                	add	s3,s3,a5
    800015c6:	fb49e6e3          	bltu	s3,s4,80001572 <uvmcopy+0x20>
    800015ca:	a081                	j	8000160a <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015cc:	00007517          	auipc	a0,0x7
    800015d0:	bbc50513          	addi	a0,a0,-1092 # 80008188 <digits+0x148>
    800015d4:	fffff097          	auipc	ra,0xfffff
    800015d8:	f64080e7          	jalr	-156(ra) # 80000538 <panic>
      panic("uvmcopy: page not present");
    800015dc:	00007517          	auipc	a0,0x7
    800015e0:	bcc50513          	addi	a0,a0,-1076 # 800081a8 <digits+0x168>
    800015e4:	fffff097          	auipc	ra,0xfffff
    800015e8:	f54080e7          	jalr	-172(ra) # 80000538 <panic>
      kfree(mem);
    800015ec:	854a                	mv	a0,s2
    800015ee:	fffff097          	auipc	ra,0xfffff
    800015f2:	3f6080e7          	jalr	1014(ra) # 800009e4 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800015f6:	4685                	li	a3,1
    800015f8:	00c9d613          	srli	a2,s3,0xc
    800015fc:	4581                	li	a1,0
    800015fe:	8556                	mv	a0,s5
    80001600:	00000097          	auipc	ra,0x0
    80001604:	c5a080e7          	jalr	-934(ra) # 8000125a <uvmunmap>
  return -1;
    80001608:	557d                	li	a0,-1
}
    8000160a:	60a6                	ld	ra,72(sp)
    8000160c:	6406                	ld	s0,64(sp)
    8000160e:	74e2                	ld	s1,56(sp)
    80001610:	7942                	ld	s2,48(sp)
    80001612:	79a2                	ld	s3,40(sp)
    80001614:	7a02                	ld	s4,32(sp)
    80001616:	6ae2                	ld	s5,24(sp)
    80001618:	6b42                	ld	s6,16(sp)
    8000161a:	6ba2                	ld	s7,8(sp)
    8000161c:	6161                	addi	sp,sp,80
    8000161e:	8082                	ret
  return 0;
    80001620:	4501                	li	a0,0
}
    80001622:	8082                	ret

0000000080001624 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001624:	1141                	addi	sp,sp,-16
    80001626:	e406                	sd	ra,8(sp)
    80001628:	e022                	sd	s0,0(sp)
    8000162a:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000162c:	4601                	li	a2,0
    8000162e:	00000097          	auipc	ra,0x0
    80001632:	97e080e7          	jalr	-1666(ra) # 80000fac <walk>
  if(pte == 0)
    80001636:	c901                	beqz	a0,80001646 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001638:	611c                	ld	a5,0(a0)
    8000163a:	9bbd                	andi	a5,a5,-17
    8000163c:	e11c                	sd	a5,0(a0)
}
    8000163e:	60a2                	ld	ra,8(sp)
    80001640:	6402                	ld	s0,0(sp)
    80001642:	0141                	addi	sp,sp,16
    80001644:	8082                	ret
    panic("uvmclear");
    80001646:	00007517          	auipc	a0,0x7
    8000164a:	b8250513          	addi	a0,a0,-1150 # 800081c8 <digits+0x188>
    8000164e:	fffff097          	auipc	ra,0xfffff
    80001652:	eea080e7          	jalr	-278(ra) # 80000538 <panic>

0000000080001656 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001656:	c6bd                	beqz	a3,800016c4 <copyout+0x6e>
{
    80001658:	715d                	addi	sp,sp,-80
    8000165a:	e486                	sd	ra,72(sp)
    8000165c:	e0a2                	sd	s0,64(sp)
    8000165e:	fc26                	sd	s1,56(sp)
    80001660:	f84a                	sd	s2,48(sp)
    80001662:	f44e                	sd	s3,40(sp)
    80001664:	f052                	sd	s4,32(sp)
    80001666:	ec56                	sd	s5,24(sp)
    80001668:	e85a                	sd	s6,16(sp)
    8000166a:	e45e                	sd	s7,8(sp)
    8000166c:	e062                	sd	s8,0(sp)
    8000166e:	0880                	addi	s0,sp,80
    80001670:	8b2a                	mv	s6,a0
    80001672:	8c2e                	mv	s8,a1
    80001674:	8a32                	mv	s4,a2
    80001676:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001678:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000167a:	6a85                	lui	s5,0x1
    8000167c:	a015                	j	800016a0 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000167e:	9562                	add	a0,a0,s8
    80001680:	0004861b          	sext.w	a2,s1
    80001684:	85d2                	mv	a1,s4
    80001686:	41250533          	sub	a0,a0,s2
    8000168a:	fffff097          	auipc	ra,0xfffff
    8000168e:	69e080e7          	jalr	1694(ra) # 80000d28 <memmove>

    len -= n;
    80001692:	409989b3          	sub	s3,s3,s1
    src += n;
    80001696:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001698:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000169c:	02098263          	beqz	s3,800016c0 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016a0:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016a4:	85ca                	mv	a1,s2
    800016a6:	855a                	mv	a0,s6
    800016a8:	00000097          	auipc	ra,0x0
    800016ac:	9aa080e7          	jalr	-1622(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    800016b0:	cd01                	beqz	a0,800016c8 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016b2:	418904b3          	sub	s1,s2,s8
    800016b6:	94d6                	add	s1,s1,s5
    if(n > len)
    800016b8:	fc99f3e3          	bgeu	s3,s1,8000167e <copyout+0x28>
    800016bc:	84ce                	mv	s1,s3
    800016be:	b7c1                	j	8000167e <copyout+0x28>
  }
  return 0;
    800016c0:	4501                	li	a0,0
    800016c2:	a021                	j	800016ca <copyout+0x74>
    800016c4:	4501                	li	a0,0
}
    800016c6:	8082                	ret
      return -1;
    800016c8:	557d                	li	a0,-1
}
    800016ca:	60a6                	ld	ra,72(sp)
    800016cc:	6406                	ld	s0,64(sp)
    800016ce:	74e2                	ld	s1,56(sp)
    800016d0:	7942                	ld	s2,48(sp)
    800016d2:	79a2                	ld	s3,40(sp)
    800016d4:	7a02                	ld	s4,32(sp)
    800016d6:	6ae2                	ld	s5,24(sp)
    800016d8:	6b42                	ld	s6,16(sp)
    800016da:	6ba2                	ld	s7,8(sp)
    800016dc:	6c02                	ld	s8,0(sp)
    800016de:	6161                	addi	sp,sp,80
    800016e0:	8082                	ret

00000000800016e2 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016e2:	caa5                	beqz	a3,80001752 <copyin+0x70>
{
    800016e4:	715d                	addi	sp,sp,-80
    800016e6:	e486                	sd	ra,72(sp)
    800016e8:	e0a2                	sd	s0,64(sp)
    800016ea:	fc26                	sd	s1,56(sp)
    800016ec:	f84a                	sd	s2,48(sp)
    800016ee:	f44e                	sd	s3,40(sp)
    800016f0:	f052                	sd	s4,32(sp)
    800016f2:	ec56                	sd	s5,24(sp)
    800016f4:	e85a                	sd	s6,16(sp)
    800016f6:	e45e                	sd	s7,8(sp)
    800016f8:	e062                	sd	s8,0(sp)
    800016fa:	0880                	addi	s0,sp,80
    800016fc:	8b2a                	mv	s6,a0
    800016fe:	8a2e                	mv	s4,a1
    80001700:	8c32                	mv	s8,a2
    80001702:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001704:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001706:	6a85                	lui	s5,0x1
    80001708:	a01d                	j	8000172e <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000170a:	018505b3          	add	a1,a0,s8
    8000170e:	0004861b          	sext.w	a2,s1
    80001712:	412585b3          	sub	a1,a1,s2
    80001716:	8552                	mv	a0,s4
    80001718:	fffff097          	auipc	ra,0xfffff
    8000171c:	610080e7          	jalr	1552(ra) # 80000d28 <memmove>

    len -= n;
    80001720:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001724:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001726:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000172a:	02098263          	beqz	s3,8000174e <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000172e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001732:	85ca                	mv	a1,s2
    80001734:	855a                	mv	a0,s6
    80001736:	00000097          	auipc	ra,0x0
    8000173a:	91c080e7          	jalr	-1764(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    8000173e:	cd01                	beqz	a0,80001756 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001740:	418904b3          	sub	s1,s2,s8
    80001744:	94d6                	add	s1,s1,s5
    if(n > len)
    80001746:	fc99f2e3          	bgeu	s3,s1,8000170a <copyin+0x28>
    8000174a:	84ce                	mv	s1,s3
    8000174c:	bf7d                	j	8000170a <copyin+0x28>
  }
  return 0;
    8000174e:	4501                	li	a0,0
    80001750:	a021                	j	80001758 <copyin+0x76>
    80001752:	4501                	li	a0,0
}
    80001754:	8082                	ret
      return -1;
    80001756:	557d                	li	a0,-1
}
    80001758:	60a6                	ld	ra,72(sp)
    8000175a:	6406                	ld	s0,64(sp)
    8000175c:	74e2                	ld	s1,56(sp)
    8000175e:	7942                	ld	s2,48(sp)
    80001760:	79a2                	ld	s3,40(sp)
    80001762:	7a02                	ld	s4,32(sp)
    80001764:	6ae2                	ld	s5,24(sp)
    80001766:	6b42                	ld	s6,16(sp)
    80001768:	6ba2                	ld	s7,8(sp)
    8000176a:	6c02                	ld	s8,0(sp)
    8000176c:	6161                	addi	sp,sp,80
    8000176e:	8082                	ret

0000000080001770 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001770:	c6c5                	beqz	a3,80001818 <copyinstr+0xa8>
{
    80001772:	715d                	addi	sp,sp,-80
    80001774:	e486                	sd	ra,72(sp)
    80001776:	e0a2                	sd	s0,64(sp)
    80001778:	fc26                	sd	s1,56(sp)
    8000177a:	f84a                	sd	s2,48(sp)
    8000177c:	f44e                	sd	s3,40(sp)
    8000177e:	f052                	sd	s4,32(sp)
    80001780:	ec56                	sd	s5,24(sp)
    80001782:	e85a                	sd	s6,16(sp)
    80001784:	e45e                	sd	s7,8(sp)
    80001786:	0880                	addi	s0,sp,80
    80001788:	8a2a                	mv	s4,a0
    8000178a:	8b2e                	mv	s6,a1
    8000178c:	8bb2                	mv	s7,a2
    8000178e:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001790:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001792:	6985                	lui	s3,0x1
    80001794:	a035                	j	800017c0 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001796:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000179a:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000179c:	0017b793          	seqz	a5,a5
    800017a0:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017a4:	60a6                	ld	ra,72(sp)
    800017a6:	6406                	ld	s0,64(sp)
    800017a8:	74e2                	ld	s1,56(sp)
    800017aa:	7942                	ld	s2,48(sp)
    800017ac:	79a2                	ld	s3,40(sp)
    800017ae:	7a02                	ld	s4,32(sp)
    800017b0:	6ae2                	ld	s5,24(sp)
    800017b2:	6b42                	ld	s6,16(sp)
    800017b4:	6ba2                	ld	s7,8(sp)
    800017b6:	6161                	addi	sp,sp,80
    800017b8:	8082                	ret
    srcva = va0 + PGSIZE;
    800017ba:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017be:	c8a9                	beqz	s1,80001810 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017c0:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017c4:	85ca                	mv	a1,s2
    800017c6:	8552                	mv	a0,s4
    800017c8:	00000097          	auipc	ra,0x0
    800017cc:	88a080e7          	jalr	-1910(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    800017d0:	c131                	beqz	a0,80001814 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017d2:	41790833          	sub	a6,s2,s7
    800017d6:	984e                	add	a6,a6,s3
    if(n > max)
    800017d8:	0104f363          	bgeu	s1,a6,800017de <copyinstr+0x6e>
    800017dc:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017de:	955e                	add	a0,a0,s7
    800017e0:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017e4:	fc080be3          	beqz	a6,800017ba <copyinstr+0x4a>
    800017e8:	985a                	add	a6,a6,s6
    800017ea:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017ec:	41650633          	sub	a2,a0,s6
    800017f0:	14fd                	addi	s1,s1,-1
    800017f2:	9b26                	add	s6,s6,s1
    800017f4:	00f60733          	add	a4,a2,a5
    800017f8:	00074703          	lbu	a4,0(a4)
    800017fc:	df49                	beqz	a4,80001796 <copyinstr+0x26>
        *dst = *p;
    800017fe:	00e78023          	sb	a4,0(a5)
      --max;
    80001802:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001806:	0785                	addi	a5,a5,1
    while(n > 0){
    80001808:	ff0796e3          	bne	a5,a6,800017f4 <copyinstr+0x84>
      dst++;
    8000180c:	8b42                	mv	s6,a6
    8000180e:	b775                	j	800017ba <copyinstr+0x4a>
    80001810:	4781                	li	a5,0
    80001812:	b769                	j	8000179c <copyinstr+0x2c>
      return -1;
    80001814:	557d                	li	a0,-1
    80001816:	b779                	j	800017a4 <copyinstr+0x34>
  int got_null = 0;
    80001818:	4781                	li	a5,0
  if(got_null){
    8000181a:	0017b793          	seqz	a5,a5
    8000181e:	40f00533          	neg	a0,a5
}
    80001822:	8082                	ret

0000000080001824 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001824:	7139                	addi	sp,sp,-64
    80001826:	fc06                	sd	ra,56(sp)
    80001828:	f822                	sd	s0,48(sp)
    8000182a:	f426                	sd	s1,40(sp)
    8000182c:	f04a                	sd	s2,32(sp)
    8000182e:	ec4e                	sd	s3,24(sp)
    80001830:	e852                	sd	s4,16(sp)
    80001832:	e456                	sd	s5,8(sp)
    80001834:	e05a                	sd	s6,0(sp)
    80001836:	0080                	addi	s0,sp,64
    80001838:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000183a:	00010497          	auipc	s1,0x10
    8000183e:	e9648493          	addi	s1,s1,-362 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001842:	8b26                	mv	s6,s1
    80001844:	00006a97          	auipc	s5,0x6
    80001848:	7bca8a93          	addi	s5,s5,1980 # 80008000 <etext>
    8000184c:	04000937          	lui	s2,0x4000
    80001850:	197d                	addi	s2,s2,-1
    80001852:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001854:	00016a17          	auipc	s4,0x16
    80001858:	87ca0a13          	addi	s4,s4,-1924 # 800170d0 <tickslock>
    char *pa = kalloc();
    8000185c:	fffff097          	auipc	ra,0xfffff
    80001860:	284080e7          	jalr	644(ra) # 80000ae0 <kalloc>
    80001864:	862a                	mv	a2,a0
    if(pa == 0)
    80001866:	c131                	beqz	a0,800018aa <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001868:	416485b3          	sub	a1,s1,s6
    8000186c:	858d                	srai	a1,a1,0x3
    8000186e:	000ab783          	ld	a5,0(s5)
    80001872:	02f585b3          	mul	a1,a1,a5
    80001876:	2585                	addiw	a1,a1,1
    80001878:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000187c:	4719                	li	a4,6
    8000187e:	6685                	lui	a3,0x1
    80001880:	40b905b3          	sub	a1,s2,a1
    80001884:	854e                	mv	a0,s3
    80001886:	00000097          	auipc	ra,0x0
    8000188a:	8ae080e7          	jalr	-1874(ra) # 80001134 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000188e:	16848493          	addi	s1,s1,360
    80001892:	fd4495e3          	bne	s1,s4,8000185c <proc_mapstacks+0x38>
  }
}
    80001896:	70e2                	ld	ra,56(sp)
    80001898:	7442                	ld	s0,48(sp)
    8000189a:	74a2                	ld	s1,40(sp)
    8000189c:	7902                	ld	s2,32(sp)
    8000189e:	69e2                	ld	s3,24(sp)
    800018a0:	6a42                	ld	s4,16(sp)
    800018a2:	6aa2                	ld	s5,8(sp)
    800018a4:	6b02                	ld	s6,0(sp)
    800018a6:	6121                	addi	sp,sp,64
    800018a8:	8082                	ret
      panic("kalloc");
    800018aa:	00007517          	auipc	a0,0x7
    800018ae:	92e50513          	addi	a0,a0,-1746 # 800081d8 <digits+0x198>
    800018b2:	fffff097          	auipc	ra,0xfffff
    800018b6:	c86080e7          	jalr	-890(ra) # 80000538 <panic>

00000000800018ba <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018ba:	7139                	addi	sp,sp,-64
    800018bc:	fc06                	sd	ra,56(sp)
    800018be:	f822                	sd	s0,48(sp)
    800018c0:	f426                	sd	s1,40(sp)
    800018c2:	f04a                	sd	s2,32(sp)
    800018c4:	ec4e                	sd	s3,24(sp)
    800018c6:	e852                	sd	s4,16(sp)
    800018c8:	e456                	sd	s5,8(sp)
    800018ca:	e05a                	sd	s6,0(sp)
    800018cc:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018ce:	00007597          	auipc	a1,0x7
    800018d2:	91258593          	addi	a1,a1,-1774 # 800081e0 <digits+0x1a0>
    800018d6:	00010517          	auipc	a0,0x10
    800018da:	9ca50513          	addi	a0,a0,-1590 # 800112a0 <pid_lock>
    800018de:	fffff097          	auipc	ra,0xfffff
    800018e2:	262080e7          	jalr	610(ra) # 80000b40 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018e6:	00007597          	auipc	a1,0x7
    800018ea:	90258593          	addi	a1,a1,-1790 # 800081e8 <digits+0x1a8>
    800018ee:	00010517          	auipc	a0,0x10
    800018f2:	9ca50513          	addi	a0,a0,-1590 # 800112b8 <wait_lock>
    800018f6:	fffff097          	auipc	ra,0xfffff
    800018fa:	24a080e7          	jalr	586(ra) # 80000b40 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018fe:	00010497          	auipc	s1,0x10
    80001902:	dd248493          	addi	s1,s1,-558 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001906:	00007b17          	auipc	s6,0x7
    8000190a:	8f2b0b13          	addi	s6,s6,-1806 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    8000190e:	8aa6                	mv	s5,s1
    80001910:	00006a17          	auipc	s4,0x6
    80001914:	6f0a0a13          	addi	s4,s4,1776 # 80008000 <etext>
    80001918:	04000937          	lui	s2,0x4000
    8000191c:	197d                	addi	s2,s2,-1
    8000191e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001920:	00015997          	auipc	s3,0x15
    80001924:	7b098993          	addi	s3,s3,1968 # 800170d0 <tickslock>
      initlock(&p->lock, "proc");
    80001928:	85da                	mv	a1,s6
    8000192a:	8526                	mv	a0,s1
    8000192c:	fffff097          	auipc	ra,0xfffff
    80001930:	214080e7          	jalr	532(ra) # 80000b40 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001934:	415487b3          	sub	a5,s1,s5
    80001938:	878d                	srai	a5,a5,0x3
    8000193a:	000a3703          	ld	a4,0(s4)
    8000193e:	02e787b3          	mul	a5,a5,a4
    80001942:	2785                	addiw	a5,a5,1
    80001944:	00d7979b          	slliw	a5,a5,0xd
    80001948:	40f907b3          	sub	a5,s2,a5
    8000194c:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000194e:	16848493          	addi	s1,s1,360
    80001952:	fd349be3          	bne	s1,s3,80001928 <procinit+0x6e>
  }
}
    80001956:	70e2                	ld	ra,56(sp)
    80001958:	7442                	ld	s0,48(sp)
    8000195a:	74a2                	ld	s1,40(sp)
    8000195c:	7902                	ld	s2,32(sp)
    8000195e:	69e2                	ld	s3,24(sp)
    80001960:	6a42                	ld	s4,16(sp)
    80001962:	6aa2                	ld	s5,8(sp)
    80001964:	6b02                	ld	s6,0(sp)
    80001966:	6121                	addi	sp,sp,64
    80001968:	8082                	ret

000000008000196a <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    8000196a:	1141                	addi	sp,sp,-16
    8000196c:	e422                	sd	s0,8(sp)
    8000196e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001970:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001972:	2501                	sext.w	a0,a0
    80001974:	6422                	ld	s0,8(sp)
    80001976:	0141                	addi	sp,sp,16
    80001978:	8082                	ret

000000008000197a <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    8000197a:	1141                	addi	sp,sp,-16
    8000197c:	e422                	sd	s0,8(sp)
    8000197e:	0800                	addi	s0,sp,16
    80001980:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001982:	2781                	sext.w	a5,a5
    80001984:	079e                	slli	a5,a5,0x7
  return c;
}
    80001986:	00010517          	auipc	a0,0x10
    8000198a:	94a50513          	addi	a0,a0,-1718 # 800112d0 <cpus>
    8000198e:	953e                	add	a0,a0,a5
    80001990:	6422                	ld	s0,8(sp)
    80001992:	0141                	addi	sp,sp,16
    80001994:	8082                	ret

0000000080001996 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001996:	1101                	addi	sp,sp,-32
    80001998:	ec06                	sd	ra,24(sp)
    8000199a:	e822                	sd	s0,16(sp)
    8000199c:	e426                	sd	s1,8(sp)
    8000199e:	1000                	addi	s0,sp,32
  push_off();
    800019a0:	fffff097          	auipc	ra,0xfffff
    800019a4:	1e4080e7          	jalr	484(ra) # 80000b84 <push_off>
    800019a8:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019aa:	2781                	sext.w	a5,a5
    800019ac:	079e                	slli	a5,a5,0x7
    800019ae:	00010717          	auipc	a4,0x10
    800019b2:	8f270713          	addi	a4,a4,-1806 # 800112a0 <pid_lock>
    800019b6:	97ba                	add	a5,a5,a4
    800019b8:	7b84                	ld	s1,48(a5)
  pop_off();
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	26a080e7          	jalr	618(ra) # 80000c24 <pop_off>
  return p;
}
    800019c2:	8526                	mv	a0,s1
    800019c4:	60e2                	ld	ra,24(sp)
    800019c6:	6442                	ld	s0,16(sp)
    800019c8:	64a2                	ld	s1,8(sp)
    800019ca:	6105                	addi	sp,sp,32
    800019cc:	8082                	ret

00000000800019ce <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019ce:	1141                	addi	sp,sp,-16
    800019d0:	e406                	sd	ra,8(sp)
    800019d2:	e022                	sd	s0,0(sp)
    800019d4:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019d6:	00000097          	auipc	ra,0x0
    800019da:	fc0080e7          	jalr	-64(ra) # 80001996 <myproc>
    800019de:	fffff097          	auipc	ra,0xfffff
    800019e2:	2a6080e7          	jalr	678(ra) # 80000c84 <release>

  if (first) {
    800019e6:	00007797          	auipc	a5,0x7
    800019ea:	e6a7a783          	lw	a5,-406(a5) # 80008850 <first.1>
    800019ee:	eb89                	bnez	a5,80001a00 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    800019f0:	00001097          	auipc	ra,0x1
    800019f4:	cd4080e7          	jalr	-812(ra) # 800026c4 <usertrapret>
}
    800019f8:	60a2                	ld	ra,8(sp)
    800019fa:	6402                	ld	s0,0(sp)
    800019fc:	0141                	addi	sp,sp,16
    800019fe:	8082                	ret
    first = 0;
    80001a00:	00007797          	auipc	a5,0x7
    80001a04:	e407a823          	sw	zero,-432(a5) # 80008850 <first.1>
    fsinit(ROOTDEV);
    80001a08:	4505                	li	a0,1
    80001a0a:	00002097          	auipc	ra,0x2
    80001a0e:	aec080e7          	jalr	-1300(ra) # 800034f6 <fsinit>
    80001a12:	bff9                	j	800019f0 <forkret+0x22>

0000000080001a14 <allocpid>:
allocpid() {
    80001a14:	1101                	addi	sp,sp,-32
    80001a16:	ec06                	sd	ra,24(sp)
    80001a18:	e822                	sd	s0,16(sp)
    80001a1a:	e426                	sd	s1,8(sp)
    80001a1c:	e04a                	sd	s2,0(sp)
    80001a1e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a20:	00010917          	auipc	s2,0x10
    80001a24:	88090913          	addi	s2,s2,-1920 # 800112a0 <pid_lock>
    80001a28:	854a                	mv	a0,s2
    80001a2a:	fffff097          	auipc	ra,0xfffff
    80001a2e:	1a6080e7          	jalr	422(ra) # 80000bd0 <acquire>
  pid = nextpid;
    80001a32:	00007797          	auipc	a5,0x7
    80001a36:	e2278793          	addi	a5,a5,-478 # 80008854 <nextpid>
    80001a3a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a3c:	0014871b          	addiw	a4,s1,1
    80001a40:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a42:	854a                	mv	a0,s2
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	240080e7          	jalr	576(ra) # 80000c84 <release>
}
    80001a4c:	8526                	mv	a0,s1
    80001a4e:	60e2                	ld	ra,24(sp)
    80001a50:	6442                	ld	s0,16(sp)
    80001a52:	64a2                	ld	s1,8(sp)
    80001a54:	6902                	ld	s2,0(sp)
    80001a56:	6105                	addi	sp,sp,32
    80001a58:	8082                	ret

0000000080001a5a <proc_pagetable>:
{
    80001a5a:	1101                	addi	sp,sp,-32
    80001a5c:	ec06                	sd	ra,24(sp)
    80001a5e:	e822                	sd	s0,16(sp)
    80001a60:	e426                	sd	s1,8(sp)
    80001a62:	e04a                	sd	s2,0(sp)
    80001a64:	1000                	addi	s0,sp,32
    80001a66:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a68:	00000097          	auipc	ra,0x0
    80001a6c:	8b6080e7          	jalr	-1866(ra) # 8000131e <uvmcreate>
    80001a70:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a72:	c121                	beqz	a0,80001ab2 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a74:	4729                	li	a4,10
    80001a76:	00005697          	auipc	a3,0x5
    80001a7a:	58a68693          	addi	a3,a3,1418 # 80007000 <_trampoline>
    80001a7e:	6605                	lui	a2,0x1
    80001a80:	040005b7          	lui	a1,0x4000
    80001a84:	15fd                	addi	a1,a1,-1
    80001a86:	05b2                	slli	a1,a1,0xc
    80001a88:	fffff097          	auipc	ra,0xfffff
    80001a8c:	60c080e7          	jalr	1548(ra) # 80001094 <mappages>
    80001a90:	02054863          	bltz	a0,80001ac0 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001a94:	4719                	li	a4,6
    80001a96:	05893683          	ld	a3,88(s2)
    80001a9a:	6605                	lui	a2,0x1
    80001a9c:	020005b7          	lui	a1,0x2000
    80001aa0:	15fd                	addi	a1,a1,-1
    80001aa2:	05b6                	slli	a1,a1,0xd
    80001aa4:	8526                	mv	a0,s1
    80001aa6:	fffff097          	auipc	ra,0xfffff
    80001aaa:	5ee080e7          	jalr	1518(ra) # 80001094 <mappages>
    80001aae:	02054163          	bltz	a0,80001ad0 <proc_pagetable+0x76>
}
    80001ab2:	8526                	mv	a0,s1
    80001ab4:	60e2                	ld	ra,24(sp)
    80001ab6:	6442                	ld	s0,16(sp)
    80001ab8:	64a2                	ld	s1,8(sp)
    80001aba:	6902                	ld	s2,0(sp)
    80001abc:	6105                	addi	sp,sp,32
    80001abe:	8082                	ret
    uvmfree(pagetable, 0);
    80001ac0:	4581                	li	a1,0
    80001ac2:	8526                	mv	a0,s1
    80001ac4:	00000097          	auipc	ra,0x0
    80001ac8:	a56080e7          	jalr	-1450(ra) # 8000151a <uvmfree>
    return 0;
    80001acc:	4481                	li	s1,0
    80001ace:	b7d5                	j	80001ab2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ad0:	4681                	li	a3,0
    80001ad2:	4605                	li	a2,1
    80001ad4:	040005b7          	lui	a1,0x4000
    80001ad8:	15fd                	addi	a1,a1,-1
    80001ada:	05b2                	slli	a1,a1,0xc
    80001adc:	8526                	mv	a0,s1
    80001ade:	fffff097          	auipc	ra,0xfffff
    80001ae2:	77c080e7          	jalr	1916(ra) # 8000125a <uvmunmap>
    uvmfree(pagetable, 0);
    80001ae6:	4581                	li	a1,0
    80001ae8:	8526                	mv	a0,s1
    80001aea:	00000097          	auipc	ra,0x0
    80001aee:	a30080e7          	jalr	-1488(ra) # 8000151a <uvmfree>
    return 0;
    80001af2:	4481                	li	s1,0
    80001af4:	bf7d                	j	80001ab2 <proc_pagetable+0x58>

0000000080001af6 <proc_freepagetable>:
{
    80001af6:	1101                	addi	sp,sp,-32
    80001af8:	ec06                	sd	ra,24(sp)
    80001afa:	e822                	sd	s0,16(sp)
    80001afc:	e426                	sd	s1,8(sp)
    80001afe:	e04a                	sd	s2,0(sp)
    80001b00:	1000                	addi	s0,sp,32
    80001b02:	84aa                	mv	s1,a0
    80001b04:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b06:	4681                	li	a3,0
    80001b08:	4605                	li	a2,1
    80001b0a:	040005b7          	lui	a1,0x4000
    80001b0e:	15fd                	addi	a1,a1,-1
    80001b10:	05b2                	slli	a1,a1,0xc
    80001b12:	fffff097          	auipc	ra,0xfffff
    80001b16:	748080e7          	jalr	1864(ra) # 8000125a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b1a:	4681                	li	a3,0
    80001b1c:	4605                	li	a2,1
    80001b1e:	020005b7          	lui	a1,0x2000
    80001b22:	15fd                	addi	a1,a1,-1
    80001b24:	05b6                	slli	a1,a1,0xd
    80001b26:	8526                	mv	a0,s1
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	732080e7          	jalr	1842(ra) # 8000125a <uvmunmap>
  uvmfree(pagetable, sz);
    80001b30:	85ca                	mv	a1,s2
    80001b32:	8526                	mv	a0,s1
    80001b34:	00000097          	auipc	ra,0x0
    80001b38:	9e6080e7          	jalr	-1562(ra) # 8000151a <uvmfree>
}
    80001b3c:	60e2                	ld	ra,24(sp)
    80001b3e:	6442                	ld	s0,16(sp)
    80001b40:	64a2                	ld	s1,8(sp)
    80001b42:	6902                	ld	s2,0(sp)
    80001b44:	6105                	addi	sp,sp,32
    80001b46:	8082                	ret

0000000080001b48 <freeproc>:
{
    80001b48:	1101                	addi	sp,sp,-32
    80001b4a:	ec06                	sd	ra,24(sp)
    80001b4c:	e822                	sd	s0,16(sp)
    80001b4e:	e426                	sd	s1,8(sp)
    80001b50:	1000                	addi	s0,sp,32
    80001b52:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b54:	6d28                	ld	a0,88(a0)
    80001b56:	c509                	beqz	a0,80001b60 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	e8c080e7          	jalr	-372(ra) # 800009e4 <kfree>
  p->trapframe = 0;
    80001b60:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b64:	68a8                	ld	a0,80(s1)
    80001b66:	c511                	beqz	a0,80001b72 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b68:	64ac                	ld	a1,72(s1)
    80001b6a:	00000097          	auipc	ra,0x0
    80001b6e:	f8c080e7          	jalr	-116(ra) # 80001af6 <proc_freepagetable>
  p->pagetable = 0;
    80001b72:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b76:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b7a:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b7e:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b82:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b86:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001b8a:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001b8e:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001b92:	0004ac23          	sw	zero,24(s1)
}
    80001b96:	60e2                	ld	ra,24(sp)
    80001b98:	6442                	ld	s0,16(sp)
    80001b9a:	64a2                	ld	s1,8(sp)
    80001b9c:	6105                	addi	sp,sp,32
    80001b9e:	8082                	ret

0000000080001ba0 <allocproc>:
{
    80001ba0:	1101                	addi	sp,sp,-32
    80001ba2:	ec06                	sd	ra,24(sp)
    80001ba4:	e822                	sd	s0,16(sp)
    80001ba6:	e426                	sd	s1,8(sp)
    80001ba8:	e04a                	sd	s2,0(sp)
    80001baa:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bac:	00010497          	auipc	s1,0x10
    80001bb0:	b2448493          	addi	s1,s1,-1244 # 800116d0 <proc>
    80001bb4:	00015917          	auipc	s2,0x15
    80001bb8:	51c90913          	addi	s2,s2,1308 # 800170d0 <tickslock>
    acquire(&p->lock);
    80001bbc:	8526                	mv	a0,s1
    80001bbe:	fffff097          	auipc	ra,0xfffff
    80001bc2:	012080e7          	jalr	18(ra) # 80000bd0 <acquire>
    if(p->state == UNUSED) {
    80001bc6:	4c9c                	lw	a5,24(s1)
    80001bc8:	cf81                	beqz	a5,80001be0 <allocproc+0x40>
      release(&p->lock);
    80001bca:	8526                	mv	a0,s1
    80001bcc:	fffff097          	auipc	ra,0xfffff
    80001bd0:	0b8080e7          	jalr	184(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bd4:	16848493          	addi	s1,s1,360
    80001bd8:	ff2492e3          	bne	s1,s2,80001bbc <allocproc+0x1c>
  return 0;
    80001bdc:	4481                	li	s1,0
    80001bde:	a889                	j	80001c30 <allocproc+0x90>
  p->pid = allocpid();
    80001be0:	00000097          	auipc	ra,0x0
    80001be4:	e34080e7          	jalr	-460(ra) # 80001a14 <allocpid>
    80001be8:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001bea:	4785                	li	a5,1
    80001bec:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	ef2080e7          	jalr	-270(ra) # 80000ae0 <kalloc>
    80001bf6:	892a                	mv	s2,a0
    80001bf8:	eca8                	sd	a0,88(s1)
    80001bfa:	c131                	beqz	a0,80001c3e <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001bfc:	8526                	mv	a0,s1
    80001bfe:	00000097          	auipc	ra,0x0
    80001c02:	e5c080e7          	jalr	-420(ra) # 80001a5a <proc_pagetable>
    80001c06:	892a                	mv	s2,a0
    80001c08:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c0a:	c531                	beqz	a0,80001c56 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c0c:	07000613          	li	a2,112
    80001c10:	4581                	li	a1,0
    80001c12:	06048513          	addi	a0,s1,96
    80001c16:	fffff097          	auipc	ra,0xfffff
    80001c1a:	0b6080e7          	jalr	182(ra) # 80000ccc <memset>
  p->context.ra = (uint64)forkret;
    80001c1e:	00000797          	auipc	a5,0x0
    80001c22:	db078793          	addi	a5,a5,-592 # 800019ce <forkret>
    80001c26:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c28:	60bc                	ld	a5,64(s1)
    80001c2a:	6705                	lui	a4,0x1
    80001c2c:	97ba                	add	a5,a5,a4
    80001c2e:	f4bc                	sd	a5,104(s1)
}
    80001c30:	8526                	mv	a0,s1
    80001c32:	60e2                	ld	ra,24(sp)
    80001c34:	6442                	ld	s0,16(sp)
    80001c36:	64a2                	ld	s1,8(sp)
    80001c38:	6902                	ld	s2,0(sp)
    80001c3a:	6105                	addi	sp,sp,32
    80001c3c:	8082                	ret
    freeproc(p);
    80001c3e:	8526                	mv	a0,s1
    80001c40:	00000097          	auipc	ra,0x0
    80001c44:	f08080e7          	jalr	-248(ra) # 80001b48 <freeproc>
    release(&p->lock);
    80001c48:	8526                	mv	a0,s1
    80001c4a:	fffff097          	auipc	ra,0xfffff
    80001c4e:	03a080e7          	jalr	58(ra) # 80000c84 <release>
    return 0;
    80001c52:	84ca                	mv	s1,s2
    80001c54:	bff1                	j	80001c30 <allocproc+0x90>
    freeproc(p);
    80001c56:	8526                	mv	a0,s1
    80001c58:	00000097          	auipc	ra,0x0
    80001c5c:	ef0080e7          	jalr	-272(ra) # 80001b48 <freeproc>
    release(&p->lock);
    80001c60:	8526                	mv	a0,s1
    80001c62:	fffff097          	auipc	ra,0xfffff
    80001c66:	022080e7          	jalr	34(ra) # 80000c84 <release>
    return 0;
    80001c6a:	84ca                	mv	s1,s2
    80001c6c:	b7d1                	j	80001c30 <allocproc+0x90>

0000000080001c6e <userinit>:
{
    80001c6e:	1101                	addi	sp,sp,-32
    80001c70:	ec06                	sd	ra,24(sp)
    80001c72:	e822                	sd	s0,16(sp)
    80001c74:	e426                	sd	s1,8(sp)
    80001c76:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c78:	00000097          	auipc	ra,0x0
    80001c7c:	f28080e7          	jalr	-216(ra) # 80001ba0 <allocproc>
    80001c80:	84aa                	mv	s1,a0
  initproc = p;
    80001c82:	00007797          	auipc	a5,0x7
    80001c86:	3aa7b323          	sd	a0,934(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001c8a:	03400613          	li	a2,52
    80001c8e:	00007597          	auipc	a1,0x7
    80001c92:	bd258593          	addi	a1,a1,-1070 # 80008860 <initcode>
    80001c96:	6928                	ld	a0,80(a0)
    80001c98:	fffff097          	auipc	ra,0xfffff
    80001c9c:	6b4080e7          	jalr	1716(ra) # 8000134c <uvminit>
  p->sz = PGSIZE;
    80001ca0:	6785                	lui	a5,0x1
    80001ca2:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001ca4:	6cb8                	ld	a4,88(s1)
    80001ca6:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001caa:	6cb8                	ld	a4,88(s1)
    80001cac:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cae:	4641                	li	a2,16
    80001cb0:	00006597          	auipc	a1,0x6
    80001cb4:	55058593          	addi	a1,a1,1360 # 80008200 <digits+0x1c0>
    80001cb8:	15848513          	addi	a0,s1,344
    80001cbc:	fffff097          	auipc	ra,0xfffff
    80001cc0:	15a080e7          	jalr	346(ra) # 80000e16 <safestrcpy>
  p->cwd = namei("/");
    80001cc4:	00006517          	auipc	a0,0x6
    80001cc8:	54c50513          	addi	a0,a0,1356 # 80008210 <digits+0x1d0>
    80001ccc:	00002097          	auipc	ra,0x2
    80001cd0:	258080e7          	jalr	600(ra) # 80003f24 <namei>
    80001cd4:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cd8:	478d                	li	a5,3
    80001cda:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cdc:	8526                	mv	a0,s1
    80001cde:	fffff097          	auipc	ra,0xfffff
    80001ce2:	fa6080e7          	jalr	-90(ra) # 80000c84 <release>
}
    80001ce6:	60e2                	ld	ra,24(sp)
    80001ce8:	6442                	ld	s0,16(sp)
    80001cea:	64a2                	ld	s1,8(sp)
    80001cec:	6105                	addi	sp,sp,32
    80001cee:	8082                	ret

0000000080001cf0 <growproc>:
{
    80001cf0:	1101                	addi	sp,sp,-32
    80001cf2:	ec06                	sd	ra,24(sp)
    80001cf4:	e822                	sd	s0,16(sp)
    80001cf6:	e426                	sd	s1,8(sp)
    80001cf8:	e04a                	sd	s2,0(sp)
    80001cfa:	1000                	addi	s0,sp,32
    80001cfc:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001cfe:	00000097          	auipc	ra,0x0
    80001d02:	c98080e7          	jalr	-872(ra) # 80001996 <myproc>
    80001d06:	892a                	mv	s2,a0
  sz = p->sz;
    80001d08:	652c                	ld	a1,72(a0)
    80001d0a:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d0e:	00904f63          	bgtz	s1,80001d2c <growproc+0x3c>
  } else if(n < 0){
    80001d12:	0204cc63          	bltz	s1,80001d4a <growproc+0x5a>
  p->sz = sz;
    80001d16:	1602                	slli	a2,a2,0x20
    80001d18:	9201                	srli	a2,a2,0x20
    80001d1a:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d1e:	4501                	li	a0,0
}
    80001d20:	60e2                	ld	ra,24(sp)
    80001d22:	6442                	ld	s0,16(sp)
    80001d24:	64a2                	ld	s1,8(sp)
    80001d26:	6902                	ld	s2,0(sp)
    80001d28:	6105                	addi	sp,sp,32
    80001d2a:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d2c:	9e25                	addw	a2,a2,s1
    80001d2e:	1602                	slli	a2,a2,0x20
    80001d30:	9201                	srli	a2,a2,0x20
    80001d32:	1582                	slli	a1,a1,0x20
    80001d34:	9181                	srli	a1,a1,0x20
    80001d36:	6928                	ld	a0,80(a0)
    80001d38:	fffff097          	auipc	ra,0xfffff
    80001d3c:	6ce080e7          	jalr	1742(ra) # 80001406 <uvmalloc>
    80001d40:	0005061b          	sext.w	a2,a0
    80001d44:	fa69                	bnez	a2,80001d16 <growproc+0x26>
      return -1;
    80001d46:	557d                	li	a0,-1
    80001d48:	bfe1                	j	80001d20 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d4a:	9e25                	addw	a2,a2,s1
    80001d4c:	1602                	slli	a2,a2,0x20
    80001d4e:	9201                	srli	a2,a2,0x20
    80001d50:	1582                	slli	a1,a1,0x20
    80001d52:	9181                	srli	a1,a1,0x20
    80001d54:	6928                	ld	a0,80(a0)
    80001d56:	fffff097          	auipc	ra,0xfffff
    80001d5a:	668080e7          	jalr	1640(ra) # 800013be <uvmdealloc>
    80001d5e:	0005061b          	sext.w	a2,a0
    80001d62:	bf55                	j	80001d16 <growproc+0x26>

0000000080001d64 <fork>:
{
    80001d64:	7139                	addi	sp,sp,-64
    80001d66:	fc06                	sd	ra,56(sp)
    80001d68:	f822                	sd	s0,48(sp)
    80001d6a:	f426                	sd	s1,40(sp)
    80001d6c:	f04a                	sd	s2,32(sp)
    80001d6e:	ec4e                	sd	s3,24(sp)
    80001d70:	e852                	sd	s4,16(sp)
    80001d72:	e456                	sd	s5,8(sp)
    80001d74:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d76:	00000097          	auipc	ra,0x0
    80001d7a:	c20080e7          	jalr	-992(ra) # 80001996 <myproc>
    80001d7e:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d80:	00000097          	auipc	ra,0x0
    80001d84:	e20080e7          	jalr	-480(ra) # 80001ba0 <allocproc>
    80001d88:	10050c63          	beqz	a0,80001ea0 <fork+0x13c>
    80001d8c:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d8e:	048ab603          	ld	a2,72(s5)
    80001d92:	692c                	ld	a1,80(a0)
    80001d94:	050ab503          	ld	a0,80(s5)
    80001d98:	fffff097          	auipc	ra,0xfffff
    80001d9c:	7ba080e7          	jalr	1978(ra) # 80001552 <uvmcopy>
    80001da0:	04054863          	bltz	a0,80001df0 <fork+0x8c>
  np->sz = p->sz;
    80001da4:	048ab783          	ld	a5,72(s5)
    80001da8:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001dac:	058ab683          	ld	a3,88(s5)
    80001db0:	87b6                	mv	a5,a3
    80001db2:	058a3703          	ld	a4,88(s4)
    80001db6:	12068693          	addi	a3,a3,288
    80001dba:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dbe:	6788                	ld	a0,8(a5)
    80001dc0:	6b8c                	ld	a1,16(a5)
    80001dc2:	6f90                	ld	a2,24(a5)
    80001dc4:	01073023          	sd	a6,0(a4)
    80001dc8:	e708                	sd	a0,8(a4)
    80001dca:	eb0c                	sd	a1,16(a4)
    80001dcc:	ef10                	sd	a2,24(a4)
    80001dce:	02078793          	addi	a5,a5,32
    80001dd2:	02070713          	addi	a4,a4,32
    80001dd6:	fed792e3          	bne	a5,a3,80001dba <fork+0x56>
  np->trapframe->a0 = 0;
    80001dda:	058a3783          	ld	a5,88(s4)
    80001dde:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001de2:	0d0a8493          	addi	s1,s5,208
    80001de6:	0d0a0913          	addi	s2,s4,208
    80001dea:	150a8993          	addi	s3,s5,336
    80001dee:	a00d                	j	80001e10 <fork+0xac>
    freeproc(np);
    80001df0:	8552                	mv	a0,s4
    80001df2:	00000097          	auipc	ra,0x0
    80001df6:	d56080e7          	jalr	-682(ra) # 80001b48 <freeproc>
    release(&np->lock);
    80001dfa:	8552                	mv	a0,s4
    80001dfc:	fffff097          	auipc	ra,0xfffff
    80001e00:	e88080e7          	jalr	-376(ra) # 80000c84 <release>
    return -1;
    80001e04:	597d                	li	s2,-1
    80001e06:	a059                	j	80001e8c <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001e08:	04a1                	addi	s1,s1,8
    80001e0a:	0921                	addi	s2,s2,8
    80001e0c:	01348b63          	beq	s1,s3,80001e22 <fork+0xbe>
    if(p->ofile[i])
    80001e10:	6088                	ld	a0,0(s1)
    80001e12:	d97d                	beqz	a0,80001e08 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e14:	00002097          	auipc	ra,0x2
    80001e18:	7a6080e7          	jalr	1958(ra) # 800045ba <filedup>
    80001e1c:	00a93023          	sd	a0,0(s2)
    80001e20:	b7e5                	j	80001e08 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e22:	150ab503          	ld	a0,336(s5)
    80001e26:	00002097          	auipc	ra,0x2
    80001e2a:	90a080e7          	jalr	-1782(ra) # 80003730 <idup>
    80001e2e:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e32:	4641                	li	a2,16
    80001e34:	158a8593          	addi	a1,s5,344
    80001e38:	158a0513          	addi	a0,s4,344
    80001e3c:	fffff097          	auipc	ra,0xfffff
    80001e40:	fda080e7          	jalr	-38(ra) # 80000e16 <safestrcpy>
  pid = np->pid;
    80001e44:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e48:	8552                	mv	a0,s4
    80001e4a:	fffff097          	auipc	ra,0xfffff
    80001e4e:	e3a080e7          	jalr	-454(ra) # 80000c84 <release>
  acquire(&wait_lock);
    80001e52:	0000f497          	auipc	s1,0xf
    80001e56:	46648493          	addi	s1,s1,1126 # 800112b8 <wait_lock>
    80001e5a:	8526                	mv	a0,s1
    80001e5c:	fffff097          	auipc	ra,0xfffff
    80001e60:	d74080e7          	jalr	-652(ra) # 80000bd0 <acquire>
  np->parent = p;
    80001e64:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e68:	8526                	mv	a0,s1
    80001e6a:	fffff097          	auipc	ra,0xfffff
    80001e6e:	e1a080e7          	jalr	-486(ra) # 80000c84 <release>
  acquire(&np->lock);
    80001e72:	8552                	mv	a0,s4
    80001e74:	fffff097          	auipc	ra,0xfffff
    80001e78:	d5c080e7          	jalr	-676(ra) # 80000bd0 <acquire>
  np->state = RUNNABLE;
    80001e7c:	478d                	li	a5,3
    80001e7e:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e82:	8552                	mv	a0,s4
    80001e84:	fffff097          	auipc	ra,0xfffff
    80001e88:	e00080e7          	jalr	-512(ra) # 80000c84 <release>
}
    80001e8c:	854a                	mv	a0,s2
    80001e8e:	70e2                	ld	ra,56(sp)
    80001e90:	7442                	ld	s0,48(sp)
    80001e92:	74a2                	ld	s1,40(sp)
    80001e94:	7902                	ld	s2,32(sp)
    80001e96:	69e2                	ld	s3,24(sp)
    80001e98:	6a42                	ld	s4,16(sp)
    80001e9a:	6aa2                	ld	s5,8(sp)
    80001e9c:	6121                	addi	sp,sp,64
    80001e9e:	8082                	ret
    return -1;
    80001ea0:	597d                	li	s2,-1
    80001ea2:	b7ed                	j	80001e8c <fork+0x128>

0000000080001ea4 <scheduler>:
{
    80001ea4:	7139                	addi	sp,sp,-64
    80001ea6:	fc06                	sd	ra,56(sp)
    80001ea8:	f822                	sd	s0,48(sp)
    80001eaa:	f426                	sd	s1,40(sp)
    80001eac:	f04a                	sd	s2,32(sp)
    80001eae:	ec4e                	sd	s3,24(sp)
    80001eb0:	e852                	sd	s4,16(sp)
    80001eb2:	e456                	sd	s5,8(sp)
    80001eb4:	e05a                	sd	s6,0(sp)
    80001eb6:	0080                	addi	s0,sp,64
    80001eb8:	8792                	mv	a5,tp
  int id = r_tp();
    80001eba:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ebc:	00779a93          	slli	s5,a5,0x7
    80001ec0:	0000f717          	auipc	a4,0xf
    80001ec4:	3e070713          	addi	a4,a4,992 # 800112a0 <pid_lock>
    80001ec8:	9756                	add	a4,a4,s5
    80001eca:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ece:	0000f717          	auipc	a4,0xf
    80001ed2:	40a70713          	addi	a4,a4,1034 # 800112d8 <cpus+0x8>
    80001ed6:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001ed8:	498d                	li	s3,3
        p->state = RUNNING;
    80001eda:	4b11                	li	s6,4
        c->proc = p;
    80001edc:	079e                	slli	a5,a5,0x7
    80001ede:	0000fa17          	auipc	s4,0xf
    80001ee2:	3c2a0a13          	addi	s4,s4,962 # 800112a0 <pid_lock>
    80001ee6:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ee8:	00015917          	auipc	s2,0x15
    80001eec:	1e890913          	addi	s2,s2,488 # 800170d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ef0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ef4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ef8:	10079073          	csrw	sstatus,a5
    80001efc:	0000f497          	auipc	s1,0xf
    80001f00:	7d448493          	addi	s1,s1,2004 # 800116d0 <proc>
    80001f04:	a811                	j	80001f18 <scheduler+0x74>
      release(&p->lock);
    80001f06:	8526                	mv	a0,s1
    80001f08:	fffff097          	auipc	ra,0xfffff
    80001f0c:	d7c080e7          	jalr	-644(ra) # 80000c84 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f10:	16848493          	addi	s1,s1,360
    80001f14:	fd248ee3          	beq	s1,s2,80001ef0 <scheduler+0x4c>
      acquire(&p->lock);
    80001f18:	8526                	mv	a0,s1
    80001f1a:	fffff097          	auipc	ra,0xfffff
    80001f1e:	cb6080e7          	jalr	-842(ra) # 80000bd0 <acquire>
      if(p->state == RUNNABLE) {
    80001f22:	4c9c                	lw	a5,24(s1)
    80001f24:	ff3791e3          	bne	a5,s3,80001f06 <scheduler+0x62>
        p->state = RUNNING;
    80001f28:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f2c:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f30:	06048593          	addi	a1,s1,96
    80001f34:	8556                	mv	a0,s5
    80001f36:	00000097          	auipc	ra,0x0
    80001f3a:	6e4080e7          	jalr	1764(ra) # 8000261a <swtch>
        c->proc = 0;
    80001f3e:	020a3823          	sd	zero,48(s4)
    80001f42:	b7d1                	j	80001f06 <scheduler+0x62>

0000000080001f44 <sched>:
{
    80001f44:	7179                	addi	sp,sp,-48
    80001f46:	f406                	sd	ra,40(sp)
    80001f48:	f022                	sd	s0,32(sp)
    80001f4a:	ec26                	sd	s1,24(sp)
    80001f4c:	e84a                	sd	s2,16(sp)
    80001f4e:	e44e                	sd	s3,8(sp)
    80001f50:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f52:	00000097          	auipc	ra,0x0
    80001f56:	a44080e7          	jalr	-1468(ra) # 80001996 <myproc>
    80001f5a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f5c:	fffff097          	auipc	ra,0xfffff
    80001f60:	bfa080e7          	jalr	-1030(ra) # 80000b56 <holding>
    80001f64:	c93d                	beqz	a0,80001fda <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f66:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f68:	2781                	sext.w	a5,a5
    80001f6a:	079e                	slli	a5,a5,0x7
    80001f6c:	0000f717          	auipc	a4,0xf
    80001f70:	33470713          	addi	a4,a4,820 # 800112a0 <pid_lock>
    80001f74:	97ba                	add	a5,a5,a4
    80001f76:	0a87a703          	lw	a4,168(a5)
    80001f7a:	4785                	li	a5,1
    80001f7c:	06f71763          	bne	a4,a5,80001fea <sched+0xa6>
  if(p->state == RUNNING)
    80001f80:	4c98                	lw	a4,24(s1)
    80001f82:	4791                	li	a5,4
    80001f84:	06f70b63          	beq	a4,a5,80001ffa <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f88:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f8c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f8e:	efb5                	bnez	a5,8000200a <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f90:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f92:	0000f917          	auipc	s2,0xf
    80001f96:	30e90913          	addi	s2,s2,782 # 800112a0 <pid_lock>
    80001f9a:	2781                	sext.w	a5,a5
    80001f9c:	079e                	slli	a5,a5,0x7
    80001f9e:	97ca                	add	a5,a5,s2
    80001fa0:	0ac7a983          	lw	s3,172(a5)
    80001fa4:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fa6:	2781                	sext.w	a5,a5
    80001fa8:	079e                	slli	a5,a5,0x7
    80001faa:	0000f597          	auipc	a1,0xf
    80001fae:	32e58593          	addi	a1,a1,814 # 800112d8 <cpus+0x8>
    80001fb2:	95be                	add	a1,a1,a5
    80001fb4:	06048513          	addi	a0,s1,96
    80001fb8:	00000097          	auipc	ra,0x0
    80001fbc:	662080e7          	jalr	1634(ra) # 8000261a <swtch>
    80001fc0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fc2:	2781                	sext.w	a5,a5
    80001fc4:	079e                	slli	a5,a5,0x7
    80001fc6:	97ca                	add	a5,a5,s2
    80001fc8:	0b37a623          	sw	s3,172(a5)
}
    80001fcc:	70a2                	ld	ra,40(sp)
    80001fce:	7402                	ld	s0,32(sp)
    80001fd0:	64e2                	ld	s1,24(sp)
    80001fd2:	6942                	ld	s2,16(sp)
    80001fd4:	69a2                	ld	s3,8(sp)
    80001fd6:	6145                	addi	sp,sp,48
    80001fd8:	8082                	ret
    panic("sched p->lock");
    80001fda:	00006517          	auipc	a0,0x6
    80001fde:	23e50513          	addi	a0,a0,574 # 80008218 <digits+0x1d8>
    80001fe2:	ffffe097          	auipc	ra,0xffffe
    80001fe6:	556080e7          	jalr	1366(ra) # 80000538 <panic>
    panic("sched locks");
    80001fea:	00006517          	auipc	a0,0x6
    80001fee:	23e50513          	addi	a0,a0,574 # 80008228 <digits+0x1e8>
    80001ff2:	ffffe097          	auipc	ra,0xffffe
    80001ff6:	546080e7          	jalr	1350(ra) # 80000538 <panic>
    panic("sched running");
    80001ffa:	00006517          	auipc	a0,0x6
    80001ffe:	23e50513          	addi	a0,a0,574 # 80008238 <digits+0x1f8>
    80002002:	ffffe097          	auipc	ra,0xffffe
    80002006:	536080e7          	jalr	1334(ra) # 80000538 <panic>
    panic("sched interruptible");
    8000200a:	00006517          	auipc	a0,0x6
    8000200e:	23e50513          	addi	a0,a0,574 # 80008248 <digits+0x208>
    80002012:	ffffe097          	auipc	ra,0xffffe
    80002016:	526080e7          	jalr	1318(ra) # 80000538 <panic>

000000008000201a <yield>:
{
    8000201a:	1101                	addi	sp,sp,-32
    8000201c:	ec06                	sd	ra,24(sp)
    8000201e:	e822                	sd	s0,16(sp)
    80002020:	e426                	sd	s1,8(sp)
    80002022:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002024:	00000097          	auipc	ra,0x0
    80002028:	972080e7          	jalr	-1678(ra) # 80001996 <myproc>
    8000202c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000202e:	fffff097          	auipc	ra,0xfffff
    80002032:	ba2080e7          	jalr	-1118(ra) # 80000bd0 <acquire>
  p->state = RUNNABLE;
    80002036:	478d                	li	a5,3
    80002038:	cc9c                	sw	a5,24(s1)
  sched();
    8000203a:	00000097          	auipc	ra,0x0
    8000203e:	f0a080e7          	jalr	-246(ra) # 80001f44 <sched>
  release(&p->lock);
    80002042:	8526                	mv	a0,s1
    80002044:	fffff097          	auipc	ra,0xfffff
    80002048:	c40080e7          	jalr	-960(ra) # 80000c84 <release>
}
    8000204c:	60e2                	ld	ra,24(sp)
    8000204e:	6442                	ld	s0,16(sp)
    80002050:	64a2                	ld	s1,8(sp)
    80002052:	6105                	addi	sp,sp,32
    80002054:	8082                	ret

0000000080002056 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002056:	7179                	addi	sp,sp,-48
    80002058:	f406                	sd	ra,40(sp)
    8000205a:	f022                	sd	s0,32(sp)
    8000205c:	ec26                	sd	s1,24(sp)
    8000205e:	e84a                	sd	s2,16(sp)
    80002060:	e44e                	sd	s3,8(sp)
    80002062:	1800                	addi	s0,sp,48
    80002064:	89aa                	mv	s3,a0
    80002066:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002068:	00000097          	auipc	ra,0x0
    8000206c:	92e080e7          	jalr	-1746(ra) # 80001996 <myproc>
    80002070:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002072:	fffff097          	auipc	ra,0xfffff
    80002076:	b5e080e7          	jalr	-1186(ra) # 80000bd0 <acquire>
  release(lk);
    8000207a:	854a                	mv	a0,s2
    8000207c:	fffff097          	auipc	ra,0xfffff
    80002080:	c08080e7          	jalr	-1016(ra) # 80000c84 <release>

  // Go to sleep.
  p->chan = chan;
    80002084:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002088:	4789                	li	a5,2
    8000208a:	cc9c                	sw	a5,24(s1)

  sched();
    8000208c:	00000097          	auipc	ra,0x0
    80002090:	eb8080e7          	jalr	-328(ra) # 80001f44 <sched>

  // Tidy up.
  p->chan = 0;
    80002094:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002098:	8526                	mv	a0,s1
    8000209a:	fffff097          	auipc	ra,0xfffff
    8000209e:	bea080e7          	jalr	-1046(ra) # 80000c84 <release>
  acquire(lk);
    800020a2:	854a                	mv	a0,s2
    800020a4:	fffff097          	auipc	ra,0xfffff
    800020a8:	b2c080e7          	jalr	-1236(ra) # 80000bd0 <acquire>
}
    800020ac:	70a2                	ld	ra,40(sp)
    800020ae:	7402                	ld	s0,32(sp)
    800020b0:	64e2                	ld	s1,24(sp)
    800020b2:	6942                	ld	s2,16(sp)
    800020b4:	69a2                	ld	s3,8(sp)
    800020b6:	6145                	addi	sp,sp,48
    800020b8:	8082                	ret

00000000800020ba <wait>:
{
    800020ba:	715d                	addi	sp,sp,-80
    800020bc:	e486                	sd	ra,72(sp)
    800020be:	e0a2                	sd	s0,64(sp)
    800020c0:	fc26                	sd	s1,56(sp)
    800020c2:	f84a                	sd	s2,48(sp)
    800020c4:	f44e                	sd	s3,40(sp)
    800020c6:	f052                	sd	s4,32(sp)
    800020c8:	ec56                	sd	s5,24(sp)
    800020ca:	e85a                	sd	s6,16(sp)
    800020cc:	e45e                	sd	s7,8(sp)
    800020ce:	e062                	sd	s8,0(sp)
    800020d0:	0880                	addi	s0,sp,80
    800020d2:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800020d4:	00000097          	auipc	ra,0x0
    800020d8:	8c2080e7          	jalr	-1854(ra) # 80001996 <myproc>
    800020dc:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800020de:	0000f517          	auipc	a0,0xf
    800020e2:	1da50513          	addi	a0,a0,474 # 800112b8 <wait_lock>
    800020e6:	fffff097          	auipc	ra,0xfffff
    800020ea:	aea080e7          	jalr	-1302(ra) # 80000bd0 <acquire>
    havekids = 0;
    800020ee:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800020f0:	4a15                	li	s4,5
        havekids = 1;
    800020f2:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    800020f4:	00015997          	auipc	s3,0x15
    800020f8:	fdc98993          	addi	s3,s3,-36 # 800170d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800020fc:	0000fc17          	auipc	s8,0xf
    80002100:	1bcc0c13          	addi	s8,s8,444 # 800112b8 <wait_lock>
    havekids = 0;
    80002104:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002106:	0000f497          	auipc	s1,0xf
    8000210a:	5ca48493          	addi	s1,s1,1482 # 800116d0 <proc>
    8000210e:	a0bd                	j	8000217c <wait+0xc2>
          pid = np->pid;
    80002110:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002114:	000b0e63          	beqz	s6,80002130 <wait+0x76>
    80002118:	4691                	li	a3,4
    8000211a:	02c48613          	addi	a2,s1,44
    8000211e:	85da                	mv	a1,s6
    80002120:	05093503          	ld	a0,80(s2)
    80002124:	fffff097          	auipc	ra,0xfffff
    80002128:	532080e7          	jalr	1330(ra) # 80001656 <copyout>
    8000212c:	02054563          	bltz	a0,80002156 <wait+0x9c>
          freeproc(np);
    80002130:	8526                	mv	a0,s1
    80002132:	00000097          	auipc	ra,0x0
    80002136:	a16080e7          	jalr	-1514(ra) # 80001b48 <freeproc>
          release(&np->lock);
    8000213a:	8526                	mv	a0,s1
    8000213c:	fffff097          	auipc	ra,0xfffff
    80002140:	b48080e7          	jalr	-1208(ra) # 80000c84 <release>
          release(&wait_lock);
    80002144:	0000f517          	auipc	a0,0xf
    80002148:	17450513          	addi	a0,a0,372 # 800112b8 <wait_lock>
    8000214c:	fffff097          	auipc	ra,0xfffff
    80002150:	b38080e7          	jalr	-1224(ra) # 80000c84 <release>
          return pid;
    80002154:	a09d                	j	800021ba <wait+0x100>
            release(&np->lock);
    80002156:	8526                	mv	a0,s1
    80002158:	fffff097          	auipc	ra,0xfffff
    8000215c:	b2c080e7          	jalr	-1236(ra) # 80000c84 <release>
            release(&wait_lock);
    80002160:	0000f517          	auipc	a0,0xf
    80002164:	15850513          	addi	a0,a0,344 # 800112b8 <wait_lock>
    80002168:	fffff097          	auipc	ra,0xfffff
    8000216c:	b1c080e7          	jalr	-1252(ra) # 80000c84 <release>
            return -1;
    80002170:	59fd                	li	s3,-1
    80002172:	a0a1                	j	800021ba <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002174:	16848493          	addi	s1,s1,360
    80002178:	03348463          	beq	s1,s3,800021a0 <wait+0xe6>
      if(np->parent == p){
    8000217c:	7c9c                	ld	a5,56(s1)
    8000217e:	ff279be3          	bne	a5,s2,80002174 <wait+0xba>
        acquire(&np->lock);
    80002182:	8526                	mv	a0,s1
    80002184:	fffff097          	auipc	ra,0xfffff
    80002188:	a4c080e7          	jalr	-1460(ra) # 80000bd0 <acquire>
        if(np->state == ZOMBIE){
    8000218c:	4c9c                	lw	a5,24(s1)
    8000218e:	f94781e3          	beq	a5,s4,80002110 <wait+0x56>
        release(&np->lock);
    80002192:	8526                	mv	a0,s1
    80002194:	fffff097          	auipc	ra,0xfffff
    80002198:	af0080e7          	jalr	-1296(ra) # 80000c84 <release>
        havekids = 1;
    8000219c:	8756                	mv	a4,s5
    8000219e:	bfd9                	j	80002174 <wait+0xba>
    if(!havekids || p->killed){
    800021a0:	c701                	beqz	a4,800021a8 <wait+0xee>
    800021a2:	02892783          	lw	a5,40(s2)
    800021a6:	c79d                	beqz	a5,800021d4 <wait+0x11a>
      release(&wait_lock);
    800021a8:	0000f517          	auipc	a0,0xf
    800021ac:	11050513          	addi	a0,a0,272 # 800112b8 <wait_lock>
    800021b0:	fffff097          	auipc	ra,0xfffff
    800021b4:	ad4080e7          	jalr	-1324(ra) # 80000c84 <release>
      return -1;
    800021b8:	59fd                	li	s3,-1
}
    800021ba:	854e                	mv	a0,s3
    800021bc:	60a6                	ld	ra,72(sp)
    800021be:	6406                	ld	s0,64(sp)
    800021c0:	74e2                	ld	s1,56(sp)
    800021c2:	7942                	ld	s2,48(sp)
    800021c4:	79a2                	ld	s3,40(sp)
    800021c6:	7a02                	ld	s4,32(sp)
    800021c8:	6ae2                	ld	s5,24(sp)
    800021ca:	6b42                	ld	s6,16(sp)
    800021cc:	6ba2                	ld	s7,8(sp)
    800021ce:	6c02                	ld	s8,0(sp)
    800021d0:	6161                	addi	sp,sp,80
    800021d2:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800021d4:	85e2                	mv	a1,s8
    800021d6:	854a                	mv	a0,s2
    800021d8:	00000097          	auipc	ra,0x0
    800021dc:	e7e080e7          	jalr	-386(ra) # 80002056 <sleep>
    havekids = 0;
    800021e0:	b715                	j	80002104 <wait+0x4a>

00000000800021e2 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800021e2:	7139                	addi	sp,sp,-64
    800021e4:	fc06                	sd	ra,56(sp)
    800021e6:	f822                	sd	s0,48(sp)
    800021e8:	f426                	sd	s1,40(sp)
    800021ea:	f04a                	sd	s2,32(sp)
    800021ec:	ec4e                	sd	s3,24(sp)
    800021ee:	e852                	sd	s4,16(sp)
    800021f0:	e456                	sd	s5,8(sp)
    800021f2:	0080                	addi	s0,sp,64
    800021f4:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800021f6:	0000f497          	auipc	s1,0xf
    800021fa:	4da48493          	addi	s1,s1,1242 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800021fe:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002200:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002202:	00015917          	auipc	s2,0x15
    80002206:	ece90913          	addi	s2,s2,-306 # 800170d0 <tickslock>
    8000220a:	a811                	j	8000221e <wakeup+0x3c>
      }
      release(&p->lock);
    8000220c:	8526                	mv	a0,s1
    8000220e:	fffff097          	auipc	ra,0xfffff
    80002212:	a76080e7          	jalr	-1418(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002216:	16848493          	addi	s1,s1,360
    8000221a:	03248663          	beq	s1,s2,80002246 <wakeup+0x64>
    if(p != myproc()){
    8000221e:	fffff097          	auipc	ra,0xfffff
    80002222:	778080e7          	jalr	1912(ra) # 80001996 <myproc>
    80002226:	fea488e3          	beq	s1,a0,80002216 <wakeup+0x34>
      acquire(&p->lock);
    8000222a:	8526                	mv	a0,s1
    8000222c:	fffff097          	auipc	ra,0xfffff
    80002230:	9a4080e7          	jalr	-1628(ra) # 80000bd0 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002234:	4c9c                	lw	a5,24(s1)
    80002236:	fd379be3          	bne	a5,s3,8000220c <wakeup+0x2a>
    8000223a:	709c                	ld	a5,32(s1)
    8000223c:	fd4798e3          	bne	a5,s4,8000220c <wakeup+0x2a>
        p->state = RUNNABLE;
    80002240:	0154ac23          	sw	s5,24(s1)
    80002244:	b7e1                	j	8000220c <wakeup+0x2a>
    }
  }
}
    80002246:	70e2                	ld	ra,56(sp)
    80002248:	7442                	ld	s0,48(sp)
    8000224a:	74a2                	ld	s1,40(sp)
    8000224c:	7902                	ld	s2,32(sp)
    8000224e:	69e2                	ld	s3,24(sp)
    80002250:	6a42                	ld	s4,16(sp)
    80002252:	6aa2                	ld	s5,8(sp)
    80002254:	6121                	addi	sp,sp,64
    80002256:	8082                	ret

0000000080002258 <reparent>:
{
    80002258:	7179                	addi	sp,sp,-48
    8000225a:	f406                	sd	ra,40(sp)
    8000225c:	f022                	sd	s0,32(sp)
    8000225e:	ec26                	sd	s1,24(sp)
    80002260:	e84a                	sd	s2,16(sp)
    80002262:	e44e                	sd	s3,8(sp)
    80002264:	e052                	sd	s4,0(sp)
    80002266:	1800                	addi	s0,sp,48
    80002268:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000226a:	0000f497          	auipc	s1,0xf
    8000226e:	46648493          	addi	s1,s1,1126 # 800116d0 <proc>
      pp->parent = initproc;
    80002272:	00007a17          	auipc	s4,0x7
    80002276:	db6a0a13          	addi	s4,s4,-586 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000227a:	00015997          	auipc	s3,0x15
    8000227e:	e5698993          	addi	s3,s3,-426 # 800170d0 <tickslock>
    80002282:	a029                	j	8000228c <reparent+0x34>
    80002284:	16848493          	addi	s1,s1,360
    80002288:	01348d63          	beq	s1,s3,800022a2 <reparent+0x4a>
    if(pp->parent == p){
    8000228c:	7c9c                	ld	a5,56(s1)
    8000228e:	ff279be3          	bne	a5,s2,80002284 <reparent+0x2c>
      pp->parent = initproc;
    80002292:	000a3503          	ld	a0,0(s4)
    80002296:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002298:	00000097          	auipc	ra,0x0
    8000229c:	f4a080e7          	jalr	-182(ra) # 800021e2 <wakeup>
    800022a0:	b7d5                	j	80002284 <reparent+0x2c>
}
    800022a2:	70a2                	ld	ra,40(sp)
    800022a4:	7402                	ld	s0,32(sp)
    800022a6:	64e2                	ld	s1,24(sp)
    800022a8:	6942                	ld	s2,16(sp)
    800022aa:	69a2                	ld	s3,8(sp)
    800022ac:	6a02                	ld	s4,0(sp)
    800022ae:	6145                	addi	sp,sp,48
    800022b0:	8082                	ret

00000000800022b2 <exit>:
{
    800022b2:	7179                	addi	sp,sp,-48
    800022b4:	f406                	sd	ra,40(sp)
    800022b6:	f022                	sd	s0,32(sp)
    800022b8:	ec26                	sd	s1,24(sp)
    800022ba:	e84a                	sd	s2,16(sp)
    800022bc:	e44e                	sd	s3,8(sp)
    800022be:	e052                	sd	s4,0(sp)
    800022c0:	1800                	addi	s0,sp,48
    800022c2:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022c4:	fffff097          	auipc	ra,0xfffff
    800022c8:	6d2080e7          	jalr	1746(ra) # 80001996 <myproc>
    800022cc:	89aa                	mv	s3,a0
  if(p == initproc)
    800022ce:	00007797          	auipc	a5,0x7
    800022d2:	d5a7b783          	ld	a5,-678(a5) # 80009028 <initproc>
    800022d6:	0d050493          	addi	s1,a0,208
    800022da:	15050913          	addi	s2,a0,336
    800022de:	02a79363          	bne	a5,a0,80002304 <exit+0x52>
    panic("init exiting");
    800022e2:	00006517          	auipc	a0,0x6
    800022e6:	f7e50513          	addi	a0,a0,-130 # 80008260 <digits+0x220>
    800022ea:	ffffe097          	auipc	ra,0xffffe
    800022ee:	24e080e7          	jalr	590(ra) # 80000538 <panic>
      fileclose(f);
    800022f2:	00002097          	auipc	ra,0x2
    800022f6:	31a080e7          	jalr	794(ra) # 8000460c <fileclose>
      p->ofile[fd] = 0;
    800022fa:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800022fe:	04a1                	addi	s1,s1,8
    80002300:	01248563          	beq	s1,s2,8000230a <exit+0x58>
    if(p->ofile[fd]){
    80002304:	6088                	ld	a0,0(s1)
    80002306:	f575                	bnez	a0,800022f2 <exit+0x40>
    80002308:	bfdd                	j	800022fe <exit+0x4c>
  begin_op();
    8000230a:	00002097          	auipc	ra,0x2
    8000230e:	e36080e7          	jalr	-458(ra) # 80004140 <begin_op>
  iput(p->cwd);
    80002312:	1509b503          	ld	a0,336(s3)
    80002316:	00001097          	auipc	ra,0x1
    8000231a:	612080e7          	jalr	1554(ra) # 80003928 <iput>
  end_op();
    8000231e:	00002097          	auipc	ra,0x2
    80002322:	ea2080e7          	jalr	-350(ra) # 800041c0 <end_op>
  p->cwd = 0;
    80002326:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000232a:	0000f497          	auipc	s1,0xf
    8000232e:	f8e48493          	addi	s1,s1,-114 # 800112b8 <wait_lock>
    80002332:	8526                	mv	a0,s1
    80002334:	fffff097          	auipc	ra,0xfffff
    80002338:	89c080e7          	jalr	-1892(ra) # 80000bd0 <acquire>
  reparent(p);
    8000233c:	854e                	mv	a0,s3
    8000233e:	00000097          	auipc	ra,0x0
    80002342:	f1a080e7          	jalr	-230(ra) # 80002258 <reparent>
  wakeup(p->parent);
    80002346:	0389b503          	ld	a0,56(s3)
    8000234a:	00000097          	auipc	ra,0x0
    8000234e:	e98080e7          	jalr	-360(ra) # 800021e2 <wakeup>
  acquire(&p->lock);
    80002352:	854e                	mv	a0,s3
    80002354:	fffff097          	auipc	ra,0xfffff
    80002358:	87c080e7          	jalr	-1924(ra) # 80000bd0 <acquire>
  p->xstate = status;
    8000235c:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002360:	4795                	li	a5,5
    80002362:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002366:	8526                	mv	a0,s1
    80002368:	fffff097          	auipc	ra,0xfffff
    8000236c:	91c080e7          	jalr	-1764(ra) # 80000c84 <release>
  sched();
    80002370:	00000097          	auipc	ra,0x0
    80002374:	bd4080e7          	jalr	-1068(ra) # 80001f44 <sched>
  panic("zombie exit");
    80002378:	00006517          	auipc	a0,0x6
    8000237c:	ef850513          	addi	a0,a0,-264 # 80008270 <digits+0x230>
    80002380:	ffffe097          	auipc	ra,0xffffe
    80002384:	1b8080e7          	jalr	440(ra) # 80000538 <panic>

0000000080002388 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002388:	7179                	addi	sp,sp,-48
    8000238a:	f406                	sd	ra,40(sp)
    8000238c:	f022                	sd	s0,32(sp)
    8000238e:	ec26                	sd	s1,24(sp)
    80002390:	e84a                	sd	s2,16(sp)
    80002392:	e44e                	sd	s3,8(sp)
    80002394:	1800                	addi	s0,sp,48
    80002396:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002398:	0000f497          	auipc	s1,0xf
    8000239c:	33848493          	addi	s1,s1,824 # 800116d0 <proc>
    800023a0:	00015997          	auipc	s3,0x15
    800023a4:	d3098993          	addi	s3,s3,-720 # 800170d0 <tickslock>
    acquire(&p->lock);
    800023a8:	8526                	mv	a0,s1
    800023aa:	fffff097          	auipc	ra,0xfffff
    800023ae:	826080e7          	jalr	-2010(ra) # 80000bd0 <acquire>
    if(p->pid == pid){
    800023b2:	589c                	lw	a5,48(s1)
    800023b4:	01278d63          	beq	a5,s2,800023ce <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023b8:	8526                	mv	a0,s1
    800023ba:	fffff097          	auipc	ra,0xfffff
    800023be:	8ca080e7          	jalr	-1846(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800023c2:	16848493          	addi	s1,s1,360
    800023c6:	ff3491e3          	bne	s1,s3,800023a8 <kill+0x20>
  }
  return -1;
    800023ca:	557d                	li	a0,-1
    800023cc:	a829                	j	800023e6 <kill+0x5e>
      p->killed = 1;
    800023ce:	4785                	li	a5,1
    800023d0:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800023d2:	4c98                	lw	a4,24(s1)
    800023d4:	4789                	li	a5,2
    800023d6:	00f70f63          	beq	a4,a5,800023f4 <kill+0x6c>
      release(&p->lock);
    800023da:	8526                	mv	a0,s1
    800023dc:	fffff097          	auipc	ra,0xfffff
    800023e0:	8a8080e7          	jalr	-1880(ra) # 80000c84 <release>
      return 0;
    800023e4:	4501                	li	a0,0
}
    800023e6:	70a2                	ld	ra,40(sp)
    800023e8:	7402                	ld	s0,32(sp)
    800023ea:	64e2                	ld	s1,24(sp)
    800023ec:	6942                	ld	s2,16(sp)
    800023ee:	69a2                	ld	s3,8(sp)
    800023f0:	6145                	addi	sp,sp,48
    800023f2:	8082                	ret
        p->state = RUNNABLE;
    800023f4:	478d                	li	a5,3
    800023f6:	cc9c                	sw	a5,24(s1)
    800023f8:	b7cd                	j	800023da <kill+0x52>

00000000800023fa <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800023fa:	7179                	addi	sp,sp,-48
    800023fc:	f406                	sd	ra,40(sp)
    800023fe:	f022                	sd	s0,32(sp)
    80002400:	ec26                	sd	s1,24(sp)
    80002402:	e84a                	sd	s2,16(sp)
    80002404:	e44e                	sd	s3,8(sp)
    80002406:	e052                	sd	s4,0(sp)
    80002408:	1800                	addi	s0,sp,48
    8000240a:	84aa                	mv	s1,a0
    8000240c:	892e                	mv	s2,a1
    8000240e:	89b2                	mv	s3,a2
    80002410:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002412:	fffff097          	auipc	ra,0xfffff
    80002416:	584080e7          	jalr	1412(ra) # 80001996 <myproc>
  if(user_dst){
    8000241a:	c08d                	beqz	s1,8000243c <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000241c:	86d2                	mv	a3,s4
    8000241e:	864e                	mv	a2,s3
    80002420:	85ca                	mv	a1,s2
    80002422:	6928                	ld	a0,80(a0)
    80002424:	fffff097          	auipc	ra,0xfffff
    80002428:	232080e7          	jalr	562(ra) # 80001656 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000242c:	70a2                	ld	ra,40(sp)
    8000242e:	7402                	ld	s0,32(sp)
    80002430:	64e2                	ld	s1,24(sp)
    80002432:	6942                	ld	s2,16(sp)
    80002434:	69a2                	ld	s3,8(sp)
    80002436:	6a02                	ld	s4,0(sp)
    80002438:	6145                	addi	sp,sp,48
    8000243a:	8082                	ret
    memmove((char *)dst, src, len);
    8000243c:	000a061b          	sext.w	a2,s4
    80002440:	85ce                	mv	a1,s3
    80002442:	854a                	mv	a0,s2
    80002444:	fffff097          	auipc	ra,0xfffff
    80002448:	8e4080e7          	jalr	-1820(ra) # 80000d28 <memmove>
    return 0;
    8000244c:	8526                	mv	a0,s1
    8000244e:	bff9                	j	8000242c <either_copyout+0x32>

0000000080002450 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002450:	7179                	addi	sp,sp,-48
    80002452:	f406                	sd	ra,40(sp)
    80002454:	f022                	sd	s0,32(sp)
    80002456:	ec26                	sd	s1,24(sp)
    80002458:	e84a                	sd	s2,16(sp)
    8000245a:	e44e                	sd	s3,8(sp)
    8000245c:	e052                	sd	s4,0(sp)
    8000245e:	1800                	addi	s0,sp,48
    80002460:	892a                	mv	s2,a0
    80002462:	84ae                	mv	s1,a1
    80002464:	89b2                	mv	s3,a2
    80002466:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002468:	fffff097          	auipc	ra,0xfffff
    8000246c:	52e080e7          	jalr	1326(ra) # 80001996 <myproc>
  if(user_src){
    80002470:	c08d                	beqz	s1,80002492 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002472:	86d2                	mv	a3,s4
    80002474:	864e                	mv	a2,s3
    80002476:	85ca                	mv	a1,s2
    80002478:	6928                	ld	a0,80(a0)
    8000247a:	fffff097          	auipc	ra,0xfffff
    8000247e:	268080e7          	jalr	616(ra) # 800016e2 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002482:	70a2                	ld	ra,40(sp)
    80002484:	7402                	ld	s0,32(sp)
    80002486:	64e2                	ld	s1,24(sp)
    80002488:	6942                	ld	s2,16(sp)
    8000248a:	69a2                	ld	s3,8(sp)
    8000248c:	6a02                	ld	s4,0(sp)
    8000248e:	6145                	addi	sp,sp,48
    80002490:	8082                	ret
    memmove(dst, (char*)src, len);
    80002492:	000a061b          	sext.w	a2,s4
    80002496:	85ce                	mv	a1,s3
    80002498:	854a                	mv	a0,s2
    8000249a:	fffff097          	auipc	ra,0xfffff
    8000249e:	88e080e7          	jalr	-1906(ra) # 80000d28 <memmove>
    return 0;
    800024a2:	8526                	mv	a0,s1
    800024a4:	bff9                	j	80002482 <either_copyin+0x32>

00000000800024a6 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800024a6:	715d                	addi	sp,sp,-80
    800024a8:	e486                	sd	ra,72(sp)
    800024aa:	e0a2                	sd	s0,64(sp)
    800024ac:	fc26                	sd	s1,56(sp)
    800024ae:	f84a                	sd	s2,48(sp)
    800024b0:	f44e                	sd	s3,40(sp)
    800024b2:	f052                	sd	s4,32(sp)
    800024b4:	ec56                	sd	s5,24(sp)
    800024b6:	e85a                	sd	s6,16(sp)
    800024b8:	e45e                	sd	s7,8(sp)
    800024ba:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800024bc:	00006517          	auipc	a0,0x6
    800024c0:	c0c50513          	addi	a0,a0,-1012 # 800080c8 <digits+0x88>
    800024c4:	ffffe097          	auipc	ra,0xffffe
    800024c8:	0be080e7          	jalr	190(ra) # 80000582 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800024cc:	0000f497          	auipc	s1,0xf
    800024d0:	35c48493          	addi	s1,s1,860 # 80011828 <proc+0x158>
    800024d4:	00015917          	auipc	s2,0x15
    800024d8:	d5490913          	addi	s2,s2,-684 # 80017228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024dc:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800024de:	00006997          	auipc	s3,0x6
    800024e2:	da298993          	addi	s3,s3,-606 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    800024e6:	00006a97          	auipc	s5,0x6
    800024ea:	da2a8a93          	addi	s5,s5,-606 # 80008288 <digits+0x248>
    printf("\n");
    800024ee:	00006a17          	auipc	s4,0x6
    800024f2:	bdaa0a13          	addi	s4,s4,-1062 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024f6:	00006b97          	auipc	s7,0x6
    800024fa:	dfab8b93          	addi	s7,s7,-518 # 800082f0 <states.0>
    800024fe:	a00d                	j	80002520 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002500:	ed86a583          	lw	a1,-296(a3)
    80002504:	8556                	mv	a0,s5
    80002506:	ffffe097          	auipc	ra,0xffffe
    8000250a:	07c080e7          	jalr	124(ra) # 80000582 <printf>
    printf("\n");
    8000250e:	8552                	mv	a0,s4
    80002510:	ffffe097          	auipc	ra,0xffffe
    80002514:	072080e7          	jalr	114(ra) # 80000582 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002518:	16848493          	addi	s1,s1,360
    8000251c:	03248163          	beq	s1,s2,8000253e <procdump+0x98>
    if(p->state == UNUSED)
    80002520:	86a6                	mv	a3,s1
    80002522:	ec04a783          	lw	a5,-320(s1)
    80002526:	dbed                	beqz	a5,80002518 <procdump+0x72>
      state = "???";
    80002528:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000252a:	fcfb6be3          	bltu	s6,a5,80002500 <procdump+0x5a>
    8000252e:	1782                	slli	a5,a5,0x20
    80002530:	9381                	srli	a5,a5,0x20
    80002532:	078e                	slli	a5,a5,0x3
    80002534:	97de                	add	a5,a5,s7
    80002536:	6390                	ld	a2,0(a5)
    80002538:	f661                	bnez	a2,80002500 <procdump+0x5a>
      state = "???";
    8000253a:	864e                	mv	a2,s3
    8000253c:	b7d1                	j	80002500 <procdump+0x5a>
  }
}
    8000253e:	60a6                	ld	ra,72(sp)
    80002540:	6406                	ld	s0,64(sp)
    80002542:	74e2                	ld	s1,56(sp)
    80002544:	7942                	ld	s2,48(sp)
    80002546:	79a2                	ld	s3,40(sp)
    80002548:	7a02                	ld	s4,32(sp)
    8000254a:	6ae2                	ld	s5,24(sp)
    8000254c:	6b42                	ld	s6,16(sp)
    8000254e:	6ba2                	ld	s7,8(sp)
    80002550:	6161                	addi	sp,sp,80
    80002552:	8082                	ret

0000000080002554 <ps>:
// Aidan Darlington
// StudentID: 21134427
// Function to check what processes are running and prints them out
int
ps(int onlyrunning)
{
    80002554:	711d                	addi	sp,sp,-96
    80002556:	ec86                	sd	ra,88(sp)
    80002558:	e8a2                	sd	s0,80(sp)
    8000255a:	e4a6                	sd	s1,72(sp)
    8000255c:	e0ca                	sd	s2,64(sp)
    8000255e:	fc4e                	sd	s3,56(sp)
    80002560:	f852                	sd	s4,48(sp)
    80002562:	f456                	sd	s5,40(sp)
    80002564:	f05a                	sd	s6,32(sp)
    80002566:	ec5e                	sd	s7,24(sp)
    80002568:	e862                	sd	s8,16(sp)
    8000256a:	e466                	sd	s9,8(sp)
    8000256c:	e06a                	sd	s10,0(sp)
    8000256e:	1080                	addi	s0,sp,96
    80002570:	8baa                	mv	s7,a0
  struct proc *p;

  // Loop through the process table
  for(p = proc; p < &proc[NPROC]; p++){
    80002572:	0000f497          	auipc	s1,0xf
    80002576:	2b648493          	addi	s1,s1,694 # 80011828 <proc+0x158>
    8000257a:	00015997          	auipc	s3,0x15
    8000257e:	cae98993          	addi	s3,s3,-850 # 80017228 <bcache+0x140>
    if(p->state == RUNNING || (!onlyrunning && p->state == SLEEPING)){
    80002582:	4911                	li	s2,4
      if (onlyrunning && p->state != RUNNING) {
	continue;
      }

      // Print process information
      if(p->pid == 1){
    80002584:	4a05                	li	s4,1
        printf("%d 0 %s %s %d\n", p->pid, state, p->name, p->sz);
      }
      else{
        printf("%d %d %s %s %d\n", p->pid, p->parent->pid, state, p->name, p->sz);
    80002586:	00006c17          	auipc	s8,0x6
    8000258a:	d32c0c13          	addi	s8,s8,-718 # 800082b8 <digits+0x278>
        printf("%d 0 %s %s %d\n", p->pid, state, p->name, p->sz);
    8000258e:	00006d17          	auipc	s10,0x6
    80002592:	d1ad0d13          	addi	s10,s10,-742 # 800082a8 <digits+0x268>
	state = "running";
    80002596:	00006a97          	auipc	s5,0x6
    8000259a:	d02a8a93          	addi	s5,s5,-766 # 80008298 <digits+0x258>
    if(p->state == RUNNING || (!onlyrunning && p->state == SLEEPING)){
    8000259e:	4b09                	li	s6,2
	state = "sleep";
    800025a0:	00006c97          	auipc	s9,0x6
    800025a4:	d00c8c93          	addi	s9,s9,-768 # 800082a0 <digits+0x260>
    800025a8:	a035                	j	800025d4 <ps+0x80>
	state = "running";
    800025aa:	8656                	mv	a2,s5
      if(p->pid == 1){
    800025ac:	ed86a583          	lw	a1,-296(a3)
    800025b0:	03458d63          	beq	a1,s4,800025ea <ps+0x96>
        printf("%d %d %s %s %d\n", p->pid, p->parent->pid, state, p->name, p->sz);
    800025b4:	ee06b503          	ld	a0,-288(a3)
    800025b8:	ef06b783          	ld	a5,-272(a3)
    800025bc:	8736                	mv	a4,a3
    800025be:	86b2                	mv	a3,a2
    800025c0:	5910                	lw	a2,48(a0)
    800025c2:	8562                	mv	a0,s8
    800025c4:	ffffe097          	auipc	ra,0xffffe
    800025c8:	fbe080e7          	jalr	-66(ra) # 80000582 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025cc:	16848493          	addi	s1,s1,360
    800025d0:	03348663          	beq	s1,s3,800025fc <ps+0xa8>
    if(p->state == RUNNING || (!onlyrunning && p->state == SLEEPING)){
    800025d4:	86a6                	mv	a3,s1
    800025d6:	ec04a783          	lw	a5,-320(s1)
    800025da:	fd2788e3          	beq	a5,s2,800025aa <ps+0x56>
    800025de:	ff6797e3          	bne	a5,s6,800025cc <ps+0x78>
	state = "sleep";
    800025e2:	8666                	mv	a2,s9
      if (onlyrunning && p->state != RUNNING) {
    800025e4:	fc0b84e3          	beqz	s7,800025ac <ps+0x58>
    800025e8:	b7d5                	j	800025cc <ps+0x78>
        printf("%d 0 %s %s %d\n", p->pid, state, p->name, p->sz);
    800025ea:	ef06b703          	ld	a4,-272(a3)
    800025ee:	85d2                	mv	a1,s4
    800025f0:	856a                	mv	a0,s10
    800025f2:	ffffe097          	auipc	ra,0xffffe
    800025f6:	f90080e7          	jalr	-112(ra) # 80000582 <printf>
    800025fa:	bfc9                	j	800025cc <ps+0x78>
      }
    }
  }
  return 0;
}
    800025fc:	4501                	li	a0,0
    800025fe:	60e6                	ld	ra,88(sp)
    80002600:	6446                	ld	s0,80(sp)
    80002602:	64a6                	ld	s1,72(sp)
    80002604:	6906                	ld	s2,64(sp)
    80002606:	79e2                	ld	s3,56(sp)
    80002608:	7a42                	ld	s4,48(sp)
    8000260a:	7aa2                	ld	s5,40(sp)
    8000260c:	7b02                	ld	s6,32(sp)
    8000260e:	6be2                	ld	s7,24(sp)
    80002610:	6c42                	ld	s8,16(sp)
    80002612:	6ca2                	ld	s9,8(sp)
    80002614:	6d02                	ld	s10,0(sp)
    80002616:	6125                	addi	sp,sp,96
    80002618:	8082                	ret

000000008000261a <swtch>:
    8000261a:	00153023          	sd	ra,0(a0)
    8000261e:	00253423          	sd	sp,8(a0)
    80002622:	e900                	sd	s0,16(a0)
    80002624:	ed04                	sd	s1,24(a0)
    80002626:	03253023          	sd	s2,32(a0)
    8000262a:	03353423          	sd	s3,40(a0)
    8000262e:	03453823          	sd	s4,48(a0)
    80002632:	03553c23          	sd	s5,56(a0)
    80002636:	05653023          	sd	s6,64(a0)
    8000263a:	05753423          	sd	s7,72(a0)
    8000263e:	05853823          	sd	s8,80(a0)
    80002642:	05953c23          	sd	s9,88(a0)
    80002646:	07a53023          	sd	s10,96(a0)
    8000264a:	07b53423          	sd	s11,104(a0)
    8000264e:	0005b083          	ld	ra,0(a1)
    80002652:	0085b103          	ld	sp,8(a1)
    80002656:	6980                	ld	s0,16(a1)
    80002658:	6d84                	ld	s1,24(a1)
    8000265a:	0205b903          	ld	s2,32(a1)
    8000265e:	0285b983          	ld	s3,40(a1)
    80002662:	0305ba03          	ld	s4,48(a1)
    80002666:	0385ba83          	ld	s5,56(a1)
    8000266a:	0405bb03          	ld	s6,64(a1)
    8000266e:	0485bb83          	ld	s7,72(a1)
    80002672:	0505bc03          	ld	s8,80(a1)
    80002676:	0585bc83          	ld	s9,88(a1)
    8000267a:	0605bd03          	ld	s10,96(a1)
    8000267e:	0685bd83          	ld	s11,104(a1)
    80002682:	8082                	ret

0000000080002684 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002684:	1141                	addi	sp,sp,-16
    80002686:	e406                	sd	ra,8(sp)
    80002688:	e022                	sd	s0,0(sp)
    8000268a:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000268c:	00006597          	auipc	a1,0x6
    80002690:	c9458593          	addi	a1,a1,-876 # 80008320 <states.0+0x30>
    80002694:	00015517          	auipc	a0,0x15
    80002698:	a3c50513          	addi	a0,a0,-1476 # 800170d0 <tickslock>
    8000269c:	ffffe097          	auipc	ra,0xffffe
    800026a0:	4a4080e7          	jalr	1188(ra) # 80000b40 <initlock>
}
    800026a4:	60a2                	ld	ra,8(sp)
    800026a6:	6402                	ld	s0,0(sp)
    800026a8:	0141                	addi	sp,sp,16
    800026aa:	8082                	ret

00000000800026ac <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026ac:	1141                	addi	sp,sp,-16
    800026ae:	e422                	sd	s0,8(sp)
    800026b0:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026b2:	00003797          	auipc	a5,0x3
    800026b6:	57e78793          	addi	a5,a5,1406 # 80005c30 <kernelvec>
    800026ba:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026be:	6422                	ld	s0,8(sp)
    800026c0:	0141                	addi	sp,sp,16
    800026c2:	8082                	ret

00000000800026c4 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800026c4:	1141                	addi	sp,sp,-16
    800026c6:	e406                	sd	ra,8(sp)
    800026c8:	e022                	sd	s0,0(sp)
    800026ca:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800026cc:	fffff097          	auipc	ra,0xfffff
    800026d0:	2ca080e7          	jalr	714(ra) # 80001996 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026d4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026d8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026da:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800026de:	00005617          	auipc	a2,0x5
    800026e2:	92260613          	addi	a2,a2,-1758 # 80007000 <_trampoline>
    800026e6:	00005697          	auipc	a3,0x5
    800026ea:	91a68693          	addi	a3,a3,-1766 # 80007000 <_trampoline>
    800026ee:	8e91                	sub	a3,a3,a2
    800026f0:	040007b7          	lui	a5,0x4000
    800026f4:	17fd                	addi	a5,a5,-1
    800026f6:	07b2                	slli	a5,a5,0xc
    800026f8:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026fa:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800026fe:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002700:	180026f3          	csrr	a3,satp
    80002704:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002706:	6d38                	ld	a4,88(a0)
    80002708:	6134                	ld	a3,64(a0)
    8000270a:	6585                	lui	a1,0x1
    8000270c:	96ae                	add	a3,a3,a1
    8000270e:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002710:	6d38                	ld	a4,88(a0)
    80002712:	00000697          	auipc	a3,0x0
    80002716:	13868693          	addi	a3,a3,312 # 8000284a <usertrap>
    8000271a:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000271c:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000271e:	8692                	mv	a3,tp
    80002720:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002722:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002726:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000272a:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000272e:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002732:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002734:	6f18                	ld	a4,24(a4)
    80002736:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000273a:	692c                	ld	a1,80(a0)
    8000273c:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000273e:	00005717          	auipc	a4,0x5
    80002742:	95270713          	addi	a4,a4,-1710 # 80007090 <userret>
    80002746:	8f11                	sub	a4,a4,a2
    80002748:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000274a:	577d                	li	a4,-1
    8000274c:	177e                	slli	a4,a4,0x3f
    8000274e:	8dd9                	or	a1,a1,a4
    80002750:	02000537          	lui	a0,0x2000
    80002754:	157d                	addi	a0,a0,-1
    80002756:	0536                	slli	a0,a0,0xd
    80002758:	9782                	jalr	a5
}
    8000275a:	60a2                	ld	ra,8(sp)
    8000275c:	6402                	ld	s0,0(sp)
    8000275e:	0141                	addi	sp,sp,16
    80002760:	8082                	ret

0000000080002762 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002762:	1101                	addi	sp,sp,-32
    80002764:	ec06                	sd	ra,24(sp)
    80002766:	e822                	sd	s0,16(sp)
    80002768:	e426                	sd	s1,8(sp)
    8000276a:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000276c:	00015497          	auipc	s1,0x15
    80002770:	96448493          	addi	s1,s1,-1692 # 800170d0 <tickslock>
    80002774:	8526                	mv	a0,s1
    80002776:	ffffe097          	auipc	ra,0xffffe
    8000277a:	45a080e7          	jalr	1114(ra) # 80000bd0 <acquire>
  ticks++;
    8000277e:	00007517          	auipc	a0,0x7
    80002782:	8b250513          	addi	a0,a0,-1870 # 80009030 <ticks>
    80002786:	411c                	lw	a5,0(a0)
    80002788:	2785                	addiw	a5,a5,1
    8000278a:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000278c:	00000097          	auipc	ra,0x0
    80002790:	a56080e7          	jalr	-1450(ra) # 800021e2 <wakeup>
  release(&tickslock);
    80002794:	8526                	mv	a0,s1
    80002796:	ffffe097          	auipc	ra,0xffffe
    8000279a:	4ee080e7          	jalr	1262(ra) # 80000c84 <release>
}
    8000279e:	60e2                	ld	ra,24(sp)
    800027a0:	6442                	ld	s0,16(sp)
    800027a2:	64a2                	ld	s1,8(sp)
    800027a4:	6105                	addi	sp,sp,32
    800027a6:	8082                	ret

00000000800027a8 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027a8:	1101                	addi	sp,sp,-32
    800027aa:	ec06                	sd	ra,24(sp)
    800027ac:	e822                	sd	s0,16(sp)
    800027ae:	e426                	sd	s1,8(sp)
    800027b0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027b2:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027b6:	00074d63          	bltz	a4,800027d0 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027ba:	57fd                	li	a5,-1
    800027bc:	17fe                	slli	a5,a5,0x3f
    800027be:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027c0:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800027c2:	06f70363          	beq	a4,a5,80002828 <devintr+0x80>
  }
}
    800027c6:	60e2                	ld	ra,24(sp)
    800027c8:	6442                	ld	s0,16(sp)
    800027ca:	64a2                	ld	s1,8(sp)
    800027cc:	6105                	addi	sp,sp,32
    800027ce:	8082                	ret
     (scause & 0xff) == 9){
    800027d0:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800027d4:	46a5                	li	a3,9
    800027d6:	fed792e3          	bne	a5,a3,800027ba <devintr+0x12>
    int irq = plic_claim();
    800027da:	00003097          	auipc	ra,0x3
    800027de:	55e080e7          	jalr	1374(ra) # 80005d38 <plic_claim>
    800027e2:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800027e4:	47a9                	li	a5,10
    800027e6:	02f50763          	beq	a0,a5,80002814 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800027ea:	4785                	li	a5,1
    800027ec:	02f50963          	beq	a0,a5,8000281e <devintr+0x76>
    return 1;
    800027f0:	4505                	li	a0,1
    } else if(irq){
    800027f2:	d8f1                	beqz	s1,800027c6 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800027f4:	85a6                	mv	a1,s1
    800027f6:	00006517          	auipc	a0,0x6
    800027fa:	b3250513          	addi	a0,a0,-1230 # 80008328 <states.0+0x38>
    800027fe:	ffffe097          	auipc	ra,0xffffe
    80002802:	d84080e7          	jalr	-636(ra) # 80000582 <printf>
      plic_complete(irq);
    80002806:	8526                	mv	a0,s1
    80002808:	00003097          	auipc	ra,0x3
    8000280c:	554080e7          	jalr	1364(ra) # 80005d5c <plic_complete>
    return 1;
    80002810:	4505                	li	a0,1
    80002812:	bf55                	j	800027c6 <devintr+0x1e>
      uartintr();
    80002814:	ffffe097          	auipc	ra,0xffffe
    80002818:	180080e7          	jalr	384(ra) # 80000994 <uartintr>
    8000281c:	b7ed                	j	80002806 <devintr+0x5e>
      virtio_disk_intr();
    8000281e:	00004097          	auipc	ra,0x4
    80002822:	9d0080e7          	jalr	-1584(ra) # 800061ee <virtio_disk_intr>
    80002826:	b7c5                	j	80002806 <devintr+0x5e>
    if(cpuid() == 0){
    80002828:	fffff097          	auipc	ra,0xfffff
    8000282c:	142080e7          	jalr	322(ra) # 8000196a <cpuid>
    80002830:	c901                	beqz	a0,80002840 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002832:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002836:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002838:	14479073          	csrw	sip,a5
    return 2;
    8000283c:	4509                	li	a0,2
    8000283e:	b761                	j	800027c6 <devintr+0x1e>
      clockintr();
    80002840:	00000097          	auipc	ra,0x0
    80002844:	f22080e7          	jalr	-222(ra) # 80002762 <clockintr>
    80002848:	b7ed                	j	80002832 <devintr+0x8a>

000000008000284a <usertrap>:
{
    8000284a:	1101                	addi	sp,sp,-32
    8000284c:	ec06                	sd	ra,24(sp)
    8000284e:	e822                	sd	s0,16(sp)
    80002850:	e426                	sd	s1,8(sp)
    80002852:	e04a                	sd	s2,0(sp)
    80002854:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002856:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000285a:	1007f793          	andi	a5,a5,256
    8000285e:	e3ad                	bnez	a5,800028c0 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002860:	00003797          	auipc	a5,0x3
    80002864:	3d078793          	addi	a5,a5,976 # 80005c30 <kernelvec>
    80002868:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000286c:	fffff097          	auipc	ra,0xfffff
    80002870:	12a080e7          	jalr	298(ra) # 80001996 <myproc>
    80002874:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002876:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002878:	14102773          	csrr	a4,sepc
    8000287c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000287e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002882:	47a1                	li	a5,8
    80002884:	04f71c63          	bne	a4,a5,800028dc <usertrap+0x92>
    if(p->killed)
    80002888:	551c                	lw	a5,40(a0)
    8000288a:	e3b9                	bnez	a5,800028d0 <usertrap+0x86>
    p->trapframe->epc += 4;
    8000288c:	6cb8                	ld	a4,88(s1)
    8000288e:	6f1c                	ld	a5,24(a4)
    80002890:	0791                	addi	a5,a5,4
    80002892:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002894:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002898:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000289c:	10079073          	csrw	sstatus,a5
    syscall();
    800028a0:	00000097          	auipc	ra,0x0
    800028a4:	2e0080e7          	jalr	736(ra) # 80002b80 <syscall>
  if(p->killed)
    800028a8:	549c                	lw	a5,40(s1)
    800028aa:	ebc1                	bnez	a5,8000293a <usertrap+0xf0>
  usertrapret();
    800028ac:	00000097          	auipc	ra,0x0
    800028b0:	e18080e7          	jalr	-488(ra) # 800026c4 <usertrapret>
}
    800028b4:	60e2                	ld	ra,24(sp)
    800028b6:	6442                	ld	s0,16(sp)
    800028b8:	64a2                	ld	s1,8(sp)
    800028ba:	6902                	ld	s2,0(sp)
    800028bc:	6105                	addi	sp,sp,32
    800028be:	8082                	ret
    panic("usertrap: not from user mode");
    800028c0:	00006517          	auipc	a0,0x6
    800028c4:	a8850513          	addi	a0,a0,-1400 # 80008348 <states.0+0x58>
    800028c8:	ffffe097          	auipc	ra,0xffffe
    800028cc:	c70080e7          	jalr	-912(ra) # 80000538 <panic>
      exit(-1);
    800028d0:	557d                	li	a0,-1
    800028d2:	00000097          	auipc	ra,0x0
    800028d6:	9e0080e7          	jalr	-1568(ra) # 800022b2 <exit>
    800028da:	bf4d                	j	8000288c <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800028dc:	00000097          	auipc	ra,0x0
    800028e0:	ecc080e7          	jalr	-308(ra) # 800027a8 <devintr>
    800028e4:	892a                	mv	s2,a0
    800028e6:	c501                	beqz	a0,800028ee <usertrap+0xa4>
  if(p->killed)
    800028e8:	549c                	lw	a5,40(s1)
    800028ea:	c3a1                	beqz	a5,8000292a <usertrap+0xe0>
    800028ec:	a815                	j	80002920 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028ee:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800028f2:	5890                	lw	a2,48(s1)
    800028f4:	00006517          	auipc	a0,0x6
    800028f8:	a7450513          	addi	a0,a0,-1420 # 80008368 <states.0+0x78>
    800028fc:	ffffe097          	auipc	ra,0xffffe
    80002900:	c86080e7          	jalr	-890(ra) # 80000582 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002904:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002908:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000290c:	00006517          	auipc	a0,0x6
    80002910:	a8c50513          	addi	a0,a0,-1396 # 80008398 <states.0+0xa8>
    80002914:	ffffe097          	auipc	ra,0xffffe
    80002918:	c6e080e7          	jalr	-914(ra) # 80000582 <printf>
    p->killed = 1;
    8000291c:	4785                	li	a5,1
    8000291e:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002920:	557d                	li	a0,-1
    80002922:	00000097          	auipc	ra,0x0
    80002926:	990080e7          	jalr	-1648(ra) # 800022b2 <exit>
  if(which_dev == 2)
    8000292a:	4789                	li	a5,2
    8000292c:	f8f910e3          	bne	s2,a5,800028ac <usertrap+0x62>
    yield();
    80002930:	fffff097          	auipc	ra,0xfffff
    80002934:	6ea080e7          	jalr	1770(ra) # 8000201a <yield>
    80002938:	bf95                	j	800028ac <usertrap+0x62>
  int which_dev = 0;
    8000293a:	4901                	li	s2,0
    8000293c:	b7d5                	j	80002920 <usertrap+0xd6>

000000008000293e <kerneltrap>:
{
    8000293e:	7179                	addi	sp,sp,-48
    80002940:	f406                	sd	ra,40(sp)
    80002942:	f022                	sd	s0,32(sp)
    80002944:	ec26                	sd	s1,24(sp)
    80002946:	e84a                	sd	s2,16(sp)
    80002948:	e44e                	sd	s3,8(sp)
    8000294a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000294c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002950:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002954:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002958:	1004f793          	andi	a5,s1,256
    8000295c:	cb85                	beqz	a5,8000298c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000295e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002962:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002964:	ef85                	bnez	a5,8000299c <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002966:	00000097          	auipc	ra,0x0
    8000296a:	e42080e7          	jalr	-446(ra) # 800027a8 <devintr>
    8000296e:	cd1d                	beqz	a0,800029ac <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002970:	4789                	li	a5,2
    80002972:	06f50a63          	beq	a0,a5,800029e6 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002976:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000297a:	10049073          	csrw	sstatus,s1
}
    8000297e:	70a2                	ld	ra,40(sp)
    80002980:	7402                	ld	s0,32(sp)
    80002982:	64e2                	ld	s1,24(sp)
    80002984:	6942                	ld	s2,16(sp)
    80002986:	69a2                	ld	s3,8(sp)
    80002988:	6145                	addi	sp,sp,48
    8000298a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000298c:	00006517          	auipc	a0,0x6
    80002990:	a2c50513          	addi	a0,a0,-1492 # 800083b8 <states.0+0xc8>
    80002994:	ffffe097          	auipc	ra,0xffffe
    80002998:	ba4080e7          	jalr	-1116(ra) # 80000538 <panic>
    panic("kerneltrap: interrupts enabled");
    8000299c:	00006517          	auipc	a0,0x6
    800029a0:	a4450513          	addi	a0,a0,-1468 # 800083e0 <states.0+0xf0>
    800029a4:	ffffe097          	auipc	ra,0xffffe
    800029a8:	b94080e7          	jalr	-1132(ra) # 80000538 <panic>
    printf("scause %p\n", scause);
    800029ac:	85ce                	mv	a1,s3
    800029ae:	00006517          	auipc	a0,0x6
    800029b2:	a5250513          	addi	a0,a0,-1454 # 80008400 <states.0+0x110>
    800029b6:	ffffe097          	auipc	ra,0xffffe
    800029ba:	bcc080e7          	jalr	-1076(ra) # 80000582 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029be:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029c2:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029c6:	00006517          	auipc	a0,0x6
    800029ca:	a4a50513          	addi	a0,a0,-1462 # 80008410 <states.0+0x120>
    800029ce:	ffffe097          	auipc	ra,0xffffe
    800029d2:	bb4080e7          	jalr	-1100(ra) # 80000582 <printf>
    panic("kerneltrap");
    800029d6:	00006517          	auipc	a0,0x6
    800029da:	a5250513          	addi	a0,a0,-1454 # 80008428 <states.0+0x138>
    800029de:	ffffe097          	auipc	ra,0xffffe
    800029e2:	b5a080e7          	jalr	-1190(ra) # 80000538 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029e6:	fffff097          	auipc	ra,0xfffff
    800029ea:	fb0080e7          	jalr	-80(ra) # 80001996 <myproc>
    800029ee:	d541                	beqz	a0,80002976 <kerneltrap+0x38>
    800029f0:	fffff097          	auipc	ra,0xfffff
    800029f4:	fa6080e7          	jalr	-90(ra) # 80001996 <myproc>
    800029f8:	4d18                	lw	a4,24(a0)
    800029fa:	4791                	li	a5,4
    800029fc:	f6f71de3          	bne	a4,a5,80002976 <kerneltrap+0x38>
    yield();
    80002a00:	fffff097          	auipc	ra,0xfffff
    80002a04:	61a080e7          	jalr	1562(ra) # 8000201a <yield>
    80002a08:	b7bd                	j	80002976 <kerneltrap+0x38>

0000000080002a0a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a0a:	1101                	addi	sp,sp,-32
    80002a0c:	ec06                	sd	ra,24(sp)
    80002a0e:	e822                	sd	s0,16(sp)
    80002a10:	e426                	sd	s1,8(sp)
    80002a12:	1000                	addi	s0,sp,32
    80002a14:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a16:	fffff097          	auipc	ra,0xfffff
    80002a1a:	f80080e7          	jalr	-128(ra) # 80001996 <myproc>
  switch (n) {
    80002a1e:	4795                	li	a5,5
    80002a20:	0497e163          	bltu	a5,s1,80002a62 <argraw+0x58>
    80002a24:	048a                	slli	s1,s1,0x2
    80002a26:	00006717          	auipc	a4,0x6
    80002a2a:	a3a70713          	addi	a4,a4,-1478 # 80008460 <states.0+0x170>
    80002a2e:	94ba                	add	s1,s1,a4
    80002a30:	409c                	lw	a5,0(s1)
    80002a32:	97ba                	add	a5,a5,a4
    80002a34:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a36:	6d3c                	ld	a5,88(a0)
    80002a38:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a3a:	60e2                	ld	ra,24(sp)
    80002a3c:	6442                	ld	s0,16(sp)
    80002a3e:	64a2                	ld	s1,8(sp)
    80002a40:	6105                	addi	sp,sp,32
    80002a42:	8082                	ret
    return p->trapframe->a1;
    80002a44:	6d3c                	ld	a5,88(a0)
    80002a46:	7fa8                	ld	a0,120(a5)
    80002a48:	bfcd                	j	80002a3a <argraw+0x30>
    return p->trapframe->a2;
    80002a4a:	6d3c                	ld	a5,88(a0)
    80002a4c:	63c8                	ld	a0,128(a5)
    80002a4e:	b7f5                	j	80002a3a <argraw+0x30>
    return p->trapframe->a3;
    80002a50:	6d3c                	ld	a5,88(a0)
    80002a52:	67c8                	ld	a0,136(a5)
    80002a54:	b7dd                	j	80002a3a <argraw+0x30>
    return p->trapframe->a4;
    80002a56:	6d3c                	ld	a5,88(a0)
    80002a58:	6bc8                	ld	a0,144(a5)
    80002a5a:	b7c5                	j	80002a3a <argraw+0x30>
    return p->trapframe->a5;
    80002a5c:	6d3c                	ld	a5,88(a0)
    80002a5e:	6fc8                	ld	a0,152(a5)
    80002a60:	bfe9                	j	80002a3a <argraw+0x30>
  panic("argraw");
    80002a62:	00006517          	auipc	a0,0x6
    80002a66:	9d650513          	addi	a0,a0,-1578 # 80008438 <states.0+0x148>
    80002a6a:	ffffe097          	auipc	ra,0xffffe
    80002a6e:	ace080e7          	jalr	-1330(ra) # 80000538 <panic>

0000000080002a72 <fetchaddr>:
{
    80002a72:	1101                	addi	sp,sp,-32
    80002a74:	ec06                	sd	ra,24(sp)
    80002a76:	e822                	sd	s0,16(sp)
    80002a78:	e426                	sd	s1,8(sp)
    80002a7a:	e04a                	sd	s2,0(sp)
    80002a7c:	1000                	addi	s0,sp,32
    80002a7e:	84aa                	mv	s1,a0
    80002a80:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a82:	fffff097          	auipc	ra,0xfffff
    80002a86:	f14080e7          	jalr	-236(ra) # 80001996 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002a8a:	653c                	ld	a5,72(a0)
    80002a8c:	02f4f863          	bgeu	s1,a5,80002abc <fetchaddr+0x4a>
    80002a90:	00848713          	addi	a4,s1,8
    80002a94:	02e7e663          	bltu	a5,a4,80002ac0 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a98:	46a1                	li	a3,8
    80002a9a:	8626                	mv	a2,s1
    80002a9c:	85ca                	mv	a1,s2
    80002a9e:	6928                	ld	a0,80(a0)
    80002aa0:	fffff097          	auipc	ra,0xfffff
    80002aa4:	c42080e7          	jalr	-958(ra) # 800016e2 <copyin>
    80002aa8:	00a03533          	snez	a0,a0
    80002aac:	40a00533          	neg	a0,a0
}
    80002ab0:	60e2                	ld	ra,24(sp)
    80002ab2:	6442                	ld	s0,16(sp)
    80002ab4:	64a2                	ld	s1,8(sp)
    80002ab6:	6902                	ld	s2,0(sp)
    80002ab8:	6105                	addi	sp,sp,32
    80002aba:	8082                	ret
    return -1;
    80002abc:	557d                	li	a0,-1
    80002abe:	bfcd                	j	80002ab0 <fetchaddr+0x3e>
    80002ac0:	557d                	li	a0,-1
    80002ac2:	b7fd                	j	80002ab0 <fetchaddr+0x3e>

0000000080002ac4 <fetchstr>:
{
    80002ac4:	7179                	addi	sp,sp,-48
    80002ac6:	f406                	sd	ra,40(sp)
    80002ac8:	f022                	sd	s0,32(sp)
    80002aca:	ec26                	sd	s1,24(sp)
    80002acc:	e84a                	sd	s2,16(sp)
    80002ace:	e44e                	sd	s3,8(sp)
    80002ad0:	1800                	addi	s0,sp,48
    80002ad2:	892a                	mv	s2,a0
    80002ad4:	84ae                	mv	s1,a1
    80002ad6:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002ad8:	fffff097          	auipc	ra,0xfffff
    80002adc:	ebe080e7          	jalr	-322(ra) # 80001996 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002ae0:	86ce                	mv	a3,s3
    80002ae2:	864a                	mv	a2,s2
    80002ae4:	85a6                	mv	a1,s1
    80002ae6:	6928                	ld	a0,80(a0)
    80002ae8:	fffff097          	auipc	ra,0xfffff
    80002aec:	c88080e7          	jalr	-888(ra) # 80001770 <copyinstr>
  if(err < 0)
    80002af0:	00054763          	bltz	a0,80002afe <fetchstr+0x3a>
  return strlen(buf);
    80002af4:	8526                	mv	a0,s1
    80002af6:	ffffe097          	auipc	ra,0xffffe
    80002afa:	352080e7          	jalr	850(ra) # 80000e48 <strlen>
}
    80002afe:	70a2                	ld	ra,40(sp)
    80002b00:	7402                	ld	s0,32(sp)
    80002b02:	64e2                	ld	s1,24(sp)
    80002b04:	6942                	ld	s2,16(sp)
    80002b06:	69a2                	ld	s3,8(sp)
    80002b08:	6145                	addi	sp,sp,48
    80002b0a:	8082                	ret

0000000080002b0c <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002b0c:	1101                	addi	sp,sp,-32
    80002b0e:	ec06                	sd	ra,24(sp)
    80002b10:	e822                	sd	s0,16(sp)
    80002b12:	e426                	sd	s1,8(sp)
    80002b14:	1000                	addi	s0,sp,32
    80002b16:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b18:	00000097          	auipc	ra,0x0
    80002b1c:	ef2080e7          	jalr	-270(ra) # 80002a0a <argraw>
    80002b20:	c088                	sw	a0,0(s1)
  return 0;
}
    80002b22:	4501                	li	a0,0
    80002b24:	60e2                	ld	ra,24(sp)
    80002b26:	6442                	ld	s0,16(sp)
    80002b28:	64a2                	ld	s1,8(sp)
    80002b2a:	6105                	addi	sp,sp,32
    80002b2c:	8082                	ret

0000000080002b2e <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002b2e:	1101                	addi	sp,sp,-32
    80002b30:	ec06                	sd	ra,24(sp)
    80002b32:	e822                	sd	s0,16(sp)
    80002b34:	e426                	sd	s1,8(sp)
    80002b36:	1000                	addi	s0,sp,32
    80002b38:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b3a:	00000097          	auipc	ra,0x0
    80002b3e:	ed0080e7          	jalr	-304(ra) # 80002a0a <argraw>
    80002b42:	e088                	sd	a0,0(s1)
  return 0;
}
    80002b44:	4501                	li	a0,0
    80002b46:	60e2                	ld	ra,24(sp)
    80002b48:	6442                	ld	s0,16(sp)
    80002b4a:	64a2                	ld	s1,8(sp)
    80002b4c:	6105                	addi	sp,sp,32
    80002b4e:	8082                	ret

0000000080002b50 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b50:	1101                	addi	sp,sp,-32
    80002b52:	ec06                	sd	ra,24(sp)
    80002b54:	e822                	sd	s0,16(sp)
    80002b56:	e426                	sd	s1,8(sp)
    80002b58:	e04a                	sd	s2,0(sp)
    80002b5a:	1000                	addi	s0,sp,32
    80002b5c:	84ae                	mv	s1,a1
    80002b5e:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002b60:	00000097          	auipc	ra,0x0
    80002b64:	eaa080e7          	jalr	-342(ra) # 80002a0a <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002b68:	864a                	mv	a2,s2
    80002b6a:	85a6                	mv	a1,s1
    80002b6c:	00000097          	auipc	ra,0x0
    80002b70:	f58080e7          	jalr	-168(ra) # 80002ac4 <fetchstr>
}
    80002b74:	60e2                	ld	ra,24(sp)
    80002b76:	6442                	ld	s0,16(sp)
    80002b78:	64a2                	ld	s1,8(sp)
    80002b7a:	6902                	ld	s2,0(sp)
    80002b7c:	6105                	addi	sp,sp,32
    80002b7e:	8082                	ret

0000000080002b80 <syscall>:
[SYS_pageAccess] sys_pageAccess,
};

void
syscall(void)
{
    80002b80:	1101                	addi	sp,sp,-32
    80002b82:	ec06                	sd	ra,24(sp)
    80002b84:	e822                	sd	s0,16(sp)
    80002b86:	e426                	sd	s1,8(sp)
    80002b88:	e04a                	sd	s2,0(sp)
    80002b8a:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002b8c:	fffff097          	auipc	ra,0xfffff
    80002b90:	e0a080e7          	jalr	-502(ra) # 80001996 <myproc>
    80002b94:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002b96:	05853903          	ld	s2,88(a0)
    80002b9a:	0a893783          	ld	a5,168(s2)
    80002b9e:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002ba2:	37fd                	addiw	a5,a5,-1
    80002ba4:	4755                	li	a4,21
    80002ba6:	00f76f63          	bltu	a4,a5,80002bc4 <syscall+0x44>
    80002baa:	00369713          	slli	a4,a3,0x3
    80002bae:	00006797          	auipc	a5,0x6
    80002bb2:	8ca78793          	addi	a5,a5,-1846 # 80008478 <syscalls>
    80002bb6:	97ba                	add	a5,a5,a4
    80002bb8:	639c                	ld	a5,0(a5)
    80002bba:	c789                	beqz	a5,80002bc4 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002bbc:	9782                	jalr	a5
    80002bbe:	06a93823          	sd	a0,112(s2)
    80002bc2:	a839                	j	80002be0 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002bc4:	15848613          	addi	a2,s1,344
    80002bc8:	588c                	lw	a1,48(s1)
    80002bca:	00006517          	auipc	a0,0x6
    80002bce:	87650513          	addi	a0,a0,-1930 # 80008440 <states.0+0x150>
    80002bd2:	ffffe097          	auipc	ra,0xffffe
    80002bd6:	9b0080e7          	jalr	-1616(ra) # 80000582 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002bda:	6cbc                	ld	a5,88(s1)
    80002bdc:	577d                	li	a4,-1
    80002bde:	fbb8                	sd	a4,112(a5)
  }
}
    80002be0:	60e2                	ld	ra,24(sp)
    80002be2:	6442                	ld	s0,16(sp)
    80002be4:	64a2                	ld	s1,8(sp)
    80002be6:	6902                	ld	s2,0(sp)
    80002be8:	6105                	addi	sp,sp,32
    80002bea:	8082                	ret

0000000080002bec <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002bec:	1101                	addi	sp,sp,-32
    80002bee:	ec06                	sd	ra,24(sp)
    80002bf0:	e822                	sd	s0,16(sp)
    80002bf2:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002bf4:	fec40593          	addi	a1,s0,-20
    80002bf8:	4501                	li	a0,0
    80002bfa:	00000097          	auipc	ra,0x0
    80002bfe:	f12080e7          	jalr	-238(ra) # 80002b0c <argint>
    return -1;
    80002c02:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c04:	00054963          	bltz	a0,80002c16 <sys_exit+0x2a>
  exit(n);
    80002c08:	fec42503          	lw	a0,-20(s0)
    80002c0c:	fffff097          	auipc	ra,0xfffff
    80002c10:	6a6080e7          	jalr	1702(ra) # 800022b2 <exit>
  return 0;  // not reached
    80002c14:	4781                	li	a5,0
}
    80002c16:	853e                	mv	a0,a5
    80002c18:	60e2                	ld	ra,24(sp)
    80002c1a:	6442                	ld	s0,16(sp)
    80002c1c:	6105                	addi	sp,sp,32
    80002c1e:	8082                	ret

0000000080002c20 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c20:	1141                	addi	sp,sp,-16
    80002c22:	e406                	sd	ra,8(sp)
    80002c24:	e022                	sd	s0,0(sp)
    80002c26:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c28:	fffff097          	auipc	ra,0xfffff
    80002c2c:	d6e080e7          	jalr	-658(ra) # 80001996 <myproc>
}
    80002c30:	5908                	lw	a0,48(a0)
    80002c32:	60a2                	ld	ra,8(sp)
    80002c34:	6402                	ld	s0,0(sp)
    80002c36:	0141                	addi	sp,sp,16
    80002c38:	8082                	ret

0000000080002c3a <sys_fork>:

uint64
sys_fork(void)
{
    80002c3a:	1141                	addi	sp,sp,-16
    80002c3c:	e406                	sd	ra,8(sp)
    80002c3e:	e022                	sd	s0,0(sp)
    80002c40:	0800                	addi	s0,sp,16
  return fork();
    80002c42:	fffff097          	auipc	ra,0xfffff
    80002c46:	122080e7          	jalr	290(ra) # 80001d64 <fork>
}
    80002c4a:	60a2                	ld	ra,8(sp)
    80002c4c:	6402                	ld	s0,0(sp)
    80002c4e:	0141                	addi	sp,sp,16
    80002c50:	8082                	ret

0000000080002c52 <sys_wait>:

uint64
sys_wait(void)
{
    80002c52:	1101                	addi	sp,sp,-32
    80002c54:	ec06                	sd	ra,24(sp)
    80002c56:	e822                	sd	s0,16(sp)
    80002c58:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002c5a:	fe840593          	addi	a1,s0,-24
    80002c5e:	4501                	li	a0,0
    80002c60:	00000097          	auipc	ra,0x0
    80002c64:	ece080e7          	jalr	-306(ra) # 80002b2e <argaddr>
    80002c68:	87aa                	mv	a5,a0
    return -1;
    80002c6a:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002c6c:	0007c863          	bltz	a5,80002c7c <sys_wait+0x2a>
  return wait(p);
    80002c70:	fe843503          	ld	a0,-24(s0)
    80002c74:	fffff097          	auipc	ra,0xfffff
    80002c78:	446080e7          	jalr	1094(ra) # 800020ba <wait>
}
    80002c7c:	60e2                	ld	ra,24(sp)
    80002c7e:	6442                	ld	s0,16(sp)
    80002c80:	6105                	addi	sp,sp,32
    80002c82:	8082                	ret

0000000080002c84 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002c84:	7179                	addi	sp,sp,-48
    80002c86:	f406                	sd	ra,40(sp)
    80002c88:	f022                	sd	s0,32(sp)
    80002c8a:	ec26                	sd	s1,24(sp)
    80002c8c:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002c8e:	fdc40593          	addi	a1,s0,-36
    80002c92:	4501                	li	a0,0
    80002c94:	00000097          	auipc	ra,0x0
    80002c98:	e78080e7          	jalr	-392(ra) # 80002b0c <argint>
    return -1;
    80002c9c:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002c9e:	00054f63          	bltz	a0,80002cbc <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002ca2:	fffff097          	auipc	ra,0xfffff
    80002ca6:	cf4080e7          	jalr	-780(ra) # 80001996 <myproc>
    80002caa:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002cac:	fdc42503          	lw	a0,-36(s0)
    80002cb0:	fffff097          	auipc	ra,0xfffff
    80002cb4:	040080e7          	jalr	64(ra) # 80001cf0 <growproc>
    80002cb8:	00054863          	bltz	a0,80002cc8 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002cbc:	8526                	mv	a0,s1
    80002cbe:	70a2                	ld	ra,40(sp)
    80002cc0:	7402                	ld	s0,32(sp)
    80002cc2:	64e2                	ld	s1,24(sp)
    80002cc4:	6145                	addi	sp,sp,48
    80002cc6:	8082                	ret
    return -1;
    80002cc8:	54fd                	li	s1,-1
    80002cca:	bfcd                	j	80002cbc <sys_sbrk+0x38>

0000000080002ccc <sys_sleep>:

uint64
sys_sleep(void)
{
    80002ccc:	7139                	addi	sp,sp,-64
    80002cce:	fc06                	sd	ra,56(sp)
    80002cd0:	f822                	sd	s0,48(sp)
    80002cd2:	f426                	sd	s1,40(sp)
    80002cd4:	f04a                	sd	s2,32(sp)
    80002cd6:	ec4e                	sd	s3,24(sp)
    80002cd8:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002cda:	fcc40593          	addi	a1,s0,-52
    80002cde:	4501                	li	a0,0
    80002ce0:	00000097          	auipc	ra,0x0
    80002ce4:	e2c080e7          	jalr	-468(ra) # 80002b0c <argint>
    return -1;
    80002ce8:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002cea:	06054563          	bltz	a0,80002d54 <sys_sleep+0x88>
  acquire(&tickslock);
    80002cee:	00014517          	auipc	a0,0x14
    80002cf2:	3e250513          	addi	a0,a0,994 # 800170d0 <tickslock>
    80002cf6:	ffffe097          	auipc	ra,0xffffe
    80002cfa:	eda080e7          	jalr	-294(ra) # 80000bd0 <acquire>
  ticks0 = ticks;
    80002cfe:	00006917          	auipc	s2,0x6
    80002d02:	33292903          	lw	s2,818(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002d06:	fcc42783          	lw	a5,-52(s0)
    80002d0a:	cf85                	beqz	a5,80002d42 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d0c:	00014997          	auipc	s3,0x14
    80002d10:	3c498993          	addi	s3,s3,964 # 800170d0 <tickslock>
    80002d14:	00006497          	auipc	s1,0x6
    80002d18:	31c48493          	addi	s1,s1,796 # 80009030 <ticks>
    if(myproc()->killed){
    80002d1c:	fffff097          	auipc	ra,0xfffff
    80002d20:	c7a080e7          	jalr	-902(ra) # 80001996 <myproc>
    80002d24:	551c                	lw	a5,40(a0)
    80002d26:	ef9d                	bnez	a5,80002d64 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002d28:	85ce                	mv	a1,s3
    80002d2a:	8526                	mv	a0,s1
    80002d2c:	fffff097          	auipc	ra,0xfffff
    80002d30:	32a080e7          	jalr	810(ra) # 80002056 <sleep>
  while(ticks - ticks0 < n){
    80002d34:	409c                	lw	a5,0(s1)
    80002d36:	412787bb          	subw	a5,a5,s2
    80002d3a:	fcc42703          	lw	a4,-52(s0)
    80002d3e:	fce7efe3          	bltu	a5,a4,80002d1c <sys_sleep+0x50>
  }
  release(&tickslock);
    80002d42:	00014517          	auipc	a0,0x14
    80002d46:	38e50513          	addi	a0,a0,910 # 800170d0 <tickslock>
    80002d4a:	ffffe097          	auipc	ra,0xffffe
    80002d4e:	f3a080e7          	jalr	-198(ra) # 80000c84 <release>
  return 0;
    80002d52:	4781                	li	a5,0
}
    80002d54:	853e                	mv	a0,a5
    80002d56:	70e2                	ld	ra,56(sp)
    80002d58:	7442                	ld	s0,48(sp)
    80002d5a:	74a2                	ld	s1,40(sp)
    80002d5c:	7902                	ld	s2,32(sp)
    80002d5e:	69e2                	ld	s3,24(sp)
    80002d60:	6121                	addi	sp,sp,64
    80002d62:	8082                	ret
      release(&tickslock);
    80002d64:	00014517          	auipc	a0,0x14
    80002d68:	36c50513          	addi	a0,a0,876 # 800170d0 <tickslock>
    80002d6c:	ffffe097          	auipc	ra,0xffffe
    80002d70:	f18080e7          	jalr	-232(ra) # 80000c84 <release>
      return -1;
    80002d74:	57fd                	li	a5,-1
    80002d76:	bff9                	j	80002d54 <sys_sleep+0x88>

0000000080002d78 <sys_kill>:

uint64
sys_kill(void)
{
    80002d78:	1101                	addi	sp,sp,-32
    80002d7a:	ec06                	sd	ra,24(sp)
    80002d7c:	e822                	sd	s0,16(sp)
    80002d7e:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002d80:	fec40593          	addi	a1,s0,-20
    80002d84:	4501                	li	a0,0
    80002d86:	00000097          	auipc	ra,0x0
    80002d8a:	d86080e7          	jalr	-634(ra) # 80002b0c <argint>
    80002d8e:	87aa                	mv	a5,a0
    return -1;
    80002d90:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002d92:	0007c863          	bltz	a5,80002da2 <sys_kill+0x2a>
  return kill(pid);
    80002d96:	fec42503          	lw	a0,-20(s0)
    80002d9a:	fffff097          	auipc	ra,0xfffff
    80002d9e:	5ee080e7          	jalr	1518(ra) # 80002388 <kill>
}
    80002da2:	60e2                	ld	ra,24(sp)
    80002da4:	6442                	ld	s0,16(sp)
    80002da6:	6105                	addi	sp,sp,32
    80002da8:	8082                	ret

0000000080002daa <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002daa:	1101                	addi	sp,sp,-32
    80002dac:	ec06                	sd	ra,24(sp)
    80002dae:	e822                	sd	s0,16(sp)
    80002db0:	e426                	sd	s1,8(sp)
    80002db2:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002db4:	00014517          	auipc	a0,0x14
    80002db8:	31c50513          	addi	a0,a0,796 # 800170d0 <tickslock>
    80002dbc:	ffffe097          	auipc	ra,0xffffe
    80002dc0:	e14080e7          	jalr	-492(ra) # 80000bd0 <acquire>
  xticks = ticks;
    80002dc4:	00006497          	auipc	s1,0x6
    80002dc8:	26c4a483          	lw	s1,620(s1) # 80009030 <ticks>
  release(&tickslock);
    80002dcc:	00014517          	auipc	a0,0x14
    80002dd0:	30450513          	addi	a0,a0,772 # 800170d0 <tickslock>
    80002dd4:	ffffe097          	auipc	ra,0xffffe
    80002dd8:	eb0080e7          	jalr	-336(ra) # 80000c84 <release>
  return xticks;
}
    80002ddc:	02049513          	slli	a0,s1,0x20
    80002de0:	9101                	srli	a0,a0,0x20
    80002de2:	60e2                	ld	ra,24(sp)
    80002de4:	6442                	ld	s0,16(sp)
    80002de6:	64a2                	ld	s1,8(sp)
    80002de8:	6105                	addi	sp,sp,32
    80002dea:	8082                	ret

0000000080002dec <sys_pageAccess>:
// Aidan Darlington
// StudentID: 21134427
// Creating pageAccess function
int
sys_pageAccess(void)
{
    80002dec:	711d                	addi	sp,sp,-96
    80002dee:	ec86                	sd	ra,88(sp)
    80002df0:	e8a2                	sd	s0,80(sp)
    80002df2:	e4a6                	sd	s1,72(sp)
    80002df4:	e0ca                	sd	s2,64(sp)
    80002df6:	fc4e                	sd	s3,56(sp)
    80002df8:	f852                	sd	s4,48(sp)
    80002dfa:	f456                	sd	s5,40(sp)
    80002dfc:	f05a                	sd	s6,32(sp)
    80002dfe:	1080                	addi	s0,sp,96
    uint64 usrpage_ptr;  // First argument - pointer to user space address
    int npages;          // Second argument - the number of pages to examine
    uint64 usraddr;      // Third argument - pointer to the bitmap

    // Retrieve the arguments passed from the user program
    if (argaddr(0, &usrpage_ptr) < 0 || argint(1, &npages) < 0 || argaddr(2, &usraddr) < 0)
    80002e00:	fb840593          	addi	a1,s0,-72
    80002e04:	4501                	li	a0,0
    80002e06:	00000097          	auipc	ra,0x0
    80002e0a:	d28080e7          	jalr	-728(ra) # 80002b2e <argaddr>
    80002e0e:	0a054e63          	bltz	a0,80002eca <sys_pageAccess+0xde>
    80002e12:	fb440593          	addi	a1,s0,-76
    80002e16:	4505                	li	a0,1
    80002e18:	00000097          	auipc	ra,0x0
    80002e1c:	cf4080e7          	jalr	-780(ra) # 80002b0c <argint>
    80002e20:	0a054763          	bltz	a0,80002ece <sys_pageAccess+0xe2>
    80002e24:	fa840593          	addi	a1,s0,-88
    80002e28:	4509                	li	a0,2
    80002e2a:	00000097          	auipc	ra,0x0
    80002e2e:	d04080e7          	jalr	-764(ra) # 80002b2e <argaddr>
    80002e32:	0a054063          	bltz	a0,80002ed2 <sys_pageAccess+0xe6>
	return -1;

    // Validate the number of pages (npages cannot exceed 64)
    if (npages > 64)
    80002e36:	fb442703          	lw	a4,-76(s0)
    80002e3a:	04000793          	li	a5,64
    80002e3e:	08e7cc63          	blt	a5,a4,80002ed6 <sys_pageAccess+0xea>
	return -1;

    struct proc *p = myproc(); // Get current process
    80002e42:	fffff097          	auipc	ra,0xfffff
    80002e46:	b54080e7          	jalr	-1196(ra) # 80001996 <myproc>
    80002e4a:	89aa                	mv	s3,a0
    uint64 bitmap = 0; // Initialize the bitmap to 0
    80002e4c:	fa043023          	sd	zero,-96(s0)
    uint64 va_start = usrpage_ptr; // Start virtual address
    80002e50:	fb843903          	ld	s2,-72(s0)

    // Iterate through the pages and check if they have been accessed
    for (int i = 0; i < npages; i++) {
    80002e54:	fb442783          	lw	a5,-76(s0)
    80002e58:	04f05263          	blez	a5,80002e9c <sys_pageAccess+0xb0>
    80002e5c:	4481                	li	s1,0

	if (pa == 0) {
	    return -1; // Invalid page address
	}

	pte_t* pte = (pte_t*)(pa & ~0xFFF); // Get page table entry (PTE)
    80002e5e:	7afd                	lui	s5,0xfffff

	// Check if the page has been accessed
	if (*pte & (PTE_R | PTE_W)) {
	    bitmap |= (1 << i); // Set the corresponding bit in the bitmap
    80002e60:	4b05                	li	s6,1
    for (int i = 0; i < npages; i++) {
    80002e62:	6a05                	lui	s4,0x1
    80002e64:	a039                	j	80002e72 <sys_pageAccess+0x86>
    80002e66:	2485                	addiw	s1,s1,1
    80002e68:	9952                	add	s2,s2,s4
    80002e6a:	fb442783          	lw	a5,-76(s0)
    80002e6e:	02f4d763          	bge	s1,a5,80002e9c <sys_pageAccess+0xb0>
	uint64 pa = walkaddr(p->pagetable, page_addr); // Get the physical address
    80002e72:	85ca                	mv	a1,s2
    80002e74:	0509b503          	ld	a0,80(s3)
    80002e78:	ffffe097          	auipc	ra,0xffffe
    80002e7c:	1da080e7          	jalr	474(ra) # 80001052 <walkaddr>
	if (pa == 0) {
    80002e80:	cd29                	beqz	a0,80002eda <sys_pageAccess+0xee>
	pte_t* pte = (pte_t*)(pa & ~0xFFF); // Get page table entry (PTE)
    80002e82:	01557533          	and	a0,a0,s5
	if (*pte & (PTE_R | PTE_W)) {
    80002e86:	611c                	ld	a5,0(a0)
    80002e88:	8b99                	andi	a5,a5,6
    80002e8a:	dff1                	beqz	a5,80002e66 <sys_pageAccess+0x7a>
	    bitmap |= (1 << i); // Set the corresponding bit in the bitmap
    80002e8c:	009b17bb          	sllw	a5,s6,s1
    80002e90:	fa043703          	ld	a4,-96(s0)
    80002e94:	8fd9                	or	a5,a5,a4
    80002e96:	faf43023          	sd	a5,-96(s0)
    80002e9a:	b7f1                	j	80002e66 <sys_pageAccess+0x7a>
	}
    }

    // Copy the bitmap to user space before returning
    if (copyout(p->pagetable, usraddr, (char*)&bitmap, sizeof(bitmap)) < 0)
    80002e9c:	46a1                	li	a3,8
    80002e9e:	fa040613          	addi	a2,s0,-96
    80002ea2:	fa843583          	ld	a1,-88(s0)
    80002ea6:	0509b503          	ld	a0,80(s3)
    80002eaa:	ffffe097          	auipc	ra,0xffffe
    80002eae:	7ac080e7          	jalr	1964(ra) # 80001656 <copyout>
    80002eb2:	41f5551b          	sraiw	a0,a0,0x1f
	return -1;

    return 0; // Return success
}
    80002eb6:	60e6                	ld	ra,88(sp)
    80002eb8:	6446                	ld	s0,80(sp)
    80002eba:	64a6                	ld	s1,72(sp)
    80002ebc:	6906                	ld	s2,64(sp)
    80002ebe:	79e2                	ld	s3,56(sp)
    80002ec0:	7a42                	ld	s4,48(sp)
    80002ec2:	7aa2                	ld	s5,40(sp)
    80002ec4:	7b02                	ld	s6,32(sp)
    80002ec6:	6125                	addi	sp,sp,96
    80002ec8:	8082                	ret
	return -1;
    80002eca:	557d                	li	a0,-1
    80002ecc:	b7ed                	j	80002eb6 <sys_pageAccess+0xca>
    80002ece:	557d                	li	a0,-1
    80002ed0:	b7dd                	j	80002eb6 <sys_pageAccess+0xca>
    80002ed2:	557d                	li	a0,-1
    80002ed4:	b7cd                	j	80002eb6 <sys_pageAccess+0xca>
	return -1;
    80002ed6:	557d                	li	a0,-1
    80002ed8:	bff9                	j	80002eb6 <sys_pageAccess+0xca>
	    return -1; // Invalid page address
    80002eda:	557d                	li	a0,-1
    80002edc:	bfe9                	j	80002eb6 <sys_pageAccess+0xca>

0000000080002ede <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002ede:	7179                	addi	sp,sp,-48
    80002ee0:	f406                	sd	ra,40(sp)
    80002ee2:	f022                	sd	s0,32(sp)
    80002ee4:	ec26                	sd	s1,24(sp)
    80002ee6:	e84a                	sd	s2,16(sp)
    80002ee8:	e44e                	sd	s3,8(sp)
    80002eea:	e052                	sd	s4,0(sp)
    80002eec:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002eee:	00005597          	auipc	a1,0x5
    80002ef2:	64258593          	addi	a1,a1,1602 # 80008530 <syscalls+0xb8>
    80002ef6:	00014517          	auipc	a0,0x14
    80002efa:	1f250513          	addi	a0,a0,498 # 800170e8 <bcache>
    80002efe:	ffffe097          	auipc	ra,0xffffe
    80002f02:	c42080e7          	jalr	-958(ra) # 80000b40 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f06:	0001c797          	auipc	a5,0x1c
    80002f0a:	1e278793          	addi	a5,a5,482 # 8001f0e8 <bcache+0x8000>
    80002f0e:	0001c717          	auipc	a4,0x1c
    80002f12:	44270713          	addi	a4,a4,1090 # 8001f350 <bcache+0x8268>
    80002f16:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f1a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f1e:	00014497          	auipc	s1,0x14
    80002f22:	1e248493          	addi	s1,s1,482 # 80017100 <bcache+0x18>
    b->next = bcache.head.next;
    80002f26:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f28:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f2a:	00005a17          	auipc	s4,0x5
    80002f2e:	60ea0a13          	addi	s4,s4,1550 # 80008538 <syscalls+0xc0>
    b->next = bcache.head.next;
    80002f32:	2b893783          	ld	a5,696(s2)
    80002f36:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f38:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f3c:	85d2                	mv	a1,s4
    80002f3e:	01048513          	addi	a0,s1,16
    80002f42:	00001097          	auipc	ra,0x1
    80002f46:	4bc080e7          	jalr	1212(ra) # 800043fe <initsleeplock>
    bcache.head.next->prev = b;
    80002f4a:	2b893783          	ld	a5,696(s2)
    80002f4e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f50:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f54:	45848493          	addi	s1,s1,1112
    80002f58:	fd349de3          	bne	s1,s3,80002f32 <binit+0x54>
  }
}
    80002f5c:	70a2                	ld	ra,40(sp)
    80002f5e:	7402                	ld	s0,32(sp)
    80002f60:	64e2                	ld	s1,24(sp)
    80002f62:	6942                	ld	s2,16(sp)
    80002f64:	69a2                	ld	s3,8(sp)
    80002f66:	6a02                	ld	s4,0(sp)
    80002f68:	6145                	addi	sp,sp,48
    80002f6a:	8082                	ret

0000000080002f6c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f6c:	7179                	addi	sp,sp,-48
    80002f6e:	f406                	sd	ra,40(sp)
    80002f70:	f022                	sd	s0,32(sp)
    80002f72:	ec26                	sd	s1,24(sp)
    80002f74:	e84a                	sd	s2,16(sp)
    80002f76:	e44e                	sd	s3,8(sp)
    80002f78:	1800                	addi	s0,sp,48
    80002f7a:	892a                	mv	s2,a0
    80002f7c:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002f7e:	00014517          	auipc	a0,0x14
    80002f82:	16a50513          	addi	a0,a0,362 # 800170e8 <bcache>
    80002f86:	ffffe097          	auipc	ra,0xffffe
    80002f8a:	c4a080e7          	jalr	-950(ra) # 80000bd0 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f8e:	0001c497          	auipc	s1,0x1c
    80002f92:	4124b483          	ld	s1,1042(s1) # 8001f3a0 <bcache+0x82b8>
    80002f96:	0001c797          	auipc	a5,0x1c
    80002f9a:	3ba78793          	addi	a5,a5,954 # 8001f350 <bcache+0x8268>
    80002f9e:	02f48f63          	beq	s1,a5,80002fdc <bread+0x70>
    80002fa2:	873e                	mv	a4,a5
    80002fa4:	a021                	j	80002fac <bread+0x40>
    80002fa6:	68a4                	ld	s1,80(s1)
    80002fa8:	02e48a63          	beq	s1,a4,80002fdc <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002fac:	449c                	lw	a5,8(s1)
    80002fae:	ff279ce3          	bne	a5,s2,80002fa6 <bread+0x3a>
    80002fb2:	44dc                	lw	a5,12(s1)
    80002fb4:	ff3799e3          	bne	a5,s3,80002fa6 <bread+0x3a>
      b->refcnt++;
    80002fb8:	40bc                	lw	a5,64(s1)
    80002fba:	2785                	addiw	a5,a5,1
    80002fbc:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fbe:	00014517          	auipc	a0,0x14
    80002fc2:	12a50513          	addi	a0,a0,298 # 800170e8 <bcache>
    80002fc6:	ffffe097          	auipc	ra,0xffffe
    80002fca:	cbe080e7          	jalr	-834(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    80002fce:	01048513          	addi	a0,s1,16
    80002fd2:	00001097          	auipc	ra,0x1
    80002fd6:	466080e7          	jalr	1126(ra) # 80004438 <acquiresleep>
      return b;
    80002fda:	a8b9                	j	80003038 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fdc:	0001c497          	auipc	s1,0x1c
    80002fe0:	3bc4b483          	ld	s1,956(s1) # 8001f398 <bcache+0x82b0>
    80002fe4:	0001c797          	auipc	a5,0x1c
    80002fe8:	36c78793          	addi	a5,a5,876 # 8001f350 <bcache+0x8268>
    80002fec:	00f48863          	beq	s1,a5,80002ffc <bread+0x90>
    80002ff0:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002ff2:	40bc                	lw	a5,64(s1)
    80002ff4:	cf81                	beqz	a5,8000300c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002ff6:	64a4                	ld	s1,72(s1)
    80002ff8:	fee49de3          	bne	s1,a4,80002ff2 <bread+0x86>
  panic("bget: no buffers");
    80002ffc:	00005517          	auipc	a0,0x5
    80003000:	54450513          	addi	a0,a0,1348 # 80008540 <syscalls+0xc8>
    80003004:	ffffd097          	auipc	ra,0xffffd
    80003008:	534080e7          	jalr	1332(ra) # 80000538 <panic>
      b->dev = dev;
    8000300c:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003010:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003014:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003018:	4785                	li	a5,1
    8000301a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000301c:	00014517          	auipc	a0,0x14
    80003020:	0cc50513          	addi	a0,a0,204 # 800170e8 <bcache>
    80003024:	ffffe097          	auipc	ra,0xffffe
    80003028:	c60080e7          	jalr	-928(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    8000302c:	01048513          	addi	a0,s1,16
    80003030:	00001097          	auipc	ra,0x1
    80003034:	408080e7          	jalr	1032(ra) # 80004438 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003038:	409c                	lw	a5,0(s1)
    8000303a:	cb89                	beqz	a5,8000304c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000303c:	8526                	mv	a0,s1
    8000303e:	70a2                	ld	ra,40(sp)
    80003040:	7402                	ld	s0,32(sp)
    80003042:	64e2                	ld	s1,24(sp)
    80003044:	6942                	ld	s2,16(sp)
    80003046:	69a2                	ld	s3,8(sp)
    80003048:	6145                	addi	sp,sp,48
    8000304a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000304c:	4581                	li	a1,0
    8000304e:	8526                	mv	a0,s1
    80003050:	00003097          	auipc	ra,0x3
    80003054:	f16080e7          	jalr	-234(ra) # 80005f66 <virtio_disk_rw>
    b->valid = 1;
    80003058:	4785                	li	a5,1
    8000305a:	c09c                	sw	a5,0(s1)
  return b;
    8000305c:	b7c5                	j	8000303c <bread+0xd0>

000000008000305e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000305e:	1101                	addi	sp,sp,-32
    80003060:	ec06                	sd	ra,24(sp)
    80003062:	e822                	sd	s0,16(sp)
    80003064:	e426                	sd	s1,8(sp)
    80003066:	1000                	addi	s0,sp,32
    80003068:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000306a:	0541                	addi	a0,a0,16
    8000306c:	00001097          	auipc	ra,0x1
    80003070:	466080e7          	jalr	1126(ra) # 800044d2 <holdingsleep>
    80003074:	cd01                	beqz	a0,8000308c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003076:	4585                	li	a1,1
    80003078:	8526                	mv	a0,s1
    8000307a:	00003097          	auipc	ra,0x3
    8000307e:	eec080e7          	jalr	-276(ra) # 80005f66 <virtio_disk_rw>
}
    80003082:	60e2                	ld	ra,24(sp)
    80003084:	6442                	ld	s0,16(sp)
    80003086:	64a2                	ld	s1,8(sp)
    80003088:	6105                	addi	sp,sp,32
    8000308a:	8082                	ret
    panic("bwrite");
    8000308c:	00005517          	auipc	a0,0x5
    80003090:	4cc50513          	addi	a0,a0,1228 # 80008558 <syscalls+0xe0>
    80003094:	ffffd097          	auipc	ra,0xffffd
    80003098:	4a4080e7          	jalr	1188(ra) # 80000538 <panic>

000000008000309c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000309c:	1101                	addi	sp,sp,-32
    8000309e:	ec06                	sd	ra,24(sp)
    800030a0:	e822                	sd	s0,16(sp)
    800030a2:	e426                	sd	s1,8(sp)
    800030a4:	e04a                	sd	s2,0(sp)
    800030a6:	1000                	addi	s0,sp,32
    800030a8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030aa:	01050913          	addi	s2,a0,16
    800030ae:	854a                	mv	a0,s2
    800030b0:	00001097          	auipc	ra,0x1
    800030b4:	422080e7          	jalr	1058(ra) # 800044d2 <holdingsleep>
    800030b8:	c92d                	beqz	a0,8000312a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800030ba:	854a                	mv	a0,s2
    800030bc:	00001097          	auipc	ra,0x1
    800030c0:	3d2080e7          	jalr	978(ra) # 8000448e <releasesleep>

  acquire(&bcache.lock);
    800030c4:	00014517          	auipc	a0,0x14
    800030c8:	02450513          	addi	a0,a0,36 # 800170e8 <bcache>
    800030cc:	ffffe097          	auipc	ra,0xffffe
    800030d0:	b04080e7          	jalr	-1276(ra) # 80000bd0 <acquire>
  b->refcnt--;
    800030d4:	40bc                	lw	a5,64(s1)
    800030d6:	37fd                	addiw	a5,a5,-1
    800030d8:	0007871b          	sext.w	a4,a5
    800030dc:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800030de:	eb05                	bnez	a4,8000310e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800030e0:	68bc                	ld	a5,80(s1)
    800030e2:	64b8                	ld	a4,72(s1)
    800030e4:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800030e6:	64bc                	ld	a5,72(s1)
    800030e8:	68b8                	ld	a4,80(s1)
    800030ea:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800030ec:	0001c797          	auipc	a5,0x1c
    800030f0:	ffc78793          	addi	a5,a5,-4 # 8001f0e8 <bcache+0x8000>
    800030f4:	2b87b703          	ld	a4,696(a5)
    800030f8:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800030fa:	0001c717          	auipc	a4,0x1c
    800030fe:	25670713          	addi	a4,a4,598 # 8001f350 <bcache+0x8268>
    80003102:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003104:	2b87b703          	ld	a4,696(a5)
    80003108:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000310a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000310e:	00014517          	auipc	a0,0x14
    80003112:	fda50513          	addi	a0,a0,-38 # 800170e8 <bcache>
    80003116:	ffffe097          	auipc	ra,0xffffe
    8000311a:	b6e080e7          	jalr	-1170(ra) # 80000c84 <release>
}
    8000311e:	60e2                	ld	ra,24(sp)
    80003120:	6442                	ld	s0,16(sp)
    80003122:	64a2                	ld	s1,8(sp)
    80003124:	6902                	ld	s2,0(sp)
    80003126:	6105                	addi	sp,sp,32
    80003128:	8082                	ret
    panic("brelse");
    8000312a:	00005517          	auipc	a0,0x5
    8000312e:	43650513          	addi	a0,a0,1078 # 80008560 <syscalls+0xe8>
    80003132:	ffffd097          	auipc	ra,0xffffd
    80003136:	406080e7          	jalr	1030(ra) # 80000538 <panic>

000000008000313a <bpin>:

void
bpin(struct buf *b) {
    8000313a:	1101                	addi	sp,sp,-32
    8000313c:	ec06                	sd	ra,24(sp)
    8000313e:	e822                	sd	s0,16(sp)
    80003140:	e426                	sd	s1,8(sp)
    80003142:	1000                	addi	s0,sp,32
    80003144:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003146:	00014517          	auipc	a0,0x14
    8000314a:	fa250513          	addi	a0,a0,-94 # 800170e8 <bcache>
    8000314e:	ffffe097          	auipc	ra,0xffffe
    80003152:	a82080e7          	jalr	-1406(ra) # 80000bd0 <acquire>
  b->refcnt++;
    80003156:	40bc                	lw	a5,64(s1)
    80003158:	2785                	addiw	a5,a5,1
    8000315a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000315c:	00014517          	auipc	a0,0x14
    80003160:	f8c50513          	addi	a0,a0,-116 # 800170e8 <bcache>
    80003164:	ffffe097          	auipc	ra,0xffffe
    80003168:	b20080e7          	jalr	-1248(ra) # 80000c84 <release>
}
    8000316c:	60e2                	ld	ra,24(sp)
    8000316e:	6442                	ld	s0,16(sp)
    80003170:	64a2                	ld	s1,8(sp)
    80003172:	6105                	addi	sp,sp,32
    80003174:	8082                	ret

0000000080003176 <bunpin>:

void
bunpin(struct buf *b) {
    80003176:	1101                	addi	sp,sp,-32
    80003178:	ec06                	sd	ra,24(sp)
    8000317a:	e822                	sd	s0,16(sp)
    8000317c:	e426                	sd	s1,8(sp)
    8000317e:	1000                	addi	s0,sp,32
    80003180:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003182:	00014517          	auipc	a0,0x14
    80003186:	f6650513          	addi	a0,a0,-154 # 800170e8 <bcache>
    8000318a:	ffffe097          	auipc	ra,0xffffe
    8000318e:	a46080e7          	jalr	-1466(ra) # 80000bd0 <acquire>
  b->refcnt--;
    80003192:	40bc                	lw	a5,64(s1)
    80003194:	37fd                	addiw	a5,a5,-1
    80003196:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003198:	00014517          	auipc	a0,0x14
    8000319c:	f5050513          	addi	a0,a0,-176 # 800170e8 <bcache>
    800031a0:	ffffe097          	auipc	ra,0xffffe
    800031a4:	ae4080e7          	jalr	-1308(ra) # 80000c84 <release>
}
    800031a8:	60e2                	ld	ra,24(sp)
    800031aa:	6442                	ld	s0,16(sp)
    800031ac:	64a2                	ld	s1,8(sp)
    800031ae:	6105                	addi	sp,sp,32
    800031b0:	8082                	ret

00000000800031b2 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031b2:	1101                	addi	sp,sp,-32
    800031b4:	ec06                	sd	ra,24(sp)
    800031b6:	e822                	sd	s0,16(sp)
    800031b8:	e426                	sd	s1,8(sp)
    800031ba:	e04a                	sd	s2,0(sp)
    800031bc:	1000                	addi	s0,sp,32
    800031be:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031c0:	00d5d59b          	srliw	a1,a1,0xd
    800031c4:	0001c797          	auipc	a5,0x1c
    800031c8:	6007a783          	lw	a5,1536(a5) # 8001f7c4 <sb+0x1c>
    800031cc:	9dbd                	addw	a1,a1,a5
    800031ce:	00000097          	auipc	ra,0x0
    800031d2:	d9e080e7          	jalr	-610(ra) # 80002f6c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800031d6:	0074f713          	andi	a4,s1,7
    800031da:	4785                	li	a5,1
    800031dc:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800031e0:	14ce                	slli	s1,s1,0x33
    800031e2:	90d9                	srli	s1,s1,0x36
    800031e4:	00950733          	add	a4,a0,s1
    800031e8:	05874703          	lbu	a4,88(a4)
    800031ec:	00e7f6b3          	and	a3,a5,a4
    800031f0:	c69d                	beqz	a3,8000321e <bfree+0x6c>
    800031f2:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800031f4:	94aa                	add	s1,s1,a0
    800031f6:	fff7c793          	not	a5,a5
    800031fa:	8ff9                	and	a5,a5,a4
    800031fc:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003200:	00001097          	auipc	ra,0x1
    80003204:	118080e7          	jalr	280(ra) # 80004318 <log_write>
  brelse(bp);
    80003208:	854a                	mv	a0,s2
    8000320a:	00000097          	auipc	ra,0x0
    8000320e:	e92080e7          	jalr	-366(ra) # 8000309c <brelse>
}
    80003212:	60e2                	ld	ra,24(sp)
    80003214:	6442                	ld	s0,16(sp)
    80003216:	64a2                	ld	s1,8(sp)
    80003218:	6902                	ld	s2,0(sp)
    8000321a:	6105                	addi	sp,sp,32
    8000321c:	8082                	ret
    panic("freeing free block");
    8000321e:	00005517          	auipc	a0,0x5
    80003222:	34a50513          	addi	a0,a0,842 # 80008568 <syscalls+0xf0>
    80003226:	ffffd097          	auipc	ra,0xffffd
    8000322a:	312080e7          	jalr	786(ra) # 80000538 <panic>

000000008000322e <balloc>:
{
    8000322e:	711d                	addi	sp,sp,-96
    80003230:	ec86                	sd	ra,88(sp)
    80003232:	e8a2                	sd	s0,80(sp)
    80003234:	e4a6                	sd	s1,72(sp)
    80003236:	e0ca                	sd	s2,64(sp)
    80003238:	fc4e                	sd	s3,56(sp)
    8000323a:	f852                	sd	s4,48(sp)
    8000323c:	f456                	sd	s5,40(sp)
    8000323e:	f05a                	sd	s6,32(sp)
    80003240:	ec5e                	sd	s7,24(sp)
    80003242:	e862                	sd	s8,16(sp)
    80003244:	e466                	sd	s9,8(sp)
    80003246:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003248:	0001c797          	auipc	a5,0x1c
    8000324c:	5647a783          	lw	a5,1380(a5) # 8001f7ac <sb+0x4>
    80003250:	cbd1                	beqz	a5,800032e4 <balloc+0xb6>
    80003252:	8baa                	mv	s7,a0
    80003254:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003256:	0001cb17          	auipc	s6,0x1c
    8000325a:	552b0b13          	addi	s6,s6,1362 # 8001f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000325e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003260:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003262:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003264:	6c89                	lui	s9,0x2
    80003266:	a831                	j	80003282 <balloc+0x54>
    brelse(bp);
    80003268:	854a                	mv	a0,s2
    8000326a:	00000097          	auipc	ra,0x0
    8000326e:	e32080e7          	jalr	-462(ra) # 8000309c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003272:	015c87bb          	addw	a5,s9,s5
    80003276:	00078a9b          	sext.w	s5,a5
    8000327a:	004b2703          	lw	a4,4(s6)
    8000327e:	06eaf363          	bgeu	s5,a4,800032e4 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003282:	41fad79b          	sraiw	a5,s5,0x1f
    80003286:	0137d79b          	srliw	a5,a5,0x13
    8000328a:	015787bb          	addw	a5,a5,s5
    8000328e:	40d7d79b          	sraiw	a5,a5,0xd
    80003292:	01cb2583          	lw	a1,28(s6)
    80003296:	9dbd                	addw	a1,a1,a5
    80003298:	855e                	mv	a0,s7
    8000329a:	00000097          	auipc	ra,0x0
    8000329e:	cd2080e7          	jalr	-814(ra) # 80002f6c <bread>
    800032a2:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032a4:	004b2503          	lw	a0,4(s6)
    800032a8:	000a849b          	sext.w	s1,s5
    800032ac:	8662                	mv	a2,s8
    800032ae:	faa4fde3          	bgeu	s1,a0,80003268 <balloc+0x3a>
      m = 1 << (bi % 8);
    800032b2:	41f6579b          	sraiw	a5,a2,0x1f
    800032b6:	01d7d69b          	srliw	a3,a5,0x1d
    800032ba:	00c6873b          	addw	a4,a3,a2
    800032be:	00777793          	andi	a5,a4,7
    800032c2:	9f95                	subw	a5,a5,a3
    800032c4:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800032c8:	4037571b          	sraiw	a4,a4,0x3
    800032cc:	00e906b3          	add	a3,s2,a4
    800032d0:	0586c683          	lbu	a3,88(a3)
    800032d4:	00d7f5b3          	and	a1,a5,a3
    800032d8:	cd91                	beqz	a1,800032f4 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032da:	2605                	addiw	a2,a2,1
    800032dc:	2485                	addiw	s1,s1,1
    800032de:	fd4618e3          	bne	a2,s4,800032ae <balloc+0x80>
    800032e2:	b759                	j	80003268 <balloc+0x3a>
  panic("balloc: out of blocks");
    800032e4:	00005517          	auipc	a0,0x5
    800032e8:	29c50513          	addi	a0,a0,668 # 80008580 <syscalls+0x108>
    800032ec:	ffffd097          	auipc	ra,0xffffd
    800032f0:	24c080e7          	jalr	588(ra) # 80000538 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800032f4:	974a                	add	a4,a4,s2
    800032f6:	8fd5                	or	a5,a5,a3
    800032f8:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800032fc:	854a                	mv	a0,s2
    800032fe:	00001097          	auipc	ra,0x1
    80003302:	01a080e7          	jalr	26(ra) # 80004318 <log_write>
        brelse(bp);
    80003306:	854a                	mv	a0,s2
    80003308:	00000097          	auipc	ra,0x0
    8000330c:	d94080e7          	jalr	-620(ra) # 8000309c <brelse>
  bp = bread(dev, bno);
    80003310:	85a6                	mv	a1,s1
    80003312:	855e                	mv	a0,s7
    80003314:	00000097          	auipc	ra,0x0
    80003318:	c58080e7          	jalr	-936(ra) # 80002f6c <bread>
    8000331c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000331e:	40000613          	li	a2,1024
    80003322:	4581                	li	a1,0
    80003324:	05850513          	addi	a0,a0,88
    80003328:	ffffe097          	auipc	ra,0xffffe
    8000332c:	9a4080e7          	jalr	-1628(ra) # 80000ccc <memset>
  log_write(bp);
    80003330:	854a                	mv	a0,s2
    80003332:	00001097          	auipc	ra,0x1
    80003336:	fe6080e7          	jalr	-26(ra) # 80004318 <log_write>
  brelse(bp);
    8000333a:	854a                	mv	a0,s2
    8000333c:	00000097          	auipc	ra,0x0
    80003340:	d60080e7          	jalr	-672(ra) # 8000309c <brelse>
}
    80003344:	8526                	mv	a0,s1
    80003346:	60e6                	ld	ra,88(sp)
    80003348:	6446                	ld	s0,80(sp)
    8000334a:	64a6                	ld	s1,72(sp)
    8000334c:	6906                	ld	s2,64(sp)
    8000334e:	79e2                	ld	s3,56(sp)
    80003350:	7a42                	ld	s4,48(sp)
    80003352:	7aa2                	ld	s5,40(sp)
    80003354:	7b02                	ld	s6,32(sp)
    80003356:	6be2                	ld	s7,24(sp)
    80003358:	6c42                	ld	s8,16(sp)
    8000335a:	6ca2                	ld	s9,8(sp)
    8000335c:	6125                	addi	sp,sp,96
    8000335e:	8082                	ret

0000000080003360 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003360:	7179                	addi	sp,sp,-48
    80003362:	f406                	sd	ra,40(sp)
    80003364:	f022                	sd	s0,32(sp)
    80003366:	ec26                	sd	s1,24(sp)
    80003368:	e84a                	sd	s2,16(sp)
    8000336a:	e44e                	sd	s3,8(sp)
    8000336c:	e052                	sd	s4,0(sp)
    8000336e:	1800                	addi	s0,sp,48
    80003370:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003372:	47ad                	li	a5,11
    80003374:	04b7fe63          	bgeu	a5,a1,800033d0 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003378:	ff45849b          	addiw	s1,a1,-12
    8000337c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003380:	0ff00793          	li	a5,255
    80003384:	0ae7e363          	bltu	a5,a4,8000342a <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003388:	08052583          	lw	a1,128(a0)
    8000338c:	c5ad                	beqz	a1,800033f6 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000338e:	00092503          	lw	a0,0(s2)
    80003392:	00000097          	auipc	ra,0x0
    80003396:	bda080e7          	jalr	-1062(ra) # 80002f6c <bread>
    8000339a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000339c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033a0:	02049593          	slli	a1,s1,0x20
    800033a4:	9181                	srli	a1,a1,0x20
    800033a6:	058a                	slli	a1,a1,0x2
    800033a8:	00b784b3          	add	s1,a5,a1
    800033ac:	0004a983          	lw	s3,0(s1)
    800033b0:	04098d63          	beqz	s3,8000340a <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800033b4:	8552                	mv	a0,s4
    800033b6:	00000097          	auipc	ra,0x0
    800033ba:	ce6080e7          	jalr	-794(ra) # 8000309c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800033be:	854e                	mv	a0,s3
    800033c0:	70a2                	ld	ra,40(sp)
    800033c2:	7402                	ld	s0,32(sp)
    800033c4:	64e2                	ld	s1,24(sp)
    800033c6:	6942                	ld	s2,16(sp)
    800033c8:	69a2                	ld	s3,8(sp)
    800033ca:	6a02                	ld	s4,0(sp)
    800033cc:	6145                	addi	sp,sp,48
    800033ce:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800033d0:	02059493          	slli	s1,a1,0x20
    800033d4:	9081                	srli	s1,s1,0x20
    800033d6:	048a                	slli	s1,s1,0x2
    800033d8:	94aa                	add	s1,s1,a0
    800033da:	0504a983          	lw	s3,80(s1)
    800033de:	fe0990e3          	bnez	s3,800033be <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800033e2:	4108                	lw	a0,0(a0)
    800033e4:	00000097          	auipc	ra,0x0
    800033e8:	e4a080e7          	jalr	-438(ra) # 8000322e <balloc>
    800033ec:	0005099b          	sext.w	s3,a0
    800033f0:	0534a823          	sw	s3,80(s1)
    800033f4:	b7e9                	j	800033be <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800033f6:	4108                	lw	a0,0(a0)
    800033f8:	00000097          	auipc	ra,0x0
    800033fc:	e36080e7          	jalr	-458(ra) # 8000322e <balloc>
    80003400:	0005059b          	sext.w	a1,a0
    80003404:	08b92023          	sw	a1,128(s2)
    80003408:	b759                	j	8000338e <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000340a:	00092503          	lw	a0,0(s2)
    8000340e:	00000097          	auipc	ra,0x0
    80003412:	e20080e7          	jalr	-480(ra) # 8000322e <balloc>
    80003416:	0005099b          	sext.w	s3,a0
    8000341a:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000341e:	8552                	mv	a0,s4
    80003420:	00001097          	auipc	ra,0x1
    80003424:	ef8080e7          	jalr	-264(ra) # 80004318 <log_write>
    80003428:	b771                	j	800033b4 <bmap+0x54>
  panic("bmap: out of range");
    8000342a:	00005517          	auipc	a0,0x5
    8000342e:	16e50513          	addi	a0,a0,366 # 80008598 <syscalls+0x120>
    80003432:	ffffd097          	auipc	ra,0xffffd
    80003436:	106080e7          	jalr	262(ra) # 80000538 <panic>

000000008000343a <iget>:
{
    8000343a:	7179                	addi	sp,sp,-48
    8000343c:	f406                	sd	ra,40(sp)
    8000343e:	f022                	sd	s0,32(sp)
    80003440:	ec26                	sd	s1,24(sp)
    80003442:	e84a                	sd	s2,16(sp)
    80003444:	e44e                	sd	s3,8(sp)
    80003446:	e052                	sd	s4,0(sp)
    80003448:	1800                	addi	s0,sp,48
    8000344a:	89aa                	mv	s3,a0
    8000344c:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000344e:	0001c517          	auipc	a0,0x1c
    80003452:	37a50513          	addi	a0,a0,890 # 8001f7c8 <itable>
    80003456:	ffffd097          	auipc	ra,0xffffd
    8000345a:	77a080e7          	jalr	1914(ra) # 80000bd0 <acquire>
  empty = 0;
    8000345e:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003460:	0001c497          	auipc	s1,0x1c
    80003464:	38048493          	addi	s1,s1,896 # 8001f7e0 <itable+0x18>
    80003468:	0001e697          	auipc	a3,0x1e
    8000346c:	e0868693          	addi	a3,a3,-504 # 80021270 <log>
    80003470:	a039                	j	8000347e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003472:	02090b63          	beqz	s2,800034a8 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003476:	08848493          	addi	s1,s1,136
    8000347a:	02d48a63          	beq	s1,a3,800034ae <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000347e:	449c                	lw	a5,8(s1)
    80003480:	fef059e3          	blez	a5,80003472 <iget+0x38>
    80003484:	4098                	lw	a4,0(s1)
    80003486:	ff3716e3          	bne	a4,s3,80003472 <iget+0x38>
    8000348a:	40d8                	lw	a4,4(s1)
    8000348c:	ff4713e3          	bne	a4,s4,80003472 <iget+0x38>
      ip->ref++;
    80003490:	2785                	addiw	a5,a5,1
    80003492:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003494:	0001c517          	auipc	a0,0x1c
    80003498:	33450513          	addi	a0,a0,820 # 8001f7c8 <itable>
    8000349c:	ffffd097          	auipc	ra,0xffffd
    800034a0:	7e8080e7          	jalr	2024(ra) # 80000c84 <release>
      return ip;
    800034a4:	8926                	mv	s2,s1
    800034a6:	a03d                	j	800034d4 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034a8:	f7f9                	bnez	a5,80003476 <iget+0x3c>
    800034aa:	8926                	mv	s2,s1
    800034ac:	b7e9                	j	80003476 <iget+0x3c>
  if(empty == 0)
    800034ae:	02090c63          	beqz	s2,800034e6 <iget+0xac>
  ip->dev = dev;
    800034b2:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800034b6:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800034ba:	4785                	li	a5,1
    800034bc:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800034c0:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800034c4:	0001c517          	auipc	a0,0x1c
    800034c8:	30450513          	addi	a0,a0,772 # 8001f7c8 <itable>
    800034cc:	ffffd097          	auipc	ra,0xffffd
    800034d0:	7b8080e7          	jalr	1976(ra) # 80000c84 <release>
}
    800034d4:	854a                	mv	a0,s2
    800034d6:	70a2                	ld	ra,40(sp)
    800034d8:	7402                	ld	s0,32(sp)
    800034da:	64e2                	ld	s1,24(sp)
    800034dc:	6942                	ld	s2,16(sp)
    800034de:	69a2                	ld	s3,8(sp)
    800034e0:	6a02                	ld	s4,0(sp)
    800034e2:	6145                	addi	sp,sp,48
    800034e4:	8082                	ret
    panic("iget: no inodes");
    800034e6:	00005517          	auipc	a0,0x5
    800034ea:	0ca50513          	addi	a0,a0,202 # 800085b0 <syscalls+0x138>
    800034ee:	ffffd097          	auipc	ra,0xffffd
    800034f2:	04a080e7          	jalr	74(ra) # 80000538 <panic>

00000000800034f6 <fsinit>:
fsinit(int dev) {
    800034f6:	7179                	addi	sp,sp,-48
    800034f8:	f406                	sd	ra,40(sp)
    800034fa:	f022                	sd	s0,32(sp)
    800034fc:	ec26                	sd	s1,24(sp)
    800034fe:	e84a                	sd	s2,16(sp)
    80003500:	e44e                	sd	s3,8(sp)
    80003502:	1800                	addi	s0,sp,48
    80003504:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003506:	4585                	li	a1,1
    80003508:	00000097          	auipc	ra,0x0
    8000350c:	a64080e7          	jalr	-1436(ra) # 80002f6c <bread>
    80003510:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003512:	0001c997          	auipc	s3,0x1c
    80003516:	29698993          	addi	s3,s3,662 # 8001f7a8 <sb>
    8000351a:	02000613          	li	a2,32
    8000351e:	05850593          	addi	a1,a0,88
    80003522:	854e                	mv	a0,s3
    80003524:	ffffe097          	auipc	ra,0xffffe
    80003528:	804080e7          	jalr	-2044(ra) # 80000d28 <memmove>
  brelse(bp);
    8000352c:	8526                	mv	a0,s1
    8000352e:	00000097          	auipc	ra,0x0
    80003532:	b6e080e7          	jalr	-1170(ra) # 8000309c <brelse>
  if(sb.magic != FSMAGIC)
    80003536:	0009a703          	lw	a4,0(s3)
    8000353a:	102037b7          	lui	a5,0x10203
    8000353e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003542:	02f71263          	bne	a4,a5,80003566 <fsinit+0x70>
  initlog(dev, &sb);
    80003546:	0001c597          	auipc	a1,0x1c
    8000354a:	26258593          	addi	a1,a1,610 # 8001f7a8 <sb>
    8000354e:	854a                	mv	a0,s2
    80003550:	00001097          	auipc	ra,0x1
    80003554:	b4c080e7          	jalr	-1204(ra) # 8000409c <initlog>
}
    80003558:	70a2                	ld	ra,40(sp)
    8000355a:	7402                	ld	s0,32(sp)
    8000355c:	64e2                	ld	s1,24(sp)
    8000355e:	6942                	ld	s2,16(sp)
    80003560:	69a2                	ld	s3,8(sp)
    80003562:	6145                	addi	sp,sp,48
    80003564:	8082                	ret
    panic("invalid file system");
    80003566:	00005517          	auipc	a0,0x5
    8000356a:	05a50513          	addi	a0,a0,90 # 800085c0 <syscalls+0x148>
    8000356e:	ffffd097          	auipc	ra,0xffffd
    80003572:	fca080e7          	jalr	-54(ra) # 80000538 <panic>

0000000080003576 <iinit>:
{
    80003576:	7179                	addi	sp,sp,-48
    80003578:	f406                	sd	ra,40(sp)
    8000357a:	f022                	sd	s0,32(sp)
    8000357c:	ec26                	sd	s1,24(sp)
    8000357e:	e84a                	sd	s2,16(sp)
    80003580:	e44e                	sd	s3,8(sp)
    80003582:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003584:	00005597          	auipc	a1,0x5
    80003588:	05458593          	addi	a1,a1,84 # 800085d8 <syscalls+0x160>
    8000358c:	0001c517          	auipc	a0,0x1c
    80003590:	23c50513          	addi	a0,a0,572 # 8001f7c8 <itable>
    80003594:	ffffd097          	auipc	ra,0xffffd
    80003598:	5ac080e7          	jalr	1452(ra) # 80000b40 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000359c:	0001c497          	auipc	s1,0x1c
    800035a0:	25448493          	addi	s1,s1,596 # 8001f7f0 <itable+0x28>
    800035a4:	0001e997          	auipc	s3,0x1e
    800035a8:	cdc98993          	addi	s3,s3,-804 # 80021280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800035ac:	00005917          	auipc	s2,0x5
    800035b0:	03490913          	addi	s2,s2,52 # 800085e0 <syscalls+0x168>
    800035b4:	85ca                	mv	a1,s2
    800035b6:	8526                	mv	a0,s1
    800035b8:	00001097          	auipc	ra,0x1
    800035bc:	e46080e7          	jalr	-442(ra) # 800043fe <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800035c0:	08848493          	addi	s1,s1,136
    800035c4:	ff3498e3          	bne	s1,s3,800035b4 <iinit+0x3e>
}
    800035c8:	70a2                	ld	ra,40(sp)
    800035ca:	7402                	ld	s0,32(sp)
    800035cc:	64e2                	ld	s1,24(sp)
    800035ce:	6942                	ld	s2,16(sp)
    800035d0:	69a2                	ld	s3,8(sp)
    800035d2:	6145                	addi	sp,sp,48
    800035d4:	8082                	ret

00000000800035d6 <ialloc>:
{
    800035d6:	715d                	addi	sp,sp,-80
    800035d8:	e486                	sd	ra,72(sp)
    800035da:	e0a2                	sd	s0,64(sp)
    800035dc:	fc26                	sd	s1,56(sp)
    800035de:	f84a                	sd	s2,48(sp)
    800035e0:	f44e                	sd	s3,40(sp)
    800035e2:	f052                	sd	s4,32(sp)
    800035e4:	ec56                	sd	s5,24(sp)
    800035e6:	e85a                	sd	s6,16(sp)
    800035e8:	e45e                	sd	s7,8(sp)
    800035ea:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800035ec:	0001c717          	auipc	a4,0x1c
    800035f0:	1c872703          	lw	a4,456(a4) # 8001f7b4 <sb+0xc>
    800035f4:	4785                	li	a5,1
    800035f6:	04e7fa63          	bgeu	a5,a4,8000364a <ialloc+0x74>
    800035fa:	8aaa                	mv	s5,a0
    800035fc:	8bae                	mv	s7,a1
    800035fe:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003600:	0001ca17          	auipc	s4,0x1c
    80003604:	1a8a0a13          	addi	s4,s4,424 # 8001f7a8 <sb>
    80003608:	00048b1b          	sext.w	s6,s1
    8000360c:	0044d793          	srli	a5,s1,0x4
    80003610:	018a2583          	lw	a1,24(s4)
    80003614:	9dbd                	addw	a1,a1,a5
    80003616:	8556                	mv	a0,s5
    80003618:	00000097          	auipc	ra,0x0
    8000361c:	954080e7          	jalr	-1708(ra) # 80002f6c <bread>
    80003620:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003622:	05850993          	addi	s3,a0,88
    80003626:	00f4f793          	andi	a5,s1,15
    8000362a:	079a                	slli	a5,a5,0x6
    8000362c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000362e:	00099783          	lh	a5,0(s3)
    80003632:	c785                	beqz	a5,8000365a <ialloc+0x84>
    brelse(bp);
    80003634:	00000097          	auipc	ra,0x0
    80003638:	a68080e7          	jalr	-1432(ra) # 8000309c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000363c:	0485                	addi	s1,s1,1
    8000363e:	00ca2703          	lw	a4,12(s4)
    80003642:	0004879b          	sext.w	a5,s1
    80003646:	fce7e1e3          	bltu	a5,a4,80003608 <ialloc+0x32>
  panic("ialloc: no inodes");
    8000364a:	00005517          	auipc	a0,0x5
    8000364e:	f9e50513          	addi	a0,a0,-98 # 800085e8 <syscalls+0x170>
    80003652:	ffffd097          	auipc	ra,0xffffd
    80003656:	ee6080e7          	jalr	-282(ra) # 80000538 <panic>
      memset(dip, 0, sizeof(*dip));
    8000365a:	04000613          	li	a2,64
    8000365e:	4581                	li	a1,0
    80003660:	854e                	mv	a0,s3
    80003662:	ffffd097          	auipc	ra,0xffffd
    80003666:	66a080e7          	jalr	1642(ra) # 80000ccc <memset>
      dip->type = type;
    8000366a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000366e:	854a                	mv	a0,s2
    80003670:	00001097          	auipc	ra,0x1
    80003674:	ca8080e7          	jalr	-856(ra) # 80004318 <log_write>
      brelse(bp);
    80003678:	854a                	mv	a0,s2
    8000367a:	00000097          	auipc	ra,0x0
    8000367e:	a22080e7          	jalr	-1502(ra) # 8000309c <brelse>
      return iget(dev, inum);
    80003682:	85da                	mv	a1,s6
    80003684:	8556                	mv	a0,s5
    80003686:	00000097          	auipc	ra,0x0
    8000368a:	db4080e7          	jalr	-588(ra) # 8000343a <iget>
}
    8000368e:	60a6                	ld	ra,72(sp)
    80003690:	6406                	ld	s0,64(sp)
    80003692:	74e2                	ld	s1,56(sp)
    80003694:	7942                	ld	s2,48(sp)
    80003696:	79a2                	ld	s3,40(sp)
    80003698:	7a02                	ld	s4,32(sp)
    8000369a:	6ae2                	ld	s5,24(sp)
    8000369c:	6b42                	ld	s6,16(sp)
    8000369e:	6ba2                	ld	s7,8(sp)
    800036a0:	6161                	addi	sp,sp,80
    800036a2:	8082                	ret

00000000800036a4 <iupdate>:
{
    800036a4:	1101                	addi	sp,sp,-32
    800036a6:	ec06                	sd	ra,24(sp)
    800036a8:	e822                	sd	s0,16(sp)
    800036aa:	e426                	sd	s1,8(sp)
    800036ac:	e04a                	sd	s2,0(sp)
    800036ae:	1000                	addi	s0,sp,32
    800036b0:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036b2:	415c                	lw	a5,4(a0)
    800036b4:	0047d79b          	srliw	a5,a5,0x4
    800036b8:	0001c597          	auipc	a1,0x1c
    800036bc:	1085a583          	lw	a1,264(a1) # 8001f7c0 <sb+0x18>
    800036c0:	9dbd                	addw	a1,a1,a5
    800036c2:	4108                	lw	a0,0(a0)
    800036c4:	00000097          	auipc	ra,0x0
    800036c8:	8a8080e7          	jalr	-1880(ra) # 80002f6c <bread>
    800036cc:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036ce:	05850793          	addi	a5,a0,88
    800036d2:	40c8                	lw	a0,4(s1)
    800036d4:	893d                	andi	a0,a0,15
    800036d6:	051a                	slli	a0,a0,0x6
    800036d8:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800036da:	04449703          	lh	a4,68(s1)
    800036de:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800036e2:	04649703          	lh	a4,70(s1)
    800036e6:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800036ea:	04849703          	lh	a4,72(s1)
    800036ee:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800036f2:	04a49703          	lh	a4,74(s1)
    800036f6:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800036fa:	44f8                	lw	a4,76(s1)
    800036fc:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800036fe:	03400613          	li	a2,52
    80003702:	05048593          	addi	a1,s1,80
    80003706:	0531                	addi	a0,a0,12
    80003708:	ffffd097          	auipc	ra,0xffffd
    8000370c:	620080e7          	jalr	1568(ra) # 80000d28 <memmove>
  log_write(bp);
    80003710:	854a                	mv	a0,s2
    80003712:	00001097          	auipc	ra,0x1
    80003716:	c06080e7          	jalr	-1018(ra) # 80004318 <log_write>
  brelse(bp);
    8000371a:	854a                	mv	a0,s2
    8000371c:	00000097          	auipc	ra,0x0
    80003720:	980080e7          	jalr	-1664(ra) # 8000309c <brelse>
}
    80003724:	60e2                	ld	ra,24(sp)
    80003726:	6442                	ld	s0,16(sp)
    80003728:	64a2                	ld	s1,8(sp)
    8000372a:	6902                	ld	s2,0(sp)
    8000372c:	6105                	addi	sp,sp,32
    8000372e:	8082                	ret

0000000080003730 <idup>:
{
    80003730:	1101                	addi	sp,sp,-32
    80003732:	ec06                	sd	ra,24(sp)
    80003734:	e822                	sd	s0,16(sp)
    80003736:	e426                	sd	s1,8(sp)
    80003738:	1000                	addi	s0,sp,32
    8000373a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000373c:	0001c517          	auipc	a0,0x1c
    80003740:	08c50513          	addi	a0,a0,140 # 8001f7c8 <itable>
    80003744:	ffffd097          	auipc	ra,0xffffd
    80003748:	48c080e7          	jalr	1164(ra) # 80000bd0 <acquire>
  ip->ref++;
    8000374c:	449c                	lw	a5,8(s1)
    8000374e:	2785                	addiw	a5,a5,1
    80003750:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003752:	0001c517          	auipc	a0,0x1c
    80003756:	07650513          	addi	a0,a0,118 # 8001f7c8 <itable>
    8000375a:	ffffd097          	auipc	ra,0xffffd
    8000375e:	52a080e7          	jalr	1322(ra) # 80000c84 <release>
}
    80003762:	8526                	mv	a0,s1
    80003764:	60e2                	ld	ra,24(sp)
    80003766:	6442                	ld	s0,16(sp)
    80003768:	64a2                	ld	s1,8(sp)
    8000376a:	6105                	addi	sp,sp,32
    8000376c:	8082                	ret

000000008000376e <ilock>:
{
    8000376e:	1101                	addi	sp,sp,-32
    80003770:	ec06                	sd	ra,24(sp)
    80003772:	e822                	sd	s0,16(sp)
    80003774:	e426                	sd	s1,8(sp)
    80003776:	e04a                	sd	s2,0(sp)
    80003778:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000377a:	c115                	beqz	a0,8000379e <ilock+0x30>
    8000377c:	84aa                	mv	s1,a0
    8000377e:	451c                	lw	a5,8(a0)
    80003780:	00f05f63          	blez	a5,8000379e <ilock+0x30>
  acquiresleep(&ip->lock);
    80003784:	0541                	addi	a0,a0,16
    80003786:	00001097          	auipc	ra,0x1
    8000378a:	cb2080e7          	jalr	-846(ra) # 80004438 <acquiresleep>
  if(ip->valid == 0){
    8000378e:	40bc                	lw	a5,64(s1)
    80003790:	cf99                	beqz	a5,800037ae <ilock+0x40>
}
    80003792:	60e2                	ld	ra,24(sp)
    80003794:	6442                	ld	s0,16(sp)
    80003796:	64a2                	ld	s1,8(sp)
    80003798:	6902                	ld	s2,0(sp)
    8000379a:	6105                	addi	sp,sp,32
    8000379c:	8082                	ret
    panic("ilock");
    8000379e:	00005517          	auipc	a0,0x5
    800037a2:	e6250513          	addi	a0,a0,-414 # 80008600 <syscalls+0x188>
    800037a6:	ffffd097          	auipc	ra,0xffffd
    800037aa:	d92080e7          	jalr	-622(ra) # 80000538 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037ae:	40dc                	lw	a5,4(s1)
    800037b0:	0047d79b          	srliw	a5,a5,0x4
    800037b4:	0001c597          	auipc	a1,0x1c
    800037b8:	00c5a583          	lw	a1,12(a1) # 8001f7c0 <sb+0x18>
    800037bc:	9dbd                	addw	a1,a1,a5
    800037be:	4088                	lw	a0,0(s1)
    800037c0:	fffff097          	auipc	ra,0xfffff
    800037c4:	7ac080e7          	jalr	1964(ra) # 80002f6c <bread>
    800037c8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037ca:	05850593          	addi	a1,a0,88
    800037ce:	40dc                	lw	a5,4(s1)
    800037d0:	8bbd                	andi	a5,a5,15
    800037d2:	079a                	slli	a5,a5,0x6
    800037d4:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800037d6:	00059783          	lh	a5,0(a1)
    800037da:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800037de:	00259783          	lh	a5,2(a1)
    800037e2:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800037e6:	00459783          	lh	a5,4(a1)
    800037ea:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800037ee:	00659783          	lh	a5,6(a1)
    800037f2:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800037f6:	459c                	lw	a5,8(a1)
    800037f8:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800037fa:	03400613          	li	a2,52
    800037fe:	05b1                	addi	a1,a1,12
    80003800:	05048513          	addi	a0,s1,80
    80003804:	ffffd097          	auipc	ra,0xffffd
    80003808:	524080e7          	jalr	1316(ra) # 80000d28 <memmove>
    brelse(bp);
    8000380c:	854a                	mv	a0,s2
    8000380e:	00000097          	auipc	ra,0x0
    80003812:	88e080e7          	jalr	-1906(ra) # 8000309c <brelse>
    ip->valid = 1;
    80003816:	4785                	li	a5,1
    80003818:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000381a:	04449783          	lh	a5,68(s1)
    8000381e:	fbb5                	bnez	a5,80003792 <ilock+0x24>
      panic("ilock: no type");
    80003820:	00005517          	auipc	a0,0x5
    80003824:	de850513          	addi	a0,a0,-536 # 80008608 <syscalls+0x190>
    80003828:	ffffd097          	auipc	ra,0xffffd
    8000382c:	d10080e7          	jalr	-752(ra) # 80000538 <panic>

0000000080003830 <iunlock>:
{
    80003830:	1101                	addi	sp,sp,-32
    80003832:	ec06                	sd	ra,24(sp)
    80003834:	e822                	sd	s0,16(sp)
    80003836:	e426                	sd	s1,8(sp)
    80003838:	e04a                	sd	s2,0(sp)
    8000383a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000383c:	c905                	beqz	a0,8000386c <iunlock+0x3c>
    8000383e:	84aa                	mv	s1,a0
    80003840:	01050913          	addi	s2,a0,16
    80003844:	854a                	mv	a0,s2
    80003846:	00001097          	auipc	ra,0x1
    8000384a:	c8c080e7          	jalr	-884(ra) # 800044d2 <holdingsleep>
    8000384e:	cd19                	beqz	a0,8000386c <iunlock+0x3c>
    80003850:	449c                	lw	a5,8(s1)
    80003852:	00f05d63          	blez	a5,8000386c <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003856:	854a                	mv	a0,s2
    80003858:	00001097          	auipc	ra,0x1
    8000385c:	c36080e7          	jalr	-970(ra) # 8000448e <releasesleep>
}
    80003860:	60e2                	ld	ra,24(sp)
    80003862:	6442                	ld	s0,16(sp)
    80003864:	64a2                	ld	s1,8(sp)
    80003866:	6902                	ld	s2,0(sp)
    80003868:	6105                	addi	sp,sp,32
    8000386a:	8082                	ret
    panic("iunlock");
    8000386c:	00005517          	auipc	a0,0x5
    80003870:	dac50513          	addi	a0,a0,-596 # 80008618 <syscalls+0x1a0>
    80003874:	ffffd097          	auipc	ra,0xffffd
    80003878:	cc4080e7          	jalr	-828(ra) # 80000538 <panic>

000000008000387c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000387c:	7179                	addi	sp,sp,-48
    8000387e:	f406                	sd	ra,40(sp)
    80003880:	f022                	sd	s0,32(sp)
    80003882:	ec26                	sd	s1,24(sp)
    80003884:	e84a                	sd	s2,16(sp)
    80003886:	e44e                	sd	s3,8(sp)
    80003888:	e052                	sd	s4,0(sp)
    8000388a:	1800                	addi	s0,sp,48
    8000388c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000388e:	05050493          	addi	s1,a0,80
    80003892:	08050913          	addi	s2,a0,128
    80003896:	a021                	j	8000389e <itrunc+0x22>
    80003898:	0491                	addi	s1,s1,4
    8000389a:	01248d63          	beq	s1,s2,800038b4 <itrunc+0x38>
    if(ip->addrs[i]){
    8000389e:	408c                	lw	a1,0(s1)
    800038a0:	dde5                	beqz	a1,80003898 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800038a2:	0009a503          	lw	a0,0(s3)
    800038a6:	00000097          	auipc	ra,0x0
    800038aa:	90c080e7          	jalr	-1780(ra) # 800031b2 <bfree>
      ip->addrs[i] = 0;
    800038ae:	0004a023          	sw	zero,0(s1)
    800038b2:	b7dd                	j	80003898 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038b4:	0809a583          	lw	a1,128(s3)
    800038b8:	e185                	bnez	a1,800038d8 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800038ba:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800038be:	854e                	mv	a0,s3
    800038c0:	00000097          	auipc	ra,0x0
    800038c4:	de4080e7          	jalr	-540(ra) # 800036a4 <iupdate>
}
    800038c8:	70a2                	ld	ra,40(sp)
    800038ca:	7402                	ld	s0,32(sp)
    800038cc:	64e2                	ld	s1,24(sp)
    800038ce:	6942                	ld	s2,16(sp)
    800038d0:	69a2                	ld	s3,8(sp)
    800038d2:	6a02                	ld	s4,0(sp)
    800038d4:	6145                	addi	sp,sp,48
    800038d6:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800038d8:	0009a503          	lw	a0,0(s3)
    800038dc:	fffff097          	auipc	ra,0xfffff
    800038e0:	690080e7          	jalr	1680(ra) # 80002f6c <bread>
    800038e4:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800038e6:	05850493          	addi	s1,a0,88
    800038ea:	45850913          	addi	s2,a0,1112
    800038ee:	a021                	j	800038f6 <itrunc+0x7a>
    800038f0:	0491                	addi	s1,s1,4
    800038f2:	01248b63          	beq	s1,s2,80003908 <itrunc+0x8c>
      if(a[j])
    800038f6:	408c                	lw	a1,0(s1)
    800038f8:	dde5                	beqz	a1,800038f0 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800038fa:	0009a503          	lw	a0,0(s3)
    800038fe:	00000097          	auipc	ra,0x0
    80003902:	8b4080e7          	jalr	-1868(ra) # 800031b2 <bfree>
    80003906:	b7ed                	j	800038f0 <itrunc+0x74>
    brelse(bp);
    80003908:	8552                	mv	a0,s4
    8000390a:	fffff097          	auipc	ra,0xfffff
    8000390e:	792080e7          	jalr	1938(ra) # 8000309c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003912:	0809a583          	lw	a1,128(s3)
    80003916:	0009a503          	lw	a0,0(s3)
    8000391a:	00000097          	auipc	ra,0x0
    8000391e:	898080e7          	jalr	-1896(ra) # 800031b2 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003922:	0809a023          	sw	zero,128(s3)
    80003926:	bf51                	j	800038ba <itrunc+0x3e>

0000000080003928 <iput>:
{
    80003928:	1101                	addi	sp,sp,-32
    8000392a:	ec06                	sd	ra,24(sp)
    8000392c:	e822                	sd	s0,16(sp)
    8000392e:	e426                	sd	s1,8(sp)
    80003930:	e04a                	sd	s2,0(sp)
    80003932:	1000                	addi	s0,sp,32
    80003934:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003936:	0001c517          	auipc	a0,0x1c
    8000393a:	e9250513          	addi	a0,a0,-366 # 8001f7c8 <itable>
    8000393e:	ffffd097          	auipc	ra,0xffffd
    80003942:	292080e7          	jalr	658(ra) # 80000bd0 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003946:	4498                	lw	a4,8(s1)
    80003948:	4785                	li	a5,1
    8000394a:	02f70363          	beq	a4,a5,80003970 <iput+0x48>
  ip->ref--;
    8000394e:	449c                	lw	a5,8(s1)
    80003950:	37fd                	addiw	a5,a5,-1
    80003952:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003954:	0001c517          	auipc	a0,0x1c
    80003958:	e7450513          	addi	a0,a0,-396 # 8001f7c8 <itable>
    8000395c:	ffffd097          	auipc	ra,0xffffd
    80003960:	328080e7          	jalr	808(ra) # 80000c84 <release>
}
    80003964:	60e2                	ld	ra,24(sp)
    80003966:	6442                	ld	s0,16(sp)
    80003968:	64a2                	ld	s1,8(sp)
    8000396a:	6902                	ld	s2,0(sp)
    8000396c:	6105                	addi	sp,sp,32
    8000396e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003970:	40bc                	lw	a5,64(s1)
    80003972:	dff1                	beqz	a5,8000394e <iput+0x26>
    80003974:	04a49783          	lh	a5,74(s1)
    80003978:	fbf9                	bnez	a5,8000394e <iput+0x26>
    acquiresleep(&ip->lock);
    8000397a:	01048913          	addi	s2,s1,16
    8000397e:	854a                	mv	a0,s2
    80003980:	00001097          	auipc	ra,0x1
    80003984:	ab8080e7          	jalr	-1352(ra) # 80004438 <acquiresleep>
    release(&itable.lock);
    80003988:	0001c517          	auipc	a0,0x1c
    8000398c:	e4050513          	addi	a0,a0,-448 # 8001f7c8 <itable>
    80003990:	ffffd097          	auipc	ra,0xffffd
    80003994:	2f4080e7          	jalr	756(ra) # 80000c84 <release>
    itrunc(ip);
    80003998:	8526                	mv	a0,s1
    8000399a:	00000097          	auipc	ra,0x0
    8000399e:	ee2080e7          	jalr	-286(ra) # 8000387c <itrunc>
    ip->type = 0;
    800039a2:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039a6:	8526                	mv	a0,s1
    800039a8:	00000097          	auipc	ra,0x0
    800039ac:	cfc080e7          	jalr	-772(ra) # 800036a4 <iupdate>
    ip->valid = 0;
    800039b0:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039b4:	854a                	mv	a0,s2
    800039b6:	00001097          	auipc	ra,0x1
    800039ba:	ad8080e7          	jalr	-1320(ra) # 8000448e <releasesleep>
    acquire(&itable.lock);
    800039be:	0001c517          	auipc	a0,0x1c
    800039c2:	e0a50513          	addi	a0,a0,-502 # 8001f7c8 <itable>
    800039c6:	ffffd097          	auipc	ra,0xffffd
    800039ca:	20a080e7          	jalr	522(ra) # 80000bd0 <acquire>
    800039ce:	b741                	j	8000394e <iput+0x26>

00000000800039d0 <iunlockput>:
{
    800039d0:	1101                	addi	sp,sp,-32
    800039d2:	ec06                	sd	ra,24(sp)
    800039d4:	e822                	sd	s0,16(sp)
    800039d6:	e426                	sd	s1,8(sp)
    800039d8:	1000                	addi	s0,sp,32
    800039da:	84aa                	mv	s1,a0
  iunlock(ip);
    800039dc:	00000097          	auipc	ra,0x0
    800039e0:	e54080e7          	jalr	-428(ra) # 80003830 <iunlock>
  iput(ip);
    800039e4:	8526                	mv	a0,s1
    800039e6:	00000097          	auipc	ra,0x0
    800039ea:	f42080e7          	jalr	-190(ra) # 80003928 <iput>
}
    800039ee:	60e2                	ld	ra,24(sp)
    800039f0:	6442                	ld	s0,16(sp)
    800039f2:	64a2                	ld	s1,8(sp)
    800039f4:	6105                	addi	sp,sp,32
    800039f6:	8082                	ret

00000000800039f8 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800039f8:	1141                	addi	sp,sp,-16
    800039fa:	e422                	sd	s0,8(sp)
    800039fc:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800039fe:	411c                	lw	a5,0(a0)
    80003a00:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a02:	415c                	lw	a5,4(a0)
    80003a04:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a06:	04451783          	lh	a5,68(a0)
    80003a0a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a0e:	04a51783          	lh	a5,74(a0)
    80003a12:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a16:	04c56783          	lwu	a5,76(a0)
    80003a1a:	e99c                	sd	a5,16(a1)
}
    80003a1c:	6422                	ld	s0,8(sp)
    80003a1e:	0141                	addi	sp,sp,16
    80003a20:	8082                	ret

0000000080003a22 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a22:	457c                	lw	a5,76(a0)
    80003a24:	0ed7e963          	bltu	a5,a3,80003b16 <readi+0xf4>
{
    80003a28:	7159                	addi	sp,sp,-112
    80003a2a:	f486                	sd	ra,104(sp)
    80003a2c:	f0a2                	sd	s0,96(sp)
    80003a2e:	eca6                	sd	s1,88(sp)
    80003a30:	e8ca                	sd	s2,80(sp)
    80003a32:	e4ce                	sd	s3,72(sp)
    80003a34:	e0d2                	sd	s4,64(sp)
    80003a36:	fc56                	sd	s5,56(sp)
    80003a38:	f85a                	sd	s6,48(sp)
    80003a3a:	f45e                	sd	s7,40(sp)
    80003a3c:	f062                	sd	s8,32(sp)
    80003a3e:	ec66                	sd	s9,24(sp)
    80003a40:	e86a                	sd	s10,16(sp)
    80003a42:	e46e                	sd	s11,8(sp)
    80003a44:	1880                	addi	s0,sp,112
    80003a46:	8baa                	mv	s7,a0
    80003a48:	8c2e                	mv	s8,a1
    80003a4a:	8ab2                	mv	s5,a2
    80003a4c:	84b6                	mv	s1,a3
    80003a4e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a50:	9f35                	addw	a4,a4,a3
    return 0;
    80003a52:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a54:	0ad76063          	bltu	a4,a3,80003af4 <readi+0xd2>
  if(off + n > ip->size)
    80003a58:	00e7f463          	bgeu	a5,a4,80003a60 <readi+0x3e>
    n = ip->size - off;
    80003a5c:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a60:	0a0b0963          	beqz	s6,80003b12 <readi+0xf0>
    80003a64:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a66:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a6a:	5cfd                	li	s9,-1
    80003a6c:	a82d                	j	80003aa6 <readi+0x84>
    80003a6e:	020a1d93          	slli	s11,s4,0x20
    80003a72:	020ddd93          	srli	s11,s11,0x20
    80003a76:	05890793          	addi	a5,s2,88
    80003a7a:	86ee                	mv	a3,s11
    80003a7c:	963e                	add	a2,a2,a5
    80003a7e:	85d6                	mv	a1,s5
    80003a80:	8562                	mv	a0,s8
    80003a82:	fffff097          	auipc	ra,0xfffff
    80003a86:	978080e7          	jalr	-1672(ra) # 800023fa <either_copyout>
    80003a8a:	05950d63          	beq	a0,s9,80003ae4 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a8e:	854a                	mv	a0,s2
    80003a90:	fffff097          	auipc	ra,0xfffff
    80003a94:	60c080e7          	jalr	1548(ra) # 8000309c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a98:	013a09bb          	addw	s3,s4,s3
    80003a9c:	009a04bb          	addw	s1,s4,s1
    80003aa0:	9aee                	add	s5,s5,s11
    80003aa2:	0569f763          	bgeu	s3,s6,80003af0 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003aa6:	000ba903          	lw	s2,0(s7)
    80003aaa:	00a4d59b          	srliw	a1,s1,0xa
    80003aae:	855e                	mv	a0,s7
    80003ab0:	00000097          	auipc	ra,0x0
    80003ab4:	8b0080e7          	jalr	-1872(ra) # 80003360 <bmap>
    80003ab8:	0005059b          	sext.w	a1,a0
    80003abc:	854a                	mv	a0,s2
    80003abe:	fffff097          	auipc	ra,0xfffff
    80003ac2:	4ae080e7          	jalr	1198(ra) # 80002f6c <bread>
    80003ac6:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ac8:	3ff4f613          	andi	a2,s1,1023
    80003acc:	40cd07bb          	subw	a5,s10,a2
    80003ad0:	413b073b          	subw	a4,s6,s3
    80003ad4:	8a3e                	mv	s4,a5
    80003ad6:	2781                	sext.w	a5,a5
    80003ad8:	0007069b          	sext.w	a3,a4
    80003adc:	f8f6f9e3          	bgeu	a3,a5,80003a6e <readi+0x4c>
    80003ae0:	8a3a                	mv	s4,a4
    80003ae2:	b771                	j	80003a6e <readi+0x4c>
      brelse(bp);
    80003ae4:	854a                	mv	a0,s2
    80003ae6:	fffff097          	auipc	ra,0xfffff
    80003aea:	5b6080e7          	jalr	1462(ra) # 8000309c <brelse>
      tot = -1;
    80003aee:	59fd                	li	s3,-1
  }
  return tot;
    80003af0:	0009851b          	sext.w	a0,s3
}
    80003af4:	70a6                	ld	ra,104(sp)
    80003af6:	7406                	ld	s0,96(sp)
    80003af8:	64e6                	ld	s1,88(sp)
    80003afa:	6946                	ld	s2,80(sp)
    80003afc:	69a6                	ld	s3,72(sp)
    80003afe:	6a06                	ld	s4,64(sp)
    80003b00:	7ae2                	ld	s5,56(sp)
    80003b02:	7b42                	ld	s6,48(sp)
    80003b04:	7ba2                	ld	s7,40(sp)
    80003b06:	7c02                	ld	s8,32(sp)
    80003b08:	6ce2                	ld	s9,24(sp)
    80003b0a:	6d42                	ld	s10,16(sp)
    80003b0c:	6da2                	ld	s11,8(sp)
    80003b0e:	6165                	addi	sp,sp,112
    80003b10:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b12:	89da                	mv	s3,s6
    80003b14:	bff1                	j	80003af0 <readi+0xce>
    return 0;
    80003b16:	4501                	li	a0,0
}
    80003b18:	8082                	ret

0000000080003b1a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b1a:	457c                	lw	a5,76(a0)
    80003b1c:	10d7e863          	bltu	a5,a3,80003c2c <writei+0x112>
{
    80003b20:	7159                	addi	sp,sp,-112
    80003b22:	f486                	sd	ra,104(sp)
    80003b24:	f0a2                	sd	s0,96(sp)
    80003b26:	eca6                	sd	s1,88(sp)
    80003b28:	e8ca                	sd	s2,80(sp)
    80003b2a:	e4ce                	sd	s3,72(sp)
    80003b2c:	e0d2                	sd	s4,64(sp)
    80003b2e:	fc56                	sd	s5,56(sp)
    80003b30:	f85a                	sd	s6,48(sp)
    80003b32:	f45e                	sd	s7,40(sp)
    80003b34:	f062                	sd	s8,32(sp)
    80003b36:	ec66                	sd	s9,24(sp)
    80003b38:	e86a                	sd	s10,16(sp)
    80003b3a:	e46e                	sd	s11,8(sp)
    80003b3c:	1880                	addi	s0,sp,112
    80003b3e:	8b2a                	mv	s6,a0
    80003b40:	8c2e                	mv	s8,a1
    80003b42:	8ab2                	mv	s5,a2
    80003b44:	8936                	mv	s2,a3
    80003b46:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003b48:	00e687bb          	addw	a5,a3,a4
    80003b4c:	0ed7e263          	bltu	a5,a3,80003c30 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b50:	00043737          	lui	a4,0x43
    80003b54:	0ef76063          	bltu	a4,a5,80003c34 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b58:	0c0b8863          	beqz	s7,80003c28 <writei+0x10e>
    80003b5c:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b5e:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b62:	5cfd                	li	s9,-1
    80003b64:	a091                	j	80003ba8 <writei+0x8e>
    80003b66:	02099d93          	slli	s11,s3,0x20
    80003b6a:	020ddd93          	srli	s11,s11,0x20
    80003b6e:	05848793          	addi	a5,s1,88
    80003b72:	86ee                	mv	a3,s11
    80003b74:	8656                	mv	a2,s5
    80003b76:	85e2                	mv	a1,s8
    80003b78:	953e                	add	a0,a0,a5
    80003b7a:	fffff097          	auipc	ra,0xfffff
    80003b7e:	8d6080e7          	jalr	-1834(ra) # 80002450 <either_copyin>
    80003b82:	07950263          	beq	a0,s9,80003be6 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b86:	8526                	mv	a0,s1
    80003b88:	00000097          	auipc	ra,0x0
    80003b8c:	790080e7          	jalr	1936(ra) # 80004318 <log_write>
    brelse(bp);
    80003b90:	8526                	mv	a0,s1
    80003b92:	fffff097          	auipc	ra,0xfffff
    80003b96:	50a080e7          	jalr	1290(ra) # 8000309c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b9a:	01498a3b          	addw	s4,s3,s4
    80003b9e:	0129893b          	addw	s2,s3,s2
    80003ba2:	9aee                	add	s5,s5,s11
    80003ba4:	057a7663          	bgeu	s4,s7,80003bf0 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ba8:	000b2483          	lw	s1,0(s6)
    80003bac:	00a9559b          	srliw	a1,s2,0xa
    80003bb0:	855a                	mv	a0,s6
    80003bb2:	fffff097          	auipc	ra,0xfffff
    80003bb6:	7ae080e7          	jalr	1966(ra) # 80003360 <bmap>
    80003bba:	0005059b          	sext.w	a1,a0
    80003bbe:	8526                	mv	a0,s1
    80003bc0:	fffff097          	auipc	ra,0xfffff
    80003bc4:	3ac080e7          	jalr	940(ra) # 80002f6c <bread>
    80003bc8:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bca:	3ff97513          	andi	a0,s2,1023
    80003bce:	40ad07bb          	subw	a5,s10,a0
    80003bd2:	414b873b          	subw	a4,s7,s4
    80003bd6:	89be                	mv	s3,a5
    80003bd8:	2781                	sext.w	a5,a5
    80003bda:	0007069b          	sext.w	a3,a4
    80003bde:	f8f6f4e3          	bgeu	a3,a5,80003b66 <writei+0x4c>
    80003be2:	89ba                	mv	s3,a4
    80003be4:	b749                	j	80003b66 <writei+0x4c>
      brelse(bp);
    80003be6:	8526                	mv	a0,s1
    80003be8:	fffff097          	auipc	ra,0xfffff
    80003bec:	4b4080e7          	jalr	1204(ra) # 8000309c <brelse>
  }

  if(off > ip->size)
    80003bf0:	04cb2783          	lw	a5,76(s6)
    80003bf4:	0127f463          	bgeu	a5,s2,80003bfc <writei+0xe2>
    ip->size = off;
    80003bf8:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003bfc:	855a                	mv	a0,s6
    80003bfe:	00000097          	auipc	ra,0x0
    80003c02:	aa6080e7          	jalr	-1370(ra) # 800036a4 <iupdate>

  return tot;
    80003c06:	000a051b          	sext.w	a0,s4
}
    80003c0a:	70a6                	ld	ra,104(sp)
    80003c0c:	7406                	ld	s0,96(sp)
    80003c0e:	64e6                	ld	s1,88(sp)
    80003c10:	6946                	ld	s2,80(sp)
    80003c12:	69a6                	ld	s3,72(sp)
    80003c14:	6a06                	ld	s4,64(sp)
    80003c16:	7ae2                	ld	s5,56(sp)
    80003c18:	7b42                	ld	s6,48(sp)
    80003c1a:	7ba2                	ld	s7,40(sp)
    80003c1c:	7c02                	ld	s8,32(sp)
    80003c1e:	6ce2                	ld	s9,24(sp)
    80003c20:	6d42                	ld	s10,16(sp)
    80003c22:	6da2                	ld	s11,8(sp)
    80003c24:	6165                	addi	sp,sp,112
    80003c26:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c28:	8a5e                	mv	s4,s7
    80003c2a:	bfc9                	j	80003bfc <writei+0xe2>
    return -1;
    80003c2c:	557d                	li	a0,-1
}
    80003c2e:	8082                	ret
    return -1;
    80003c30:	557d                	li	a0,-1
    80003c32:	bfe1                	j	80003c0a <writei+0xf0>
    return -1;
    80003c34:	557d                	li	a0,-1
    80003c36:	bfd1                	j	80003c0a <writei+0xf0>

0000000080003c38 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c38:	1141                	addi	sp,sp,-16
    80003c3a:	e406                	sd	ra,8(sp)
    80003c3c:	e022                	sd	s0,0(sp)
    80003c3e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c40:	4639                	li	a2,14
    80003c42:	ffffd097          	auipc	ra,0xffffd
    80003c46:	15a080e7          	jalr	346(ra) # 80000d9c <strncmp>
}
    80003c4a:	60a2                	ld	ra,8(sp)
    80003c4c:	6402                	ld	s0,0(sp)
    80003c4e:	0141                	addi	sp,sp,16
    80003c50:	8082                	ret

0000000080003c52 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c52:	7139                	addi	sp,sp,-64
    80003c54:	fc06                	sd	ra,56(sp)
    80003c56:	f822                	sd	s0,48(sp)
    80003c58:	f426                	sd	s1,40(sp)
    80003c5a:	f04a                	sd	s2,32(sp)
    80003c5c:	ec4e                	sd	s3,24(sp)
    80003c5e:	e852                	sd	s4,16(sp)
    80003c60:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c62:	04451703          	lh	a4,68(a0)
    80003c66:	4785                	li	a5,1
    80003c68:	00f71a63          	bne	a4,a5,80003c7c <dirlookup+0x2a>
    80003c6c:	892a                	mv	s2,a0
    80003c6e:	89ae                	mv	s3,a1
    80003c70:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c72:	457c                	lw	a5,76(a0)
    80003c74:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c76:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c78:	e79d                	bnez	a5,80003ca6 <dirlookup+0x54>
    80003c7a:	a8a5                	j	80003cf2 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c7c:	00005517          	auipc	a0,0x5
    80003c80:	9a450513          	addi	a0,a0,-1628 # 80008620 <syscalls+0x1a8>
    80003c84:	ffffd097          	auipc	ra,0xffffd
    80003c88:	8b4080e7          	jalr	-1868(ra) # 80000538 <panic>
      panic("dirlookup read");
    80003c8c:	00005517          	auipc	a0,0x5
    80003c90:	9ac50513          	addi	a0,a0,-1620 # 80008638 <syscalls+0x1c0>
    80003c94:	ffffd097          	auipc	ra,0xffffd
    80003c98:	8a4080e7          	jalr	-1884(ra) # 80000538 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c9c:	24c1                	addiw	s1,s1,16
    80003c9e:	04c92783          	lw	a5,76(s2)
    80003ca2:	04f4f763          	bgeu	s1,a5,80003cf0 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ca6:	4741                	li	a4,16
    80003ca8:	86a6                	mv	a3,s1
    80003caa:	fc040613          	addi	a2,s0,-64
    80003cae:	4581                	li	a1,0
    80003cb0:	854a                	mv	a0,s2
    80003cb2:	00000097          	auipc	ra,0x0
    80003cb6:	d70080e7          	jalr	-656(ra) # 80003a22 <readi>
    80003cba:	47c1                	li	a5,16
    80003cbc:	fcf518e3          	bne	a0,a5,80003c8c <dirlookup+0x3a>
    if(de.inum == 0)
    80003cc0:	fc045783          	lhu	a5,-64(s0)
    80003cc4:	dfe1                	beqz	a5,80003c9c <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003cc6:	fc240593          	addi	a1,s0,-62
    80003cca:	854e                	mv	a0,s3
    80003ccc:	00000097          	auipc	ra,0x0
    80003cd0:	f6c080e7          	jalr	-148(ra) # 80003c38 <namecmp>
    80003cd4:	f561                	bnez	a0,80003c9c <dirlookup+0x4a>
      if(poff)
    80003cd6:	000a0463          	beqz	s4,80003cde <dirlookup+0x8c>
        *poff = off;
    80003cda:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003cde:	fc045583          	lhu	a1,-64(s0)
    80003ce2:	00092503          	lw	a0,0(s2)
    80003ce6:	fffff097          	auipc	ra,0xfffff
    80003cea:	754080e7          	jalr	1876(ra) # 8000343a <iget>
    80003cee:	a011                	j	80003cf2 <dirlookup+0xa0>
  return 0;
    80003cf0:	4501                	li	a0,0
}
    80003cf2:	70e2                	ld	ra,56(sp)
    80003cf4:	7442                	ld	s0,48(sp)
    80003cf6:	74a2                	ld	s1,40(sp)
    80003cf8:	7902                	ld	s2,32(sp)
    80003cfa:	69e2                	ld	s3,24(sp)
    80003cfc:	6a42                	ld	s4,16(sp)
    80003cfe:	6121                	addi	sp,sp,64
    80003d00:	8082                	ret

0000000080003d02 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d02:	711d                	addi	sp,sp,-96
    80003d04:	ec86                	sd	ra,88(sp)
    80003d06:	e8a2                	sd	s0,80(sp)
    80003d08:	e4a6                	sd	s1,72(sp)
    80003d0a:	e0ca                	sd	s2,64(sp)
    80003d0c:	fc4e                	sd	s3,56(sp)
    80003d0e:	f852                	sd	s4,48(sp)
    80003d10:	f456                	sd	s5,40(sp)
    80003d12:	f05a                	sd	s6,32(sp)
    80003d14:	ec5e                	sd	s7,24(sp)
    80003d16:	e862                	sd	s8,16(sp)
    80003d18:	e466                	sd	s9,8(sp)
    80003d1a:	1080                	addi	s0,sp,96
    80003d1c:	84aa                	mv	s1,a0
    80003d1e:	8aae                	mv	s5,a1
    80003d20:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d22:	00054703          	lbu	a4,0(a0)
    80003d26:	02f00793          	li	a5,47
    80003d2a:	02f70363          	beq	a4,a5,80003d50 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d2e:	ffffe097          	auipc	ra,0xffffe
    80003d32:	c68080e7          	jalr	-920(ra) # 80001996 <myproc>
    80003d36:	15053503          	ld	a0,336(a0)
    80003d3a:	00000097          	auipc	ra,0x0
    80003d3e:	9f6080e7          	jalr	-1546(ra) # 80003730 <idup>
    80003d42:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d44:	02f00913          	li	s2,47
  len = path - s;
    80003d48:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003d4a:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d4c:	4b85                	li	s7,1
    80003d4e:	a865                	j	80003e06 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d50:	4585                	li	a1,1
    80003d52:	4505                	li	a0,1
    80003d54:	fffff097          	auipc	ra,0xfffff
    80003d58:	6e6080e7          	jalr	1766(ra) # 8000343a <iget>
    80003d5c:	89aa                	mv	s3,a0
    80003d5e:	b7dd                	j	80003d44 <namex+0x42>
      iunlockput(ip);
    80003d60:	854e                	mv	a0,s3
    80003d62:	00000097          	auipc	ra,0x0
    80003d66:	c6e080e7          	jalr	-914(ra) # 800039d0 <iunlockput>
      return 0;
    80003d6a:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d6c:	854e                	mv	a0,s3
    80003d6e:	60e6                	ld	ra,88(sp)
    80003d70:	6446                	ld	s0,80(sp)
    80003d72:	64a6                	ld	s1,72(sp)
    80003d74:	6906                	ld	s2,64(sp)
    80003d76:	79e2                	ld	s3,56(sp)
    80003d78:	7a42                	ld	s4,48(sp)
    80003d7a:	7aa2                	ld	s5,40(sp)
    80003d7c:	7b02                	ld	s6,32(sp)
    80003d7e:	6be2                	ld	s7,24(sp)
    80003d80:	6c42                	ld	s8,16(sp)
    80003d82:	6ca2                	ld	s9,8(sp)
    80003d84:	6125                	addi	sp,sp,96
    80003d86:	8082                	ret
      iunlock(ip);
    80003d88:	854e                	mv	a0,s3
    80003d8a:	00000097          	auipc	ra,0x0
    80003d8e:	aa6080e7          	jalr	-1370(ra) # 80003830 <iunlock>
      return ip;
    80003d92:	bfe9                	j	80003d6c <namex+0x6a>
      iunlockput(ip);
    80003d94:	854e                	mv	a0,s3
    80003d96:	00000097          	auipc	ra,0x0
    80003d9a:	c3a080e7          	jalr	-966(ra) # 800039d0 <iunlockput>
      return 0;
    80003d9e:	89e6                	mv	s3,s9
    80003da0:	b7f1                	j	80003d6c <namex+0x6a>
  len = path - s;
    80003da2:	40b48633          	sub	a2,s1,a1
    80003da6:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003daa:	099c5463          	bge	s8,s9,80003e32 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003dae:	4639                	li	a2,14
    80003db0:	8552                	mv	a0,s4
    80003db2:	ffffd097          	auipc	ra,0xffffd
    80003db6:	f76080e7          	jalr	-138(ra) # 80000d28 <memmove>
  while(*path == '/')
    80003dba:	0004c783          	lbu	a5,0(s1)
    80003dbe:	01279763          	bne	a5,s2,80003dcc <namex+0xca>
    path++;
    80003dc2:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dc4:	0004c783          	lbu	a5,0(s1)
    80003dc8:	ff278de3          	beq	a5,s2,80003dc2 <namex+0xc0>
    ilock(ip);
    80003dcc:	854e                	mv	a0,s3
    80003dce:	00000097          	auipc	ra,0x0
    80003dd2:	9a0080e7          	jalr	-1632(ra) # 8000376e <ilock>
    if(ip->type != T_DIR){
    80003dd6:	04499783          	lh	a5,68(s3)
    80003dda:	f97793e3          	bne	a5,s7,80003d60 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003dde:	000a8563          	beqz	s5,80003de8 <namex+0xe6>
    80003de2:	0004c783          	lbu	a5,0(s1)
    80003de6:	d3cd                	beqz	a5,80003d88 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003de8:	865a                	mv	a2,s6
    80003dea:	85d2                	mv	a1,s4
    80003dec:	854e                	mv	a0,s3
    80003dee:	00000097          	auipc	ra,0x0
    80003df2:	e64080e7          	jalr	-412(ra) # 80003c52 <dirlookup>
    80003df6:	8caa                	mv	s9,a0
    80003df8:	dd51                	beqz	a0,80003d94 <namex+0x92>
    iunlockput(ip);
    80003dfa:	854e                	mv	a0,s3
    80003dfc:	00000097          	auipc	ra,0x0
    80003e00:	bd4080e7          	jalr	-1068(ra) # 800039d0 <iunlockput>
    ip = next;
    80003e04:	89e6                	mv	s3,s9
  while(*path == '/')
    80003e06:	0004c783          	lbu	a5,0(s1)
    80003e0a:	05279763          	bne	a5,s2,80003e58 <namex+0x156>
    path++;
    80003e0e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e10:	0004c783          	lbu	a5,0(s1)
    80003e14:	ff278de3          	beq	a5,s2,80003e0e <namex+0x10c>
  if(*path == 0)
    80003e18:	c79d                	beqz	a5,80003e46 <namex+0x144>
    path++;
    80003e1a:	85a6                	mv	a1,s1
  len = path - s;
    80003e1c:	8cda                	mv	s9,s6
    80003e1e:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003e20:	01278963          	beq	a5,s2,80003e32 <namex+0x130>
    80003e24:	dfbd                	beqz	a5,80003da2 <namex+0xa0>
    path++;
    80003e26:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e28:	0004c783          	lbu	a5,0(s1)
    80003e2c:	ff279ce3          	bne	a5,s2,80003e24 <namex+0x122>
    80003e30:	bf8d                	j	80003da2 <namex+0xa0>
    memmove(name, s, len);
    80003e32:	2601                	sext.w	a2,a2
    80003e34:	8552                	mv	a0,s4
    80003e36:	ffffd097          	auipc	ra,0xffffd
    80003e3a:	ef2080e7          	jalr	-270(ra) # 80000d28 <memmove>
    name[len] = 0;
    80003e3e:	9cd2                	add	s9,s9,s4
    80003e40:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003e44:	bf9d                	j	80003dba <namex+0xb8>
  if(nameiparent){
    80003e46:	f20a83e3          	beqz	s5,80003d6c <namex+0x6a>
    iput(ip);
    80003e4a:	854e                	mv	a0,s3
    80003e4c:	00000097          	auipc	ra,0x0
    80003e50:	adc080e7          	jalr	-1316(ra) # 80003928 <iput>
    return 0;
    80003e54:	4981                	li	s3,0
    80003e56:	bf19                	j	80003d6c <namex+0x6a>
  if(*path == 0)
    80003e58:	d7fd                	beqz	a5,80003e46 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003e5a:	0004c783          	lbu	a5,0(s1)
    80003e5e:	85a6                	mv	a1,s1
    80003e60:	b7d1                	j	80003e24 <namex+0x122>

0000000080003e62 <dirlink>:
{
    80003e62:	7139                	addi	sp,sp,-64
    80003e64:	fc06                	sd	ra,56(sp)
    80003e66:	f822                	sd	s0,48(sp)
    80003e68:	f426                	sd	s1,40(sp)
    80003e6a:	f04a                	sd	s2,32(sp)
    80003e6c:	ec4e                	sd	s3,24(sp)
    80003e6e:	e852                	sd	s4,16(sp)
    80003e70:	0080                	addi	s0,sp,64
    80003e72:	892a                	mv	s2,a0
    80003e74:	8a2e                	mv	s4,a1
    80003e76:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e78:	4601                	li	a2,0
    80003e7a:	00000097          	auipc	ra,0x0
    80003e7e:	dd8080e7          	jalr	-552(ra) # 80003c52 <dirlookup>
    80003e82:	e93d                	bnez	a0,80003ef8 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e84:	04c92483          	lw	s1,76(s2)
    80003e88:	c49d                	beqz	s1,80003eb6 <dirlink+0x54>
    80003e8a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e8c:	4741                	li	a4,16
    80003e8e:	86a6                	mv	a3,s1
    80003e90:	fc040613          	addi	a2,s0,-64
    80003e94:	4581                	li	a1,0
    80003e96:	854a                	mv	a0,s2
    80003e98:	00000097          	auipc	ra,0x0
    80003e9c:	b8a080e7          	jalr	-1142(ra) # 80003a22 <readi>
    80003ea0:	47c1                	li	a5,16
    80003ea2:	06f51163          	bne	a0,a5,80003f04 <dirlink+0xa2>
    if(de.inum == 0)
    80003ea6:	fc045783          	lhu	a5,-64(s0)
    80003eaa:	c791                	beqz	a5,80003eb6 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eac:	24c1                	addiw	s1,s1,16
    80003eae:	04c92783          	lw	a5,76(s2)
    80003eb2:	fcf4ede3          	bltu	s1,a5,80003e8c <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003eb6:	4639                	li	a2,14
    80003eb8:	85d2                	mv	a1,s4
    80003eba:	fc240513          	addi	a0,s0,-62
    80003ebe:	ffffd097          	auipc	ra,0xffffd
    80003ec2:	f1a080e7          	jalr	-230(ra) # 80000dd8 <strncpy>
  de.inum = inum;
    80003ec6:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003eca:	4741                	li	a4,16
    80003ecc:	86a6                	mv	a3,s1
    80003ece:	fc040613          	addi	a2,s0,-64
    80003ed2:	4581                	li	a1,0
    80003ed4:	854a                	mv	a0,s2
    80003ed6:	00000097          	auipc	ra,0x0
    80003eda:	c44080e7          	jalr	-956(ra) # 80003b1a <writei>
    80003ede:	872a                	mv	a4,a0
    80003ee0:	47c1                	li	a5,16
  return 0;
    80003ee2:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ee4:	02f71863          	bne	a4,a5,80003f14 <dirlink+0xb2>
}
    80003ee8:	70e2                	ld	ra,56(sp)
    80003eea:	7442                	ld	s0,48(sp)
    80003eec:	74a2                	ld	s1,40(sp)
    80003eee:	7902                	ld	s2,32(sp)
    80003ef0:	69e2                	ld	s3,24(sp)
    80003ef2:	6a42                	ld	s4,16(sp)
    80003ef4:	6121                	addi	sp,sp,64
    80003ef6:	8082                	ret
    iput(ip);
    80003ef8:	00000097          	auipc	ra,0x0
    80003efc:	a30080e7          	jalr	-1488(ra) # 80003928 <iput>
    return -1;
    80003f00:	557d                	li	a0,-1
    80003f02:	b7dd                	j	80003ee8 <dirlink+0x86>
      panic("dirlink read");
    80003f04:	00004517          	auipc	a0,0x4
    80003f08:	74450513          	addi	a0,a0,1860 # 80008648 <syscalls+0x1d0>
    80003f0c:	ffffc097          	auipc	ra,0xffffc
    80003f10:	62c080e7          	jalr	1580(ra) # 80000538 <panic>
    panic("dirlink");
    80003f14:	00005517          	auipc	a0,0x5
    80003f18:	84450513          	addi	a0,a0,-1980 # 80008758 <syscalls+0x2e0>
    80003f1c:	ffffc097          	auipc	ra,0xffffc
    80003f20:	61c080e7          	jalr	1564(ra) # 80000538 <panic>

0000000080003f24 <namei>:

struct inode*
namei(char *path)
{
    80003f24:	1101                	addi	sp,sp,-32
    80003f26:	ec06                	sd	ra,24(sp)
    80003f28:	e822                	sd	s0,16(sp)
    80003f2a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f2c:	fe040613          	addi	a2,s0,-32
    80003f30:	4581                	li	a1,0
    80003f32:	00000097          	auipc	ra,0x0
    80003f36:	dd0080e7          	jalr	-560(ra) # 80003d02 <namex>
}
    80003f3a:	60e2                	ld	ra,24(sp)
    80003f3c:	6442                	ld	s0,16(sp)
    80003f3e:	6105                	addi	sp,sp,32
    80003f40:	8082                	ret

0000000080003f42 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f42:	1141                	addi	sp,sp,-16
    80003f44:	e406                	sd	ra,8(sp)
    80003f46:	e022                	sd	s0,0(sp)
    80003f48:	0800                	addi	s0,sp,16
    80003f4a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f4c:	4585                	li	a1,1
    80003f4e:	00000097          	auipc	ra,0x0
    80003f52:	db4080e7          	jalr	-588(ra) # 80003d02 <namex>
}
    80003f56:	60a2                	ld	ra,8(sp)
    80003f58:	6402                	ld	s0,0(sp)
    80003f5a:	0141                	addi	sp,sp,16
    80003f5c:	8082                	ret

0000000080003f5e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f5e:	1101                	addi	sp,sp,-32
    80003f60:	ec06                	sd	ra,24(sp)
    80003f62:	e822                	sd	s0,16(sp)
    80003f64:	e426                	sd	s1,8(sp)
    80003f66:	e04a                	sd	s2,0(sp)
    80003f68:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f6a:	0001d917          	auipc	s2,0x1d
    80003f6e:	30690913          	addi	s2,s2,774 # 80021270 <log>
    80003f72:	01892583          	lw	a1,24(s2)
    80003f76:	02892503          	lw	a0,40(s2)
    80003f7a:	fffff097          	auipc	ra,0xfffff
    80003f7e:	ff2080e7          	jalr	-14(ra) # 80002f6c <bread>
    80003f82:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f84:	02c92683          	lw	a3,44(s2)
    80003f88:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f8a:	02d05763          	blez	a3,80003fb8 <write_head+0x5a>
    80003f8e:	0001d797          	auipc	a5,0x1d
    80003f92:	31278793          	addi	a5,a5,786 # 800212a0 <log+0x30>
    80003f96:	05c50713          	addi	a4,a0,92
    80003f9a:	36fd                	addiw	a3,a3,-1
    80003f9c:	1682                	slli	a3,a3,0x20
    80003f9e:	9281                	srli	a3,a3,0x20
    80003fa0:	068a                	slli	a3,a3,0x2
    80003fa2:	0001d617          	auipc	a2,0x1d
    80003fa6:	30260613          	addi	a2,a2,770 # 800212a4 <log+0x34>
    80003faa:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003fac:	4390                	lw	a2,0(a5)
    80003fae:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003fb0:	0791                	addi	a5,a5,4
    80003fb2:	0711                	addi	a4,a4,4
    80003fb4:	fed79ce3          	bne	a5,a3,80003fac <write_head+0x4e>
  }
  bwrite(buf);
    80003fb8:	8526                	mv	a0,s1
    80003fba:	fffff097          	auipc	ra,0xfffff
    80003fbe:	0a4080e7          	jalr	164(ra) # 8000305e <bwrite>
  brelse(buf);
    80003fc2:	8526                	mv	a0,s1
    80003fc4:	fffff097          	auipc	ra,0xfffff
    80003fc8:	0d8080e7          	jalr	216(ra) # 8000309c <brelse>
}
    80003fcc:	60e2                	ld	ra,24(sp)
    80003fce:	6442                	ld	s0,16(sp)
    80003fd0:	64a2                	ld	s1,8(sp)
    80003fd2:	6902                	ld	s2,0(sp)
    80003fd4:	6105                	addi	sp,sp,32
    80003fd6:	8082                	ret

0000000080003fd8 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fd8:	0001d797          	auipc	a5,0x1d
    80003fdc:	2c47a783          	lw	a5,708(a5) # 8002129c <log+0x2c>
    80003fe0:	0af05d63          	blez	a5,8000409a <install_trans+0xc2>
{
    80003fe4:	7139                	addi	sp,sp,-64
    80003fe6:	fc06                	sd	ra,56(sp)
    80003fe8:	f822                	sd	s0,48(sp)
    80003fea:	f426                	sd	s1,40(sp)
    80003fec:	f04a                	sd	s2,32(sp)
    80003fee:	ec4e                	sd	s3,24(sp)
    80003ff0:	e852                	sd	s4,16(sp)
    80003ff2:	e456                	sd	s5,8(sp)
    80003ff4:	e05a                	sd	s6,0(sp)
    80003ff6:	0080                	addi	s0,sp,64
    80003ff8:	8b2a                	mv	s6,a0
    80003ffa:	0001da97          	auipc	s5,0x1d
    80003ffe:	2a6a8a93          	addi	s5,s5,678 # 800212a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004002:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004004:	0001d997          	auipc	s3,0x1d
    80004008:	26c98993          	addi	s3,s3,620 # 80021270 <log>
    8000400c:	a00d                	j	8000402e <install_trans+0x56>
    brelse(lbuf);
    8000400e:	854a                	mv	a0,s2
    80004010:	fffff097          	auipc	ra,0xfffff
    80004014:	08c080e7          	jalr	140(ra) # 8000309c <brelse>
    brelse(dbuf);
    80004018:	8526                	mv	a0,s1
    8000401a:	fffff097          	auipc	ra,0xfffff
    8000401e:	082080e7          	jalr	130(ra) # 8000309c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004022:	2a05                	addiw	s4,s4,1
    80004024:	0a91                	addi	s5,s5,4
    80004026:	02c9a783          	lw	a5,44(s3)
    8000402a:	04fa5e63          	bge	s4,a5,80004086 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000402e:	0189a583          	lw	a1,24(s3)
    80004032:	014585bb          	addw	a1,a1,s4
    80004036:	2585                	addiw	a1,a1,1
    80004038:	0289a503          	lw	a0,40(s3)
    8000403c:	fffff097          	auipc	ra,0xfffff
    80004040:	f30080e7          	jalr	-208(ra) # 80002f6c <bread>
    80004044:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004046:	000aa583          	lw	a1,0(s5)
    8000404a:	0289a503          	lw	a0,40(s3)
    8000404e:	fffff097          	auipc	ra,0xfffff
    80004052:	f1e080e7          	jalr	-226(ra) # 80002f6c <bread>
    80004056:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004058:	40000613          	li	a2,1024
    8000405c:	05890593          	addi	a1,s2,88
    80004060:	05850513          	addi	a0,a0,88
    80004064:	ffffd097          	auipc	ra,0xffffd
    80004068:	cc4080e7          	jalr	-828(ra) # 80000d28 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000406c:	8526                	mv	a0,s1
    8000406e:	fffff097          	auipc	ra,0xfffff
    80004072:	ff0080e7          	jalr	-16(ra) # 8000305e <bwrite>
    if(recovering == 0)
    80004076:	f80b1ce3          	bnez	s6,8000400e <install_trans+0x36>
      bunpin(dbuf);
    8000407a:	8526                	mv	a0,s1
    8000407c:	fffff097          	auipc	ra,0xfffff
    80004080:	0fa080e7          	jalr	250(ra) # 80003176 <bunpin>
    80004084:	b769                	j	8000400e <install_trans+0x36>
}
    80004086:	70e2                	ld	ra,56(sp)
    80004088:	7442                	ld	s0,48(sp)
    8000408a:	74a2                	ld	s1,40(sp)
    8000408c:	7902                	ld	s2,32(sp)
    8000408e:	69e2                	ld	s3,24(sp)
    80004090:	6a42                	ld	s4,16(sp)
    80004092:	6aa2                	ld	s5,8(sp)
    80004094:	6b02                	ld	s6,0(sp)
    80004096:	6121                	addi	sp,sp,64
    80004098:	8082                	ret
    8000409a:	8082                	ret

000000008000409c <initlog>:
{
    8000409c:	7179                	addi	sp,sp,-48
    8000409e:	f406                	sd	ra,40(sp)
    800040a0:	f022                	sd	s0,32(sp)
    800040a2:	ec26                	sd	s1,24(sp)
    800040a4:	e84a                	sd	s2,16(sp)
    800040a6:	e44e                	sd	s3,8(sp)
    800040a8:	1800                	addi	s0,sp,48
    800040aa:	892a                	mv	s2,a0
    800040ac:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040ae:	0001d497          	auipc	s1,0x1d
    800040b2:	1c248493          	addi	s1,s1,450 # 80021270 <log>
    800040b6:	00004597          	auipc	a1,0x4
    800040ba:	5a258593          	addi	a1,a1,1442 # 80008658 <syscalls+0x1e0>
    800040be:	8526                	mv	a0,s1
    800040c0:	ffffd097          	auipc	ra,0xffffd
    800040c4:	a80080e7          	jalr	-1408(ra) # 80000b40 <initlock>
  log.start = sb->logstart;
    800040c8:	0149a583          	lw	a1,20(s3)
    800040cc:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800040ce:	0109a783          	lw	a5,16(s3)
    800040d2:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800040d4:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800040d8:	854a                	mv	a0,s2
    800040da:	fffff097          	auipc	ra,0xfffff
    800040de:	e92080e7          	jalr	-366(ra) # 80002f6c <bread>
  log.lh.n = lh->n;
    800040e2:	4d34                	lw	a3,88(a0)
    800040e4:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800040e6:	02d05563          	blez	a3,80004110 <initlog+0x74>
    800040ea:	05c50793          	addi	a5,a0,92
    800040ee:	0001d717          	auipc	a4,0x1d
    800040f2:	1b270713          	addi	a4,a4,434 # 800212a0 <log+0x30>
    800040f6:	36fd                	addiw	a3,a3,-1
    800040f8:	1682                	slli	a3,a3,0x20
    800040fa:	9281                	srli	a3,a3,0x20
    800040fc:	068a                	slli	a3,a3,0x2
    800040fe:	06050613          	addi	a2,a0,96
    80004102:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004104:	4390                	lw	a2,0(a5)
    80004106:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004108:	0791                	addi	a5,a5,4
    8000410a:	0711                	addi	a4,a4,4
    8000410c:	fed79ce3          	bne	a5,a3,80004104 <initlog+0x68>
  brelse(buf);
    80004110:	fffff097          	auipc	ra,0xfffff
    80004114:	f8c080e7          	jalr	-116(ra) # 8000309c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004118:	4505                	li	a0,1
    8000411a:	00000097          	auipc	ra,0x0
    8000411e:	ebe080e7          	jalr	-322(ra) # 80003fd8 <install_trans>
  log.lh.n = 0;
    80004122:	0001d797          	auipc	a5,0x1d
    80004126:	1607ad23          	sw	zero,378(a5) # 8002129c <log+0x2c>
  write_head(); // clear the log
    8000412a:	00000097          	auipc	ra,0x0
    8000412e:	e34080e7          	jalr	-460(ra) # 80003f5e <write_head>
}
    80004132:	70a2                	ld	ra,40(sp)
    80004134:	7402                	ld	s0,32(sp)
    80004136:	64e2                	ld	s1,24(sp)
    80004138:	6942                	ld	s2,16(sp)
    8000413a:	69a2                	ld	s3,8(sp)
    8000413c:	6145                	addi	sp,sp,48
    8000413e:	8082                	ret

0000000080004140 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004140:	1101                	addi	sp,sp,-32
    80004142:	ec06                	sd	ra,24(sp)
    80004144:	e822                	sd	s0,16(sp)
    80004146:	e426                	sd	s1,8(sp)
    80004148:	e04a                	sd	s2,0(sp)
    8000414a:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000414c:	0001d517          	auipc	a0,0x1d
    80004150:	12450513          	addi	a0,a0,292 # 80021270 <log>
    80004154:	ffffd097          	auipc	ra,0xffffd
    80004158:	a7c080e7          	jalr	-1412(ra) # 80000bd0 <acquire>
  while(1){
    if(log.committing){
    8000415c:	0001d497          	auipc	s1,0x1d
    80004160:	11448493          	addi	s1,s1,276 # 80021270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004164:	4979                	li	s2,30
    80004166:	a039                	j	80004174 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004168:	85a6                	mv	a1,s1
    8000416a:	8526                	mv	a0,s1
    8000416c:	ffffe097          	auipc	ra,0xffffe
    80004170:	eea080e7          	jalr	-278(ra) # 80002056 <sleep>
    if(log.committing){
    80004174:	50dc                	lw	a5,36(s1)
    80004176:	fbed                	bnez	a5,80004168 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004178:	509c                	lw	a5,32(s1)
    8000417a:	0017871b          	addiw	a4,a5,1
    8000417e:	0007069b          	sext.w	a3,a4
    80004182:	0027179b          	slliw	a5,a4,0x2
    80004186:	9fb9                	addw	a5,a5,a4
    80004188:	0017979b          	slliw	a5,a5,0x1
    8000418c:	54d8                	lw	a4,44(s1)
    8000418e:	9fb9                	addw	a5,a5,a4
    80004190:	00f95963          	bge	s2,a5,800041a2 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004194:	85a6                	mv	a1,s1
    80004196:	8526                	mv	a0,s1
    80004198:	ffffe097          	auipc	ra,0xffffe
    8000419c:	ebe080e7          	jalr	-322(ra) # 80002056 <sleep>
    800041a0:	bfd1                	j	80004174 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041a2:	0001d517          	auipc	a0,0x1d
    800041a6:	0ce50513          	addi	a0,a0,206 # 80021270 <log>
    800041aa:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041ac:	ffffd097          	auipc	ra,0xffffd
    800041b0:	ad8080e7          	jalr	-1320(ra) # 80000c84 <release>
      break;
    }
  }
}
    800041b4:	60e2                	ld	ra,24(sp)
    800041b6:	6442                	ld	s0,16(sp)
    800041b8:	64a2                	ld	s1,8(sp)
    800041ba:	6902                	ld	s2,0(sp)
    800041bc:	6105                	addi	sp,sp,32
    800041be:	8082                	ret

00000000800041c0 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800041c0:	7139                	addi	sp,sp,-64
    800041c2:	fc06                	sd	ra,56(sp)
    800041c4:	f822                	sd	s0,48(sp)
    800041c6:	f426                	sd	s1,40(sp)
    800041c8:	f04a                	sd	s2,32(sp)
    800041ca:	ec4e                	sd	s3,24(sp)
    800041cc:	e852                	sd	s4,16(sp)
    800041ce:	e456                	sd	s5,8(sp)
    800041d0:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800041d2:	0001d497          	auipc	s1,0x1d
    800041d6:	09e48493          	addi	s1,s1,158 # 80021270 <log>
    800041da:	8526                	mv	a0,s1
    800041dc:	ffffd097          	auipc	ra,0xffffd
    800041e0:	9f4080e7          	jalr	-1548(ra) # 80000bd0 <acquire>
  log.outstanding -= 1;
    800041e4:	509c                	lw	a5,32(s1)
    800041e6:	37fd                	addiw	a5,a5,-1
    800041e8:	0007891b          	sext.w	s2,a5
    800041ec:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800041ee:	50dc                	lw	a5,36(s1)
    800041f0:	e7b9                	bnez	a5,8000423e <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800041f2:	04091e63          	bnez	s2,8000424e <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800041f6:	0001d497          	auipc	s1,0x1d
    800041fa:	07a48493          	addi	s1,s1,122 # 80021270 <log>
    800041fe:	4785                	li	a5,1
    80004200:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004202:	8526                	mv	a0,s1
    80004204:	ffffd097          	auipc	ra,0xffffd
    80004208:	a80080e7          	jalr	-1408(ra) # 80000c84 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000420c:	54dc                	lw	a5,44(s1)
    8000420e:	06f04763          	bgtz	a5,8000427c <end_op+0xbc>
    acquire(&log.lock);
    80004212:	0001d497          	auipc	s1,0x1d
    80004216:	05e48493          	addi	s1,s1,94 # 80021270 <log>
    8000421a:	8526                	mv	a0,s1
    8000421c:	ffffd097          	auipc	ra,0xffffd
    80004220:	9b4080e7          	jalr	-1612(ra) # 80000bd0 <acquire>
    log.committing = 0;
    80004224:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004228:	8526                	mv	a0,s1
    8000422a:	ffffe097          	auipc	ra,0xffffe
    8000422e:	fb8080e7          	jalr	-72(ra) # 800021e2 <wakeup>
    release(&log.lock);
    80004232:	8526                	mv	a0,s1
    80004234:	ffffd097          	auipc	ra,0xffffd
    80004238:	a50080e7          	jalr	-1456(ra) # 80000c84 <release>
}
    8000423c:	a03d                	j	8000426a <end_op+0xaa>
    panic("log.committing");
    8000423e:	00004517          	auipc	a0,0x4
    80004242:	42250513          	addi	a0,a0,1058 # 80008660 <syscalls+0x1e8>
    80004246:	ffffc097          	auipc	ra,0xffffc
    8000424a:	2f2080e7          	jalr	754(ra) # 80000538 <panic>
    wakeup(&log);
    8000424e:	0001d497          	auipc	s1,0x1d
    80004252:	02248493          	addi	s1,s1,34 # 80021270 <log>
    80004256:	8526                	mv	a0,s1
    80004258:	ffffe097          	auipc	ra,0xffffe
    8000425c:	f8a080e7          	jalr	-118(ra) # 800021e2 <wakeup>
  release(&log.lock);
    80004260:	8526                	mv	a0,s1
    80004262:	ffffd097          	auipc	ra,0xffffd
    80004266:	a22080e7          	jalr	-1502(ra) # 80000c84 <release>
}
    8000426a:	70e2                	ld	ra,56(sp)
    8000426c:	7442                	ld	s0,48(sp)
    8000426e:	74a2                	ld	s1,40(sp)
    80004270:	7902                	ld	s2,32(sp)
    80004272:	69e2                	ld	s3,24(sp)
    80004274:	6a42                	ld	s4,16(sp)
    80004276:	6aa2                	ld	s5,8(sp)
    80004278:	6121                	addi	sp,sp,64
    8000427a:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000427c:	0001da97          	auipc	s5,0x1d
    80004280:	024a8a93          	addi	s5,s5,36 # 800212a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004284:	0001da17          	auipc	s4,0x1d
    80004288:	feca0a13          	addi	s4,s4,-20 # 80021270 <log>
    8000428c:	018a2583          	lw	a1,24(s4)
    80004290:	012585bb          	addw	a1,a1,s2
    80004294:	2585                	addiw	a1,a1,1
    80004296:	028a2503          	lw	a0,40(s4)
    8000429a:	fffff097          	auipc	ra,0xfffff
    8000429e:	cd2080e7          	jalr	-814(ra) # 80002f6c <bread>
    800042a2:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042a4:	000aa583          	lw	a1,0(s5)
    800042a8:	028a2503          	lw	a0,40(s4)
    800042ac:	fffff097          	auipc	ra,0xfffff
    800042b0:	cc0080e7          	jalr	-832(ra) # 80002f6c <bread>
    800042b4:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800042b6:	40000613          	li	a2,1024
    800042ba:	05850593          	addi	a1,a0,88
    800042be:	05848513          	addi	a0,s1,88
    800042c2:	ffffd097          	auipc	ra,0xffffd
    800042c6:	a66080e7          	jalr	-1434(ra) # 80000d28 <memmove>
    bwrite(to);  // write the log
    800042ca:	8526                	mv	a0,s1
    800042cc:	fffff097          	auipc	ra,0xfffff
    800042d0:	d92080e7          	jalr	-622(ra) # 8000305e <bwrite>
    brelse(from);
    800042d4:	854e                	mv	a0,s3
    800042d6:	fffff097          	auipc	ra,0xfffff
    800042da:	dc6080e7          	jalr	-570(ra) # 8000309c <brelse>
    brelse(to);
    800042de:	8526                	mv	a0,s1
    800042e0:	fffff097          	auipc	ra,0xfffff
    800042e4:	dbc080e7          	jalr	-580(ra) # 8000309c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042e8:	2905                	addiw	s2,s2,1
    800042ea:	0a91                	addi	s5,s5,4
    800042ec:	02ca2783          	lw	a5,44(s4)
    800042f0:	f8f94ee3          	blt	s2,a5,8000428c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800042f4:	00000097          	auipc	ra,0x0
    800042f8:	c6a080e7          	jalr	-918(ra) # 80003f5e <write_head>
    install_trans(0); // Now install writes to home locations
    800042fc:	4501                	li	a0,0
    800042fe:	00000097          	auipc	ra,0x0
    80004302:	cda080e7          	jalr	-806(ra) # 80003fd8 <install_trans>
    log.lh.n = 0;
    80004306:	0001d797          	auipc	a5,0x1d
    8000430a:	f807ab23          	sw	zero,-106(a5) # 8002129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000430e:	00000097          	auipc	ra,0x0
    80004312:	c50080e7          	jalr	-944(ra) # 80003f5e <write_head>
    80004316:	bdf5                	j	80004212 <end_op+0x52>

0000000080004318 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004318:	1101                	addi	sp,sp,-32
    8000431a:	ec06                	sd	ra,24(sp)
    8000431c:	e822                	sd	s0,16(sp)
    8000431e:	e426                	sd	s1,8(sp)
    80004320:	e04a                	sd	s2,0(sp)
    80004322:	1000                	addi	s0,sp,32
    80004324:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004326:	0001d917          	auipc	s2,0x1d
    8000432a:	f4a90913          	addi	s2,s2,-182 # 80021270 <log>
    8000432e:	854a                	mv	a0,s2
    80004330:	ffffd097          	auipc	ra,0xffffd
    80004334:	8a0080e7          	jalr	-1888(ra) # 80000bd0 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004338:	02c92603          	lw	a2,44(s2)
    8000433c:	47f5                	li	a5,29
    8000433e:	06c7c563          	blt	a5,a2,800043a8 <log_write+0x90>
    80004342:	0001d797          	auipc	a5,0x1d
    80004346:	f4a7a783          	lw	a5,-182(a5) # 8002128c <log+0x1c>
    8000434a:	37fd                	addiw	a5,a5,-1
    8000434c:	04f65e63          	bge	a2,a5,800043a8 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004350:	0001d797          	auipc	a5,0x1d
    80004354:	f407a783          	lw	a5,-192(a5) # 80021290 <log+0x20>
    80004358:	06f05063          	blez	a5,800043b8 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000435c:	4781                	li	a5,0
    8000435e:	06c05563          	blez	a2,800043c8 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004362:	44cc                	lw	a1,12(s1)
    80004364:	0001d717          	auipc	a4,0x1d
    80004368:	f3c70713          	addi	a4,a4,-196 # 800212a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000436c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000436e:	4314                	lw	a3,0(a4)
    80004370:	04b68c63          	beq	a3,a1,800043c8 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004374:	2785                	addiw	a5,a5,1
    80004376:	0711                	addi	a4,a4,4
    80004378:	fef61be3          	bne	a2,a5,8000436e <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000437c:	0621                	addi	a2,a2,8
    8000437e:	060a                	slli	a2,a2,0x2
    80004380:	0001d797          	auipc	a5,0x1d
    80004384:	ef078793          	addi	a5,a5,-272 # 80021270 <log>
    80004388:	963e                	add	a2,a2,a5
    8000438a:	44dc                	lw	a5,12(s1)
    8000438c:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000438e:	8526                	mv	a0,s1
    80004390:	fffff097          	auipc	ra,0xfffff
    80004394:	daa080e7          	jalr	-598(ra) # 8000313a <bpin>
    log.lh.n++;
    80004398:	0001d717          	auipc	a4,0x1d
    8000439c:	ed870713          	addi	a4,a4,-296 # 80021270 <log>
    800043a0:	575c                	lw	a5,44(a4)
    800043a2:	2785                	addiw	a5,a5,1
    800043a4:	d75c                	sw	a5,44(a4)
    800043a6:	a835                	j	800043e2 <log_write+0xca>
    panic("too big a transaction");
    800043a8:	00004517          	auipc	a0,0x4
    800043ac:	2c850513          	addi	a0,a0,712 # 80008670 <syscalls+0x1f8>
    800043b0:	ffffc097          	auipc	ra,0xffffc
    800043b4:	188080e7          	jalr	392(ra) # 80000538 <panic>
    panic("log_write outside of trans");
    800043b8:	00004517          	auipc	a0,0x4
    800043bc:	2d050513          	addi	a0,a0,720 # 80008688 <syscalls+0x210>
    800043c0:	ffffc097          	auipc	ra,0xffffc
    800043c4:	178080e7          	jalr	376(ra) # 80000538 <panic>
  log.lh.block[i] = b->blockno;
    800043c8:	00878713          	addi	a4,a5,8
    800043cc:	00271693          	slli	a3,a4,0x2
    800043d0:	0001d717          	auipc	a4,0x1d
    800043d4:	ea070713          	addi	a4,a4,-352 # 80021270 <log>
    800043d8:	9736                	add	a4,a4,a3
    800043da:	44d4                	lw	a3,12(s1)
    800043dc:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800043de:	faf608e3          	beq	a2,a5,8000438e <log_write+0x76>
  }
  release(&log.lock);
    800043e2:	0001d517          	auipc	a0,0x1d
    800043e6:	e8e50513          	addi	a0,a0,-370 # 80021270 <log>
    800043ea:	ffffd097          	auipc	ra,0xffffd
    800043ee:	89a080e7          	jalr	-1894(ra) # 80000c84 <release>
}
    800043f2:	60e2                	ld	ra,24(sp)
    800043f4:	6442                	ld	s0,16(sp)
    800043f6:	64a2                	ld	s1,8(sp)
    800043f8:	6902                	ld	s2,0(sp)
    800043fa:	6105                	addi	sp,sp,32
    800043fc:	8082                	ret

00000000800043fe <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800043fe:	1101                	addi	sp,sp,-32
    80004400:	ec06                	sd	ra,24(sp)
    80004402:	e822                	sd	s0,16(sp)
    80004404:	e426                	sd	s1,8(sp)
    80004406:	e04a                	sd	s2,0(sp)
    80004408:	1000                	addi	s0,sp,32
    8000440a:	84aa                	mv	s1,a0
    8000440c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000440e:	00004597          	auipc	a1,0x4
    80004412:	29a58593          	addi	a1,a1,666 # 800086a8 <syscalls+0x230>
    80004416:	0521                	addi	a0,a0,8
    80004418:	ffffc097          	auipc	ra,0xffffc
    8000441c:	728080e7          	jalr	1832(ra) # 80000b40 <initlock>
  lk->name = name;
    80004420:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004424:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004428:	0204a423          	sw	zero,40(s1)
}
    8000442c:	60e2                	ld	ra,24(sp)
    8000442e:	6442                	ld	s0,16(sp)
    80004430:	64a2                	ld	s1,8(sp)
    80004432:	6902                	ld	s2,0(sp)
    80004434:	6105                	addi	sp,sp,32
    80004436:	8082                	ret

0000000080004438 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004438:	1101                	addi	sp,sp,-32
    8000443a:	ec06                	sd	ra,24(sp)
    8000443c:	e822                	sd	s0,16(sp)
    8000443e:	e426                	sd	s1,8(sp)
    80004440:	e04a                	sd	s2,0(sp)
    80004442:	1000                	addi	s0,sp,32
    80004444:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004446:	00850913          	addi	s2,a0,8
    8000444a:	854a                	mv	a0,s2
    8000444c:	ffffc097          	auipc	ra,0xffffc
    80004450:	784080e7          	jalr	1924(ra) # 80000bd0 <acquire>
  while (lk->locked) {
    80004454:	409c                	lw	a5,0(s1)
    80004456:	cb89                	beqz	a5,80004468 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004458:	85ca                	mv	a1,s2
    8000445a:	8526                	mv	a0,s1
    8000445c:	ffffe097          	auipc	ra,0xffffe
    80004460:	bfa080e7          	jalr	-1030(ra) # 80002056 <sleep>
  while (lk->locked) {
    80004464:	409c                	lw	a5,0(s1)
    80004466:	fbed                	bnez	a5,80004458 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004468:	4785                	li	a5,1
    8000446a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000446c:	ffffd097          	auipc	ra,0xffffd
    80004470:	52a080e7          	jalr	1322(ra) # 80001996 <myproc>
    80004474:	591c                	lw	a5,48(a0)
    80004476:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004478:	854a                	mv	a0,s2
    8000447a:	ffffd097          	auipc	ra,0xffffd
    8000447e:	80a080e7          	jalr	-2038(ra) # 80000c84 <release>
}
    80004482:	60e2                	ld	ra,24(sp)
    80004484:	6442                	ld	s0,16(sp)
    80004486:	64a2                	ld	s1,8(sp)
    80004488:	6902                	ld	s2,0(sp)
    8000448a:	6105                	addi	sp,sp,32
    8000448c:	8082                	ret

000000008000448e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000448e:	1101                	addi	sp,sp,-32
    80004490:	ec06                	sd	ra,24(sp)
    80004492:	e822                	sd	s0,16(sp)
    80004494:	e426                	sd	s1,8(sp)
    80004496:	e04a                	sd	s2,0(sp)
    80004498:	1000                	addi	s0,sp,32
    8000449a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000449c:	00850913          	addi	s2,a0,8
    800044a0:	854a                	mv	a0,s2
    800044a2:	ffffc097          	auipc	ra,0xffffc
    800044a6:	72e080e7          	jalr	1838(ra) # 80000bd0 <acquire>
  lk->locked = 0;
    800044aa:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044ae:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044b2:	8526                	mv	a0,s1
    800044b4:	ffffe097          	auipc	ra,0xffffe
    800044b8:	d2e080e7          	jalr	-722(ra) # 800021e2 <wakeup>
  release(&lk->lk);
    800044bc:	854a                	mv	a0,s2
    800044be:	ffffc097          	auipc	ra,0xffffc
    800044c2:	7c6080e7          	jalr	1990(ra) # 80000c84 <release>
}
    800044c6:	60e2                	ld	ra,24(sp)
    800044c8:	6442                	ld	s0,16(sp)
    800044ca:	64a2                	ld	s1,8(sp)
    800044cc:	6902                	ld	s2,0(sp)
    800044ce:	6105                	addi	sp,sp,32
    800044d0:	8082                	ret

00000000800044d2 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800044d2:	7179                	addi	sp,sp,-48
    800044d4:	f406                	sd	ra,40(sp)
    800044d6:	f022                	sd	s0,32(sp)
    800044d8:	ec26                	sd	s1,24(sp)
    800044da:	e84a                	sd	s2,16(sp)
    800044dc:	e44e                	sd	s3,8(sp)
    800044de:	1800                	addi	s0,sp,48
    800044e0:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800044e2:	00850913          	addi	s2,a0,8
    800044e6:	854a                	mv	a0,s2
    800044e8:	ffffc097          	auipc	ra,0xffffc
    800044ec:	6e8080e7          	jalr	1768(ra) # 80000bd0 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800044f0:	409c                	lw	a5,0(s1)
    800044f2:	ef99                	bnez	a5,80004510 <holdingsleep+0x3e>
    800044f4:	4481                	li	s1,0
  release(&lk->lk);
    800044f6:	854a                	mv	a0,s2
    800044f8:	ffffc097          	auipc	ra,0xffffc
    800044fc:	78c080e7          	jalr	1932(ra) # 80000c84 <release>
  return r;
}
    80004500:	8526                	mv	a0,s1
    80004502:	70a2                	ld	ra,40(sp)
    80004504:	7402                	ld	s0,32(sp)
    80004506:	64e2                	ld	s1,24(sp)
    80004508:	6942                	ld	s2,16(sp)
    8000450a:	69a2                	ld	s3,8(sp)
    8000450c:	6145                	addi	sp,sp,48
    8000450e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004510:	0284a983          	lw	s3,40(s1)
    80004514:	ffffd097          	auipc	ra,0xffffd
    80004518:	482080e7          	jalr	1154(ra) # 80001996 <myproc>
    8000451c:	5904                	lw	s1,48(a0)
    8000451e:	413484b3          	sub	s1,s1,s3
    80004522:	0014b493          	seqz	s1,s1
    80004526:	bfc1                	j	800044f6 <holdingsleep+0x24>

0000000080004528 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004528:	1141                	addi	sp,sp,-16
    8000452a:	e406                	sd	ra,8(sp)
    8000452c:	e022                	sd	s0,0(sp)
    8000452e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004530:	00004597          	auipc	a1,0x4
    80004534:	18858593          	addi	a1,a1,392 # 800086b8 <syscalls+0x240>
    80004538:	0001d517          	auipc	a0,0x1d
    8000453c:	e8050513          	addi	a0,a0,-384 # 800213b8 <ftable>
    80004540:	ffffc097          	auipc	ra,0xffffc
    80004544:	600080e7          	jalr	1536(ra) # 80000b40 <initlock>
}
    80004548:	60a2                	ld	ra,8(sp)
    8000454a:	6402                	ld	s0,0(sp)
    8000454c:	0141                	addi	sp,sp,16
    8000454e:	8082                	ret

0000000080004550 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004550:	1101                	addi	sp,sp,-32
    80004552:	ec06                	sd	ra,24(sp)
    80004554:	e822                	sd	s0,16(sp)
    80004556:	e426                	sd	s1,8(sp)
    80004558:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000455a:	0001d517          	auipc	a0,0x1d
    8000455e:	e5e50513          	addi	a0,a0,-418 # 800213b8 <ftable>
    80004562:	ffffc097          	auipc	ra,0xffffc
    80004566:	66e080e7          	jalr	1646(ra) # 80000bd0 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000456a:	0001d497          	auipc	s1,0x1d
    8000456e:	e6648493          	addi	s1,s1,-410 # 800213d0 <ftable+0x18>
    80004572:	0001e717          	auipc	a4,0x1e
    80004576:	dfe70713          	addi	a4,a4,-514 # 80022370 <ftable+0xfb8>
    if(f->ref == 0){
    8000457a:	40dc                	lw	a5,4(s1)
    8000457c:	cf99                	beqz	a5,8000459a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000457e:	02848493          	addi	s1,s1,40
    80004582:	fee49ce3          	bne	s1,a4,8000457a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004586:	0001d517          	auipc	a0,0x1d
    8000458a:	e3250513          	addi	a0,a0,-462 # 800213b8 <ftable>
    8000458e:	ffffc097          	auipc	ra,0xffffc
    80004592:	6f6080e7          	jalr	1782(ra) # 80000c84 <release>
  return 0;
    80004596:	4481                	li	s1,0
    80004598:	a819                	j	800045ae <filealloc+0x5e>
      f->ref = 1;
    8000459a:	4785                	li	a5,1
    8000459c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000459e:	0001d517          	auipc	a0,0x1d
    800045a2:	e1a50513          	addi	a0,a0,-486 # 800213b8 <ftable>
    800045a6:	ffffc097          	auipc	ra,0xffffc
    800045aa:	6de080e7          	jalr	1758(ra) # 80000c84 <release>
}
    800045ae:	8526                	mv	a0,s1
    800045b0:	60e2                	ld	ra,24(sp)
    800045b2:	6442                	ld	s0,16(sp)
    800045b4:	64a2                	ld	s1,8(sp)
    800045b6:	6105                	addi	sp,sp,32
    800045b8:	8082                	ret

00000000800045ba <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800045ba:	1101                	addi	sp,sp,-32
    800045bc:	ec06                	sd	ra,24(sp)
    800045be:	e822                	sd	s0,16(sp)
    800045c0:	e426                	sd	s1,8(sp)
    800045c2:	1000                	addi	s0,sp,32
    800045c4:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800045c6:	0001d517          	auipc	a0,0x1d
    800045ca:	df250513          	addi	a0,a0,-526 # 800213b8 <ftable>
    800045ce:	ffffc097          	auipc	ra,0xffffc
    800045d2:	602080e7          	jalr	1538(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    800045d6:	40dc                	lw	a5,4(s1)
    800045d8:	02f05263          	blez	a5,800045fc <filedup+0x42>
    panic("filedup");
  f->ref++;
    800045dc:	2785                	addiw	a5,a5,1
    800045de:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800045e0:	0001d517          	auipc	a0,0x1d
    800045e4:	dd850513          	addi	a0,a0,-552 # 800213b8 <ftable>
    800045e8:	ffffc097          	auipc	ra,0xffffc
    800045ec:	69c080e7          	jalr	1692(ra) # 80000c84 <release>
  return f;
}
    800045f0:	8526                	mv	a0,s1
    800045f2:	60e2                	ld	ra,24(sp)
    800045f4:	6442                	ld	s0,16(sp)
    800045f6:	64a2                	ld	s1,8(sp)
    800045f8:	6105                	addi	sp,sp,32
    800045fa:	8082                	ret
    panic("filedup");
    800045fc:	00004517          	auipc	a0,0x4
    80004600:	0c450513          	addi	a0,a0,196 # 800086c0 <syscalls+0x248>
    80004604:	ffffc097          	auipc	ra,0xffffc
    80004608:	f34080e7          	jalr	-204(ra) # 80000538 <panic>

000000008000460c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000460c:	7139                	addi	sp,sp,-64
    8000460e:	fc06                	sd	ra,56(sp)
    80004610:	f822                	sd	s0,48(sp)
    80004612:	f426                	sd	s1,40(sp)
    80004614:	f04a                	sd	s2,32(sp)
    80004616:	ec4e                	sd	s3,24(sp)
    80004618:	e852                	sd	s4,16(sp)
    8000461a:	e456                	sd	s5,8(sp)
    8000461c:	0080                	addi	s0,sp,64
    8000461e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004620:	0001d517          	auipc	a0,0x1d
    80004624:	d9850513          	addi	a0,a0,-616 # 800213b8 <ftable>
    80004628:	ffffc097          	auipc	ra,0xffffc
    8000462c:	5a8080e7          	jalr	1448(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    80004630:	40dc                	lw	a5,4(s1)
    80004632:	06f05163          	blez	a5,80004694 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004636:	37fd                	addiw	a5,a5,-1
    80004638:	0007871b          	sext.w	a4,a5
    8000463c:	c0dc                	sw	a5,4(s1)
    8000463e:	06e04363          	bgtz	a4,800046a4 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004642:	0004a903          	lw	s2,0(s1)
    80004646:	0094ca83          	lbu	s5,9(s1)
    8000464a:	0104ba03          	ld	s4,16(s1)
    8000464e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004652:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004656:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000465a:	0001d517          	auipc	a0,0x1d
    8000465e:	d5e50513          	addi	a0,a0,-674 # 800213b8 <ftable>
    80004662:	ffffc097          	auipc	ra,0xffffc
    80004666:	622080e7          	jalr	1570(ra) # 80000c84 <release>

  if(ff.type == FD_PIPE){
    8000466a:	4785                	li	a5,1
    8000466c:	04f90d63          	beq	s2,a5,800046c6 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004670:	3979                	addiw	s2,s2,-2
    80004672:	4785                	li	a5,1
    80004674:	0527e063          	bltu	a5,s2,800046b4 <fileclose+0xa8>
    begin_op();
    80004678:	00000097          	auipc	ra,0x0
    8000467c:	ac8080e7          	jalr	-1336(ra) # 80004140 <begin_op>
    iput(ff.ip);
    80004680:	854e                	mv	a0,s3
    80004682:	fffff097          	auipc	ra,0xfffff
    80004686:	2a6080e7          	jalr	678(ra) # 80003928 <iput>
    end_op();
    8000468a:	00000097          	auipc	ra,0x0
    8000468e:	b36080e7          	jalr	-1226(ra) # 800041c0 <end_op>
    80004692:	a00d                	j	800046b4 <fileclose+0xa8>
    panic("fileclose");
    80004694:	00004517          	auipc	a0,0x4
    80004698:	03450513          	addi	a0,a0,52 # 800086c8 <syscalls+0x250>
    8000469c:	ffffc097          	auipc	ra,0xffffc
    800046a0:	e9c080e7          	jalr	-356(ra) # 80000538 <panic>
    release(&ftable.lock);
    800046a4:	0001d517          	auipc	a0,0x1d
    800046a8:	d1450513          	addi	a0,a0,-748 # 800213b8 <ftable>
    800046ac:	ffffc097          	auipc	ra,0xffffc
    800046b0:	5d8080e7          	jalr	1496(ra) # 80000c84 <release>
  }
}
    800046b4:	70e2                	ld	ra,56(sp)
    800046b6:	7442                	ld	s0,48(sp)
    800046b8:	74a2                	ld	s1,40(sp)
    800046ba:	7902                	ld	s2,32(sp)
    800046bc:	69e2                	ld	s3,24(sp)
    800046be:	6a42                	ld	s4,16(sp)
    800046c0:	6aa2                	ld	s5,8(sp)
    800046c2:	6121                	addi	sp,sp,64
    800046c4:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800046c6:	85d6                	mv	a1,s5
    800046c8:	8552                	mv	a0,s4
    800046ca:	00000097          	auipc	ra,0x0
    800046ce:	34c080e7          	jalr	844(ra) # 80004a16 <pipeclose>
    800046d2:	b7cd                	j	800046b4 <fileclose+0xa8>

00000000800046d4 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800046d4:	715d                	addi	sp,sp,-80
    800046d6:	e486                	sd	ra,72(sp)
    800046d8:	e0a2                	sd	s0,64(sp)
    800046da:	fc26                	sd	s1,56(sp)
    800046dc:	f84a                	sd	s2,48(sp)
    800046de:	f44e                	sd	s3,40(sp)
    800046e0:	0880                	addi	s0,sp,80
    800046e2:	84aa                	mv	s1,a0
    800046e4:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800046e6:	ffffd097          	auipc	ra,0xffffd
    800046ea:	2b0080e7          	jalr	688(ra) # 80001996 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800046ee:	409c                	lw	a5,0(s1)
    800046f0:	37f9                	addiw	a5,a5,-2
    800046f2:	4705                	li	a4,1
    800046f4:	04f76763          	bltu	a4,a5,80004742 <filestat+0x6e>
    800046f8:	892a                	mv	s2,a0
    ilock(f->ip);
    800046fa:	6c88                	ld	a0,24(s1)
    800046fc:	fffff097          	auipc	ra,0xfffff
    80004700:	072080e7          	jalr	114(ra) # 8000376e <ilock>
    stati(f->ip, &st);
    80004704:	fb840593          	addi	a1,s0,-72
    80004708:	6c88                	ld	a0,24(s1)
    8000470a:	fffff097          	auipc	ra,0xfffff
    8000470e:	2ee080e7          	jalr	750(ra) # 800039f8 <stati>
    iunlock(f->ip);
    80004712:	6c88                	ld	a0,24(s1)
    80004714:	fffff097          	auipc	ra,0xfffff
    80004718:	11c080e7          	jalr	284(ra) # 80003830 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000471c:	46e1                	li	a3,24
    8000471e:	fb840613          	addi	a2,s0,-72
    80004722:	85ce                	mv	a1,s3
    80004724:	05093503          	ld	a0,80(s2)
    80004728:	ffffd097          	auipc	ra,0xffffd
    8000472c:	f2e080e7          	jalr	-210(ra) # 80001656 <copyout>
    80004730:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004734:	60a6                	ld	ra,72(sp)
    80004736:	6406                	ld	s0,64(sp)
    80004738:	74e2                	ld	s1,56(sp)
    8000473a:	7942                	ld	s2,48(sp)
    8000473c:	79a2                	ld	s3,40(sp)
    8000473e:	6161                	addi	sp,sp,80
    80004740:	8082                	ret
  return -1;
    80004742:	557d                	li	a0,-1
    80004744:	bfc5                	j	80004734 <filestat+0x60>

0000000080004746 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004746:	7179                	addi	sp,sp,-48
    80004748:	f406                	sd	ra,40(sp)
    8000474a:	f022                	sd	s0,32(sp)
    8000474c:	ec26                	sd	s1,24(sp)
    8000474e:	e84a                	sd	s2,16(sp)
    80004750:	e44e                	sd	s3,8(sp)
    80004752:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004754:	00854783          	lbu	a5,8(a0)
    80004758:	c3d5                	beqz	a5,800047fc <fileread+0xb6>
    8000475a:	84aa                	mv	s1,a0
    8000475c:	89ae                	mv	s3,a1
    8000475e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004760:	411c                	lw	a5,0(a0)
    80004762:	4705                	li	a4,1
    80004764:	04e78963          	beq	a5,a4,800047b6 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004768:	470d                	li	a4,3
    8000476a:	04e78d63          	beq	a5,a4,800047c4 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000476e:	4709                	li	a4,2
    80004770:	06e79e63          	bne	a5,a4,800047ec <fileread+0xa6>
    ilock(f->ip);
    80004774:	6d08                	ld	a0,24(a0)
    80004776:	fffff097          	auipc	ra,0xfffff
    8000477a:	ff8080e7          	jalr	-8(ra) # 8000376e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000477e:	874a                	mv	a4,s2
    80004780:	5094                	lw	a3,32(s1)
    80004782:	864e                	mv	a2,s3
    80004784:	4585                	li	a1,1
    80004786:	6c88                	ld	a0,24(s1)
    80004788:	fffff097          	auipc	ra,0xfffff
    8000478c:	29a080e7          	jalr	666(ra) # 80003a22 <readi>
    80004790:	892a                	mv	s2,a0
    80004792:	00a05563          	blez	a0,8000479c <fileread+0x56>
      f->off += r;
    80004796:	509c                	lw	a5,32(s1)
    80004798:	9fa9                	addw	a5,a5,a0
    8000479a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000479c:	6c88                	ld	a0,24(s1)
    8000479e:	fffff097          	auipc	ra,0xfffff
    800047a2:	092080e7          	jalr	146(ra) # 80003830 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047a6:	854a                	mv	a0,s2
    800047a8:	70a2                	ld	ra,40(sp)
    800047aa:	7402                	ld	s0,32(sp)
    800047ac:	64e2                	ld	s1,24(sp)
    800047ae:	6942                	ld	s2,16(sp)
    800047b0:	69a2                	ld	s3,8(sp)
    800047b2:	6145                	addi	sp,sp,48
    800047b4:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800047b6:	6908                	ld	a0,16(a0)
    800047b8:	00000097          	auipc	ra,0x0
    800047bc:	3c0080e7          	jalr	960(ra) # 80004b78 <piperead>
    800047c0:	892a                	mv	s2,a0
    800047c2:	b7d5                	j	800047a6 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800047c4:	02451783          	lh	a5,36(a0)
    800047c8:	03079693          	slli	a3,a5,0x30
    800047cc:	92c1                	srli	a3,a3,0x30
    800047ce:	4725                	li	a4,9
    800047d0:	02d76863          	bltu	a4,a3,80004800 <fileread+0xba>
    800047d4:	0792                	slli	a5,a5,0x4
    800047d6:	0001d717          	auipc	a4,0x1d
    800047da:	b4270713          	addi	a4,a4,-1214 # 80021318 <devsw>
    800047de:	97ba                	add	a5,a5,a4
    800047e0:	639c                	ld	a5,0(a5)
    800047e2:	c38d                	beqz	a5,80004804 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800047e4:	4505                	li	a0,1
    800047e6:	9782                	jalr	a5
    800047e8:	892a                	mv	s2,a0
    800047ea:	bf75                	j	800047a6 <fileread+0x60>
    panic("fileread");
    800047ec:	00004517          	auipc	a0,0x4
    800047f0:	eec50513          	addi	a0,a0,-276 # 800086d8 <syscalls+0x260>
    800047f4:	ffffc097          	auipc	ra,0xffffc
    800047f8:	d44080e7          	jalr	-700(ra) # 80000538 <panic>
    return -1;
    800047fc:	597d                	li	s2,-1
    800047fe:	b765                	j	800047a6 <fileread+0x60>
      return -1;
    80004800:	597d                	li	s2,-1
    80004802:	b755                	j	800047a6 <fileread+0x60>
    80004804:	597d                	li	s2,-1
    80004806:	b745                	j	800047a6 <fileread+0x60>

0000000080004808 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004808:	715d                	addi	sp,sp,-80
    8000480a:	e486                	sd	ra,72(sp)
    8000480c:	e0a2                	sd	s0,64(sp)
    8000480e:	fc26                	sd	s1,56(sp)
    80004810:	f84a                	sd	s2,48(sp)
    80004812:	f44e                	sd	s3,40(sp)
    80004814:	f052                	sd	s4,32(sp)
    80004816:	ec56                	sd	s5,24(sp)
    80004818:	e85a                	sd	s6,16(sp)
    8000481a:	e45e                	sd	s7,8(sp)
    8000481c:	e062                	sd	s8,0(sp)
    8000481e:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004820:	00954783          	lbu	a5,9(a0)
    80004824:	10078663          	beqz	a5,80004930 <filewrite+0x128>
    80004828:	892a                	mv	s2,a0
    8000482a:	8aae                	mv	s5,a1
    8000482c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000482e:	411c                	lw	a5,0(a0)
    80004830:	4705                	li	a4,1
    80004832:	02e78263          	beq	a5,a4,80004856 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004836:	470d                	li	a4,3
    80004838:	02e78663          	beq	a5,a4,80004864 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000483c:	4709                	li	a4,2
    8000483e:	0ee79163          	bne	a5,a4,80004920 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004842:	0ac05d63          	blez	a2,800048fc <filewrite+0xf4>
    int i = 0;
    80004846:	4981                	li	s3,0
    80004848:	6b05                	lui	s6,0x1
    8000484a:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000484e:	6b85                	lui	s7,0x1
    80004850:	c00b8b9b          	addiw	s7,s7,-1024
    80004854:	a861                	j	800048ec <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004856:	6908                	ld	a0,16(a0)
    80004858:	00000097          	auipc	ra,0x0
    8000485c:	22e080e7          	jalr	558(ra) # 80004a86 <pipewrite>
    80004860:	8a2a                	mv	s4,a0
    80004862:	a045                	j	80004902 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004864:	02451783          	lh	a5,36(a0)
    80004868:	03079693          	slli	a3,a5,0x30
    8000486c:	92c1                	srli	a3,a3,0x30
    8000486e:	4725                	li	a4,9
    80004870:	0cd76263          	bltu	a4,a3,80004934 <filewrite+0x12c>
    80004874:	0792                	slli	a5,a5,0x4
    80004876:	0001d717          	auipc	a4,0x1d
    8000487a:	aa270713          	addi	a4,a4,-1374 # 80021318 <devsw>
    8000487e:	97ba                	add	a5,a5,a4
    80004880:	679c                	ld	a5,8(a5)
    80004882:	cbdd                	beqz	a5,80004938 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004884:	4505                	li	a0,1
    80004886:	9782                	jalr	a5
    80004888:	8a2a                	mv	s4,a0
    8000488a:	a8a5                	j	80004902 <filewrite+0xfa>
    8000488c:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004890:	00000097          	auipc	ra,0x0
    80004894:	8b0080e7          	jalr	-1872(ra) # 80004140 <begin_op>
      ilock(f->ip);
    80004898:	01893503          	ld	a0,24(s2)
    8000489c:	fffff097          	auipc	ra,0xfffff
    800048a0:	ed2080e7          	jalr	-302(ra) # 8000376e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048a4:	8762                	mv	a4,s8
    800048a6:	02092683          	lw	a3,32(s2)
    800048aa:	01598633          	add	a2,s3,s5
    800048ae:	4585                	li	a1,1
    800048b0:	01893503          	ld	a0,24(s2)
    800048b4:	fffff097          	auipc	ra,0xfffff
    800048b8:	266080e7          	jalr	614(ra) # 80003b1a <writei>
    800048bc:	84aa                	mv	s1,a0
    800048be:	00a05763          	blez	a0,800048cc <filewrite+0xc4>
        f->off += r;
    800048c2:	02092783          	lw	a5,32(s2)
    800048c6:	9fa9                	addw	a5,a5,a0
    800048c8:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800048cc:	01893503          	ld	a0,24(s2)
    800048d0:	fffff097          	auipc	ra,0xfffff
    800048d4:	f60080e7          	jalr	-160(ra) # 80003830 <iunlock>
      end_op();
    800048d8:	00000097          	auipc	ra,0x0
    800048dc:	8e8080e7          	jalr	-1816(ra) # 800041c0 <end_op>

      if(r != n1){
    800048e0:	009c1f63          	bne	s8,s1,800048fe <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800048e4:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800048e8:	0149db63          	bge	s3,s4,800048fe <filewrite+0xf6>
      int n1 = n - i;
    800048ec:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800048f0:	84be                	mv	s1,a5
    800048f2:	2781                	sext.w	a5,a5
    800048f4:	f8fb5ce3          	bge	s6,a5,8000488c <filewrite+0x84>
    800048f8:	84de                	mv	s1,s7
    800048fa:	bf49                	j	8000488c <filewrite+0x84>
    int i = 0;
    800048fc:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800048fe:	013a1f63          	bne	s4,s3,8000491c <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004902:	8552                	mv	a0,s4
    80004904:	60a6                	ld	ra,72(sp)
    80004906:	6406                	ld	s0,64(sp)
    80004908:	74e2                	ld	s1,56(sp)
    8000490a:	7942                	ld	s2,48(sp)
    8000490c:	79a2                	ld	s3,40(sp)
    8000490e:	7a02                	ld	s4,32(sp)
    80004910:	6ae2                	ld	s5,24(sp)
    80004912:	6b42                	ld	s6,16(sp)
    80004914:	6ba2                	ld	s7,8(sp)
    80004916:	6c02                	ld	s8,0(sp)
    80004918:	6161                	addi	sp,sp,80
    8000491a:	8082                	ret
    ret = (i == n ? n : -1);
    8000491c:	5a7d                	li	s4,-1
    8000491e:	b7d5                	j	80004902 <filewrite+0xfa>
    panic("filewrite");
    80004920:	00004517          	auipc	a0,0x4
    80004924:	dc850513          	addi	a0,a0,-568 # 800086e8 <syscalls+0x270>
    80004928:	ffffc097          	auipc	ra,0xffffc
    8000492c:	c10080e7          	jalr	-1008(ra) # 80000538 <panic>
    return -1;
    80004930:	5a7d                	li	s4,-1
    80004932:	bfc1                	j	80004902 <filewrite+0xfa>
      return -1;
    80004934:	5a7d                	li	s4,-1
    80004936:	b7f1                	j	80004902 <filewrite+0xfa>
    80004938:	5a7d                	li	s4,-1
    8000493a:	b7e1                	j	80004902 <filewrite+0xfa>

000000008000493c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000493c:	7179                	addi	sp,sp,-48
    8000493e:	f406                	sd	ra,40(sp)
    80004940:	f022                	sd	s0,32(sp)
    80004942:	ec26                	sd	s1,24(sp)
    80004944:	e84a                	sd	s2,16(sp)
    80004946:	e44e                	sd	s3,8(sp)
    80004948:	e052                	sd	s4,0(sp)
    8000494a:	1800                	addi	s0,sp,48
    8000494c:	84aa                	mv	s1,a0
    8000494e:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004950:	0005b023          	sd	zero,0(a1)
    80004954:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004958:	00000097          	auipc	ra,0x0
    8000495c:	bf8080e7          	jalr	-1032(ra) # 80004550 <filealloc>
    80004960:	e088                	sd	a0,0(s1)
    80004962:	c551                	beqz	a0,800049ee <pipealloc+0xb2>
    80004964:	00000097          	auipc	ra,0x0
    80004968:	bec080e7          	jalr	-1044(ra) # 80004550 <filealloc>
    8000496c:	00aa3023          	sd	a0,0(s4)
    80004970:	c92d                	beqz	a0,800049e2 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004972:	ffffc097          	auipc	ra,0xffffc
    80004976:	16e080e7          	jalr	366(ra) # 80000ae0 <kalloc>
    8000497a:	892a                	mv	s2,a0
    8000497c:	c125                	beqz	a0,800049dc <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000497e:	4985                	li	s3,1
    80004980:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004984:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004988:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000498c:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004990:	00004597          	auipc	a1,0x4
    80004994:	d6858593          	addi	a1,a1,-664 # 800086f8 <syscalls+0x280>
    80004998:	ffffc097          	auipc	ra,0xffffc
    8000499c:	1a8080e7          	jalr	424(ra) # 80000b40 <initlock>
  (*f0)->type = FD_PIPE;
    800049a0:	609c                	ld	a5,0(s1)
    800049a2:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049a6:	609c                	ld	a5,0(s1)
    800049a8:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049ac:	609c                	ld	a5,0(s1)
    800049ae:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800049b2:	609c                	ld	a5,0(s1)
    800049b4:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800049b8:	000a3783          	ld	a5,0(s4)
    800049bc:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800049c0:	000a3783          	ld	a5,0(s4)
    800049c4:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800049c8:	000a3783          	ld	a5,0(s4)
    800049cc:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800049d0:	000a3783          	ld	a5,0(s4)
    800049d4:	0127b823          	sd	s2,16(a5)
  return 0;
    800049d8:	4501                	li	a0,0
    800049da:	a025                	j	80004a02 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800049dc:	6088                	ld	a0,0(s1)
    800049de:	e501                	bnez	a0,800049e6 <pipealloc+0xaa>
    800049e0:	a039                	j	800049ee <pipealloc+0xb2>
    800049e2:	6088                	ld	a0,0(s1)
    800049e4:	c51d                	beqz	a0,80004a12 <pipealloc+0xd6>
    fileclose(*f0);
    800049e6:	00000097          	auipc	ra,0x0
    800049ea:	c26080e7          	jalr	-986(ra) # 8000460c <fileclose>
  if(*f1)
    800049ee:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800049f2:	557d                	li	a0,-1
  if(*f1)
    800049f4:	c799                	beqz	a5,80004a02 <pipealloc+0xc6>
    fileclose(*f1);
    800049f6:	853e                	mv	a0,a5
    800049f8:	00000097          	auipc	ra,0x0
    800049fc:	c14080e7          	jalr	-1004(ra) # 8000460c <fileclose>
  return -1;
    80004a00:	557d                	li	a0,-1
}
    80004a02:	70a2                	ld	ra,40(sp)
    80004a04:	7402                	ld	s0,32(sp)
    80004a06:	64e2                	ld	s1,24(sp)
    80004a08:	6942                	ld	s2,16(sp)
    80004a0a:	69a2                	ld	s3,8(sp)
    80004a0c:	6a02                	ld	s4,0(sp)
    80004a0e:	6145                	addi	sp,sp,48
    80004a10:	8082                	ret
  return -1;
    80004a12:	557d                	li	a0,-1
    80004a14:	b7fd                	j	80004a02 <pipealloc+0xc6>

0000000080004a16 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a16:	1101                	addi	sp,sp,-32
    80004a18:	ec06                	sd	ra,24(sp)
    80004a1a:	e822                	sd	s0,16(sp)
    80004a1c:	e426                	sd	s1,8(sp)
    80004a1e:	e04a                	sd	s2,0(sp)
    80004a20:	1000                	addi	s0,sp,32
    80004a22:	84aa                	mv	s1,a0
    80004a24:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a26:	ffffc097          	auipc	ra,0xffffc
    80004a2a:	1aa080e7          	jalr	426(ra) # 80000bd0 <acquire>
  if(writable){
    80004a2e:	02090d63          	beqz	s2,80004a68 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a32:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a36:	21848513          	addi	a0,s1,536
    80004a3a:	ffffd097          	auipc	ra,0xffffd
    80004a3e:	7a8080e7          	jalr	1960(ra) # 800021e2 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a42:	2204b783          	ld	a5,544(s1)
    80004a46:	eb95                	bnez	a5,80004a7a <pipeclose+0x64>
    release(&pi->lock);
    80004a48:	8526                	mv	a0,s1
    80004a4a:	ffffc097          	auipc	ra,0xffffc
    80004a4e:	23a080e7          	jalr	570(ra) # 80000c84 <release>
    kfree((char*)pi);
    80004a52:	8526                	mv	a0,s1
    80004a54:	ffffc097          	auipc	ra,0xffffc
    80004a58:	f90080e7          	jalr	-112(ra) # 800009e4 <kfree>
  } else
    release(&pi->lock);
}
    80004a5c:	60e2                	ld	ra,24(sp)
    80004a5e:	6442                	ld	s0,16(sp)
    80004a60:	64a2                	ld	s1,8(sp)
    80004a62:	6902                	ld	s2,0(sp)
    80004a64:	6105                	addi	sp,sp,32
    80004a66:	8082                	ret
    pi->readopen = 0;
    80004a68:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a6c:	21c48513          	addi	a0,s1,540
    80004a70:	ffffd097          	auipc	ra,0xffffd
    80004a74:	772080e7          	jalr	1906(ra) # 800021e2 <wakeup>
    80004a78:	b7e9                	j	80004a42 <pipeclose+0x2c>
    release(&pi->lock);
    80004a7a:	8526                	mv	a0,s1
    80004a7c:	ffffc097          	auipc	ra,0xffffc
    80004a80:	208080e7          	jalr	520(ra) # 80000c84 <release>
}
    80004a84:	bfe1                	j	80004a5c <pipeclose+0x46>

0000000080004a86 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a86:	711d                	addi	sp,sp,-96
    80004a88:	ec86                	sd	ra,88(sp)
    80004a8a:	e8a2                	sd	s0,80(sp)
    80004a8c:	e4a6                	sd	s1,72(sp)
    80004a8e:	e0ca                	sd	s2,64(sp)
    80004a90:	fc4e                	sd	s3,56(sp)
    80004a92:	f852                	sd	s4,48(sp)
    80004a94:	f456                	sd	s5,40(sp)
    80004a96:	f05a                	sd	s6,32(sp)
    80004a98:	ec5e                	sd	s7,24(sp)
    80004a9a:	e862                	sd	s8,16(sp)
    80004a9c:	1080                	addi	s0,sp,96
    80004a9e:	84aa                	mv	s1,a0
    80004aa0:	8aae                	mv	s5,a1
    80004aa2:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004aa4:	ffffd097          	auipc	ra,0xffffd
    80004aa8:	ef2080e7          	jalr	-270(ra) # 80001996 <myproc>
    80004aac:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004aae:	8526                	mv	a0,s1
    80004ab0:	ffffc097          	auipc	ra,0xffffc
    80004ab4:	120080e7          	jalr	288(ra) # 80000bd0 <acquire>
  while(i < n){
    80004ab8:	0b405363          	blez	s4,80004b5e <pipewrite+0xd8>
  int i = 0;
    80004abc:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004abe:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004ac0:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004ac4:	21c48b93          	addi	s7,s1,540
    80004ac8:	a089                	j	80004b0a <pipewrite+0x84>
      release(&pi->lock);
    80004aca:	8526                	mv	a0,s1
    80004acc:	ffffc097          	auipc	ra,0xffffc
    80004ad0:	1b8080e7          	jalr	440(ra) # 80000c84 <release>
      return -1;
    80004ad4:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004ad6:	854a                	mv	a0,s2
    80004ad8:	60e6                	ld	ra,88(sp)
    80004ada:	6446                	ld	s0,80(sp)
    80004adc:	64a6                	ld	s1,72(sp)
    80004ade:	6906                	ld	s2,64(sp)
    80004ae0:	79e2                	ld	s3,56(sp)
    80004ae2:	7a42                	ld	s4,48(sp)
    80004ae4:	7aa2                	ld	s5,40(sp)
    80004ae6:	7b02                	ld	s6,32(sp)
    80004ae8:	6be2                	ld	s7,24(sp)
    80004aea:	6c42                	ld	s8,16(sp)
    80004aec:	6125                	addi	sp,sp,96
    80004aee:	8082                	ret
      wakeup(&pi->nread);
    80004af0:	8562                	mv	a0,s8
    80004af2:	ffffd097          	auipc	ra,0xffffd
    80004af6:	6f0080e7          	jalr	1776(ra) # 800021e2 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004afa:	85a6                	mv	a1,s1
    80004afc:	855e                	mv	a0,s7
    80004afe:	ffffd097          	auipc	ra,0xffffd
    80004b02:	558080e7          	jalr	1368(ra) # 80002056 <sleep>
  while(i < n){
    80004b06:	05495d63          	bge	s2,s4,80004b60 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004b0a:	2204a783          	lw	a5,544(s1)
    80004b0e:	dfd5                	beqz	a5,80004aca <pipewrite+0x44>
    80004b10:	0289a783          	lw	a5,40(s3)
    80004b14:	fbdd                	bnez	a5,80004aca <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b16:	2184a783          	lw	a5,536(s1)
    80004b1a:	21c4a703          	lw	a4,540(s1)
    80004b1e:	2007879b          	addiw	a5,a5,512
    80004b22:	fcf707e3          	beq	a4,a5,80004af0 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b26:	4685                	li	a3,1
    80004b28:	01590633          	add	a2,s2,s5
    80004b2c:	faf40593          	addi	a1,s0,-81
    80004b30:	0509b503          	ld	a0,80(s3)
    80004b34:	ffffd097          	auipc	ra,0xffffd
    80004b38:	bae080e7          	jalr	-1106(ra) # 800016e2 <copyin>
    80004b3c:	03650263          	beq	a0,s6,80004b60 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b40:	21c4a783          	lw	a5,540(s1)
    80004b44:	0017871b          	addiw	a4,a5,1
    80004b48:	20e4ae23          	sw	a4,540(s1)
    80004b4c:	1ff7f793          	andi	a5,a5,511
    80004b50:	97a6                	add	a5,a5,s1
    80004b52:	faf44703          	lbu	a4,-81(s0)
    80004b56:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b5a:	2905                	addiw	s2,s2,1
    80004b5c:	b76d                	j	80004b06 <pipewrite+0x80>
  int i = 0;
    80004b5e:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004b60:	21848513          	addi	a0,s1,536
    80004b64:	ffffd097          	auipc	ra,0xffffd
    80004b68:	67e080e7          	jalr	1662(ra) # 800021e2 <wakeup>
  release(&pi->lock);
    80004b6c:	8526                	mv	a0,s1
    80004b6e:	ffffc097          	auipc	ra,0xffffc
    80004b72:	116080e7          	jalr	278(ra) # 80000c84 <release>
  return i;
    80004b76:	b785                	j	80004ad6 <pipewrite+0x50>

0000000080004b78 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b78:	715d                	addi	sp,sp,-80
    80004b7a:	e486                	sd	ra,72(sp)
    80004b7c:	e0a2                	sd	s0,64(sp)
    80004b7e:	fc26                	sd	s1,56(sp)
    80004b80:	f84a                	sd	s2,48(sp)
    80004b82:	f44e                	sd	s3,40(sp)
    80004b84:	f052                	sd	s4,32(sp)
    80004b86:	ec56                	sd	s5,24(sp)
    80004b88:	e85a                	sd	s6,16(sp)
    80004b8a:	0880                	addi	s0,sp,80
    80004b8c:	84aa                	mv	s1,a0
    80004b8e:	892e                	mv	s2,a1
    80004b90:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b92:	ffffd097          	auipc	ra,0xffffd
    80004b96:	e04080e7          	jalr	-508(ra) # 80001996 <myproc>
    80004b9a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b9c:	8526                	mv	a0,s1
    80004b9e:	ffffc097          	auipc	ra,0xffffc
    80004ba2:	032080e7          	jalr	50(ra) # 80000bd0 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ba6:	2184a703          	lw	a4,536(s1)
    80004baa:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bae:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bb2:	02f71463          	bne	a4,a5,80004bda <piperead+0x62>
    80004bb6:	2244a783          	lw	a5,548(s1)
    80004bba:	c385                	beqz	a5,80004bda <piperead+0x62>
    if(pr->killed){
    80004bbc:	028a2783          	lw	a5,40(s4)
    80004bc0:	ebc1                	bnez	a5,80004c50 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bc2:	85a6                	mv	a1,s1
    80004bc4:	854e                	mv	a0,s3
    80004bc6:	ffffd097          	auipc	ra,0xffffd
    80004bca:	490080e7          	jalr	1168(ra) # 80002056 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bce:	2184a703          	lw	a4,536(s1)
    80004bd2:	21c4a783          	lw	a5,540(s1)
    80004bd6:	fef700e3          	beq	a4,a5,80004bb6 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bda:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bdc:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bde:	05505363          	blez	s5,80004c24 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004be2:	2184a783          	lw	a5,536(s1)
    80004be6:	21c4a703          	lw	a4,540(s1)
    80004bea:	02f70d63          	beq	a4,a5,80004c24 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004bee:	0017871b          	addiw	a4,a5,1
    80004bf2:	20e4ac23          	sw	a4,536(s1)
    80004bf6:	1ff7f793          	andi	a5,a5,511
    80004bfa:	97a6                	add	a5,a5,s1
    80004bfc:	0187c783          	lbu	a5,24(a5)
    80004c00:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c04:	4685                	li	a3,1
    80004c06:	fbf40613          	addi	a2,s0,-65
    80004c0a:	85ca                	mv	a1,s2
    80004c0c:	050a3503          	ld	a0,80(s4)
    80004c10:	ffffd097          	auipc	ra,0xffffd
    80004c14:	a46080e7          	jalr	-1466(ra) # 80001656 <copyout>
    80004c18:	01650663          	beq	a0,s6,80004c24 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c1c:	2985                	addiw	s3,s3,1
    80004c1e:	0905                	addi	s2,s2,1
    80004c20:	fd3a91e3          	bne	s5,s3,80004be2 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c24:	21c48513          	addi	a0,s1,540
    80004c28:	ffffd097          	auipc	ra,0xffffd
    80004c2c:	5ba080e7          	jalr	1466(ra) # 800021e2 <wakeup>
  release(&pi->lock);
    80004c30:	8526                	mv	a0,s1
    80004c32:	ffffc097          	auipc	ra,0xffffc
    80004c36:	052080e7          	jalr	82(ra) # 80000c84 <release>
  return i;
}
    80004c3a:	854e                	mv	a0,s3
    80004c3c:	60a6                	ld	ra,72(sp)
    80004c3e:	6406                	ld	s0,64(sp)
    80004c40:	74e2                	ld	s1,56(sp)
    80004c42:	7942                	ld	s2,48(sp)
    80004c44:	79a2                	ld	s3,40(sp)
    80004c46:	7a02                	ld	s4,32(sp)
    80004c48:	6ae2                	ld	s5,24(sp)
    80004c4a:	6b42                	ld	s6,16(sp)
    80004c4c:	6161                	addi	sp,sp,80
    80004c4e:	8082                	ret
      release(&pi->lock);
    80004c50:	8526                	mv	a0,s1
    80004c52:	ffffc097          	auipc	ra,0xffffc
    80004c56:	032080e7          	jalr	50(ra) # 80000c84 <release>
      return -1;
    80004c5a:	59fd                	li	s3,-1
    80004c5c:	bff9                	j	80004c3a <piperead+0xc2>

0000000080004c5e <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004c5e:	de010113          	addi	sp,sp,-544
    80004c62:	20113c23          	sd	ra,536(sp)
    80004c66:	20813823          	sd	s0,528(sp)
    80004c6a:	20913423          	sd	s1,520(sp)
    80004c6e:	21213023          	sd	s2,512(sp)
    80004c72:	ffce                	sd	s3,504(sp)
    80004c74:	fbd2                	sd	s4,496(sp)
    80004c76:	f7d6                	sd	s5,488(sp)
    80004c78:	f3da                	sd	s6,480(sp)
    80004c7a:	efde                	sd	s7,472(sp)
    80004c7c:	ebe2                	sd	s8,464(sp)
    80004c7e:	e7e6                	sd	s9,456(sp)
    80004c80:	e3ea                	sd	s10,448(sp)
    80004c82:	ff6e                	sd	s11,440(sp)
    80004c84:	1400                	addi	s0,sp,544
    80004c86:	892a                	mv	s2,a0
    80004c88:	dea43423          	sd	a0,-536(s0)
    80004c8c:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c90:	ffffd097          	auipc	ra,0xffffd
    80004c94:	d06080e7          	jalr	-762(ra) # 80001996 <myproc>
    80004c98:	84aa                	mv	s1,a0

  begin_op();
    80004c9a:	fffff097          	auipc	ra,0xfffff
    80004c9e:	4a6080e7          	jalr	1190(ra) # 80004140 <begin_op>

  if((ip = namei(path)) == 0){
    80004ca2:	854a                	mv	a0,s2
    80004ca4:	fffff097          	auipc	ra,0xfffff
    80004ca8:	280080e7          	jalr	640(ra) # 80003f24 <namei>
    80004cac:	c93d                	beqz	a0,80004d22 <exec+0xc4>
    80004cae:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004cb0:	fffff097          	auipc	ra,0xfffff
    80004cb4:	abe080e7          	jalr	-1346(ra) # 8000376e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004cb8:	04000713          	li	a4,64
    80004cbc:	4681                	li	a3,0
    80004cbe:	e5040613          	addi	a2,s0,-432
    80004cc2:	4581                	li	a1,0
    80004cc4:	8556                	mv	a0,s5
    80004cc6:	fffff097          	auipc	ra,0xfffff
    80004cca:	d5c080e7          	jalr	-676(ra) # 80003a22 <readi>
    80004cce:	04000793          	li	a5,64
    80004cd2:	00f51a63          	bne	a0,a5,80004ce6 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004cd6:	e5042703          	lw	a4,-432(s0)
    80004cda:	464c47b7          	lui	a5,0x464c4
    80004cde:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004ce2:	04f70663          	beq	a4,a5,80004d2e <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004ce6:	8556                	mv	a0,s5
    80004ce8:	fffff097          	auipc	ra,0xfffff
    80004cec:	ce8080e7          	jalr	-792(ra) # 800039d0 <iunlockput>
    end_op();
    80004cf0:	fffff097          	auipc	ra,0xfffff
    80004cf4:	4d0080e7          	jalr	1232(ra) # 800041c0 <end_op>
  }
  return -1;
    80004cf8:	557d                	li	a0,-1
}
    80004cfa:	21813083          	ld	ra,536(sp)
    80004cfe:	21013403          	ld	s0,528(sp)
    80004d02:	20813483          	ld	s1,520(sp)
    80004d06:	20013903          	ld	s2,512(sp)
    80004d0a:	79fe                	ld	s3,504(sp)
    80004d0c:	7a5e                	ld	s4,496(sp)
    80004d0e:	7abe                	ld	s5,488(sp)
    80004d10:	7b1e                	ld	s6,480(sp)
    80004d12:	6bfe                	ld	s7,472(sp)
    80004d14:	6c5e                	ld	s8,464(sp)
    80004d16:	6cbe                	ld	s9,456(sp)
    80004d18:	6d1e                	ld	s10,448(sp)
    80004d1a:	7dfa                	ld	s11,440(sp)
    80004d1c:	22010113          	addi	sp,sp,544
    80004d20:	8082                	ret
    end_op();
    80004d22:	fffff097          	auipc	ra,0xfffff
    80004d26:	49e080e7          	jalr	1182(ra) # 800041c0 <end_op>
    return -1;
    80004d2a:	557d                	li	a0,-1
    80004d2c:	b7f9                	j	80004cfa <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d2e:	8526                	mv	a0,s1
    80004d30:	ffffd097          	auipc	ra,0xffffd
    80004d34:	d2a080e7          	jalr	-726(ra) # 80001a5a <proc_pagetable>
    80004d38:	8b2a                	mv	s6,a0
    80004d3a:	d555                	beqz	a0,80004ce6 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d3c:	e7042783          	lw	a5,-400(s0)
    80004d40:	e8845703          	lhu	a4,-376(s0)
    80004d44:	c735                	beqz	a4,80004db0 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d46:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d48:	e0043423          	sd	zero,-504(s0)
    if((ph.vaddr % PGSIZE) != 0)
    80004d4c:	6a05                	lui	s4,0x1
    80004d4e:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004d52:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004d56:	6d85                	lui	s11,0x1
    80004d58:	7d7d                	lui	s10,0xfffff
    80004d5a:	ac1d                	j	80004f90 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d5c:	00004517          	auipc	a0,0x4
    80004d60:	9a450513          	addi	a0,a0,-1628 # 80008700 <syscalls+0x288>
    80004d64:	ffffb097          	auipc	ra,0xffffb
    80004d68:	7d4080e7          	jalr	2004(ra) # 80000538 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d6c:	874a                	mv	a4,s2
    80004d6e:	009c86bb          	addw	a3,s9,s1
    80004d72:	4581                	li	a1,0
    80004d74:	8556                	mv	a0,s5
    80004d76:	fffff097          	auipc	ra,0xfffff
    80004d7a:	cac080e7          	jalr	-852(ra) # 80003a22 <readi>
    80004d7e:	2501                	sext.w	a0,a0
    80004d80:	1aa91863          	bne	s2,a0,80004f30 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004d84:	009d84bb          	addw	s1,s11,s1
    80004d88:	013d09bb          	addw	s3,s10,s3
    80004d8c:	1f74f263          	bgeu	s1,s7,80004f70 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004d90:	02049593          	slli	a1,s1,0x20
    80004d94:	9181                	srli	a1,a1,0x20
    80004d96:	95e2                	add	a1,a1,s8
    80004d98:	855a                	mv	a0,s6
    80004d9a:	ffffc097          	auipc	ra,0xffffc
    80004d9e:	2b8080e7          	jalr	696(ra) # 80001052 <walkaddr>
    80004da2:	862a                	mv	a2,a0
    if(pa == 0)
    80004da4:	dd45                	beqz	a0,80004d5c <exec+0xfe>
      n = PGSIZE;
    80004da6:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004da8:	fd49f2e3          	bgeu	s3,s4,80004d6c <exec+0x10e>
      n = sz - i;
    80004dac:	894e                	mv	s2,s3
    80004dae:	bf7d                	j	80004d6c <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004db0:	4481                	li	s1,0
  iunlockput(ip);
    80004db2:	8556                	mv	a0,s5
    80004db4:	fffff097          	auipc	ra,0xfffff
    80004db8:	c1c080e7          	jalr	-996(ra) # 800039d0 <iunlockput>
  end_op();
    80004dbc:	fffff097          	auipc	ra,0xfffff
    80004dc0:	404080e7          	jalr	1028(ra) # 800041c0 <end_op>
  p = myproc();
    80004dc4:	ffffd097          	auipc	ra,0xffffd
    80004dc8:	bd2080e7          	jalr	-1070(ra) # 80001996 <myproc>
    80004dcc:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004dce:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004dd2:	6785                	lui	a5,0x1
    80004dd4:	17fd                	addi	a5,a5,-1
    80004dd6:	94be                	add	s1,s1,a5
    80004dd8:	77fd                	lui	a5,0xfffff
    80004dda:	8fe5                	and	a5,a5,s1
    80004ddc:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004de0:	6609                	lui	a2,0x2
    80004de2:	963e                	add	a2,a2,a5
    80004de4:	85be                	mv	a1,a5
    80004de6:	855a                	mv	a0,s6
    80004de8:	ffffc097          	auipc	ra,0xffffc
    80004dec:	61e080e7          	jalr	1566(ra) # 80001406 <uvmalloc>
    80004df0:	8c2a                	mv	s8,a0
  ip = 0;
    80004df2:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004df4:	12050e63          	beqz	a0,80004f30 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004df8:	75f9                	lui	a1,0xffffe
    80004dfa:	95aa                	add	a1,a1,a0
    80004dfc:	855a                	mv	a0,s6
    80004dfe:	ffffd097          	auipc	ra,0xffffd
    80004e02:	826080e7          	jalr	-2010(ra) # 80001624 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e06:	7afd                	lui	s5,0xfffff
    80004e08:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e0a:	df043783          	ld	a5,-528(s0)
    80004e0e:	6388                	ld	a0,0(a5)
    80004e10:	c925                	beqz	a0,80004e80 <exec+0x222>
    80004e12:	e9040993          	addi	s3,s0,-368
    80004e16:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004e1a:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e1c:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004e1e:	ffffc097          	auipc	ra,0xffffc
    80004e22:	02a080e7          	jalr	42(ra) # 80000e48 <strlen>
    80004e26:	0015079b          	addiw	a5,a0,1
    80004e2a:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e2e:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e32:	13596363          	bltu	s2,s5,80004f58 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e36:	df043d83          	ld	s11,-528(s0)
    80004e3a:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004e3e:	8552                	mv	a0,s4
    80004e40:	ffffc097          	auipc	ra,0xffffc
    80004e44:	008080e7          	jalr	8(ra) # 80000e48 <strlen>
    80004e48:	0015069b          	addiw	a3,a0,1
    80004e4c:	8652                	mv	a2,s4
    80004e4e:	85ca                	mv	a1,s2
    80004e50:	855a                	mv	a0,s6
    80004e52:	ffffd097          	auipc	ra,0xffffd
    80004e56:	804080e7          	jalr	-2044(ra) # 80001656 <copyout>
    80004e5a:	10054363          	bltz	a0,80004f60 <exec+0x302>
    ustack[argc] = sp;
    80004e5e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e62:	0485                	addi	s1,s1,1
    80004e64:	008d8793          	addi	a5,s11,8
    80004e68:	def43823          	sd	a5,-528(s0)
    80004e6c:	008db503          	ld	a0,8(s11)
    80004e70:	c911                	beqz	a0,80004e84 <exec+0x226>
    if(argc >= MAXARG)
    80004e72:	09a1                	addi	s3,s3,8
    80004e74:	fb3c95e3          	bne	s9,s3,80004e1e <exec+0x1c0>
  sz = sz1;
    80004e78:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e7c:	4a81                	li	s5,0
    80004e7e:	a84d                	j	80004f30 <exec+0x2d2>
  sp = sz;
    80004e80:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e82:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e84:	00349793          	slli	a5,s1,0x3
    80004e88:	f9040713          	addi	a4,s0,-112
    80004e8c:	97ba                	add	a5,a5,a4
    80004e8e:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffd8f00>
  sp -= (argc+1) * sizeof(uint64);
    80004e92:	00148693          	addi	a3,s1,1
    80004e96:	068e                	slli	a3,a3,0x3
    80004e98:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004e9c:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004ea0:	01597663          	bgeu	s2,s5,80004eac <exec+0x24e>
  sz = sz1;
    80004ea4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ea8:	4a81                	li	s5,0
    80004eaa:	a059                	j	80004f30 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004eac:	e9040613          	addi	a2,s0,-368
    80004eb0:	85ca                	mv	a1,s2
    80004eb2:	855a                	mv	a0,s6
    80004eb4:	ffffc097          	auipc	ra,0xffffc
    80004eb8:	7a2080e7          	jalr	1954(ra) # 80001656 <copyout>
    80004ebc:	0a054663          	bltz	a0,80004f68 <exec+0x30a>
  p->trapframe->a1 = sp;
    80004ec0:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004ec4:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004ec8:	de843783          	ld	a5,-536(s0)
    80004ecc:	0007c703          	lbu	a4,0(a5)
    80004ed0:	cf11                	beqz	a4,80004eec <exec+0x28e>
    80004ed2:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004ed4:	02f00693          	li	a3,47
    80004ed8:	a039                	j	80004ee6 <exec+0x288>
      last = s+1;
    80004eda:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004ede:	0785                	addi	a5,a5,1
    80004ee0:	fff7c703          	lbu	a4,-1(a5)
    80004ee4:	c701                	beqz	a4,80004eec <exec+0x28e>
    if(*s == '/')
    80004ee6:	fed71ce3          	bne	a4,a3,80004ede <exec+0x280>
    80004eea:	bfc5                	j	80004eda <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004eec:	4641                	li	a2,16
    80004eee:	de843583          	ld	a1,-536(s0)
    80004ef2:	158b8513          	addi	a0,s7,344
    80004ef6:	ffffc097          	auipc	ra,0xffffc
    80004efa:	f20080e7          	jalr	-224(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    80004efe:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004f02:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004f06:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f0a:	058bb783          	ld	a5,88(s7)
    80004f0e:	e6843703          	ld	a4,-408(s0)
    80004f12:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f14:	058bb783          	ld	a5,88(s7)
    80004f18:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f1c:	85ea                	mv	a1,s10
    80004f1e:	ffffd097          	auipc	ra,0xffffd
    80004f22:	bd8080e7          	jalr	-1064(ra) # 80001af6 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f26:	0004851b          	sext.w	a0,s1
    80004f2a:	bbc1                	j	80004cfa <exec+0x9c>
    80004f2c:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004f30:	df843583          	ld	a1,-520(s0)
    80004f34:	855a                	mv	a0,s6
    80004f36:	ffffd097          	auipc	ra,0xffffd
    80004f3a:	bc0080e7          	jalr	-1088(ra) # 80001af6 <proc_freepagetable>
  if(ip){
    80004f3e:	da0a94e3          	bnez	s5,80004ce6 <exec+0x88>
  return -1;
    80004f42:	557d                	li	a0,-1
    80004f44:	bb5d                	j	80004cfa <exec+0x9c>
    80004f46:	de943c23          	sd	s1,-520(s0)
    80004f4a:	b7dd                	j	80004f30 <exec+0x2d2>
    80004f4c:	de943c23          	sd	s1,-520(s0)
    80004f50:	b7c5                	j	80004f30 <exec+0x2d2>
    80004f52:	de943c23          	sd	s1,-520(s0)
    80004f56:	bfe9                	j	80004f30 <exec+0x2d2>
  sz = sz1;
    80004f58:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f5c:	4a81                	li	s5,0
    80004f5e:	bfc9                	j	80004f30 <exec+0x2d2>
  sz = sz1;
    80004f60:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f64:	4a81                	li	s5,0
    80004f66:	b7e9                	j	80004f30 <exec+0x2d2>
  sz = sz1;
    80004f68:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f6c:	4a81                	li	s5,0
    80004f6e:	b7c9                	j	80004f30 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f70:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f74:	e0843783          	ld	a5,-504(s0)
    80004f78:	0017869b          	addiw	a3,a5,1
    80004f7c:	e0d43423          	sd	a3,-504(s0)
    80004f80:	e0043783          	ld	a5,-512(s0)
    80004f84:	0387879b          	addiw	a5,a5,56
    80004f88:	e8845703          	lhu	a4,-376(s0)
    80004f8c:	e2e6d3e3          	bge	a3,a4,80004db2 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f90:	2781                	sext.w	a5,a5
    80004f92:	e0f43023          	sd	a5,-512(s0)
    80004f96:	03800713          	li	a4,56
    80004f9a:	86be                	mv	a3,a5
    80004f9c:	e1840613          	addi	a2,s0,-488
    80004fa0:	4581                	li	a1,0
    80004fa2:	8556                	mv	a0,s5
    80004fa4:	fffff097          	auipc	ra,0xfffff
    80004fa8:	a7e080e7          	jalr	-1410(ra) # 80003a22 <readi>
    80004fac:	03800793          	li	a5,56
    80004fb0:	f6f51ee3          	bne	a0,a5,80004f2c <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80004fb4:	e1842783          	lw	a5,-488(s0)
    80004fb8:	4705                	li	a4,1
    80004fba:	fae79de3          	bne	a5,a4,80004f74 <exec+0x316>
    if(ph.memsz < ph.filesz)
    80004fbe:	e4043603          	ld	a2,-448(s0)
    80004fc2:	e3843783          	ld	a5,-456(s0)
    80004fc6:	f8f660e3          	bltu	a2,a5,80004f46 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004fca:	e2843783          	ld	a5,-472(s0)
    80004fce:	963e                	add	a2,a2,a5
    80004fd0:	f6f66ee3          	bltu	a2,a5,80004f4c <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004fd4:	85a6                	mv	a1,s1
    80004fd6:	855a                	mv	a0,s6
    80004fd8:	ffffc097          	auipc	ra,0xffffc
    80004fdc:	42e080e7          	jalr	1070(ra) # 80001406 <uvmalloc>
    80004fe0:	dea43c23          	sd	a0,-520(s0)
    80004fe4:	d53d                	beqz	a0,80004f52 <exec+0x2f4>
    if((ph.vaddr % PGSIZE) != 0)
    80004fe6:	e2843c03          	ld	s8,-472(s0)
    80004fea:	de043783          	ld	a5,-544(s0)
    80004fee:	00fc77b3          	and	a5,s8,a5
    80004ff2:	ff9d                	bnez	a5,80004f30 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004ff4:	e2042c83          	lw	s9,-480(s0)
    80004ff8:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004ffc:	f60b8ae3          	beqz	s7,80004f70 <exec+0x312>
    80005000:	89de                	mv	s3,s7
    80005002:	4481                	li	s1,0
    80005004:	b371                	j	80004d90 <exec+0x132>

0000000080005006 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005006:	7179                	addi	sp,sp,-48
    80005008:	f406                	sd	ra,40(sp)
    8000500a:	f022                	sd	s0,32(sp)
    8000500c:	ec26                	sd	s1,24(sp)
    8000500e:	e84a                	sd	s2,16(sp)
    80005010:	1800                	addi	s0,sp,48
    80005012:	892e                	mv	s2,a1
    80005014:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005016:	fdc40593          	addi	a1,s0,-36
    8000501a:	ffffe097          	auipc	ra,0xffffe
    8000501e:	af2080e7          	jalr	-1294(ra) # 80002b0c <argint>
    80005022:	04054063          	bltz	a0,80005062 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005026:	fdc42703          	lw	a4,-36(s0)
    8000502a:	47bd                	li	a5,15
    8000502c:	02e7ed63          	bltu	a5,a4,80005066 <argfd+0x60>
    80005030:	ffffd097          	auipc	ra,0xffffd
    80005034:	966080e7          	jalr	-1690(ra) # 80001996 <myproc>
    80005038:	fdc42703          	lw	a4,-36(s0)
    8000503c:	01a70793          	addi	a5,a4,26
    80005040:	078e                	slli	a5,a5,0x3
    80005042:	953e                	add	a0,a0,a5
    80005044:	611c                	ld	a5,0(a0)
    80005046:	c395                	beqz	a5,8000506a <argfd+0x64>
    return -1;
  if(pfd)
    80005048:	00090463          	beqz	s2,80005050 <argfd+0x4a>
    *pfd = fd;
    8000504c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005050:	4501                	li	a0,0
  if(pf)
    80005052:	c091                	beqz	s1,80005056 <argfd+0x50>
    *pf = f;
    80005054:	e09c                	sd	a5,0(s1)
}
    80005056:	70a2                	ld	ra,40(sp)
    80005058:	7402                	ld	s0,32(sp)
    8000505a:	64e2                	ld	s1,24(sp)
    8000505c:	6942                	ld	s2,16(sp)
    8000505e:	6145                	addi	sp,sp,48
    80005060:	8082                	ret
    return -1;
    80005062:	557d                	li	a0,-1
    80005064:	bfcd                	j	80005056 <argfd+0x50>
    return -1;
    80005066:	557d                	li	a0,-1
    80005068:	b7fd                	j	80005056 <argfd+0x50>
    8000506a:	557d                	li	a0,-1
    8000506c:	b7ed                	j	80005056 <argfd+0x50>

000000008000506e <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000506e:	1101                	addi	sp,sp,-32
    80005070:	ec06                	sd	ra,24(sp)
    80005072:	e822                	sd	s0,16(sp)
    80005074:	e426                	sd	s1,8(sp)
    80005076:	1000                	addi	s0,sp,32
    80005078:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000507a:	ffffd097          	auipc	ra,0xffffd
    8000507e:	91c080e7          	jalr	-1764(ra) # 80001996 <myproc>
    80005082:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005084:	0d050793          	addi	a5,a0,208
    80005088:	4501                	li	a0,0
    8000508a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000508c:	6398                	ld	a4,0(a5)
    8000508e:	cb19                	beqz	a4,800050a4 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005090:	2505                	addiw	a0,a0,1
    80005092:	07a1                	addi	a5,a5,8
    80005094:	fed51ce3          	bne	a0,a3,8000508c <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005098:	557d                	li	a0,-1
}
    8000509a:	60e2                	ld	ra,24(sp)
    8000509c:	6442                	ld	s0,16(sp)
    8000509e:	64a2                	ld	s1,8(sp)
    800050a0:	6105                	addi	sp,sp,32
    800050a2:	8082                	ret
      p->ofile[fd] = f;
    800050a4:	01a50793          	addi	a5,a0,26
    800050a8:	078e                	slli	a5,a5,0x3
    800050aa:	963e                	add	a2,a2,a5
    800050ac:	e204                	sd	s1,0(a2)
      return fd;
    800050ae:	b7f5                	j	8000509a <fdalloc+0x2c>

00000000800050b0 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050b0:	715d                	addi	sp,sp,-80
    800050b2:	e486                	sd	ra,72(sp)
    800050b4:	e0a2                	sd	s0,64(sp)
    800050b6:	fc26                	sd	s1,56(sp)
    800050b8:	f84a                	sd	s2,48(sp)
    800050ba:	f44e                	sd	s3,40(sp)
    800050bc:	f052                	sd	s4,32(sp)
    800050be:	ec56                	sd	s5,24(sp)
    800050c0:	0880                	addi	s0,sp,80
    800050c2:	89ae                	mv	s3,a1
    800050c4:	8ab2                	mv	s5,a2
    800050c6:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800050c8:	fb040593          	addi	a1,s0,-80
    800050cc:	fffff097          	auipc	ra,0xfffff
    800050d0:	e76080e7          	jalr	-394(ra) # 80003f42 <nameiparent>
    800050d4:	892a                	mv	s2,a0
    800050d6:	12050e63          	beqz	a0,80005212 <create+0x162>
    return 0;

  ilock(dp);
    800050da:	ffffe097          	auipc	ra,0xffffe
    800050de:	694080e7          	jalr	1684(ra) # 8000376e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800050e2:	4601                	li	a2,0
    800050e4:	fb040593          	addi	a1,s0,-80
    800050e8:	854a                	mv	a0,s2
    800050ea:	fffff097          	auipc	ra,0xfffff
    800050ee:	b68080e7          	jalr	-1176(ra) # 80003c52 <dirlookup>
    800050f2:	84aa                	mv	s1,a0
    800050f4:	c921                	beqz	a0,80005144 <create+0x94>
    iunlockput(dp);
    800050f6:	854a                	mv	a0,s2
    800050f8:	fffff097          	auipc	ra,0xfffff
    800050fc:	8d8080e7          	jalr	-1832(ra) # 800039d0 <iunlockput>
    ilock(ip);
    80005100:	8526                	mv	a0,s1
    80005102:	ffffe097          	auipc	ra,0xffffe
    80005106:	66c080e7          	jalr	1644(ra) # 8000376e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000510a:	2981                	sext.w	s3,s3
    8000510c:	4789                	li	a5,2
    8000510e:	02f99463          	bne	s3,a5,80005136 <create+0x86>
    80005112:	0444d783          	lhu	a5,68(s1)
    80005116:	37f9                	addiw	a5,a5,-2
    80005118:	17c2                	slli	a5,a5,0x30
    8000511a:	93c1                	srli	a5,a5,0x30
    8000511c:	4705                	li	a4,1
    8000511e:	00f76c63          	bltu	a4,a5,80005136 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005122:	8526                	mv	a0,s1
    80005124:	60a6                	ld	ra,72(sp)
    80005126:	6406                	ld	s0,64(sp)
    80005128:	74e2                	ld	s1,56(sp)
    8000512a:	7942                	ld	s2,48(sp)
    8000512c:	79a2                	ld	s3,40(sp)
    8000512e:	7a02                	ld	s4,32(sp)
    80005130:	6ae2                	ld	s5,24(sp)
    80005132:	6161                	addi	sp,sp,80
    80005134:	8082                	ret
    iunlockput(ip);
    80005136:	8526                	mv	a0,s1
    80005138:	fffff097          	auipc	ra,0xfffff
    8000513c:	898080e7          	jalr	-1896(ra) # 800039d0 <iunlockput>
    return 0;
    80005140:	4481                	li	s1,0
    80005142:	b7c5                	j	80005122 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005144:	85ce                	mv	a1,s3
    80005146:	00092503          	lw	a0,0(s2)
    8000514a:	ffffe097          	auipc	ra,0xffffe
    8000514e:	48c080e7          	jalr	1164(ra) # 800035d6 <ialloc>
    80005152:	84aa                	mv	s1,a0
    80005154:	c521                	beqz	a0,8000519c <create+0xec>
  ilock(ip);
    80005156:	ffffe097          	auipc	ra,0xffffe
    8000515a:	618080e7          	jalr	1560(ra) # 8000376e <ilock>
  ip->major = major;
    8000515e:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005162:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005166:	4a05                	li	s4,1
    80005168:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    8000516c:	8526                	mv	a0,s1
    8000516e:	ffffe097          	auipc	ra,0xffffe
    80005172:	536080e7          	jalr	1334(ra) # 800036a4 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005176:	2981                	sext.w	s3,s3
    80005178:	03498a63          	beq	s3,s4,800051ac <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    8000517c:	40d0                	lw	a2,4(s1)
    8000517e:	fb040593          	addi	a1,s0,-80
    80005182:	854a                	mv	a0,s2
    80005184:	fffff097          	auipc	ra,0xfffff
    80005188:	cde080e7          	jalr	-802(ra) # 80003e62 <dirlink>
    8000518c:	06054b63          	bltz	a0,80005202 <create+0x152>
  iunlockput(dp);
    80005190:	854a                	mv	a0,s2
    80005192:	fffff097          	auipc	ra,0xfffff
    80005196:	83e080e7          	jalr	-1986(ra) # 800039d0 <iunlockput>
  return ip;
    8000519a:	b761                	j	80005122 <create+0x72>
    panic("create: ialloc");
    8000519c:	00003517          	auipc	a0,0x3
    800051a0:	58450513          	addi	a0,a0,1412 # 80008720 <syscalls+0x2a8>
    800051a4:	ffffb097          	auipc	ra,0xffffb
    800051a8:	394080e7          	jalr	916(ra) # 80000538 <panic>
    dp->nlink++;  // for ".."
    800051ac:	04a95783          	lhu	a5,74(s2)
    800051b0:	2785                	addiw	a5,a5,1
    800051b2:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800051b6:	854a                	mv	a0,s2
    800051b8:	ffffe097          	auipc	ra,0xffffe
    800051bc:	4ec080e7          	jalr	1260(ra) # 800036a4 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800051c0:	40d0                	lw	a2,4(s1)
    800051c2:	00003597          	auipc	a1,0x3
    800051c6:	56e58593          	addi	a1,a1,1390 # 80008730 <syscalls+0x2b8>
    800051ca:	8526                	mv	a0,s1
    800051cc:	fffff097          	auipc	ra,0xfffff
    800051d0:	c96080e7          	jalr	-874(ra) # 80003e62 <dirlink>
    800051d4:	00054f63          	bltz	a0,800051f2 <create+0x142>
    800051d8:	00492603          	lw	a2,4(s2)
    800051dc:	00003597          	auipc	a1,0x3
    800051e0:	55c58593          	addi	a1,a1,1372 # 80008738 <syscalls+0x2c0>
    800051e4:	8526                	mv	a0,s1
    800051e6:	fffff097          	auipc	ra,0xfffff
    800051ea:	c7c080e7          	jalr	-900(ra) # 80003e62 <dirlink>
    800051ee:	f80557e3          	bgez	a0,8000517c <create+0xcc>
      panic("create dots");
    800051f2:	00003517          	auipc	a0,0x3
    800051f6:	54e50513          	addi	a0,a0,1358 # 80008740 <syscalls+0x2c8>
    800051fa:	ffffb097          	auipc	ra,0xffffb
    800051fe:	33e080e7          	jalr	830(ra) # 80000538 <panic>
    panic("create: dirlink");
    80005202:	00003517          	auipc	a0,0x3
    80005206:	54e50513          	addi	a0,a0,1358 # 80008750 <syscalls+0x2d8>
    8000520a:	ffffb097          	auipc	ra,0xffffb
    8000520e:	32e080e7          	jalr	814(ra) # 80000538 <panic>
    return 0;
    80005212:	84aa                	mv	s1,a0
    80005214:	b739                	j	80005122 <create+0x72>

0000000080005216 <sys_dup>:
{
    80005216:	7179                	addi	sp,sp,-48
    80005218:	f406                	sd	ra,40(sp)
    8000521a:	f022                	sd	s0,32(sp)
    8000521c:	ec26                	sd	s1,24(sp)
    8000521e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005220:	fd840613          	addi	a2,s0,-40
    80005224:	4581                	li	a1,0
    80005226:	4501                	li	a0,0
    80005228:	00000097          	auipc	ra,0x0
    8000522c:	dde080e7          	jalr	-546(ra) # 80005006 <argfd>
    return -1;
    80005230:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005232:	02054363          	bltz	a0,80005258 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005236:	fd843503          	ld	a0,-40(s0)
    8000523a:	00000097          	auipc	ra,0x0
    8000523e:	e34080e7          	jalr	-460(ra) # 8000506e <fdalloc>
    80005242:	84aa                	mv	s1,a0
    return -1;
    80005244:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005246:	00054963          	bltz	a0,80005258 <sys_dup+0x42>
  filedup(f);
    8000524a:	fd843503          	ld	a0,-40(s0)
    8000524e:	fffff097          	auipc	ra,0xfffff
    80005252:	36c080e7          	jalr	876(ra) # 800045ba <filedup>
  return fd;
    80005256:	87a6                	mv	a5,s1
}
    80005258:	853e                	mv	a0,a5
    8000525a:	70a2                	ld	ra,40(sp)
    8000525c:	7402                	ld	s0,32(sp)
    8000525e:	64e2                	ld	s1,24(sp)
    80005260:	6145                	addi	sp,sp,48
    80005262:	8082                	ret

0000000080005264 <sys_read>:
{
    80005264:	7179                	addi	sp,sp,-48
    80005266:	f406                	sd	ra,40(sp)
    80005268:	f022                	sd	s0,32(sp)
    8000526a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000526c:	fe840613          	addi	a2,s0,-24
    80005270:	4581                	li	a1,0
    80005272:	4501                	li	a0,0
    80005274:	00000097          	auipc	ra,0x0
    80005278:	d92080e7          	jalr	-622(ra) # 80005006 <argfd>
    return -1;
    8000527c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000527e:	04054163          	bltz	a0,800052c0 <sys_read+0x5c>
    80005282:	fe440593          	addi	a1,s0,-28
    80005286:	4509                	li	a0,2
    80005288:	ffffe097          	auipc	ra,0xffffe
    8000528c:	884080e7          	jalr	-1916(ra) # 80002b0c <argint>
    return -1;
    80005290:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005292:	02054763          	bltz	a0,800052c0 <sys_read+0x5c>
    80005296:	fd840593          	addi	a1,s0,-40
    8000529a:	4505                	li	a0,1
    8000529c:	ffffe097          	auipc	ra,0xffffe
    800052a0:	892080e7          	jalr	-1902(ra) # 80002b2e <argaddr>
    return -1;
    800052a4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052a6:	00054d63          	bltz	a0,800052c0 <sys_read+0x5c>
  return fileread(f, p, n);
    800052aa:	fe442603          	lw	a2,-28(s0)
    800052ae:	fd843583          	ld	a1,-40(s0)
    800052b2:	fe843503          	ld	a0,-24(s0)
    800052b6:	fffff097          	auipc	ra,0xfffff
    800052ba:	490080e7          	jalr	1168(ra) # 80004746 <fileread>
    800052be:	87aa                	mv	a5,a0
}
    800052c0:	853e                	mv	a0,a5
    800052c2:	70a2                	ld	ra,40(sp)
    800052c4:	7402                	ld	s0,32(sp)
    800052c6:	6145                	addi	sp,sp,48
    800052c8:	8082                	ret

00000000800052ca <sys_write>:
{
    800052ca:	7179                	addi	sp,sp,-48
    800052cc:	f406                	sd	ra,40(sp)
    800052ce:	f022                	sd	s0,32(sp)
    800052d0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052d2:	fe840613          	addi	a2,s0,-24
    800052d6:	4581                	li	a1,0
    800052d8:	4501                	li	a0,0
    800052da:	00000097          	auipc	ra,0x0
    800052de:	d2c080e7          	jalr	-724(ra) # 80005006 <argfd>
    return -1;
    800052e2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052e4:	04054163          	bltz	a0,80005326 <sys_write+0x5c>
    800052e8:	fe440593          	addi	a1,s0,-28
    800052ec:	4509                	li	a0,2
    800052ee:	ffffe097          	auipc	ra,0xffffe
    800052f2:	81e080e7          	jalr	-2018(ra) # 80002b0c <argint>
    return -1;
    800052f6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052f8:	02054763          	bltz	a0,80005326 <sys_write+0x5c>
    800052fc:	fd840593          	addi	a1,s0,-40
    80005300:	4505                	li	a0,1
    80005302:	ffffe097          	auipc	ra,0xffffe
    80005306:	82c080e7          	jalr	-2004(ra) # 80002b2e <argaddr>
    return -1;
    8000530a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000530c:	00054d63          	bltz	a0,80005326 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005310:	fe442603          	lw	a2,-28(s0)
    80005314:	fd843583          	ld	a1,-40(s0)
    80005318:	fe843503          	ld	a0,-24(s0)
    8000531c:	fffff097          	auipc	ra,0xfffff
    80005320:	4ec080e7          	jalr	1260(ra) # 80004808 <filewrite>
    80005324:	87aa                	mv	a5,a0
}
    80005326:	853e                	mv	a0,a5
    80005328:	70a2                	ld	ra,40(sp)
    8000532a:	7402                	ld	s0,32(sp)
    8000532c:	6145                	addi	sp,sp,48
    8000532e:	8082                	ret

0000000080005330 <sys_close>:
{
    80005330:	1101                	addi	sp,sp,-32
    80005332:	ec06                	sd	ra,24(sp)
    80005334:	e822                	sd	s0,16(sp)
    80005336:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005338:	fe040613          	addi	a2,s0,-32
    8000533c:	fec40593          	addi	a1,s0,-20
    80005340:	4501                	li	a0,0
    80005342:	00000097          	auipc	ra,0x0
    80005346:	cc4080e7          	jalr	-828(ra) # 80005006 <argfd>
    return -1;
    8000534a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000534c:	02054463          	bltz	a0,80005374 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005350:	ffffc097          	auipc	ra,0xffffc
    80005354:	646080e7          	jalr	1606(ra) # 80001996 <myproc>
    80005358:	fec42783          	lw	a5,-20(s0)
    8000535c:	07e9                	addi	a5,a5,26
    8000535e:	078e                	slli	a5,a5,0x3
    80005360:	97aa                	add	a5,a5,a0
    80005362:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005366:	fe043503          	ld	a0,-32(s0)
    8000536a:	fffff097          	auipc	ra,0xfffff
    8000536e:	2a2080e7          	jalr	674(ra) # 8000460c <fileclose>
  return 0;
    80005372:	4781                	li	a5,0
}
    80005374:	853e                	mv	a0,a5
    80005376:	60e2                	ld	ra,24(sp)
    80005378:	6442                	ld	s0,16(sp)
    8000537a:	6105                	addi	sp,sp,32
    8000537c:	8082                	ret

000000008000537e <sys_fstat>:
{
    8000537e:	1101                	addi	sp,sp,-32
    80005380:	ec06                	sd	ra,24(sp)
    80005382:	e822                	sd	s0,16(sp)
    80005384:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005386:	fe840613          	addi	a2,s0,-24
    8000538a:	4581                	li	a1,0
    8000538c:	4501                	li	a0,0
    8000538e:	00000097          	auipc	ra,0x0
    80005392:	c78080e7          	jalr	-904(ra) # 80005006 <argfd>
    return -1;
    80005396:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005398:	02054563          	bltz	a0,800053c2 <sys_fstat+0x44>
    8000539c:	fe040593          	addi	a1,s0,-32
    800053a0:	4505                	li	a0,1
    800053a2:	ffffd097          	auipc	ra,0xffffd
    800053a6:	78c080e7          	jalr	1932(ra) # 80002b2e <argaddr>
    return -1;
    800053aa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053ac:	00054b63          	bltz	a0,800053c2 <sys_fstat+0x44>
  return filestat(f, st);
    800053b0:	fe043583          	ld	a1,-32(s0)
    800053b4:	fe843503          	ld	a0,-24(s0)
    800053b8:	fffff097          	auipc	ra,0xfffff
    800053bc:	31c080e7          	jalr	796(ra) # 800046d4 <filestat>
    800053c0:	87aa                	mv	a5,a0
}
    800053c2:	853e                	mv	a0,a5
    800053c4:	60e2                	ld	ra,24(sp)
    800053c6:	6442                	ld	s0,16(sp)
    800053c8:	6105                	addi	sp,sp,32
    800053ca:	8082                	ret

00000000800053cc <sys_link>:
{
    800053cc:	7169                	addi	sp,sp,-304
    800053ce:	f606                	sd	ra,296(sp)
    800053d0:	f222                	sd	s0,288(sp)
    800053d2:	ee26                	sd	s1,280(sp)
    800053d4:	ea4a                	sd	s2,272(sp)
    800053d6:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053d8:	08000613          	li	a2,128
    800053dc:	ed040593          	addi	a1,s0,-304
    800053e0:	4501                	li	a0,0
    800053e2:	ffffd097          	auipc	ra,0xffffd
    800053e6:	76e080e7          	jalr	1902(ra) # 80002b50 <argstr>
    return -1;
    800053ea:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053ec:	10054e63          	bltz	a0,80005508 <sys_link+0x13c>
    800053f0:	08000613          	li	a2,128
    800053f4:	f5040593          	addi	a1,s0,-176
    800053f8:	4505                	li	a0,1
    800053fa:	ffffd097          	auipc	ra,0xffffd
    800053fe:	756080e7          	jalr	1878(ra) # 80002b50 <argstr>
    return -1;
    80005402:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005404:	10054263          	bltz	a0,80005508 <sys_link+0x13c>
  begin_op();
    80005408:	fffff097          	auipc	ra,0xfffff
    8000540c:	d38080e7          	jalr	-712(ra) # 80004140 <begin_op>
  if((ip = namei(old)) == 0){
    80005410:	ed040513          	addi	a0,s0,-304
    80005414:	fffff097          	auipc	ra,0xfffff
    80005418:	b10080e7          	jalr	-1264(ra) # 80003f24 <namei>
    8000541c:	84aa                	mv	s1,a0
    8000541e:	c551                	beqz	a0,800054aa <sys_link+0xde>
  ilock(ip);
    80005420:	ffffe097          	auipc	ra,0xffffe
    80005424:	34e080e7          	jalr	846(ra) # 8000376e <ilock>
  if(ip->type == T_DIR){
    80005428:	04449703          	lh	a4,68(s1)
    8000542c:	4785                	li	a5,1
    8000542e:	08f70463          	beq	a4,a5,800054b6 <sys_link+0xea>
  ip->nlink++;
    80005432:	04a4d783          	lhu	a5,74(s1)
    80005436:	2785                	addiw	a5,a5,1
    80005438:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000543c:	8526                	mv	a0,s1
    8000543e:	ffffe097          	auipc	ra,0xffffe
    80005442:	266080e7          	jalr	614(ra) # 800036a4 <iupdate>
  iunlock(ip);
    80005446:	8526                	mv	a0,s1
    80005448:	ffffe097          	auipc	ra,0xffffe
    8000544c:	3e8080e7          	jalr	1000(ra) # 80003830 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005450:	fd040593          	addi	a1,s0,-48
    80005454:	f5040513          	addi	a0,s0,-176
    80005458:	fffff097          	auipc	ra,0xfffff
    8000545c:	aea080e7          	jalr	-1302(ra) # 80003f42 <nameiparent>
    80005460:	892a                	mv	s2,a0
    80005462:	c935                	beqz	a0,800054d6 <sys_link+0x10a>
  ilock(dp);
    80005464:	ffffe097          	auipc	ra,0xffffe
    80005468:	30a080e7          	jalr	778(ra) # 8000376e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000546c:	00092703          	lw	a4,0(s2)
    80005470:	409c                	lw	a5,0(s1)
    80005472:	04f71d63          	bne	a4,a5,800054cc <sys_link+0x100>
    80005476:	40d0                	lw	a2,4(s1)
    80005478:	fd040593          	addi	a1,s0,-48
    8000547c:	854a                	mv	a0,s2
    8000547e:	fffff097          	auipc	ra,0xfffff
    80005482:	9e4080e7          	jalr	-1564(ra) # 80003e62 <dirlink>
    80005486:	04054363          	bltz	a0,800054cc <sys_link+0x100>
  iunlockput(dp);
    8000548a:	854a                	mv	a0,s2
    8000548c:	ffffe097          	auipc	ra,0xffffe
    80005490:	544080e7          	jalr	1348(ra) # 800039d0 <iunlockput>
  iput(ip);
    80005494:	8526                	mv	a0,s1
    80005496:	ffffe097          	auipc	ra,0xffffe
    8000549a:	492080e7          	jalr	1170(ra) # 80003928 <iput>
  end_op();
    8000549e:	fffff097          	auipc	ra,0xfffff
    800054a2:	d22080e7          	jalr	-734(ra) # 800041c0 <end_op>
  return 0;
    800054a6:	4781                	li	a5,0
    800054a8:	a085                	j	80005508 <sys_link+0x13c>
    end_op();
    800054aa:	fffff097          	auipc	ra,0xfffff
    800054ae:	d16080e7          	jalr	-746(ra) # 800041c0 <end_op>
    return -1;
    800054b2:	57fd                	li	a5,-1
    800054b4:	a891                	j	80005508 <sys_link+0x13c>
    iunlockput(ip);
    800054b6:	8526                	mv	a0,s1
    800054b8:	ffffe097          	auipc	ra,0xffffe
    800054bc:	518080e7          	jalr	1304(ra) # 800039d0 <iunlockput>
    end_op();
    800054c0:	fffff097          	auipc	ra,0xfffff
    800054c4:	d00080e7          	jalr	-768(ra) # 800041c0 <end_op>
    return -1;
    800054c8:	57fd                	li	a5,-1
    800054ca:	a83d                	j	80005508 <sys_link+0x13c>
    iunlockput(dp);
    800054cc:	854a                	mv	a0,s2
    800054ce:	ffffe097          	auipc	ra,0xffffe
    800054d2:	502080e7          	jalr	1282(ra) # 800039d0 <iunlockput>
  ilock(ip);
    800054d6:	8526                	mv	a0,s1
    800054d8:	ffffe097          	auipc	ra,0xffffe
    800054dc:	296080e7          	jalr	662(ra) # 8000376e <ilock>
  ip->nlink--;
    800054e0:	04a4d783          	lhu	a5,74(s1)
    800054e4:	37fd                	addiw	a5,a5,-1
    800054e6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054ea:	8526                	mv	a0,s1
    800054ec:	ffffe097          	auipc	ra,0xffffe
    800054f0:	1b8080e7          	jalr	440(ra) # 800036a4 <iupdate>
  iunlockput(ip);
    800054f4:	8526                	mv	a0,s1
    800054f6:	ffffe097          	auipc	ra,0xffffe
    800054fa:	4da080e7          	jalr	1242(ra) # 800039d0 <iunlockput>
  end_op();
    800054fe:	fffff097          	auipc	ra,0xfffff
    80005502:	cc2080e7          	jalr	-830(ra) # 800041c0 <end_op>
  return -1;
    80005506:	57fd                	li	a5,-1
}
    80005508:	853e                	mv	a0,a5
    8000550a:	70b2                	ld	ra,296(sp)
    8000550c:	7412                	ld	s0,288(sp)
    8000550e:	64f2                	ld	s1,280(sp)
    80005510:	6952                	ld	s2,272(sp)
    80005512:	6155                	addi	sp,sp,304
    80005514:	8082                	ret

0000000080005516 <sys_unlink>:
{
    80005516:	7151                	addi	sp,sp,-240
    80005518:	f586                	sd	ra,232(sp)
    8000551a:	f1a2                	sd	s0,224(sp)
    8000551c:	eda6                	sd	s1,216(sp)
    8000551e:	e9ca                	sd	s2,208(sp)
    80005520:	e5ce                	sd	s3,200(sp)
    80005522:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005524:	08000613          	li	a2,128
    80005528:	f3040593          	addi	a1,s0,-208
    8000552c:	4501                	li	a0,0
    8000552e:	ffffd097          	auipc	ra,0xffffd
    80005532:	622080e7          	jalr	1570(ra) # 80002b50 <argstr>
    80005536:	18054163          	bltz	a0,800056b8 <sys_unlink+0x1a2>
  begin_op();
    8000553a:	fffff097          	auipc	ra,0xfffff
    8000553e:	c06080e7          	jalr	-1018(ra) # 80004140 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005542:	fb040593          	addi	a1,s0,-80
    80005546:	f3040513          	addi	a0,s0,-208
    8000554a:	fffff097          	auipc	ra,0xfffff
    8000554e:	9f8080e7          	jalr	-1544(ra) # 80003f42 <nameiparent>
    80005552:	84aa                	mv	s1,a0
    80005554:	c979                	beqz	a0,8000562a <sys_unlink+0x114>
  ilock(dp);
    80005556:	ffffe097          	auipc	ra,0xffffe
    8000555a:	218080e7          	jalr	536(ra) # 8000376e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000555e:	00003597          	auipc	a1,0x3
    80005562:	1d258593          	addi	a1,a1,466 # 80008730 <syscalls+0x2b8>
    80005566:	fb040513          	addi	a0,s0,-80
    8000556a:	ffffe097          	auipc	ra,0xffffe
    8000556e:	6ce080e7          	jalr	1742(ra) # 80003c38 <namecmp>
    80005572:	14050a63          	beqz	a0,800056c6 <sys_unlink+0x1b0>
    80005576:	00003597          	auipc	a1,0x3
    8000557a:	1c258593          	addi	a1,a1,450 # 80008738 <syscalls+0x2c0>
    8000557e:	fb040513          	addi	a0,s0,-80
    80005582:	ffffe097          	auipc	ra,0xffffe
    80005586:	6b6080e7          	jalr	1718(ra) # 80003c38 <namecmp>
    8000558a:	12050e63          	beqz	a0,800056c6 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000558e:	f2c40613          	addi	a2,s0,-212
    80005592:	fb040593          	addi	a1,s0,-80
    80005596:	8526                	mv	a0,s1
    80005598:	ffffe097          	auipc	ra,0xffffe
    8000559c:	6ba080e7          	jalr	1722(ra) # 80003c52 <dirlookup>
    800055a0:	892a                	mv	s2,a0
    800055a2:	12050263          	beqz	a0,800056c6 <sys_unlink+0x1b0>
  ilock(ip);
    800055a6:	ffffe097          	auipc	ra,0xffffe
    800055aa:	1c8080e7          	jalr	456(ra) # 8000376e <ilock>
  if(ip->nlink < 1)
    800055ae:	04a91783          	lh	a5,74(s2)
    800055b2:	08f05263          	blez	a5,80005636 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055b6:	04491703          	lh	a4,68(s2)
    800055ba:	4785                	li	a5,1
    800055bc:	08f70563          	beq	a4,a5,80005646 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800055c0:	4641                	li	a2,16
    800055c2:	4581                	li	a1,0
    800055c4:	fc040513          	addi	a0,s0,-64
    800055c8:	ffffb097          	auipc	ra,0xffffb
    800055cc:	704080e7          	jalr	1796(ra) # 80000ccc <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055d0:	4741                	li	a4,16
    800055d2:	f2c42683          	lw	a3,-212(s0)
    800055d6:	fc040613          	addi	a2,s0,-64
    800055da:	4581                	li	a1,0
    800055dc:	8526                	mv	a0,s1
    800055de:	ffffe097          	auipc	ra,0xffffe
    800055e2:	53c080e7          	jalr	1340(ra) # 80003b1a <writei>
    800055e6:	47c1                	li	a5,16
    800055e8:	0af51563          	bne	a0,a5,80005692 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800055ec:	04491703          	lh	a4,68(s2)
    800055f0:	4785                	li	a5,1
    800055f2:	0af70863          	beq	a4,a5,800056a2 <sys_unlink+0x18c>
  iunlockput(dp);
    800055f6:	8526                	mv	a0,s1
    800055f8:	ffffe097          	auipc	ra,0xffffe
    800055fc:	3d8080e7          	jalr	984(ra) # 800039d0 <iunlockput>
  ip->nlink--;
    80005600:	04a95783          	lhu	a5,74(s2)
    80005604:	37fd                	addiw	a5,a5,-1
    80005606:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000560a:	854a                	mv	a0,s2
    8000560c:	ffffe097          	auipc	ra,0xffffe
    80005610:	098080e7          	jalr	152(ra) # 800036a4 <iupdate>
  iunlockput(ip);
    80005614:	854a                	mv	a0,s2
    80005616:	ffffe097          	auipc	ra,0xffffe
    8000561a:	3ba080e7          	jalr	954(ra) # 800039d0 <iunlockput>
  end_op();
    8000561e:	fffff097          	auipc	ra,0xfffff
    80005622:	ba2080e7          	jalr	-1118(ra) # 800041c0 <end_op>
  return 0;
    80005626:	4501                	li	a0,0
    80005628:	a84d                	j	800056da <sys_unlink+0x1c4>
    end_op();
    8000562a:	fffff097          	auipc	ra,0xfffff
    8000562e:	b96080e7          	jalr	-1130(ra) # 800041c0 <end_op>
    return -1;
    80005632:	557d                	li	a0,-1
    80005634:	a05d                	j	800056da <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005636:	00003517          	auipc	a0,0x3
    8000563a:	12a50513          	addi	a0,a0,298 # 80008760 <syscalls+0x2e8>
    8000563e:	ffffb097          	auipc	ra,0xffffb
    80005642:	efa080e7          	jalr	-262(ra) # 80000538 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005646:	04c92703          	lw	a4,76(s2)
    8000564a:	02000793          	li	a5,32
    8000564e:	f6e7f9e3          	bgeu	a5,a4,800055c0 <sys_unlink+0xaa>
    80005652:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005656:	4741                	li	a4,16
    80005658:	86ce                	mv	a3,s3
    8000565a:	f1840613          	addi	a2,s0,-232
    8000565e:	4581                	li	a1,0
    80005660:	854a                	mv	a0,s2
    80005662:	ffffe097          	auipc	ra,0xffffe
    80005666:	3c0080e7          	jalr	960(ra) # 80003a22 <readi>
    8000566a:	47c1                	li	a5,16
    8000566c:	00f51b63          	bne	a0,a5,80005682 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005670:	f1845783          	lhu	a5,-232(s0)
    80005674:	e7a1                	bnez	a5,800056bc <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005676:	29c1                	addiw	s3,s3,16
    80005678:	04c92783          	lw	a5,76(s2)
    8000567c:	fcf9ede3          	bltu	s3,a5,80005656 <sys_unlink+0x140>
    80005680:	b781                	j	800055c0 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005682:	00003517          	auipc	a0,0x3
    80005686:	0f650513          	addi	a0,a0,246 # 80008778 <syscalls+0x300>
    8000568a:	ffffb097          	auipc	ra,0xffffb
    8000568e:	eae080e7          	jalr	-338(ra) # 80000538 <panic>
    panic("unlink: writei");
    80005692:	00003517          	auipc	a0,0x3
    80005696:	0fe50513          	addi	a0,a0,254 # 80008790 <syscalls+0x318>
    8000569a:	ffffb097          	auipc	ra,0xffffb
    8000569e:	e9e080e7          	jalr	-354(ra) # 80000538 <panic>
    dp->nlink--;
    800056a2:	04a4d783          	lhu	a5,74(s1)
    800056a6:	37fd                	addiw	a5,a5,-1
    800056a8:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056ac:	8526                	mv	a0,s1
    800056ae:	ffffe097          	auipc	ra,0xffffe
    800056b2:	ff6080e7          	jalr	-10(ra) # 800036a4 <iupdate>
    800056b6:	b781                	j	800055f6 <sys_unlink+0xe0>
    return -1;
    800056b8:	557d                	li	a0,-1
    800056ba:	a005                	j	800056da <sys_unlink+0x1c4>
    iunlockput(ip);
    800056bc:	854a                	mv	a0,s2
    800056be:	ffffe097          	auipc	ra,0xffffe
    800056c2:	312080e7          	jalr	786(ra) # 800039d0 <iunlockput>
  iunlockput(dp);
    800056c6:	8526                	mv	a0,s1
    800056c8:	ffffe097          	auipc	ra,0xffffe
    800056cc:	308080e7          	jalr	776(ra) # 800039d0 <iunlockput>
  end_op();
    800056d0:	fffff097          	auipc	ra,0xfffff
    800056d4:	af0080e7          	jalr	-1296(ra) # 800041c0 <end_op>
  return -1;
    800056d8:	557d                	li	a0,-1
}
    800056da:	70ae                	ld	ra,232(sp)
    800056dc:	740e                	ld	s0,224(sp)
    800056de:	64ee                	ld	s1,216(sp)
    800056e0:	694e                	ld	s2,208(sp)
    800056e2:	69ae                	ld	s3,200(sp)
    800056e4:	616d                	addi	sp,sp,240
    800056e6:	8082                	ret

00000000800056e8 <sys_open>:

uint64
sys_open(void)
{
    800056e8:	7131                	addi	sp,sp,-192
    800056ea:	fd06                	sd	ra,184(sp)
    800056ec:	f922                	sd	s0,176(sp)
    800056ee:	f526                	sd	s1,168(sp)
    800056f0:	f14a                	sd	s2,160(sp)
    800056f2:	ed4e                	sd	s3,152(sp)
    800056f4:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800056f6:	08000613          	li	a2,128
    800056fa:	f5040593          	addi	a1,s0,-176
    800056fe:	4501                	li	a0,0
    80005700:	ffffd097          	auipc	ra,0xffffd
    80005704:	450080e7          	jalr	1104(ra) # 80002b50 <argstr>
    return -1;
    80005708:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000570a:	0c054163          	bltz	a0,800057cc <sys_open+0xe4>
    8000570e:	f4c40593          	addi	a1,s0,-180
    80005712:	4505                	li	a0,1
    80005714:	ffffd097          	auipc	ra,0xffffd
    80005718:	3f8080e7          	jalr	1016(ra) # 80002b0c <argint>
    8000571c:	0a054863          	bltz	a0,800057cc <sys_open+0xe4>

  begin_op();
    80005720:	fffff097          	auipc	ra,0xfffff
    80005724:	a20080e7          	jalr	-1504(ra) # 80004140 <begin_op>

  if(omode & O_CREATE){
    80005728:	f4c42783          	lw	a5,-180(s0)
    8000572c:	2007f793          	andi	a5,a5,512
    80005730:	cbdd                	beqz	a5,800057e6 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005732:	4681                	li	a3,0
    80005734:	4601                	li	a2,0
    80005736:	4589                	li	a1,2
    80005738:	f5040513          	addi	a0,s0,-176
    8000573c:	00000097          	auipc	ra,0x0
    80005740:	974080e7          	jalr	-1676(ra) # 800050b0 <create>
    80005744:	892a                	mv	s2,a0
    if(ip == 0){
    80005746:	c959                	beqz	a0,800057dc <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005748:	04491703          	lh	a4,68(s2)
    8000574c:	478d                	li	a5,3
    8000574e:	00f71763          	bne	a4,a5,8000575c <sys_open+0x74>
    80005752:	04695703          	lhu	a4,70(s2)
    80005756:	47a5                	li	a5,9
    80005758:	0ce7ec63          	bltu	a5,a4,80005830 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000575c:	fffff097          	auipc	ra,0xfffff
    80005760:	df4080e7          	jalr	-524(ra) # 80004550 <filealloc>
    80005764:	89aa                	mv	s3,a0
    80005766:	10050263          	beqz	a0,8000586a <sys_open+0x182>
    8000576a:	00000097          	auipc	ra,0x0
    8000576e:	904080e7          	jalr	-1788(ra) # 8000506e <fdalloc>
    80005772:	84aa                	mv	s1,a0
    80005774:	0e054663          	bltz	a0,80005860 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005778:	04491703          	lh	a4,68(s2)
    8000577c:	478d                	li	a5,3
    8000577e:	0cf70463          	beq	a4,a5,80005846 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005782:	4789                	li	a5,2
    80005784:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005788:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000578c:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005790:	f4c42783          	lw	a5,-180(s0)
    80005794:	0017c713          	xori	a4,a5,1
    80005798:	8b05                	andi	a4,a4,1
    8000579a:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000579e:	0037f713          	andi	a4,a5,3
    800057a2:	00e03733          	snez	a4,a4
    800057a6:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057aa:	4007f793          	andi	a5,a5,1024
    800057ae:	c791                	beqz	a5,800057ba <sys_open+0xd2>
    800057b0:	04491703          	lh	a4,68(s2)
    800057b4:	4789                	li	a5,2
    800057b6:	08f70f63          	beq	a4,a5,80005854 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800057ba:	854a                	mv	a0,s2
    800057bc:	ffffe097          	auipc	ra,0xffffe
    800057c0:	074080e7          	jalr	116(ra) # 80003830 <iunlock>
  end_op();
    800057c4:	fffff097          	auipc	ra,0xfffff
    800057c8:	9fc080e7          	jalr	-1540(ra) # 800041c0 <end_op>

  return fd;
}
    800057cc:	8526                	mv	a0,s1
    800057ce:	70ea                	ld	ra,184(sp)
    800057d0:	744a                	ld	s0,176(sp)
    800057d2:	74aa                	ld	s1,168(sp)
    800057d4:	790a                	ld	s2,160(sp)
    800057d6:	69ea                	ld	s3,152(sp)
    800057d8:	6129                	addi	sp,sp,192
    800057da:	8082                	ret
      end_op();
    800057dc:	fffff097          	auipc	ra,0xfffff
    800057e0:	9e4080e7          	jalr	-1564(ra) # 800041c0 <end_op>
      return -1;
    800057e4:	b7e5                	j	800057cc <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800057e6:	f5040513          	addi	a0,s0,-176
    800057ea:	ffffe097          	auipc	ra,0xffffe
    800057ee:	73a080e7          	jalr	1850(ra) # 80003f24 <namei>
    800057f2:	892a                	mv	s2,a0
    800057f4:	c905                	beqz	a0,80005824 <sys_open+0x13c>
    ilock(ip);
    800057f6:	ffffe097          	auipc	ra,0xffffe
    800057fa:	f78080e7          	jalr	-136(ra) # 8000376e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800057fe:	04491703          	lh	a4,68(s2)
    80005802:	4785                	li	a5,1
    80005804:	f4f712e3          	bne	a4,a5,80005748 <sys_open+0x60>
    80005808:	f4c42783          	lw	a5,-180(s0)
    8000580c:	dba1                	beqz	a5,8000575c <sys_open+0x74>
      iunlockput(ip);
    8000580e:	854a                	mv	a0,s2
    80005810:	ffffe097          	auipc	ra,0xffffe
    80005814:	1c0080e7          	jalr	448(ra) # 800039d0 <iunlockput>
      end_op();
    80005818:	fffff097          	auipc	ra,0xfffff
    8000581c:	9a8080e7          	jalr	-1624(ra) # 800041c0 <end_op>
      return -1;
    80005820:	54fd                	li	s1,-1
    80005822:	b76d                	j	800057cc <sys_open+0xe4>
      end_op();
    80005824:	fffff097          	auipc	ra,0xfffff
    80005828:	99c080e7          	jalr	-1636(ra) # 800041c0 <end_op>
      return -1;
    8000582c:	54fd                	li	s1,-1
    8000582e:	bf79                	j	800057cc <sys_open+0xe4>
    iunlockput(ip);
    80005830:	854a                	mv	a0,s2
    80005832:	ffffe097          	auipc	ra,0xffffe
    80005836:	19e080e7          	jalr	414(ra) # 800039d0 <iunlockput>
    end_op();
    8000583a:	fffff097          	auipc	ra,0xfffff
    8000583e:	986080e7          	jalr	-1658(ra) # 800041c0 <end_op>
    return -1;
    80005842:	54fd                	li	s1,-1
    80005844:	b761                	j	800057cc <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005846:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000584a:	04691783          	lh	a5,70(s2)
    8000584e:	02f99223          	sh	a5,36(s3)
    80005852:	bf2d                	j	8000578c <sys_open+0xa4>
    itrunc(ip);
    80005854:	854a                	mv	a0,s2
    80005856:	ffffe097          	auipc	ra,0xffffe
    8000585a:	026080e7          	jalr	38(ra) # 8000387c <itrunc>
    8000585e:	bfb1                	j	800057ba <sys_open+0xd2>
      fileclose(f);
    80005860:	854e                	mv	a0,s3
    80005862:	fffff097          	auipc	ra,0xfffff
    80005866:	daa080e7          	jalr	-598(ra) # 8000460c <fileclose>
    iunlockput(ip);
    8000586a:	854a                	mv	a0,s2
    8000586c:	ffffe097          	auipc	ra,0xffffe
    80005870:	164080e7          	jalr	356(ra) # 800039d0 <iunlockput>
    end_op();
    80005874:	fffff097          	auipc	ra,0xfffff
    80005878:	94c080e7          	jalr	-1716(ra) # 800041c0 <end_op>
    return -1;
    8000587c:	54fd                	li	s1,-1
    8000587e:	b7b9                	j	800057cc <sys_open+0xe4>

0000000080005880 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005880:	7175                	addi	sp,sp,-144
    80005882:	e506                	sd	ra,136(sp)
    80005884:	e122                	sd	s0,128(sp)
    80005886:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005888:	fffff097          	auipc	ra,0xfffff
    8000588c:	8b8080e7          	jalr	-1864(ra) # 80004140 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005890:	08000613          	li	a2,128
    80005894:	f7040593          	addi	a1,s0,-144
    80005898:	4501                	li	a0,0
    8000589a:	ffffd097          	auipc	ra,0xffffd
    8000589e:	2b6080e7          	jalr	694(ra) # 80002b50 <argstr>
    800058a2:	02054963          	bltz	a0,800058d4 <sys_mkdir+0x54>
    800058a6:	4681                	li	a3,0
    800058a8:	4601                	li	a2,0
    800058aa:	4585                	li	a1,1
    800058ac:	f7040513          	addi	a0,s0,-144
    800058b0:	00000097          	auipc	ra,0x0
    800058b4:	800080e7          	jalr	-2048(ra) # 800050b0 <create>
    800058b8:	cd11                	beqz	a0,800058d4 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058ba:	ffffe097          	auipc	ra,0xffffe
    800058be:	116080e7          	jalr	278(ra) # 800039d0 <iunlockput>
  end_op();
    800058c2:	fffff097          	auipc	ra,0xfffff
    800058c6:	8fe080e7          	jalr	-1794(ra) # 800041c0 <end_op>
  return 0;
    800058ca:	4501                	li	a0,0
}
    800058cc:	60aa                	ld	ra,136(sp)
    800058ce:	640a                	ld	s0,128(sp)
    800058d0:	6149                	addi	sp,sp,144
    800058d2:	8082                	ret
    end_op();
    800058d4:	fffff097          	auipc	ra,0xfffff
    800058d8:	8ec080e7          	jalr	-1812(ra) # 800041c0 <end_op>
    return -1;
    800058dc:	557d                	li	a0,-1
    800058de:	b7fd                	j	800058cc <sys_mkdir+0x4c>

00000000800058e0 <sys_mknod>:

uint64
sys_mknod(void)
{
    800058e0:	7135                	addi	sp,sp,-160
    800058e2:	ed06                	sd	ra,152(sp)
    800058e4:	e922                	sd	s0,144(sp)
    800058e6:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800058e8:	fffff097          	auipc	ra,0xfffff
    800058ec:	858080e7          	jalr	-1960(ra) # 80004140 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058f0:	08000613          	li	a2,128
    800058f4:	f7040593          	addi	a1,s0,-144
    800058f8:	4501                	li	a0,0
    800058fa:	ffffd097          	auipc	ra,0xffffd
    800058fe:	256080e7          	jalr	598(ra) # 80002b50 <argstr>
    80005902:	04054a63          	bltz	a0,80005956 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005906:	f6c40593          	addi	a1,s0,-148
    8000590a:	4505                	li	a0,1
    8000590c:	ffffd097          	auipc	ra,0xffffd
    80005910:	200080e7          	jalr	512(ra) # 80002b0c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005914:	04054163          	bltz	a0,80005956 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005918:	f6840593          	addi	a1,s0,-152
    8000591c:	4509                	li	a0,2
    8000591e:	ffffd097          	auipc	ra,0xffffd
    80005922:	1ee080e7          	jalr	494(ra) # 80002b0c <argint>
     argint(1, &major) < 0 ||
    80005926:	02054863          	bltz	a0,80005956 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000592a:	f6841683          	lh	a3,-152(s0)
    8000592e:	f6c41603          	lh	a2,-148(s0)
    80005932:	458d                	li	a1,3
    80005934:	f7040513          	addi	a0,s0,-144
    80005938:	fffff097          	auipc	ra,0xfffff
    8000593c:	778080e7          	jalr	1912(ra) # 800050b0 <create>
     argint(2, &minor) < 0 ||
    80005940:	c919                	beqz	a0,80005956 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005942:	ffffe097          	auipc	ra,0xffffe
    80005946:	08e080e7          	jalr	142(ra) # 800039d0 <iunlockput>
  end_op();
    8000594a:	fffff097          	auipc	ra,0xfffff
    8000594e:	876080e7          	jalr	-1930(ra) # 800041c0 <end_op>
  return 0;
    80005952:	4501                	li	a0,0
    80005954:	a031                	j	80005960 <sys_mknod+0x80>
    end_op();
    80005956:	fffff097          	auipc	ra,0xfffff
    8000595a:	86a080e7          	jalr	-1942(ra) # 800041c0 <end_op>
    return -1;
    8000595e:	557d                	li	a0,-1
}
    80005960:	60ea                	ld	ra,152(sp)
    80005962:	644a                	ld	s0,144(sp)
    80005964:	610d                	addi	sp,sp,160
    80005966:	8082                	ret

0000000080005968 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005968:	7135                	addi	sp,sp,-160
    8000596a:	ed06                	sd	ra,152(sp)
    8000596c:	e922                	sd	s0,144(sp)
    8000596e:	e526                	sd	s1,136(sp)
    80005970:	e14a                	sd	s2,128(sp)
    80005972:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005974:	ffffc097          	auipc	ra,0xffffc
    80005978:	022080e7          	jalr	34(ra) # 80001996 <myproc>
    8000597c:	892a                	mv	s2,a0
  
  begin_op();
    8000597e:	ffffe097          	auipc	ra,0xffffe
    80005982:	7c2080e7          	jalr	1986(ra) # 80004140 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005986:	08000613          	li	a2,128
    8000598a:	f6040593          	addi	a1,s0,-160
    8000598e:	4501                	li	a0,0
    80005990:	ffffd097          	auipc	ra,0xffffd
    80005994:	1c0080e7          	jalr	448(ra) # 80002b50 <argstr>
    80005998:	04054b63          	bltz	a0,800059ee <sys_chdir+0x86>
    8000599c:	f6040513          	addi	a0,s0,-160
    800059a0:	ffffe097          	auipc	ra,0xffffe
    800059a4:	584080e7          	jalr	1412(ra) # 80003f24 <namei>
    800059a8:	84aa                	mv	s1,a0
    800059aa:	c131                	beqz	a0,800059ee <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059ac:	ffffe097          	auipc	ra,0xffffe
    800059b0:	dc2080e7          	jalr	-574(ra) # 8000376e <ilock>
  if(ip->type != T_DIR){
    800059b4:	04449703          	lh	a4,68(s1)
    800059b8:	4785                	li	a5,1
    800059ba:	04f71063          	bne	a4,a5,800059fa <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800059be:	8526                	mv	a0,s1
    800059c0:	ffffe097          	auipc	ra,0xffffe
    800059c4:	e70080e7          	jalr	-400(ra) # 80003830 <iunlock>
  iput(p->cwd);
    800059c8:	15093503          	ld	a0,336(s2)
    800059cc:	ffffe097          	auipc	ra,0xffffe
    800059d0:	f5c080e7          	jalr	-164(ra) # 80003928 <iput>
  end_op();
    800059d4:	ffffe097          	auipc	ra,0xffffe
    800059d8:	7ec080e7          	jalr	2028(ra) # 800041c0 <end_op>
  p->cwd = ip;
    800059dc:	14993823          	sd	s1,336(s2)
  return 0;
    800059e0:	4501                	li	a0,0
}
    800059e2:	60ea                	ld	ra,152(sp)
    800059e4:	644a                	ld	s0,144(sp)
    800059e6:	64aa                	ld	s1,136(sp)
    800059e8:	690a                	ld	s2,128(sp)
    800059ea:	610d                	addi	sp,sp,160
    800059ec:	8082                	ret
    end_op();
    800059ee:	ffffe097          	auipc	ra,0xffffe
    800059f2:	7d2080e7          	jalr	2002(ra) # 800041c0 <end_op>
    return -1;
    800059f6:	557d                	li	a0,-1
    800059f8:	b7ed                	j	800059e2 <sys_chdir+0x7a>
    iunlockput(ip);
    800059fa:	8526                	mv	a0,s1
    800059fc:	ffffe097          	auipc	ra,0xffffe
    80005a00:	fd4080e7          	jalr	-44(ra) # 800039d0 <iunlockput>
    end_op();
    80005a04:	ffffe097          	auipc	ra,0xffffe
    80005a08:	7bc080e7          	jalr	1980(ra) # 800041c0 <end_op>
    return -1;
    80005a0c:	557d                	li	a0,-1
    80005a0e:	bfd1                	j	800059e2 <sys_chdir+0x7a>

0000000080005a10 <sys_exec>:

uint64
sys_exec(void)
{
    80005a10:	7145                	addi	sp,sp,-464
    80005a12:	e786                	sd	ra,456(sp)
    80005a14:	e3a2                	sd	s0,448(sp)
    80005a16:	ff26                	sd	s1,440(sp)
    80005a18:	fb4a                	sd	s2,432(sp)
    80005a1a:	f74e                	sd	s3,424(sp)
    80005a1c:	f352                	sd	s4,416(sp)
    80005a1e:	ef56                	sd	s5,408(sp)
    80005a20:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a22:	08000613          	li	a2,128
    80005a26:	f4040593          	addi	a1,s0,-192
    80005a2a:	4501                	li	a0,0
    80005a2c:	ffffd097          	auipc	ra,0xffffd
    80005a30:	124080e7          	jalr	292(ra) # 80002b50 <argstr>
    return -1;
    80005a34:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a36:	0c054a63          	bltz	a0,80005b0a <sys_exec+0xfa>
    80005a3a:	e3840593          	addi	a1,s0,-456
    80005a3e:	4505                	li	a0,1
    80005a40:	ffffd097          	auipc	ra,0xffffd
    80005a44:	0ee080e7          	jalr	238(ra) # 80002b2e <argaddr>
    80005a48:	0c054163          	bltz	a0,80005b0a <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a4c:	10000613          	li	a2,256
    80005a50:	4581                	li	a1,0
    80005a52:	e4040513          	addi	a0,s0,-448
    80005a56:	ffffb097          	auipc	ra,0xffffb
    80005a5a:	276080e7          	jalr	630(ra) # 80000ccc <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a5e:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a62:	89a6                	mv	s3,s1
    80005a64:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a66:	02000a13          	li	s4,32
    80005a6a:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a6e:	00391793          	slli	a5,s2,0x3
    80005a72:	e3040593          	addi	a1,s0,-464
    80005a76:	e3843503          	ld	a0,-456(s0)
    80005a7a:	953e                	add	a0,a0,a5
    80005a7c:	ffffd097          	auipc	ra,0xffffd
    80005a80:	ff6080e7          	jalr	-10(ra) # 80002a72 <fetchaddr>
    80005a84:	02054a63          	bltz	a0,80005ab8 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005a88:	e3043783          	ld	a5,-464(s0)
    80005a8c:	c3b9                	beqz	a5,80005ad2 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a8e:	ffffb097          	auipc	ra,0xffffb
    80005a92:	052080e7          	jalr	82(ra) # 80000ae0 <kalloc>
    80005a96:	85aa                	mv	a1,a0
    80005a98:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a9c:	cd11                	beqz	a0,80005ab8 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a9e:	6605                	lui	a2,0x1
    80005aa0:	e3043503          	ld	a0,-464(s0)
    80005aa4:	ffffd097          	auipc	ra,0xffffd
    80005aa8:	020080e7          	jalr	32(ra) # 80002ac4 <fetchstr>
    80005aac:	00054663          	bltz	a0,80005ab8 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005ab0:	0905                	addi	s2,s2,1
    80005ab2:	09a1                	addi	s3,s3,8
    80005ab4:	fb491be3          	bne	s2,s4,80005a6a <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ab8:	10048913          	addi	s2,s1,256
    80005abc:	6088                	ld	a0,0(s1)
    80005abe:	c529                	beqz	a0,80005b08 <sys_exec+0xf8>
    kfree(argv[i]);
    80005ac0:	ffffb097          	auipc	ra,0xffffb
    80005ac4:	f24080e7          	jalr	-220(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ac8:	04a1                	addi	s1,s1,8
    80005aca:	ff2499e3          	bne	s1,s2,80005abc <sys_exec+0xac>
  return -1;
    80005ace:	597d                	li	s2,-1
    80005ad0:	a82d                	j	80005b0a <sys_exec+0xfa>
      argv[i] = 0;
    80005ad2:	0a8e                	slli	s5,s5,0x3
    80005ad4:	fc040793          	addi	a5,s0,-64
    80005ad8:	9abe                	add	s5,s5,a5
    80005ada:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd8e80>
  int ret = exec(path, argv);
    80005ade:	e4040593          	addi	a1,s0,-448
    80005ae2:	f4040513          	addi	a0,s0,-192
    80005ae6:	fffff097          	auipc	ra,0xfffff
    80005aea:	178080e7          	jalr	376(ra) # 80004c5e <exec>
    80005aee:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005af0:	10048993          	addi	s3,s1,256
    80005af4:	6088                	ld	a0,0(s1)
    80005af6:	c911                	beqz	a0,80005b0a <sys_exec+0xfa>
    kfree(argv[i]);
    80005af8:	ffffb097          	auipc	ra,0xffffb
    80005afc:	eec080e7          	jalr	-276(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b00:	04a1                	addi	s1,s1,8
    80005b02:	ff3499e3          	bne	s1,s3,80005af4 <sys_exec+0xe4>
    80005b06:	a011                	j	80005b0a <sys_exec+0xfa>
  return -1;
    80005b08:	597d                	li	s2,-1
}
    80005b0a:	854a                	mv	a0,s2
    80005b0c:	60be                	ld	ra,456(sp)
    80005b0e:	641e                	ld	s0,448(sp)
    80005b10:	74fa                	ld	s1,440(sp)
    80005b12:	795a                	ld	s2,432(sp)
    80005b14:	79ba                	ld	s3,424(sp)
    80005b16:	7a1a                	ld	s4,416(sp)
    80005b18:	6afa                	ld	s5,408(sp)
    80005b1a:	6179                	addi	sp,sp,464
    80005b1c:	8082                	ret

0000000080005b1e <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b1e:	7139                	addi	sp,sp,-64
    80005b20:	fc06                	sd	ra,56(sp)
    80005b22:	f822                	sd	s0,48(sp)
    80005b24:	f426                	sd	s1,40(sp)
    80005b26:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b28:	ffffc097          	auipc	ra,0xffffc
    80005b2c:	e6e080e7          	jalr	-402(ra) # 80001996 <myproc>
    80005b30:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005b32:	fd840593          	addi	a1,s0,-40
    80005b36:	4501                	li	a0,0
    80005b38:	ffffd097          	auipc	ra,0xffffd
    80005b3c:	ff6080e7          	jalr	-10(ra) # 80002b2e <argaddr>
    return -1;
    80005b40:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b42:	0e054063          	bltz	a0,80005c22 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b46:	fc840593          	addi	a1,s0,-56
    80005b4a:	fd040513          	addi	a0,s0,-48
    80005b4e:	fffff097          	auipc	ra,0xfffff
    80005b52:	dee080e7          	jalr	-530(ra) # 8000493c <pipealloc>
    return -1;
    80005b56:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b58:	0c054563          	bltz	a0,80005c22 <sys_pipe+0x104>
  fd0 = -1;
    80005b5c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b60:	fd043503          	ld	a0,-48(s0)
    80005b64:	fffff097          	auipc	ra,0xfffff
    80005b68:	50a080e7          	jalr	1290(ra) # 8000506e <fdalloc>
    80005b6c:	fca42223          	sw	a0,-60(s0)
    80005b70:	08054c63          	bltz	a0,80005c08 <sys_pipe+0xea>
    80005b74:	fc843503          	ld	a0,-56(s0)
    80005b78:	fffff097          	auipc	ra,0xfffff
    80005b7c:	4f6080e7          	jalr	1270(ra) # 8000506e <fdalloc>
    80005b80:	fca42023          	sw	a0,-64(s0)
    80005b84:	06054863          	bltz	a0,80005bf4 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b88:	4691                	li	a3,4
    80005b8a:	fc440613          	addi	a2,s0,-60
    80005b8e:	fd843583          	ld	a1,-40(s0)
    80005b92:	68a8                	ld	a0,80(s1)
    80005b94:	ffffc097          	auipc	ra,0xffffc
    80005b98:	ac2080e7          	jalr	-1342(ra) # 80001656 <copyout>
    80005b9c:	02054063          	bltz	a0,80005bbc <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005ba0:	4691                	li	a3,4
    80005ba2:	fc040613          	addi	a2,s0,-64
    80005ba6:	fd843583          	ld	a1,-40(s0)
    80005baa:	0591                	addi	a1,a1,4
    80005bac:	68a8                	ld	a0,80(s1)
    80005bae:	ffffc097          	auipc	ra,0xffffc
    80005bb2:	aa8080e7          	jalr	-1368(ra) # 80001656 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005bb6:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bb8:	06055563          	bgez	a0,80005c22 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005bbc:	fc442783          	lw	a5,-60(s0)
    80005bc0:	07e9                	addi	a5,a5,26
    80005bc2:	078e                	slli	a5,a5,0x3
    80005bc4:	97a6                	add	a5,a5,s1
    80005bc6:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005bca:	fc042503          	lw	a0,-64(s0)
    80005bce:	0569                	addi	a0,a0,26
    80005bd0:	050e                	slli	a0,a0,0x3
    80005bd2:	9526                	add	a0,a0,s1
    80005bd4:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005bd8:	fd043503          	ld	a0,-48(s0)
    80005bdc:	fffff097          	auipc	ra,0xfffff
    80005be0:	a30080e7          	jalr	-1488(ra) # 8000460c <fileclose>
    fileclose(wf);
    80005be4:	fc843503          	ld	a0,-56(s0)
    80005be8:	fffff097          	auipc	ra,0xfffff
    80005bec:	a24080e7          	jalr	-1500(ra) # 8000460c <fileclose>
    return -1;
    80005bf0:	57fd                	li	a5,-1
    80005bf2:	a805                	j	80005c22 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005bf4:	fc442783          	lw	a5,-60(s0)
    80005bf8:	0007c863          	bltz	a5,80005c08 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005bfc:	01a78513          	addi	a0,a5,26
    80005c00:	050e                	slli	a0,a0,0x3
    80005c02:	9526                	add	a0,a0,s1
    80005c04:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c08:	fd043503          	ld	a0,-48(s0)
    80005c0c:	fffff097          	auipc	ra,0xfffff
    80005c10:	a00080e7          	jalr	-1536(ra) # 8000460c <fileclose>
    fileclose(wf);
    80005c14:	fc843503          	ld	a0,-56(s0)
    80005c18:	fffff097          	auipc	ra,0xfffff
    80005c1c:	9f4080e7          	jalr	-1548(ra) # 8000460c <fileclose>
    return -1;
    80005c20:	57fd                	li	a5,-1
}
    80005c22:	853e                	mv	a0,a5
    80005c24:	70e2                	ld	ra,56(sp)
    80005c26:	7442                	ld	s0,48(sp)
    80005c28:	74a2                	ld	s1,40(sp)
    80005c2a:	6121                	addi	sp,sp,64
    80005c2c:	8082                	ret
	...

0000000080005c30 <kernelvec>:
    80005c30:	7111                	addi	sp,sp,-256
    80005c32:	e006                	sd	ra,0(sp)
    80005c34:	e40a                	sd	sp,8(sp)
    80005c36:	e80e                	sd	gp,16(sp)
    80005c38:	ec12                	sd	tp,24(sp)
    80005c3a:	f016                	sd	t0,32(sp)
    80005c3c:	f41a                	sd	t1,40(sp)
    80005c3e:	f81e                	sd	t2,48(sp)
    80005c40:	fc22                	sd	s0,56(sp)
    80005c42:	e0a6                	sd	s1,64(sp)
    80005c44:	e4aa                	sd	a0,72(sp)
    80005c46:	e8ae                	sd	a1,80(sp)
    80005c48:	ecb2                	sd	a2,88(sp)
    80005c4a:	f0b6                	sd	a3,96(sp)
    80005c4c:	f4ba                	sd	a4,104(sp)
    80005c4e:	f8be                	sd	a5,112(sp)
    80005c50:	fcc2                	sd	a6,120(sp)
    80005c52:	e146                	sd	a7,128(sp)
    80005c54:	e54a                	sd	s2,136(sp)
    80005c56:	e94e                	sd	s3,144(sp)
    80005c58:	ed52                	sd	s4,152(sp)
    80005c5a:	f156                	sd	s5,160(sp)
    80005c5c:	f55a                	sd	s6,168(sp)
    80005c5e:	f95e                	sd	s7,176(sp)
    80005c60:	fd62                	sd	s8,184(sp)
    80005c62:	e1e6                	sd	s9,192(sp)
    80005c64:	e5ea                	sd	s10,200(sp)
    80005c66:	e9ee                	sd	s11,208(sp)
    80005c68:	edf2                	sd	t3,216(sp)
    80005c6a:	f1f6                	sd	t4,224(sp)
    80005c6c:	f5fa                	sd	t5,232(sp)
    80005c6e:	f9fe                	sd	t6,240(sp)
    80005c70:	ccffc0ef          	jal	ra,8000293e <kerneltrap>
    80005c74:	6082                	ld	ra,0(sp)
    80005c76:	6122                	ld	sp,8(sp)
    80005c78:	61c2                	ld	gp,16(sp)
    80005c7a:	7282                	ld	t0,32(sp)
    80005c7c:	7322                	ld	t1,40(sp)
    80005c7e:	73c2                	ld	t2,48(sp)
    80005c80:	7462                	ld	s0,56(sp)
    80005c82:	6486                	ld	s1,64(sp)
    80005c84:	6526                	ld	a0,72(sp)
    80005c86:	65c6                	ld	a1,80(sp)
    80005c88:	6666                	ld	a2,88(sp)
    80005c8a:	7686                	ld	a3,96(sp)
    80005c8c:	7726                	ld	a4,104(sp)
    80005c8e:	77c6                	ld	a5,112(sp)
    80005c90:	7866                	ld	a6,120(sp)
    80005c92:	688a                	ld	a7,128(sp)
    80005c94:	692a                	ld	s2,136(sp)
    80005c96:	69ca                	ld	s3,144(sp)
    80005c98:	6a6a                	ld	s4,152(sp)
    80005c9a:	7a8a                	ld	s5,160(sp)
    80005c9c:	7b2a                	ld	s6,168(sp)
    80005c9e:	7bca                	ld	s7,176(sp)
    80005ca0:	7c6a                	ld	s8,184(sp)
    80005ca2:	6c8e                	ld	s9,192(sp)
    80005ca4:	6d2e                	ld	s10,200(sp)
    80005ca6:	6dce                	ld	s11,208(sp)
    80005ca8:	6e6e                	ld	t3,216(sp)
    80005caa:	7e8e                	ld	t4,224(sp)
    80005cac:	7f2e                	ld	t5,232(sp)
    80005cae:	7fce                	ld	t6,240(sp)
    80005cb0:	6111                	addi	sp,sp,256
    80005cb2:	10200073          	sret
    80005cb6:	00000013          	nop
    80005cba:	00000013          	nop
    80005cbe:	0001                	nop

0000000080005cc0 <timervec>:
    80005cc0:	34051573          	csrrw	a0,mscratch,a0
    80005cc4:	e10c                	sd	a1,0(a0)
    80005cc6:	e510                	sd	a2,8(a0)
    80005cc8:	e914                	sd	a3,16(a0)
    80005cca:	6d0c                	ld	a1,24(a0)
    80005ccc:	7110                	ld	a2,32(a0)
    80005cce:	6194                	ld	a3,0(a1)
    80005cd0:	96b2                	add	a3,a3,a2
    80005cd2:	e194                	sd	a3,0(a1)
    80005cd4:	4589                	li	a1,2
    80005cd6:	14459073          	csrw	sip,a1
    80005cda:	6914                	ld	a3,16(a0)
    80005cdc:	6510                	ld	a2,8(a0)
    80005cde:	610c                	ld	a1,0(a0)
    80005ce0:	34051573          	csrrw	a0,mscratch,a0
    80005ce4:	30200073          	mret
	...

0000000080005cea <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005cea:	1141                	addi	sp,sp,-16
    80005cec:	e422                	sd	s0,8(sp)
    80005cee:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005cf0:	0c0007b7          	lui	a5,0xc000
    80005cf4:	4705                	li	a4,1
    80005cf6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005cf8:	c3d8                	sw	a4,4(a5)
}
    80005cfa:	6422                	ld	s0,8(sp)
    80005cfc:	0141                	addi	sp,sp,16
    80005cfe:	8082                	ret

0000000080005d00 <plicinithart>:

void
plicinithart(void)
{
    80005d00:	1141                	addi	sp,sp,-16
    80005d02:	e406                	sd	ra,8(sp)
    80005d04:	e022                	sd	s0,0(sp)
    80005d06:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d08:	ffffc097          	auipc	ra,0xffffc
    80005d0c:	c62080e7          	jalr	-926(ra) # 8000196a <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d10:	0085171b          	slliw	a4,a0,0x8
    80005d14:	0c0027b7          	lui	a5,0xc002
    80005d18:	97ba                	add	a5,a5,a4
    80005d1a:	40200713          	li	a4,1026
    80005d1e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d22:	00d5151b          	slliw	a0,a0,0xd
    80005d26:	0c2017b7          	lui	a5,0xc201
    80005d2a:	953e                	add	a0,a0,a5
    80005d2c:	00052023          	sw	zero,0(a0)
}
    80005d30:	60a2                	ld	ra,8(sp)
    80005d32:	6402                	ld	s0,0(sp)
    80005d34:	0141                	addi	sp,sp,16
    80005d36:	8082                	ret

0000000080005d38 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d38:	1141                	addi	sp,sp,-16
    80005d3a:	e406                	sd	ra,8(sp)
    80005d3c:	e022                	sd	s0,0(sp)
    80005d3e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d40:	ffffc097          	auipc	ra,0xffffc
    80005d44:	c2a080e7          	jalr	-982(ra) # 8000196a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d48:	00d5179b          	slliw	a5,a0,0xd
    80005d4c:	0c201537          	lui	a0,0xc201
    80005d50:	953e                	add	a0,a0,a5
  return irq;
}
    80005d52:	4148                	lw	a0,4(a0)
    80005d54:	60a2                	ld	ra,8(sp)
    80005d56:	6402                	ld	s0,0(sp)
    80005d58:	0141                	addi	sp,sp,16
    80005d5a:	8082                	ret

0000000080005d5c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d5c:	1101                	addi	sp,sp,-32
    80005d5e:	ec06                	sd	ra,24(sp)
    80005d60:	e822                	sd	s0,16(sp)
    80005d62:	e426                	sd	s1,8(sp)
    80005d64:	1000                	addi	s0,sp,32
    80005d66:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d68:	ffffc097          	auipc	ra,0xffffc
    80005d6c:	c02080e7          	jalr	-1022(ra) # 8000196a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d70:	00d5151b          	slliw	a0,a0,0xd
    80005d74:	0c2017b7          	lui	a5,0xc201
    80005d78:	97aa                	add	a5,a5,a0
    80005d7a:	c3c4                	sw	s1,4(a5)
}
    80005d7c:	60e2                	ld	ra,24(sp)
    80005d7e:	6442                	ld	s0,16(sp)
    80005d80:	64a2                	ld	s1,8(sp)
    80005d82:	6105                	addi	sp,sp,32
    80005d84:	8082                	ret

0000000080005d86 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d86:	1141                	addi	sp,sp,-16
    80005d88:	e406                	sd	ra,8(sp)
    80005d8a:	e022                	sd	s0,0(sp)
    80005d8c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d8e:	479d                	li	a5,7
    80005d90:	06a7c963          	blt	a5,a0,80005e02 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005d94:	0001d797          	auipc	a5,0x1d
    80005d98:	26c78793          	addi	a5,a5,620 # 80023000 <disk>
    80005d9c:	00a78733          	add	a4,a5,a0
    80005da0:	6789                	lui	a5,0x2
    80005da2:	97ba                	add	a5,a5,a4
    80005da4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005da8:	e7ad                	bnez	a5,80005e12 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005daa:	00451793          	slli	a5,a0,0x4
    80005dae:	0001f717          	auipc	a4,0x1f
    80005db2:	25270713          	addi	a4,a4,594 # 80025000 <disk+0x2000>
    80005db6:	6314                	ld	a3,0(a4)
    80005db8:	96be                	add	a3,a3,a5
    80005dba:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005dbe:	6314                	ld	a3,0(a4)
    80005dc0:	96be                	add	a3,a3,a5
    80005dc2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005dc6:	6314                	ld	a3,0(a4)
    80005dc8:	96be                	add	a3,a3,a5
    80005dca:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005dce:	6318                	ld	a4,0(a4)
    80005dd0:	97ba                	add	a5,a5,a4
    80005dd2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005dd6:	0001d797          	auipc	a5,0x1d
    80005dda:	22a78793          	addi	a5,a5,554 # 80023000 <disk>
    80005dde:	97aa                	add	a5,a5,a0
    80005de0:	6509                	lui	a0,0x2
    80005de2:	953e                	add	a0,a0,a5
    80005de4:	4785                	li	a5,1
    80005de6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005dea:	0001f517          	auipc	a0,0x1f
    80005dee:	22e50513          	addi	a0,a0,558 # 80025018 <disk+0x2018>
    80005df2:	ffffc097          	auipc	ra,0xffffc
    80005df6:	3f0080e7          	jalr	1008(ra) # 800021e2 <wakeup>
}
    80005dfa:	60a2                	ld	ra,8(sp)
    80005dfc:	6402                	ld	s0,0(sp)
    80005dfe:	0141                	addi	sp,sp,16
    80005e00:	8082                	ret
    panic("free_desc 1");
    80005e02:	00003517          	auipc	a0,0x3
    80005e06:	99e50513          	addi	a0,a0,-1634 # 800087a0 <syscalls+0x328>
    80005e0a:	ffffa097          	auipc	ra,0xffffa
    80005e0e:	72e080e7          	jalr	1838(ra) # 80000538 <panic>
    panic("free_desc 2");
    80005e12:	00003517          	auipc	a0,0x3
    80005e16:	99e50513          	addi	a0,a0,-1634 # 800087b0 <syscalls+0x338>
    80005e1a:	ffffa097          	auipc	ra,0xffffa
    80005e1e:	71e080e7          	jalr	1822(ra) # 80000538 <panic>

0000000080005e22 <virtio_disk_init>:
{
    80005e22:	1101                	addi	sp,sp,-32
    80005e24:	ec06                	sd	ra,24(sp)
    80005e26:	e822                	sd	s0,16(sp)
    80005e28:	e426                	sd	s1,8(sp)
    80005e2a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e2c:	00003597          	auipc	a1,0x3
    80005e30:	99458593          	addi	a1,a1,-1644 # 800087c0 <syscalls+0x348>
    80005e34:	0001f517          	auipc	a0,0x1f
    80005e38:	2f450513          	addi	a0,a0,756 # 80025128 <disk+0x2128>
    80005e3c:	ffffb097          	auipc	ra,0xffffb
    80005e40:	d04080e7          	jalr	-764(ra) # 80000b40 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e44:	100017b7          	lui	a5,0x10001
    80005e48:	4398                	lw	a4,0(a5)
    80005e4a:	2701                	sext.w	a4,a4
    80005e4c:	747277b7          	lui	a5,0x74727
    80005e50:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e54:	0ef71163          	bne	a4,a5,80005f36 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e58:	100017b7          	lui	a5,0x10001
    80005e5c:	43dc                	lw	a5,4(a5)
    80005e5e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e60:	4705                	li	a4,1
    80005e62:	0ce79a63          	bne	a5,a4,80005f36 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e66:	100017b7          	lui	a5,0x10001
    80005e6a:	479c                	lw	a5,8(a5)
    80005e6c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e6e:	4709                	li	a4,2
    80005e70:	0ce79363          	bne	a5,a4,80005f36 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e74:	100017b7          	lui	a5,0x10001
    80005e78:	47d8                	lw	a4,12(a5)
    80005e7a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e7c:	554d47b7          	lui	a5,0x554d4
    80005e80:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e84:	0af71963          	bne	a4,a5,80005f36 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e88:	100017b7          	lui	a5,0x10001
    80005e8c:	4705                	li	a4,1
    80005e8e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e90:	470d                	li	a4,3
    80005e92:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e94:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005e96:	c7ffe737          	lui	a4,0xc7ffe
    80005e9a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005e9e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005ea0:	2701                	sext.w	a4,a4
    80005ea2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ea4:	472d                	li	a4,11
    80005ea6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ea8:	473d                	li	a4,15
    80005eaa:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005eac:	6705                	lui	a4,0x1
    80005eae:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005eb0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005eb4:	5bdc                	lw	a5,52(a5)
    80005eb6:	2781                	sext.w	a5,a5
  if(max == 0)
    80005eb8:	c7d9                	beqz	a5,80005f46 <virtio_disk_init+0x124>
  if(max < NUM)
    80005eba:	471d                	li	a4,7
    80005ebc:	08f77d63          	bgeu	a4,a5,80005f56 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005ec0:	100014b7          	lui	s1,0x10001
    80005ec4:	47a1                	li	a5,8
    80005ec6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005ec8:	6609                	lui	a2,0x2
    80005eca:	4581                	li	a1,0
    80005ecc:	0001d517          	auipc	a0,0x1d
    80005ed0:	13450513          	addi	a0,a0,308 # 80023000 <disk>
    80005ed4:	ffffb097          	auipc	ra,0xffffb
    80005ed8:	df8080e7          	jalr	-520(ra) # 80000ccc <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005edc:	0001d717          	auipc	a4,0x1d
    80005ee0:	12470713          	addi	a4,a4,292 # 80023000 <disk>
    80005ee4:	00c75793          	srli	a5,a4,0xc
    80005ee8:	2781                	sext.w	a5,a5
    80005eea:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005eec:	0001f797          	auipc	a5,0x1f
    80005ef0:	11478793          	addi	a5,a5,276 # 80025000 <disk+0x2000>
    80005ef4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005ef6:	0001d717          	auipc	a4,0x1d
    80005efa:	18a70713          	addi	a4,a4,394 # 80023080 <disk+0x80>
    80005efe:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005f00:	0001e717          	auipc	a4,0x1e
    80005f04:	10070713          	addi	a4,a4,256 # 80024000 <disk+0x1000>
    80005f08:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005f0a:	4705                	li	a4,1
    80005f0c:	00e78c23          	sb	a4,24(a5)
    80005f10:	00e78ca3          	sb	a4,25(a5)
    80005f14:	00e78d23          	sb	a4,26(a5)
    80005f18:	00e78da3          	sb	a4,27(a5)
    80005f1c:	00e78e23          	sb	a4,28(a5)
    80005f20:	00e78ea3          	sb	a4,29(a5)
    80005f24:	00e78f23          	sb	a4,30(a5)
    80005f28:	00e78fa3          	sb	a4,31(a5)
}
    80005f2c:	60e2                	ld	ra,24(sp)
    80005f2e:	6442                	ld	s0,16(sp)
    80005f30:	64a2                	ld	s1,8(sp)
    80005f32:	6105                	addi	sp,sp,32
    80005f34:	8082                	ret
    panic("could not find virtio disk");
    80005f36:	00003517          	auipc	a0,0x3
    80005f3a:	89a50513          	addi	a0,a0,-1894 # 800087d0 <syscalls+0x358>
    80005f3e:	ffffa097          	auipc	ra,0xffffa
    80005f42:	5fa080e7          	jalr	1530(ra) # 80000538 <panic>
    panic("virtio disk has no queue 0");
    80005f46:	00003517          	auipc	a0,0x3
    80005f4a:	8aa50513          	addi	a0,a0,-1878 # 800087f0 <syscalls+0x378>
    80005f4e:	ffffa097          	auipc	ra,0xffffa
    80005f52:	5ea080e7          	jalr	1514(ra) # 80000538 <panic>
    panic("virtio disk max queue too short");
    80005f56:	00003517          	auipc	a0,0x3
    80005f5a:	8ba50513          	addi	a0,a0,-1862 # 80008810 <syscalls+0x398>
    80005f5e:	ffffa097          	auipc	ra,0xffffa
    80005f62:	5da080e7          	jalr	1498(ra) # 80000538 <panic>

0000000080005f66 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f66:	7119                	addi	sp,sp,-128
    80005f68:	fc86                	sd	ra,120(sp)
    80005f6a:	f8a2                	sd	s0,112(sp)
    80005f6c:	f4a6                	sd	s1,104(sp)
    80005f6e:	f0ca                	sd	s2,96(sp)
    80005f70:	ecce                	sd	s3,88(sp)
    80005f72:	e8d2                	sd	s4,80(sp)
    80005f74:	e4d6                	sd	s5,72(sp)
    80005f76:	e0da                	sd	s6,64(sp)
    80005f78:	fc5e                	sd	s7,56(sp)
    80005f7a:	f862                	sd	s8,48(sp)
    80005f7c:	f466                	sd	s9,40(sp)
    80005f7e:	f06a                	sd	s10,32(sp)
    80005f80:	ec6e                	sd	s11,24(sp)
    80005f82:	0100                	addi	s0,sp,128
    80005f84:	8aaa                	mv	s5,a0
    80005f86:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f88:	00c52c83          	lw	s9,12(a0)
    80005f8c:	001c9c9b          	slliw	s9,s9,0x1
    80005f90:	1c82                	slli	s9,s9,0x20
    80005f92:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005f96:	0001f517          	auipc	a0,0x1f
    80005f9a:	19250513          	addi	a0,a0,402 # 80025128 <disk+0x2128>
    80005f9e:	ffffb097          	auipc	ra,0xffffb
    80005fa2:	c32080e7          	jalr	-974(ra) # 80000bd0 <acquire>
  for(int i = 0; i < 3; i++){
    80005fa6:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005fa8:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005faa:	0001dc17          	auipc	s8,0x1d
    80005fae:	056c0c13          	addi	s8,s8,86 # 80023000 <disk>
    80005fb2:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80005fb4:	4b0d                	li	s6,3
    80005fb6:	a0ad                	j	80006020 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80005fb8:	00fc0733          	add	a4,s8,a5
    80005fbc:	975e                	add	a4,a4,s7
    80005fbe:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005fc2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005fc4:	0207c563          	bltz	a5,80005fee <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005fc8:	2905                	addiw	s2,s2,1
    80005fca:	0611                	addi	a2,a2,4
    80005fcc:	19690d63          	beq	s2,s6,80006166 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80005fd0:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005fd2:	0001f717          	auipc	a4,0x1f
    80005fd6:	04670713          	addi	a4,a4,70 # 80025018 <disk+0x2018>
    80005fda:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005fdc:	00074683          	lbu	a3,0(a4)
    80005fe0:	fee1                	bnez	a3,80005fb8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005fe2:	2785                	addiw	a5,a5,1
    80005fe4:	0705                	addi	a4,a4,1
    80005fe6:	fe979be3          	bne	a5,s1,80005fdc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005fea:	57fd                	li	a5,-1
    80005fec:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005fee:	01205d63          	blez	s2,80006008 <virtio_disk_rw+0xa2>
    80005ff2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80005ff4:	000a2503          	lw	a0,0(s4)
    80005ff8:	00000097          	auipc	ra,0x0
    80005ffc:	d8e080e7          	jalr	-626(ra) # 80005d86 <free_desc>
      for(int j = 0; j < i; j++)
    80006000:	2d85                	addiw	s11,s11,1
    80006002:	0a11                	addi	s4,s4,4
    80006004:	ffb918e3          	bne	s2,s11,80005ff4 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006008:	0001f597          	auipc	a1,0x1f
    8000600c:	12058593          	addi	a1,a1,288 # 80025128 <disk+0x2128>
    80006010:	0001f517          	auipc	a0,0x1f
    80006014:	00850513          	addi	a0,a0,8 # 80025018 <disk+0x2018>
    80006018:	ffffc097          	auipc	ra,0xffffc
    8000601c:	03e080e7          	jalr	62(ra) # 80002056 <sleep>
  for(int i = 0; i < 3; i++){
    80006020:	f8040a13          	addi	s4,s0,-128
{
    80006024:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006026:	894e                	mv	s2,s3
    80006028:	b765                	j	80005fd0 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000602a:	0001f697          	auipc	a3,0x1f
    8000602e:	fd66b683          	ld	a3,-42(a3) # 80025000 <disk+0x2000>
    80006032:	96ba                	add	a3,a3,a4
    80006034:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006038:	0001d817          	auipc	a6,0x1d
    8000603c:	fc880813          	addi	a6,a6,-56 # 80023000 <disk>
    80006040:	0001f697          	auipc	a3,0x1f
    80006044:	fc068693          	addi	a3,a3,-64 # 80025000 <disk+0x2000>
    80006048:	6290                	ld	a2,0(a3)
    8000604a:	963a                	add	a2,a2,a4
    8000604c:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80006050:	0015e593          	ori	a1,a1,1
    80006054:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006058:	f8842603          	lw	a2,-120(s0)
    8000605c:	628c                	ld	a1,0(a3)
    8000605e:	972e                	add	a4,a4,a1
    80006060:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006064:	20050593          	addi	a1,a0,512
    80006068:	0592                	slli	a1,a1,0x4
    8000606a:	95c2                	add	a1,a1,a6
    8000606c:	577d                	li	a4,-1
    8000606e:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006072:	00461713          	slli	a4,a2,0x4
    80006076:	6290                	ld	a2,0(a3)
    80006078:	963a                	add	a2,a2,a4
    8000607a:	03078793          	addi	a5,a5,48
    8000607e:	97c2                	add	a5,a5,a6
    80006080:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80006082:	629c                	ld	a5,0(a3)
    80006084:	97ba                	add	a5,a5,a4
    80006086:	4605                	li	a2,1
    80006088:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000608a:	629c                	ld	a5,0(a3)
    8000608c:	97ba                	add	a5,a5,a4
    8000608e:	4809                	li	a6,2
    80006090:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006094:	629c                	ld	a5,0(a3)
    80006096:	973e                	add	a4,a4,a5
    80006098:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000609c:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    800060a0:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800060a4:	6698                	ld	a4,8(a3)
    800060a6:	00275783          	lhu	a5,2(a4)
    800060aa:	8b9d                	andi	a5,a5,7
    800060ac:	0786                	slli	a5,a5,0x1
    800060ae:	97ba                	add	a5,a5,a4
    800060b0:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    800060b4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800060b8:	6698                	ld	a4,8(a3)
    800060ba:	00275783          	lhu	a5,2(a4)
    800060be:	2785                	addiw	a5,a5,1
    800060c0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800060c4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800060c8:	100017b7          	lui	a5,0x10001
    800060cc:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800060d0:	004aa783          	lw	a5,4(s5)
    800060d4:	02c79163          	bne	a5,a2,800060f6 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    800060d8:	0001f917          	auipc	s2,0x1f
    800060dc:	05090913          	addi	s2,s2,80 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800060e0:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800060e2:	85ca                	mv	a1,s2
    800060e4:	8556                	mv	a0,s5
    800060e6:	ffffc097          	auipc	ra,0xffffc
    800060ea:	f70080e7          	jalr	-144(ra) # 80002056 <sleep>
  while(b->disk == 1) {
    800060ee:	004aa783          	lw	a5,4(s5)
    800060f2:	fe9788e3          	beq	a5,s1,800060e2 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    800060f6:	f8042903          	lw	s2,-128(s0)
    800060fa:	20090793          	addi	a5,s2,512
    800060fe:	00479713          	slli	a4,a5,0x4
    80006102:	0001d797          	auipc	a5,0x1d
    80006106:	efe78793          	addi	a5,a5,-258 # 80023000 <disk>
    8000610a:	97ba                	add	a5,a5,a4
    8000610c:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006110:	0001f997          	auipc	s3,0x1f
    80006114:	ef098993          	addi	s3,s3,-272 # 80025000 <disk+0x2000>
    80006118:	00491713          	slli	a4,s2,0x4
    8000611c:	0009b783          	ld	a5,0(s3)
    80006120:	97ba                	add	a5,a5,a4
    80006122:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006126:	854a                	mv	a0,s2
    80006128:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000612c:	00000097          	auipc	ra,0x0
    80006130:	c5a080e7          	jalr	-934(ra) # 80005d86 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006134:	8885                	andi	s1,s1,1
    80006136:	f0ed                	bnez	s1,80006118 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006138:	0001f517          	auipc	a0,0x1f
    8000613c:	ff050513          	addi	a0,a0,-16 # 80025128 <disk+0x2128>
    80006140:	ffffb097          	auipc	ra,0xffffb
    80006144:	b44080e7          	jalr	-1212(ra) # 80000c84 <release>
}
    80006148:	70e6                	ld	ra,120(sp)
    8000614a:	7446                	ld	s0,112(sp)
    8000614c:	74a6                	ld	s1,104(sp)
    8000614e:	7906                	ld	s2,96(sp)
    80006150:	69e6                	ld	s3,88(sp)
    80006152:	6a46                	ld	s4,80(sp)
    80006154:	6aa6                	ld	s5,72(sp)
    80006156:	6b06                	ld	s6,64(sp)
    80006158:	7be2                	ld	s7,56(sp)
    8000615a:	7c42                	ld	s8,48(sp)
    8000615c:	7ca2                	ld	s9,40(sp)
    8000615e:	7d02                	ld	s10,32(sp)
    80006160:	6de2                	ld	s11,24(sp)
    80006162:	6109                	addi	sp,sp,128
    80006164:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006166:	f8042503          	lw	a0,-128(s0)
    8000616a:	20050793          	addi	a5,a0,512
    8000616e:	0792                	slli	a5,a5,0x4
  if(write)
    80006170:	0001d817          	auipc	a6,0x1d
    80006174:	e9080813          	addi	a6,a6,-368 # 80023000 <disk>
    80006178:	00f80733          	add	a4,a6,a5
    8000617c:	01a036b3          	snez	a3,s10
    80006180:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80006184:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006188:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000618c:	7679                	lui	a2,0xffffe
    8000618e:	963e                	add	a2,a2,a5
    80006190:	0001f697          	auipc	a3,0x1f
    80006194:	e7068693          	addi	a3,a3,-400 # 80025000 <disk+0x2000>
    80006198:	6298                	ld	a4,0(a3)
    8000619a:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000619c:	0a878593          	addi	a1,a5,168
    800061a0:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    800061a2:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800061a4:	6298                	ld	a4,0(a3)
    800061a6:	9732                	add	a4,a4,a2
    800061a8:	45c1                	li	a1,16
    800061aa:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800061ac:	6298                	ld	a4,0(a3)
    800061ae:	9732                	add	a4,a4,a2
    800061b0:	4585                	li	a1,1
    800061b2:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800061b6:	f8442703          	lw	a4,-124(s0)
    800061ba:	628c                	ld	a1,0(a3)
    800061bc:	962e                	add	a2,a2,a1
    800061be:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    800061c2:	0712                	slli	a4,a4,0x4
    800061c4:	6290                	ld	a2,0(a3)
    800061c6:	963a                	add	a2,a2,a4
    800061c8:	058a8593          	addi	a1,s5,88
    800061cc:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800061ce:	6294                	ld	a3,0(a3)
    800061d0:	96ba                	add	a3,a3,a4
    800061d2:	40000613          	li	a2,1024
    800061d6:	c690                	sw	a2,8(a3)
  if(write)
    800061d8:	e40d19e3          	bnez	s10,8000602a <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800061dc:	0001f697          	auipc	a3,0x1f
    800061e0:	e246b683          	ld	a3,-476(a3) # 80025000 <disk+0x2000>
    800061e4:	96ba                	add	a3,a3,a4
    800061e6:	4609                	li	a2,2
    800061e8:	00c69623          	sh	a2,12(a3)
    800061ec:	b5b1                	j	80006038 <virtio_disk_rw+0xd2>

00000000800061ee <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800061ee:	1101                	addi	sp,sp,-32
    800061f0:	ec06                	sd	ra,24(sp)
    800061f2:	e822                	sd	s0,16(sp)
    800061f4:	e426                	sd	s1,8(sp)
    800061f6:	e04a                	sd	s2,0(sp)
    800061f8:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800061fa:	0001f517          	auipc	a0,0x1f
    800061fe:	f2e50513          	addi	a0,a0,-210 # 80025128 <disk+0x2128>
    80006202:	ffffb097          	auipc	ra,0xffffb
    80006206:	9ce080e7          	jalr	-1586(ra) # 80000bd0 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000620a:	10001737          	lui	a4,0x10001
    8000620e:	533c                	lw	a5,96(a4)
    80006210:	8b8d                	andi	a5,a5,3
    80006212:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006214:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006218:	0001f797          	auipc	a5,0x1f
    8000621c:	de878793          	addi	a5,a5,-536 # 80025000 <disk+0x2000>
    80006220:	6b94                	ld	a3,16(a5)
    80006222:	0207d703          	lhu	a4,32(a5)
    80006226:	0026d783          	lhu	a5,2(a3)
    8000622a:	06f70163          	beq	a4,a5,8000628c <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000622e:	0001d917          	auipc	s2,0x1d
    80006232:	dd290913          	addi	s2,s2,-558 # 80023000 <disk>
    80006236:	0001f497          	auipc	s1,0x1f
    8000623a:	dca48493          	addi	s1,s1,-566 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000623e:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006242:	6898                	ld	a4,16(s1)
    80006244:	0204d783          	lhu	a5,32(s1)
    80006248:	8b9d                	andi	a5,a5,7
    8000624a:	078e                	slli	a5,a5,0x3
    8000624c:	97ba                	add	a5,a5,a4
    8000624e:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006250:	20078713          	addi	a4,a5,512
    80006254:	0712                	slli	a4,a4,0x4
    80006256:	974a                	add	a4,a4,s2
    80006258:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000625c:	e731                	bnez	a4,800062a8 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000625e:	20078793          	addi	a5,a5,512
    80006262:	0792                	slli	a5,a5,0x4
    80006264:	97ca                	add	a5,a5,s2
    80006266:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006268:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000626c:	ffffc097          	auipc	ra,0xffffc
    80006270:	f76080e7          	jalr	-138(ra) # 800021e2 <wakeup>

    disk.used_idx += 1;
    80006274:	0204d783          	lhu	a5,32(s1)
    80006278:	2785                	addiw	a5,a5,1
    8000627a:	17c2                	slli	a5,a5,0x30
    8000627c:	93c1                	srli	a5,a5,0x30
    8000627e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006282:	6898                	ld	a4,16(s1)
    80006284:	00275703          	lhu	a4,2(a4)
    80006288:	faf71be3          	bne	a4,a5,8000623e <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000628c:	0001f517          	auipc	a0,0x1f
    80006290:	e9c50513          	addi	a0,a0,-356 # 80025128 <disk+0x2128>
    80006294:	ffffb097          	auipc	ra,0xffffb
    80006298:	9f0080e7          	jalr	-1552(ra) # 80000c84 <release>
}
    8000629c:	60e2                	ld	ra,24(sp)
    8000629e:	6442                	ld	s0,16(sp)
    800062a0:	64a2                	ld	s1,8(sp)
    800062a2:	6902                	ld	s2,0(sp)
    800062a4:	6105                	addi	sp,sp,32
    800062a6:	8082                	ret
      panic("virtio_disk_intr status");
    800062a8:	00002517          	auipc	a0,0x2
    800062ac:	58850513          	addi	a0,a0,1416 # 80008830 <syscalls+0x3b8>
    800062b0:	ffffa097          	auipc	ra,0xffffa
    800062b4:	288080e7          	jalr	648(ra) # 80000538 <panic>
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
