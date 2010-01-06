void subBytes (__private uint4 *state, int offset);
void mixColumns (__private uint4 *state);
void shiftRows (__private uint4 *state);
void round_ (__private uint4 *state, int offset, int id, const __constant uint4 *key, int key_offset);

__kernel
void encrypt (__global uint4 *global_state, const __global uint4 *key)
{
	__private uint4 state[32];
	global_state += get_global_id (0) * 32;

	for (uint i = 0; i < 32; i ++)
		state[i] = global_state[i] ^ key[i];

	for (uint round = 1; round < 10; round ++) {
		subBytes (state, 0);
		subBytes (state, 8);
		subBytes (state, 16);
		subBytes (state, 24);
		shiftRows (state);
		mixColumns (state);
		for (uint i = 0; i < 32; i ++)
			state[i] ^= key[round * 32 + i];
	}

	subBytes (state, 0);
	subBytes (state, 8);
	subBytes (state, 16);
	subBytes (state, 24);
	shiftRows (state);
	for (uint i = 0; i < 32; i ++)
		global_state[i] = state[i] ^ key[320 + i];
}

__kernel
void bitslice_kernel (__global uint4* state, __local uint4* cache)
{
	const uint4 c1 = (uint4)(1);
	size_t id = get_local_id (0);
	uint4 t = (uint4)(0), cs;
	cache += id & 0xFFFFFFE0;
	state += get_global_id (0) & 0xFFFFFFE0;

	id &= 0x1F;
	cache[id] = state[id];
	barrier (CLK_LOCAL_MEM_FENCE);

	cs = (uint4)(id);
	for (int i = 0; i < 32; i ++)
		t |= ((cache[i] >> cs) & c1) << (uint4)(i);
	state[id] = t;
}

__kernel 
void bitslice_key (__constant uchar* expandedKey,
                   __global   uint4*  bitsliceKey)
{
	size_t gid = get_global_id (0);
	int q = gid >> 5;
	int g = (q << 7) + (gid & 0x1F);
	int k = g >> 3;
	int j = g & 7;

	bitsliceKey[gid] =
		(uint4)(((expandedKey[k +  0] >> j) & 1) == 0 ? 0 : 0xffffffff,
				  ((expandedKey[k +  4] >> j) & 1) == 0 ? 0 : 0xffffffff,
				  ((expandedKey[k +  8] >> j) & 1) == 0 ? 0 : 0xffffffff,
				  ((expandedKey[k + 12] >> j) & 1) == 0 ? 0 : 0xffffffff);
}

