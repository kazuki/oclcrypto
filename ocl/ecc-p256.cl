int Compare (__private uint x[8], __private uint y[8]);
int IsZero (__private uint x[8]);

// r = x + y (xとyに指定した配列をrに指定してもOK)
void Add (__private uint x[8], __private uint y[8], __private uint prime[8], __private uint r[8]);

// r = x - y (xとyに指定した配列をrに指定してもOK)
void Subtract (__private uint x[8], __private uint y[8], __private uint prime[8], __private uint r[8]);

// r = x * y (xとyに指定した配列をrに指定してもOK)
void Multiply (__private uint x[8], __private uint y[8], __private uint prime[8], __private uint r[8]);

// r.xyz = 1.xyz + 2.xyz (rと1,2は異なるメモリである必要がある)
void EC_Add (__private uint x1[8], __private uint y1[8], __private uint z1[8],
				 __private uint x2[8], __private uint y2[8], __private uint z2[8],
				 __private uint prime[8],
				 __private uint rx[8], __private uint ry[8], __private uint rz[8]);

// x,y,zとrx,ry,rzは異なるメモリである必要がある
void EC_Double (__private uint x[8], __private uint y[8], __private uint z[8],
					  __private uint prime[8],
					  __private uint rx[8], __private uint ry[8], __private uint rz[8]);

// x,y,zとrx,ry,rzは異なるメモリである必要がある
void EC_Multiply (__private uint x[8], __private uint y[8], __private uint z[8],
						__private uint s[8], __private uint prime[8],
						__private uint rx[8], __private uint ry[8], __private uint rz[8]);

__kernel void Test (__global uint* input, __global uint* output)
{
	__private uint x1[8];
	__private uint y1[8];
	__private uint z1[8];
	__private uint x2[8];
	__private uint y2[8];
	__private uint z2[8];
	__private uint s[8];
	__private uint prime[8] = {0xffffffff, 0xffffffff, 0xffffffff, 0, 0, 0, 1, 0xffffffff};

	int global_id = get_global_id (0);
	input += global_id * 32;
	output += global_id * 24;

	for (uint i = 0; i < 8; i ++) {
		x1[i] = input[i];
		y1[i] = input[i + 8];
		z1[i] = input[i + 16];
		s[i]  = input[i + 24];
	}

	EC_Multiply (x1, y1, z1, s, prime, x2, y2, z2);

	for (uint i = 0; i < 8; i ++) {
		output[i] = x2[i];
		output[i + 8] = y2[i];
		output[i + 16] = z2[i];
	}
}

void EC_Multiply (__private uint x[8], __private uint y[8], __private uint z[8],
						__private uint s[8], __private uint prime[8],
						__private uint rx[8], __private uint ry[8], __private uint rz[8])
{
	__private uint tx[8];
	__private uint ty[8];
	__private uint tz[8];
	__private uint *sx, *sy, *sz, *dx, *dy, *dz, *tp;

	int j = 255;
	while (j >= 0 && ((s[j >> 5] >> (j & 31)) & 1) == 0)
		j --;
	for (int i = 0; i < 8; i ++) {
		rx[i] = x[i];
		ry[i] = y[i];
		rz[i] = z[i];
	}
	j --;

	sx = rx; sy = ry; sz = rz;
	dx = tx; dy = ty; dz = tz;

	for (; j >= 0; j --) {
		EC_Double (sx, sy, sz, prime, dx, dy, dz);
		if (((s[j >> 5] >> (j & 31)) & 1) == 1) {
			EC_Add (dx, dy, dz, x, y, z, prime, sx, sy, sz);
		} else {
			tp = sx; sx = dx; dx = tp;
			tp = sy; sy = dy; dy = tp;
			tp = sz; sz = dz; dz = tp;
		}
	}
	for (int i = 0; i < 8; i ++) {
		rx[i] = sx[i];
		ry[i] = sy[i];
		rz[i] = sz[i];
	}
}

