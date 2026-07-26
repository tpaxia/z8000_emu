// license:BSD-3-Clause
// copyright-holders:Juergen Buchmueller,Ernesto Corvi
#include <cstdio>

#define CF  0x100
#define HF  0x200
#define DF  0x400

int dab[0x800];

int main(void)
{
	int i;

	for (i = 0; i < DF; i++) {
		const int value = i & 0xff;
		const bool carry = i & CF;
		const bool half_carry = i & HF;

		/* ADDB/ADCB: correct the low digit for H or A-F, and the
		   high digit for C or a value above packed BCD 99. */
		const bool add_carry = carry || value > 0x99;
		int add_result = value;
		if (half_carry || (value & 0x0f) > 9)
			add_result += 0x06;
		if (add_carry)
			add_result += 0x60;
		dab[i] = (add_carry ? CF : 0) | (add_result & 0xff);

		/* SUBB/SBCB: C represents the high-digit borrow and H the
		   low-digit borrow.  H alone must not set carry. */
		int sub_result = value;
		if (half_carry)
			sub_result += 0xfa; // -0x06 modulo 256
		if (carry)
			sub_result += 0xa0; // -0x60 modulo 256
		dab[DF+i] = (carry ? CF : 0) | (sub_result & 0xff);
	}

	printf("/************************************************ \n");
	printf(" * Result table for Z8000 DAB instruction         \n");
	printf(" *                                                \n");
	printf(" * bits    description                            \n");
	printf(" * ---------------------------------------------- \n");
	printf(" * 0..7    destination value                      \n");
	printf(" * 8       carry flag before                      \n");
	printf(" * 9       half carry flag before                 \n");
	printf(" * 10      D flag (0 add/adc, 1 sub/sbc)          \n");
	printf(" *                                                \n");
	printf(" * result  description                            \n");
	printf(" * ---------------------------------------------- \n");
	printf(" * 0..7    result value                           \n");
	printf(" * 8       carry flag after                       \n");
	printf(" ************************************************/\n");
	printf("static const uint16_t Z8000_dab[0x800] = {\n");
	for (i = 0; i < 0x800; i++) {
		if ((i & 0x3ff) == 0) {
			if (i & 0x400)
				printf("\t/* sub/sbc results */\n");
			else
				printf("\t/* add/adc results */\n");
		}
		if ((i & 7) == 0) printf("\t");
		printf("0x%03x,",dab[i]);
		if ((i & 7) == 7) printf("\n");
	}
	printf("};\n");

	return 0;
}