void subBytes (__private uint4 *state, int offset)
{
	uint4 x0, x1, x2, x3, x4, x5, x6, x7;
	uint4 a0, a1, a2, a3, b0, b1, b2, b3;
	uint4 t0,t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13,t14;

	a0 = state[offset + 0]; a1 = state[offset + 1]; a2 = state[offset + 2]; a3 = state[offset + 3];
	b0 = state[offset + 4]; b1 = state[offset + 5]; b2 = state[offset + 6]; b3 = state[offset + 7];

	/* Isomorphic Mapping */
	x7 = b1 ^ b3; x3 = a1 ^ a2; x6 = x3 ^ a3; x0 = a1 ^ b2;
	x1 = x0 ^ b0; x0 ^= a0;  x2 = x6 ^ b0 ^ b3;
	x3 ^= b2 ^ b3; x4 = x6 ^ x7; x5 = a2 ^ a3 ^ x7; x6 ^= b0 ^ b2 ^ b3;

	/* a[0-3] = x[0-3] ^ x[4-7]*/
	a0 = x0 ^ x4; a1 = x1 ^ x5; a2 = x2 ^ x6; a3 = x3 ^ x7;

	/* lambda * (a[0-3] * a[0-3]) */
	b0 = x4 ^ x5 ^ x7; b1 = x5 ^ x6; b2 = x6 ^ x7;
	b3 = b0 ^ b2; b0 = b2; b2 = b1 ^ x7 ^ b3; b1 = x7;

	/* x[0-3] = a[0-3] * x[0-3] */
	t0 = a3 & x3; t1 = (a2 & x2) ^ t0;
	t2 = t0 ^ (a2 & x3) ^ (a3 & x2);
	t3 = a1 & x1; t4 = (a0 & x0) ^ t3;
	t5 = t3 ^ (a0 & x1) ^ (a1 & x0);
	t0 = a0 ^ a2; t3 = a1 ^ a3;
	x0 ^= x2; x1 ^= x3; t6 = t3 & x1;
	x2 = (t0 & x0) ^ t6 ^ t4;
	x3 = t6 ^ (t0 & x1) ^ (t3 & x0) ^ t5;
	x0 = t2 ^ t4; x1 = t1 ^ t2 ^ t5;

	/* b[0-3] = (x[0-3] * b[0-3])^(-1) in GF(2^4) */
	t0 = b0 ^ x0; t1 = b1 ^ x1; t2 = b2 ^ x2; t3 = b3 ^ x3;
	t4 = t0 & t3; t5 = t1 & t2; t6 = t1 & t3; t7 = t2 & t3;
	t8 = t0 & t5; t9 = t0 & t6; t10 = t0 & t7; t11 = t1 & t7;
	t12 = t1 ^ t2; t13 = t11 ^ t10; t14 = t4 ^ t5;
	b0 = t0 ^ t12 ^ t13 ^ t6 ^ t9 ^ t14 ^ t8;
	b1 = t12 ^ t3 ^ t11 ^ t9 ^ (t0 & t2);
	b2 = t2 ^ t13 ^ t14;
	b3 = t2 ^ t3 ^ t11 ^ t4;

	/* x[0-3] = a[0-3] * b[0-3], x[4-7] = b[0-3] * x[4-7] */
	t0 = b0 ^ b2; 	t1 = b1 ^ b3;
	t2 = b3 & x7; t3 = (b2 & x6) ^ t2;
	t4 = t2 ^ (b2 & x7) ^ (b3 & x6);
	t5 = b1 & x5; t6 = (b0 & x4) ^ t5;
	t7 = t5 ^ (b0 & x5) ^ (b1 & x4);
	t2 = x4 ^ x6; t5 = x5 ^ x7;
	t8 = t1 & t5; x4 = t4 ^ t6;
	x5 = t3 ^ t4 ^ t7;
	x6 = (t0 & t2) ^ t8 ^ t6;
	x7 = t8 ^ (t0 & t5) ^ (t1 & t2) ^ t7;
	t2 = b3 & a3; t3 = (b2 & a2) ^ t2;
	t4 = t2 ^ (b2 & a3) ^ (b3 & a2);
	t5 = b1 & a1; t6 = (b0 & a0) ^ t5;
	t7 = t5 ^ (b0 & a1) ^ (b1 & a0);
	t2 = a0 ^ a2; t5 = a1 ^ a3;
	t8 = t1 & t5; x0 = t4 ^ t6;
	x1 = t3 ^ t4 ^ t7;
	x2 = (t0 & t2) ^ t8 ^ t6;
	x3 = t8 ^ (t0 & t5) ^ (t1 & t2) ^ t7;

	/* Inverse Isomorphic Mapping and S-box */
	a0 = x0 ^ x1 ^ x2;
	a1 = x6 ^ x7;
	a2 = x0 ^ x7;
	a3 = x2 ^ x7;
	b0 = x4 ^ x5 ^ x6;
	state[offset + 0] = ~(a0 ^ a1);
	state[offset + 1] = ~a2;
	state[offset + 2] = x0 ^ x2 ^ x3 ^ b0;
	state[offset + 3] = a0;
	state[offset + 4] = a2 ^ x1 ^ x4;
	state[offset + 5] = ~a3;
	state[offset + 6] = ~(b0 ^ x7);
	state[offset + 7] = a3 ^ x3;
}

