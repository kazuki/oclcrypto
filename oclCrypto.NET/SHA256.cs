﻿using System;
using System.Collections.Generic;
using System.Text;

namespace oclCrypto
{
	class SHA256
	{
		public const int MessageSize = 4 * 16;
		public const int StateSize = 4 * 8;

		public static readonly uint[] InitialValues = new uint[] {
			0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
		};

		public static readonly uint[] Constants = new uint[] {
			0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
			0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
			0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
			0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
			0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
			0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
			0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
			0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
			0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
			0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
			0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
			0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
			0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
			0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
			0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
			0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
		};

		public static unsafe void InitState (byte[] state)
		{
			fixed (byte* pstate = state) {
				uint* p = (uint*)pstate;
				for (int i = 0; i < state.Length; i += StateSize) {
					for (int q = 0; q < InitialValues.Length; q++)
						p[i / 4 + q] = InitialValues[q];
				}
			}
		}

		public unsafe static void Update (byte[] data, int offset, int size, byte[] state)
		{
			uint* buf = stackalloc uint[64];
			fixed (byte* pdata = data, pstate = state) {
				uint* ps = (uint*)pstate;
				for (int i = 0, j = 0; i < state.Length; i += StateSize, j += MessageSize) {
					Update (pdata + j + offset, ps + (i / 4), buf);
				}
			}
		}

		static unsafe void Update (byte* data, uint* state, uint *buf)
		{
			uint a, b, c, d, e, f, g, h;
			uint t1, t2;
			uint[] constants = Constants;

			for (int i = 0; i < 16; i++)
				buf[i] = (uint)(((data[4 * i]) << 24) | ((data[4 * i + 1]) << 16) | ((data[4 * i + 2]) << 8) | ((data[4 * i + 3])));
			
			for (int i = 16; i < 64; i++) {
				t1 = buf[i - 15];
				t1 = (((t1 >> 7) | (t1 << 25)) ^ ((t1 >> 18) | (t1 << 14)) ^ (t1 >> 3));
				t2 = buf[i - 2];
				t2 = (((t2 >> 17) | (t2 << 15)) ^ ((t2 >> 19) | (t2 << 13)) ^ (t2 >> 10));
				buf[i] = t2 + buf[i - 7] + t1 + buf[i - 16];
			}

			a = state[0]; b = state[1]; c = state[2]; d = state[3];
			e = state[4]; f = state[5]; g = state[6]; h = state[7];

			for (int i = 0; i < 64; i++) {
				t1 = h + (((e >> 6) | (e << 26)) ^ ((e >> 11) | (e << 21)) ^ ((e >> 25) | (e << 7))) + ((e & f) ^ (~e & g)) + constants[i] + buf[i];

				t2 = (((a >> 2) | (a << 30)) ^ ((a >> 13) | (a << 19)) ^ ((a >> 22) | (a << 10)));
				t2 = t2 + ((a & b) ^ (a & c) ^ (b & c));
				h = g;
				g = f;
				f = e;
				e = d + t1;
				d = c;
				c = b;
				b = a;
				a = t1 + t2;
			}

			state[0] += a; state[1] += b; state[2] += c; state[3] += d;
			state[4] += e; state[5] += f; state[6] += g; state[7] += h;
		}
	}
}
