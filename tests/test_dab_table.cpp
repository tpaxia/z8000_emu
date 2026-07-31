#include <cstdint>
#include <cstdio>

#include "z8000/z8000dab.h"

static bool valid_bcd(uint8_t value)
{
	return (value & 0x0f) <= 9 && (value >> 4) <= 9;
}

int main()
{
	unsigned failures = 0;
	unsigned cases = 0;
	unsigned quirks = 0;

	for (unsigned a = 0; a <= 0xff; ++a)
	{
		if (!valid_bcd(a))
			continue;
		for (unsigned b = 0; b <= 0xff; ++b)
		{
			if (!valid_bcd(b))
				continue;
			for (unsigned carry_in = 0; carry_in <= 1; ++carry_in)
			{
				const unsigned a_decimal = 10 * (a >> 4) + (a & 0x0f);
				const unsigned b_decimal = 10 * (b >> 4) + (b & 0x0f);

				const int add_binary = int(a) + int(b) + int(carry_in);
				const uint8_t add_raw = add_binary;
				const bool add_carry = add_binary > 0xff;
				const bool add_half =
					((add_raw & 0x0f) < (a & 0x0f)) ||
					(((add_raw & 0x0f) == (a & 0x0f)) && (b & 0x0f));
				const uint16_t add_got = Z8000_dab[
					add_raw | (add_carry ? 0x100 : 0) | (add_half ? 0x200 : 0)];
				const unsigned add_decimal = a_decimal + b_decimal + carry_in;
				uint16_t add_expected =
					(add_decimal >= 100 ? 0x100 : 0) |
					(((add_decimal / 10) % 10) << 4) | (add_decimal % 10);

				/* Silicon quirk: with neither carry nor half carry in, a
				   low digit correction that ripples out of the byte does
				   not produce a carry out - the high digit test runs on
				   the already wrapped value and sees a digit in range.
				   DAB returns the wrapped result with C clear, which is
				   decimally wrong; the Z8001 does this and the emulator
				   must match.  See dab_sweep_add_c0h0. */
				if (!add_carry && !add_half && (add_raw + 0x06) > 0xff)
				{
					add_expected = (add_raw + 0x06) & 0xff;
					++quirks;
				}

				if (add_got != add_expected)
					++failures;
				++cases;

				const int sub_binary = int(a) - int(b) - int(carry_in);
				const uint8_t sub_raw = sub_binary;
				const bool sub_carry = sub_binary < 0;
				const bool sub_half =
					((sub_raw & 0x0f) > (a & 0x0f)) ||
					(((sub_raw & 0x0f) == (a & 0x0f)) && (b & 0x0f));
				const uint16_t sub_got = Z8000_dab[
					0x400 | sub_raw | (sub_carry ? 0x100 : 0) |
					(sub_half ? 0x200 : 0)];
				int sub_decimal = int(a_decimal) - int(b_decimal) - int(carry_in);
				const bool sub_borrow = sub_decimal < 0;
				if (sub_borrow)
					sub_decimal += 100;
				const uint16_t sub_expected =
					(sub_borrow ? 0x100 : 0) |
					((sub_decimal / 10) << 4) | (sub_decimal % 10);
				if (sub_got != sub_expected)
					++failures;
				++cases;
			}
		}
	}

	if (failures)
	{
		std::fprintf(stderr, "DAB: %u of %u valid BCD cases failed\n", failures, cases);
		return 1;
	}

	std::printf("DAB: all %u valid BCD cases passed"
		" (%u silicon carry-ripple quirks)\n", cases, quirks);
	return 0;
}
