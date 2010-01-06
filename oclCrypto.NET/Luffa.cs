using System;

namespace oclCrypto
{
	class Luffa
	{
		public const int StateSize = 3 * 32; // Luffa-256
		public const int MessageSize = 32;

		public static unsafe void InitState (byte[] state)
		{
			fixed (byte* pstate = state) {
				uint *p = (uint*)pstate;
				for (int i = 0; i < state.Length; i += StateSize) {
					for (int q = 0; q < 24; q ++)
						p[i / 4 + q] = StartingValues[q];
				}
			}
		}

		public unsafe static void Update (byte[] data, int offset, int size, byte[] state)
		{
			int numOfStates = state.Length / StateSize;
			if (size / MessageSize != numOfStates)
				throw new ArgumentOutOfRangeException ();

			uint* m = stackalloc uint[8];
			fixed (byte* pdata = data, pstate = state)
			fixed (uint* c = InitValues) {
				uint* ps = (uint*)pstate;
				for (int i = 0, j = 0; i < state.Length; i += StateSize, j += MessageSize) {
					Copy (m, pdata + j + offset);
					HashCore256 (ps + (i / 4), m, c);
				}
			}
		}

		static unsafe void Copy (uint* m, byte* buf)
		{
			m[0] = ((uint)buf[0] << 24) | ((uint)buf[1] << 16) | ((uint)buf[2] << 8) | buf[3];
			m[1] = ((uint)buf[4] << 24) | ((uint)buf[5] << 16) | ((uint)buf[6] << 8) | buf[7];
			m[2] = ((uint)buf[8] << 24) | ((uint)buf[9] << 16) | ((uint)buf[10] << 8) | buf[11];
			m[3] = ((uint)buf[12] << 24) | ((uint)buf[13] << 16) | ((uint)buf[14] << 8) | buf[15];
			m[4] = ((uint)buf[16] << 24) | ((uint)buf[17] << 16) | ((uint)buf[18] << 8) | buf[19];
			m[5] = ((uint)buf[20] << 24) | ((uint)buf[21] << 16) | ((uint)buf[22] << 8) | buf[23];
			m[6] = ((uint)buf[24] << 24) | ((uint)buf[25] << 16) | ((uint)buf[26] << 8) | buf[27];
			m[7] = ((uint)buf[28] << 24) | ((uint)buf[29] << 16) | ((uint)buf[30] << 8) | buf[31];
		}

		static unsafe void HashCore256 (uint* v, uint* m, uint* c)
		{
			uint t0 = v[0] ^ v[8] ^ v[16];
			uint t1 = v[1] ^ v[9] ^ v[17];
			uint t2 = v[2] ^ v[10] ^ v[18];
			uint t3 = v[3] ^ v[11] ^ v[19];
			uint t4 = v[4] ^ v[12] ^ v[20];
			uint t5 = v[5] ^ v[13] ^ v[21];
			uint t6 = v[6] ^ v[14] ^ v[22];
			uint t7 = v[7] ^ v[15] ^ v[23];
			uint m0 = m[0], m1 = m[1], m2 = m[2], m3 = m[3];
			uint m4 = m[4], m5 = m[5], m6 = m[6], m7 = m[7];

			uint tmp = t7; t7 = t6; t6 = t5; t5 = t4;
			t4 = t3 ^ tmp; t3 = t2 ^ tmp; t2 = t1;
			t1 = t0 ^ tmp; t0 = tmp;

			v[0] ^= t0 ^ m0; v[1] ^= t1 ^ m1;
			v[2] ^= t2 ^ m2; v[3] ^= t3 ^ m3;
			v[4] ^= t4 ^ m4; v[5] ^= t5 ^ m5;
			v[6] ^= t6 ^ m6; v[7] ^= t7 ^ m7;

			tmp = m7; m7 = m6; m6 = m5; m5 = m4;
			m4 = m3 ^ tmp; m3 = m2 ^ tmp; m2 = m1;
			m1 = m0 ^ tmp; m0 = tmp;

			v[8] ^= t0 ^ m0; v[9] ^= t1 ^ m1;
			v[10] ^= t2 ^ m2; v[11] ^= t3 ^ m3;
			v[12] ^= t4 ^ m4; v[13] ^= t5 ^ m5;
			v[14] ^= t6 ^ m6; v[15] ^= t7 ^ m7;

			tmp = m7; m7 = m6; m6 = m5; m5 = m4;
			m4 = m3 ^ tmp; m3 = m2 ^ tmp; m2 = m1;
			m1 = m0 ^ tmp; m0 = tmp;

			v[16] ^= t0 ^ m0; v[17] ^= t1 ^ m1;
			v[18] ^= t2 ^ m2; v[19] ^= t3 ^ m3;
			v[20] ^= t4 ^ m4; v[21] ^= t5 ^ m5;
			v[22] ^= t6 ^ m6; v[23] ^= t7 ^ m7;

			Permute (v, 0, c);
			Permute (v + 8, 1, c + 16);
			Permute (v + 16, 2, c + 32);
		}