void EC_Add (__private uint x1[8], __private uint y1[8], __private uint z1[8],
				 __private uint x2[8], __private uint y2[8], __private uint z2[8],
				 __private uint prime[8],
				 __private uint rx[8], __private uint ry[8], __private uint rz[8])
{
	__private uint *u1 = ry;
	//__private uint u1[8];
	__private uint *u2 = rx;
	//__private uint u2[8];
	__private uint H2[8];
	__private uint H3[8];
	__private uint s1[8];
	__private uint s2[8];
	__private uint r[8];

	/*if (IsZero (z1)) {
		for (int i = 0; i < 8; i ++) {
			rx[i] = x2[i];
			ry[i] = y2[i];
			rz[i] = z2[i];
		}
		return;
	}
	if (IsZero (z2)) {
		for (int i = 0; i < 8; i ++) {
			rx[i] = x1[i];
			ry[i] = y1[i];
			rz[i] = z1[i];
		}
		return;
	}*/

	Multiply (z1, z1, prime, u2);
	Multiply (z1, u2, prime, s2);
	Multiply (x2, u2, prime, u2);
	Multiply (y2, s2, prime, s2);
	Multiply (z2, z2, prime, u1);
	Multiply (z2, u1, prime, s1);
	Multiply (x1, u1, prime, u1);
	Multiply (y1, s1, prime, s1);
	Subtract (u2, u1, prime, H3);
	Multiply (z1, z2, prime, rz);
	Multiply (rz, H3, prime, rz);
	Multiply (H3, H3, prime, H2);
	Multiply (H3, H2, prime, H3);
	Subtract (s2, s1, prime, r);
	Multiply (r, r, prime, s2);
	Subtract (s2, H3, prime, s2);
	Add (u1, u1, prime, u2);
	Multiply (u2, H2, prime, u2);
	Subtract (s2, u2, prime, rx);
	Multiply (u1, H2, prime, u1);
	Subtract (u1, rx, prime, u1);
	Multiply (u1, r, prime, u1);
	Multiply (s1, H3, prime, s1);
	Subtract (u1, s1, prime, ry);
}

void EC_Double (__private uint x[8], __private uint y[8], __private uint z[8],
					  __private uint prime[8],
					  __private uint rx[8], __private uint ry[8], __private uint rz[8])
{
	__private uint y2[8];
	__private uint l1[8];
	__private uint *l2 = rz;

	/*if (IsZero (z)) {
		for (int i = 0; i < 8; i ++) {
			rx[i] = x[i];
			ry[i] = y[i];
			rz[i] = z[i];
		}
		return;
	}*/

	// l1 = 3(x - z^2)(x + z^2)
	Multiply (z, z, prime, y2);
	Subtract (x, y2, prime, l1);
	Add (x, y2, prime, y2);
	Multiply (l1, y2, prime, l1);
	Add (l1, l1, prime, y2);
	Add (l1, y2, prime, l1);

	// l2 = 4(xy^2)
	Multiply (y, y, prime, y2);
	Multiply (x, y2, prime, l2);
	Add (l2, l2, prime, l2);
	Add (l2, l2, prime, l2);

	// X = l1^2 - 2l2
	Multiply (l1, l1, prime, rx);
	Add (l2, l2, prime, ry);
	Subtract (rx, ry, prime, rx);

	// y2 = 8*y^4
	Multiply (y2, y2, prime, y2);
	Add (y2, y2, prime, y2);
	Add (y2, y2, prime, y2);
	Add (y2, y2, prime, y2);

	// Y = l1(l2 - X) - l3
	Subtract (l2, rx, prime, l2);
	Multiply (l1, l2, prime, l1);
	Subtract (l1, y2, prime, ry);

	// Z = 2yz
	Multiply (y, z, prime, rz);
	Add (rz, rz, prime, rz);
}

void Add (__private uint x[8], __private uint y[8], __private uint prime[8], __private uint r[8])
{
	uint tmp, carry = 0;
	ulong t = 0;
	for (uint i = 0; i < 8; i ++) {
		t += ((ulong)x[i]) + ((ulong)y[i]);
		r[i] = (uint)(t & 0xffffffff);
		t >>= 32;
	}
	if (t == 0 && Compare (r, prime) < 0)
		return;

	for (uint i = 0; i < 7; i ++) {
		tmp = prime[i] + carry;
		r[i] -= tmp;
		carry = (tmp < carry || r[i] > ~tmp ? 1 : 0);
	}
	r[7] -= prime[7] + carry;
}