void mixColumns (__private uint4 *s)
{
	uint4 t0, t1, t2, t3, t4, t5, t6, t7;
	uint4 q0, q1, q2;
	q0 = s[ 7] ^ s[ 8];
	q1 = s[15] ^ s[16];
	q2 = s[23] ^ s[24];
	t0 = q0 ^ q1 ^ s[24];
	t1 = s[ 0] ^ q1 ^ q2;
	t2 = s[ 0] ^ s[ 8] ^ q2 ^ s[31];
	t3 = s[ 0] ^ q0 ^ s[16] ^ s[31];
	t4 = s[ 0] ^ q0 ^ s[ 9] ^ s[15] ^ s[17] ^ s[25];
	t5 = s[ 1] ^ s[ 8] ^ q1 ^ s[17] ^ s[23] ^ s[25];
	t6 = s[ 1] ^ s[ 9] ^ s[16] ^ q2 ^ s[25] ^ s[31];
	t7 = s[ 0] ^ s[ 1] ^ s[ 7] ^ s[ 9] ^ s[17] ^ s[24] ^ s[31];
	s[0] = t0; s[8] = t1; s[16] = t2; s[24] = t3;
	t0 = s[ 1] ^ s[ 9] ^ s[10] ^ s[18] ^ s[26];
	t1 = s[ 2] ^ s[ 9] ^ s[17] ^ s[18] ^ s[26];
	t2 = s[ 2] ^ s[10] ^ s[17] ^ s[25] ^ s[26];
	t3 = s[ 1] ^ s[ 2] ^ s[10] ^ s[18] ^ s[25];
	s[1] = t4; s[9] = t5; s[17] = t6; s[25] = t7;
	t4 = s[ 2] ^ s[ 7] ^ s[10] ^ s[11] ^ s[15] ^ s[19] ^ s[27];
	t5 = s[ 3] ^ s[10] ^ s[15] ^ s[18] ^ s[19] ^ s[23] ^ s[27];
	t6 = s[ 3] ^ s[11] ^ s[18] ^ s[23] ^ s[26] ^ s[27] ^ s[31];
	t7 = s[ 2] ^ s[ 3] ^ s[ 7] ^ s[11] ^ s[19] ^ s[26] ^ s[31];
	s[2] = t0; s[10] = t1; s[18] = t2; s[26] = t3;
	t0 = s[ 3] ^ s[ 7] ^ s[11] ^ s[12] ^ s[15] ^ s[20] ^ s[28];
	t1 = s[ 4] ^ s[11] ^ s[15] ^ s[19] ^ s[20] ^ s[23] ^ s[28];
	t2 = s[ 4] ^ s[12] ^ s[19] ^ s[23] ^ s[27] ^ s[28] ^ s[31];
	t3 = s[ 3] ^ s[ 4] ^ s[ 7] ^ s[12] ^ s[20] ^ s[27] ^ s[31];
	s[3] = t4; s[11] = t5; s[19] = t6; s[27] = t7;
	t4 = s[ 4] ^ s[12] ^ s[13] ^ s[21] ^ s[29];
	t5 = s[ 5] ^ s[12] ^ s[20] ^ s[21] ^ s[29];
	t6 = s[ 5] ^ s[13] ^ s[20] ^ s[28] ^ s[29];
	t7 = s[ 4] ^ s[ 5] ^ s[13] ^ s[21] ^ s[28];
	s[4] = t0; s[12] = t1; s[20] = t2; s[28] = t3;
	t0 = s[ 5] ^ s[13] ^ s[14] ^ s[22] ^ s[30];
	t1 = s[ 6] ^ s[13] ^ s[21] ^ s[22] ^ s[30];
	t2 = s[ 6] ^ s[14] ^ s[21] ^ s[29] ^ s[30];
	t3 = s[ 5] ^ s[ 6] ^ s[14] ^ s[22] ^ s[29];
	s[5] = t4; s[13] = t5; s[21] = t6; s[29] = t7;
	t4 = s[ 6] ^ s[14] ^ s[15] ^ s[23] ^ s[31];
	t5 = s[ 7] ^ s[14] ^ s[22] ^ s[23] ^ s[31];
	t6 = s[ 7] ^ s[15] ^ s[22] ^ s[30] ^ s[31];
	t7 = s[ 6] ^ s[ 7] ^ s[15] ^ s[23] ^ s[30];
	s[6] = t0; s[7] = t4; s[14] = t1; s[15] = t5;
	s[22] = t2; s[23] = t6; s[30] = t3; s[31] = t7;
}

void shiftRows (__private uint4 *state)
{
	for (uint i = 8; i < 16; i ++)
		state[i] = state[i].s1230;
	for (uint i = 16; i < 24; i ++)
		state[i] = state[i].s2301;
	for (uint i = 24; i < 32; i ++)
		state[i] = state[i].s3012;
}