		static unsafe void Permute (uint* v, int j, uint* c)
		{
			uint tmp;
			uint v0 = v[0], v1 = v[1], v2 = v[2], v3 = v[3];
			uint v4 = v[4], v5 = v[5], v6 = v[6], v7 = v[7];

			// Tweak
			if (j != 0) {
				v4 = (v4 << j) | (v4 >> (32 - j));
				v5 = (v5 << j) | (v5 >> (32 - j));
				v6 = (v6 << j) | (v6 >> (32 - j));
				v7 = (v7 << j) | (v7 >> (32 - j));
			}

			/* Iteration.1 */
			// SubCrumb (from p.23, Implementations of SubCrumb for Intel Core2)
			tmp = v0; v0 |= v1; v2 ^= v3; v1 = ~v1; v0 ^= v3; v3 &= tmp;
			v1 ^= v3; v3 ^= v2; v2 &= v0; v0 = ~v0; v2 ^= v1; v1 |= v3;
			tmp^= v1; v3 ^= v2; v2 &= v1; v1 ^= v0; v0 = tmp;
			tmp = v5; v5 |= v6; v7 ^= v4; v6 = ~v6; v5 ^= v4; v4 &= tmp;
			v6 ^= v4; v4 ^= v7; v7 &= v5; v5 = ~v5; v7 ^= v6; v6 |= v4;
			tmp^= v6; v4 ^= v7; v7 &= v6; v6 ^= v5; v5 = tmp;
			// MixWord & Add Constant
			v4 ^= v0; v5 ^= v1; v6 ^= v2; v7 ^= v3;
			v0 = ((v0 << 2) | (v0 >> 30)) ^ v4;
			v1 = ((v1 << 2) | (v1 >> 30)) ^ v5;
			v2 = ((v2 << 2) | (v2 >> 30)) ^ v6;
			v3 = ((v3 << 2) | (v3 >> 30)) ^ v7;
			v4 = ((v4 << 14) | (v4 >> 18)) ^ v0;
			v5 = ((v5 << 14) | (v5 >> 18)) ^ v1;
			v6 = ((v6 << 14) | (v6 >> 18)) ^ v2;
			v7 = ((v7 << 14) | (v7 >> 18)) ^ v3;
			v0 = ((v0 << 10) | (v0 >> 22)) ^ v4 ^ c[0]; // Add Constant
			v1 = ((v1 << 10) | (v1 >> 22)) ^ v5;
			v2 = ((v2 << 10) | (v2 >> 22)) ^ v6;
			v3 = ((v3 << 10) | (v3 >> 22)) ^ v7;
			v4 = ((v4 << 1) | (v4 >> 31)) ^ c[1];       // Add Constant
			v5 = (v5 << 1) | (v5 >> 31);
			v6 = (v6 << 1) | (v6 >> 31);
			v7 = (v7 << 1) | (v7 >> 31);

			/* Iteration.2 */
			tmp = v0; v0 |= v1; v2 ^= v3; v1 = ~v1; v0 ^= v3; v3 &= tmp;
			v1 ^= v3; v3 ^= v2; v2 &= v0; v0 = ~v0; v2 ^= v1; v1 |= v3;
			tmp^= v1; v3 ^= v2; v2 &= v1; v1 ^= v0; v0 = tmp;
			tmp = v5; v5 |= v6; v7 ^= v4; v6 = ~v6; v5 ^= v4; v4 &= tmp;
			v6 ^= v4; v4 ^= v7; v7 &= v5; v5 = ~v5; v7 ^= v6; v6 |= v4;
			tmp^= v6; v4 ^= v7; v7 &= v6; v6 ^= v5; v5 = tmp;
			v4 ^= v0; v5 ^= v1; v6 ^= v2; v7 ^= v3;
			v0 = ((v0 << 2) | (v0 >> 30)) ^ v4;
			v1 = ((v1 << 2) | (v1 >> 30)) ^ v5;
			v2 = ((v2 << 2) | (v2 >> 30)) ^ v6;
			v3 = ((v3 << 2) | (v3 >> 30)) ^ v7;
			v4 = ((v4 << 14) | (v4 >> 18)) ^ v0;
			v5 = ((v5 << 14) | (v5 >> 18)) ^ v1;
			v6 = ((v6 << 14) | (v6 >> 18)) ^ v2;
			v7 = ((v7 << 14) | (v7 >> 18)) ^ v3;
			v0 = ((v0 << 10) | (v0 >> 22)) ^ v4 ^ c[2];
			v1 = ((v1 << 10) | (v1 >> 22)) ^ v5;
			v2 = ((v2 << 10) | (v2 >> 22)) ^ v6;
			v3 = ((v3 << 10) | (v3 >> 22)) ^ v7;
			v4 = ((v4 << 1) | (v4 >> 31)) ^ c[3];
			v5 = (v5 << 1) | (v5 >> 31);
			v6 = (v6 << 1) | (v6 >> 31);
			v7 = (v7 << 1) | (v7 >> 31);

			/* Iteration.3 */
			tmp = v0; v0 |= v1; v2 ^= v3; v1 = ~v1; v0 ^= v3; v3 &= tmp;
			v1 ^= v3; v3 ^= v2; v2 &= v0; v0 = ~v0; v2 ^= v1; v1 |= v3;
			tmp^= v1; v3 ^= v2; v2 &= v1; v1 ^= v0; v0 = tmp;
			tmp = v5; v5 |= v6; v7 ^= v4; v6 = ~v6; v5 ^= v4; v4 &= tmp;
			v6 ^= v4; v4 ^= v7; v7 &= v5; v5 = ~v5; v7 ^= v6; v6 |= v4;
			tmp^= v6; v4 ^= v7; v7 &= v6; v6 ^= v5; v5 = tmp;
			v4 ^= v0; v5 ^= v1; v6 ^= v2; v7 ^= v3;
			v0 = ((v0 << 2) | (v0 >> 30)) ^ v4;
			v1 = ((v1 << 2) | (v1 >> 30)) ^ v5;
			v2 = ((v2 << 2) | (v2 >> 30)) ^ v6;
			v3 = ((v3 << 2) | (v3 >> 30)) ^ v7;
			v4 = ((v4 << 14) | (v4 >> 18)) ^ v0;
			v5 = ((v5 << 14) | (v5 >> 18)) ^ v1;
			v6 = ((v6 << 14) | (v6 >> 18)) ^ v2;
			v7 = ((v7 << 14) | (v7 >> 18)) ^ v3;
			v0 = ((v0 << 10) | (v0 >> 22)) ^ v4 ^ c[4];
			v1 = ((v1 << 10) | (v1 >> 22)) ^ v5;
			v2 = ((v2 << 10) | (v2 >> 22)) ^ v6;
			v3 = ((v3 << 10) | (v3 >> 22)) ^ v7;
			v4 = ((v4 << 1) | (v4 >> 31)) ^ c[5];
			v5 = (v5 << 1) | (v5 >> 31);
			v6 = (v6 << 1) | (v6 >> 31);
			v7 = (v7 << 1) | (v7 >> 31);

			/* Iteration.4 */
			tmp = v0; v0 |= v1; v2 ^= v3; v1 = ~v1; v0 ^= v3; v3 &= tmp;
			v1 ^= v3; v3 ^= v2; v2 &= v0; v0 = ~v0; v2 ^= v1; v1 |= v3;
			tmp^= v1; v3 ^= v2; v2 &= v1; v1 ^= v0; v0 = tmp;
			tmp = v5; v5 |= v6; v7 ^= v4; v6 = ~v6; v5 ^= v4; v4 &= tmp;
			v6 ^= v4; v4 ^= v7; v7 &= v5; v5 = ~v5; v7 ^= v6; v6 |= v4;
			tmp^= v6; v4 ^= v7; v7 &= v6; v6 ^= v5; v5 = tmp;
			v4 ^= v0; v5 ^= v1; v6 ^= v2; v7 ^= v3;
			v0 = ((v0 << 2) | (v0 >> 30)) ^ v4;
			v1 = ((v1 << 2) | (v1 >> 30)) ^ v5;
			v2 = ((v2 << 2) | (v2 >> 30)) ^ v6;
			v3 = ((v3 << 2) | (v3 >> 30)) ^ v7;
			v4 = ((v4 << 14) | (v4 >> 18)) ^ v0;
			v5 = ((v5 << 14) | (v5 >> 18)) ^ v1;
			v6 = ((v6 << 14) | (v6 >> 18)) ^ v2;
			v7 = ((v7 << 14) | (v7 >> 18)) ^ v3;
			v0 = ((v0 << 10) | (v0 >> 22)) ^ v4 ^ c[6];
			v1 = ((v1 << 10) | (v1 >> 22)) ^ v5;
			v2 = ((v2 << 10) | (v2 >> 22)) ^ v6;
			v3 = ((v3 << 10) | (v3 >> 22)) ^ v7;
			v4 = ((v4 << 1) | (v4 >> 31)) ^ c[7];
			v5 = (v5 << 1) | (v5 >> 31);
			v6 = (v6 << 1) | (v6 >> 31);
			v7 = (v7 << 1) | (v7 >> 31);

			/* Iteration.5 */
			tmp = v0; v0 |= v1; v2 ^= v3; v1 = ~v1; v0 ^= v3; v3 &= tmp;
			v1 ^= v3; v3 ^= v2; v2 &= v0; v0 = ~v0; v2 ^= v1; v1 |= v3;
			tmp^= v1; v3 ^= v2; v2 &= v1; v1 ^= v0; v0 = tmp;
			tmp = v5; v5 |= v6; v7 ^= v4; v6 = ~v6; v5 ^= v4; v4 &= tmp;
			v6 ^= v4; v4 ^= v7; v7 &= v5; v5 = ~v5; v7 ^= v6; v6 |= v4;
			tmp^= v6; v4 ^= v7; v7 &= v6; v6 ^= v5; v5 = tmp;
			v4 ^= v0; v5 ^= v1; v6 ^= v2; v7 ^= v3;
			v0 = ((v0 << 2) | (v0 >> 30)) ^ v4;
			v1 = ((v1 << 2) | (v1 >> 30)) ^ v5;
			v2 = ((v2 << 2) | (v2 >> 30)) ^ v6;
			v3 = ((v3 << 2) | (v3 >> 30)) ^ v7;
			v4 = ((v4 << 14) | (v4 >> 18)) ^ v0;
			v5 = ((v5 << 14) | (v5 >> 18)) ^ v1;
			v6 = ((v6 << 14) | (v6 >> 18)) ^ v2;
			v7 = ((v7 << 14) | (v7 >> 18)) ^ v3;
			v0 = ((v0 << 10) | (v0 >> 22)) ^ v4 ^ c[8];
			v1 = ((v1 << 10) | (v1 >> 22)) ^ v5;
			v2 = ((v2 << 10) | (v2 >> 22)) ^ v6;
			v3 = ((v3 << 10) | (v3 >> 22)) ^ v7;
			v4 = ((v4 << 1) | (v4 >> 31)) ^ c[9];
			v5 = (v5 << 1) | (v5 >> 31);
			v6 = (v6 << 1) | (v6 >> 31);
			v7 = (v7 << 1) | (v7 >> 31);

			/* Iteration.6 */
			tmp = v0; v0 |= v1; v2 ^= v3; v1 = ~v1; v0 ^= v3; v3 &= tmp;
			v1 ^= v3; v3 ^= v2; v2 &= v0; v0 = ~v0; v2 ^= v1; v1 |= v3;
			tmp^= v1; v3 ^= v2; v2 &= v1; v1 ^= v0; v0 = tmp;
			tmp = v5; v5 |= v6; v7 ^= v4; v6 = ~v6; v5 ^= v4; v4 &= tmp;
			v6 ^= v4; v4 ^= v7; v7 &= v5; v5 = ~v5; v7 ^= v6; v6 |= v4;
			tmp^= v6; v4 ^= v7; v7 &= v6; v6 ^= v5; v5 = tmp;
			v4 ^= v0; v5 ^= v1; v6 ^= v2; v7 ^= v3;
			v0 = ((v0 << 2) | (v0 >> 30)) ^ v4;
			v1 = ((v1 << 2) | (v1 >> 30)) ^ v5;
			v2 = ((v2 << 2) | (v2 >> 30)) ^ v6;
			v3 = ((v3 << 2) | (v3 >> 30)) ^ v7;
			v4 = ((v4 << 14) | (v4 >> 18)) ^ v0;
			v5 = ((v5 << 14) | (v5 >> 18)) ^ v1;
			v6 = ((v6 << 14) | (v6 >> 18)) ^ v2;
			v7 = ((v7 << 14) | (v7 >> 18)) ^ v3;
			v0 = ((v0 << 10) | (v0 >> 22)) ^ v4 ^ c[10];
			v1 = ((v1 << 10) | (v1 >> 22)) ^ v5;
			v2 = ((v2 << 10) | (v2 >> 22)) ^ v6;
			v3 = ((v3 << 10) | (v3 >> 22)) ^ v7;
			v4 = ((v4 << 1) | (v4 >> 31)) ^ c[11];
			v5 = (v5 << 1) | (v5 >> 31);
			v6 = (v6 << 1) | (v6 >> 31);
			v7 = (v7 << 1) | (v7 >> 31);

			/* Iteration.7 */
			tmp = v0; v0 |= v1; v2 ^= v3; v1 = ~v1; v0 ^= v3; v3 &= tmp;
			v1 ^= v3; v3 ^= v2; v2 &= v0; v0 = ~v0; v2 ^= v1; v1 |= v3;
			tmp^= v1; v3 ^= v2; v2 &= v1; v1 ^= v0; v0 = tmp;
			tmp = v5; v5 |= v6; v7 ^= v4; v6 = ~v6; v5 ^= v4; v4 &= tmp;
			v6 ^= v4; v4 ^= v7; v7 &= v5; v5 = ~v5; v7 ^= v6; v6 |= v4;
			tmp^= v6; v4 ^= v7; v7 &= v6; v6 ^= v5; v5 = tmp;
			v4 ^= v0; v5 ^= v1; v6 ^= v2; v7 ^= v3;
			v0 = ((v0 << 2) | (v0 >> 30)) ^ v4;
			v1 = ((v1 << 2) | (v1 >> 30)) ^ v5;
			v2 = ((v2 << 2) | (v2 >> 30)) ^ v6;
			v3 = ((v3 << 2) | (v3 >> 30)) ^ v7;
			v4 = ((v4 << 14) | (v4 >> 18)) ^ v0;
			v5 = ((v5 << 14) | (v5 >> 18)) ^ v1;
			v6 = ((v6 << 14) | (v6 >> 18)) ^ v2;
			v7 = ((v7 << 14) | (v7 >> 18)) ^ v3;
			v0 = ((v0 << 10) | (v0 >> 22)) ^ v4 ^ c[12];
			v1 = ((v1 << 10) | (v1 >> 22)) ^ v5;
			v2 = ((v2 << 10) | (v2 >> 22)) ^ v6;
			v3 = ((v3 << 10) | (v3 >> 22)) ^ v7;
			v4 = ((v4 << 1) | (v4 >> 31)) ^ c[13];
			v5 = (v5 << 1) | (v5 >> 31);
			v6 = (v6 << 1) | (v6 >> 31);
			v7 = (v7 << 1) | (v7 >> 31);

			/* Iteration.8 */
			tmp = v0; v0 |= v1; v2 ^= v3; v1 = ~v1; v0 ^= v3; v3 &= tmp;
			v1 ^= v3; v3 ^= v2; v2 &= v0; v0 = ~v0; v2 ^= v1; v1 |= v3;
			tmp^= v1; v3 ^= v2; v2 &= v1; v1 ^= v0; v0 = tmp;
			tmp = v5; v5 |= v6; v7 ^= v4; v6 = ~v6; v5 ^= v4; v4 &= tmp;
			v6 ^= v4; v4 ^= v7; v7 &= v5; v5 = ~v5; v7 ^= v6; v6 |= v4;
			tmp^= v6; v4 ^= v7; v7 &= v6; v6 ^= v5; v5 = tmp;
			v4 ^= v0; v5 ^= v1; v6 ^= v2; v7 ^= v3;
			v0 = ((v0 << 2) | (v0 >> 30)) ^ v4;
			v1 = ((v1 << 2) | (v1 >> 30)) ^ v5;
			v2 = ((v2 << 2) | (v2 >> 30)) ^ v6;
			v3 = ((v3 << 2) | (v3 >> 30)) ^ v7;
			v4 = ((v4 << 14) | (v4 >> 18)) ^ v0;
			v5 = ((v5 << 14) | (v5 >> 18)) ^ v1;
			v6 = ((v6 << 14) | (v6 >> 18)) ^ v2;
			v7 = ((v7 << 14) | (v7 >> 18)) ^ v3;
			v[0] = ((v0 << 10) | (v0 >> 22)) ^ v4 ^ c[14];
			v[1] = ((v1 << 10) | (v1 >> 22)) ^ v5;
			v[2] = ((v2 << 10) | (v2 >> 22)) ^ v6;
			v[3] = ((v3 << 10) | (v3 >> 22)) ^ v7;
			v[4] = ((v4 << 1) | (v4 >> 31)) ^ c[15];
			v[5] = (v5 << 1) | (v5 >> 31);
			v[6] = (v6 << 1) | (v6 >> 31);
			v[7] = (v7 << 1) | (v7 >> 31);
		}