void Subtract (__private uint x[8], __private uint y[8], __private uint prime[8], __private uint r[8])
{
	int cmp = Compare (x, y);
	if (cmp >= 0) {
		uint tmp = y[0], carry;
		carry = ((r[0] = x[0] - y[0]) > ~tmp ? 1U : 0U);
		tmp = y[1] + carry; carry = (tmp < carry | (r[1] = x[1] - tmp) > ~tmp ? 1U : 0U);
		tmp = y[2] + carry; carry = (tmp < carry | (r[2] = x[2] - tmp) > ~tmp ? 1U : 0U);
		tmp = y[3] + carry; carry = (tmp < carry | (r[3] = x[3] - tmp) > ~tmp ? 1U : 0U);
		tmp = y[4] + carry; carry = (tmp < carry | (r[4] = x[4] - tmp) > ~tmp ? 1U : 0U);
		tmp = y[5] + carry; carry = (tmp < carry | (r[5] = x[5] - tmp) > ~tmp ? 1U : 0U);
		tmp = y[6] + carry; carry = (tmp < carry | (r[6] = x[6] - tmp) > ~tmp ? 1U : 0U);
		r[7] = x[7] - y[7] - carry;
	} else {
		long tmp;
		int carry = 0;
		r[0] = (uint)(tmp = ((long)x[0]) + ((long)prime[0]) - y[0] - carry); carry = (tmp < 0 ? 1 : tmp > 0xFFFFFFFF ? -1 : 0);
		r[1] = (uint)(tmp = ((long)x[1]) + ((long)prime[1]) - y[1] - carry); carry = (tmp < 0 ? 1 : tmp > 0xFFFFFFFF ? -1 : 0);
		r[2] = (uint)(tmp = ((long)x[2]) + ((long)prime[2]) - y[2] - carry); carry = (tmp < 0 ? 1 : tmp > 0xFFFFFFFF ? -1 : 0);
		r[3] = (uint)(tmp = ((long)x[3]) + ((long)prime[3]) - y[3] - carry); carry = (tmp < 0 ? 1 : tmp > 0xFFFFFFFF ? -1 : 0);
		r[4] = (uint)(tmp = ((long)x[4]) + ((long)prime[4]) - y[4] - carry); carry = (tmp < 0 ? 1 : tmp > 0xFFFFFFFF ? -1 : 0);
		r[5] = (uint)(tmp = ((long)x[5]) + ((long)prime[5]) - y[5] - carry); carry = (tmp < 0 ? 1 : tmp > 0xFFFFFFFF ? -1 : 0);
		r[6] = (uint)(tmp = ((long)x[6]) + ((long)prime[6]) - y[6] - carry); carry = (tmp < 0 ? 1 : tmp > 0xFFFFFFFF ? -1 : 0);
		r[7] = (uint)(tmp = ((long)x[7]) + ((long)prime[7]) - y[7] - carry);
	}
}