		public static readonly uint[] InitValues =
		{
			0x303994a6, 0xe0337818, 0xc0e65299, 0x441ba90d,
			0x6cc33a12, 0x7f34d442, 0xdc56983e, 0x9389217f,
			0x1e00108f, 0xe5a8bce6, 0x7800423d, 0x5274baf4,
			0x8f5b7882, 0x26889ba7, 0x96e1db12, 0x9a226e9d,
			0xb6de10ed, 0x01685f3d, 0x70f47aae, 0x05a17cf4,
			0x0707a3d4, 0xbd09caca, 0x1c1e8f51, 0xf4272b28,
			0x707a3d45, 0x144ae5cc, 0xaeb28562, 0xfaa7ae2b,
			0xbaca1589, 0x2e48f1c1, 0x40a46f3e, 0xb923c704,
			0xfc20d9d2, 0xe25e72c1, 0x34552e25, 0xe623bb72,
			0x7ad8818f, 0x5c58a4a4, 0x8438764a, 0x1e38e2e7,
			0xbb6de032, 0x78e38b9d, 0xedb780c8, 0x27586719,
			0xd9847356, 0x36eda57f, 0xa2c78434, 0x703aace7,
			0xb213afa5, 0xe028c9bf, 0xc84ebe95, 0x44756f91,
			0x4e608a22, 0x7e8fce32, 0x56d858fe, 0x956548be,
			0x343b138f, 0xfe191be2, 0xd0ec4e3d, 0x3cb226e5,
			0x2ceb4882, 0x5944a28e, 0xb3ad2208, 0xa1c4c355,
			0xf0d2e9e3, 0x5090d577, 0xac11d7fa, 0x2d1925ab,
			0x1bcb66f2, 0xb46496ac, 0x6f2d9bc9, 0xd1925ab0,
			0x78602649, 0x29131ab6, 0x8edae952, 0x0fc053c3,
			0x3b6ba548, 0x3f014f0c, 0xedae9520, 0xfc053c31
		};

		public static readonly uint[] StartingValues = 
		{
			0x6d251e69, 0x44b051e0, 0x4eaa6fb4, 0xdbf78465,
			0x6e292011, 0x90152df4, 0xee058139, 0xdef610bb,
			0xc3b44b95, 0xd9d2f256, 0x70eee9a0, 0xde099fa3,
			0x5d9b0557, 0x8fc944b3, 0xcf1ccf0e, 0x746cd581,
			0xf7efc89d, 0x5dba5781, 0x04016ce5, 0xad659c05,
			0x0306194f, 0x666d1836, 0x24aa230a, 0x8b264ae7,
			0x858075d5, 0x36d79cce, 0xe571f7d7, 0x204b1f67,
			0x35870c6a, 0x57e9e923, 0x14bcb808, 0x7cde72ce,
			0x6c68e9be, 0x5ec41e22, 0xc825b7c7, 0xaffb4363,
			0xf5df3999, 0x0fc688f1, 0xb07224cc, 0x03e86cea
		};
	}
}