void Multiply (__private uint x[8], __private uint y[8], __private uint prime[8], __private uint r[8])
{
	ulong r0, r1, r2, r3, r4, r5, r6, r7;
	uint tmp32;
	ulong tmp, tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7;
	ulong d1, d2, d3, d4, d5;
	ulong triple1, triple2;
	const ulong mask = 0xffffffff;
	const ulong carry = 0x100000000;
	const ulong negative = 0xffffff800000007f; // (2^62-1) - ((2^32) - 1) * 16 * 8
	
	tmp = ((ulong)x[0]) * ((ulong)y[0]); r0 = tmp & mask; r1 = tmp >> 32;
	tmp = ((ulong)x[1]) * ((ulong)y[0]); r1 += tmp & mask; r2 = tmp >> 32;
	tmp = ((ulong)x[2]) * ((ulong)y[0]); r2 += tmp & mask; r3 = tmp >> 32;
	tmp = ((ulong)x[3]) * ((ulong)y[0]); r3 += tmp & mask; r4 = tmp >> 32;
	tmp = ((ulong)x[4]) * ((ulong)y[0]); r4 += tmp & mask; r5 = tmp >> 32;
	tmp = ((ulong)x[5]) * ((ulong)y[0]); r5 += tmp & mask; r6 = tmp >> 32;
	tmp = ((ulong)x[6]) * ((ulong)y[0]); r6 += tmp & mask; r7 = tmp >> 32;
	tmp = ((ulong)x[7]) * ((ulong)y[0]); r7 += tmp & mask; tmp32 = (uint)(tmp >> 32);
	r7 += tmp32;
	r6 -= tmp32;
	r3 -= tmp32;
	r0 += tmp32;
	
	tmp = ((ulong)x[0]) * ((ulong)y[1]); r1 += tmp & mask; r2 += tmp >> 32;
	tmp = ((ulong)x[1]) * ((ulong)y[1]); r2 += tmp & mask; r3 += tmp >> 32;
	tmp = ((ulong)x[2]) * ((ulong)y[1]); r3 += tmp & mask; r4 += tmp >> 32;
	tmp = ((ulong)x[3]) * ((ulong)y[1]); r4 += tmp & mask; r5 += tmp >> 32;
	tmp = ((ulong)x[4]) * ((ulong)y[1]); r5 += tmp & mask; r6 += tmp >> 32;
	tmp = ((ulong)x[5]) * ((ulong)y[1]); r6 += tmp & mask; r7 += tmp >> 32;
	tmp = ((ulong)x[6]) * ((ulong)y[1]); r7 += tmp & mask; tmp1 = (uint)(tmp >> 32);
	tmp = ((ulong)x[7]) * ((ulong)y[1]); tmp1 += (uint)tmp; tmp32 = (uint)(tmp >> 32);
	r7 += tmp1;
	r6 -= tmp1 + tmp32;
	r4 -= tmp32;
	r3 -= tmp1 + tmp32;
	r1 += tmp32;
	r0 += tmp1 + tmp32;
	
	tmp = ((ulong)x[0]) * ((ulong)y[2]); r2 += tmp & mask; r3 += tmp >> 32;
	tmp = ((ulong)x[1]) * ((ulong)y[2]); r3 += tmp & mask; r4 += tmp >> 32;
	tmp = ((ulong)x[2]) * ((ulong)y[2]); r4 += tmp & mask; r5 += tmp >> 32;
	tmp = ((ulong)x[3]) * ((ulong)y[2]); r5 += tmp & mask; r6 += tmp >> 32;
	tmp = ((ulong)x[4]) * ((ulong)y[2]); r6 += tmp & mask; r7 += tmp >> 32;
	tmp = ((ulong)x[5]) * ((ulong)y[2]); r7 += tmp & mask; tmp1 = (uint)(tmp >> 32);
	tmp = ((ulong)x[6]) * ((ulong)y[2]); tmp1 += (uint)tmp; tmp2 = (uint)(tmp >> 32);
	tmp = ((ulong)x[7]) * ((ulong)y[2]); tmp2 += (uint)tmp; tmp32 = (uint)(tmp >> 32);
	r7 += tmp1 - tmp32;
	r6 -= tmp1 + tmp2;
	r5 -= tmp32;
	r4 -= tmp2 + tmp32;
	r3 -= tmp1 + tmp2;
	r2 += tmp32;
	r1 += tmp2 + tmp32;
	r0 += tmp1 + tmp2;
	
	tmp = ((ulong)x[0]) * ((ulong)y[3]); r3 += tmp & mask; r4 += tmp >> 32;
	tmp = ((ulong)x[1]) * ((ulong)y[3]); r4 += tmp & mask; r5 += tmp >> 32;
	tmp = ((ulong)x[2]) * ((ulong)y[3]); r5 += tmp & mask; r6 += tmp >> 32;
	tmp = ((ulong)x[3]) * ((ulong)y[3]); r6 += tmp & mask; r7 += tmp >> 32;
	tmp = ((ulong)x[4]) * ((ulong)y[3]); r7 += tmp & mask; tmp1 = (uint)(tmp >> 32);
	tmp = ((ulong)x[5]) * ((ulong)y[3]); tmp1 += (uint)tmp; tmp2 = (uint)(tmp >> 32);
	tmp = ((ulong)x[6]) * ((ulong)y[3]); tmp2 += (uint)tmp; tmp3 = (uint)(tmp >> 32);
	tmp = ((ulong)x[7]) * ((ulong)y[3]); tmp3 += (uint)tmp; tmp32 = (uint)(tmp >> 32);
	d1 = ((ulong)tmp32) << 1;
	r7 += tmp1 - tmp3 - tmp32;
	r6 -= tmp1 + tmp2;
	r5 -= tmp3 + tmp32;
	r4 -= tmp2 + tmp3;
	r3 -= tmp1 + tmp2 - d1;
	r2 += tmp3 + tmp32;
	r1 += tmp2 + tmp3;
	r0 += tmp1 + tmp2 - tmp32;
	
	tmp = ((ulong)x[0]) * ((ulong)y[4]); r4 += tmp & mask; r5 += tmp >> 32;
	tmp = ((ulong)x[1]) * ((ulong)y[4]); r5 += tmp & mask; r6 += tmp >> 32;
	tmp = ((ulong)x[2]) * ((ulong)y[4]); r6 += tmp & mask; r7 += tmp >> 32;
	tmp = ((ulong)x[3]) * ((ulong)y[4]); r7 += tmp & mask; tmp1 = (uint)(tmp >> 32);
	tmp = ((ulong)x[4]) * ((ulong)y[4]); tmp1 += (uint)tmp; tmp2 = (uint)(tmp >> 32);
	tmp = ((ulong)x[5]) * ((ulong)y[4]); tmp2 += (uint)tmp; tmp3 = (uint)(tmp >> 32);
	tmp = ((ulong)x[6]) * ((ulong)y[4]); tmp3 += (uint)tmp; tmp4 = (uint)(tmp >> 32);
	tmp = ((ulong)x[7]) * ((ulong)y[4]); tmp4 += (uint)tmp; tmp32 = (uint)(tmp >> 32);
	d1 = tmp4 << 1;
	d2 = ((ulong)tmp32) << 1;
	r7 += tmp1 - tmp3 - tmp4 - tmp32;
	r6 -= tmp1 + tmp2;
	r5 -= tmp3 + tmp4;
	r4 -= tmp2 + tmp3 - d2;
	r3 -= tmp1 + tmp2 - d1 - d2;
	r2 += tmp3 + tmp4;
	r1 += tmp2 + tmp3 - tmp32;
	r0 += tmp1 + tmp2 - tmp4 - tmp32;
	
	tmp = ((ulong)x[0]) * ((ulong)y[5]); r5 += tmp & mask; r6 += tmp >> 32;
	tmp = ((ulong)x[1]) * ((ulong)y[5]); r6 += tmp & mask; r7 += tmp >> 32;
	tmp = ((ulong)x[2]) * ((ulong)y[5]); r7 += tmp & mask; tmp1 = (uint)(tmp >> 32);
	tmp = ((ulong)x[3]) * ((ulong)y[5]); tmp1 += (uint)tmp; tmp2 = (uint)(tmp >> 32);
	tmp = ((ulong)x[4]) * ((ulong)y[5]); tmp2 += (uint)tmp; tmp3 = (uint)(tmp >> 32);
	tmp = ((ulong)x[5]) * ((ulong)y[5]); tmp3 += (uint)tmp; tmp4 = (uint)(tmp >> 32);
	tmp = ((ulong)x[6]) * ((ulong)y[5]); tmp4 += (uint)tmp; tmp5 = (uint)(tmp >> 32);
	tmp = ((ulong)x[7]) * ((ulong)y[5]); tmp5 += (uint)tmp; tmp32 = (uint)(tmp >> 32);
	d1 = tmp4 << 1;
	d2 = tmp5 << 1;
	d3 = ((ulong)tmp32) << 1;
	r7 += tmp1 - tmp3 - tmp4 - tmp5 - tmp32;
	r6 -= tmp1 + tmp2 - tmp32;
	r5 -= tmp3 + tmp4 - d3;
	r4 -= tmp2 + tmp3 - d2 - d3;
	r3 -= tmp1 + tmp2 - d1 - d2 - tmp32;
	r2 += tmp3 + tmp4 - tmp32;
	r1 += tmp2 + tmp3 - tmp5 - tmp32;
	r0 += tmp1 + tmp2 - tmp4 - tmp5 - tmp32;
	
	tmp = ((ulong)x[0]) * ((ulong)y[6]); r6 += tmp & mask; r7 += tmp >> 32;
	tmp = ((ulong)x[1]) * ((ulong)y[6]); r7 += tmp & mask; tmp1 = (uint)(tmp >> 32);
	tmp = ((ulong)x[2]) * ((ulong)y[6]); tmp1 += (uint)tmp; tmp2 = (uint)(tmp >> 32);
	tmp = ((ulong)x[3]) * ((ulong)y[6]); tmp2 += (uint)tmp; tmp3 = (uint)(tmp >> 32);
	tmp = ((ulong)x[4]) * ((ulong)y[6]); tmp3 += (uint)tmp; tmp4 = (uint)(tmp >> 32);
	tmp = ((ulong)x[5]) * ((ulong)y[6]); tmp4 += (uint)tmp; tmp5 = (uint)(tmp >> 32);
	tmp = ((ulong)x[6]) * ((ulong)y[6]); tmp5 += (uint)tmp; tmp6 = (uint)(tmp >> 32);
	tmp = ((ulong)x[7]) * ((ulong)y[6]); tmp6 += (uint)tmp; tmp32 = (uint)(tmp >> 32);
	d1 = tmp4 << 1;
	d2 = tmp5 << 1;
	d3 = tmp6 << 1;
	d4 = ((ulong)tmp32) << 1;
	triple1 = d4 + tmp32;
	r7 += tmp1 - tmp3 - tmp4 - tmp5 - tmp6;
	r6 -= tmp1 + tmp2 - tmp6 - triple1;
	r5 -= tmp3 + tmp4 - d3 - d4;
	r4 -= tmp2 + tmp3 - d2 - d3 - tmp32;
	r3 -= tmp1 + tmp2 - d1 - d2 - tmp6;
	r2 += tmp3 + tmp4 - tmp6 - tmp32;
	r1 += tmp2 + tmp3 - tmp5 - tmp6 - tmp32;
	r0 += tmp1 + tmp2 - tmp4 - tmp5 - tmp6 - tmp32;

	tmp = ((ulong)x[0]) * ((ulong)y[7]); r7 += tmp & mask; tmp1 = (uint)(tmp >> 32);
	tmp = ((ulong)x[1]) * ((ulong)y[7]); tmp1 += (uint)tmp; tmp2 = (uint)(tmp >> 32);
	tmp = ((ulong)x[2]) * ((ulong)y[7]); tmp2 += (uint)tmp; tmp3 = (uint)(tmp >> 32);
	tmp = ((ulong)x[3]) * ((ulong)y[7]); tmp3 += (uint)tmp; tmp4 = (uint)(tmp >> 32);
	tmp = ((ulong)x[4]) * ((ulong)y[7]); tmp4 += (uint)tmp; tmp5 = (uint)(tmp >> 32);
	tmp = ((ulong)x[5]) * ((ulong)y[7]); tmp5 += (uint)tmp; tmp6 = (uint)(tmp >> 32);
	tmp = ((ulong)x[6]) * ((ulong)y[7]); tmp6 += (uint)tmp; tmp7 = (uint)(tmp >> 32);
	tmp = ((ulong)x[7]) * ((ulong)y[7]); tmp7 += (uint)tmp; tmp32 = (uint)(tmp >> 32);
	d1 = tmp4 << 1;
	d2 = tmp5 << 1;
	d3 = tmp6 << 1;
	d4 = tmp7 << 1;
	d5 = ((ulong)tmp32) << 1;
	triple1 = d4 + tmp7;
	triple2 = d5 + tmp32;
	r7 += tmp1 - tmp3 - tmp4 - tmp5 - tmp6 + triple2;
	r6 -= tmp1 + tmp2 - tmp6 - triple1 - d5;
	r5 -= tmp3 + tmp4 - d3 - d4 - tmp32;
	r4 -= tmp2 + tmp3 - d2 - d3 - tmp7;
	r3 -= tmp1 + tmp2 - d1 - d2 - tmp6 + tmp32;
	r2 += tmp3 + tmp4 - tmp6 - tmp7 - tmp32;
	r1 += tmp2 + tmp3 - tmp5 - tmp6 - tmp7 - tmp32;
	r0 += tmp1 + tmp2 - tmp4 - tmp5 - tmp6 - tmp7;
	
	// check negative-value
	while (r0 >= negative) { r1--; r0 += carry; }
	while (r1 >= negative) { r2--; r1 += carry; }
	while (r2 >= negative) { r3--; r2 += carry; }
	while (r3 >= negative) { r4--; r3 += carry; }
	while (r4 >= negative) { r5--; r4 += carry; }
	while (r5 >= negative) { r6--; r5 += carry; }
	while (r6 >= negative) { r7--; r6 += carry; }
	while (r7 >= negative) {
		r0 += prime[0];
		r1 += prime[1];
		r2 += prime[2];
		r3 += prime[3];
		r4 += prime[4];
		r5 += prime[5];
		r6 += prime[6];
		r7 += prime[7];
	}

	// check carry
	while (r0 > mask || r1 > mask || r2 > mask || r3 > mask || r4 > mask || r5 > mask || r6 > mask || r7 > mask) {
		if (r7 > mask) {
			tmp32 = (uint)(r7 >> 32);
			r0 += tmp32;
			r3 -= tmp32;
			r6 -= tmp32;
			r7 = tmp32 + (ulong)((uint)r7);

			// check negative-value
			while (r3 >= negative) { r4--; r3 += carry; }
			while (r4 >= negative) { r5--; r4 += carry; }
			while (r5 >= negative) { r6--; r5 += carry; }
			while (r6 >= negative) { r7--; r6 += carry; }
		}
		tmp32 = (uint)(r0 >> 32); r0 = (uint)r0; r1 += tmp32;
		tmp32 = (uint)(r1 >> 32); r1 = (uint)r1; r2 += tmp32;
		tmp32 = (uint)(r2 >> 32); r2 = (uint)r2; r3 += tmp32;
		tmp32 = (uint)(r3 >> 32); r3 = (uint)r3; r4 += tmp32;
		tmp32 = (uint)(r4 >> 32); r4 = (uint)r4; r5 += tmp32;
		tmp32 = (uint)(r5 >> 32); r5 = (uint)r5; r6 += tmp32;
		tmp32 = (uint)(r6 >> 32); r6 = (uint)r6; r7 += tmp32;
	}

	r[0] = r0; r[1] = r1; r[2] = r2; r[3] = r3;
	r[4] = r4; r[5] = r5; r[6] = r6; r[7] = r7;
	
	if (Compare (x, prime) >= 0) {
		r[0] -= prime[0];
		uint carry32 = r[0] > ~tmp32 ? 1U : 0U;
		tmp32 = carry32 + prime[0]; r[1] -= tmp32;
		carry32 = (tmp32 < carry32 || r[1] > ~tmp32 ? 1U : 0U);
		tmp32 = carry32 + prime[0]; r[2] -= tmp32;
		carry32 = (tmp32 < carry32 || r[2] > ~tmp32 ? 1U : 0U);
		tmp32 = carry32 + prime[0]; r[3] -= tmp32;
		carry32 = (tmp32 < carry32 || r[3] > ~tmp32 ? 1U : 0U);
		tmp32 = carry32 + prime[0]; r[4] -= tmp32;
		carry32 = (tmp32 < carry32 || r[4] > ~tmp32 ? 1U : 0U);
		tmp32 = carry32 + prime[0]; r[5] -= tmp32;
		carry32 = (tmp32 < carry32 || r[5] > ~tmp32 ? 1U : 0U);
		tmp32 = carry32 + prime[0]; r[6] -= tmp32;
		carry32 = (tmp32 < carry32 || r[6] > ~tmp32 ? 1U : 0U);
		tmp32 = carry32 + prime[0]; r[7] -= tmp32;
	}
}

int Compare (__private uint x[8], __private uint y[8])
{
	int i = 7;
	while (i != 0 && x[i] == y[i]) i --;
	if (x[i] > y[i])
		return 1;
	if (x[i] < y[i])
		return -1;
	return 0;
}

int IsZero (__private uint x[8])
{
	for (int i = 0; i < 8; i ++)
		if (x[i] != 0)
			return 0;
	return 1;
}
